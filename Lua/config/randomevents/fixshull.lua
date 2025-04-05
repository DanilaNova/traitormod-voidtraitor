local event = {}

event.Name = "FixHull"
event.MinRoundTime = 0
event.MinIntensity = 0.6
event.MaxIntensity = 1
event.ChancePerMinute = 0.05
event.OnlyOncePerRound = false

event.Start = function ()
    for key, wall in pairs(Structure.WallList) do
        if wall.Submarine == Submarine.MainSub then
            for i = 0, wall.SectionCount, 1 do
                wall.AddDamage(i, -50)
            end
        end
    end

    local text = Traitormod.Language.FixHull
    Traitormod.RoundEvents.SendEventMessage(text, "GameModeIcon.sandbox")

    event.End()
end


event.End = function ()

end

return event