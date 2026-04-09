local event = {}

event.Name = "WreckRescue"
event.MinRoundTime = 1
event.MaxRoundTime = 15
event.MinIntensity = 0
event.MaxIntensity = 1
event.ChancePerMinute = 0.04
event.OnlyOncePerRound = true
event.AmountPoints = 1000

local function reservePirateEvent()
    if Traitormod.RoundEvents.ThisRoundEvents["WreckPirate"] == nil then
        Traitormod.RoundEvents.ThisRoundEvents["WreckPirate"] = 0
    end
end

local function getSpawnPosition(submarine)
    if submarine == nil then
        return nil
    end

    local positions = {}
    for _, waypoint in pairs(submarine.GetWaypoints(true)) do
        if waypoint.CurrentHull ~= nil then
            table.insert(positions, waypoint.WorldPosition)
        end
    end

    if #positions == 0 then
        return submarine.WorldPosition
    end

    return positions[math.random(#positions)]
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
        if character ~= nil and character.IsHuman and not character.IsDead and character.TeamID == CharacterTeamType.Team1 then
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
    return #Level.Loaded.Wrecks > 0
        and not Traitormod.RoundEvents.IsEventActive("WreckPirate")
        and Traitormod.RoundEvents.ThisRoundEvents["WreckPirate"] == nil
end

event.Start = function()
    if #Level.Loaded.Wrecks == 0 then
        event.End()
        return
    end

    local wreck = Level.Loaded.Wrecks[math.random(#Level.Loaded.Wrecks)]
    local position = getSpawnPosition(wreck)
    if wreck == nil or position == nil then
        event.End()
        return
    end

    reservePirateEvent()

    local info = CharacterInfo(Identifier("human"))
    info.Job = Job(JobPrefab.Get("assistant"), false)

    local character = Character.Create(info, position, info.Name, 0, false, true)
    character.TeamID = CharacterTeamType.Team1
    character.GiveJobItems(false, nil)

    event.Character = character
    event.Success = false
    event.NextOrderUpdate = 0

    equipSurvivalSuit(character)
    giveWeakSurvivalSupplies(character)

    Traitormod.RoundEvents.SendEventMessage(string.format(Traitormod.Language.WreckRescue, event.AmountPoints), "GameModeIcon.sandbox", Color.Yellow)

    Traitormod.GhostRoles.Ask(Traitormod.Language.WreckRescueName, function(client)
        Traitormod.LostLivesThisRound[client.SteamID] = false
        client.SetClientCharacter(character)
        Traitormod.SendMessageCharacter(character, Traitormod.Language.RescueYou, "InfoFrameTabButton.Mission")
    end, character)

    Hook.Add("think", "WreckRescue.Think", function()
        local survivor = event.Character
        if survivor == nil or survivor.Removed or survivor.IsDead then
            event.End()
            return
        end

        local currentTime = Timer.GetTime()
        if currentTime >= event.NextOrderUpdate and Traitormod.FindClientCharacter(survivor) == nil then
            local closestCrew = findClosestCrew()
            if closestCrew ~= nil then
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
    Hook.Remove("think", "WreckRescue.Think")

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
