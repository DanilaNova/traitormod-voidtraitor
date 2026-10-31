local event = {}

event.Name = "MechanicMechanicalRepair"
event.MinRoundTime = 1
event.MinIntensity = 0
event.MaxIntensity = 1
event.ChancePerMinute = 0.01
event.OnlyOncePerRound = true

local mechanicalIdentifiers = {
    smallpump = true,
    pump = true,
    oxygenerator = true,
    shuttleoxygenerator = true,
    outpostoxygenerator = true,
    deconstructor = true,
    fabricator = true,
    engine = true,
    largeengine = true,
    shuttleengine = true,
    coilgunloader = true,
    pulselaserloader = true,
    depthchargeloader = true,
    railgunloader = true,
    chaingunloader = true,
    flakcannonloader = true,
}

local function isValidTarget(character)
    return character ~= nil
        and character.IsHuman
        and not character.IsDead
        and character.TeamID == CharacterTeamType.Team1
        and character.HasJob("mechanic")
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
        if identifier ~= nil and mechanicalIdentifiers[identifier] then
            local newCondition = math.min(item.MaxCondition, item.Condition + item.MaxCondition * 0.15)
            if newCondition > item.Condition then
                item.Condition = newCondition
                syncItemCondition(item)
                repaired = repaired + 1
            end
        end
    end

    if repaired > 0 then
        Traitormod.RoundEvents.SendEventMessage(Traitormod.Language.MechanicMechanicalRepair, "GameModeIcon.sandbox", Color.Yellow)
    end

    event.End()
end

event.End = function()
end

return event
