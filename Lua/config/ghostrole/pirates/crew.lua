local category = {}

category.Identifier = "pirates.crew"

category.Roles = {
    {
        Identifier = "member",
        Name = "GhostRolePirateCrewName",
        Description = "GhostRolePirateCrewDescription",
        Price = 0,
        Icon = "pirateclothes",
        Action = function(client)
            Traitormod.LostLivesThisRound[Traitormod.GetClientAccountKey(client)] = false
        end,
    },
}

return category
