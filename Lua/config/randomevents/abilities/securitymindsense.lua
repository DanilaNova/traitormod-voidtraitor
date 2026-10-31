local event = {}

event.Name = "SecurityMindSense"
event.MinRoundTime = 1
event.MinIntensity = 0
event.MaxIntensity = 1
event.ChancePerMinute = 0.01
event.OnlyOncePerRound = true

local function applyAffliction(character, afflictionIdentifier, amount)
    if character == nil or character.CharacterHealth == nil or character.AnimController == nil then
        return false
    end

    local prefab = AfflictionPrefab.Prefabs[afflictionIdentifier]
    if prefab == nil then
        return false
    end

    character.CharacterHealth.ApplyAffliction(character.AnimController.MainLimb, prefab.Instantiate(amount))
    return true
end

local function isValidTarget(character)
    return character ~= nil
        and character.IsHuman
        and not character.IsDead
        and character.TeamID == CharacterTeamType.Team1
        and character.HasJob("securityofficer")
        and not Traitormod.RoleManager.IsAntagonist(character)
end

local function getRandomTarget()
    local targets = {}

    for _, character in pairs(Character.CharacterList) do
        if isValidTarget(character) then
            table.insert(targets, character)
        end
    end

    if #targets == 0 then
        return nil
    end

    return targets[math.random(#targets)]
end

event.CanStart = function()
    return getRandomTarget() ~= nil
end

event.Start = function()
    local character = getRandomTarget()
    if character ~= nil then
        applyAffliction(character, "mindsense", 600)
        applyAffliction(character, "psychosis", 20)
        Traitormod.SendMessageCharacter(character, Traitormod.Language.SecurityMindSense, "InfoFrameTabButton.Mission")
    end

    event.End()
end

event.End = function()
end

return event
