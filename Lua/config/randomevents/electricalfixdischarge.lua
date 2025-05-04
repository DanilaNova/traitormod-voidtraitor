local event = {}

event.Name = "ElectricalFixDischarge"
event.MinRoundTime = 0
event.MinIntensity = 0.5
event.MaxIntensity = 1
event.ChancePerMinute = 0.05
event.OnlyOncePerRound = false

local allowedItems = {"junctionbox", "supercapacitor", "battery", "smallpump", "navterminal", "pump", "statusmonitor", "reactor1", "engine", "Largeengine", "shuttleengine"}

event.Start = function ()
    for key, item in pairs(Submarine.MainSub.GetItems(true)) do
        for _, allowed in pairs(allowedItems) do
            if item.Prefab.Identifier.Value == allowed then
                item.Condition = item.Condition + 33
            end
        end
    end

    local text = Traitormod.Language.ElectricalFixDischarge
    Traitormod.RoundEvents.SendEventMessage(text, "GameModeIcon.sandbox")

    event.End()
end


event.End = function ()

end

return event