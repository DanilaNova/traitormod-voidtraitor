local skillBuffs = {}

Traitormod.SkillBuffStates = {}
Traitormod.NextSkillBuffId = 0
local roundSkillGiveTimer = -1
local skillBuffUpdateInterval = 1
local skillBuffUpdateTimer = skillBuffUpdateInterval

local function isValidBuffCharacter(character)
    return character ~= nil and character.IsHuman and not character.IsDead and character.Info ~= nil and character.Info.Job ~= nil
end

local function getSkillBuffState(character, create)
    local state = Traitormod.SkillBuffStates[character]
    if state == nil and create then
        state = {
            Effects = {},
            Skills = {},
        }
        Traitormod.SkillBuffStates[character] = state
    end

    return state
end

local function getJobSkill(character, skill)
    if character == nil or character.Info == nil or character.Info.Job == nil or skill == nil then
        return nil
    end

    local identifier = Identifier(tostring(skill))
    return character.Info.Job.GetSkill(identifier)
end

local function getJobSkillLevel(character, skill)
    if character == nil or character.Info == nil or character.Info.Job == nil or skill == nil then
        return 0
    end

    local identifier = Identifier(tostring(skill))
    return math.max(0, tonumber(character.Info.Job.GetSkillLevel(identifier)) or 0)
end

local function setJobSkillLevelSilent(character, skill, level)
    if character == nil or character.Info == nil or character.Info.Job == nil or skill == nil then
        return false
    end

    local identifier = Identifier(tostring(skill))
    level = math.max(0, tonumber(level) or 0)

    local jobSkill = getJobSkill(character, skill)
    if jobSkill == nil then
        character.Info.Job.IncreaseSkillLevel(identifier, level, true)
        jobSkill = getJobSkill(character, skill)
        if jobSkill == nil then
            return false
        end
    end

    jobSkill.Level = level
    return true
end

local function getSkillStateBonus(skillState)
    local totalBonus = 0
    for _, bonus in pairs(skillState.Bonuses or {}) do
        totalBonus = totalBonus + (tonumber(bonus) or 0)
    end

    return math.max(0, totalBonus)
end

function Traitormod.GetTrackedSkillBonus(character, skill)
    local state = getSkillBuffState(character, false)
    if state == nil then
        return 0
    end

    local skillState = state.Skills[tostring(skill)]
    if skillState == nil then
        return 0
    end

    return getSkillStateBonus(skillState)
end

function Traitormod.GetBaseSkillLevel(character, skill)
    local state = getSkillBuffState(character, false)
    if state ~= nil then
        local skillState = state.Skills[tostring(skill)]
        if skillState ~= nil then
            return math.max(0, tonumber(skillState.Baseline) or 0)
        end
    end

    return getJobSkillLevel(character, skill)
end

local statusSkills = {
    { Identifier = "weapons", LanguageKey = "StatusSkillWeapons" },
    { Identifier = "mechanical", LanguageKey = "StatusSkillMechanical" },
    { Identifier = "electrical", LanguageKey = "StatusSkillElectrical" },
    { Identifier = "medical", LanguageKey = "StatusSkillMedical" },
    { Identifier = "surgery", LanguageKey = "StatusSkillSurgery" },
    { Identifier = "helm", LanguageKey = "StatusSkillHelm" },
}

local function getStatusSkillName(skillInfo)
    local languageKey = skillInfo.LanguageKey
    if Traitormod.Language ~= nil and Traitormod.Language[languageKey] ~= nil then
        return Traitormod.Language[languageKey]
    end

    return skillInfo.Identifier
end

local function formatStatusTime(seconds)
    seconds = math.max(0, math.ceil(tonumber(seconds) or 0))
    local minutes = math.floor(seconds / 60)
    local remainingSeconds = seconds % 60
    return string.format("%02d:%02d", minutes, remainingSeconds)
end

local function formatSkillEffectBonuses(skillMap)
    local parts = {}

    for _, skillInfo in ipairs(statusSkills) do
        local bonus = tonumber(skillMap[skillInfo.Identifier]) or 0
        if bonus > 0 then
            table.insert(parts, string.format("+%d %s", math.floor(bonus), getStatusSkillName(skillInfo)))
        end
    end

    for skill, bonus in pairs(skillMap) do
        local known = false
        for _, skillInfo in ipairs(statusSkills) do
            if skillInfo.Identifier == tostring(skill) then
                known = true
                break
            end
        end

        bonus = tonumber(bonus) or 0
        if not known and bonus > 0 then
            table.insert(parts, string.format("+%d %s", math.floor(bonus), tostring(skill)))
        end
    end

    if #parts == 0 then
        return Traitormod.GetText("StatusUnknownEffect")
    end

    return table.concat(parts, ", ")
end

