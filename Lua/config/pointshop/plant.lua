local category = {}

category.Identifier = "plant"

category.Products = {
    {
        Price = 150,
        Limit = 8,
        Items = {"paralyxis"}
    },

    {
        Price = 70,
        Limit = 5,
        Items = {"aquaticpoppy"}
    },

    {
        Price = 50,
        Limit = 5,
        Items = {"elastinplant"}
    },

    {
        Price = 60,
        Limit = 5,
        Items = {"fiberplant"}
    },

    {
        Price = 65,
        Limit = 5,
        Items = {"yeastshroom"}
    },

    {
        Price = 600,
        Limit = 5,
        IsLimitGlobal = true,
        Items = {"slimebacteria"}
    },
	
	{
        Identifier = "gardeningkit",
        Price = 100,
        Limit = 2,
        Items = {"raptorbaneseed", "creepingorangevineseed", "saltvineseed", "tobaccovineseed", "smallplanter", "fertilizer", "wateringcan"}
    },
}

return category