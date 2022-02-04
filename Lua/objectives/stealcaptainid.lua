local objective = {}

objective.Name = "StealCaptainID"

objective.Start = function (character)
    objective.Character = character
end

objective.CheckCompleted = function ()
    for item in objective.Character.Inventory.AllItems do
        if item.Prefab.Identifier == "idcard" and string.find(item.Tags, "jobid:captain") then
            return true
        end
    end
end

objective.GetListText = function ()
    if objective.CheckCompleted() then
        return Traitormod.Language.Completed .. Traitormod.Language.ObjectiveStealCaptainID
    else
        return Traitormod.Language.ObjectiveStealCaptainID .. " (" .. string.format(Traitormod.Language.Points, objective.Config.AmountPoints) .. ")"
    end
end

objective.GetCompletedText = function ()
    return string.format(Traitormod.Language.ObjectiveCompleted, Traitormod.Language.ObjectiveStealCaptainID)
end

objective.Award = function (character)
    local client = Traitormod.FindClientCharacter(character)
    Traitormod.AddData(client, "Points", objective.Config.AmountPoints)
    objective.Awarded = true
end

return objective