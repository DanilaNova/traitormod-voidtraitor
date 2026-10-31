local category = {}
local abilities = dofile(Traitormod.Path .. "/Lua/config/pointshop/utility/abilities.lua")

local function canBuyTurretEvent(eventName, slotIdentifier)
    if Traitormod.RoundEvents.IsEventActive(eventName) then
        return false, Traitormod.Language.PointshopCannotBeUsed
    end

    return abilities.CanBuyTurretAbility(nil, slotIdentifier)
end

local function markTurretEventTriggered(eventName)
    if Traitormod.RoundEvents ~= nil and Traitormod.RoundEvents.ThisRoundEvents ~= nil then
        if Traitormod.RoundEvents.ThisRoundEvents[eventName] == nil then
            Traitormod.RoundEvents.ThisRoundEvents[eventName] = 0
        end
        Traitormod.RoundEvents.ThisRoundEvents[eventName] = Traitormod.RoundEvents.ThisRoundEvents[eventName] + 1
    end

    if Traitormod.Stats ~= nil and Traitormod.Stats.AddStat ~= nil then
        pcall(function() Traitormod.Stats.AddStat("EventTriggered", eventName, 1) end)
    end
end

local function installTurretFromGhostShop(eventName, turretIdentifier, slotIdentifier)
    if Traitormod.RoundEvents.IsEventActive(eventName) then
        return false, Traitormod.Language.PointshopCannotBeUsed
    end

    local success, reason = abilities.InstallTurret(turretIdentifier, slotIdentifier, Traitormod.GetText("EuropeanForceTurretInstalled"))
    if not success then
        return false, reason or Traitormod.Language.PointshopCannotBeUsed
    end

    markTurretEventTriggered(eventName)
    return true
end

category.Identifier = "deathtrigerevent"
category.Decoration = "huskinvite"

category.CanAccess = function(client)
    return client.Character == nil or client.Character.IsDead or not client.Character.IsHuman
end

