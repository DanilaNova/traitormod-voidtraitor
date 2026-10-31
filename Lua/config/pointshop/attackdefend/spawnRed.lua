---@diagnostic disable-next-line: unknown-cast-variable
---@cast Traitormod.SelectedGamemode Gamemodes.AttackDefendV2

---@module "adv2"
local ADV2 = dofile(Traitormod.Path .. "/Lua/config/pointshop/attackdefend/utility/adv2.lua")
local CreateClassProduct = ADV2.CreateClassProduct
local CreateClassSubcategory = ADV2.CreateClassSubcategory
ADV2 = nil

local ShopTeamID = CharacterTeamType.Team2

---@type Pointshop.Category
local category = {

Identifier = "spawnRed",
CanAccess = function (client)
	return Traitormod.SelectedGamemode.Teams[ShopTeamID].Respawns[client.AccountId] ~= nil
end,

Products = {
	-- ========================================================
	-- SCOUTS (СКАУТЫ)
	-- ========================================================
    CreateClassProduct(ShopTeamID, {
        Identifier = "separatists_scout",
        JobId = "separatists_scout",
        Skills = {
            { Identifier = "weapons", Level = 45 },
            { Identifier = "medical", Level = 40 },
            { Identifier = "surgery", Level = 30 },
        },
        Talents = {
            "stonewall",
            "skedaddle",
            "ntsp_adrenalinepump",
            "physicalconditioning",
            "laresistance",
            "supersoldiers",
        },
        Afflictions = {
            { Identifier = "precursor", Strength = 23 },
            { Identifier = "deepfixnanite", Strength = 2 },
            { Identifier = "hyperbuffnanite", Strength = 1 },
            { Identifier = "fastrepair", Strength = 100 },
        },
        Items = {
            ["advancedgenesplicer"] = {
                InvSlotType = InvSlotType.HealthInterface,
                Locked = true,
                Items = {
                    ["geneticmaterialskitter"] = 1,
                    ["geneticmaterialmantis"] = 1,
                }
            },
            ["autoinjectorheadset"] = {
                InvSlotType = InvSlotType.Headset,
                Items = {
                    ["hyperzine"] = 1,
                }
            },
            ["piratebandana"] = {
                InvSlotType = InvSlotType.Head,
            },
            ["securityuniform2"] = {
                InvSlotType = InvSlotType.InnerClothes,
            },
            ["toolbelt"] = {
                InvSlotType = InvSlotType.Bag,
                Items = {
                    ["smgmagazine"] = 4,
                    ["hyperzine"] = 2,
                    ["wrench"] = 1,
                }
            },
            ["machinepistol"] = {
                Quantity = 2,
                Items = {
                    ["smgmagazine"] = 1,
                }
            },
            ["medtoolbox"] = {
                Items = {
                    ["deusizine"] = 2,
                    ["ointment"] = 8,
                    ["skinaid"] = 8,
                    ["opium"] = 4,
                    ["antibleeding1"] = 8,
                    ["gypsum"] = 2,
                    ["antibloodloss2"] = 2,
                }
            },
            ["artmod_scrapclub"] = 1,
        },
        LogSuffix = "has spawned as scout",
    }),
	-- ========================================================
	-- SOLDIERS (СОЛДАТЫ)
	-- ========================================================
    CreateClassProduct(ShopTeamID, {
        Identifier = "separatists_soldier_1",
        JobId = "separatists_soldier",
        Skills = {
            { Identifier = "weapons", Level = 85 },
            { Identifier = "medical", Level = 60 },
            { Identifier = "surgery", Level = 45 },
        },
        Talents = {
            "implacable",
            "inordinateexsanguination",
            "swole",
            "commando",
            "ntsp_captainresist",
            "gunrunner",
        },
        Afflictions = {
            { Identifier = "precursor", Strength = 23 },
            { Identifier = "deepfixnanite", Strength = 2 },
        },
        Items = {
            ["ballistichelmet1"] = {
                InvSlotType = InvSlotType.Head,
            },
            ["autoinjectorheadset"] = {
                InvSlotType = InvSlotType.Headset,
                Items = {
                    ["deusizine"] = 1,
                }
            },
            ["securityseparatistsuniform1"] = {
                InvSlotType = InvSlotType.InnerClothes,
            },
            ["bodyarmor"] = {
                InvSlotType = InvSlotType.OuterClothes,
            },
            ["bandolier"] = {
                InvSlotType = InvSlotType.Bag,
                Items = {
                    ["smgmagazine"] = 2,
                    ["revolverround"] = 12,
                    ["wrench"] = 1,
                    ["aed"] = 1,
                }
            },
            ["genesplicer"] = {
                InvSlotType = InvSlotType.HealthInterface,
                Locked = true,
                Items = {
                    ["geneticmaterialmoloch"] = 1,
                }
            },
            ["smg"] = {
                Items = {
                    ["smgmagazine"] = 1,
                }
            },
            ["revolver"] = {
                Items = {
                    ["revolverround"] = 6,
                }
            },
            ["stungrenade"] = 1,
            ["fraggrenade"] = 1,
            ["medkit"] = {
                Items = {
                    ["deusizine"] = 2,
                    ["redjellymed"] = 1,
                    ["bluejellymed"] = 1,
                }
            },
            ["medtoolbox"] = {
                Items = {
                    ["antidama1"] = 2,
                    ["needle"] = 1,
                    ["tourniquet"] = 2,
                    ["antibloodloss2"] = 4,
                    ["skinaid"] = 8,
                    ["ointment"] = 8,
                    ["antibleeding1"] = 4,
                    ["suture"] = 12,
                    ["gypsum"] = 4,
                }
            }
        },
        LogSuffix = " has spawned as soldier1",
    }),
    CreateClassProduct(ShopTeamID, {
        Identifier = "separatists_soldier_2",
        JobId = "separatists_soldier",
        Skills = {
            { Identifier = "weapons", Level = 85 },
            { Identifier = "medical", Level = 60 },
            { Identifier = "surgery", Level = 45 },
        },
        Talents = {
            "implacable",
            "inordinateexsanguination",
            "swole",
            "commando",
            "ntsp_captainresist",
            "gunrunner",
        },
        Afflictions = {
            { Identifier = "precursor", Strength = 23 },
            { Identifier = "deepfixnanite", Strength = 2 },
        },
        Items = {
            ["ballistichelmet1"] = {
                InvSlotType = InvSlotType.Head,
            },
            ["autoinjectorheadset"] = {
                InvSlotType = InvSlotType.Headset,
                Items = {
                    ["deusizine"] = 1,
                }
            },
            ["securityseparatistsuniform1"] = {
                InvSlotType = InvSlotType.InnerClothes,
            },
            ["bodyarmor"] = {
                InvSlotType = InvSlotType.OuterClothes,
            },
            ["bandolier"] = {
                InvSlotType = InvSlotType.Bag,
                Items = {
                    ["shotgunshell"] = 12,
                    ["revolverround"] = 12,
                    ["wrench"] = 1,
                    ["aed"] = 1,
                }
            },
            ["genesplicer"] = {
                InvSlotType = InvSlotType.HealthInterface,
                Locked = true,
                Items = {
                    ["geneticmaterialmoloch"] = 1,
                }
            },
            ["shotgun"] = {
                Items = {
                    ["shotgunshell"] = 6,
                }
            },
            ["revolver"] = {
                Items = {
                    ["revolverround"] = 6,
                }
            },
            ["fraggrenade"] = 1,
            ["stungrenade"] = 1,
            ["medkit"] = {
                Items = {
                    ["deusizine"] = 2,
                    ["redjellymed"] = 1,
                    ["bluejellymed"] = 1,
                }
            },
            ["medtoolbox"] = {
                Items = {
                    ["antidama1"] = 2,
                    ["needle"] = 1,
                    ["tourniquet"] = 2,
                    ["antibloodloss2"] = 4,
                    ["skinaid"] = 8,
                    ["ointment"] = 8,
                    ["antibleeding1"] = 4,
                    ["suture"] = 12,
                    ["gypsum"] = 4,
                }
            }
        },
        LogSuffix = " has spawned as soldier2",
    }),
	-- ========================================================
	-- STORMTROOPER (ШТУРМОВИКИ)
	-- ========================================================
    CreateClassProduct(ShopTeamID, {
        Identifier = "separatists_stormtrooper_1",
        JobId = "separatists_stormtrooper",
        Skills = {
            { Identifier = "weapons", Level = 100 },
            { Identifier = "medical", Level = 40 },
            { Identifier = "surgery", Level = 40 },
        },
        Talents = {
            "physicalconditioning",
            "implacable",
            "inordinateexsanguination",
            "specops",
            "foolhardy",
            "rifleman",
        },
        Afflictions = {
            { Identifier = "precursor", Strength = 23 },
            { Identifier = "deepfixnanite", Strength = 2 },
        },
        Items = {
            ["ballistichelmet1"] = {
                InvSlotType = InvSlotType.Head,
            },
            ["autoinjectorheadset"] = {
                InvSlotType = InvSlotType.Headset,
                Items = {
                    ["deusizine"] = 1,
                }
            },
            ["securityseparatistsuniform2"] = {
                InvSlotType = InvSlotType.InnerClothes,
            },
            ["bodyarmor"] = {
                InvSlotType = InvSlotType.OuterClothes,
            },
            ["bandolier"] = {
                InvSlotType = InvSlotType.Bag,
                Items = {
                    ["wrench"] = 1,
                    ["revolverround"] = 12,
                    ["assaultriflemagazine"] = 2,
                    ["stungrenade"] = 2,
                }
            },
            ["advancedgenesplicer"] = {
                InvSlotType = InvSlotType.HealthInterface,
                Locked = true,
                Items = {
                    ["geneticmaterialhammerheadmatriarch"] = 1,
                    ["geneticmaterialmantis"] = 1,
                }
            },
            ["weakassaultrifle"] = {
                Items = {
                    ["assaultriflemagazine"] = 1,
                }
            },
            ["revolver"] = {
                Items = {
                    ["revolverrounddepletedfuel"] = 6,
                }
            },
            ["antibleeding1"] = 4,
            ["medkit"] = {
                Items = {
                    ["morehealthsyringe"] = 1,
                    ["redjellymed"] = 1,
                    ["antidama1"] = 1,
                    ["deusizine"] = 1,
                }
            }
        },
        LogSuffix = " has spawned as assault2",
    }),
    CreateClassProduct(ShopTeamID, {
        Identifier = "separatists_stormtrooper_2",
        JobId = "separatists_stormtrooper",
        Skills = {
            { Identifier = "weapons", Level = 100 },
            { Identifier = "medical", Level = 40 },
            { Identifier = "surgery", Level = 40 },
        },
        Talents = {
            "physicalconditioning",
            "implacable",
            "inordinateexsanguination",
            "specops",
            "foolhardy",
            "rifleman",
        },
        Afflictions = {
            { Identifier = "precursor", Strength = 23 },
            { Identifier = "deepfixnanite", Strength = 2 },
        },
        Items = {
            ["ballistichelmet1"] = {
                InvSlotType = InvSlotType.Head,
            },
            ["autoinjectorheadset"] = {
                InvSlotType = InvSlotType.Headset,
                Items = {
                    ["deusizine"] = 1,
                }
            },
            ["securityseparatistsuniform2"] = {
                InvSlotType = InvSlotType.InnerClothes,
            },
            ["bodyarmor"] = {
                InvSlotType = InvSlotType.OuterClothes,
            },
            ["bandolier"] = {
                InvSlotType = InvSlotType.Bag,
                Items = {
                    ["wrench"] = 1,
                    ["shotgunshell"] = 12,
                    ["shotgunshellblunt"] = 12,
                    ["electrogunmagazine"] = 2,
                }
            },
            ["advancedgenesplicer"] = {
                InvSlotType = InvSlotType.HealthInterface,
                Locked = true,
                Items = {
                    ["geneticmaterialhammerheadmatriarch"] = 1,
                    ["geneticmaterialmantis"] = 1,
                }
            },
            ["shotgununique"] = {
                Items = {
                    ["shotgunshell"] = 2,
                }
            },
            ["electrogun"] = {
                Items = {
                    ["electrogunmagazine"] = 1,
                }
            },
            ["antibleeding1"] = 4,
            ["medkit"] = {
                Items = {
                    ["morehealthsyringe"] = 1,
                    ["redjellymed"] = 1,
                    ["antidama1"] = 1,
                    ["deusizine"] = 1,
                }
            }
        },
        LogSuffix = " has spawned as assault1",
    }),
    -- ========================================================
	-- SNIPERS СНАЙПЕРЫ
	-- ========================================================
    CreateClassProduct(ShopTeamID, {
        Identifier = "separatists_sniper_1",
        JobId = "separatists_sniper",
        Skills = {
            { Identifier = "weapons", Level = 100 },
            { Identifier = "medical", Level = 40 },
            { Identifier = "surgery", Level = 30 },
        },
        Talents = {
            "commando",
            "specops",
            "inordinateexsanguination",
            "beatcop",
            "gunrunner",
            "warlord",
            "extrapowder",
        },
        Afflictions = {
            { Identifier = "precursor", Strength = 23 },
            { Identifier = "deepfixnanite", Strength = 2 },
            { Identifier = "visionbuffnanite", Strength = 1 },
        },
        Items = {
            ["ballistichelmet1"] = {
                InvSlotType = InvSlotType.Head,
            },
            ["autoinjectorheadset"] = {
                InvSlotType = InvSlotType.Headset,
                Items = {
                    ["deusizine"] = 1,
                }
            },
            ["securityseparatistsuniform3"] = {
                InvSlotType = InvSlotType.InnerClothes,
            },
            ["bodyarmor"] = {
                InvSlotType = InvSlotType.OuterClothes,
            },
            ["bandolier"] = {
                InvSlotType = InvSlotType.Bag,
                Items = {
                    ["wrench"] = 1,
                    ["40mmgrenade"] = 2,
                    ["riflebullet"] = 12,
                    ["revolverround"] = 12,
                }
            },
            ["genesplicer"] = {
                InvSlotType = InvSlotType.HealthInterface,
                Locked = true,
                Items = {
                    ["geneticmaterialmudraptor"] = 1,
                }
            },
            ["rifle"] = {
                Items = {
                    ["riflebullet"] = 6,
                }
            },
            ["revolver"] = {
                Items = {
                    ["revolverround"] = 6,
                }
            },
            ["medtoolbox"] = {
                Items = {
                    ["antidama1"] = 2,
                    ["needle"] = 1,
                    ["tourniquet"] = 2,
                    ["antibloodloss2"] = 2,
                    ["skinaid"] = 8,
                    ["ointment"] = 8,
                    ["antibleeding1"] = 4,
                    ["suture"] = 6,
                    ["gypsum"] = 4,
                }
            }
        },
        LogSuffix = " has spawned as sniper1",
    }),
    CreateClassProduct(ShopTeamID, {
        Identifier = "separatists_sniper_2",
        JobId = "separatists_sniper",
        Skills = {
            { Identifier = "weapons", Level = 100 },
            { Identifier = "medical", Level = 40 },
            { Identifier = "surgery", Level = 30 },
        },
        Talents = {
            "commando",
            "specops",
            "inordinateexsanguination",
            "beatcop",
            "gunrunner",
            "warlord",
            "extrapowder",
        },
        Afflictions = {
            { Identifier = "precursor", Strength = 23 },
            { Identifier = "deepfixnanite", Strength = 2 },
            { Identifier = "visionbuffnanite", Strength = 1 },
        },
        Items = {
            ["ballistichelmet1"] = {
                InvSlotType = InvSlotType.Head,
            },
            ["autoinjectorheadset"] = {
                InvSlotType = InvSlotType.Headset,
                Items = {
                    ["deusizine"] = 1,
                }
            },
            ["securityseparatistsuniform3"] = {
                InvSlotType = InvSlotType.InnerClothes,
            },
            ["bodyarmor"] = {
                InvSlotType = InvSlotType.OuterClothes,
            },
            ["bandolier"] = {
                InvSlotType = InvSlotType.Bag,
                Items = {
                    ["wichesterround"] = 16,
                    ["wrench"] = 1,
                    ["revolverround"] = 12,
                }
            },
            ["genesplicer"] = {
                InvSlotType = InvSlotType.HealthInterface,
                Locked = true,
                Items = {
                    ["geneticmaterialmudraptor"] = 1,
                }
            },
            ["winchester"] = {
                Items = {
                    ["wichesterroundhard"] = 4,
                }
            },
            ["revolver"] = {
                Items = {
                    ["revolverround"] = 6,
                }
            },
            ["medtoolbox"] = {
                Items = {
                    ["antidama1"] = 2,
                    ["needle"] = 1,
                    ["tourniquet"] = 2,
                    ["antibloodloss2"] = 2,
                    ["skinaid"] = 8,
                    ["ointment"] = 8,
                    ["antibleeding1"] = 4,
                    ["suture"] = 6,
                    ["gypsum"] = 4,
                }
            }
        },
        LogSuffix = " has spawned as sniper2",
    }),
	-- ========================================================
	-- MEDICS МЕДИКИ
	-- ========================================================
    CreateClassProduct(ShopTeamID, {
        Identifier = "separatists_medic",
        JobId = "separatists_medic",
        Skills = {
            { Identifier = "medical", Level = 90 },
            { Identifier = "surgery", Level = 80 },
            { Identifier = "weapons", Level = 45 },
        },
        Talents = {
            "ntsp_adrenalinepump",
            "ntsp_therapisttintraining",
            "ntsp_captainresist",
            "ntsp_fallenandcantgetup",
            "ntsp_underpressure",
            "ntsp_bedsidemanner",
            "ntsp_preventativepermit",
            "ntsp_properfol",
            "ntsp_ultrasoniccleaner",
            "ntsp_imasurgeonnota",
            "plaguedoctor",
            "whatastench",
        },
        Afflictions = {
            { Identifier = "precursor", Strength = 23 },
            { Identifier = "deepfixnanite", Strength = 2 },
            { Identifier = "hyperbuffnanite", Strength = 1 },
        },
        Items = {
            ["ballistichelmet1"] = {
                InvSlotType = InvSlotType.Head,
            },
            ["autoinjectorheadset"] = {
                InvSlotType = InvSlotType.Headset,
                Items = {
                    ["combatstimulantsyringe"] = 1,
                }
            },
            ["surgeonclothes"] = {
                InvSlotType = InvSlotType.InnerClothes,
            },
            ["bodyarmor"] = {
                InvSlotType = InvSlotType.OuterClothes,
            },
            ["artmod_toolbelt"] = {
                InvSlotType = InvSlotType.Bag,
                Items = {
                    ["autocpr"] = {Items = {["fulguriumbatterycell"] = 1 }},
                    ["defibrillator"] = {Items = {["fulguriumbatterycell"] = 1 }},
                    ["bvm"] = {Items = {["oxygenitetank"] = 1 }},
                    ["wrench"] = 1,
                    ["surgicaldrapes"] = 1,
                    ["surgicalmask"] = 1,
                    ["fulguriumbatterycell"] = 2,
                    ["artmod_speeddevice"] = {Items = {["fulguriumbatterycell"] = 1 }},
                    ["osteosynthesisimplants"] = 1,
                    ["spinalimplant"] = 1,
                }
            },
            ["advancedgenesplicer"] = {
                InvSlotType = InvSlotType.HealthInterface,
                Locked = true,
                Items = {
                    ["geneticmaterialskitter"] = 1,
                    ["geneticmaterialmantis"] = 1,
                }
            },
            ["artmod_acidbubblegun"] = 1,
            ["advancedsyringegun"] = {
                Items = {
                    ["combatstimulantsyringe"] = 4,
                    ["hyperzine"] = 4,
                }
            },
            ["chemgrenade"] = 4,
            ["surgerytoolbox"] = {
                Items = {
                    ["advscalpel"] = 1,
                    ["advhemostat"] = 1,
                    ["advretractors"] = 1,
                    ["surgicaldrill"] = 1,
                    ["multiscalpel"] = 1,
                    ["surgerysaw"] = 1,
                    ["drainage"] = 2,
                    ["medstent"] = 2,
                    ["traumashears"] = 1,
                    ["suture"] = 32,
                    ["needle"] = 4,
                }
            },
            ["medtoolbox"] = {
                Items = {
                    ["tourniquet"] = 4,
                    ["gypsum"] = 4,
                    ["ointment"] = 8,
                    ["antibleeding1"] = 8,
                    ["antibloodloss2"] = 8,
                    ["skinaid"] = 8,
                    ["mannitolplus"] = 4,
                    ["antidama1"] = 8,
                    ["antibiotics"] = 8,
                }
            },
            ["medkit"] = {
                Items = {
                    ["combatstimulantsyringe"] = 4,
                }
            }
        },
        LogSuffix = " has spawned as medic1",
    }),
	-- ========================================================
	-- CLOWNS КЛОУНЫ
	-- ========================================================
    CreateClassProduct(ShopTeamID, {
        Identifier = "separatists_clown_1",
        JobId = "separatists_clown",
        Skills = {
            { Identifier = "weapons", Level = 25 },
            { Identifier = "medical", Level = 50 },
            { Identifier = "surgery", Level = 30 },
        },
        Talents = {
            "iamthatguy",
            "truepotential",
            "revengesquad",
            "psychoclown",
        },
        Afflictions = {
            { Identifier = "precursor", Strength = 23 },
            { Identifier = "deepfixnanite", Strength = 2 },
        },
        Items = {
            ["noseless_clownmask"] = {
                InvSlotType = InvSlotType.Head,
            },
            ["autoinjectorheadset"] = {
                InvSlotType = InvSlotType.Headset,
                Items = {
                    ["hyperzine"] = 1,
                }
            },
            ["noseless_clowncostume"] = {
                InvSlotType = InvSlotType.InnerClothes,
            },
            ["bodyarmor"] = {
                InvSlotType = InvSlotType.OuterClothes,
            },
            ["bandolier"] = {
                InvSlotType = InvSlotType.Bag,
                Items = {
                    ["wrench"] = 1,
                    ["batterycell"] = 4,
                    ["artmod_randomgrenade"] = 6,
                    ["antibleeding1"] = 8,
                }
            },
            ["advancedgenesplicer"] = {
                InvSlotType = InvSlotType.HealthInterface,
                Locked = true,
                Items = {
                    ["geneticmaterialmantis"] = 1,
                    ["geneticmaterialhammerhead"] = 1,
                }
            },
            ["BOYhammer"] = 2,
            ["MANhammer"] = 1,
            ["gpistol"] = 1,
            ["artmod_clownmachine"] = {
                Items = {
                    ["batterycell"] = 1,
                }
            },
            ["clowncostume"] = 1,
            ["clownmask"] = 1,
            ["medkit"] = {
                Items = {
                    ["deusizine"] = 1,
                    ["redjellymed"] = 1,
                    ["antidama1"] = 1,
                    ["steroids"] = 1,
                }
            }
        },
        LogSuffix = " has spawned as clown1",
    }),
    CreateClassProduct(ShopTeamID, {
        Identifier = "separatists_clown_2",
        JobId = "separatists_clown",
        Skills = {
            { Identifier = "weapons", Level = 25 },
            { Identifier = "medical", Level = 50 },
            { Identifier = "surgery", Level = 30 },
        },
        Talents = {
            "iamthatguy",
            "truepotential",
            "revengesquad",
            "psychoclown",
        },
        Afflictions = {
            { Identifier = "precursor", Strength = 23 },
            { Identifier = "deepfixnanite", Strength = 2 },
        },
        Items = {
            ["noseless_clownmask"] = {
                InvSlotType = InvSlotType.Head,
            },
            ["autoinjectorheadset"] = {
                InvSlotType = InvSlotType.Headset,
                Items = {
                    ["hyperzine"] = 1,
                }
            },
            ["noseless_clowncostume"] = {
                InvSlotType = InvSlotType.InnerClothes,
            },
            ["bodyarmor"] = {
                InvSlotType = InvSlotType.OuterClothes,
            },
            ["bandolier"] = {
                InvSlotType = InvSlotType.Bag,
                Items = {
                    ["clown_shotgunshell"] = 12,
                    ["wrench"] = 1,
                    ["artmod_randomgrenade"] = 4,
                    ["antibleeding1"] = 8,
                }
            },
            ["advancedgenesplicer"] = {
                InvSlotType = InvSlotType.HealthInterface,
                Locked = true,
                Items = {
                    ["geneticmaterialmantis"] = 1,
                    ["geneticmaterialhammerheadmatriarch"] = 1,
                }
            },
            ["artmod_clownautoshotgun"] = 1,
            ["artmod_scrapshotgun"] = {
                Items = {
                    ["clown_shotgunshell"] = 12,
                }
            },
            ["clowncostume"] = 1,
            ["clownmask"] = 1,
            ["medkit"] = {
                Items = {
                    ["deusizine"] = 1,
                    ["redjellymed"] = 1,
                    ["antidama1"] = 1,
                }
            }
        },
        LogSuffix = " has spawned as clown2",
    }),
    CreateClassProduct(ShopTeamID, {
        Identifier = "separatists_clown_3",
        JobId = "separatists_clown",
        Skills = {
            { Identifier = "weapons", Level = 25 },
            { Identifier = "medical", Level = 50 },
            { Identifier = "surgery", Level = 30 },
        },
        Talents = {
            "iamthatguy",
            "truepotential",
            "revengesquad",
            "psychoclown",
        },
        Afflictions = {
            { Identifier = "precursor", Strength = 23 },
            { Identifier = "deepfixnanite", Strength = 2 },
        },
        Items = {
            ["noseless_clownmask"] = {
                InvSlotType = InvSlotType.Head,
            },
            ["autoinjectorheadset"] = {
                InvSlotType = InvSlotType.Headset,
                Items = {
                    ["hyperzine"] = 1,
                }
            },
            ["noseless_clowncostume"] = {
                InvSlotType = InvSlotType.InnerClothes,
            },
            ["bodyarmor"] = {
                InvSlotType = InvSlotType.OuterClothes,
            },
            ["bandolier"] = {
                InvSlotType = InvSlotType.Bag,
                Items = {
                    ["clown_smgmagazine"] = 2,
                    ["clown_revolverround"] = 12,
                    ["wrench"] = 1,
                    ["artmod_randomgrenade"] = 2,
                }
            },
            ["advancedgenesplicer"] = {
                InvSlotType = InvSlotType.HealthInterface,
                Locked = true,
                Items = {
                    ["geneticmaterialmantis"] = 1,
                    ["geneticmaterialhammerheadmatriarch"] = 1,
                }
            },
            ["artmod_clownmachinepistol"] = {
                Items = {
                    ["clown_smgmagazine"] = 1,
                }
            },
            ["artmod_clownrevolver"] = {
                Items = {
                    ["clown_revolverround"] = 12,
                }
            },
            ["artmod_bubblegun"] = 1,
            ["clowncostume"] = 1,
            ["clownmask"] = 1,
            ["antibleeding1"] = 8,
            ["medkit"] = {
                Items = {
                    ["deusizine"] = 1,
                    ["redjellymed"] = 1,
                    ["antidama1"] = 1,
                    ["hyperzine"] = 1,
                }
            }
        },
        LogSuffix = " has spawned as clown3",
    }),
	-- ========================================================
	-- JUGGERNAUTS ДЖАГЕРНАУТЫ
	-- ========================================================
    CreateClassProduct(ShopTeamID, {
        Identifier = "separatists_juggernaut_1",
        JobId = "separatists_juggernaut",
        Skills = {
            { Identifier = "weapons", Level = 100 },
            { Identifier = "medical", Level = 40 },
            { Identifier = "surgery", Level = 25 },
        },
        Talents = {
            "berserker",
            "truepotential",
            "stonewall",
            "swole",
            "exampleofhealth",
            "crustyseaman",
            "ntsp_therapisttintraining",
            "foolhardy",
            "ntsp_fallenandcantgetup",
            "iamthatguy",
            "skedaddle",
        },
        Afflictions = {
            { Identifier = "precursor", Strength = 23 },
            { Identifier = "deepfixnanite", Strength = 2 },
            { Identifier = "morevigor", Strength = 800 },
            { Identifier = "rigidjoints", Strength = 200 },
        },
        Items = {
            ["piratehelmet"] = {
                InvSlotType = InvSlotType.Head,
            },
            ["autoinjectorheadset"] = {
                InvSlotType = InvSlotType.Headset,
                Items = {
                    ["combatstimulantsyringe"] = 1,
                }
            },
            ["captainseparatistsuniform3"] = {
                InvSlotType = InvSlotType.InnerClothes,
            },
            ["piratebodyarmor"] = {
                InvSlotType = InvSlotType.OuterClothes,
            },
            ["backpack_slow"] = {
                InvSlotType = InvSlotType.Bag,
                Items = {
                    ["wrench"] = 12,
                }
            },
            ["advancedgenesplicer"] = {
                InvSlotType = InvSlotType.HealthInterface,
                Locked = true,
                Items = {
                    ["geneticmaterialhammerhead"] = 1,
                    ["geneticmaterialmoloch"] = 1,
                }
            },
            ["artmod_scraphammer"] = 1,
            ["wrench"] = 1,
            ["medkit"] = {
                Items = {
                    ["redjellymedS"] = 1,
                    ["bluejellymed"] = 1,
                }
            },
            ["antibleeding1"] = 8,
            ["gypsum"] = 4,
            ["tourniquet"] = 4,
        },
        LogSuffix = " has spawned as juggernaut1",
    }),
    CreateClassProduct(ShopTeamID, {
        Identifier = "separatists_juggernaut_2",
        JobId = "separatists_juggernaut",
        Skills = {
            { Identifier = "weapons", Level = 100 },
            { Identifier = "medical", Level = 40 },
            { Identifier = "surgery", Level = 25 },
        },
        Talents = {
            "berserker",
            "truepotential",
            "stonewall",
            "swole",
            "exampleofhealth",
            "crustyseaman",
            "ntsp_therapisttintraining",
            "foolhardy",
            "ntsp_fallenandcantgetup",
            "iamthatguy",
            "skedaddle",
        },
        Afflictions = {
            { Identifier = "precursor", Strength = 23 },
            { Identifier = "deepfixnanite", Strength = 2 },
            { Identifier = "morevigor", Strength = 800 },
            { Identifier = "rigidjoints", Strength = 200 },
        },
        Items = {
            ["piratehelmet"] = {
                InvSlotType = InvSlotType.Head,
            },
            ["autoinjectorheadset"] = {
                InvSlotType = InvSlotType.Headset,
                Items = {
                    ["combatstimulantsyringe"] = 1,
                }
            },
            ["captainseparatistsuniform3"] = {
                InvSlotType = InvSlotType.InnerClothes,
            },
            ["piratebodyarmor"] = {
                InvSlotType = InvSlotType.OuterClothes,
            },
            ["backpack_slow"] = {
                InvSlotType = InvSlotType.Bag,
                Items = {
                    ["wrench"] = 12,
                }
            },
            ["advancedgenesplicer"] = {
                InvSlotType = InvSlotType.HealthInterface,
                Locked = true,
                Items = {
                    ["geneticmaterialhammerhead"] = 1,
                    ["geneticmaterialmoloch"] = 1,
                }
            },
            ["artmod_scrapsecira"] = 1,
            ["wrench"] = 1,
            ["medkit"] = {
                Items = {
                    ["redjellymedS"] = 1,
                    ["bluejellymed"] = 1,
                }
            },
            ["antibleeding1"] = 8,
            ["gypsum"] = 4,
            ["tourniquet"] = 4,
        },
        LogSuffix = " has spawned as juggernaut2",
    }),
	-- ========================================================
	-- CAPTAINS КАПИТАНЫ
	-- ========================================================
    CreateClassProduct(ShopTeamID, {
        Identifier = "separatists_captain_1",
        JobId = "separatists_captain",
        Skills = {
            { Identifier = "helm", Level = 100 },
            { Identifier = "weapons", Level = 70 },
            { Identifier = "medical", Level = 65 },
            { Identifier = "surgery", Level = 45 },
        },
        Talents = {
            "quickdraw",
            "bigguns",
            "drunkensailor",
            "family",
            "leadingbyexample",
            "inordinateexsanguination",
            "commando",
        },
        Afflictions = {
            { Identifier = "precursor", Strength = 23 },
            { Identifier = "deepfixnanite", Strength = 2 },
        },
        Items = {
            ["captainscap1"] = {
                InvSlotType = InvSlotType.Head,
            },
            ["autoinjectorheadset"] = {
                InvSlotType = InvSlotType.Headset,
                Items = {
                    ["deusizine"] = 1,
                }
            },
            ["captainseparatistsuniform2"] = {
                InvSlotType = InvSlotType.InnerClothes,
            },
            ["bodyarmor"] = {
                InvSlotType = InvSlotType.OuterClothes,
            },
            ["bandolier"] = {
                InvSlotType = InvSlotType.Bag,
                Items = {
                    ["revolverround"] = 24,
                    ["wrench"] = 1,
                }
            },
            ["advancedgenesplicer"] = {
                InvSlotType = InvSlotType.HealthInterface,
                Locked = true,
                Items = {
                    ["geneticmaterialskitter"] = 1,
                    ["geneticmaterialmantis"] = 1,
                }
            },
            ["artmod_clownrevolver"] = {
                Quantity = 2,
                Items = {
                    ["revolverround"] = 12,
                }
            },
            ["empgrenade"] = 2,
            ["piratecaptainhat"] = 1,
            ["beerbottle2"] = 2,
            ["beerbottle1"] = 2,
            ["rum"] = 2,
            ["medkit"] = {
                Items = {
                    ["deusizine"] = 2,
                    ["antidama1"] = 1,
                    ["steroids"] = 1,
                }
            },
            ["medtoolbox"] = {
                Items = {
                    ["opium"] = 4,
                    ["needle"] = 8,
                    ["tourniquet"] = 2,
                    ["antibloodloss2"] = 2,
                    ["skinaid"] = 8,
                    ["ointment"] = 8,
                    ["antibleeding1"] = 8,
                    ["gypsum"] = 4,
                    ["combatstimulantsyringe"] = 1,
                }
            }
        },
        LogSuffix = " has spawned as captain1",
    }),
    CreateClassProduct(ShopTeamID, {
        Identifier = "separatists_captain_2",
        JobId = "separatists_captain",
        Skills = {
            { Identifier = "helm", Level = 100 },
            { Identifier = "weapons", Level = 70 },
            { Identifier = "medical", Level = 65 },
            { Identifier = "surgery", Level = 45 },
        },
        Talents = {
            "quickdraw",
            "bigguns",
            "drunkensailor",
            "family",
            "leadingbyexample",
            "inordinateexsanguination",
            "commando",
        },
        Afflictions = {
            { Identifier = "precursor", Strength = 23 },
            { Identifier = "deepfixnanite", Strength = 2 },
        },
        Items = {
            ["captainscap1"] = {
                InvSlotType = InvSlotType.Head,
            },
            ["autoinjectorheadset"] = {
                InvSlotType = InvSlotType.Headset,
                Items = {
                    ["deusizine"] = 1,
                }
            },
            ["captainseparatistsuniform2"] = {
                InvSlotType = InvSlotType.InnerClothes,
            },
            ["bodyarmor"] = {
                InvSlotType = InvSlotType.OuterClothes,
            },
            ["bandolier"] = {
                InvSlotType = InvSlotType.Bag,
                Items = {
                    ["revolverround"] = 12,
                    ["artmod_scrapassaultriflemagazine"] = 2,
                    ["wrench"] = 1,
                }
            },
            ["genesplicer"] = {
                InvSlotType = InvSlotType.HealthInterface,
                Locked = true,
                Items = {
                    ["geneticmaterialmoloch"] = 1,
                }
            },
            ["artmod_scrapassaultrifle"] = {
                Items = {
                    ["artmod_scrapassaultriflemagazine"] = 1,
                }
            },
            ["artmod_piraterevolver"] = {
                Items = {
                    ["revolverround"] = 6,
                }
            },
            ["empgrenade"] = 2,
            ["piratecaptainhat"] = 1,
            ["rum"] = 2,
            ["beerbottle1"] = 2,
            ["beerbottle2"] = 2,
            ["medtoolbox"] = {
                Items = {
                    ["opium"] = 4,
                    ["needle"] = 8,
                    ["tourniquet"] = 2,
                    ["antibloodloss2"] = 2,
                    ["skinaid"] = 8,
                    ["ointment"] = 8,
                    ["antibleeding1"] = 8,
                    ["gypsum"] = 4,
                    ["combatstimulantsyringe"] = 1,
                }
            }
        },
        LogSuffix = " has spawned as captain2",
    }),
	-- ========================================================
	-- ENGINEERS ИНЖИНЕРЫ
	-- ========================================================
    CreateClassProduct(ShopTeamID, {
        Identifier = "separatists_engineer_1",
        JobId = "separatists_engineer",
        Skills = {
            { Identifier = "electrical", Level = 100 },
            { Identifier = "weapons", Level = 60 },
            { Identifier = "medical", Level = 40 },
            { Identifier = "surgery", Level = 25 },
        },
        Talents = {
            "beatcop",
            "phdinnuclearphysics",
            "lightningwizard",
            "dangerzone",
            "swole",
            "aggressiveengineering",
            "multifunctional",
            "iamthatguy",
            "grounded",
        },
        Afflictions = {
            { Identifier = "precursor", Strength = 23 },
            { Identifier = "deepfixnanite", Strength = 2 },
        },
        Items = {
            ["piratebandana"] = {
                InvSlotType = InvSlotType.Head,
            },
            ["autoinjectorheadset"] = {
                InvSlotType = InvSlotType.Headset,
            },
            ["engineerseparatistsuniform1"] = {
                InvSlotType = InvSlotType.InnerClothes,
            },
            ["bodyarmor"] = {
                InvSlotType = InvSlotType.OuterClothes,
            },
            ["artmod_toolbelt"] = {
                InvSlotType = InvSlotType.Bag,
                Items = {
                    ["timeddetonator"] = {Quantity = 2, Items = {["uex"] = 1 }},
                    ["uex"] = 2,
                    ["blackwire"] = 4,
                    ["artmod_detonator"] = {Items = {["uex"] = 1 }},
                    ["artmod_redbottom"] = 1,
                    ["wrench"] = 1,
                    ["screwdriver"] = 1,
                    ["antibleeding1"] = 8,
                    ["gypsum"] = 4,
                }
            },
            ["advancedgenesplicer"] = {
                InvSlotType = InvSlotType.HealthInterface,
                Locked = true,
                Items = {
                    ["geneticmaterialskitter"] = 1,
                    ["geneticmaterialhunter"] = 1,
                }
            },
            ["arcemitter"] = {
                Items = {
                    ["fulguriumbatterycell"] = 1,
                }
            },
            ["crowbarhardened"] = 1,
            ["fulguriumbatterycell"] = 2,
            ["medkit"] = {
                Items = {
                    ["deusizine"] = 2,
                    ["steroids"] = 2,
                }
            },
            ["medtoolbox"] = {
                Items = {
                    ["opium"] = 4,
                    ["needle"] = 2,
                    ["tourniquet"] = 2,
                    ["antibloodloss2"] = 2,
                    ["skinaid"] = 8,
                    ["ointment"] = 8,
                    ["antibleeding1"] = 8,
                    ["gypsum"] = 4,
                    ["combatstimulantsyringe"] = 1,
                }
            }
        },
        LogSuffix = " has spawned as engineer1",
    }),
    CreateClassProduct(ShopTeamID, {
        Identifier = "separatists_engineer_2",
        JobId = "separatists_engineer",
        Skills = {
            { Identifier = "electrical", Level = 100 },
            { Identifier = "weapons", Level = 60 },
            { Identifier = "medical", Level = 40 },
            { Identifier = "surgery", Level = 25 },
        },
        Talents = {
            "beatcop",
            "phdinnuclearphysics",
            "lightningwizard",
            "dangerzone",
            "swole",
            "aggressiveengineering",
            "multifunctional",
            "iamthatguy",
            "grounded",
        },
        Afflictions = {
            { Identifier = "precursor", Strength = 23 },
            { Identifier = "deepfixnanite", Strength = 2 },
        },
        Items = {
            ["piratebandana"] = {
                InvSlotType = InvSlotType.Head,
            },
            ["autoinjectorheadset"] = {
                InvSlotType = InvSlotType.Headset,
            },
            ["engineerseparatistsuniform1"] = {
                InvSlotType = InvSlotType.InnerClothes,
            },
            ["bodyarmor"] = {
                InvSlotType = InvSlotType.OuterClothes,
            },
            ["artmod_toolbelt"] = {
                InvSlotType = InvSlotType.Bag,
                Items = {
                    ["timeddetonator"] = {Quantity = 2, Items = {["uex"] = 1 }},
                    ["uex"] = 2,
                    ["blackwire"] = 4,
                    ["artmod_detonator"] = {Items = {["uex"] = 1 }},
                    ["artmod_redbottom"] = 1,
                    ["wrench"] = 1,
                    ["screwdriver"] = 1,
                    ["antibleeding1"] = 8,
                    ["gypsum"] = 4,
                }
            },
            ["advancedgenesplicer"] = {
                InvSlotType = InvSlotType.HealthInterface,
                Locked = true,
                Items = {
                    ["geneticmaterialskitter"] = 1,
                    ["geneticmaterialhunter"] = 1,
                }
            },
            ["nucleargun"] = {
                Items = {
                    ["thoriumfuelrod"] = 1,
                }
            },
            ["screwdriverhardened"] = 2,
            ["thoriumfuelrod"] = 2,
            ["medkit"] = {
                Items = {
                    ["deusizine"] = 2,
                    ["steroids"] = 2,
                }
            },
            ["medtoolbox"] = {
                Items = {
                    ["opium"] = 4,
                    ["needle"] = 2,
                    ["tourniquet"] = 2,
                    ["antibloodloss2"] = 2,
                    ["skinaid"] = 8,
                    ["ointment"] = 8,
                    ["antibleeding1"] = 8,
                    ["gypsum"] = 4,
                }
            }
        },
        LogSuffix = " has spawned as engineer2",
    }),
	-- ========================================================
	-- GUNNERS АРТЕЛЕРИСТ 
	-- ========================================================
    CreateClassProduct(ShopTeamID, {
        Identifier = "separatists_gunner_1",
        JobId = "separatists_gunner",
        Skills = {
            { Identifier = "weapons", Level = 70 },
            { Identifier = "medical", Level = 40 },
            { Identifier = "surgery", Level = 25 },
        },
        Talents = {
            "extrapowder",
            "whatastench",
            "commando",
            "plaguedoctor",
            "implacable",
        },
        Afflictions = {
            { Identifier = "precursor", Strength = 23 },
            { Identifier = "deepfixnanite", Strength = 2 },
        },
        Items = {
            ["ironhelmet"] = {
                InvSlotType = InvSlotType.Head,
            },
            ["autoinjectorheadset"] = {
                InvSlotType = InvSlotType.Headset,
            },
            ["mechanicseparatistsuniform1"] = {
                InvSlotType = InvSlotType.InnerClothes,
            },
            ["makeshiftarmor"] = {
                InvSlotType = InvSlotType.OuterClothes,
            },
            ["bandolier"] = {
                InvSlotType = InvSlotType.Bag,
                Items = {
                    ["wrench"] = 1,
                    ["revolverround"] = 12,
                    ["40mmchemgrenade"] = 8,
                    ["40mmgrenade"] = 4,
                }
            },
            ["advancedgenesplicer"] = {
                InvSlotType = InvSlotType.HealthInterface,
                Locked = true,
                Items = {
                    ["geneticmaterialmantis"] = 1,
                    ["geneticmaterialskitter"] = 1,
                }
            },
            ["revolver"] = {
                Items = {
                    ["revolverround"] = 6,
                }
            },
            ["compactgrenadelauncher"] = {
                Items = {
                    ["40mmgrenade"] = 4,
                    ["40mmchemgrenade"] = 4,
                }
            },
            ["alienartifactpiece"] = 1,
            ["fraggrenade"] = 2,
            ["stungrenade"] = 2,
            ["empgrenade"] = 2,
            ["chemgrenade"] = 4,
            ["medkit"] = {
                Items = {
                    ["deusizine"] = 2,
                    ["antidama1"] = 1,
                    ["steroids"] = 1,
                }
            }
        },
        LogSuffix = " has spawned as gunner1",
    }),
    CreateClassProduct(ShopTeamID, {
        Identifier = "separatists_gunner_2",
        JobId = "separatists_gunner",
        Skills = {
            { Identifier = "weapons", Level = 70 },
            { Identifier = "medical", Level = 40 },
            { Identifier = "surgery", Level = 25 },
        },
        Talents = {
            "extrapowder",
            "whatastench",
            "commando",
            "plaguedoctor",
            "implacable",
        },
        Afflictions = {
            { Identifier = "precursor", Strength = 23 },
            { Identifier = "deepfixnanite", Strength = 2 },
        },
        Items = {
            ["ironhelmet"] = {
                InvSlotType = InvSlotType.Head,
            },
            ["autoinjectorheadset"] = {
                InvSlotType = InvSlotType.Headset,
            },
            ["mechanicseparatistsuniform1"] = {
                InvSlotType = InvSlotType.InnerClothes,
            },
            ["makeshiftarmor"] = {
                InvSlotType = InvSlotType.OuterClothes,
            },
            ["bandolier"] = {
                InvSlotType = InvSlotType.Bag,
                Items = {
                    ["wrench"] = 1,
                    ["revolverround"] = 12,
                    ["40mmchemgrenade"] = 8,
                    ["40mmgrenade"] = 4,
                }
            },
            ["advancedgenesplicer"] = {
                InvSlotType = InvSlotType.HealthInterface,
                Locked = true,
                Items = {
                    ["geneticmaterialmantis"] = 1,
                    ["geneticmaterialskitter"] = 1,
                }
            },
            ["grenadelauncher"] = {
                Items = {
                    ["40mmgrenade"] = 3,
                    ["40mmchemgrenade"] = 3,
                }
            },
            ["alienartifactpiece"] = 4,
            ["fraggrenade"] = 2,
            ["stungrenade"] = 2,
            ["empgrenade"] = 2,
            ["medkit"] = {
                Items = {
                    ["deusizine"] = 2,
                    ["antidama1"] = 1,
                    ["steroids"] = 1,
                }
            }
        },
        LogSuffix = " has spawned as gunner2",
    }),
}

}


