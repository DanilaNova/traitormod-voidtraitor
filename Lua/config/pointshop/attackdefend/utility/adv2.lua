---@diagnostic disable-next-line: unknown-cast-variable
---@cast Traitormod.SelectedGamemode Gamemodes.AttackDefendV2

local ADV2 = {}

---@param identifier string
---@param limit integer
---@param counterId string?
---@return table
function ADV2.CreateClassSubcategory(identifier, limit, counterId)
	return {
		Identifier = identifier,
		CounterType = "ClassGroup",
		CounterId = counterId or identifier,
		Limit = limit,
	}
end

---@param product Pointshop.Product?
---@return table?
function ADV2.GetClassSubcategory(product)
	if product == nil then return nil end
	local subcategory = product.Subcategory
	if subcategory == nil then return nil end

	if type(subcategory) == "table" then
		if subcategory.CounterType == "ClassGroup" then
			return subcategory
		end

		for i = #subcategory, 1, -1 do
			local entry = subcategory[i]
			if type(entry) == "table" and entry.CounterType == "ClassGroup" then
				return entry
			end
		end
	end

	return nil
end

---@param client Barotrauma.Networking.Client
---@param teamId Barotrauma.CharacterTeamType
---@param classId string
---@param JobId string?
---@param product Pointshop.Product?
---@return RespawnEntry?
function ADV2.RespawnStart(client, teamId, classId, JobId, product)
	local respawns = Traitormod.SelectedGamemode.Teams[teamId].Respawns
	local clientId = client.AccountId
	---@type RespawnEntry?
	local respawnEntry = respawns[clientId]

	if respawnEntry == nil then
		Traitormod.Error("Respawn entry of %s was empty", client.Name)
		return nil
	end

	respawnEntry.JobId = JobId
	local selectedGamemode = Traitormod.SelectedGamemode
	local classCounters = selectedGamemode.ClassCounters
	local classGroupCounters = selectedGamemode.ClassGroupCounters
	local classSubcategory = ADV2.GetClassSubcategory(product)
	local classGroupId = classSubcategory and classSubcategory.CounterId
	local previousClassId = respawnEntry.ClassId
	local previousClassGroupId = respawnEntry.ClassGroupId

	if previousClassId ~= nil and previousClassId ~= classId then
		classCounters[previousClassId] = math.max((classCounters[previousClassId] or 0) - 1, 0)
	end
	if previousClassGroupId ~= nil and previousClassGroupId ~= classGroupId then
		classGroupCounters[previousClassGroupId] = math.max((classGroupCounters[previousClassGroupId] or 0) - 1, 0)
	end

	if previousClassId ~= classId then
		classCounters[classId] = (classCounters[classId] or 0) + 1
	end
	if classGroupId ~= nil and previousClassGroupId ~= classGroupId then
		classGroupCounters[classGroupId] = (classGroupCounters[classGroupId] or 0) + 1
	end

	respawnEntry.PrevClassId = nil
	respawnEntry.ClassId = classId
	respawnEntry.PrevClassGroupId = nil
	respawnEntry.ClassGroupId = classGroupId

	return respawnEntry
end

---@param client Barotrauma.Networking.Client?
---@return RespawnEntry?
function ADV2.GetClientRespawnEntry(client)
	if client == nil or Traitormod.SelectedGamemode == nil then return nil end

	for _, team in pairs(Traitormod.SelectedGamemode.Teams) do
		local respawnEntry = team.Respawns[client.AccountId]
		if respawnEntry ~= nil then
			return respawnEntry
		end
	end

	return nil
end

---@param client Barotrauma.Networking.Client?
---@param classId string
---@param limit integer
---@return boolean, string?
function ADV2.CanBuy(client, classId, limit)
	local classCount = Traitormod.SelectedGamemode.ClassCounters[classId] or 0
	local respawnEntry = ADV2.GetClientRespawnEntry(client)
	if respawnEntry ~= nil and respawnEntry.ClassId == classId then
		classCount = math.max(classCount - 1, 0)
	end

	local result = classCount < limit
	return result, not result and Traitormod.Language.AttackDefendClassFull or nil
end

