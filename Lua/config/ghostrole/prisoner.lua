local category = {}

category.Identifier = "prisoner"

category.Roles = {
    {
        Identifier = "prisoner",
        Name = "GhostRolePrisonerName",
        Description = "GhostRolePrisonerDescription",
        Price = 0,
        Icon = "handcuffs",
        Action = function(client)
            Traitormod.LostLivesThisRound[Traitormod.GetClientAccountKey(client)] = false
        end,
    },
}

return category
