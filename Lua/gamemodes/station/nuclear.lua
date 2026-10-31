local nuclear = {}
Traitormod.Nuclear = nuclear
local config = Traitormod.Config.Nuclear
local json = require("json")
local bombs, sessions = {}, {}
local active = false
local texts
local statusLabels = { locked = "Locked", code = "AwaitCode", ready = "Ready", armed = "Armed", cooldown = "Cooldown", exploded = "Exploded" }
-- Track order must match the six OnActive sounds in nuclear.xml.
local musicLengths = { 109.9977, 111.6000, 103.3606, 196.2902, 109.5756 }
local activationLength = 14

local componentEvent = LuaUserData.CreateStatic("Barotrauma.Item+ComponentStateEventData", true)
local eventSet = LuaUserData.CreateStatic("Barotrauma.EventSet", true)
local holdableDescriptor = Descriptors["Barotrauma.Items.Components.Holdable"] or LuaUserData.RegisterType("Barotrauma.Items.Components.Holdable")
LuaUserData.MakePropertyAccessible(holdableDescriptor, "PickingTime")
local terminalDescriptor = Descriptors["Barotrauma.Items.Components.Terminal"] or LuaUserData.RegisterType("Barotrauma.Items.Components.Terminal")
LuaUserData.MakePropertyAccessible(terminalDescriptor, "OutputValue")

function nuclear.Start()
    active, bombs, sessions = true, {}, {}
    texts = {}
    for _, key in ipairs({ "Title", "Locked", "AwaitDisk", "AwaitCode", "Ready", "Armed", "Cooldown", "Exploded",
        "Time", "Cooling", "Code", "Eject", "Insert", "Anchor", "Detach", "Arm", "Close" }) do
        texts[key] = Traitormod.GetText("Nuke" .. key)
    end
    for item in Item.ItemList do
        if item.Prefab.Identifier == "vt_nuclear_bomb" then nuclear.Register(item) end
    end
end

function nuclear.Register(item)
    if not active or bombs[item] ~= nil then return end
    local code = ""
    for _ = 1, 6 do code = code .. tostring(math.random(0, 9)) end
    bombs[item] = { Code = code, Entered = "", Status = "locked", Remaining = config.Time, Cooldown = 0, LastAttempt = -1,
        MusicIndex = 0,
        MusicElapsed = 0, MusicPlaying = false, MusicStarted = false }
end

function nuclear.Validate(client, item, readOnly)
    return active and Game.RoundStarted
        and client ~= nil and client.Character ~= nil and client.Character.IsHuman
        and not client.Character.IsDead and not client.Character.IsIncapacitated
        and item ~= nil and not item.Removed and bombs[item] ~= nil and item.CanClientAccess(client)
        and (readOnly == true or client.Character.SelectedItem == item)
end

function nuclear.Snapshot(item, data)
    return { Status = data.Status, Remaining = math.ceil(data.ActivationRemaining or data.Remaining), Cooldown = math.ceil(data.Cooldown),
        Entered = #data.Entered, Disk = item.OwnInventory.GetItemAt(0) ~= nil,
        Anchored = item.GetComponentString("Holdable").Attached, Text = texts }
end

function nuclear.Send(client, item, payload)
    local message = Networking.Start("VoidTraitor_NuclearSnapshot")
    message.WriteUInt16(UShort(item.ID))
    message.WriteString(payload or json.encode(nuclear.Snapshot(item, bombs[item])))
    Networking.Send(message, client.Connection)
end

