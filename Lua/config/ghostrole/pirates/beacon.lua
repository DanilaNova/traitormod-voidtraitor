local function keepLife(client)
    Traitormod.LostLivesThisRound[Traitormod.GetClientAccountKey(client)] = false
end

local category = {}

category.Identifier = "pirates.beacon"

category.Roles = {
    {
        Identifier = "helper",
        Name = "GhostRoleBeaconPirateHelperName",
        Description = "GhostRoleBeaconPirateHelperDescription",
        Price = 0,
        Icon = "pirateclothes",
        Action = keepLife,
    },

    {
        Identifier = "captain",
        Name = "GhostRoleBeaconPirateCaptainName",
        Description = "GhostRoleBeaconPirateCaptainDescription",
        Price = 0,
        Icon = "pirateclothes",
        Action = keepLife,
    },
}

return category
