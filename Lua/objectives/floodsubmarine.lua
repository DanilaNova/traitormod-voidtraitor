local objective = Traitormod.RoleManager.Objectives.Objective:new()

objective.Name = "FloodSubmarine"
objective.AmountPoints = 400
objective.RequiredFloodPercent = 80
objective.CheckInterval = 1

local function getFloodPercent(hulls, totalVolume)
    if totalVolume <= 0 then return 0 end

    local waterVolume = 0
    for _, hull in ipairs(hulls) do
        if hull ~= nil and not hull.Removed then
            waterVolume = waterVolume + (hull.WaterVolume or 0)
        end
    end

    return waterVolume / totalVolume * 100
end

function objective:Start()
    local mainSub = Submarine.MainSub
    if mainSub == nil then return false end

    self.Hulls = {}
    self.TotalVolume = 0
    for _, hull in pairs(mainSub.GetHulls(false)) do
        local volume = hull.Volume or 0
        if volume > 0 then
            table.insert(self.Hulls, hull)
            self.TotalVolume = self.TotalVolume + volume
        end
    end

    if self.TotalVolume <= 0 then return false end

    local required = self.RequiredFloodPercent or 80
    if getFloodPercent(self.Hulls, self.TotalVolume) >= required then return false end

    self.NextCheckAt = 0
    self.Text = string.format(Traitormod.Language.ObjectiveFloodSubmarine, required)
    return true
end

function objective:IsCompleted()
    local now = Timer.GetTime()
    if now < self.NextCheckAt then return false end
    self.NextCheckAt = now + (self.CheckInterval or 1)

    return getFloodPercent(self.Hulls, self.TotalVolume) >= (self.RequiredFloodPercent or 80)
end

return objective
