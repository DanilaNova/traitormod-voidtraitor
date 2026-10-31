---@diagnostic disable-next-line: unknown-cast-variable
---@cast Traitormod.SelectedGamemode Gamemodes.HideAndSeekV2

---@module "adv2"
local ADV2 = dofile(Traitormod.Path .. "/Lua/config/pointshop/attackdefend/utility/adv2.lua")
local CreateClassProduct = ADV2.CreateClassProduct
local CreateClassSubcategory = ADV2.CreateClassSubcategory
ADV2 = nil

local ShopTeamID = CharacterTeamType.Team2

---@type Pointshop.Category
local category = {
    Identifier = "hideRed",
    CanAccess = function(client)
        local entry = Traitormod.SelectedGamemode.Teams[ShopTeamID].Respawns[client.AccountId]
        return entry ~= nil and not entry.Forfeited and not entry.Spawned
    end,
    Products = {
        CreateClassProduct(ShopTeamID, {
            Identifier = "hide_seeker_1",
            JobId = "securityofficer",
            Items = {
                ["idcard"] = {
                    InvSlotType = InvSlotType.Card,
                    OnSpawn = function(card, spawnPoint, character)
                        card.GetComponentString("IdCard").Initialize(spawnPoint, character)
                    end,
                },
                ["headset"] = {
                    InvSlotType = InvSlotType.Headset,
                },
            },
        }),
        CreateClassProduct(ShopTeamID, {
            Identifier = "hide_seeker_2",
            JobId = "captain",
            Items = {
                ["idcard"] = {
                    InvSlotType = InvSlotType.Card,
                    OnSpawn = function(card, spawnPoint, character)
                        card.GetComponentString("IdCard").Initialize(spawnPoint, character)
                    end,
                },
                ["headset"] = {
                    InvSlotType = InvSlotType.Headset,
                },
            },
        }),
    }
}

local classSubcategory = CreateClassSubcategory("hideandseek_seeker_classes")
for _, product in ipairs(category.Products) do
    product.Subcategory = classSubcategory
end

return category