category.Products = {
    {
        Identifier = "FixHull",
        Price = 2400,
        Limit = 2,
        IsLimitGlobal = true,
        PricePerLimit = 300,
        Timeout = 60,

        RoundPrice = {
            PriceReduction = 750,
            StartTime = 10,
            EndTime = 20,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("FixHull")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("FixHull")
        end
    },

    {
        Identifier = "ElectricalFixDischarge",
        Price = 2400,
        Limit = 2,
        IsLimitGlobal = true,
        PricePerLimit = 300,
        Timeout = 60,

        RoundPrice = {
            PriceReduction = 750,
            StartTime = 10,
            EndTime = 20,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("ElectricalFixDischarge")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("ElectricalFixDischarge")
        end
    },

    {
        Identifier = "FullFixHull",
        Price = 4800,
        Limit = 2,
        IsLimitGlobal = true,
        PricePerLimit = 600,
        Timeout = 60,

        RoundPrice = {
            PriceReduction = 1000,
            StartTime = 20,
            EndTime = 30,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("FullFixHull")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("FullFixHull")
        end
    },

    {
        Identifier = "FullElectricalFixDischarge",
        Price = 4800,
        Limit = 2,
        IsLimitGlobal = true,
        PricePerLimit = 600,
        Timeout = 60,

        RoundPrice = {
            PriceReduction = 1000,
            StartTime = 20,
            EndTime = 30,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("FullElectricalFixDischarge")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("FullElectricalFixDischarge")
        end
    },

    {
        Identifier = "MaintenanceToolsDelivery",
        Price = 600,
        Limit = 2,
        IsLimitGlobal = true,
        PricePerLimit = 200,
        Timeout = 60,

        RoundPrice = {
            PriceReduction = 400,
            StartTime = 10,
            EndTime = 20,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("MaintenanceToolsDelivery")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("MaintenanceToolsDelivery")
        end
    },

    {
        Identifier = "MedicalDelivery",
        Price = 1500,
        Limit = 2,
        IsLimitGlobal = true,
        PricePerLimit = 300,
        Timeout = 60,

        RoundPrice = {
            PriceReduction = 750,
            StartTime = 15,
            EndTime = 25,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("MedicalDelivery")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("MedicalDelivery")
        end
    },

    {
        Identifier = "AmmoDelivery",
        Price = 600,
        Limit = 2,
        IsLimitGlobal = true,
        PricePerLimit = 200,
        Timeout = 60,

        RoundPrice = {
            PriceReduction = 250,
            StartTime = 10,
            EndTime = 20,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("AmmoDelivery")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("AmmoDelivery")
        end
    },

    {
        Identifier = "EmergencyTeam",
        Price = 3300,
        Limit = 2,
        IsLimitGlobal = true,
        PricePerLimit = 1000,
        Timeout = 60,

        RoundPrice = {
            PriceReduction = 2350,
            StartTime = 15,
            EndTime = 30,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("EmergencyTeam")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("EmergencyTeam")
        end
    },

    {
        Identifier = "CaptainHelmBoost",
        Price = 600,
        Limit = 2,
        IsLimitGlobal = true,
        PricePerLimit = 150,
        Timeout = 60,
        Subcategory = {
            { Identifier = "deathtrigereventabilities" },
            { Identifier = "abilities_captain" },
        },

        RoundPrice = {
            PriceReduction = 250,
            StartTime = 10,
            EndTime = 20,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("CaptainHelmBoost")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("CaptainHelmBoost")
        end
    },

    {
        Identifier = "SecurityMindSense",
        Price = 900,
        Limit = 2,
        IsLimitGlobal = true,
        PricePerLimit = 200,
        Timeout = 60,
        Subcategory = {
            { Identifier = "deathtrigereventabilities" },
            { Identifier = "abilities_security" },
        },

        RoundPrice = {
            PriceReduction = 300,
            StartTime = 10,
            EndTime = 20,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("SecurityMindSense")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("SecurityMindSense")
        end
    },

    {
        Identifier = "SecurityTurretCoilgun",
        Price = 2200,
        Limit = 1,
        IsLimitGlobal = true,
        PricePerLimit = 350,
        Subcategory = {
            { Identifier = "deathtrigereventabilities" },
            { Identifier = "abilities_security" },
            { Identifier = "abilities_security_turrets" },
        },

        RoundPrice = {
            PriceReduction = 700,
            StartTime = 15,
            EndTime = 30,
        },
        CanBuy = function ()
            return canBuyTurretEvent("SecurityTurretCoilgun", "turrethardpoint")
        end,

        Action = function ()
            return installTurretFromGhostShop("SecurityTurretCoilgun", "coilgun", "turrethardpoint")
        end
    },

    {
        Identifier = "SecurityTurretChaingun",
        Price = 2500,
        Limit = 1,
        IsLimitGlobal = true,
        PricePerLimit = 400,
        Subcategory = {
            { Identifier = "deathtrigereventabilities" },
            { Identifier = "abilities_security" },
            { Identifier = "abilities_security_turrets" },
        },

        RoundPrice = {
            PriceReduction = 800,
            StartTime = 15,
            EndTime = 30,
        },
        CanBuy = function ()
            return canBuyTurretEvent("SecurityTurretChaingun", "turrethardpoint")
        end,

        Action = function ()
            return installTurretFromGhostShop("SecurityTurretChaingun", "chaingun", "turrethardpoint")
        end
    },

    {
        Identifier = "SecurityTurretFlakcannon",
        Price = 2800,
        Limit = 1,
        IsLimitGlobal = true,
        PricePerLimit = 450,
        Subcategory = {
            { Identifier = "deathtrigereventabilities" },
            { Identifier = "abilities_security" },
            { Identifier = "abilities_security_turrets" },
        },

        RoundPrice = {
            PriceReduction = 900,
            StartTime = 15,
            EndTime = 30,
        },
        CanBuy = function ()
            return canBuyTurretEvent("SecurityTurretFlakcannon", "largeturrethardpoint")
        end,

        Action = function ()
            return installTurretFromGhostShop("SecurityTurretFlakcannon", "flakcannon", "largeturrethardpoint")
        end
    },

    {
        Identifier = "SecurityTurretPulseLaser",
        Price = 3000,
        Limit = 1,
        IsLimitGlobal = true,
        PricePerLimit = 500,
        Subcategory = {
            { Identifier = "deathtrigereventabilities" },
            { Identifier = "abilities_security" },
            { Identifier = "abilities_security_turrets" },
        },

        RoundPrice = {
            PriceReduction = 1000,
            StartTime = 15,
            EndTime = 30,
        },
        CanBuy = function ()
            return canBuyTurretEvent("SecurityTurretPulseLaser", "turrethardpoint")
        end,

        Action = function ()
            return installTurretFromGhostShop("SecurityTurretPulseLaser", "pulselaser", "turrethardpoint")
        end
    },

    {
        Identifier = "SecurityTurretDoubleCoilgun",
        Price = 3000,
        Limit = 1,
        IsLimitGlobal = true,
        PricePerLimit = 500,
        Subcategory = {
            { Identifier = "deathtrigereventabilities" },
            { Identifier = "abilities_security" },
            { Identifier = "abilities_security_turrets" },
        },

        RoundPrice = {
            PriceReduction = 1000,
            StartTime = 15,
            EndTime = 30,
        },
        CanBuy = function ()
            return canBuyTurretEvent("SecurityTurretDoubleCoilgun", "largeturrethardpoint")
        end,

        Action = function ()
            return installTurretFromGhostShop("SecurityTurretDoubleCoilgun", "doublecoilgun", "largeturrethardpoint")
        end
    },

    {
        Identifier = "SecurityTurretRailgun",
        Price = 3200,
        Limit = 1,
        IsLimitGlobal = true,
        PricePerLimit = 500,
        Subcategory = {
            { Identifier = "deathtrigereventabilities" },
            { Identifier = "abilities_security" },
            { Identifier = "abilities_security_turrets" },
        },

        RoundPrice = {
            PriceReduction = 1000,
            StartTime = 15,
            EndTime = 30,
        },
        CanBuy = function ()
            return canBuyTurretEvent("SecurityTurretRailgun", "largeturrethardpoint")
        end,

        Action = function ()
            return installTurretFromGhostShop("SecurityTurretRailgun", "railgun", "largeturrethardpoint")
        end
    },

    {
        Identifier = "MechanicMechanicalRepair",
        Price = 1100,
        Limit = 2,
        IsLimitGlobal = true,
        PricePerLimit = 250,
        Timeout = 60,
        Subcategory = {
            { Identifier = "deathtrigereventabilities" },
            { Identifier = "abilities_mechanic" },
        },

        RoundPrice = {
            PriceReduction = 400,
            StartTime = 10,
            EndTime = 20,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("MechanicMechanicalRepair")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("MechanicMechanicalRepair")
        end
    },

    {
        Identifier = "MechanicHullRepair",
        Price = 2000,
        Limit = 2,
        IsLimitGlobal = true,
        PricePerLimit = 300,
        Timeout = 60,
        Subcategory = {
            { Identifier = "deathtrigereventabilities" },
            { Identifier = "abilities_mechanic" },
        },

        RoundPrice = {
            PriceReduction = 500,
            StartTime = 10,
            EndTime = 20,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("MechanicHullRepair")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("MechanicHullRepair")
        end
    },


    {
        Identifier = "EngineerElectricalRepair",
        Price = 1000,
        Limit = 2,
        IsLimitGlobal = true,
        PricePerLimit = 250,
        Timeout = 60,
        Subcategory = {
            { Identifier = "deathtrigereventabilities" },
            { Identifier = "abilities_engineer" },
        },

        RoundPrice = {
            PriceReduction = 350,
            StartTime = 10,
            EndTime = 20,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("EngineerElectricalRepair")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("EngineerElectricalRepair")
        end
    },

    {
        Identifier = "MechanicSkillBoost",
        Price = 700,
        Limit = 2,
        IsLimitGlobal = true,
        PricePerLimit = 175,
        Timeout = 60,
        Subcategory = {
            { Identifier = "deathtrigereventabilities" },
            { Identifier = "abilities_mechanic" },
        },

        RoundPrice = {
            PriceReduction = 250,
            StartTime = 10,
            EndTime = 20,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("MechanicSkillBoost")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("MechanicSkillBoost")
        end
    },

    {
        Identifier = "EngineerSkillBoost",
        Price = 650,
        Limit = 2,
        IsLimitGlobal = true,
        PricePerLimit = 150,
        Timeout = 60,
        Subcategory = {
            { Identifier = "deathtrigereventabilities" },
            { Identifier = "abilities_engineer" },
        },

        RoundPrice = {
            PriceReduction = 200,
            StartTime = 10,
            EndTime = 20,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("EngineerSkillBoost")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("EngineerSkillBoost")
        end
    },

    {
        Identifier = "MedicSkillBoost",
        Price = 700,
        Limit = 2,
        IsLimitGlobal = true,
        PricePerLimit = 175,
        Timeout = 60,
        Subcategory = {
            { Identifier = "deathtrigereventabilities" },
            { Identifier = "abilities_medical" },
        },

        RoundPrice = {
            PriceReduction = 250,
            StartTime = 10,
            EndTime = 20,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("MedicSkillBoost")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("MedicSkillBoost")
        end
    },

    {
        Identifier = "SurgeonSkillBoost",
        Price = 700,
        Limit = 2,
        IsLimitGlobal = true,
        PricePerLimit = 175,
        Timeout = 60,
        Subcategory = {
            { Identifier = "deathtrigereventabilities" },
            { Identifier = "abilities_surgeon" },
        },

        RoundPrice = {
            PriceReduction = 250,
            StartTime = 10,
            EndTime = 20,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("SurgeonSkillBoost")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("SurgeonSkillBoost")
        end
    },
}

return category