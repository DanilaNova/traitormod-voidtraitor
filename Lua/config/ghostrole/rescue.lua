local function keepLife(client)
    Traitormod.LostLivesThisRound[Traitormod.GetClientAccountKey(client)] = false
end

local category = {}

category.Identifier = "rescue"

category.Roles = {
    {
        Identifier = "beacon",
        Name = "GhostRoleBeaconRescueName",
        Description = "GhostRoleBeaconRescueDescription",
        Price = 0,
        Icon = "job:assistant",
        Action = keepLife,
    },

    {
        Identifier = "wreck",
        Name = "GhostRoleWreckRescueName",
        Description = "GhostRoleWreckRescueDescription",
        Price = 0,
        Icon = "job:assistant",
        Action = keepLife,
    },
}

return category