---@param client Barotrauma.Networking.Client?
---@param product Pointshop.Product
---@return boolean, string?
function ADV2.CanBuyGroup(client, product)
	local classSubcategory = ADV2.GetClassSubcategory(product)
	if classSubcategory == nil then
		return true
	end

	local counterId = classSubcategory.CounterId
	local limit = classSubcategory.Limit
	if counterId == nil or limit == nil then
		return true
	end

	local groupCount = Traitormod.SelectedGamemode.ClassGroupCounters[counterId] or 0
	local respawnEntry = ADV2.GetClientRespawnEntry(client)
	if respawnEntry ~= nil and respawnEntry.ClassGroupId == counterId then
		groupCount = math.max(groupCount - 1, 0)
	end

	local result = groupCount < limit
	return result, not result and Traitormod.Language.AttackDefendClassFull or nil
end

---@alias ItemTable table<string, integer | ItemTableEntry>
---@class ItemTableEntry
---@field Items ItemTable?
---@field Quantity integer?
---@field Condition number?
---@field Quality integer?
---@field IgnoreLimbs boolean?
---@field SpawnIfFull boolean?
---@field InvSlotType Barotrauma.InvSlotType?
---@field Locked boolean?
---@field LockContainedItems boolean?
---@field LockContainer boolean?
---@field OnSpawn fun(item: Barotrauma.Item, spawnPoint: Barotrauma.WayPoint?, character: Barotrauma.Character?)?

local function syncItemProperty(item, propertyName)
	if item == nil or item.Removed or item.SerializableProperties == nil then return end
	local property = item.SerializableProperties[Identifier(propertyName)]
	if property ~= nil then
		Networking.CreateEntityEvent(item, Item.ChangePropertyEventData(property, item))
	end
end

local function applyNativeItemLocks(item, locked, lockContainer)
	if item == nil or item.Removed then return end

	if locked then
		item.NonInteractable = true
		syncItemProperty(item, "NonInteractable")
	end

	if lockContainer then
		local itemContainer = item.GetComponentString ~= nil and item.GetComponentString("ItemContainer") or nil
		if itemContainer ~= nil then
			itemContainer.Locked = true
		elseif item.OwnInventory ~= nil then
			item.OwnInventory.Locked = true
		end
	end
end

local defaultLockedSlots = {
	[InvSlotType.InnerClothes] = true,
}

local function applyDefaultClassLockSettings(itemId, itemEntry)
	if type(itemEntry) ~= "table" then return end

	if itemEntry.Locked == nil and itemEntry.InvSlotType ~= nil and defaultLockedSlots[itemEntry.InvSlotType] then
		itemEntry.Locked = true
	end

	if itemId == "autoinjectorheadset" and itemEntry.LockContainedItems == nil then
		itemEntry.LockContainedItems = true
	end

	local items = itemEntry.Items
	if items == nil then return end

	for nestedItemId, nestedEntry in pairs(items) do
		applyDefaultClassLockSettings(nestedItemId, nestedEntry)
	end
end

function ADV2.ApplyDefaultClassLocks(items)
	if items == nil then return items end
	for itemId, itemEntry in pairs(items) do
		applyDefaultClassLockSettings(itemId, itemEntry)
	end
	return items
end

