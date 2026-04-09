local event = {}

event.Name = "EngineerElectricalRepair"
event.MinRoundTime = 10
event.MinIntensity = 0
event.MaxIntensity = 1
event.ChancePerMinute = 0.0005
event.OnlyOncePerRound = true

local electricalIdentifiers = {
    junctionbox = true,
    statusmonitor = true,
    sonarmonitor = true,
    shuttlenavterminal = true,
    navterminal = true,
    battery = true,
    shuttlebattery = true,
    supercapacitor = true,
    reactor1 = true,
    outpostreactor = true,
}

local function isValidTarget(character)
    return character ~= nil
        and character.IsHuman
        and not character.IsDead
        and character.TeamID == CharacterTeamType.Team1
        and character.HasJob("engineer")
        and not Traitormod.RoleManager.IsAntagonist(character)
end

local function hasValidTarget()
    for _, character in pairs(Character.CharacterList) do
        if isValidTarget(character) then
            return true
        end
    end

    return false
end

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
    return Submarine.MainSub ~= nil and hasValidTarget()
end

event.Start = function()
    local repaired = 0

    for _, item in pairs(Submarine.MainSub.GetItems(true)) do
        local identifier = getItemIdentifier(item)
        if identifier ~= nil and electricalIdentifiers[identifier] then
            local newCondition = math.min(item.MaxCondition, item.Condition + item.MaxCondition * 0.10)
            if newCondition > item.Condition then
                item.Condition = newCondition
                syncItemCondition(item)
                repaired = repaired + 1
            end
        end
    end

    if repaired > 0 then
        Traitormod.RoundEvents.SendEventMessage(Traitormod.Language.EngineerElectricalRepair, "GameModeIcon.sandbox", Color.Yellow)
    end

    event.End()
end

event.End = function()
end

return event
