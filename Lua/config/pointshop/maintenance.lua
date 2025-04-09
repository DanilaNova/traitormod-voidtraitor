local category = {}

category.Identifier = "maintenance"

category.Products = {
    {
        Price = 50,
        Limit = 2,
        Items = {"screwdriver"}
    },

    {
        Price = 50,
        Limit = 2,
        Items = {"wrench"}
    },
	
    {
        Price = 150,
        Limit = 1,
        Items = {"toolbelt"}
    },
	
	{
        Price = 375,
        Limit = 1,
        Items = {"artmod_toolbelt"}
    },

    {
        Price = 150,
        Limit = 4,
        Items = {"weldingtool", "weldingfueltank"}
    },

    {
        Price = 250,
        Limit = 2,
        Items = {"handheldstatusmonitor"}
    },

    {
        Price = 200,
        Limit = 4,
        Items = {"fixfoamgrenade", "fixfoamgrenade"}
    },

    {
        Price = 250,
        Limit = 2,
        Items = {"repairpack"}
    },

    {
        Identifier = "fuelrodlowquality",
        Price = 250,
        Limit = 10,
        Items = {{Identifier = "fuelrod", Condition = 9}},
    },
	
}

return category