function nuclear.Update(item, data)
    local snapshot = nuclear.Snapshot(item, data)
    local first = snapshot.Text[statusLabels[data.Status]]
    local second = Traitormod.FormatText("NukeTime", snapshot.Remaining)
    if data.Status == "locked" then second = snapshot.Text.AwaitDisk
    elseif data.Status == "code" then second = Traitormod.FormatText("NukeCode", string.rep("*", #data.Entered) .. string.rep("_", 6 - #data.Entered))
    elseif data.Status == "cooldown" then second = Traitormod.FormatText("NukeCooling", snapshot.Cooldown) end
    local body = first .. "\n" .. second
    local terminal = item.GetComponentString("Terminal")
    if terminal.ShowMessage ~= body then
        terminal.ShowMessage = body
        -- the Terminal event only carries OutputValue; SyncHistory would resend every previous countdown line
        terminal.OutputValue = body
        Networking.CreateEntityEvent(item, componentEvent.__new(terminal, nil))
    end
    local holdable = item.GetComponentString("Holdable")
    local canPick = data.Status ~= "exploded" and (not holdable.Attached or data.Status == "armed" and data.Remaining > config.DisarmTime)
    if holdable.CanBePicked ~= canPick then
        holdable.CanBePicked = canPick
        Networking.CreateEntityEvent(item, Item.ChangePropertyEventData(holdable.SerializableProperties[Identifier("CanBePicked")], holdable))
    end
    local light = data.Light
    local armed = data.Status == "armed" or data.Status == "exploded"
    if light.IsOn ~= armed then
        light.IsOn = armed
        -- A property event would only say "IsOn" and clients would apply it to the first light component,
        -- which is the first music track (child components are added before the parent).
        Networking.CreateEntityEvent(item, componentEvent.__new(light, nil))
    end
    local playing = data.Status == "exploded" and #musicLengths + 1 or data.MusicPlaying and data.MusicIndex or 0
    for index, audio in ipairs(data.Audio) do
        local enabled = index == playing
        if audio.IsOn ~= enabled then audio.IsOn = enabled end
    end
    local payload
    for client, selected in pairs(sessions) do
        if selected == item then
            if nuclear.Validate(client, item) then
                payload = payload or json.encode(snapshot)
                nuclear.Send(client, item, payload)
            else
                sessions[client] = nil
            end
        end
    end
end

function nuclear.PlaySound(item, sound)
    local prefab = eventSet.GetEventPrefab(Identifier("vt_nuke_" .. sound))
    local event = prefab.CreateInstance(Game.GameSession.EventManager.RandomSeed)
    event.AddTarget(Identifier("nuke"), item)
    Game.GameSession.EventManager.ActivateEvent(event)
end

function nuclear.Disarm(item, data)
    if data.Status ~= "armed" or data.Remaining <= 0 then return end
    data.Status, data.Cooldown, data.Entered = "cooldown", config.Cooldown, ""
    data.MusicPlaying, data.MusicStarted = false, false
    data.Remaining = math.max(data.Remaining, config.MinimumTime)
    nuclear.PlaySound(item, "disarm")
    item.OwnInventory.Locked = false
    Traitormod.SelectedGamemode:OnNuclearDisarmed()
end

function nuclear.Action(client, item, action, value)
    if action == "close" then
        if sessions[client] == item then sessions[client] = nil end
        return true
    end
    if not nuclear.Validate(client, item) then return false end
    local data = bombs[item]
    local disk = item.OwnInventory.GetItemAt(0)
    local holdable = item.GetComponentString("Holdable")
    if action == "insert" and disk == nil and data.Status ~= "armed" and data.Status ~= "exploded" then
        for held in client.Character.Inventory.AllItems do
            if held.Prefab.Identifier == "vt_nuclear_disk" then
                if item.OwnInventory.TryPutItem(held, 0, false, false, client.Character, true) then
                    nuclear.PlaySound(item, "disk")
                    break
                end
            end
        end
    elseif action == "eject" and disk ~= nil and data.Status ~= "armed" and data.Status ~= "exploded" and holdable.Attached then
        if not client.Character.Inventory.TryPutItem(disk, client.Character, disk.GetComponentString("Pickable").AllowedSlots, true, false, true) then
            disk.Drop(client.Character, true)
        end
        if item.OwnInventory.GetItemAt(0) ~= disk then nuclear.PlaySound(item, "disk") end
        -- As in SS14, only an unfinished code needs the disk again; a bomb that accepted it stays ready.
        if data.Status == "code" then data.Status, data.Entered = "locked", "" end
    elseif action == "digit" and data.Status == "code" and type(value) == "string" and value:match("^%d$") and #data.Entered < 6 then
        data.Entered = data.Entered .. value
        nuclear.PlaySound(item, "key_" .. value)
    elseif action == "clear" and data.Status == "code" then
        data.Entered = ""
        nuclear.PlaySound(item, "key_clear")
    elseif action == "enter" and data.Status == "code" and Timer.GetTime() - data.LastAttempt >= 1 then
        data.LastAttempt = Timer.GetTime()
        if data.Entered == data.Code then
            data.Status = "ready"
            nuclear.PlaySound(item, "confirm")
        else
            data.Entered = ""
            nuclear.PlaySound(item, "reject")
        end
    elseif action == "code" and data.Status == "code" and type(value) == "string" and value:match("^%d%d%d%d%d%d$") then
        if Timer.GetTime() - data.LastAttempt < 1 then return false end
        data.Entered = value
        return nuclear.Action(client, item, "enter")
    elseif action == "anchor" and data.Status ~= "armed" and data.Status ~= "exploded" and item.ParentInventory == nil then
        if disk == nil then
            Traitormod.SendChatMessage(client, Traitormod.GetText("NukeAnchorNeedsDisk"))
            return false
        end
        if holdable.Attached then
            holdable.Drop(nil, false)
            Networking.CreateEntityEvent(item, componentEvent.__new(holdable, nil))
            nuclear.PlaySound(item, "detach")
        else
            local position = item.WorldPosition
            local hull = Hull.FindHull(position, item.CurrentHull)
            local safe = hull ~= nil and hull.Submarine == Submarine.MainSub
            if safe then
                local margin = config.PlacementMargin
                local diagonal = margin / math.sqrt(2)
                for _, offset in ipairs({ Vector2(margin, 0), Vector2(-margin, 0), Vector2(0, margin), Vector2(0, -margin),
                    Vector2(diagonal, diagonal), Vector2(-diagonal, diagonal), Vector2(diagonal, -diagonal), Vector2(-diagonal, -diagonal) }) do
                    local nearby = Hull.FindHull(position + offset, hull)
                    if nearby == nil or nearby.Submarine ~= Submarine.MainSub then safe = false break end
                end
            end
            if not safe then
                Traitormod.SendChatMessage(client, Traitormod.GetText("NukeUnsafePlacement"))
                return false
            end
            if not holdable.CanBeAttached(nil) then return false end
            holdable.AttachToWall()
            Networking.CreateEntityEvent(item, componentEvent.__new(holdable, nil))
            nuclear.PlaySound(item, "anchor")
        end
    elseif action == "arm" and data.Status == "ready" and disk ~= nil and holdable.Attached then
        if data.MusicIndex == 0 then
            local availableMusic = {}
            for index, length in ipairs(musicLengths) do
                if length + config.MusicStartDelay + 1 < data.Remaining then availableMusic[#availableMusic + 1] = index end
            end
            data.MusicIndex = #availableMusic > 0 and availableMusic[math.random(#availableMusic)] or 0
        end
        for _, audio in ipairs(data.Audio) do
            Networking.CreateEntityEvent(item, componentEvent.__new(audio, nil))
        end
        data.Status = "armed"
        item.OwnInventory.Locked = true
        nuclear.PlaySound(item, "confirm")
        Traitormod.SelectedGamemode:OnNuclearArmed(item, data.Remaining)
    else return false end
    if data.Status == "locked" and item.OwnInventory.GetItemAt(0) ~= nil then data.Status = "code" end
    nuclear.Update(item, data)
    return true
end

function nuclear.Think(deltaTime)
    if not active or not Game.RoundStarted then return end
    for item, data in pairs(bombs) do
        if item.Removed then bombs[item] = nil
        else
            -- OnSpawn runs before the item's spawn is sent to clients, so the rest is set up here
            if not data.Initialized then
                data.Initialized = true
                data.Audio = {}
                for component in item.Components do
                    if component.Name == "LightComponent" then
                        if component.Range == 0 then
                            table.insert(data.Audio, component)
                        else
                            data.Light = component
                        end
                    end
                end
                for _, audio in ipairs(data.Audio) do
                    Networking.CreateEntityEvent(item, componentEvent.__new(audio, nil))
                end
                local holdable = item.GetComponentString("Holdable")
                if holdable.PickingTime ~= config.DisarmTime then
                    holdable.PickingTime = config.DisarmTime
                    Networking.CreateEntityEvent(item, Item.ChangePropertyEventData(holdable.SerializableProperties[Identifier("PickingTime")], holdable))
                end
                nuclear.Update(item, data)
            end
            local previous = data.Status .. ":" .. math.ceil(data.ActivationRemaining or data.Remaining) .. ":" .. math.ceil(data.Cooldown) .. ":" .. tostring(data.MusicPlaying)
            local disk = item.OwnInventory.GetItemAt(0)
            if disk == nil then
                if data.Status == "armed" then
                    nuclear.Disarm(item, data)
                end
                if data.Status == "code" then data.Status, data.Entered = "locked", "" end
            elseif data.Status == "locked" then data.Status = "code" end
            if data.Status == "cooldown" then
                data.Cooldown = math.max(0, data.Cooldown - deltaTime)
                if data.Cooldown == 0 then data.Status = "ready" end
            elseif data.Status == "armed" then
                data.Remaining = math.max(0, data.Remaining - deltaTime)
                if data.MusicIndex > 0 and not data.MusicStarted
                    and data.Remaining <= musicLengths[data.MusicIndex] - data.MusicElapsed + 1 then
                    data.MusicStarted, data.MusicPlaying = true, true
                end
                if data.MusicPlaying then data.MusicElapsed = data.MusicElapsed + deltaTime end
                if data.Remaining <= 1 then data.MusicPlaying = false end
                if data.Remaining == 0 and data.Status == "armed" then
                    data.Status = "exploded"
                    data.ActivationRemaining = activationLength
                end
            elseif data.Status == "exploded" then
                data.ActivationRemaining = math.max(0, data.ActivationRemaining - deltaTime)
                if data.ActivationRemaining == 0 and not data.Detonated then
                    data.Detonated = true
                    local position = item.WorldPosition
                    nuclear.PlaySound(item.CurrentHull or item, "detonate")
                    Explosion(config.ExplosionRange, 100, 10000, 10000, 10000, 1).Explode(position, item)
                    if Vector2.Distance(position, Submarine.MainSub.WorldPosition) <= config.ExplosionRange then
                        Traitormod.SelectedGamemode:BeginEnding("traitors")
                    end
                    Entity.Spawner.AddEntityToRemoveQueue(item)
                end
            end
            if not item.Removed and previous ~= data.Status .. ":" .. math.ceil(data.ActivationRemaining or data.Remaining) .. ":" .. math.ceil(data.Cooldown) .. ":" .. tostring(data.MusicPlaying) then nuclear.Update(item, data) end
        end
    end
end

Networking.Receive("VoidTraitor_NuclearOpen", function(message, client)
    local item = Entity.FindEntityByID(message.ReadUInt16())
    if nuclear.Validate(client, item, true) then sessions[client] = item nuclear.Send(client, item) end
end)
Networking.Receive("VoidTraitor_NuclearAction", function(message, client)
    local item, action, value = Entity.FindEntityByID(message.ReadUInt16()), message.ReadString(), message.ReadString()
    if #action <= 16 and #value <= 6 then nuclear.Action(client, item, action, value) end
end)

Hook.Patch("Traitormod.Nuclear.Terminal", "Barotrauma.Items.Components.Terminal", "ServerEventRead", function(instance, parameters)
    if instance.Item.Prefab.Identifier ~= "vt_nuclear_bomb" then return end
    local value = parameters["msg"].ReadString()
    parameters.PreventExecution = true
    if #value <= 6 then nuclear.Action(parameters["c"], instance.Item, "code", value) end
end, Hook.HookMethodType.Before)
Hook.Patch("Traitormod.Nuclear.Buttons", "Barotrauma.Items.Components.CustomInterface", "ServerEventRead", function(instance, parameters)
    if instance.Item.Prefab.Identifier ~= "vt_nuclear_bomb" then return end
    local message = parameters["msg"]
    local insert, eject, anchor, arm = message.ReadBoolean(), message.ReadBoolean(), message.ReadBoolean(), message.ReadBoolean()
    parameters.PreventExecution = true
    if insert then nuclear.Action(parameters["c"], instance.Item, "insert")
    elseif eject then nuclear.Action(parameters["c"], instance.Item, "eject")
    elseif anchor then nuclear.Action(parameters["c"], instance.Item, "anchor")
    elseif arm then nuclear.Action(parameters["c"], instance.Item, "arm") end
end, Hook.HookMethodType.Before)
-- LMB picks up a loose bomb; an armed anchored bomb is disarmed with the game's timed pick action.
Hook.Patch("Traitormod.Nuclear.Use", "Barotrauma.Items.Components.Holdable", "Use", function(instance, parameters)
    if instance.Item.Prefab.Identifier ~= "vt_nuclear_bomb" then return end
    parameters.PreventExecution = true
    return false
end, Hook.HookMethodType.Before)
Hook.Patch("Traitormod.Nuclear.NativeAttach", "Barotrauma.Items.Components.Holdable", "ServerEventRead", function(instance, parameters)
    if instance.Item.Prefab.Identifier ~= "vt_nuclear_bomb" then return end
    local message = parameters["msg"]
    message.ReadSingle()
    message.ReadSingle()
    parameters.PreventExecution = true
end, Hook.HookMethodType.Before)
Hook.Patch("Traitormod.Nuclear.Interact", "Barotrauma.Items.Components.Holdable", "Pick", function(instance, parameters)
    if instance.Item.Prefab.Identifier ~= "vt_nuclear_bomb" then return end
    local data = bombs[instance.Item]
    if not active or data == nil or data.Status == "exploded" or data.Status == "armed" and data.Remaining <= config.DisarmTime then
        parameters.PreventExecution = true
        return false
    end
    if instance.Attached and data.Status ~= "armed" then
        parameters.PreventExecution = true
        return false
    end
end, Hook.HookMethodType.Before)
Hook.Patch("Traitormod.Nuclear.Defuse", "Barotrauma.Items.Components.Holdable", "OnPicked", { "Barotrauma.Character" }, function(instance, parameters)
    if instance.Item.Prefab.Identifier ~= "vt_nuclear_bomb" or not instance.Attached then return end
    parameters.PreventExecution = true
    local character = parameters["picker"]
    local data = bombs[instance.Item]
    if active and Game.RoundStarted and data ~= nil and data.Status == "armed"
        and data.Remaining > 0 and character ~= nil and character.IsHuman and not character.IsDead and not character.IsIncapacitated
        and not character.LockHands and character.CanInteractWith(instance.Item) then
        nuclear.Disarm(instance.Item, data)
        nuclear.Update(instance.Item, data)
    end
    return false
end, Hook.HookMethodType.Before)
Hook.Patch("Traitormod.Nuclear.Detach", "Barotrauma.Items.Components.Holdable", "CanBeDeattached", function(instance, parameters)
    local data = bombs[instance.Item]
    if data ~= nil and data.Status == "exploded" then parameters.PreventExecution = true return false end
end, Hook.HookMethodType.Before)
Hook.Add("vt_nuclear_spawn", "Traitormod.Nuclear.Spawn", function(effect, deltaTime, item)
    if active and item.Prefab.Identifier == "vt_nuclear_bomb" then nuclear.Register(item) end
end)
Hook.Add("think", "Traitormod.Nuclear.Think", nuclear.Think)
Hook.Add("roundEnd", "Traitormod.Nuclear.End", function() active, bombs, sessions = false, {}, {} end)
Hook.Add("client.disconnected", "Traitormod.Nuclear.Disconnect", function(client) sessions[client] = nil end)

Traitormod.AddCommand("!nukecode", function(client)
    if not client.HasPermission(ClientPermissions.ConsoleCommands) then return true end
    for item, data in pairs(bombs) do
        if not item.Removed then Traitormod.SendChatMessage(client, Traitormod.FormatText("NukeAdminCode", item.ID, data.Code)) end
    end
    return true
end)
return nuclear
