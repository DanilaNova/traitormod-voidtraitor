local category = {}

category.Identifier = "pirates.hidden"

category.Roles = {
    {
        Identifier = "pirate",
        Name = "GhostRoleHiddenPirateName",
        Description = "GhostRoleHiddenPirateDescription",
        Price = 0,
        Icon = "pirateclothes",
        Action = function(client)
            Traitormod.LostLivesThisRound[Traitormod.GetClientAccountKey(client)] = false
        end,
    },
}

return category
