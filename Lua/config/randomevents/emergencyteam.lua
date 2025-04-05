local event = {}

event.Enabled = true
event.Name = "EmergencyTeam"
event.MinRoundTime = 5
event.MinIntensity = 0.8
event.MaxIntensity = 1
event.ChancePerMinute = 0.075
event.OnlyOncePerRound = true

event.Start = function()
    local areas = {}

    for key, value in pairs(Submarine.MainSub.GetHulls(true)) do
        if value.IsAirlock then
            table.insert(areas, value)
        end
    end

    if #areas == 0 then
        table.insert(areas, Submarine.MainSub)
    end

    local area = areas[math.random(#areas)]

    local crew = {"mechanic", "engineer", "mechanic", "engineer"}
    for k, v in pairs(crew) do
        local info = CharacterInfo(Identifier("human"))
		info.Name = "Emergency " .. info.Name
        info.Job = Job(JobPrefab.Get(v), false)

        local character = Character.Create(info, area.WorldPosition, info.Name, 0, false, true)

        character.TeamID = CharacterTeamType.Team1
        character.GiveJobItems(false, nil)
        character.CanSpeak = false

        Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab("divingsuit"), character.Inventory, nil, nil, function (item)
            Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab("oxygenitetank"), item.OwnInventory)
        end)

        Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab("weldingtool"), character.Inventory, nil, nil, function (item)
            Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab("weldingfueltank"), item.OwnInventory)
        end)

        if info.Job.Prefab.Identifier == "mechanic" then
            local repairOrderPrefab = OrderPrefab.Prefabs["repairsystems"]
            local repairOrder = Order(repairOrderPrefab, nil, nil).WithManualPriority(CharacterInfo.HighestManualOrderPriority)
            character.SetOrder(repairOrder, true, false, true)
        elseif info.Job.Prefab.Identifier == "engineer" then
            local repairOrderPrefab = OrderPrefab.Prefabs["repairelectrical"]
            local repairOrder = Order(repairOrderPrefab, nil, nil).WithManualPriority(CharacterInfo.HighestManualOrderPriority)
            character.SetOrder(repairOrder, true, false, true)
        end

        local leakOrderPrefab = OrderPrefab.Prefabs["fixleaks"]
        local leakOrder = Order(leakOrderPrefab, nil, nil).WithManualPriority(CharacterInfo.HighestManualOrderPriority)
        character.SetOrder(leakOrder, true, false, true)
		
        Traitormod.GhostRoles.Ask("Emergency " .. k, function (client)
            Traitormod.LostLivesThisRound[client.SteamID] = false
            client.SetClientCharacter(character)

            Traitormod.SendMessageCharacter(character, Traitormod.Language.EmergencyYou, "InfoFrameTabButton.Mission")
        end, character)
    end
	
    local text = Traitormod.Language.EmergencyTeam
    Traitormod.RoundEvents.SendEventMessage(text, "GameModeIcon.sandbox")

    event.End()
end



event.End = function()

end

return event
