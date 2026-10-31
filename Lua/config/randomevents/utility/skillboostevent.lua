---@class SkillBoostEventConfig
---@field Name string
---@field Job string
---@field Skills table<string, number>
---@field Message string

---@param config SkillBoostEventConfig
---@return table
local function CreateSkillBoostEvent(config)
    local event = {}

    event.Name = config.Name
    event.MinRoundTime = 1
    event.MinIntensity = 0
    event.MaxIntensity = 1
    event.ChancePerMinute = 0.01
    event.OnlyOncePerRound = true

    local function isValidTarget(character)
        return character ~= nil
            and character.IsHuman
            and not character.IsDead
            and character.TeamID == CharacterTeamType.Team1
            and character.HasJob(config.Job)
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
        if character ~= nil and Traitormod.ApplyTemporarySkillBuff(character, config.Skills, 300) then
            Traitormod.SendMessageCharacter(
                character,
                Traitormod.Language[config.Message],
                "InfoFrameTabButton.Mission"
            )
        end

        event.End()
    end

    event.End = function()
    end

    return event
end

return CreateSkillBoostEvent
