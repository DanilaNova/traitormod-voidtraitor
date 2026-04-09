local event = {}

event.Name = "MechanicSkillBoost"
event.MinRoundTime = 10
event.MinIntensity = 0
event.MaxIntensity = 1
event.ChancePerMinute = 0.0005
event.OnlyOncePerRound = true

local function isValidTarget(character)
    return character ~= nil
        and character.IsHuman
        and not character.IsDead
        and character.TeamID == CharacterTeamType.Team1
        and character.HasJob("mechanic")
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
    if character ~= nil and Traitormod.ApplyTemporarySkillBuff(character, { mechanical = 100 }, 300) then
        Traitormod.SendMessageCharacter(character, Traitormod.Language.MechanicSkillBoost, "InfoFrameTabButton.Mission")
    end

    event.End()
end

event.End = function()
end

return event
