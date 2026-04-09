local objective = Traitormod.RoleManager.Objectives.Objective:new()

objective.Name = "SuffocateCrew"
objective.AmountPoints = 900
objective.RequiredLowOxygenSeconds = 4
objective.SuffocationKillWindowSeconds = 20
objective.SevereOxygenThreshold = 15
objective.LowOxygenAfflictionThreshold = 35
objective.AdditionalLowOxygenAfflictions = {"oxygenlow", "hypoxemia", "cerebralhypoxia", "asphyxia"}

local function getAfflictionStrength(character, identifier)
    if character == nil or identifier == nil then return 0 end
    if character.CharacterHealth == nil then return 0 end

    local success, strength = pcall(function()
        return character.CharacterHealth.GetAfflictionStrengthByIdentifier(identifier)
    end)

    if not success or strength == nil then return 0 end
    return strength
end

local function hasSevereLowOxygen(objectiveInstance, character)
    if character == nil or character.Removed then return false end

    local oxygen = nil
    local success = pcall(function()
        oxygen = character.Oxygen
    end)

    if success and oxygen ~= nil and oxygen <= objectiveInstance.SevereOxygenThreshold then
        return true
    end

    for _, identifier in pairs(objectiveInstance.AdditionalLowOxygenAfflictions or {}) do
        if getAfflictionStrength(character, identifier) >= objectiveInstance.LowOxygenAfflictionThreshold then
            return true
        end
    end

    return false
end

function objective:Start(target)
    self.Target = target
    self.LowOxygenStartedAt = nil
    self.LastSevereLowOxygenAt = nil
    self.ObservedSevereLowOxygen = false

    if self.Target == nil then return false end

    self.Text = string.format("Suffocate %s to death.", self.Target.Name)

    return true
end

function objective:UpdateSuffocationState()
    if self.Target == nil or self.Target.Removed then return end

    local now = Timer.GetTime()
    local severeLowOxygen = hasSevereLowOxygen(self, self.Target)

    if severeLowOxygen then
        if self.LowOxygenStartedAt == nil then
            self.LowOxygenStartedAt = now
        end

        if now - self.LowOxygenStartedAt >= self.RequiredLowOxygenSeconds then
            self.ObservedSevereLowOxygen = true
            self.LastSevereLowOxygenAt = now
        end
    else
        self.LowOxygenStartedAt = nil
    end
end

function objective:IsCompleted()
    self:UpdateSuffocationState()

    if self.Target == nil or not self.Target.IsDead then return false end
    if not self.ObservedSevereLowOxygen then return false end
    if self.LastSevereLowOxygenAt == nil then return false end

    return (Timer.GetTime() - self.LastSevereLowOxygenAt) <= self.SuffocationKillWindowSeconds
end

function objective:IsFailed()
    self:UpdateSuffocationState()

    if self.Target == nil or not self.Target.IsDead then return false end

    if not self.ObservedSevereLowOxygen or self.LastSevereLowOxygenAt == nil then
        return true
    end

    return (Timer.GetTime() - self.LastSevereLowOxygenAt) > self.SuffocationKillWindowSeconds
end

return objective
