local objective = {}

objective.Name = "Objective"
objective.Text = "Complete the objective!"
objective.AmountPoints = 100
objective.EndRoundObjective = false
objective.DontLooseLives = false

objective.Awarded = false
objective.Failed = false

function objective:Static() end

function objective:Init(character)
    self.Character = character
end

function objective:Start()
    return true
end

function objective:IsCompleted()
    return true
end

function objective:TargetPreference(character) return true end

function objective:IsFailed()
    return false
end

function objective:Award()
    self.Awarded = true
    self.Failed = false

    if Traitormod.ObjectiveHud ~= nil then
        Traitormod.ObjectiveHud.CompleteObjective(self.Character, self, false)
    end

    local client = Traitormod.FindClientCharacter(self.Character)

    if client then 
        local points = Traitormod.AwardPoints(client, self.AmountPoints)
        local lives = Traitormod.AdjustLives(client, self.AmountLives)
        Traitormod.SendObjectiveCompleted(client, self.Text, points, lives)

        if self.DontLooseLives then
            Traitormod.LostLivesThisRound[Traitormod.GetClientAccountKey(client)] = true
        end
    end

    if self.OnAwarded ~= nil then
        self:OnAwarded()
    end

    local role = Traitormod.RoleManager.GetRole(self.Character)
    if role ~= nil and Traitormod.ObjectiveHud ~= nil then
        Traitormod.ObjectiveHud.SyncRoleLog(role)
    end
end

function objective:Fail(silent)
    self.Failed = true

    if Traitormod.ObjectiveHud ~= nil then
        Traitormod.ObjectiveHud.CompleteObjective(self.Character, self, true)
    end
    
    local client = Traitormod.FindClientCharacter(self.Character)

    if client and not silent then
        Traitormod.SendObjectiveFailed(client, self.Text)
    end

    local role = Traitormod.RoleManager.GetRole(self.Character)
    if role ~= nil and Traitormod.ObjectiveHud ~= nil then
        Traitormod.ObjectiveHud.SyncRoleLog(role)
    end
end

function objective:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    return o
end

return objective
