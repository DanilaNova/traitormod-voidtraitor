local category = {}

category.Identifier = "deathtrigereventevil"
category.Decoration = "huskinvite"

category.CanAccess = function(client)
    return client.Character == nil or client.Character.IsDead or not client.Character.IsHuman
end

category.Products = {
    {
        Identifier = "BreackHull",
        Price = 12000,
        Limit = 3,
        IsLimitGlobal = true,
        PricePerLimit = 1000,
        Timeout = 300,

        RoundPrice = {
            PriceReduction = 3750,
            StartTime = 35,
            EndTime = 45,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("BreackHull")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("BreackHull")
        end
    },

    {
        Identifier = "BreackElectrical",
        Price = 8500,
        Limit = 2,
        IsLimitGlobal = true,
        PricePerLimit = 2250,
        Timeout = 300,

        RoundPrice = {
            PriceReduction = 1500,
            StartTime = 35,
            EndTime = 45,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("BreackElectrical")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("BreackElectrical")
        end
    },

    {
        Identifier = "KillElectrical",
        Price = 35000,
        Limit = 2,
        IsLimitGlobal = true,
        PricePerLimit = 2500,
        Timeout = 600,

        RoundPrice = {
            PriceReduction = 15000,
            StartTime = 45,
            EndTime = 60,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("KillElectrical")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("KillElectrical")
        end
    },

    {
        Identifier = "KillHull",
        Price = 45000,
        Limit = 1,
        IsLimitGlobal = true,
        PricePerLimit = 5000,
        Timeout = 600,

        RoundPrice = {
            PriceReduction = 20000,
            StartTime = 45,
            EndTime = 60,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("KillHull")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("KillHull")
        end
    },

    {
        Identifier = "randomizelights",
        Price = 400,
        Limit = 3,
        IsLimitGlobal = true,
        PricePerLimit = 100,
        Timeout = 150,

        RoundPrice = {
            PriceReduction = 350,
            StartTime = 5,
            EndTime = 15,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("RandomLights")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("RandomLights")
        end
    },

    {
        Identifier = "clownmagic",
        Price = 1000,
        Limit = 3,
        IsLimitGlobal = true,
        PricePerLimit = 250,
        Timeout = 150,

        RoundPrice = {
            PriceReduction = 400,
            StartTime = 15,
            EndTime = 25,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("ClownMagic")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("ClownMagic")
        end
    },

    {
        Identifier = "turnofflights",
        Price = 1200,
        Limit = 2,
        IsLimitGlobal = true,
        PricePerLimit = 250,
        Timeout = 150,

        RoundPrice = {
            PriceReduction = 400,
            StartTime = 10,
            EndTime = 20,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("LightsOff")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("LightsOff")
        end
    },

    {
        Identifier = "SuperBallastFlora",
        Price = 5500,
        Limit = 1,
        IsLimitGlobal = true,
        PricePerLimit = 500,
        Timeout = 300,

        RoundPrice = {
            PriceReduction = 1800,
            StartTime = 25,
            EndTime = 35,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("SuperBallastFlora")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("SuperBallastFlora")
        end
    },

    {
        Identifier = "turnoffcommunications",
        Price = 1500,
        Limit = 2,
        IsLimitGlobal = true,
        PricePerLimit = 400,
        Timeout = 150,

        RoundPrice = {
            PriceReduction = 500,
            StartTime = 20,
            EndTime = 30,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("CommunicationsOffline")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("CommunicationsOffline")
        end
    },

    {
        Identifier = "poisonoxygensupply",
        Price = 3300,
        Limit = 1,
        IsLimitGlobal = true,
        PricePerLimit = 500,
        Timeout = 150,
        Subcategory = {
            { Identifier = "traitor_sabotage_oxygensabotage" },
        },

        RoundPrice = {
            PriceReduction = 1000,
            StartTime = 35,
            EndTime = 45,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("OxygenGeneratorPoison")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("OxygenGeneratorPoison")
        end
    },

    {
        Identifier = "huskoxygensupply",
        Price = 3300,
        Limit = 1,
        IsLimitGlobal = true,
        PricePerLimit = 500,
        Timeout = 150,
        Subcategory = {
            { Identifier = "traitor_sabotage_oxygensabotage" },
        },

        RoundPrice = {
            PriceReduction = 1000,
            StartTime = 35,
            EndTime = 45,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("OxygenGeneratorHusk")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("OxygenGeneratorHusk")
        end
    },

    {
        Identifier = "OxygenSufforin",
        Price = 3900,
        Limit = 1,
        IsLimitGlobal = true,
        PricePerLimit = 500,
        Timeout = 180,
        Subcategory = {
            { Identifier = "traitor_sabotage_oxygensabotage" },
        },

        RoundPrice = {
            PriceReduction = 1200,
            StartTime = 25,
            EndTime = 35,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("OxygenSufforin")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("OxygenSufforin")
        end
    },

    {
        Identifier = "OxygenParalyzant",
        Price = 5400,
        Limit = 1,
        IsLimitGlobal = true,
        PricePerLimit = 700,
        Timeout = 180,
        Subcategory = {
            { Identifier = "traitor_sabotage_oxygensabotage" },
        },

        RoundPrice = {
            PriceReduction = 1500,
            StartTime = 30,
            EndTime = 40,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("OxygenParalyzant")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("OxygenParalyzant")
        end
    },

    {
        Identifier = "OxygenMorbusine",
        Price = 7500,
        Limit = 1,
        IsLimitGlobal = true,
        PricePerLimit = 1000,
        Timeout = 180,
        Subcategory = {
            { Identifier = "traitor_sabotage_oxygensabotage" },
        },

        RoundPrice = {
            PriceReduction = 2200,
            StartTime = 35,
            EndTime = 45,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("OxygenMorbusine")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("OxygenMorbusine")
        end
    },

    {
        Identifier = "OxygenCyanide",
        Price = 9600,
        Limit = 1,
        IsLimitGlobal = true,
        PricePerLimit = 1200,
        Timeout = 180,
        Subcategory = {
            { Identifier = "traitor_sabotage_oxygensabotage" },
        },

        RoundPrice = {
            PriceReduction = 2800,
            StartTime = 35,
            EndTime = 45,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("OxygenCyanide")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("OxygenCyanide")
        end
    },

    {
        Identifier = "ReactorShutdown",
        Price = 1500,
        Limit = 2,
        IsLimitGlobal = true,
        PricePerLimit = 300,
        Timeout = 150,

        RoundPrice = {
            PriceReduction = 500,
            StartTime = 10,
            EndTime = 20,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("ReactorShutdown")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("ReactorShutdown")
        end
    },

    {
        Identifier = "SupercapacitorFailure",
        Price = 3750,
        Limit = 2,
        IsLimitGlobal = true,
        PricePerLimit = 600,
        Timeout = 180,

        RoundPrice = {
            PriceReduction = 1250,
            StartTime = 20,
            EndTime = 30,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("SupercapacitorFailure")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("SupercapacitorFailure")
        end
    },

    {
        Identifier = "JunctionBoxOverload",
        Price = 9000,
        Limit = 1,
        IsLimitGlobal = true,
        PricePerLimit = 1000,
        Timeout = 240,

        RoundPrice = {
            PriceReduction = 2500,
            StartTime = 25,
            EndTime = 35,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("JunctionBoxOverload")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("JunctionBoxOverload")
        end
    },

    {
        Identifier = "WeakBallastFlora",
        Price = 4200,
        Limit = 1,
        IsLimitGlobal = true,
        PricePerLimit = 750,
        Timeout = 180,

        RoundPrice = {
            PriceReduction = 1400,
            StartTime = 25,
            EndTime = 35,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("WeakBallastFlora")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("WeakBallastFlora")
        end
    },

    {
        Identifier = "HiddenPirate",
        Price = 5500,
        Limit = 2,
        IsLimitGlobal = true,
        PricePerLimit = 500,
        Timeout = 150,

        RoundPrice = {
            PriceReduction = 2250,
            StartTime = 35,
            EndTime = 45,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("HiddenPirate")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("HiddenPirate")
        end
    },
}

return category