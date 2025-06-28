--#region Utility functions

---Creates character for client on desired team
---@param client Barotrauma.Networking.Client
---@param team Team
---@return Barotrauma.Character, Team
local function setupCharacter(client)
	local team = Traitormod.SelectedGamemode.Teams[2]
	local spawnPoint = team.Spawns[math.random(1, #team.Spawns)]
	local character = Character.Create(client.CharacterInfo, spawnPoint.WorldPosition, client.CharacterInfo.Name, 0, true, true)
	client.SetClientCharacter(character)

	character.TeamID = team.TeamID
    character.UpdateTeam()
    character.TeleportTo(spawnPoint.WorldPosition)

	-- Give id card
	Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab("idcard"), character.Inventory, nil, nil, function (item)
		item.GetComponentString("IdCard").Initialize(spawnPoint, character)
		item.NonPlayerTeamInteractable = true
		local lock = item.SerializableProperties[Identifier("NonPlayerTeamInteractable")]
		Networking.CreateEntityEvent(item, Item.ChangePropertyEventData(lock, item))
	end, true, false, InvSlotType.Card)



	return character, team
end

--#endregion

---@type Pointshop.Category
local category = {

Identifier = "teamRed",
CanAccess = function (client)
	local character = client.Character
	return (character == nil or character.IsDead) and client.TeamID == CharacterTeamType.Team2
end,

Products = {
	{
		Identifier = "rifleman",
		Price = 0,
		Limit = 9999,
		Action = function (client)
			local character, team = setupCharacter(client, team)

			--[[]//TODO
			Equipment
			Rifle
			Light armor
			]]
			Traitormod.Log(client.Name .. "has spawned as rifleman")
		end
	},
	{
		Identifier = "assault",
		Price = 0,
		Limit = 9999,
		Action = function (client)
			local character, team = setupCharacter(client, team)

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
		Price = 5000,
		Limit = 9999,
		Action = function (client)
			local character, team = setupCharacter(client, team)
			
			--[[]//TODO
			Equipment
			Minigun
			Heavy armor
			]]
			Traitormod.Log(client.Name .. "has spawned as juggernaut")
		end
	}
}

}

return category