---@overload fun(itemId: string, inventory: Barotrauma.Inventory, count: integer)
---@param itemId string
---@param inventory Barotrauma.Inventory
---@param itemEntry ItemTableEntry
---@param inheritedLocked boolean?
---@param teamId Barotrauma.CharacterTeamType?
---@param spawnPoint Barotrauma.WayPoint?
---@param character Barotrauma.Character?
local function spawnItems(itemId, inventory, itemEntry, inheritedLocked, teamId, spawnPoint, character)
	local onSpawn = nil
	local quantity = 1
	local condition, quality, spawnIfFull, ignoreLimbs, invSlotType
	local itemPrefab = ItemPrefab.GetItemPrefab(itemId)
	local locked = inheritedLocked == true
	local lockContainedItems = locked
	local lockContainer = false
	local itemOnSpawn = nil

	if type(itemEntry) == "number" then
		quantity = itemEntry
	else
		quantity = itemEntry.Quantity or 1
		condition = itemEntry.Condition
		quality = itemEntry.Quality
		spawnIfFull = itemEntry.SpawnIfFull
		ignoreLimbs = itemEntry.IgnoreLimbs
		invSlotType = itemEntry.InvSlotType
		itemOnSpawn = itemEntry.OnSpawn

		if itemEntry.Locked ~= nil then
			locked = itemEntry.Locked
		end
		if itemEntry.LockContainedItems ~= nil then
			lockContainedItems = itemEntry.LockContainedItems
		else
			lockContainedItems = locked
		end
		if itemEntry.LockContainer ~= nil then
			lockContainer = itemEntry.LockContainer
		end

		local items = itemEntry.Items
		if items ~= nil or locked or lockContainer then
			---@param item Barotrauma.Item
			onSpawn = function (item)
				applyNativeItemLocks(item, locked, lockContainer)

				if items ~= nil then
					for key, value in pairs(items) do
						spawnItems(key, item.OwnInventory, value, lockContainedItems, teamId, spawnPoint, character)
					end
				end
			end
		end
	end

	if onSpawn == nil and (locked or lockContainer) then
		---@param item Barotrauma.Item
		onSpawn = function (item)
			applyNativeItemLocks(item, locked, lockContainer)
		end
	end

	if teamId ~= nil or itemOnSpawn ~= nil then
		local previousOnSpawn = onSpawn
		---@param item Barotrauma.Item
		onSpawn = function (item)
			if previousOnSpawn ~= nil then previousOnSpawn(item) end

			if teamId ~= nil then
				local wifi = item.GetComponentString("WifiComponent")
				if wifi ~= nil then
					wifi.TeamID = teamId
				end
			end

			if itemOnSpawn ~= nil then
				itemOnSpawn(item, spawnPoint, character)
			end
		end
	end

	for _ = 1, quantity do
		Entity.Spawner.AddItemToSpawnQueue(itemPrefab, inventory, condition, quality, onSpawn, spawnIfFull, ignoreLimbs, invSlotType)
	end
end

ADV2.SpawnItems = spawnItems

---@class AttackDefendClassSkill
---@field Identifier string
---@field Level number
---@class AttackDefendClassAffliction
---@field Identifier string
---@field Strength number
---@class AttackDefendClassConfig
---@field Identifier string
---@field JobId string
---@field Skills AttackDefendClassSkill[]?
---@field Talents string[]?
---@field Afflictions AttackDefendClassAffliction[]?
---@field Items ItemTable | fun(): ItemTable
---@field LogSuffix string?

---@param teamId Barotrauma.CharacterTeamType
---@param config AttackDefendClassConfig
---@return Pointshop.Product
function ADV2.CreateClassProduct(teamId, config)
	if type(config.Items) == "table" then
		ADV2.ApplyDefaultClassLocks(config.Items)
	end

	return {
		Identifier = config.Identifier,
		JobId = config.JobId,
		Price = 0,
		Limit = math.huge,
		CanBuy = function(client, product)
			return ADV2.CanBuyGroup(client, product)
		end,
		Action = function(client, product)
			local respawnEntry = ADV2.RespawnStart(client, teamId, product.Identifier, nil, product)
			respawnEntry.JobId = config.JobId

			respawnEntry.OnSpawn = function(character, spawnPoint)
				for _, skill in ipairs(config.Skills or {}) do
					character.info.SetSkillLevel(skill.Identifier, skill.Level)
				end

				for _, talent in ipairs(config.Talents or {}) do
					character.GiveTalent(talent)
				end

				for _, affliction in ipairs(config.Afflictions or {}) do
					character.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs[affliction.Identifier].Instantiate(affliction.Strength))
				end

				local items = config.Items
				if type(items) == "function" then
					items = ADV2.ApplyDefaultClassLocks(items())
				end
				for itemId, itemEntry in pairs(items) do
					spawnItems(itemId, character.Inventory, itemEntry, nil, character.TeamID, spawnPoint, character)
				end
			end

			if config.LogSuffix ~= nil then
				Traitormod.Log(client.Name .. config.LogSuffix)
			end
		end,
	}
end

return ADV2
