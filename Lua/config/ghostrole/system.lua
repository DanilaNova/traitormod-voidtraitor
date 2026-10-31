local category = {}

category.Identifier = "system"

category.Roles = {
    {
        Identifier = "manual",
        Name = "GhostRoleManualName",
        Description = "GhostRoleManualDescription",
        Price = 0,
        Icon = "character",
        Action = function(client)
            Traitormod.LostLivesThisRound[Traitormod.GetClientAccountKey(client)] = false
        end,
    },

    {
        Identifier = "disconnected",
        Name = "GhostRoleDisconnectedName",
        Description = "GhostRoleDisconnectedDescription",
        Price = 0,
        Icon = "character",
    },
}

return category
