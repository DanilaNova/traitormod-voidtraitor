local category = {}

category.Identifier = "deathtrigereventrandom"
category.Decoration = "huskinvite"

category.CanAccess = function(client)
    return client.Character == nil or client.Character.IsDead or not client.Character.IsHuman
end

category.Products = {
    {
        Identifier = "VentCreatures",
        Price = 2600,
        Limit = 2,
        IsLimitGlobal = true,
        PricePerLimit = 500,
        Timeout = 180,

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
        Price = 3200,
        Limit = 2,
        IsLimitGlobal = true,
        PricePerLimit = 600,
        Timeout = 180,

        RoundPrice = {
            PriceReduction = 1100,
            StartTime = 20,
            EndTime = 35,
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