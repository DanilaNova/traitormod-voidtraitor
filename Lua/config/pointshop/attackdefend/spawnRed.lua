---@diagnostic disable-next-line: unknown-cast-variable
---@cast Traitormod.SelectedGamemode Gamemodes.AttackDefendV2

---@module "adv2"
local ADV2 = dofile(Traitormod.Path .. "/Lua/config/pointshop/attackdefend/utility/adv2.lua")
local respawnStart = ADV2.RespawnStart
local CanBuy = ADV2.CanBuy
local spawnItems = ADV2.SpawnItems
ADV2 = nil

---@type Pointshop.Category
local category = {

Identifier = "spawnRed",
CanAccess = function (client)
	return client.TeamID == CharacterTeamType.Team2
end,

Products = {
	{
		Identifier = "rifleman",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (_, product)
			return CanBuy(product.Identifier, 10)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, product.Identifier)

			respawnEntry.OnSpawn = function (character)
				character.info.SetSkillLevel("weapons", 100)
				Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab("securityseparatistsuniform3"), character.Inventory, nil, nil, nil, true, false, InvSlotType.InnerClothes)
				Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab("rifle"), character.Inventory)
			end
			print(client.Name .. " has spawned as rifleman")
		end
	},
	{
		Identifier = "assault",
		Price = 1,
		Limit = 9999,
		CanBuy = function (_, product)
			return CanBuy(product.Identifier, 10)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, product.Identifier)

			--[[]//TODO
			Equipment
			Submachine gun
			Medium armor
			]]
			Traitormod.Log(client.Name .. "has spawned as assault")
		end
	},
	{
		Identifier = "juggernaut",
		Price = 1,
		Limit = math.huge,
		CanBuy = function (_, product)
			return CanBuy(product.Identifier, 10)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, product.Identifier)

			--[[]//TODO
			Equipment
			Minigun
			Heavy armor
			]]
			Traitormod.Log(client.Name .. "has spawned as juggernaut")
		end
	},
	{
		Identifier = "scout",
		Price = 0,
		Limit = math.huge,
		CanBuy = function (_, product)
			return CanBuy(product.Identifier, 10)
		end,
		Action = function (client, product)
			local respawnEntry = respawnStart(client, product.Identifier)

			respawnEntry.OnSpawn = function (character)
				local inventory = character.Inventory
				---@type ItemTable
				local inventoryItems = {
					["advancedgenesplicer"] = {
						SpawnIfFull = true,
						IgnoreLimbs = false,
						InvSlotType = InvSlotType.HealthInterface,
						Items = {
							["geneticmaterialskitter"] = 1,
							["geneticmaterialmantis"] = 1,
						}
					},
					["autoinjectorheadset"] = {
						SpawnIfFull = true,
						IgnoreLimbs = false,
						InvSlotType = InvSlotType.Headset,
						Items = {
							["adrenaline"] = 1,
						}
					},
					["piratebandana"] = {
						SpawnIfFull = true,
						IgnoreLimbs = false,
						InvSlotType = InvSlotType.Head
					},
					["securityuniform2"] = {
						SpawnIfFull = true,
						IgnoreLimbs = false,
						InvSlotType = InvSlotType.InnerClothes,
					},
					["toolbelt"] = {
						SpawnIfFull = true,
						IgnoreLimbs = false,
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
							["adrenaline"] = 2,
							["pills6"] = 1,
							["pills2"] = 1,
							["ointment"] = 1,
							["blunttraumaointment"] = 1,
							["opium"] = 4,
							["antibleeding1"] = 6,
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
	}
}

}

return category