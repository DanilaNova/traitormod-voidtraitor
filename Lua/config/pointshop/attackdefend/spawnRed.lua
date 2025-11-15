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
		Action = function (client)
			---@type RespawnEntry?
			local respawnEntry = Traitormod.SelectedGamemode.Respawns[client]

			if respawnEntry == nil then
				respawnEntry = {Timer = nil, OnSpawn = nil, JobId = nil}
				Traitormod.SelectedGamemode.Respawns[client] = respawnEntry
			end
			respawnEntry.OnSpawn = function (character)
				character.info.SetSkillLevel("weapons", 100)
				GameMain.NetworkMember.CreateEntityEvent(character, Character.UpdateSkillsEventData("weapons", true))
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
		Action = function (client)
			---@type RespawnEntry?
			local respawnEntry = Traitormod.SelectedGamemode.Respawns[client]

			if respawnEntry == nil then
				respawnEntry = {Timer = nil, OnSpawn = nil}
				Traitormod.SelectedGamemode.Respawns[client] = respawnEntry
			end
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
		Action = function (client)
			---@type RespawnEntry?
			local respawnEntry = Traitormod.SelectedGamemode.Respawns[client]

			if respawnEntry == nil then
				respawnEntry = {Timer = nil, OnSpawn = nil}
				Traitormod.SelectedGamemode.Respawns[client] = respawnEntry
			end

			--[[]//TODO
			Equipment
			Minigun
			Heavy armor
			]]
			Traitormod.Log(client.Name .. "has spawned as juggernaut")
		end
	},
	{
		Identifier = "test",
		Price = 0,
		Limit = 9999,
		Action = function (client)
			---@type RespawnEntry?
			local respawnEntry = Traitormod.SelectedGamemode.Respawns[client]

			if respawnEntry == nil then
				respawnEntry = {Timer = nil, OnSpawn = nil}
				Traitormod.SelectedGamemode.Respawns[client] = respawnEntry
			end
			
			Traitormod.Log(client.Name .. "has spawned as juggernaut")
		end
	}
}

}

return category