local cloning = {}
local componentEvent = LuaUserData.CreateStatic("Barotrauma.Item+ComponentStateEventData", true)
Traitormod.Cloning = cloning
local config = Traitormod.Config.Cloning
local prompts = require("textpromptutils")
LuaUserData.RegisterType("Barotrauma.ContentXElement")
local contentElement = LuaUserData.CreateStatic("Barotrauma.ContentXElement")
local state

function cloning.Start()
    state = { Consoles = {}, Labels = {}, Scanners = {}, Pods = {}, Jobs = {}, Owners = {}, Reclaimed = {}, Pending = {}, ReconnectCheck = 0, Elapsed = 0 }
    for _, client in pairs(Client.ClientList) do
        if client.Character ~= nil then state.Owners[client.Character] = client end
    end
    for item in Item.ItemList do
        if item.Prefab.Identifier == "vt_cloning_console" then
            state.Consoles[#state.Consoles + 1] = item
            local labels = {}
            for component in item.Components do
                if LuaUserData.IsTargetType(component, "Barotrauma.Items.Components.ItemLabel") then
                    labels[#labels + 1] = component
                end
            end
            if #labels == 2 then
                state.Labels[item] = labels
            else
                Traitormod.Error("Cloning console requires two ItemLabel components")
            end
        end
        if item.Prefab.Identifier == "vt_cloning_scanner" then state.Scanners[item] = true end
        if item.Prefab.Identifier == "vt_cloning_pod" then state.Pods[item] = { Biomass = 0, Consumed = {} } end
    end
end

function cloning.Devices(console)
    local scanner, pod
    for connection in console.Connections do
        for recipient in connection.Recipients do
            local item = recipient.Item
            if connection.Name == "scanner" and item.Prefab.Identifier == "vt_cloning_scanner" then scanner = item end
            if connection.Name == "pod" and item.Prefab.Identifier == "vt_cloning_pod" then pod = item end
        end
    end
    local material = scanner ~= nil and scanner.OwnInventory.GetItemAt(0) or nil
    local linked = material ~= nil and material.GetComponentString("LinkedControllerCharacterComponent") or nil
    return scanner, pod, linked ~= nil and linked.Character or nil
end

function cloning.Status(console)
    local scanner, pod, corpse = cloning.Devices(console)
    if scanner == nil or pod == nil or scanner.Removed or pod.Removed or pod.Condition <= 0 or state.Pods[pod] == nil then return "CloneDisconnected", 0 end
    if not console.GetComponentString("Powered").HasPower then return "CloneNoPower", 0 end
    local job = state.Jobs[pod]
    if job ~= nil then
        return pod.GetComponentString("Powered").HasPower and "CloneGrowing" or "ClonePaused", math.floor(job.Progress / config.Time * 100)
    end
    if corpse == nil or corpse.Removed then return "CloneEmpty", 0 end
    if not corpse.IsDead then return "CloneAlive", 0 end
    if not pod.GetComponentString("Powered").HasPower then return "CloneNoPower", 0 end
    local cost = corpse.IsHuman and config.HumanBiomassCost or math.max(1, math.ceil(corpse.Mass * config.HumanBiomassCost / 80))
    if state.Pods[pod].Biomass < cost then return "CloneNoBiomass", 0, cost end
    return "CloneReady", 0
end

local function offerClone(client, job)
    if job.Account == nil or job.Declined or job.Accepted or state.Pending[client] == job
        or (client.Character ~= nil and not client.Character.IsDead) then return false end
    state.Pending[client] = job
    if Traitormod.Pointshop.GuiClients[client] then
        prompts.Prompt(Traitormod.GetText("CloneConsent"), { Traitormod.GetText("CloneAccept"), Traitormod.GetText("CloneDecline") }, client, function(index, response)
            if response == client and state ~= nil and state.Pending[client] == job then cloning.Answer(client, index == 1) end
        end, "InfoFrameTabButton.Mission")
    else
        Traitormod.SendChatMessage(client, Traitormod.GetText("CloneConsentChat"))
    end
    return true
end

function cloning.Begin(client, console)
    if state == nil or not Game.RoundStarted or console.Removed
        or client.Character == nil or client.Character.IsDead or client.Character.IsIncapacitated
        or client.Character.SelectedItem ~= console or not console.CanClientAccess(client) then return false end
    local status = cloning.Status(console)
    if status ~= "CloneReady" then return false end
    local _, pod, corpse = cloning.Devices(console)
    for _, job in pairs(state.Jobs) do if job.Corpse == corpse then return false end end
    local info
    if corpse.Info ~= nil then
        info = CharacterInfo(contentElement.__new(nil, corpse.Info.Save(nil)))
        info.PermanentlyDead, info.StartItemsGiven = false, true
    end
    local clone = Character.Create(corpse.SpeciesName.Value, pod.WorldPosition, tostring(math.random(1, 100000)), info,
        UShort(0), false, true, true, nil, true, false)
    local unkillable = clone.Unkillable
    clone.TeamID, clone.Enabled, clone.Unkillable = corpse.TeamID, true, true
    Traitormod.GhostRoles.ExcludedCharacters[clone] = true
    if clone.AIController ~= nil then clone.AIController.Enabled = false end
    if info ~= nil then clone.LoadTalents() end
    clone.CharacterHealth.Stun = 2
    pod.GetComponentString("Controller").Select(clone)
    clone.SelectedItem = pod
    pod.GetComponentString("LightComponent").IsOn = true
    local previousOwner = state.Owners[corpse]
    if previousOwner ~= nil then Traitormod.SelectedGamemode:HidePlayerFromCrew(clone) end
    local job = { Pod = pod, Corpse = corpse, Clone = clone, Progress = 0, Account = previousOwner ~= nil and Traitormod.GetClientAccountKey(previousOwner) or nil, Unkillable = unkillable }
    state.Jobs[pod] = job
    state.Pods[pod].Biomass = state.Pods[pod].Biomass - (corpse.IsHuman and config.HumanBiomassCost or math.max(1, math.ceil(corpse.Mass * config.HumanBiomassCost / 80)))
    local ownerConnected = false
    for _, client in pairs(Client.ClientList) do
        if client == previousOwner then
            ownerConnected = true
            break
        end
    end
    for _, owner in pairs(Client.ClientList) do
        if (owner == previousOwner or (not ownerConnected and Traitormod.GetClientAccountKey(owner) == job.Account))
            and (owner.Character == nil or owner.Character.IsDead) then
            offerClone(owner, job)
            break
        end
    end
    return true
end

function cloning.Answer(client, accept)
    local job = state ~= nil and state.Pending[client] or nil
    if job == nil then return false end
    state.Pending[client] = nil
    if not accept then job.Declined = true return true end
    if not Game.RoundStarted or job.Clone.Removed or job.Clone.IsDead
        or Traitormod.GetClientAccountKey(client) ~= job.Account
        or (client.Character ~= nil and not client.Character.IsDead) then return false end
    for _, owner in pairs(Client.ClientList) do
        if owner.Character == job.Clone then return false end
    end
    local role = Traitormod.RoleManager.GetRole(job.Corpse)
    if role ~= nil and role.Name == "HuskServant" then
        Traitormod.RoleManager.RemoveRole(job.Corpse)
        if job.Clone.IsHuman then
            Traitormod.RoleManager.AssignRole(job.Clone, Traitormod.RoleManager.Roles.Crew:new())
            role = Traitormod.RoleManager.GetRole(job.Clone)
        else
            role = nil
        end
    elseif role ~= nil then
        Traitormod.RoleManager.TransferRole(job.Clone, role)
    end
    client.SetClientCharacter(job.Clone)
    job.Accepted = true
    if role ~= nil then
        Traitormod.ObjectiveHud.SyncRole(role)
        if role.SyncClientState ~= nil then role:SyncClientState(client) end
        if role.IsAntagonist then Traitormod.UpdateVanillaTraitor(client, true, role:Greet()) end
    end
    Traitormod.MidRoundSpawn.SetSpawnedClient(client, job.Clone)
    state.Owners[job.Clone] = client
    return true
end

local function storeBiomass(pod, data)
    for item in pod.OwnInventory.AllItems do
        if item.Prefab.Identifier == "vt_biomass" and not data.Consumed[item] then
            data.Consumed[item] = true
            data.Biomass = data.Biomass + 1
            Entity.Spawner.AddEntityToRemoveQueue(item)
        end
    end
end

function cloning.Update(deltaTime)
    if state == nil or not Game.RoundStarted then return end
    state.Elapsed = state.Elapsed + deltaTime
    if state.Elapsed < 0.5 then return end
    deltaTime, state.Elapsed = state.Elapsed, 0
    for pod, data in pairs(state.Pods) do
        if not pod.Removed then
            for item in pairs(data.Consumed) do if item.Removed then data.Consumed[item] = nil end end
            storeBiomass(pod, data)
        end
    end
    for scanner in pairs(state.Scanners) do
        if not scanner.Removed then
            local controller = scanner.GetComponentString("Controller")
            if controller ~= nil and controller.User ~= nil and not controller.User.IsDead then
                local user = controller.User
                if user.SelectedCharacter ~= nil then user.DeselectCharacter() end
                controller.Select(user)
            end
        end
    end
    state.ReconnectCheck = state.ReconnectCheck - deltaTime
    local checkOwners = state.ReconnectCheck <= 0
    if checkOwners then state.ReconnectCheck = 1 end
    for pod, job in pairs(state.Jobs) do
        if checkOwners and not job.Accepted and not job.Declined and job.Account ~= nil then
            for _, owner in pairs(Client.ClientList) do
                if owner.InGame ~= false and Traitormod.GetClientAccountKey(owner) == job.Account then
                    offerClone(owner, job)
                    break
                end
            end
        end
        if pod.Removed or pod.Condition <= 0 or job.Clone.Removed or job.Clone.IsDead then
            if not job.Clone.Removed then
                job.Clone.Unkillable = false
                job.Clone.Kill(CauseOfDeathType.Unknown, nil)
                Entity.Spawner.AddEntityToRemoveQueue(job.Clone)
            end
            if not pod.Removed then pod.GetComponentString("LightComponent").IsOn = false end
            state.Jobs[pod] = nil
            for client, pending in pairs(state.Pending) do
                if pending == job then state.Pending[client] = nil end
            end
        else
            job.Clone.CharacterHealth.Stun = 2
            if pod.GetComponentString("Powered").HasPower then job.Progress = job.Progress + deltaTime end
            if job.Progress >= config.Time then
                job.Clone.Unkillable = job.Unkillable
                job.Clone.CharacterHealth.Stun = 0
                job.Clone.SelectedItem = nil
                job.Clone.TeleportTo(pod.WorldPosition + Vector2(pod.Rect.Width / 2 + 60, 0))
                if not job.Corpse.IsPlayer and job.Clone.AIController ~= nil then job.Clone.AIController.Enabled = true end
                pod.GetComponentString("LightComponent").IsOn = false
                state.Jobs[pod] = nil
                for client, pending in pairs(state.Pending) do
                    if pending == job then state.Pending[client] = nil end
                end
            end
        end
    end
    for _, console in ipairs(state.Consoles) do
        if not console.Removed then
            local status, percent, cost = cloning.Status(console)
            local labels = state.Labels[console]
            if labels ~= nil then
                local statusText = cost ~= nil and Traitormod.FormatText(status, cost) or Traitormod.GetText(status)
                local progressText = Traitormod.FormatText("CloneProgress", percent)
                if labels[1].Text ~= statusText then
                    labels[1].Text = statusText
                    Networking.CreateEntityEvent(console, componentEvent.__new(labels[1], nil))
                end
                if labels[2].Text ~= progressText then
                    labels[2].Text = progressText
                    Networking.CreateEntityEvent(console, componentEvent.__new(labels[2], nil))
                end
            end
        end
    end
end

Hook.Add("characterDeath", "Traitormod.Cloning.Owner", function(character)
    if state == nil then return end
    local client = Traitormod.FindClientCharacter(character)
    if client ~= nil then state.Owners[character] = client end
end)
Hook.Patch("Traitormod.Cloning.Terminal", "Barotrauma.Items.Components.CustomInterface", "ServerEventRead", function(instance, parameters)
    local item = instance.Item
    local identifier = item.Prefab.Identifier
    if identifier ~= "vt_cloning_console" and identifier ~= "vt_cloning_scanner" and identifier ~= "vt_cloning_pod" then return end
    local pressed = parameters["msg"].ReadBoolean()
    parameters.PreventExecution = true
    if identifier == "vt_cloning_pod" then
        local client = parameters["c"]
        if not pressed or state == nil or not Game.RoundStarted
            or client == nil or client.Character == nil or client.Character.IsDead
            or client.Character.SelectedItem ~= item or not item.CanClientAccess(client) then return end
        local data = state.Pods[item]
        if data == nil then return end
        storeBiomass(item, data)
        if data.Biomass == 0 then return end
        local amount = data.Biomass
        data.Biomass = 0
        for _ = 1, amount do
            Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab("vt_biomass"), client.Character.Inventory)
        end
    elseif identifier == "vt_cloning_console" then
        if pressed then cloning.Begin(parameters["c"], item) end
    elseif pressed and state ~= nil then
        local client = parameters["c"]
        if client ~= nil and client.Character ~= nil and not client.Character.IsDead
            and client.Character.SelectedItem == item and item.CanClientAccess(client) then
            local controller = item.GetComponentString("Controller")
            if controller.User ~= nil then
                client.Character.DeselectCharacter()
                controller.Select(client.Character)
            end
        end
    end
end, Hook.HookMethodType.Before)
Hook.Patch("Traitormod.Cloning.Biomass", "Barotrauma.Items.Components.Deconstructor", "ApplyDeconstructionStatusEffects", function(instance, parameters)
    if state == nil or instance.Item.Prefab.Identifier ~= "vt_biomass_reclaimer" or parameters["type"] ~= ActionType.OnDeconstructed then return end
    local linked = parameters["targetItem"].GetComponentString("LinkedControllerCharacterComponent")
    local corpse = linked ~= nil and linked.Character or nil
    if corpse == nil or corpse.Removed or not corpse.IsDead or state.Reclaimed[corpse] then return end
    state.Reclaimed[corpse] = true
    local amount = corpse.IsHuman and config.HumanBiomassYield or math.max(5, math.min(58, math.floor(corpse.Mass * config.HumanBiomassYield / 80)))
    for _ = 1, amount do
        Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab("vt_biomass"), instance.OutputContainer.Inventory)
    end
end, Hook.HookMethodType.Before)
Hook.Patch("Traitormod.Cloning.DeadOnly", "Barotrauma.Items.Components.Controller", "Select", function(instance, parameters)
    local identifier = instance.Item.Prefab.Identifier
    if identifier ~= "vt_cloning_scanner" and identifier ~= "vt_biomass_reclaimer" then return end
    local character = parameters["activator"]
    if character == nil then return end
    if identifier == "vt_cloning_scanner" and instance.User == character then return end
    local selected = character.SelectedCharacter
    if selected ~= nil and not selected.IsDead then
        parameters.PreventExecution = true
    elseif selected ~= nil and selected == instance.User then
        character.DeselectCharacter()
    end
end, Hook.HookMethodType.Before)
Hook.Add("think", "Traitormod.Cloning.Update", cloning.Update)
Hook.Add("roundEnd", "Traitormod.Cloning.End", function() state = nil end)
Hook.Add("client.disconnected", "Traitormod.Cloning.Disconnect", function(client)
    if state == nil then return end
    if client.Character ~= nil then state.Owners[client.Character] = client end
    state.Pending[client] = nil
end)
Traitormod.AddCommand("!y", function(client) Traitormod.Cloning.Answer(client, true) return true end)
Traitormod.AddCommand("!n", function(client) Traitormod.Cloning.Answer(client, false) return true end)

return cloning
