local category = {}

category.Identifier = "pirates.wreck"

category.Roles = {
    {
        Identifier = "pirate",
        Name = "GhostRoleWreckPirateName",
        Description = "GhostRoleWreckPirateDescription",
        Price = 0,
        Icon = "pirateclothes",
        Action = function(client)
            Traitormod.LostLivesThisRound[Traitormod.GetClientAccountKey(client)] = false
        end,
    },
}

return category
