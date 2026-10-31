local category = {}

category.Identifier = "saboteur"
category.Decoration = "clown"
category.FadeToBlack = true

category.CanAccess = function(client)
    if not client.Character or client.Character.IsDead then return false end

    local role = Traitormod.RoleManager.GetRole(client.Character)
    return role ~= nil and role.Name == "Saboteur"
end

category.Products = {
    {
        Price = 300,
        Limit = 1,
        IsLimitGlobal = false,
        Items = {"screwdriverhardened"},
    },

    {
        Price = 400,
        Limit = 1,
        IsLimitGlobal = false,
        Items = {"wrenchhardened"},
    },

    {
        Price = 600,
        Limit = 1,
        IsLimitGlobal = false,
        Items = {"screwdriverdementonite"},
    },

    {
        Price = 450,
        Limit = 1,
        IsLimitGlobal = false,
        Items = {"artmod_multitool"},
    },

    {
        Price = 150,
        Limit = 2,
        IsLimitGlobal = false,
        Items = {"wire", "wire", "wire", "wire"},
    },

    {
        Price = 600,
        Limit = 1,
        IsLimitGlobal = false,
        Items = {"radiojammer", "batterycell"},
    },

    {
        Price = 650,
        Limit = 2,
        IsLimitGlobal = false,
        Items = {"empgrenade"},
    },

    {
        Price = 400,
        Limit = 1,
        IsLimitGlobal = false,
        Items = {"respawndivingsuit"},
    },

    {
        Price = 500,
        Limit = 1,
        IsLimitGlobal = false,
        Items = {"plasmacutter", "oxygentank"},
    },

    {
        Price = 1600,
        Limit = 1,
        IsLimitGlobal = true,
        Items = {"plasmacutter_plus", "oxygenitetank"},
    },

    {
        Price = 1400,
        Limit = 1,
        IsLimitGlobal = false,
        Items = {"artmod_laserdrill", "batterycell"},
    },

    {
        Price = 1000,
        Limit = 1,
        IsLimitGlobal = false,
        Items = {"artmod_detonator", "artmod_redbottom"},
    },

    {
        Price = 700,
        Limit = 3,
        IsLimitGlobal = false,
        Items = {"uex"},
    },

    {
        Price = 1200,
        Limit = 1,
        IsLimitGlobal = false,
        Items = {"c4block"},
    },

    {
        Price = 350,
        Limit = 2,
        IsLimitGlobal = false,
        Items = {"fuelrod"},
    },
}

return category
