local category = {}

category.Name = "Security"
--category.Decoration = "clown"

category.CanAccess = function(client)
    return client.Character and not client.Character.IsDead and client.Character.HasJob("securityofficer")
end

category.Products = {

    {
        Name = "Handcuffs",
        Price = 100,
        Limit = 5,
        IsLimitGlobal = false,
        Items = {"handcuffs"},
    },

    {
        Name = "Stun Baton",
        Price = 200,
        Limit = 2,
        IsLimitGlobal = false,
        Items = {"stunbaton", "batterycell"},
    },

    {
        Name = "Stun Gun",
        Price = 500,
        Limit = 1,
        IsLimitGlobal = false,
        Items = {"stungun", "stungundart", "stungundart", "stungundart", "stungundart"},
    },

    {
        Name = "Stun Gun Ammo (x4)",
        Price = 100,
        Limit = 1,
        IsLimitGlobal = false,
        Items = {"stungundart", "stungundart", "stungundart", "stungundart"},
    },

    {
        Name = "Revolver Ammo (x6)",
        Price = 250,
        Limit = 1,
        IsLimitGlobal = false,
        Items = {"revolverround", "revolverround","revolverround", "revolverround", "revolverround", "revolverround"},
    },

    {
        Name = "SMG Magazine (x2)",
        Price = 350,
        Limit = 5,
        IsLimitGlobal = false,
        Items = {"smgmagazine", "smgmagazine"},
    },

    {
        Name = "Shotgun Shells (x8)",
        Price = 300,
        Limit = 5,
        IsLimitGlobal = false,
        Items = {"shotgunshell", "shotgunshell", "shotgunshell", "shotgunshell", "shotgunshell", "shotgunshell", "shotgunshell", "shotgunshell"},
    },

    {
        Name = "Stun Grenade",
        Price = 400,
        Limit = 3,
        IsLimitGlobal = false,
        Items = {"stungrenade"},
    },

    {
        Name = "Flamer",
        Price = 800,
        Limit = 1,
        IsLimitGlobal = false,
        Items = {"flamer", "incendiumfueltank"},
    },

}

return category