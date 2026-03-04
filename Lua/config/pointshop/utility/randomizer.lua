local randomizer = {}

---@alias RandomizerFilter fun(prefab: Barotrauma.ItemPrefab): boolean

---@type Barotrauma.ItemPrefab[]
local CanBeBoughtOrSold = {}

for prefab in ItemPrefab.Prefabs do
	if (prefab.CanBeBought or prefab.CanBeSold) and not prefab.ConfigElement.GetAttributeBool('NonInteractable', false) then
		table.insert(CanBeBoughtOrSold, prefab)
	end
end

---@type table<string, Barotrauma.ItemPrefab[]>
randomizer.Lists = {CanBeBoughtOrSold = CanBeBoughtOrSold}

---@param name string
---@param filter? RandomizerFilter
---@return integer
function randomizer.CreateList(name, filter)
	local filter = filter or function() return true end
	local list = {}

	for prefab in ItemPrefab.Prefabs do
		if filter(prefab) then
			table.insert(list, prefab)
		end
	end

	randomizer.Lists[name] = list
	return #list
end

---@param newCategory string
---@param fromCategory string
---@param filter? RandomizerFilter
---@return integer
function randomizer.CreateFrom(newCategory, fromCategory, filter)
	local filter = filter or function() return true end
	local newList = {}
	local fromList = randomizer.Lists[fromCategory]

	for _, prefab in ipairs(fromList) do
		if filter(prefab) then
			table.insert(newList, prefab)
		end
	end

	randomizer.Lists[newCategory] = newList
	return #newList
end

---@param blacklist string[] List of item identifiers
---@return RandomizerFilter
function randomizer.BlacklistFilter(blacklist)
	return function (prefab)
		for _, id in ipairs(blacklist) do
			if prefab.Identifier == id then
				return false
			end
		end
		return true
	end
end

---@param filter RandomizerFilter
---@param category? string
function randomizer.Filter(filter, category)
	local lists
	if category then
		lists = { [category] = randomizer.Lists[category] }
	else
		lists = randomizer.Lists
	end

	for category, oldList in pairs(lists) do
		---@type Barotrauma.ItemPrefab[]
		local newList = {}

		for _, prefab in ipairs(oldList) do
			if filter(prefab) then
				table.insert(newList, prefab)
			end
		end

		randomizer.Lists[category] = newList
	end
end

---@param category? string
---@return Barotrauma.ItemPrefab
function randomizer.GetRandom(category)
	local category = category or "CanBeBoughtOrSold"
	local i = math.random(#randomizer.Lists[category])
	return randomizer.Lists[category][i]
end

return randomizer