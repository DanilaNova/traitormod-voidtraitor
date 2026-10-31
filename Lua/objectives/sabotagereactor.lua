local objective = Traitormod.RoleManager.Objectives.Objective:new()

objective.Name = "SabotageReactor"
objective.AmountPoints = 2500

objective.Static = function()
    Hook.Patch("Barotrauma.KarmaManager", "OnReactorMeltdown", function(instance, ptable)
        Traitormod.RoleManager.CallObjectiveFunction("ReactorMeltdown", ptable["reactor"], ptable["character"])
    end, Hook.HookMethodType.Before)
end

function objective:Start()
    local mainSub = Submarine.MainSub
    if mainSub == nil then return false end

    local candidates = {}
    for _, item in pairs(mainSub.GetItems(false)) do
        if not item.Removed and item.IsInteractable(self.Character) then
            local reactor = item.GetComponentString("Reactor")
            if reactor ~= nil and not reactor.MeltedDownThisRound then
                table.insert(candidates, item)
            end
        end
    end

    if #candidates == 0 then return false end

    self.TargetItem = candidates[math.random(1, #candidates)]
    self.TargetReactor = self.TargetItem.GetComponentString("Reactor")
    self.CompletedBySaboteur = false
    self.HighlightCleared = false
    self.Text = Traitormod.Language.ObjectiveSabotageReactor

    local client = Traitormod.FindClientCharacter(self.Character)
    if client ~= nil then
        Traitormod.SetClientItemHighlight(client, self.TargetItem, true)
    end

    return true
end

function objective:ClearHighlight(client)
    if self.HighlightCleared then return end
    self.HighlightCleared = true

    if self.TargetItem == nil or self.TargetItem.Removed then return end
    client = client or Traitormod.FindClientCharacter(self.Character)
    if client ~= nil then
        Traitormod.SetClientItemHighlight(client, self.TargetItem, false)
    end
end

function objective:SyncClientState(client)
    if self.Awarded or self.Failed or self.HighlightCleared then return end
    if self.TargetItem == nil or self.TargetItem.Removed then return end
    Traitormod.SetClientItemHighlight(client, self.TargetItem, true)
end

function objective:ReactorMeltdown(item, character)
    if item ~= self.TargetItem or character ~= self.Character then return end

    self.CompletedBySaboteur = true
    self:ClearHighlight()
end

function objective:IsCompleted()
    return self.CompletedBySaboteur == true
end

function objective:IsFailed()
    if self.CompletedBySaboteur then return false end
    if self.TargetItem == nil or self.TargetItem.Removed or self.TargetReactor == nil then
        self:ClearHighlight()
        return true
    end
    if self.TargetReactor.MeltedDownThisRound then
        self:ClearHighlight()
        return true
    end
    return false
end

return objective
