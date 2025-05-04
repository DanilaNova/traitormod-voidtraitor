local event = {}

event.Name = "MedicalDelivery"
event.MinRoundTime = 5
event.MinIntensity = 0.5
event.MaxIntensity = 1
event.ChancePerMinute = 0.05
event.OnlyOncePerRound = false

local cratePrefab = ItemPrefab.GetItemPrefab("mediccrate")
local items = { "antidama1", "antidama1", "antidama1", "antidama1", "antibleeding1", "antibleeding1", "antibleeding1", "antibleeding1", "gypsum", "gypsum", "gypsum", "gypsum", "antibiotics", "antibiotics", "antibiotics", "calyxanide", "calyxanide", "suture", "suture", "suture", "suture", "suture", "suture", "suture", "suture", "suture", "suture", "suture", "suture", "suture", "suture", "suture", "suture", "mannitol", "mannitol", "mannitol", "antinarc", "antinarc", "antibloodloss2", "antibloodloss2", "antibloodloss2", "antibloodloss2", "energydrink", "energydrink", "ethanol", "ethanol", "aed" }

event.Start = function ()
    local position = nil

    for key, value in pairs(Submarine.MainSub.GetWaypoints(true)) do
        if value.AssignedJob and value.AssignedJob.Identifier == "medicaldoctor" then
            position = value.WorldPosition
            break
        end
    end

    if position == nil then
        position = Submarine.MainSub.WorldPosition
    end

    Entity.Spawner.AddItemToSpawnQueue(cratePrefab, position, nil, nil, function(item)
        item.SpriteColor = Color(255, 0, 0, 255)
        local property = item.SerializableProperties[Identifier("SpriteColor")]
        Networking.CreateEntityEvent(item, Item.ChangePropertyEventData(property, item))

        for key, value in pairs(items) do
            Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab(value), item.OwnInventory)
        end
    end)

    local text = Traitormod.Language.MedicalDelivery
    Traitormod.RoundEvents.SendEventMessage(text, "GameModeIcon.sandbox")

    event.End()
end


event.End = function ()

end

return event