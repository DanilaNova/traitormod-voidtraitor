---@class RescueEventConfig
---@field Name string
---@field PirateEvent string
---@field Message string
---@field GhostRole string
---@field HookName string
---@field SpawnSonar boolean
---@field CanStart fun(): boolean
---@field GetSubmarine fun(): any

local eventNPC = dofile(Traitormod.Path .. "/Lua/config/randomevents/utility/eventnpc.lua")

---@param config RescueEventConfig
---@return table
local function CreateRescueEvent(config)
    local event = {}

    event.Name = config.Name
    event.MinRoundTime = 2
    event.MaxRoundTime = 15
    event.MinIntensity = 0
    event.MaxIntensity = 1
    event.ChancePerMinute = 0.12
    event.OnlyOncePerRound = true
    event.AmountPoints = 1000

    local function reservePirateEvent()
        if Traitormod.RoundEvents.ThisRoundEvents[config.PirateEvent] == nil then
            Traitormod.RoundEvents.ThisRoundEvents[config.PirateEvent] = 0
        end
    end

    local function spawnItem(identifier, inventory, onSpawned)
        local prefab = ItemPrefab.GetItemPrefab(identifier)
        if prefab == nil then
            return
        end

        Entity.Spawner.AddItemToSpawnQueue(prefab, inventory, nil, nil, onSpawned)
    end

    local function equipSurvivalSuit(character)
        local oldSuit = character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes)
        if oldSuit ~= nil then
            oldSuit.Drop()
            Entity.Spawner.AddEntityToRemoveQueue(oldSuit)
        end

        spawnItem("divingsuit", character.Inventory, function(item)
            local slot = character.Inventory.FindLimbSlot(InvSlotType.OuterClothes)
            character.Inventory.TryPutItem(item, slot, true, false, character)
            spawnItem("oxygenitetank", item.OwnInventory)
        end)
    end

    local function giveWeakSurvivalSupplies(character)
        spawnItem("underwaterscooter", character.Inventory, function(item)
            spawnItem("batterycell", item.OwnInventory)
        end)

        spawnItem("handheldsonar", character.Inventory, function(item)
            spawnItem("batterycell", item.OwnInventory)
        end)

        spawnItem("antibleeding1", character.Inventory)
        spawnItem("antibleeding1", character.Inventory)
        spawnItem("antibiotics", character.Inventory)
        spawnItem("ringerssolution", character.Inventory)
    end

    local function awardCrew()
        Traitormod.RoundEvents.SendEventMessage(string.format(Traitormod.Language.RescueSuccess, event.AmountPoints), "CrewWalletIconLarge")

        for _, client in pairs(Client.ClientList) do
            if client.Character
                and not client.Character.IsDead
                and client.Character.TeamID == CharacterTeamType.Team1
                and not Traitormod.RoleManager.IsAntagonist(client.Character) then
                Traitormod.AwardPoints(client, event.AmountPoints)
                Traitormod.SendMessage(client, string.format(Traitormod.Language.ReceivedPoints, event.AmountPoints), "InfoFrameTabButton.Mission")
            end
        end
    end

    local function findClosestCrew()
        local closestCharacter = nil
        local closestDistance = math.huge

        for _, client in pairs(Client.ClientList) do
            local character = client.Character
            if character ~= nil and character.IsHuman and not character.IsDead and character.TeamID == CharacterTeamType.Team1
                and (event.Rescuer ~= nil or character.Submarine == (event.Character.Submarine or event.Submarine)) then
                local distance = Vector2.Distance(character.WorldPosition, event.Character.WorldPosition)
                if distance < closestDistance then
                    closestDistance = distance
                    closestCharacter = character
                end
            end
        end

        return closestCharacter
    end

    event.CanStart = function()
        return config.CanStart()
            and not Traitormod.RoundEvents.IsEventActive(config.PirateEvent)
            and Traitormod.RoundEvents.ThisRoundEvents[config.PirateEvent] == nil
    end

    event.Start = function()
        local submarine = config.GetSubmarine()
        if submarine == nil then
            event.End()
            return
        end
        local spawnPoint = eventNPC.GetSpawnPoint(submarine)
        if spawnPoint == nil then error(config.Name .. ": no interior spawn point") end

        reservePirateEvent()

        local info = CharacterInfo(Identifier("human"))
        info.Job = Job(JobPrefab.Get("assistant"), false)

        local character = Character.Create(info, spawnPoint.WorldPosition, info.Name, 0, false, true)
        character.TeamID = CharacterTeamType.Team1
        character.GiveJobItems(false, nil)

        event.Character = character
        event.Submarine = submarine
        event.Rescuer = nil
        event.Success = false
        event.NextOrderUpdate = 0
        eventNPC.Stay(character, submarine)

        equipSurvivalSuit(character)
        giveWeakSurvivalSupplies(character)

        if config.SpawnSonar then
            Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs["sonarbeacon"], submarine.WorldPosition, nil, nil, function(item)
                item.NonInteractable = true
                Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs["batterycell"], item.OwnInventory, nil, nil, function(battery)
                    battery.Indestructible = true
                    local interface = item.GetComponentString("CustomInterface")
                    interface.customInterfaceElementList[1].State = true
                    interface.customInterfaceElementList[2].Signal = Traitormod.Language[config.Name .. "Name"]
                    item.CreateServerEvent(interface, interface)
                end)
            end)
        end

        Traitormod.RoundEvents.SendEventMessage(string.format(Traitormod.Language[config.Message], event.AmountPoints), "GameModeIcon.sandbox", Color.Yellow)

        Traitormod.GhostRoles.Create(config.GhostRole, character, {
            OnAssigned = function()
                Traitormod.SendMessageCharacter(character, Traitormod.Language.RescueYou, "InfoFrameTabButton.Mission")
            end
        })

        Hook.Add("think", config.HookName, function()
            local survivor = event.Character
            if survivor == nil or survivor.Removed or survivor.IsDead then
                event.End()
                return
            end

            local currentTime = Timer.GetTime()
            if currentTime >= event.NextOrderUpdate and Traitormod.FindClientCharacter(survivor) == nil then
                local closestCrew = findClosestCrew()
                if closestCrew ~= nil then
                    event.Rescuer = closestCrew
                    eventNPC.Release(survivor)
                    local orderPrefab = OrderPrefab.Prefabs["follow"]
                    local order = Order(orderPrefab, nil, closestCrew).WithManualPriority(CharacterInfo.HighestManualOrderPriority)
                    survivor.SetOrder(order, true, false, true)
                end
                event.NextOrderUpdate = currentTime + 10
            end

            if survivor.Submarine == Submarine.MainSub then
                event.Success = true
                awardCrew()
                event.End()
            end
        end)
    end

    event.End = function(isEndRound)
        Hook.Remove("think", config.HookName)
        eventNPC.Release(event.Character)
        event.Submarine = nil
        event.Rescuer = nil

        if event.Success then
            event.Character = nil
            event.NextOrderUpdate = 0
            return
        end

        if isEndRound and event.Character ~= nil and not event.Character.IsDead and event.Character.Submarine == Submarine.MainSub then
            event.Success = true
            awardCrew()
            event.Character = nil
            event.NextOrderUpdate = 0
            return
        end

        if event.Character ~= nil then
            Traitormod.RoundEvents.SendEventMessage(Traitormod.Language.RescueFail, "InfoFrameTabButton.Mission", Color.Yellow)
        end

        event.Character = nil
        event.NextOrderUpdate = 0
    end

    return event
end

return CreateRescueEvent
