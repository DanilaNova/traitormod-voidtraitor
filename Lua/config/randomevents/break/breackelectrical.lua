local event = {}

event.Name = "BreackElectrical"
event.MinRoundTime = 10
event.MinIntensity = 0
event.MaxIntensity = 0.1
event.ChancePerMinute = 0.005
event.OnlyOncePerRound = false

local allowedItems = {"junctionbox", "supercapacitor", "battery", "smallpump", "navterminal", "pump", "statusmonitor", "reactor1", "engine", "Largeengine", "shuttleengine"}

event.Start = function ()
    for key, item in pairs(Submarine.MainSub.GetItems(true)) do
        for _, allowed in pairs(allowedItems) do
            if item.Prefab.Identifier.Value == allowed then
                item.Condition = item.Condition + -33
            end
        end
    end

    local text = Traitormod.Language.BreackElectrical
    Traitormod.RoundEvents.SendEventMessage(text, "GameModeIcon.sandbox")

    event.End()
end


event.End = function ()

end

return event
