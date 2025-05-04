local event = {}

event.Name = "FullFixHull"
event.MinRoundTime = 10
event.MinIntensity = 0.8
event.MaxIntensity = 1
event.ChancePerMinute = 0.0025
event.OnlyOncePerRound = false

event.Start = function ()
    for key, wall in pairs(Structure.WallList) do
        if wall.Submarine == Submarine.MainSub then
            for i = 0, wall.SectionCount, 1 do
                wall.AddDamage(i, -1000)
            end
        end
    end

    local text = Traitormod.Language.FullFixHull
    Traitormod.RoundEvents.SendEventMessage(text, "GameModeIcon.sandbox")

    event.End()
end


event.End = function ()

end

return event