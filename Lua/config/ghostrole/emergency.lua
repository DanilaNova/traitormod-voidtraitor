local category = {}

category.Identifier = "emergency"

category.Roles = {
    {
        Identifier = "member",
        Name = "GhostRoleEmergencyName",
        Description = "GhostRoleEmergencyDescription",
        Price = 0,
        Icon = "job:assistant",
        Action = function(client)
            Traitormod.LostLivesThisRound[Traitormod.GetClientAccountKey(client)] = false
        end,
    },
}

return category