local classGroups = {
    scout = { Subcategory = CreateClassSubcategory("attackdefend_scouts", 2, "separatists_scout") },
    soldier = { Subcategory = CreateClassSubcategory("attackdefend_soldiers", 3, "separatists_soldier") },
    stormtrooper = { Subcategory = CreateClassSubcategory("attackdefend_stormtroopers", 2, "separatists_stormtrooper") },
    sniper = { Subcategory = CreateClassSubcategory("attackdefend_snipers", 2, "separatists_sniper") },
    medic = { Subcategory = CreateClassSubcategory("attackdefend_medics", 1, "separatists_medic") },
    clown = { Subcategory = CreateClassSubcategory("attackdefend_clowns", 3, "separatists_clown") },
    juggernaut = { Subcategory = CreateClassSubcategory("attackdefend_juggernauts", 1, "separatists_juggernaut") },
    captain = { Subcategory = CreateClassSubcategory("attackdefend_captains", 2, "separatists_captain") },
    engineer = { Subcategory = CreateClassSubcategory("attackdefend_engineers", 2, "separatists_engineer") },
    gunner = { Subcategory = CreateClassSubcategory("attackdefend_gunners", 2, "separatists_gunner") },
}

for _, product in ipairs(category.Products) do
    local groupId = product.Identifier
        :gsub("^separatists_", "")
        :gsub("_%d+$", "")

    local classGroup = classGroups[groupId]
    if classGroup ~= nil then
        product.Subcategory = classGroup.Subcategory
    end
end


return category