local function keepLife(client)
    Traitormod.LostLivesThisRound[Traitormod.GetClientAccountKey(client)] = false
end

local category = {}

category.Identifier = "clowncrate"

category.Roles = {
    {
        Identifier = "crawler_hatchling",
        Species = "crawler_hatchling",
        Name = "GhostRoleCrawlerHatchlingName",
        Description = "GhostRoleClownCrateCreatureDescription",
        Price = 0,
        Icon = "vt_preview_creature_crawler_hatchling",
        Action = keepLife,
    },

    {
        Identifier = "tigerthresher_hatchling",
        Species = "tigerthresher_hatchling",
        Name = "GhostRoleTigerthresherHatchlingName",
        Description = "GhostRoleClownCrateCreatureDescription",
        Price = 0,
        Icon = "vt_preview_creature_tigerthresher_hatchling",
        Action = keepLife,
    },

    {
        Identifier = "mudraptor_hatchling",
        Species = "mudraptor_hatchling",
        Name = "GhostRoleMudraptorHatchlingName",
        Description = "GhostRoleClownCrateCreatureDescription",
        Price = 0,
        Icon = "vt_preview_creature_mudraptor_hatchling",
        Action = keepLife,
    },

    {
        Identifier = "crawler_hatchlinghusk",
        Species = "Crawler_hatchlinghusk",
        Name = "GhostRoleCrawlerHuskName",
        Description = "GhostRoleClownCrateCreatureDescription",
        Price = 0,
        Icon = "vt_preview_creature_crawlerhusk",
        Action = keepLife,
    },

    {
        Identifier = "tigerthresher_hatchlinghusk",
        Species = "Tigerthresher_hatchlinghusk",
        Name = "GhostRoleTigerthresherHuskName",
        Description = "GhostRoleClownCrateCreatureDescription",
        Price = 0,
        Icon = "vt_preview_creature_tigerthresherhusk",
        Action = keepLife,
    },

    {
        Identifier = "mudraptor_hatchlinghusk",
        Species = "Mudraptor_hatchlinghusk",
        Name = "GhostRoleMudraptorHuskName",
        Description = "GhostRoleClownCrateCreatureDescription",
        Price = 0,
        Icon = "vt_preview_creature_huskmutantmudraptor",
        Action = keepLife,
    },

    {
        Identifier = "orangeboy",
        Species = "orangeboy",
        Name = "GhostRoleOrangeBoyName",
        Description = "GhostRoleClownCratePetDescription",
        Price = 0,
        Icon = "vt_preview_creature_orangeboy",
        Action = keepLife,
    },

    {
        Identifier = "balloon",
        Species = "balloon",
        Name = "GhostRoleBalloonName",
        Description = "GhostRoleClownCratePetDescription",
        Price = 0,
        Icon = "vt_preview_creature_balloon",
        Action = keepLife,
    },

    {
        Identifier = "psilotoad",
        Species = "psilotoad",
        Name = "GhostRolePsilotoadName",
        Description = "GhostRoleClownCratePetDescription",
        Price = 0,
        Icon = "vt_preview_creature_psilotoad",
        Action = keepLife,
    },

    {
        Identifier = "clown_orangeboy",
        Species = "Clown_Orangeboy",
        Name = "GhostRoleClownOrangeBoyName",
        Description = "GhostRoleClownCratePetDescription",
        Price = 0,
        Icon = "vt_preview_creature_clown_orangeboy",
        Action = keepLife,
    },

    {
        Identifier = "clown_peanut",
        Species = "Clown_Peanut",
        Name = "GhostRoleClownPeanutName",
        Description = "GhostRoleClownCratePetDescription",
        Price = 0,
        Icon = "vt_preview_creature_clown_peanut",
        Action = keepLife,
    },

    {
        Identifier = "clown_psilotoad",
        Species = "Clown_Psilotoad",
        Name = "GhostRoleClownPsilotoadName",
        Description = "GhostRoleClownCratePetDescription",
        Price = 0,
        Icon = "vt_preview_creature_clown_psilotoad",
        Action = keepLife,
    },

    {
        Identifier = "npc",
        Name = "GhostRoleClownCrateNpcName",
        Description = "GhostRoleClownCrateNpcDescription",
        Price = 0,
        Icon = "job:assistant",
        Action = keepLife,
    },
}

return category
