local objective = Traitormod.RoleManager.Objectives.Objective:new()

objective.Name = "HealCharacters"
objective.AmountPoints = 400
objective.Amount = 500
objective.RecentTreatmentAttributionSeconds = 12
objective.DedupWindowSeconds = 0.05
objective.MinimumReportedHeal = 0.5

objective.ActiveObjectives = setmetatable({}, { __mode = "k" })

local function updateObjectiveText(obj)
    obj.Text = string.format(Traitormod.Language.ObjectiveHealCharacters, math.floor(obj.Progress), obj.Amount)
end

local function isActiveHealObjective(activeObjective)
    return activeObjective ~= nil
        and not activeObjective.Awarded
        and not activeObjective.Failed
        and activeObjective.Character ~= nil
        and not activeObjective.Character.IsDead
end

local function getActiveHealObjective(healer)
    if healer == nil then return nil end

    for activeObjective in pairs(objective.ActiveObjectives) do
        if not isActiveHealObjective(activeObjective) then
            objective.ActiveObjectives[activeObjective] = nil
        elseif activeObjective.Character == healer then
            return activeObjective
        end
    end

    return nil
end

objective.Static = function()
    Hook.Add("traitormod.healingTracked", "Traitormod.Objective.HealCharacters.HealingTracked", function(targetCharacter, healer, amount)
        amount = tonumber(amount) or 0
        if amount < objective.MinimumReportedHeal or targetCharacter == nil or targetCharacter.Removed then return end

        local activeObjective = getActiveHealObjective(healer)
        if activeObjective == nil then return end

        activeObjective.Progress = activeObjective.Progress + amount
        updateObjectiveText(activeObjective)
    end)

    Hook.Add("roundEnd", "Traitormod.Objective.HealCharacters.RoundEnd", function()
        objective.ActiveObjectives = setmetatable({}, { __mode = "k" })
    end)
end

function objective:Start(target)
    self.Progress = 0
    objective.ActiveObjectives[self] = true

    updateObjectiveText(self)

    return true
end

function objective:OnAwarded()
    objective.ActiveObjectives[self] = nil
end

function objective:IsCompleted()
    if Traitormod.RoundStats ~= nil then
        Traitormod.RoundStats.FlushHealing()
    end
    return self.Progress >= self.Amount
end

return objective
