local objective = Traitormod.RoleManager.Objectives.Objective:new()

objective.Name = "DestroyFuelRods"
objective.AmountPoints = 500
objective.Amount = 3

objective.Static = function()
    Hook.Add("item.deconstructed", "Traitormod.DestroyFuelRods.Deconstructed", function(item, deconstructor, userCharacter, allowRemove)
        Traitormod.RoleManager.CallObjectiveFunction("ItemDeconstructed", item, userCharacter, allowRemove)
    end)
end

function objective:UpdateText()
    self.Text = string.format(Traitormod.Language.ObjectiveDestroyFuelRods, self.Progress, self.RequiredAmount)
end

function objective:Start()
    local mainSub = Submarine.MainSub
    if mainSub == nil then return false end

    self.TrackedItems = {}
    self.DestroyedItems = {}
    self.PendingItems = {}
    self.Progress = 0

    local items = {}
    for _, item in pairs(mainSub.GetItems(false)) do
        if not item.Removed and item.Condition > 0 and item.HasTag("reactorfuel") then
            table.insert(items, item)
            self.TrackedItems[item] = true
        end
    end

    self.RequiredAmount = math.min(self.Amount or 3, #items)
    if self.RequiredAmount <= 0 then return false end

    self:UpdateText()
    return true
end

function objective:ItemDeconstructed(item, userCharacter, allowRemove)
    if userCharacter ~= self.Character or not allowRemove or not item.AllowDeconstruct then return end
    if not self.TrackedItems[item] or self.DestroyedItems[item] then return end

    self.PendingItems[item] = Timer.GetTime()
end

function objective:UpdatePendingItems()
    local now = Timer.GetTime()
    for item, startedAt in pairs(self.PendingItems) do
        if item.Removed then
            self.PendingItems[item] = nil
            if not self.DestroyedItems[item] then
                self.DestroyedItems[item] = true
                self.Progress = self.Progress + 1
                self:UpdateText()
            end
        elseif now - startedAt > 1 then
            self.PendingItems[item] = nil
        end
    end
end

function objective:IsCompleted()
    self:UpdatePendingItems()
    return self.Progress >= self.RequiredAmount
end

function objective:IsFailed()
    self:UpdatePendingItems()

    local available = 0
    for item in pairs(self.TrackedItems) do
        if not self.DestroyedItems[item] and not item.Removed then
            available = available + 1
        end
    end

    return self.Progress + available < self.RequiredAmount
end

return objective
