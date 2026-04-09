local category = {}
local abilities = dofile(Traitormod.Path .. "/Lua/config/pointshop/utility/abilities.lua")

category.Identifier = "abilities"
category.Decoration = "gambler"

category.CanAccess = function(client)
    return abilities.IsEligibleCharacter(client.Character)
end

category.Products = {
    {
        Identifier = "CaptainHelmBoost",
        Price = 600,
        Limit = 1,
        IsLimitGlobal = false,
        VisibleJobs = { "captain" },
        Action = function(client)
            if abilities.ApplySkillBuff(client.Character, { helm = 100 }, 300, Traitormod.Language.CaptainHelmBoost) then
                return true
            end

            return false, Traitormod.Language.PointshopCannotBeUsed
        end,
    },

    {
        Identifier = "SecurityMindSense",
        Price = 900,
        Limit = 1,
        IsLimitGlobal = false,
        VisibleJobs = { "securityofficer" },
        Action = function(client)
            if abilities.ApplyAfflictions(client.Character, { mindsense = 600, psychosis = 20 }, Traitormod.Language.SecurityMindSense) then
                return true
            end

            return false, Traitormod.Language.PointshopCannotBeUsed
        end,
    },

    {
        Identifier = "SecurityTurretCoilgun",
        Price = 800,
        Limit = 1,
        IsLimitGlobal = true,
        Subcategory = {
            { Identifier = "abilities_security_turrets" },
        },
        VisibleJobs = { "securityofficer" },
        CanBuy = function(client)
            return abilities.CanBuyTurretAbility(client, "turrethardpoint")
        end,
        Action = function()
            local success, reason = abilities.InstallTurret("coilgun", "turrethardpoint")
            if success then
                return true
            end

            return false, reason or Traitormod.Language.PointshopCannotBeUsed
        end,
    },

    {
        Identifier = "SecurityTurretChaingun",
        Price = 1200,
        Limit = 1,
        IsLimitGlobal = true,
        Subcategory = {
            { Identifier = "abilities_security_turrets" },
        },
        VisibleJobs = { "securityofficer" },
        CanBuy = function(client)
            return abilities.CanBuyTurretAbility(client, "turrethardpoint")
        end,
        Action = function()
            local success, reason = abilities.InstallTurret("chaingun", "turrethardpoint")
            if success then
                return true
            end

            return false, reason or Traitormod.Language.PointshopCannotBeUsed
        end,
    },

    {
        Identifier = "SecurityTurretFlakcannon",
        Price = 2000,
        Limit = 1,
        IsLimitGlobal = true,
        Subcategory = {
            { Identifier = "abilities_security_turrets" },
        },
        VisibleJobs = { "securityofficer" },
        CanBuy = function(client)
            return abilities.CanBuyTurretAbility(client, "largeturrethardpoint")
        end,
        Action = function()
            local success, reason = abilities.InstallTurret("flakcannon", "largeturrethardpoint")
            if success then
                return true
            end

            return false, reason or Traitormod.Language.PointshopCannotBeUsed
        end,
    },

    {
        Identifier = "SecurityTurretPulseLaser",
        Price = 1800,
        Limit = 1,
        IsLimitGlobal = true,
        Subcategory = {
            { Identifier = "abilities_security_turrets" },
        },
        VisibleJobs = { "securityofficer" },
        CanBuy = function(client)
            return abilities.CanBuyTurretAbility(client, "turrethardpoint")
        end,
        Action = function()
            local success, reason = abilities.InstallTurret("pulselaser", "turrethardpoint")
            if success then
                return true
            end

            return false, reason or Traitormod.Language.PointshopCannotBeUsed
        end,
    },

    {
        Identifier = "SecurityTurretDoubleCoilgun",
        Price = 2100,
        Limit = 1,
        IsLimitGlobal = true,
        Subcategory = {
            { Identifier = "abilities_security_turrets" },
        },
        VisibleJobs = { "securityofficer" },
        CanBuy = function(client)
            return abilities.CanBuyTurretAbility(client, "largeturrethardpoint")
        end,
        Action = function()
            local success, reason = abilities.InstallTurret("doublecoilgun", "largeturrethardpoint")
            if success then
                return true
            end

            return false, reason or Traitormod.Language.PointshopCannotBeUsed
        end,
    },

    {
        Identifier = "SecurityTurretRailgun",
        Price = 2300,
        Limit = 1,
        IsLimitGlobal = true,
        Subcategory = {
            { Identifier = "abilities_security_turrets" },
        },
        VisibleJobs = { "securityofficer" },
        CanBuy = function(client)
            return abilities.CanBuyTurretAbility(client, "largeturrethardpoint")
        end,
        Action = function()
            local success, reason = abilities.InstallTurret("railgun", "largeturrethardpoint")
            if success then
                return true
            end

            return false, reason or Traitormod.Language.PointshopCannotBeUsed
        end,
    },

    {
        Identifier = "MechanicMechanicalRepair",
        Price = 350,
        Limit = 1,
        IsLimitGlobal = false,
        VisibleJobs = { "mechanic" },
        Action = function()
            if abilities.RepairMechanicalDevices(0.15) then
                return true
            end

            return false, Traitormod.Language.PointshopCannotBeUsed
        end,
    },

    {
        Identifier = "MechanicHullRepair",
        Price = 750,
        Limit = 1,
        IsLimitGlobal = false,
        VisibleJobs = { "mechanic" },
        Action = function()
            if abilities.RepairHull(0.50) then
                return true
            end

            return false, Traitormod.Language.PointshopCannotBeUsed
        end,
    },

    {
        Identifier = "MechanicSkillBoost",
        Price = 300,
        Limit = 1,
        IsLimitGlobal = false,
        VisibleJobs = { "mechanic" },
        Action = function(client)
            if abilities.ApplySkillBuff(client.Character, { mechanical = 100 }, 300, Traitormod.Language.MechanicSkillBoost) then
                return true
            end

            return false, Traitormod.Language.PointshopCannotBeUsed
        end,
    },

    {
        Identifier = "EngineerElectricalRepair",
        Price = 350,
        Limit = 1,
        IsLimitGlobal = false,
        VisibleJobs = { "engineer" },
        Action = function()
            if abilities.RepairElectricalDevices(0.10) then
                return true
            end

            return false, Traitormod.Language.PointshopCannotBeUsed
        end,
    },

    {
        Identifier = "EngineerSkillBoost",
        Price = 300,
        Limit = 1,
        IsLimitGlobal = false,
        VisibleJobs = { "engineer" },
        Action = function(client)
            if abilities.ApplySkillBuff(client.Character, { electrical = 100 }, 300, Traitormod.Language.EngineerSkillBoost) then
                return true
            end

            return false, Traitormod.Language.PointshopCannotBeUsed
        end,
    },

    {
        Identifier = "MedicSkillBoost",
        Price = 500,
        Limit = 1,
        IsLimitGlobal = false,
        VisibleJobs = { "medicaldoctor" },
        Action = function(client)
            if abilities.ApplySkillBuff(client.Character, { medical = 100, surgery = 70 }, 300, Traitormod.Language.MedicSkillBoost) then
                return true
            end

            return false, Traitormod.Language.PointshopCannotBeUsed
        end,
    },

    {
        Identifier = "SurgeonSkillBoost",
        Price = 750,
        Limit = 1,
        IsLimitGlobal = false,
        VisibleJobs = { "surgeon" },
        Action = function(client)
            if abilities.ApplySkillBuff(client.Character, { surgery = 100, medical = 70 }, 300, Traitormod.Language.SurgeonSkillBoost) then
                return true
            end

            return false, Traitormod.Language.PointshopCannotBeUsed
        end,
    },
}

return category
