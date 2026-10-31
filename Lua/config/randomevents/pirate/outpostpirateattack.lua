local event = {}

local peopleInOutpost = 0
local autoTriggerTimer = 0

event.Name = "OutpostPirateAttack"
event.MinRoundTime = 0
event.MinIntensity = 0
event.MaxIntensity = 1
event.ChancePerMinute = 0.015
event.OnlyOncePerRound = true

event.Init = function()
    autoTriggerTimer = Timer.GetTime()
    Hook.Add("think", "OutpostPirateAttack.AutoTrigger", function ()
        if autoTriggerTimer > Timer.GetTime() then return end
        if not Game.RoundStarted then return end

        autoTriggerTimer = Timer.GetTime() + 5

        if Traitormod.RoundEvents.IsEventActive(event.Name) then return end
        if Traitormod.SelectedGamemode == nil or Traitormod.SelectedGamemode.Name ~= "Secret" then return end
        if not Level.Loaded.EndOutpost then return end

        local playerInOutpost = false
        local outpost = Level.Loaded.EndOutpost.WorldPosition

        for key, character in pairs(Character.CharacterList) do
            if character.IsRemotePlayer and character.IsHuman and not character.IsDead and Vector2.Distance(character.WorldPosition, outpost) < 5000 then
                playerInOutpost = true
                break
            end
        end

        if playerInOutpost then
            peopleInOutpost = peopleInOutpost + 1
        end

        if peopleInOutpost > 30 then
            Traitormod.RoundEvents.TriggerEvent(event.Name)
        end
    end)

    Hook.Add("roundEnd", "OutpostPirateAttack.RoundEnd", function ()
        peopleInOutpost = 0
    end)
end

event.CanStart = function()
    return Level.Loaded ~= nil and Level.Loaded.EndOutpost ~= nil
end

event.Start = function()
    local outpost = Level.Loaded.EndOutpost.WorldPosition

    local targets = {}

    for key, character in pairs(Character.CharacterList) do
        if character.IsRemotePlayer and character.IsHuman and not character.IsDead and Vector2.Distance(character.WorldPosition, outpost) < 5000 then
            table.insert(targets, character)
        end
    end

    if #targets == 0 then
        event.End()
        return
    end

    -- time to strike...

    event.Pirates = {}

    for i = 1, 2, 1 do
        local info = CharacterInfo(Identifier("human"))
        info.Name = "Pirate " .. info.Name
        info.Job = Job(JobPrefab.Get("securityofficer"), false)

        local character = Character.Create(info, outpost - Vector2(0, 5000), info.Name, 0, false, true)

        table.insert(event.Pirates, character)

        character.CanSpeak = false
        character.TeamID = CharacterTeamType.Team2
        character.GiveJobItems(false, nil)

        local idCard = character.Inventory.GetItemInLimbSlot(InvSlotType.Card)
        if idCard then
            idCard.NonPlayerTeamInteractable = true
            local prop = idCard.SerializableProperties[Identifier("NonPlayerTeamInteractable")]
            Networking.CreateEntityEvent(idCard, Item.ChangePropertyEventData(prop, idCard))
        end

        local headset = character.Inventory.GetItemInLimbSlot(InvSlotType.Headset)
        if headset then
            local wifi = headset.GetComponentString("WifiComponent")
            if wifi then
                wifi.TeamID = CharacterTeamType.Team1
            end
        end

        Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab("pucs"), character.Inventory, nil, nil, function (item)
            Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab("combatstimulantsyringe"), item.OwnInventory)
            Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab("oxygenitetank"), item.OwnInventory)
        end)

        Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab("shotgun"), character.Inventory, nil, nil,
            function(item)
                for i = 1, 6, 1 do
                    Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab("shotgunshell"), item.OwnInventory)
                end
            end)
        Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab("smg"), character.Inventory, nil, nil,
            function(item)
                Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab("smgmagazine"), item.OwnInventory)
            end)

        for i = 1, 4, 1 do
            Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab("antibiotics"), character.Inventory)
        end

        local oldClothes = character.Inventory.GetItemInLimbSlot(InvSlotType.InnerClothes)
        oldClothes.Drop()
        Entity.Spawner.AddEntityToRemoveQueue(oldClothes)

        Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab("pirateclothes"), character.Inventory, nil, nil,
            function(item)
                character.Inventory.TryPutItem(item, character.Inventory.FindLimbSlot(InvSlotType.InnerClothes), true,
                    false, character)
            end)
    end

    local function getClosetTarget(position)
        local closestTarget = nil
        for key, value in pairs(targets) do
            if not value.IsDead and (not closestTarget or Vector2.Distance(value.WorldPosition, position) < Vector2.Distance(closestTarget.WorldPosition, position)) then
                closestTarget = value
            end
        end
        return closestTarget
    end

    local timer = 0
    Hook.Add("think", "OutpostPirateAttack.Think", function ()
        if timer > Timer.GetTime() then return end
        timer = Timer.GetTime() + 30

        local alivePirateFound = false
        for _, pirate in pairs(event.Pirates) do
            if not pirate.IsDead then
                alivePirateFound = true
                local target = getClosetTarget(pirate.WorldPosition)
                if target == nil then
                    event.End()
                    return
                end

                local orderPrefab = OrderPrefab.Prefabs["follow"]
                local order = Order(orderPrefab, nil, target).WithManualPriority(CharacterInfo.HighestManualOrderPriority)
                pirate.SetOrder(order, true, false, true)

                if Vector2.Distance(pirate.WorldPosition, target.WorldPosition) < 50 then
                    pirate.AIController.AddCombatObjective(AIObjectiveCombat.CombatMode.Offensive, target)
                end
            end
        end

        if not alivePirateFound then
            event.End()
        end
    end)
end


event.End = function(isEndRound)
    Hook.Remove("think", "OutpostPirateAttack.Think")
end

return event
