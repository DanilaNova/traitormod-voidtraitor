local category = {}

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
        Timeout = 150,

        RoundPrice = {
            PriceReduction = 750,
            StartTime = 10,
            EndTime = 20,
        },
        CanBuy = function (client, product)
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
        Timeout = 150,

        RoundPrice = {
            PriceReduction = 750,
            StartTime = 10,
            EndTime = 20,
        },
        CanBuy = function (client, product)
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
        Timeout = 150,

        RoundPrice = {
            PriceReduction = 1000,
            StartTime = 20,
            EndTime = 30,
        },
        CanBuy = function (client, product)
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
        Timeout = 150,

        RoundPrice = {
            PriceReduction = 1000,
            StartTime = 20,
            EndTime = 30,
        },
        CanBuy = function (client, product)
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
        Timeout = 150,

        RoundPrice = {
            PriceReduction = 400,
            StartTime = 10,
            EndTime = 20,
        },
        CanBuy = function (client, product)
            return not Traitormod.RoundEvents.IsEventActive("MaintenanceToolsDelivery")
        end,
		
        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("MaintenanceToolsDelivery")
        end
	},
	
	{
        Identifier = "MedicalDelivery",
        Price = 1000,
        Limit = 2,
        IsLimitGlobal = true,
        PricePerLimit = 300,
        Timeout = 150,

        RoundPrice = {
            PriceReduction = 500,
            StartTime = 15,
            EndTime = 25,
        },
        CanBuy = function (client, product)
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
        Timeout = 150,

        RoundPrice = {
            PriceReduction = 250,
            StartTime = 10,
            EndTime = 20,
        },
        CanBuy = function (client, product)
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
        Timeout = 150,

        RoundPrice = {
            PriceReduction = 2350,
            StartTime = 15,
            EndTime = 30,
        },
        CanBuy = function (client, product)
            return not Traitormod.RoundEvents.IsEventActive("EmergencyTeam")
        end,
		
        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("EmergencyTeam")
        end
	},
}
	
return category