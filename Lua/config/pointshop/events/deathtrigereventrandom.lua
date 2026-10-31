local category = {}

category.Identifier = "deathtrigereventrandom"
category.Decoration = "huskinvite"

category.CanAccess = function(client)
    return client.Character == nil or client.Character.IsDead or not client.Character.IsHuman
end

category.Products = {
    {
        Identifier = "VentCreatures",
        Price = 1200,
        Limit = 3,
        IsLimitGlobal = true,
        PricePerLimit = 500,
        Timeout = 120,

        RoundPrice = {
            PriceReduction = 900,
            StartTime = 15,
            EndTime = 30,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("VentCreatures")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("VentCreatures")
        end
    },

    {
        Identifier = "ClownCrateSurprise",
        Price = 800,
        Limit = 5,
        IsLimitGlobal = true,
        PricePerLimit = 600,
        Timeout = 60,

        RoundPrice = {
            PriceReduction = 600,
            StartTime = 10,
            EndTime = 25,
        },
        CanBuy = function ()
            return not Traitormod.RoundEvents.IsEventActive("ClownCrateSurprise")
        end,

        Action = function ()
            Traitormod.RoundEvents.TriggerEvent("ClownCrateSurprise")
        end
    },
}

return category