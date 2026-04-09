local event = {}

event.Name = "WeakBallastFlora"
event.MinRoundTime = 5
event.MinIntensity = 0
event.MaxIntensity = 1
event.ChancePerMinute = 0.02
event.OnlyOncePerRound = true

local function isBallastPump(pump)
    if pump == nil or pump.Item == nil then
        return false
    end

    local ok, ballastHulls = pcall(function()
        return pump.BallastHulls
    end)

    if ok and ballastHulls ~= nil and ballastHulls.Count ~= nil and ballastHulls.Count > 0 then
        return true
    end

    local hull = pump.Item.CurrentHull
    if hull ~= nil and hull.RoomName ~= nil then
        local roomName = string.lower(tostring(hull.RoomName))
        return string.find(roomName, "ballast", 1, true) ~= nil
            or string.find(roomName, "bilge", 1, true) ~= nil
            or string.find(roomName, "airlock", 1, true) ~= nil
    end

    return false
end

local function getBallastPumps()
    local pumps = {}

    if Submarine.MainSub == nil then
        return pumps
    end

    for _, item in pairs(Submarine.MainSub.GetItems(true)) do
        local pump = item.GetComponentString("Pump")
        if pump ~= nil and isBallastPump(pump) then
            table.insert(pumps, pump)
        end
    end

    return pumps
end

event.CanStart = function()
    return #getBallastPumps() > 0
end

event.Start = function()
    local pumps = getBallastPumps()
    local infectCount = math.min(#pumps, math.random(1, 3))

    for i = 1, infectCount, 1 do
        local index = math.random(#pumps)
        local pump = pumps[index]
        table.remove(pumps, index)

        pump.InfectBallast("ballastflora", true)
        pump.Item.CreateServerEvent(pump, pump)
    end

    Traitormod.RoundEvents.SendEventMessage(Traitormod.Language.WeakBallastFlora, "EndRoundButton", Color(155, 255, 155, 255))
    event.End()
end

event.End = function()
end

return event
