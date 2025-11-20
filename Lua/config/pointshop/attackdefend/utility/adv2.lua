---@diagnostic disable-next-line: unknown-cast-variable
---@cast Traitormod.SelectedGamemode Gamemodes.AttackDefendV2

local ADV2 = {}

---@param client Barotrauma.Networking.Client
---@param classId string
---@param JobId string?
---@return RespawnEntry?
function ADV2.RespawnStart(client, classId, JobId)
	---@type RespawnEntry?
	local respawnEntry = Traitormod.SelectedGamemode.Respawns[client]

	if respawnEntry == nil then
		respawnEntry = {}
		Traitormod.SelectedGamemode.Respawns[client] = respawnEntry
	end

	respawnEntry.JobId = JobId
	local classCounters = Traitormod.SelectedGamemode.ClassCounters

	respawnEntry.PrevClassId = respawnEntry.ClassId
	respawnEntry.ClassId = classId

	classCounters[classId] = (classCounters[classId] or 0) + 1

	return respawnEntry
end

---@param classId string
---@param limit integer
---@return boolean, string?
function ADV2.CanBuy(classId, limit)
	local result = Traitormod.SelectedGamemode.ClassCounters[classId] or 0 < limit
	return result, not result and Traitormod.Language.ReachedClassLimit or nil
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

---@overload fun(itemId: string, inventory: Barotrauma.Inventory, count: integer)
---@param itemId string
---@param inventory Barotrauma.Inventory
---@param itemEntry ItemTableEntry
local function spawnItems(itemId, inventory, itemEntry)
	local onSpawn = nil
	local quantity = 1
	local condition, quality, spawnIfFull, ignoreLimbs, invSlotType
	local itemPrefab = ItemPrefab.GetItemPrefab(itemId)

	if type(itemEntry) == "number" then
		quantity = itemEntry
	else
		quantity = itemEntry.Quantity or 1
		condition = itemEntry.Condition
		quality = itemEntry.Quality
		spawnIfFull = itemEntry.SpawnIfFull
		ignoreLimbs = itemEntry.IgnoreLimbs
		invSlotType = itemEntry.InvSlotType

		local items = itemEntry.Items
		if items ~= nil then
			---@param item Barotrauma.Item
			onSpawn = function (item)
				for key, value in pairs(items) do
					spawnItems(key, item.OwnInventory, value)
				end
			end
		end
	end

	for _ = 1, quantity do
		Entity.Spawner.AddItemToSpawnQueue(itemPrefab, inventory, condition, quality, onSpawn, spawnIfFull, ignoreLimbs, invSlotType)
	end
end

ADV2.SpawnItems = spawnItems

return ADV2