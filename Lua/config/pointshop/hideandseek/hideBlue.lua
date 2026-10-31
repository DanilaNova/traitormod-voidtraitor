---@diagnostic disable-next-line: unknown-cast-variable
---@cast Traitormod.SelectedGamemode Gamemodes.HideAndSeekV2

---@module "adv2"
local ADV2 = dofile(Traitormod.Path .. "/Lua/config/pointshop/attackdefend/utility/adv2.lua")
local CreateClassProduct = ADV2.CreateClassProduct
local CreateClassSubcategory = ADV2.CreateClassSubcategory
ADV2 = nil

local ShopTeamID = CharacterTeamType.Team1

---@type Pointshop.Category
local category = {
    Identifier = "hideBlue",
    CanAccess = function(client)
        local entry = Traitormod.SelectedGamemode.Teams[ShopTeamID].Respawns[client.AccountId]
        return entry ~= nil and not entry.Forfeited and not entry.Spawned
    end,
    Products = {
        CreateClassProduct(ShopTeamID, {
            Identifier = "hide_hider_1",
            JobId = "assistant",
            Items = function()
                local clothes = { "vipclothes1", "vipclothes2", "vipclothes3" }
                local hats = { "captainscap1", "captainscap2", "captainscap3" }

                return {
                    ["vt_hideandseek_idcard"] = {
                        InvSlotType = InvSlotType.Card,
                        OnSpawn = function(card, spawnPoint)
                            for tag in spawnPoint.IdCardTags do
                                card.AddTag(tag)
                            end
                        end,
                    },
                    [clothes[math.random(1, #clothes)]] = {
                        InvSlotType = InvSlotType.InnerClothes,
                    },
                    [hats[math.random(1, #hats)]] = {
                        InvSlotType = InvSlotType.Head,
                    },
                    ["wrench"] = 1,
                    ["screwdriver"] = 1,
                    ["crowbar"] = 1,
                    ["weldingtool"] = {
                        Items = {
                            ["incendiumfueltank"] = 1,
                        },
                    },
                    ["plasmacutter"] = {
                        Items = {
                            ["oxygenitetank"] = 1,
                        },
                    },
                    ["flashlight"] = {
                        Items = {
                            ["fulguriumbatterycell"] = 1,
                        },
                    },
                    ["divingmask"] = {
                        Items = {
                            ["oxygenitetank"] = 1,
                        },
                    },
                    ["mudraptorshell"] = 1,
                    ["safetyharness"] = 1,
                    ["advancedgenesplicer"] = {
                        InvSlotType = InvSlotType.HealthInterface,
                        Items = {
                            ["geneticmaterialmantis"] = 1,
                            ["geneticmaterialmoloch"] = 1,
                        },
                    },
                    ["autoinjectorheadset"] = {
                        InvSlotType = InvSlotType.Headset,
                    },
                    ["medtoolbox"] = {
                        Items = {
                            ["suture"] = 16,
                            ["traumashears"] = 1,
                            ["adrenaline"] = 4,
                            ["antiparalysis"] = 2,
                            ["antibleeding2"] = 8,
                            ["pomegrenadeextract"] = 8,
                            ["antidama1"] = 8,
                            ["combatstimulantsyringe"] = 2,
                            ["needle"] = 1,
                        },
                    },
                    ["toolbelt"] = {
                        InvSlotType = InvSlotType.Bag,
                        Items = {
                            ["energydrink"] = 8,
                            ["stungrenade"] = 2,
                            ["syringegun"] = {
                                Items = {
                                    ["chloralhydrate"] = 2,
                                },
                            },
                            ["detonator"] = 1,
                            ["blackwire"] = 2,
                            ["delaycomponent"] = 1,
                        },
                    },
                }
            end,
        }),
    }
}

local classSubcategory = CreateClassSubcategory("hideandseek_hider_classes")
for _, product in ipairs(category.Products) do
    product.Subcategory = classSubcategory
end

return category
