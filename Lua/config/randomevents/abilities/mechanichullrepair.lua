local event = {}

event.Name = "MechanicHullRepair"
event.MinRoundTime = 10
event.MinIntensity = 0
event.MaxIntensity = 1
event.ChancePerMinute = 0.0005
event.OnlyOncePerRound = true

local function isValidTarget(character)
    return character ~= nil
        and character.IsHuman
        and not character.IsDead
        and character.TeamID == CharacterTeamType.Team1
        and character.HasJob("mechanic")
        and not Traitormod.RoleManager.IsAntagonist(character)
end

local function hasValidTarget()
    for _, character in pairs(Character.CharacterList) do
        if isValidTarget(character) then
            return true
        end
    end

    return false
end

event.CanStart = function()
    return Submarine.MainSub ~= nil and hasValidTarget()
end

event.Start = function()
    local repaired = 0

    for _, wall in pairs(Structure.WallList) do
        if wall.Submarine == Submarine.MainSub then
            for i = 0, wall.SectionCount, 1 do
                wall.AddDamage(i, -(wall.MaxHealth * 0.50))
            end
            repaired = repaired + 1
        end
    end

    if repaired > 0 then
        Traitormod.RoundEvents.SendEventMessage(Traitormod.Language.MechanicHullRepair, "GameModeIcon.sandbox", Color.Yellow)
    end

    event.End()
end

event.End = function()
end

return event
