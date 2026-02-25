---@diagnostic disable-next-line: unknown-cast-variable
---@cast Traitormod.SelectedGamemode Gamemodes.AttackDefendV2

---@module "adv2"
local ADV2 = dofile(Traitormod.Path .. "/Lua/config/pointshop/attackdefend/utility/adv2.lua")
local respawnStart = ADV2.RespawnStart
local CanBuy = ADV2.CanBuy
local spawnItems = ADV2.SpawnItems
ADV2 = nil

local ShopTeamID = CharacterTeamType.Team1

---@type Pointshop.Category
local category = {

Identifier = "spawnBlue",
CanAccess = function (client)
	return Traitormod.SelectedGamemode.Teams[ShopTeamID].Respawns[client.AccountId] ~= nil
end,

Products = {
	-- ========================================================
	-- SCOUTS (СКАУТЫ)
	-- ========================================================
	{
		Identifier = "scout",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (_, product)
			return CanBuy(product.Identifier, 2)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier)

			respawnEntry.JobId = "coalition_scout"

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory

				character.info.SetSkillLevel("weapons", 45)
				character.info.SetSkillLevel("medical", 40)
				character.info.SetSkillLevel("surgery", 30)
				character.GiveTalent("lightningwizard")
				
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["precursor"].Instantiate(23)) 
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["deepfixnanite"].Instantiate(2)) 
				
				---@type ItemTable
				local inventoryItems = {
					["advancedgenesplicer"] = {
						InvSlotType = InvSlotType.HealthInterface,
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
							["pills6"] = 1,
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
        Identifier = "soldier1",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (_, product)
			return CanBuy(product.Identifier, 2)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier)

			respawnEntry.JobId = "coalition_soldier"

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory

				character.info.SetSkillLevel("weapons", 85)
				character.info.SetSkillLevel("medical", 60)
				character.info.SetSkillLevel("surgery", 45)

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

				for key, value in pairs(inventoryItems) do
					spawnItems(key, inventory, value)
				end
			end
			
			Traitormod.Log(client.Name .. " has spawned as soldier1")
		end
	},
    {
		Identifier = "soldier2",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (_, product)
			return CanBuy(product.Identifier, 2)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier)

			respawnEntry.JobId = "coalition_soldier"

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory

				character.info.SetSkillLevel("weapons", 85)
				character.info.SetSkillLevel("medical", 60)
				character.info.SetSkillLevel("surgery", 45)

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

				for key, value in pairs(inventoryItems) do
					spawnItems(key, inventory, value)
				end
			end
			
			Traitormod.Log(client.Name .. " has spawned as soldier2")
		end
	},
	-- ========================================================
	-- ASSAULTS (ШТУРМОВИКИ)
	-- ========================================================
    {
		Identifier = "assault1",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (_, product)
			return CanBuy(product.Identifier, 1)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier)

			respawnEntry.JobId = "coalition_stormtrooper"

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory

				character.info.SetSkillLevel("weapons", 100)
				character.info.SetSkillLevel("medical", 40)
				character.info.SetSkillLevel("surgery", 40)

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
						Items = {
							["geneticmaterialhammerheadmatriarch"] = 1,
							["geneticmaterialmantis"] = 1,
						}
					},
					["assaultrifle"] = {
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

				for key, value in pairs(inventoryItems) do
					spawnItems(key, inventory, value)
				end
			end
			
			Traitormod.Log(client.Name .. " has spawned as assault2")
		end
	},
	{
		Identifier = "assault2",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (_, product)
			return CanBuy(product.Identifier, 1)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier)

			respawnEntry.JobId = "coalition_stormtrooper"

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory

				character.info.SetSkillLevel("weapons", 100)
				character.info.SetSkillLevel("medical", 40)
				character.info.SetSkillLevel("surgery", 40)

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
		Identifier = "sniper1",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (_, product)
			return CanBuy(product.Identifier, 1)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier)

			respawnEntry.JobId = "coalition_sniper"

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory

				character.info.SetSkillLevel("weapons", 90)
				character.info.SetSkillLevel("medical", 40)
				character.info.SetSkillLevel("surgery", 30)

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

				for key, value in pairs(inventoryItems) do
					spawnItems(key, inventory, value)
				end
			end
			
			Traitormod.Log(client.Name .. " has spawned as sniper1")
		end
	},
	{
		Identifier = "sniper2",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (_, product)
			return CanBuy(product.Identifier, 1)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier)

			respawnEntry.JobId = "coalition_sniper"

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory

				character.info.SetSkillLevel("weapons", 90)
				character.info.SetSkillLevel("medical", 40)
				character.info.SetSkillLevel("surgery", 30)

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
		Identifier = "medic1",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (_, product)
			return CanBuy(product.Identifier, 2)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier)

			respawnEntry.JobId = "coalition_medic"

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory

				character.info.SetSkillLevel("medical", 90)
				character.info.SetSkillLevel("surgery", 80)
				character.info.SetSkillLevel("weapons", 45)

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
					["stasisbag"] = 1,
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
							["suture"] = 18,
							["osteosynthesisimplants"] = 1,
						}
					},
					["medtoolbox"] = {
						Items = {
							["thiamine"] = 4,
							["gypsum"] = 4,
							["ointment"] = 8,
							["antibleeding1"] = 16,
							["skinaid"] = 8,
							["mannitolplus"] = 4,
							["antidama1"] = 8,
							["antibiotics"] = 8,
						}
					},
					["medkit"] = {
						Items = {
							["combatstimulantsyringe"] = 2,
							["hyperzine"] = 2,
						}
					}
				}

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
		Identifier = "clown1",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (_, product)
			return CanBuy(product.Identifier, 1)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier)

			respawnEntry.JobId = "coalition_clown"

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory

				character.info.SetSkillLevel("weapons", 25)
				character.info.SetSkillLevel("medical", 50)
				character.info.SetSkillLevel("surgery", 30)

				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["precursor"].Instantiate(23)) 
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["deepfixnanite"].Instantiate(2)) 

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

				for key, value in pairs(inventoryItems) do
					spawnItems(key, inventory, value)
				end
			end
			
			Traitormod.Log(client.Name .. " has spawned as clown1")
		end
	},
	{
		Identifier = "clown2",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (_, product)
			return CanBuy(product.Identifier, 1)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier)

			respawnEntry.JobId = "coalition_clown"

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory

				character.info.SetSkillLevel("weapons", 25)
				character.info.SetSkillLevel("medical", 50)
				character.info.SetSkillLevel("surgery", 30)

				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["precursor"].Instantiate(23)) 
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["deepfixnanite"].Instantiate(2)) 

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
							["hyperzine"] = 1,
						}
					}
				}

				for key, value in pairs(inventoryItems) do
					spawnItems(key, inventory, value)
				end
			end
			
			Traitormod.Log(client.Name .. " has spawned as clown2")
		end
	},
	{
		Identifier = "clown3",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (_, product)
			return CanBuy(product.Identifier, 1)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier)

			respawnEntry.JobId = "coalition_clown"

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory


				character.info.SetSkillLevel("weapons", 25)
				character.info.SetSkillLevel("medical", 50)
				character.info.SetSkillLevel("surgery", 30)

				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["precursor"].Instantiate(23)) 
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["deepfixnanite"].Instantiate(2)) 

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
		Identifier = "juggernaut1",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (_, product)
			return CanBuy(product.Identifier, 1)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier)

			respawnEntry.JobId = "coalition_juggernaut"

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory

				character.info.SetSkillLevel("weapons", 100)
				character.info.SetSkillLevel("medical", 40)
				character.info.SetSkillLevel("surgery", 25)

				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["precursor"].Instantiate(23)) 
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["deepfixnanite"].Instantiate(2)) 

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
					},
					["backpack"] = {
						InvSlotType = InvSlotType.Bag,
						Items = {
							["wrench"] = 12,
						}
					},
					["advancedgenesplicer"] = {
						InvSlotType = InvSlotType.HealthInterface,
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
							["moremorehealthsyringe"] = 1,
							["hyperzine"] = 1,
							["redjellymedS"] = 1,
							["bluejellymedS"] = 1,
						}
					},
					["antibleeding1"] = 8,
				}

				for key, value in pairs(inventoryItems) do
					spawnItems(key, inventory, value)
				end
			end
			
			Traitormod.Log(client.Name .. " has spawned as juggernaut1")
		end
	},
	{
		Identifier = "juggernaut2",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (_, product)
			return CanBuy(product.Identifier, 1)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier)

			respawnEntry.JobId = "coalition_juggernaut"

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory

				character.info.SetSkillLevel("weapons", 100)
				character.info.SetSkillLevel("medical", 40)
				character.info.SetSkillLevel("surgery", 25)

				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["precursor"].Instantiate(23)) 
				character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs["deepfixnanite"].Instantiate(2)) 

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
					},
					["backpack"] = {
						InvSlotType = InvSlotType.Bag,
						Items = {
							["wrench"] = 12,
						}
					},
					["advancedgenesplicer"] = {
						InvSlotType = InvSlotType.HealthInterface,
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
							["moremorehealthsyringe"] = 1,
							["hyperzine"] = 1,
							["redjellymedS"] = 1,
							["bluejellymedS"] = 1,
						}
					},
					["antibleeding1"] = 8,
				}

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
		Identifier = "captain1",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (_, product)
			return CanBuy(product.Identifier, 1)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier)

			respawnEntry.JobId = "coalition_captain"

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory

				character.info.SetSkillLevel("helm", 100)
				character.info.SetSkillLevel("weapons", 70)
				character.info.SetSkillLevel("medical", 65)
				character.info.SetSkillLevel("surgery", 45)

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

				for key, value in pairs(inventoryItems) do
					spawnItems(key, inventory, value)
				end
			end
			
			Traitormod.Log(client.Name .. " has spawned as captain1")
		end
	},
	{
		Identifier = "captain2",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (_, product)
			return CanBuy(product.Identifier, 1)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier)

			respawnEntry.JobId = "coalition_captain"

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory

				character.info.SetSkillLevel("helm", 100)
				character.info.SetSkillLevel("weapons", 70)
				character.info.SetSkillLevel("medical", 65)
				character.info.SetSkillLevel("surgery", 45)

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
		Identifier = "engineer1",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (_, product)
			return CanBuy(product.Identifier, 1)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier)

			respawnEntry.JobId = "coalition_engineer"

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory

				character.info.SetSkillLevel("electrical", 100)
				character.info.SetSkillLevel("weapons", 60)
				character.info.SetSkillLevel("medical", 40)
				character.info.SetSkillLevel("surgery", 25)

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
					["orangejumpsuit2"] = {
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

				for key, value in pairs(inventoryItems) do
					spawnItems(key, inventory, value)
				end
			end
			
			Traitormod.Log(client.Name .. " has spawned as engineer1")
		end
	},
	{
		Identifier = "engineer2",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (_, product)
			return CanBuy(product.Identifier, 1)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier)

			respawnEntry.JobId = "coalition_engineer"

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory

				character.info.SetSkillLevel("electrical", 100)
				character.info.SetSkillLevel("weapons", 60)
				character.info.SetSkillLevel("medical", 40)
				character.info.SetSkillLevel("surgery", 25)

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
					["orangejumpsuit2"] = {
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
		Identifier = "gunner1",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (_, product)
			return CanBuy(product.Identifier, 1)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier)

			respawnEntry.JobId = "coalition_gunner"

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory

				character.info.SetSkillLevel("weapons", 70)
				character.info.SetSkillLevel("medical", 40)
				character.info.SetSkillLevel("surgery", 25)

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

				for key, value in pairs(inventoryItems) do
					spawnItems(key, inventory, value)
				end
			end
			
			Traitormod.Log(client.Name .. " has spawned as gunner1")
		end
	},
	{
		Identifier = "gunner2",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (_, product)
			return CanBuy(product.Identifier, 1)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, ShopTeamID, product.Identifier)

			respawnEntry.JobId = "coalition_gunner"

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory

				character.info.SetSkillLevel("weapons", 70)
				character.info.SetSkillLevel("medical", 40)
				character.info.SetSkillLevel("surgery", 25)

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

				for key, value in pairs(inventoryItems) do
					spawnItems(key, inventory, value)
				end
			end
			
			Traitormod.Log(client.Name .. " has spawned as gunner2")
		end
	},
}

}

return category