function Traitormod.GetStatusMessage(character)
    if not isValidBuffCharacter(character) then
        return Traitormod.GetText("StatusAliveRequired")
    end

    local lines = {}
    table.insert(lines, Traitormod.GetText("StatusTitle"))
    table.insert(lines, "")
    table.insert(lines, Traitormod.GetText("StatusSkillsHeader"))

    for _, skillInfo in ipairs(statusSkills) do
        local base = math.floor(Traitormod.GetBaseSkillLevel(character, skillInfo.Identifier))
        local bonus = math.floor(Traitormod.GetTrackedSkillBonus(character, skillInfo.Identifier))
        local current = math.floor(getJobSkillLevel(character, skillInfo.Identifier))
        local skillName = getStatusSkillName(skillInfo)

        if bonus > 0 then
            table.insert(lines, string.format(Traitormod.GetText("StatusSkillLineWithBonus"), skillName, base, bonus, current))
        else
            table.insert(lines, string.format(Traitormod.GetText("StatusSkillLine"), skillName, current))
        end
    end

    table.insert(lines, "")
    table.insert(lines, Traitormod.GetText("StatusEffectsHeader"))

    local effects = {}
    local state = getSkillBuffState(character, false)
    if state ~= nil then
        local now = Timer.GetTime()
        for _, effect in pairs(state.Effects or {}) do
            if effect.ExpiresAt ~= nil then
                table.insert(effects, {
                    Text = formatSkillEffectBonuses(effect.Skills or {}),
                    Remaining = math.max(0, effect.ExpiresAt - now),
                })
            end
        end
    end

    table.sort(effects, function(a, b) return a.Remaining < b.Remaining end)

    if #effects == 0 then
        table.insert(lines, Traitormod.GetText("StatusNoEffects"))
    else
        for _, effect in ipairs(effects) do
            table.insert(lines, string.format(Traitormod.GetText("StatusEffectLine"), effect.Text, formatStatusTime(effect.Remaining)))
        end
    end

    return table.concat(lines, "\n")
end

function Traitormod.OnTrackedSkillIncrease(character, skill, amount, gainedFromAbility)
    if gainedFromAbility or character == nil or skill == nil then
        return
    end

    local state = getSkillBuffState(character, false)
    if state == nil then
        return
    end

    local skillState = state.Skills[tostring(skill)]
    if skillState == nil then
        return
    end

    local totalBonus = getSkillStateBonus(skillState)
    local current = getJobSkillLevel(character, skill)
    skillState.Baseline = math.max(0, current - totalBonus)
end

function Traitormod.ApplyTemporarySkillBuff(character, skillMap, durationSeconds)
    if not isValidBuffCharacter(character) then
        return false
    end

    durationSeconds = tonumber(durationSeconds)
    if durationSeconds == nil then
        durationSeconds = 300
    end

    local state = getSkillBuffState(character, true)
    local effect = {
        Character = character,
        ExpiresAt = durationSeconds > 0 and (Timer.GetTime() + durationSeconds) or nil,
        Skills = {},
    }

    Traitormod.NextSkillBuffId = Traitormod.NextSkillBuffId + 1
    effect.Id = Traitormod.NextSkillBuffId

    for skill, bonus in pairs(skillMap or {}) do
        skill = tostring(skill)
        bonus = tonumber(bonus) or 0

        if bonus > 0 then
            local current = getJobSkillLevel(character, skill)
            local skillState = state.Skills[skill]

            if skillState == nil then
                skillState = {
                    Baseline = current,
                    Bonuses = {},
                }
                state.Skills[skill] = skillState
            else
                local totalBonus = getSkillStateBonus(skillState)
                if current > (skillState.Baseline or 0) + totalBonus then
                    skillState.Baseline = current - totalBonus
                end
            end

            effect.Skills[skill] = bonus
            skillState.Bonuses[effect.Id] = bonus

            local targetLevel = (skillState.Baseline or 0) + getSkillStateBonus(skillState)
            if not setJobSkillLevelSilent(character, skill, targetLevel) then
                skillState.Bonuses[effect.Id] = nil
                effect.Skills[skill] = nil
            end
        end
    end

    if next(effect.Skills) == nil then
        return false
    end

    state.Effects[effect.Id] = effect
    return true
end

function Traitormod.RemoveTemporarySkillBuff(character, effectId)
    local state = getSkillBuffState(character, false)
    if state == nil then
        return false
    end

    local effect = state.Effects[effectId]
    if effect == nil then
        return false
    end

    state.Effects[effectId] = nil

    for skill in pairs(effect.Skills) do
        local skillState = state.Skills[skill]
        if skillState ~= nil then
            local totalBonus = getSkillStateBonus(skillState)
            local current = getJobSkillLevel(character, skill)
            if current > (skillState.Baseline or 0) + totalBonus then
                skillState.Baseline = current - totalBonus
            end

            skillState.Bonuses[effectId] = nil

            local remainingBonus = getSkillStateBonus(skillState)
            if remainingBonus <= 0 then
                setJobSkillLevelSilent(character, skill, skillState.Baseline or 0)
                state.Skills[skill] = nil
            else
                setJobSkillLevelSilent(character, skill, (skillState.Baseline or 0) + remainingBonus)
            end
        end
    end

    if next(state.Effects) == nil and next(state.Skills) == nil then
        Traitormod.SkillBuffStates[character] = nil
    end

    return true
