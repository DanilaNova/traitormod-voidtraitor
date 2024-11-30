local category = {}

category.Identifier = "security"
category.Decoration = "security"

category.CanAccess = function(client)
    return client.Character and not client.Character.IsDead and 
    (client.Character.HasJob("securityofficer") or client.Character.HasJob("captain"))
end

category.Products = {
    {
        Identifier = "firemanscarrytalent",
        Price = 350,
        Limit = 1,
        IsLimitGlobal = false,
        Action = function (client, product, items)
            client.Character.GiveTalent("firemanscarry")
        end
    },

    {
        Price = 200,
        Limit = 3,
        IsLimitGlobal = false,
        Items = {"coilgunammobox"},
    },

    {
        Price = 100,
        Limit = 5,
        IsLimitGlobal = false,
        Items = {"handcuffs"},
    },

    {
        Price = 200,
        Limit = 2,
        IsLimitGlobal = false,
        Items = {"stunbaton", "batterycell"},
    },

    {
        Price = 200,
        Limit = 2,
        IsLimitGlobal = false,
        Items = {"stungun", "stungundart", "stungundart", "stungundart", "stungundart"},
    },

    {
        Identifier = "stungunammo",
        Price = 100,
        Limit = 1,
        IsLimitGlobal = false,
        Items = {"stungundart", "stungundart", "stungundart", "stungundart"},
    },

    {
        Identifier = "revolverammo",
        Price = 200,
        Limit = 2,
        IsLimitGlobal = false,
        Items = {"revolverround", "revolverround","revolverround", "revolverround", "revolverround", "revolverround"},
    },

    {
        Identifier = "smgammo",
        Price = 250,
        Limit = 2,
        IsLimitGlobal = false,
        Items = {"smgmagazine", "smgmagazine"},
    },

    {
        Identifier = "shotgunammo",
        Price = 250,
        Limit = 2,
        IsLimitGlobal = false,
        Items = {"shotgunshell", "shotgunshell", "shotgunshell", "shotgunshell", "shotgunshell", "shotgunshell", "shotgunshell", "shotgunshell"},
    },
	
    {
        Price = 400,
        Limit = 2,
        IsLimitGlobal = false,
        Items = {"hmgmagazine"},
    },
	
    {
        Price = 4000,
        Limit = 1,
        IsLimitGlobal = true,
        Items = {"hmg", "hmgmagazine"},
    },

    {
        Price = 350,
        Limit = 3,
        IsLimitGlobal = false,
        Items = {"stungrenade"},
    },

    {
        Price = 400,
        Limit = 1,
        IsLimitGlobal = false,
        Items = {"flamer", "incendiumfueltank"},
    },
	
    {
        Price = 1250,
        Limit = 1,
        IsLimitGlobal = true,
        Items = {"thermalgoggles"},
    },
	
    {
        Price = 2000,
        Limit = 1,
        IsLimitGlobal = true,
        Items = {"dirtybomb"},
    },
}

return category