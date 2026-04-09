local event = {}

event.Name = "ReactorShutdown"
event.MinRoundTime = 10
event.MinIntensity = 0
event.MaxIntensity = 1
event.ChancePerMinute = 0.0005
event.OnlyOncePerRound = true

local function syncItemComponent(item, component)
    if item == nil or component == nil then
        return
    end

    pcall(function()
        item.CreateServerEvent(component, component)
    end)
end

event.CanStart = function()
    return Submarine.MainSub ~= nil
end

event.Start = function()
    local count = 0

    for _, item in pairs(Submarine.MainSub.GetItems(true)) do
        local reactor = item.GetComponentString("Reactor")
        if reactor ~= nil then
            reactor.TargetFissionRate = 0
            reactor.TargetTurbineOutput = 0
            reactor.FissionRate = 0
            reactor.TurbineOutput = 0
            reactor.PowerOn = false

            pcall(function()
                reactor.RequestShutdown()
            end)

            syncItemComponent(item, reactor)
            count = count + 1
        end
    end

    if count > 0 then
        Traitormod.RoundEvents.SendEventMessage(Traitormod.Language.ReactorShutdown, "GameModeIcon.PVP", Color.Red)
    end

    event.End()
end

event.End = function()
end

return event
