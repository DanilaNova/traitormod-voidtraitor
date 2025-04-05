local event = {}

event.Name = "FullElectricalFixDischarge"
event.MinRoundTime = 15
event.MinIntensity = 0
event.MaxIntensity = 0.05
event.ChancePerMinute = 0.001
event.OnlyOncePerRound = false

local allowedItems = {"junctionbox", "supercapacitor", "battery", "smallpump", "navterminal", "pump", "statusmonitor", "reactor1", "engine", "Largeengine", "shuttleengine"}

event.Start = function ()
    for key, item in pairs(Submarine.MainSub.GetItems(true)) do
        for _, allowed in pairs(allowedItems) do
            if item.Prefab.Identifier.Value == allowed then
                item.Condition = item.Condition + 100
            end
        end
    end

    local text = Traitormod.Language.FullElectricalFixDischarge
    Traitormod.RoundEvents.SendEventMessage(text, "fullGameModeIcon.sandbox")

    event.End()
end


event.End = function ()

end

return event