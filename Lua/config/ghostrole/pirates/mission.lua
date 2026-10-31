local category = {}

category.Identifier = "pirates.mission"

category.Roles = {
    {
        Identifier = "pirate",
        Name = "GhostRolePirateMissionName",
        Description = "GhostRolePirateMissionDescription",
        Price = 0,
        Icon = "pirateclothes",
        Action = function(client)
            Traitormod.LostLivesThisRound[Traitormod.GetClientAccountKey(client)] = false
        end,
    },
}

return category