end

function Traitormod.ClearTemporarySkillBuffs()
    for character, state in pairs(Traitormod.SkillBuffStates) do
        if character ~= nil and character.Info ~= nil and character.Info.Job ~= nil then
            for skill, skillState in pairs(state.Skills or {}) do
                setJobSkillLevelSilent(character, skill, skillState.Baseline or 0)
            end
        end
    end

    Traitormod.SkillBuffStates = {}
    Traitormod.NextSkillBuffId = 0
end

local function hasAliveTeam1Job(jobIdentifier)
    for _, character in pairs(Character.CharacterList) do
        if character ~= nil and character.IsHuman and not character.IsDead and character.TeamID == CharacterTeamType.Team1 and character.HasJob(jobIdentifier) then
            return true
        end
    end

    return false
end

local function applyRoundSkillGain()
    local config = Traitormod.Config.RoundSkillGain
    if config == nil or not config.Enabled then
        return
    end

    if config.SecretOnly and (Traitormod.SelectedGamemode == nil or not Traitormod.SelectedGamemode.UsesSecretRules) then
        return
    end

    for _, roleConfig in pairs(config.Roles or {}) do
        local hasAliveRole = hasAliveTeam1Job(roleConfig.Job)
        local minGain = hasAliveRole and config.AliveRoleMin or config.MissingRoleMin
        local maxGain = hasAliveRole and config.AliveRoleMax or config.MissingRoleMax
        local cap = hasAliveRole and config.AliveRoleCap or config.MissingRoleCap

        for _, character in pairs(Character.CharacterList) do
            if character ~= nil and character.IsHuman and not character.IsDead then
                if (not config.AliveTeam1Only) or character.TeamID == CharacterTeamType.Team1 then
                    local baseSkill = Traitormod.GetBaseSkillLevel(character, roleConfig.Skill)
                    if baseSkill < cap then
                        local amount = math.random(minGain, maxGain)
                        amount = math.min(amount, cap - baseSkill)
                        if amount > 0 then
                            Traitormod.ApplyTemporarySkillBuff(character, { [roleConfig.Skill] = amount }, -1)
                        end
                    end
                end
            end
        end
    end
end

function skillBuffs.RoundStart()
    if Traitormod.Config.RoundSkillGain ~= nil and Traitormod.Config.RoundSkillGain.Enabled then
        roundSkillGiveTimer = Timer.GetTime() + (tonumber(Traitormod.Config.RoundSkillGain.Timer) or Traitormod.Config.ExperienceTimer)
    else
        roundSkillGiveTimer = -1
    end
end

function skillBuffs.RoundEnd()
    roundSkillGiveTimer = -1
end

function skillBuffs.Think(deltaTime)
    skillBuffUpdateTimer = skillBuffUpdateTimer + deltaTime
    if skillBuffUpdateTimer >= skillBuffUpdateInterval then
        skillBuffUpdateTimer = 0
        local now = Timer.GetTime()

        for character, state in pairs(Traitormod.SkillBuffStates) do
            if not isValidBuffCharacter(character) then
                if character ~= nil and character.Info ~= nil and character.Info.Job ~= nil then
                    for skill, skillState in pairs(state.Skills or {}) do
                        setJobSkillLevelSilent(character, skill, skillState.Baseline or 0)
                    end
                end
                Traitormod.SkillBuffStates[character] = nil
            else
                for effectId, effect in pairs(state.Effects) do
                    if effect.ExpiresAt ~= nil and now >= effect.ExpiresAt then
                        Traitormod.RemoveTemporarySkillBuff(character, effectId)
                    end
                end

                state = Traitormod.SkillBuffStates[character]
                if state ~= nil then
                    for skill, skillState in pairs(state.Skills) do
                        local totalBonus = 0
                        for _, bonus in pairs(skillState.Bonuses or {}) do
                            totalBonus = totalBonus + (tonumber(bonus) or 0)
                        end
                        local expected = (skillState.Baseline or 0) + totalBonus

                        local current = getJobSkillLevel(character, skill)
                        if current > expected then
                            skillState.Baseline = current - totalBonus
                            expected = current
                        elseif current < expected then
                            setJobSkillLevelSilent(character, skill, expected)
                        end

                        if next(skillState.Bonuses or {}) == nil then
                            state.Skills[skill] = nil
                        end
                    end

                    if next(state.Effects) == nil and next(state.Skills) == nil then
                        Traitormod.SkillBuffStates[character] = nil
                    end
                end
            end
        end
    end
end

function skillBuffs.UpdateRoundSkillGain()
    if roundSkillGiveTimer and roundSkillGiveTimer > 0 and Timer.GetTime() > roundSkillGiveTimer then
        applyRoundSkillGain()
        roundSkillGiveTimer = Timer.GetTime() + (tonumber(Traitormod.Config.RoundSkillGain.Timer) or Traitormod.Config.ExperienceTimer)
    end
end

return skillBuffs
