---@diagnostic disable-next-line: unknown-cast-variable
---@cast Traitormod.SelectedGamemode Gamemodes.AttackDefendV2

---@module "adv2"
local ADV2 = dofile(Traitormod.Path .. "/Lua/config/pointshop/attackdefend/utility/adv2.lua")
local respawnStart = ADV2.RespawnStart
local CanBuyGroup = ADV2.CanBuyGroup
local CreateClassSubcategory = ADV2.CreateClassSubcategory
local spawnItems = ADV2.SpawnItems
local applyDefaultClassLocks = ADV2.ApplyDefaultClassLocks
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
	{
		Identifier = "separatists_scout",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (client, product)
			return CanBuyGroup(client, product)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier, nil, product)
			
			respawnEntry.JobId = "separatists_scout"
			
			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory
				
				character.info.SetSkillLevel("weapons", 45)
				character.info.SetSkillLevel("medical", 40)
				character.info.SetSkillLevel("surgery", 30)
				
				character.GiveTalent("stonewall")
				character.GiveTalent("skedaddle")
				character.GiveTalent("ntsp_adrenalinepump")
				character.GiveTalent("physicalconditioning")
				character.GiveTalent("laresistance")
				character.GiveTalent("supersoldiers")

				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["precursor"].Instantiate(23))
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["deepfixnanite"].Instantiate(2))
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["vigorbuffnanite"].Instantiate(1))
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["hyperbuffnanite"].Instantiate(1))
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["fastrepair"].Instantiate(100))
				
				---@type ItemTable
				local inventoryItems = {
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
					["piratebandana"] = 
                        {InvSlotType = InvSlotType.Head,
                    },
					["securityuniform2"] = 
                        {InvSlotType = InvSlotType.InnerClothes,
                    },
					["toolbelt"] = {
						InvSlotType = InvSlotType.Bag,
						Items = {
							["smgmagazine"] = 4,
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
							["pills2"] = 1,
							["ointment"] = 8,
							["skinaid"] = 8,
							["opium"] = 4,
							["antibleeding1"] = 8,
							["gypsum"] = 2,
							["antibloodloss2"] = 2,
						}
					},
					["artmod_scrapclub"] = 1,
				}

				applyDefaultClassLocks(inventoryItems)
				for key, value in pairs(inventoryItems) do
					spawnItems(key, inventory, value)
				end
			end
	
			Traitormod.Log(client.Name .. "has spawned as scout")
		end
	},
	-- ========================================================
	-- SOLDIERS (СОЛДАТЫ)
	-- ========================================================
	{
        Identifier = "separatists_soldier_1",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (client, product)
			return CanBuyGroup(client, product)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier, nil, product)

			respawnEntry.JobId = "separatists_soldier"

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory

				character.info.SetSkillLevel("weapons", 85)
				character.info.SetSkillLevel("medical", 60)
				character.info.SetSkillLevel("surgery", 45)

				character.GiveTalent("implacable")
				character.GiveTalent("inordinatexsanguination")
				character.GiveTalent("swole")
				character.GiveTalent("commando")
				character.GiveTalent("ntsp_captainresist")
				character.GiveTalent("gunrunner")

				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["precursor"].Instantiate(23))
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["deepfixnanite"].Instantiate(2))

				---@type ItemTable
				local inventoryItems = {
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
					Locked = true,
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
				}

				applyDefaultClassLocks(inventoryItems)
				for key, value in pairs(inventoryItems) do
					spawnItems(key, inventory, value)
				end
			end
			
			Traitormod.Log(client.Name .. " has spawned as soldier1")
		end
	},
    {
		Identifier = "separatists_soldier_2",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (client, product)
			return CanBuyGroup(client, product)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier, nil, product)

			respawnEntry.JobId = "separatists_soldier"

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory

				character.info.SetSkillLevel("weapons", 85)
				character.info.SetSkillLevel("medical", 60)
				character.info.SetSkillLevel("surgery", 45)

				character.GiveTalent("implacable")
				character.GiveTalent("inordinatexsanguination")
				character.GiveTalent("swole")
				character.GiveTalent("commando")
				character.GiveTalent("ntsp_captainresist")
				character.GiveTalent("gunrunner")

				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["precursor"].Instantiate(23))
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["deepfixnanite"].Instantiate(2))

				---@type ItemTable
				local inventoryItems = {
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
					Locked = true,
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
				}

				applyDefaultClassLocks(inventoryItems)
				for key, value in pairs(inventoryItems) do
					spawnItems(key, inventory, value)
				end
			end
			
			Traitormod.Log(client.Name .. " has spawned as soldier2")
		end
	},
	-- ========================================================
	-- STORMTROOPER (ШТУРМОВИКИ)
	-- ========================================================
    {
		Identifier = "separatists_stormtrooper_1",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (client, product)
			return CanBuyGroup(client, product)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier, nil, product)

			respawnEntry.JobId = "separatists_stormtrooper"

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory

				character.info.SetSkillLevel("weapons", 100)
				character.info.SetSkillLevel("medical", 40)
				character.info.SetSkillLevel("surgery", 40)

				character.GiveTalent("physicalconditioning")
				character.GiveTalent("implacable")
				character.GiveTalent("inordinatexsanguination")
				character.GiveTalent("specops")
				character.GiveTalent("foolhardy")
				character.GiveTalent("rifleman")

				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["precursor"].Instantiate(23))
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["deepfixnanite"].Instantiate(2))

				---@type ItemTable
				local inventoryItems = {
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
					Locked = true,
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
				}

				applyDefaultClassLocks(inventoryItems)
				for key, value in pairs(inventoryItems) do
					spawnItems(key, inventory, value)
				end
			end
			
			Traitormod.Log(client.Name .. " has spawned as assault2")
		end
	},
	{
		Identifier = "separatists_stormtrooper_2",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (client, product)
			return CanBuyGroup(client, product)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier, nil, product)

			respawnEntry.JobId = "separatists_stormtrooper"

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory

				character.info.SetSkillLevel("weapons", 100)
				character.info.SetSkillLevel("medical", 40)
				character.info.SetSkillLevel("surgery", 40)

				character.GiveTalent("physicalconditioning")
				character.GiveTalent("implacable")
				character.GiveTalent("inordinatexsanguination")
				character.GiveTalent("specops")
				character.GiveTalent("foolhardy")
				character.GiveTalent("rifleman")

				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["precursor"].Instantiate(23))
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["deepfixnanite"].Instantiate(2))

				---@type ItemTable
				local inventoryItems = {
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
					Locked = true,
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
				}

				applyDefaultClassLocks(inventoryItems)
				for key, value in pairs(inventoryItems) do
					spawnItems(key, inventory, value)
				end
			end
			
			Traitormod.Log(client.Name .. " has spawned as assault1")
		end
	},
    -- ========================================================
	-- SNIPERS СНАЙПЕРЫ
	-- ========================================================
	{
		Identifier = "separatists_sniper_1",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (client, product)
			return CanBuyGroup(client, product)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier, nil, product)

			respawnEntry.JobId = "separatists_sniper"

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory

				character.info.SetSkillLevel("weapons", 100)
				character.info.SetSkillLevel("medical", 40)
				character.info.SetSkillLevel("surgery", 30)

				character.GiveTalent("commando")
				character.GiveTalent("specops")
				character.GiveTalent("inordinatexsanguination")
				character.GiveTalent("beatcop")
				character.GiveTalent("gunrunner")
				character.GiveTalent("warlord")
				character.GiveTalent("exstrapowder")

				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["precursor"].Instantiate(23))
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["deepfixnanite"].Instantiate(2))
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["visionbuffnanite"].Instantiate(1))
				
				---@type ItemTable
				local inventoryItems = {
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
					Locked = true,
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
				}

				applyDefaultClassLocks(inventoryItems)
				for key, value in pairs(inventoryItems) do
					spawnItems(key, inventory, value)
				end
			end
			
			Traitormod.Log(client.Name .. " has spawned as sniper1")
		end
	},
	{
		Identifier = "separatists_sniper_2",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (client, product)
			return CanBuyGroup(client, product)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier, nil, product)

			respawnEntry.JobId = "separatists_sniper"

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory

				character.info.SetSkillLevel("weapons", 100)
				character.info.SetSkillLevel("medical", 40)
				character.info.SetSkillLevel("surgery", 30)

				character.GiveTalent("commando")
				character.GiveTalent("specops")
				character.GiveTalent("inordinatexsanguination")
				character.GiveTalent("beatcop")
				character.GiveTalent("gunrunner")
				character.GiveTalent("warlord")
				character.GiveTalent("exstrapowder")

				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["precursor"].Instantiate(23))
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["deepfixnanite"].Instantiate(2))
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["visionbuffnanite"].Instantiate(1))
				
				---@type ItemTable
				local inventoryItems = {
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
					Locked = true,
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
				}

				applyDefaultClassLocks(inventoryItems)
				for key, value in pairs(inventoryItems) do
					spawnItems(key, inventory, value)
				end
			end
			
			Traitormod.Log(client.Name .. " has spawned as sniper2")
		end
	},
	-- ========================================================
	-- MEDICS МЕДИКИ
	-- ========================================================
	{
		Identifier = "separatists_medic",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (client, product)
			return CanBuyGroup(client, product)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier, nil, product)

			respawnEntry.JobId = "separatists_medic"

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory

				character.info.SetSkillLevel("medical", 90)
				character.info.SetSkillLevel("surgery", 80)
				character.info.SetSkillLevel("weapons", 45)

				character.GiveTalent("ntsp_adrenalinepump")
				character.GiveTalent("ntsp_therapisttintraining")
				character.GiveTalent("ntsp_captainresist")
				character.GiveTalent("ntsp_fallandcantgetapp")
				character.GiveTalent("ntsp_underpressure")
				character.GiveTalent("ntsp_bedsidemanner")
				character.GiveTalent("ntsp_preventativepermit")
				character.GiveTalent("ntsp_properfol")
				character.GiveTalent("ntsp_ultrasoniccleaner")
				character.GiveTalent("ntsp_imasurgeonnota")
				character.GiveTalent("plaguedoctor")
				character.GiveTalent("whatastench")

				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["precursor"].Instantiate(23))
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["deepfixnanite"].Instantiate(2))
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["hyperbuffnanite"].Instantiate(1))
				
				---@type ItemTable
				local inventoryItems = {
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
					Locked = true,
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
				}

				applyDefaultClassLocks(inventoryItems)
				for key, value in pairs(inventoryItems) do
					spawnItems(key, inventory, value)
				end
			end
			
			Traitormod.Log(client.Name .. " has spawned as medic1")
		end
	},
	-- ========================================================
	-- CLOWNS КЛОУНЫ
	-- ========================================================
	{
		Identifier = "separatists_clown_1",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (client, product)
			return CanBuyGroup(client, product)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier, nil, product)

			respawnEntry.JobId = "separatists_clown"

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory

				character.info.SetSkillLevel("weapons", 25)
				character.info.SetSkillLevel("medical", 50)
				character.info.SetSkillLevel("surgery", 30)

				character.GiveTalent("enrollintoclowncollege")
				character.GiveTalent("truepotential")
				character.GiveTalent("revengesquad")
				character.GiveTalent("psychoclown")
				character.GiveTalent("iamthatguy")

				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["precursor"].Instantiate(23))
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["deepfixnanite"].Instantiate(2))
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["vigorbuffnanite"].Instantiate(1))
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["fastrepair"].Instantiate(100))

				---@type ItemTable
				local inventoryItems = {
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
					Locked = true,
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
				}

				applyDefaultClassLocks(inventoryItems)
				for key, value in pairs(inventoryItems) do
					spawnItems(key, inventory, value)
				end
			end
			
			Traitormod.Log(client.Name .. " has spawned as clown1")
		end
	},
	{
		Identifier = "separatists_clown_2",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (client, product)
			return CanBuyGroup(client, product)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier, nil, product)

			respawnEntry.JobId = "separatists_clown"

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory

				character.info.SetSkillLevel("weapons", 25)
				character.info.SetSkillLevel("medical", 50)
				character.info.SetSkillLevel("surgery", 30)

				character.GiveTalent("enrollintoclowncollege")
				character.GiveTalent("truepotential")
				character.GiveTalent("revengesquad")
				character.GiveTalent("psychoclown")
				character.GiveTalent("iamthatguy")

				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["precursor"].Instantiate(23))
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["deepfixnanite"].Instantiate(2))
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["vigorbuffnanite"].Instantiate(1))

				---@type ItemTable
				local inventoryItems = {
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
					Locked = true,
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
				}

				applyDefaultClassLocks(inventoryItems)
				for key, value in pairs(inventoryItems) do
					spawnItems(key, inventory, value)
				end
			end
			
			Traitormod.Log(client.Name .. " has spawned as clown2")
		end
	},
	{
		Identifier = "separatists_clown_3",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (client, product)
			return CanBuyGroup(client, product)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier, nil, product)

			respawnEntry.JobId = "separatists_clown"

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory

				character.info.SetSkillLevel("weapons", 25)
				character.info.SetSkillLevel("medical", 50)
				character.info.SetSkillLevel("surgery", 30)

				character.GiveTalent("enrollintoclowncollege")
				character.GiveTalent("truepotential")
				character.GiveTalent("revengesquad")
				character.GiveTalent("psychoclown")
				character.GiveTalent("iamthatguy")

				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["precursor"].Instantiate(23))
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["deepfixnanite"].Instantiate(2))
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["vigorbuffnanite"].Instantiate(1))
				
				---@type ItemTable
				local inventoryItems = {
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
					Locked = true,
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
				}

				applyDefaultClassLocks(inventoryItems)
				for key, value in pairs(inventoryItems) do
					spawnItems(key, inventory, value)
				end
			end
			
			Traitormod.Log(client.Name .. " has spawned as clown3")
		end
	},
	-- ========================================================
	-- JUGGERNAUTS ДЖАГЕРНАУТЫ
	-- ========================================================
	{
		Identifier = "separatists_juggernaut_1",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (client, product)
			return CanBuyGroup(client, product)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier, nil, product)

			respawnEntry.JobId = "separatists_juggernaut"

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory

				character.info.SetSkillLevel("weapons", 100)
				character.info.SetSkillLevel("medical", 40)
				character.info.SetSkillLevel("surgery", 25)

				character.GiveTalent("berserker")
				character.GiveTalent("truepotential")
				character.GiveTalent("stonewall")
				character.GiveTalent("swole")
				character.GiveTalent("exampleofhealth")
				character.GiveTalent("crustyseaman")
				character.GiveTalent("ntsp_therapisttintraining")
				character.GiveTalent("foolhardy")
				character.GiveTalent("ntsp_fallandcantgetapp")
				character.GiveTalent("iamthatguy")

				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["precursor"].Instantiate(23))
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["deepfixnanite"].Instantiate(2))
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["morevigor"].Instantiate(800))

				---@type ItemTable
				local inventoryItems = {
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
					Locked = true,
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
					["captainsuniform3"] = 1,
                    ["wrench"] = 1,
					["medkit"] = {
						Items = {
							["redjellymedS"] = 1,
							["bluejellymed"] = 1,
						}
					},
					["antibleeding1"] = 8,
				}

				applyDefaultClassLocks(inventoryItems)
				for key, value in pairs(inventoryItems) do
					spawnItems(key, inventory, value)
				end
			end
			
			Traitormod.Log(client.Name .. " has spawned as juggernaut1")
		end
	},
	{
		Identifier = "separatists_juggernaut_2",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (client, product)
			return CanBuyGroup(client, product)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier, nil, product)

			respawnEntry.JobId = "separatists_juggernaut"

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory

				character.info.SetSkillLevel("weapons", 100)
				character.info.SetSkillLevel("medical", 40)
				character.info.SetSkillLevel("surgery", 25)

				character.GiveTalent("berserker")
				character.GiveTalent("truepotential")
				character.GiveTalent("stonewall")
				character.GiveTalent("swole")
				character.GiveTalent("exampleofhealth")
				character.GiveTalent("crustyseaman")
				character.GiveTalent("ntsp_therapisttintraining")
				character.GiveTalent("foolhardy")
				character.GiveTalent("ntsp_fallandcantgetapp")
				character.GiveTalent("iamthatguy")

				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["precursor"].Instantiate(23))
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["deepfixnanite"].Instantiate(2))
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["morevigor"].Instantiate(800))

				---@type ItemTable
				local inventoryItems = {
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
					Locked = true,
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
					["captainsuniform3"] = 1,
                    ["wrench"] = 1,
					["medkit"] = {
						Items = {
							["redjellymedS"] = 1,
							["bluejellymed"] = 1,
						}
					},
					["antibleeding1"] = 8,
				}

				applyDefaultClassLocks(inventoryItems)
				for key, value in pairs(inventoryItems) do
					spawnItems(key, inventory, value)
				end
			end
			
			Traitormod.Log(client.Name .. " has spawned as juggernaut2")
		end
	},
	-- ========================================================
	-- CAPTAINS КАПИТАНЫ
	-- ========================================================
	{
		Identifier = "separatists_captain_1",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (client, product)
			return CanBuyGroup(client, product)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier, nil, product)

			respawnEntry.JobId = "separatists_captain"

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory

				character.info.SetSkillLevel("helm", 100)
				character.info.SetSkillLevel("weapons", 70)
				character.info.SetSkillLevel("medical", 65)
				character.info.SetSkillLevel("surgery", 45)

				character.GiveTalent("quickdraw")
				character.GiveTalent("bigguns")
				character.GiveTalent("drunkensailor")
				character.GiveTalent("family")
				character.GiveTalent("leadingbyexample")
				character.GiveTalent("inordinatexsanguination")
				character.GiveTalent("commando")

				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["precursor"].Instantiate(23))
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["deepfixnanite"].Instantiate(2))

				---@type ItemTable
				local inventoryItems = {
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
					Locked = true,
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
					["captainsuniform1"] = 1,
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
				}

				applyDefaultClassLocks(inventoryItems)
				for key, value in pairs(inventoryItems) do
					spawnItems(key, inventory, value)
				end
			end
			
			Traitormod.Log(client.Name .. " has spawned as captain1")
		end
	},
	{
		Identifier = "separatists_captain_2",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (client, product)
			return CanBuyGroup(client, product)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier, nil, product)

			respawnEntry.JobId = "separatists_captain"

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory

				character.info.SetSkillLevel("helm", 100)
				character.info.SetSkillLevel("weapons", 70)
				character.info.SetSkillLevel("medical", 65)
				character.info.SetSkillLevel("surgery", 45)

				character.GiveTalent("quickdraw")
				character.GiveTalent("bigguns")
				character.GiveTalent("drunkensailor")
				character.GiveTalent("family")
				character.GiveTalent("leadingbyexample")
				character.GiveTalent("inordinatexsanguination")
				character.GiveTalent("commando")

				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["precursor"].Instantiate(23))
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["deepfixnanite"].Instantiate(2))

				---@type ItemTable
				local inventoryItems = {
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
					Locked = true,
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
					["captainsuniform1"] = 1,
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
				}

				applyDefaultClassLocks(inventoryItems)
				for key, value in pairs(inventoryItems) do
					spawnItems(key, inventory, value)
				end
			end
			
			Traitormod.Log(client.Name .. " has spawned as captain2")
		end
	},
	-- ========================================================
	-- ENGINEERS ИНЖИНЕРЫ
	-- ========================================================
	{
		Identifier = "separatists_engineer_1",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (client, product)
			return CanBuyGroup(client, product)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier, nil, product)

			respawnEntry.JobId = "separatists_engineer"

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory

				character.info.SetSkillLevel("electrical", 100)
				character.info.SetSkillLevel("weapons", 60)
				character.info.SetSkillLevel("medical", 40)
				character.info.SetSkillLevel("surgery", 25)

				character.GiveTalent("beatcop")
				character.GiveTalent("phdinnuclearphysics")
				character.GiveTalent("lightingwizard")
				character.GiveTalent("dangerzone")
				character.GiveTalent("swole")
				character.GiveTalent("agressiveengineering")
				character.GiveTalent("multifunctional")
				character.GiveTalent("iamthatguy")
				character.GiveTalent("grounded")
				
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["precursor"].Instantiate(23))
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["deepfixnanite"].Instantiate(2))

				---@type ItemTable
				local inventoryItems = {
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
					Locked = true,
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
				}

				applyDefaultClassLocks(inventoryItems)
				for key, value in pairs(inventoryItems) do
					spawnItems(key, inventory, value)
				end
			end
			
			Traitormod.Log(client.Name .. " has spawned as engineer1")
		end
	},
	{
		Identifier = "separatists_engineer_2",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (client, product)
			return CanBuyGroup(client, product)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier, nil, product)

			respawnEntry.JobId = "separatists_engineer"

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory

				character.info.SetSkillLevel("electrical", 100)
				character.info.SetSkillLevel("weapons", 60)
				character.info.SetSkillLevel("medical", 40)
				character.info.SetSkillLevel("surgery", 25)

				character.GiveTalent("beatcop")
				character.GiveTalent("phdinnuclearphysics")
				character.GiveTalent("lightingwizard")
				character.GiveTalent("dangerzone")
				character.GiveTalent("swole")
				character.GiveTalent("agressiveengineering")
				character.GiveTalent("multifunctional")
				character.GiveTalent("iamthatguy")
				character.GiveTalent("grounded")
				character.GiveTalent("aggressiveengineering")

				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["precursor"].Instantiate(23))
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["deepfixnanite"].Instantiate(2))

				---@type ItemTable
				local inventoryItems = {
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
					Locked = true,
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
				}

				applyDefaultClassLocks(inventoryItems)
				for key, value in pairs(inventoryItems) do
					spawnItems(key, inventory, value)
				end
			end
			
			Traitormod.Log(client.Name .. " has spawned as engineer2")
		end
	},
	-- ========================================================
	-- GUNNERS АРТЕЛЕРИСТ 
	-- ========================================================
	{
		Identifier = "separatists_gunner_1",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (client, product)
			return CanBuyGroup(client, product)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier, nil, product)

			respawnEntry.JobId = "separatists_gunner"

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory

				character.info.SetSkillLevel("weapons", 70)
				character.info.SetSkillLevel("medical", 40)
				character.info.SetSkillLevel("surgery", 25)

				character.GiveTalent("extrapowder")
				character.GiveTalent("whatastench")
				character.GiveTalent("commando")
				character.GiveTalent("plaguedoctor")
				character.GiveTalent("implacable")

				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["precursor"].Instantiate(23))
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["deepfixnanite"].Instantiate(2))

				---@type ItemTable
				local inventoryItems = {
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
					Locked = true,
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
					["bluejumpsuit1"] = 1,
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
				}

				applyDefaultClassLocks(inventoryItems)
				for key, value in pairs(inventoryItems) do
					spawnItems(key, inventory, value)
				end
			end
			
			Traitormod.Log(client.Name .. " has spawned as gunner1")
		end
	},
	{
		Identifier = "separatists_gunner_2",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (client, product)
			return CanBuyGroup(client, product)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier, nil, product)

			respawnEntry.JobId = "separatists_gunner"

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory

				character.info.SetSkillLevel("weapons", 70)
				character.info.SetSkillLevel("medical", 40)
				character.info.SetSkillLevel("surgery", 25)

				character.GiveTalent("extrapowder")
				character.GiveTalent("whatastench")
				character.GiveTalent("commando")
				character.GiveTalent("plaguedoctor")
				character.GiveTalent("implacable")

				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["precursor"].Instantiate(23))
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["deepfixnanite"].Instantiate(2))

				---@type ItemTable
				local inventoryItems = {
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
					Locked = true,
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
					["bluejumpsuit1"] = 1,
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
				}

				applyDefaultClassLocks(inventoryItems)
				for key, value in pairs(inventoryItems) do
					spawnItems(key, inventory, value)
				end
			end
			
			Traitormod.Log(client.Name .. " has spawned as gunner2")
		end
	},
}

}


local classGroups = {
    scout = { Subcategory = CreateClassSubcategory("attackdefend_scouts", 2, "separatists_scout") },
    soldier = { Subcategory = CreateClassSubcategory("attackdefend_soldiers", 3, "separatists_soldier") },
    stormtrooper = { Subcategory = CreateClassSubcategory("attackdefend_stormtroopers", 2, "separatists_stormtrooper") },
    sniper = { Subcategory = CreateClassSubcategory("attackdefend_snipers", 2, "separatists_sniper") },
    medic = { Subcategory = CreateClassSubcategory("attackdefend_medics", 1, "separatists_medic") },
    clown = { Subcategory = CreateClassSubcategory("attackdefend_clowns", 3, "separatists_clown") },
    juggernaut = { Subcategory = CreateClassSubcategory("attackdefend_juggernauts", 2, "separatists_juggernaut") },
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