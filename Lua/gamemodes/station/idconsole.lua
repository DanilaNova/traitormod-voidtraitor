local console = {}
Traitormod.IdConsole = console
console.Config = Traitormod.Config.IdConsole
for _, preset in ipairs(console.Config.Presets) do
    if preset.AllAccess then
        preset.Tags = {}
        for _, entry in ipairs(console.Config.Access) do
            preset.Tags[#preset.Tags + 1] = entry.Tag
        end
    end
end
local json = require("json")
local prompts = require("textpromptutils")
local sessions = {}
local removeEvent = LuaUserData.CreateStatic("Barotrauma.EntitySpawner+RemoveEntity", true)
local spawnEvent = LuaUserData.CreateStatic("Barotrauma.EntitySpawner+SpawnEntity", true)
local interfaceEvent = LuaUserData.CreateStatic("Barotrauma.Item+ComponentStateEventData", true)
local eventSet = LuaUserData.CreateStatic("Barotrauma.EventSet", true)

local function playCardSound(item, action)
    local prefab = eventSet.GetEventPrefab(Identifier(action == "insert" and "vt_idcard_insert" or "vt_idcard_eject"))
    if prefab == nil then return end
    local event = prefab.CreateInstance(Game.GameSession.EventManager.RandomSeed)
    event.AddTarget(Identifier("idconsole"), item)
    Game.GameSession.EventManager.ActivateEvent(event)
end

local known = {}
for _, entry in ipairs(console.Config.Access) do known[entry.Tag] = true end

function console.Validate(client, item, allowUnselected)
    return Game.RoundStarted
        and client ~= nil and client.Character ~= nil and not client.Character.IsDead
        and not client.Character.IsIncapacitated and client.Character.IsHuman
        and item ~= nil and (client.Character.SelectedItem == item or allowUnselected == true) and not item.Removed
        and item.Prefab.Identifier == "vt_station_access" and item.CanClientAccess(client)
end

function console.Revision(item)
    local parts = {}
    for slot = 0, 1 do
        local card = item.OwnInventory.GetItemAt(slot)
        local info = card ~= nil and card.GetComponentString("IdCard") or nil
        parts[#parts + 1] = info ~= nil and { card.ID, card.Tags, info.OwnerName, info.OwnerJobId.Value, card.Description } or {}
    end
    return json.encode(parts)
end

function console.Sync(card, entity, property)
    Networking.CreateEntityEvent(card, Item.ChangePropertyEventData(entity.SerializableProperties[Identifier(property)], entity))
end

function console.Apply(client, item, payload)
    if not console.Validate(client, item) then return false end
    local auth, target = item.OwnInventory.GetItemAt(0), item.OwnInventory.GetItemAt(1)
    if auth == nil or target == nil or auth == target or auth.GetComponentString("IdCard") == nil
        or target.GetComponentString("IdCard") == nil then return false end
    if payload.Revision ~= console.Revision(item) then return false, "IdConsoleChanged" end
    local desired = {}
    if type(payload.Tags) ~= "table" or #payload.Tags > #console.Config.Access then return false end
    for _, tag in ipairs(payload.Tags) do
        if not known[tag] then return false end
        desired[tag] = true
    end
    for _, entry in ipairs(console.Config.Access) do
        if target.HasTag(entry.Tag) ~= (desired[entry.Tag] == true) and not auth.HasTag(entry.Tag) then return false end
    end
    local info = target.GetComponentString("IdCard")
    local name, title = payload.Name, payload.Title
    for _, value in pairs({ name, title }) do
        if type(value) ~= "string" or #value > 192 or value:find("[,;%c]") then return false end
    end
    local preset
    if payload.Job ~= nil then
        for _, entry in ipairs(console.Config.Presets) do
            if entry.Id == payload.Job then
                preset = entry
                break
            end
        end
        if preset == nil or (preset.JobId ~= nil and not JobPrefab.Prefabs.ContainsKey(preset.JobId)) then return false end
    end
    local replace = (name ~= nil and name ~= info.OwnerName) or (title ~= nil and title ~= console.CardTitle(target))
        or (preset ~= nil and preset.JobId ~= nil and preset.JobId ~= info.OwnerJobId.Value)
    if replace then
        -- An unsent refresh for this card has to go out first, otherwise the event queue
        -- can merge the events and drop the new state.
        for event in Game.Server.EntityEventManager.Events do
            if not event.Sent and (event.Entity == target or (event.Entity == Entity.Spawner
                and LuaUserData.IsTargetType(event.Data, "Barotrauma.EntitySpawner+SpawnEntity")
                and event.Data.Entity == target)) then return false, "IdConsoleSyncing" end
        end
    end
    for _, entry in ipairs(console.Config.Access) do
        if desired[entry.Tag] then target.AddTag(entry.Tag) else target.RemoveTag(Identifier(entry.Tag)) end
    end
    local remove = {}
    local storedTitle
    for tag in target.GetTags() do
        local value = tag.Value
        if value:sub(1, 12) == "vt_jobtitle:" then storedTitle = value:sub(13) end
        if (name ~= nil and value:sub(1, 5) == "name:") or (title ~= nil and value:sub(1, 12) == "vt_jobtitle:")
            or (preset ~= nil and preset.JobId ~= nil and value:sub(1, 6) == "jobid:") then remove[#remove + 1] = tag end
    end
    for _, tag in ipairs(remove) do target.RemoveTag(tag) end
    if name ~= nil then
        info.OwnerName = name
        target.AddTag("name:" .. name)
    end
    if title ~= nil then target.AddTag("vt_jobtitle:" .. title) end
    if preset ~= nil and preset.JobId ~= nil then
        info.OwnerJobId = Identifier(preset.JobId)
        target.AddTag("jobid:" .. preset.JobId)
    end
    if replace and (name ~= nil or title ~= nil) then
        target.Description = title or storedTitle or ""
        info.Description = target.Description
    end
    if replace then
        -- Clients get the card's name and look only in its spawn data, so respawn it on their side.
        -- The server item, its ID and objective references stay the same.
        Entity.Spawner.CreateNetworkEvent(removeEvent(target))
        Entity.Spawner.CreateNetworkEvent(spawnEvent(target))
        target.CreateStatusEvent(true)
    else console.Sync(target, target, "Tags") end
    return true
end

function console.CardTitle(card)
    for tag in card.GetTags() do
        if tag.Value:sub(1, 12) == "vt_jobtitle:" then return tag.Value:sub(13) end
    end
    local job = card.GetComponentString("IdCard").OwnerJob
    return job ~= nil and job.Name.Value or ""
end

function console.Snapshot(client, item)
    local snapshot = { Revision = console.Revision(item), Slots = {}, HeldCards = {}, Access = {}, Presets = {}, Text = {} }
    for _, key in ipairs({ "Title", "Auth", "Target", "Empty", "Insert", "Eject", "Choose", "Ready", "Missing", "Name", "Job", "Save", "Preset", "All", "Clear", "Confirm", "Reset", "Apply", "Close", "NoRights", "Forbidden" }) do
        snapshot.Text[key] = Traitormod.GetText("IdConsole" .. key)
    end
    local auth, target = item.OwnInventory.GetItemAt(0), item.OwnInventory.GetItemAt(1)
    snapshot.CanEdit = auth ~= nil and target ~= nil and auth.GetComponentString("IdCard") ~= nil and target.GetComponentString("IdCard") ~= nil
    for slot = 0, 1 do
        local card = item.OwnInventory.GetItemAt(slot)
        local info = card ~= nil and card.GetComponentString("IdCard") or nil
        local rights = {}
        for _, entry in ipairs(console.Config.Access) do if card ~= nil and card.HasTag(entry.Tag) then rights[#rights + 1] = Traitormod.GetText(entry.Name) end end
        snapshot.Slots[#snapshot.Slots + 1] = { Slot = slot, Id = card ~= nil and card.ID or 0,
            Name = info ~= nil and info.OwnerName or snapshot.Text.Empty, Title = info ~= nil and console.CardTitle(card) or "", Access = table.concat(rights, ", ") }
    end
    for index = 0, client.Character.Inventory.Capacity - 1 do
        local card = client.Character.Inventory.GetItemAt(index)
        local info = card ~= nil and card.GetComponentString("IdCard") or nil
        if info ~= nil then snapshot.HeldCards[#snapshot.HeldCards + 1] = { Id = card.ID, Name = info.OwnerName ~= "" and info.OwnerName or card.Name } end
    end
    for _, entry in ipairs(console.Config.Access) do
        snapshot.Access[#snapshot.Access + 1] = { Tag = entry.Tag, Name = Traitormod.GetText(entry.Name),
            Allowed = snapshot.CanEdit and auth.HasTag(entry.Tag), Granted = target ~= nil and target.HasTag(entry.Tag) }
    end
    for _, entry in ipairs(console.Config.Presets) do
        local job = JobPrefab.Prefabs.ContainsKey(entry.Id) and JobPrefab.Get(entry.Id) or nil
        snapshot.Presets[#snapshot.Presets + 1] = { Id = entry.Id, Name = entry.Name ~= nil and Traitormod.GetText(entry.Name) or (job ~= nil and job.Name.Value or entry.Id), Tags = entry.Tags }
    end
    return snapshot
end

function console.Send(client)
    local session = sessions[client]
    if session == nil or not console.Validate(client, session.Item, session.Gui) then return end
    local snapshot = console.Snapshot(client, session.Item)
    session.Revision = snapshot.Revision
    local terminal = session.Item.GetComponentString("Terminal")
    local lines = {}
    for index, slot in ipairs(snapshot.Slots) do
        lines[#lines + 1] = (index == 1 and snapshot.Text.Auth or snapshot.Text.Target) .. ": " .. slot.Name .. "\n" .. slot.Title .. "\n" .. slot.Access
    end
    lines[#lines + 1] = snapshot.CanEdit and snapshot.Text.Ready or snapshot.Text.Missing
    local body = table.concat(lines, "\n\n")
    if not session.Gui then body = body .. "\n" .. Traitormod.GetText("IdConsoleNativeIdentity") end
    if terminal.ShowMessage ~= body then
        terminal.ShowMessage = body
        terminal.SyncHistory()
    end
    local interface = session.Item.GetComponentString("CustomInterface")
    local signals = snapshot.Slots[2].Name .. ";" .. snapshot.Slots[2].Title .. ";1;1"
    if not session.Gui and interface.Signals ~= signals then
        interface.Signals = signals
        Networking.CreateEntityEvent(session.Item, interfaceEvent(interface, nil))
    end
    if session.Gui then
        local message = Networking.Start("VoidTraitor_IdConsoleSnapshot")
        message.WriteUInt16(UShort(session.Item.ID))
        message.WriteString(json.encode(snapshot))
        Networking.Send(message, client.Connection, DeliveryMethod.Reliable)
        return
    end
    local buttons = {}
    for index, slot in ipairs(snapshot.Slots) do
        if session.View == "main" then
            buttons[#buttons + 1] = { Label = (slot.Id == 0 and snapshot.Text.Insert or snapshot.Text.Eject) .. " — " .. (index == 1 and snapshot.Text.Auth or snapshot.Text.Target),
                Action = slot.Id == 0 and "choose" or "eject", Payload = { Slot = slot.Slot, Card = slot.Id } }
        end
    end
    if session.View == "choose" then
        for _, card in ipairs(snapshot.HeldCards) do buttons[#buttons + 1] = { Label = card.Name, Action = "insert", Payload = { Slot = session.Slot, Card = card.Id } } end
    elseif snapshot.CanEdit then
        if session.View == "presets" then
            for _, preset in ipairs(snapshot.Presets) do buttons[#buttons + 1] = { Label = preset.Name, Action = "preset", Payload = { Job = preset.Id, Revision = snapshot.Revision } } end
        elseif session.View == "grant" or session.View == "revoke" then
            for _, entry in ipairs(snapshot.Access) do
                if entry.Allowed then buttons[#buttons + 1] = { Label = entry.Name, Action = "toggle", Payload = { Tag = entry.Tag, Granted = session.View == "grant", Revision = snapshot.Revision } } end
            end
        elseif session.View == "clear" then
            buttons[#buttons + 1] = { Label = snapshot.Text.Confirm, Action = "clear_all", Payload = { Revision = snapshot.Revision } }
        else
            for _, action in ipairs({ "presets", "grant", "revoke", "clear" }) do
                buttons[#buttons + 1] = { Label = Traitormod.GetText(({presets="IdConsolePresets",grant="IdConsoleGrant",revoke="IdConsoleRevoke",clear="IdConsoleClear"})[action]), Action = "view", Payload = { View = action } }
            end
        end
    end
    buttons[#buttons + 1] = { Label = Traitormod.GetText(session.View == "main" and "IdConsoleRefresh" or "IdConsoleBack"), Action = "view", Payload = { View = "main" } }
    buttons[#buttons + 1] = { Label = snapshot.Text.Close, Action = "close", Payload = {} }
    local options = {}
    for _, button in ipairs(buttons) do options[#options + 1] = button.Label end
    session.Prompt = {}
    local prompt = session.Prompt
    prompts.Prompt(snapshot.Text.Title .. "\n\n" .. Traitormod.GetText("IdConsoleNativeActions"), options, client, function(index, responseClient)
        if responseClient ~= client or sessions[client] ~= session or session.Prompt ~= prompt then return end
        local button = buttons[index]
        if button ~= nil then console.Action(client, session.Item, button.Action, button.Payload) end
    end, "InfoFrameTabButton.Mission")
end

function console.Open(client, item, gui)
    -- The GUI request can arrive before the server sees the console selected, so opening doesn't
    -- require the selection; actions are validated again with it.
    if not console.Validate(client, item, gui == true) then return false end
    sessions[client] = { Item = item, View = "main", Gui = gui == true }
    console.Send(client)
    return true
end

function console.Action(client, item, action, payload)
    local session = sessions[client]
    if session == nil or session.Item ~= item then return false end
    if action == "close" then
        -- players without the GUI close the dialog to type into the console's text fields, so keep their session
        if session.Gui then sessions[client] = nil else session.Prompt = nil end
        return true
    end
    if not console.Validate(client, item) then return false end
    local accepted, reason = true, nil
    if action == "choose" then
        if payload.Slot ~= 0 and payload.Slot ~= 1 then return false end
        session.View, session.Slot = "choose", payload.Slot
    elseif action == "view" then
        if payload.View ~= "main" and payload.View ~= "presets" and payload.View ~= "grant" and payload.View ~= "revoke" and payload.View ~= "clear" then return false end
        session.View = payload.View
    elseif action == "insert" or action == "eject" then
        if payload.Slot ~= 0 and payload.Slot ~= 1 then return false end
        local card = item.OwnInventory.GetItemAt(payload.Slot)
        local character = client.Character
        if action == "insert" then
            if card ~= nil then return false end
            for index = 0, character.Inventory.Capacity - 1 do
                local held = character.Inventory.GetItemAt(index)
                if held ~= nil and held.ID == payload.Card and held.GetComponentString("IdCard") ~= nil then card = held break end
            end
            accepted = card ~= nil and item.OwnInventory.TryPutItem(card, payload.Slot, false, false, character, true)
        else
            accepted = card ~= nil and card.ID == payload.Card
            if accepted and not character.Inventory.TryPutItem(card, character, { InvSlotType.Any }, true) then card.Drop(character, true) end
        end
        if accepted then playCardSound(item, action) end
        session.View = "main"
    elseif action == "apply" then
        accepted, reason = console.Apply(client, item, payload)
    elseif action == "preset" or action == "toggle" or action == "clear_all" then
        local snapshot = console.Snapshot(client, item)
        local desired, selected = {}, nil
        if action == "preset" then
            for _, preset in ipairs(snapshot.Presets) do
                if preset.Id == payload.Job then
                    selected = preset
                    break
                end
            end
            if selected == nil then return false end
        end
        for _, entry in ipairs(snapshot.Access) do
            local granted = entry.Granted
            if entry.Allowed then
                if action == "clear_all" then granted = false
                elseif action == "toggle" and entry.Tag == payload.Tag then granted = payload.Granted == true
                elseif selected ~= nil then
                    granted = false
                    for _, tag in ipairs(selected.Tags) do
                        if tag == entry.Tag then granted = true end
                    end
                end
            end
            if granted then desired[#desired + 1] = entry.Tag end
        end
        accepted, reason = console.Apply(client, item, { Tags = desired, Revision = payload.Revision, Job = selected ~= nil and selected.Id or nil, Title = selected ~= nil and selected.Name or nil })
        session.View = "main"
    else return false end
    if not accepted then Traitormod.SendChatMessage(client, Traitormod.GetText(reason or "IdConsoleRejected")) end
    console.Send(client)
    for other, otherSession in pairs(sessions) do
        if other ~= client and otherSession.Item == item and otherSession.Gui then console.Send(other) end
    end
    return accepted
end

Networking.Receive("VoidTraitor_IdConsoleOpen", function(message, client)
    console.Open(client, Entity.FindEntityByID(message.ReadUInt16()), true)
end)
Networking.Receive("VoidTraitor_IdConsoleAction", function(message, client)
    local item, action, text = Entity.FindEntityByID(message.ReadUInt16()), message.ReadString(), message.ReadString()
    if #action > 24 or #text > 8192 then return end
    local ok, payload = pcall(json.decode, text)
    if ok and type(payload) == "table" then console.Action(client, item, action, payload) end
end)

-- The console's packet carries two text fields and two buttons, in XML order.
-- None of the generic CustomInterface handling is applied to the ID card.
Hook.Patch("Traitormod.IdConsole.Native", "Barotrauma.Items.Components.CustomInterface", "ServerEventRead", function(instance, parameters)
    local item, client = instance.Item, parameters["c"]
    if item.Prefab.Identifier ~= "vt_station_access" then return end
    local message = parameters["msg"]
    local name, title, menu, save = message.ReadString(), message.ReadString(), message.ReadBoolean(), message.ReadBoolean()
    parameters.PreventExecution = true
    if not console.Validate(client, item) then return end
    if menu then console.Open(client, item, false)
    elseif save then
        local snapshot = console.Snapshot(client, item)
        local tags = {}
        for _, entry in ipairs(snapshot.Access) do
            if entry.Granted then tags[#tags + 1] = entry.Tag end
        end
        local session = sessions[client]
        local accepted, reason
        if session ~= nil and session.Item == item then
            accepted, reason = console.Apply(client, item, { Revision = session.Revision, Tags = tags, Name = name, Title = title })
        end
        if not accepted then Traitormod.SendChatMessage(client, Traitormod.GetText(reason or "IdConsoleRejected")) end
        console.Open(client, item, false)
    end
end, Hook.HookMethodType.Before)

function console.InitializeCard(character, passenger)
    if character.Inventory == nil or character.Info == nil or character.Info.Job == nil then return end
    local card = character.Inventory.GetItemInLimbSlot(InvSlotType.Card)
    if card == nil or card.HasTag("vt_station_card_initialized") then return end
    if passenger then
        local remove = {}
        for tag in card.GetTags() do
            if tag.Value:sub(1, 5) ~= "name:"
                and tag.Value:sub(1, 6) ~= "jobid:" then
                remove[#remove + 1] = tag
            end
        end
        for _, tag in ipairs(remove) do
            card.RemoveTag(tag)
        end
    else
        for _, preset in ipairs(console.Config.Presets) do
            if preset.Id == character.Info.Job.Prefab.Identifier.Value then
                for _, tag in ipairs(preset.Tags) do card.AddTag(tag) end
                break
            end
        end
    end
    if character.Info.Job.Prefab.Identifier.Value == "captain" then
        card.AddTag("vt_station_original_captain_id")
    end
    card.AddTag("vt_station_card_initialized")
    console.Sync(card, card, "Tags")
end

Hook.Add("roundEnd", "Traitormod.IdConsole.End", function() sessions = {} end)
Hook.Add("client.disconnected", "Traitormod.IdConsole.Disconnect", function(client) sessions[client] = nil end)
return console
