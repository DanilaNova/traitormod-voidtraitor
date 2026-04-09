local objective = Traitormod.RoleManager.Objectives.Objective:new()

objective.Name = "HealCharacters"
objective.AmountPoints = 400
objective.Amount = 500
objective.RecentTreatmentAttributionSeconds = 12
objective.DedupWindowSeconds = 0.05
objective.MinimumReportedHeal = 0.5

objective.PendingReductionCalls = {}
objective.CharacterStates = {}

local function now()
    if Timer ~= nil and Timer.GetTime ~= nil then
        return Timer.GetTime()
    end

    return 0
end

local function getCharacterState(character)
    local state = objective.CharacterStates[character]
    if state ~= nil then return state end

    state = {
        LastVitality = character ~= nil and character.Vitality or 0,
        RecentHealer = nil,
        RecentHealerExpiresAt = 0,
        IgnoreHealing = 0,
        LastDirectHealer = nil,
        LastDirectAmount = 0,
        LastDirectAt = 0,
    }

    objective.CharacterStates[character] = state
    return state
end

local function updateObjectiveText(obj)
    obj.Text = string.format(Traitormod.Language.ObjectiveHealCharacters, math.floor(obj.Progress), obj.Amount)
end

local function iterActiveHealObjectives(healer)
    local found = {}
    for roleCharacter, role in pairs(Traitormod.RoleManager.RoundRoles or {}) do
        if roleCharacter ~= nil and not roleCharacter.IsDead and role ~= nil and role.Objectives ~= nil then
            for _, activeObjective in pairs(role.Objectives) do
                if activeObjective ~= nil and not activeObjective.Awarded and activeObjective.Name == objective.Name and activeObjective.Character == healer then
                    table.insert(found, activeObjective)
                end
            end
        end
    end
    return found
end

local function awardHealing(targetCharacter, healer, amount)
    if healer == nil or amount == nil or amount < objective.MinimumReportedHeal then return end
    if targetCharacter == nil or targetCharacter.Removed then return end

    for _, activeObjective in pairs(iterActiveHealObjectives(healer)) do
        activeObjective.Progress = activeObjective.Progress + amount
        updateObjectiveText(activeObjective)
    end
end

local function markRecentHealer(targetCharacter, healer)
    if targetCharacter == nil or healer == nil then return end

    local state = getCharacterState(targetCharacter)
    state.RecentHealer = healer
    state.RecentHealerExpiresAt = now() + objective.RecentTreatmentAttributionSeconds
end

local function registerDirectHealing(targetCharacter, healer, amount)
    if targetCharacter == nil or healer == nil then return end

    markRecentHealer(targetCharacter, healer)

    if amount == nil or amount < objective.MinimumReportedHeal then return end

    local state = getCharacterState(targetCharacter)
    state.IgnoreHealing = state.IgnoreHealing + amount
    state.LastVitality = targetCharacter.Vitality
    state.LastDirectHealer = healer
    state.LastDirectAmount = amount
    state.LastDirectAt = now()

    awardHealing(targetCharacter, healer, amount)
end

local function isDuplicateDirectHealing(targetCharacter, healer, amount)
    if targetCharacter == nil or healer == nil or amount == nil then return false end

    local state = getCharacterState(targetCharacter)
    if state.LastDirectHealer ~= healer then return false end
    if math.abs(state.LastDirectAmount - amount) > objective.MinimumReportedHeal then return false end

    return (now() - state.LastDirectAt) <= objective.DedupWindowSeconds
end

local function captureReductionState(instance, ptable)
    if instance == nil or instance.Character == nil then return end

    table.insert(objective.PendingReductionCalls, {
        Health = instance,
        Target = instance.Character,
        PrevVitality = instance.Character.Vitality,
        Healer = ptable["attacker"],
    })
end

local function finishReductionState(instance)
    local index = nil
    for i = #objective.PendingReductionCalls, 1, -1 do
        if objective.PendingReductionCalls[i].Health == instance then
            index = i
            break
        end
    end

    if index == nil then return end

    local context = table.remove(objective.PendingReductionCalls, index)
    local targetCharacter = context.Target
    local healer = context.Healer

    if targetCharacter == nil or targetCharacter.Removed or healer == nil then return end

    local healthChange = targetCharacter.Vitality - context.PrevVitality
    registerDirectHealing(targetCharacter, healer, healthChange)
end

objective.Static = function()
    Hook.Patch(
        "Traitormod.Objective.HealCharacters.ReduceAfflictionAll.Before",
        "Barotrauma.CharacterHealth",
        "ReduceAfflictionOnAllLimbs",
        function(instance, ptable)
            captureReductionState(instance, ptable)
        end,
        Hook.HookMethodType.Before
    )

    Hook.Patch(
        "Traitormod.Objective.HealCharacters.ReduceAfflictionAll.After",
        "Barotrauma.CharacterHealth",
        "ReduceAfflictionOnAllLimbs",
        function(instance, _)
            finishReductionState(instance)
        end,
        Hook.HookMethodType.After
    )

    Hook.Patch(
        "Traitormod.Objective.HealCharacters.ReduceAfflictionLimb.Before",
        "Barotrauma.CharacterHealth",
        "ReduceAfflictionOnLimb",
        function(instance, ptable)
            captureReductionState(instance, ptable)
        end,
        Hook.HookMethodType.Before
    )

    Hook.Patch(
        "Traitormod.Objective.HealCharacters.ReduceAfflictionLimb.After",
        "Barotrauma.CharacterHealth",
        "ReduceAfflictionOnLimb",
        function(instance, _)
            finishReductionState(instance)
        end,
        Hook.HookMethodType.After
    )

    Hook.Patch(
        "Traitormod.Objective.HealCharacters.TryAdjustHealerSkill.After",
        "Barotrauma.Character",
        "TryAdjustHealerSkill",
        function(targetCharacter, ptable)
            local healer = ptable["healer"]
            local healthChange = ptable["healthChange"] or 0

            if targetCharacter == nil or healer == nil then return end

            markRecentHealer(targetCharacter, healer)

            if healthChange >= objective.MinimumReportedHeal and not isDuplicateDirectHealing(targetCharacter, healer, healthChange) then
                registerDirectHealing(targetCharacter, healer, healthChange)
            end
        end,
        Hook.HookMethodType.After
    )

    Hook.Add("think", "Traitormod.Objective.HealCharacters.TrackDelayedHealing", function()
        if not Game.RoundStarted then return end

        for _, character in pairs(Character.CharacterList) do
            if character == nil or character.Removed then
                objective.CharacterStates[character] = nil
            else
                local state = getCharacterState(character)
                local currentVitality = character.Vitality
                local vitalityGain = currentVitality - state.LastVitality

                if vitalityGain > 0 then
                    if state.IgnoreHealing > 0 then
                        local ignored = math.min(vitalityGain, state.IgnoreHealing)
                        state.IgnoreHealing = state.IgnoreHealing - ignored
                        vitalityGain = vitalityGain - ignored
                    end

                    if vitalityGain >= objective.MinimumReportedHeal and state.RecentHealer ~= nil and now() <= state.RecentHealerExpiresAt then
                        awardHealing(character, state.RecentHealer, vitalityGain)
                    end
                end

                state.LastVitality = currentVitality

                if state.RecentHealer ~= nil and now() > state.RecentHealerExpiresAt then
                    state.RecentHealer = nil
                end
            end
        end
    end)
end

function objective:Start(target)
    self.Progress = 0

    updateObjectiveText(self)

    return true
end

function objective:IsCompleted()
    return self.Progress >= self.Amount
end

return objective
