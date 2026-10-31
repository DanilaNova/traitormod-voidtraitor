local event = {}

event.Name = "JunctionBoxOverload"
event.MinRoundTime = 10
event.MinIntensity = 0
event.MaxIntensity = 1
event.ChancePerMinute = 0.005
event.OnlyOncePerRound = true

local function getItemIdentifier(item)
    if item == nil or item.Prefab == nil or item.Prefab.Identifier == nil then
        return nil
    end

    return string.lower(item.Prefab.Identifier.Value)
end

local function syncItemCondition(item)
    if item == nil then
        return
    end

    local property = item.SerializableProperties[Identifier("Condition")]
    if property ~= nil then
        Networking.CreateEntityEvent(item, Item.ChangePropertyEventData(property, item))
    end
end

event.CanStart = function()
    return Submarine.MainSub ~= nil
end

event.Start = function()
    local count = 0

    for _, item in pairs(Submarine.MainSub.GetItems(true)) do
        local identifier = getItemIdentifier(item)
        if identifier ~= nil and string.find(identifier, "junctionbox", 1, true) ~= nil then
            item.Condition = 0
            syncItemCondition(item)
            count = count + 1
        end
    end

    if count > 0 then
        Traitormod.RoundEvents.SendEventMessage(Traitormod.Language.JunctionBoxOverload, "GameModeIcon.PVP", Color.Red)
    end

    event.End()
end

event.End = function()
end

return event
