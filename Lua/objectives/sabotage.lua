local objective = Traitormod.RoleManager.Objectives.Objective:new()
local repairActions = LuaUserData.CreateEnumTable("Barotrauma.Items.Components.Repairable+FixActions")

objective.Name = "Sabotage"
objective.AmountPoints = 50

local sabotageComponents = {
    "PowerTransfer",
    "PowerContainer",
    "Pump",
    "OxygenGenerator",
    "Deconstructor",
    "Fabricator",
    "Engine",
    "Sonar",
    "Steering",
    "MiniMap",
}

local function isSabotageDevice(item, character)
    if item == nil or item.Removed or item.Submarine ~= Submarine.MainSub then return false end
    if not item.IsInteractable(character) then return false end
    if item.GetComponentString("Reactor") ~= nil then return false end

    local repairable = item.GetComponentString("Repairable")
    if repairable == nil or item.ConditionPercentage <= repairable.MinSabotageCondition then return false end

    for _, componentName in ipairs(sabotageComponents) do
        if item.GetComponentString(componentName) ~= nil then
            return true
        end
    end

    return false
end

function objective:Start()
    local mainSub = Submarine.MainSub
    if mainSub == nil then return false end

    local candidates = {}
    local alternatives = {}
    for _, item in pairs(mainSub.GetItems(false)) do
        if isSabotageDevice(item, self.Character) then
            table.insert(candidates, item)
            if item ~= self.ExcludedItem then
                table.insert(alternatives, item)
            end
        end
    end

    if #candidates == 0 then return false end

    local selection = #alternatives > 0 and alternatives or candidates
    self.TargetItem = selection[math.random(1, #selection)]
    self.CompletedBySabotage = false
    self.HighlightCleared = false
    self.Text = string.format(Traitormod.Language.ObjectiveSabotage, tostring(self.TargetItem.Name))

    local client = Traitormod.FindClientCharacter(self.Character)
    if client ~= nil then
        Traitormod.SetClientItemHighlight(client, self.TargetItem, true)
    end

    return true
end

function objective:StopRepairing(item, character, action)
    if self.CompletedBySabotage then return end
    if item ~= self.TargetItem or character ~= self.Character or action ~= repairActions.Sabotage then return end

    local repairable = item.GetComponentString("Repairable")
    if repairable == nil or item.ConditionPercentage > repairable.MinSabotageCondition then return end

    self.CompletedBySabotage = true
    self:ClearHighlight()
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

function objective:IsCompleted()
    return self.CompletedBySabotage == true
end

function objective:IsFailed()
    if self.CompletedBySabotage or self.TargetItem == nil then return false end
    if self.TargetItem.Removed then
        self:ClearHighlight()
        return true
    end

    local repairable = self.TargetItem.GetComponentString("Repairable")
    if repairable == nil or self.TargetItem.ConditionPercentage <= repairable.MinSabotageCondition then
        self:ClearHighlight()
        return true
    end

    return false
end

function objective:Fail(silent)
    self:ClearHighlight()
    Traitormod.RoleManager.Objectives.Objective.Fail(self, silent)
    if self.OnFailed ~= nil then
        self:OnFailed()
    end
end

return objective
