---@module "utility.randomizer"
local randomizer = dofile(Traitormod.Path .. "/Lua/config/pointshop/utility/randomizer.lua")

-- Создание нового списка
local categories = {
	Structure = 1,
	Decorative = 2,
	Machine = 4,
	Medical = 8,
	Weapon = 16,
	Diving = 32,
	Equipment = 64,
	Fuel = 128,
	Electrical = 256,
	Material = 1024,
	Alien = 2048,
	Wrecked = 4096,
	ItemAssembly = 8192,
	Legacy = 16384,
	Misc = 32768
}
local btest = bit32.btest

-- Создание нового списка
-- randomizer.CreateList("Weapons", function (prefab)
-- 	return
-- 		btest(prefab.Category, categories.Weapon)
-- 		and not btest(prefab.Category, categories.Machine)
-- 		and (prefab.CanBeBought or prefab.CanBeSold)
-- 		and not prefab.ConfigElement.GetAttributeBool('NonInteractable', false)
-- end)

-- Создание списка на основе имеющегося
randomizer.CreateFrom("Weapons", "CanBeBoughtOrSold", function (prefab)
	return
		btest(prefab.Category, categories.Weapon)
		and not btest(prefab.Category, categories.Machine)
end)

-- Фильтр списка через чёрный список
local blacklist = {}
randomizer.Filter(randomizer.BlacklistFilter(blacklist), "Weapons")

-- Использование фильтра-функции
randomizer.Filter(function (prefab)
	for tag in prefab.Tags do
		if tag == "weapon" then
			return true
		end
	end
	return false
end, "Weapons")

randomizer.CreateList("Material", function (prefab)
	return btest(prefab.Category, categories.Material)
end)

randomizer.CreateList("All", function (prefab)
	return not prefab.ConfigElement.GetAttributeBool('NonInteractable', false)
end)

randomizer.CreateList("Medical", function (prefab)
	return btest(prefab.Category, categories.Medical)
end)

local function canPreview(prefab)
	if prefab.ConfigElement.GetAttributeBool('NonInteractable', false) then return false end
	for tag in prefab.Tags do
		if tag == "alienartifact" then return false end
	end

	for element in prefab.ConfigElement.Descendants() do
		local name = string.lower(element.Name.LocalName)
		if name == "door"
			or name == "entityspawnercomponent"
			or name == "spawnitem"
			or name == "spawncharacter"
			or element.GetAttributeString("spawnwithid", "") ~= "" then
			return false
		end
		if name == "statuseffect" and string.lower(element.GetAttributeString("type", "")) == "onspawn" then
			return false
		end
	end
	return true
end

randomizer.CreateFrom("PreviewAll", "All", canPreview)
randomizer.CreateFrom("PreviewNormal", "CanBeBoughtOrSold", canPreview)
randomizer.CreateFrom("PreviewMaterial", "Material", canPreview)
randomizer.CreateFrom("PreviewMedical", "Medical", canPreview)
randomizer.CreateFrom("PreviewWeapons", "Weapons", canPreview)

local BodyType = LuaUserData.CreateEnumTable("FarseerPhysics.BodyType")
local Category = LuaUserData.CreateEnumTable("FarseerPhysics.Dynamics.Category")
local crateLists = {
	vtcasinocratecrazy = { reward = "All", preview = "PreviewAll" },
	vtcasinocratenormal = { reward = "CanBeBoughtOrSold", preview = "PreviewNormal" },
	vtcasinocratematerials = { reward = "Material", preview = "PreviewMaterial" },
	vtcasinocratemedical = { reward = "Medical", preview = "PreviewMedical" },
	vtcasinocrateweapons = { reward = "Weapons", preview = "PreviewWeapons" }
}
local rouletteChangeTimes = {
	0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5, 5.5, 6,
	6.75, 8
}
local openingCrates = setmetatable({}, { __mode = "k" })

local function spawnAtPosition(prefab, position, submarine, onSpawned)
	if submarine == nil then
		Entity.Spawner.AddItemToSpawnQueue(prefab, position, nil, nil, onSpawned)
	else
		Entity.Spawner.AddItemToSpawnQueue(prefab, position, submarine, nil, nil, onSpawned)
	end
end

local function getRouletteBottom(state)
	local progress = math.min(state.elapsed / 1.5, 1)
	progress = 1 - (1 - progress) ^ 3
	return state.floorY + (state.hoverBottomY - state.floorY) * progress
end

local function removeItemAndContents(item)
	for containedItem in item.ContainedItems do
		Entity.Spawner.AddEntityToRemoveQueue(containedItem)
	end
	Entity.Spawner.AddEntityToRemoveQueue(item)
end

local function removePreview(state)
	if state.preview ~= nil and not state.preview.Removed then
		removeItemAndContents(state.preview)
	end
	state.preview = nil
end

local function spawnPreview(state)
	state.generation = state.generation + 1
	local generation = state.generation
	removePreview(state)

	local prefab = randomizer.GetRandom(state.previewList)
	local position = Vector2(state.x, getRouletteBottom(state) + prefab.Size.Y * prefab.Scale / 2)
	spawnAtPosition(prefab, position, state.submarine, function(preview)
		if state.finished or state.generation ~= generation then
			removeItemAndContents(preview)
			return
		end

		preview.NonInteractable = true
		preview.SpriteDepth = state.previewDepth
		preview.IsActive = false
		Networking.CreateEntityEvent(preview, Item.ChangePropertyEventData(preview.SerializableProperties[Identifier("NonInteractable")], preview))
		Networking.CreateEntityEvent(preview, Item.ChangePropertyEventData(preview.SerializableProperties[Identifier("SpriteDepth")], preview))
		if preview.body ~= nil then
			preview.body.BodyType = BodyType.Kinematic
			preview.body.CollisionCategories = Category.None
			preview.body.CollidesWith = Category.None
			preview.body.LinearVelocity = Vector2.Zero
			preview.body.AngularVelocity = 0
			preview.PositionUpdateInterval = state.elapsed < 1.5 and 0.1 or 30
		end
		state.preview = preview
	end)
end

local function finishRoulette(crate, state)
	state.finished = true
	state.generation = state.generation + 1
	removePreview(state)

	local prefab = state.reward
	local position = Vector2(state.x, state.hoverBottomY + prefab.Size.Y * prefab.Scale / 2)
	spawnAtPosition(prefab, position, state.submarine, function(reward)
		if reward.body == nil or reward.body.BodyType ~= BodyType.Dynamic then
			local floorPosition = Vector2(state.x, state.floorY + reward.Prefab.Size.Y * reward.Scale / 2)
			reward.SetTransform(ConvertUnits.ToSimUnits(floorPosition), 0, true, true, state.submarine)
		end
	end)

	Entity.Spawner.AddEntityToRemoveQueue(crate)
	openingCrates[crate] = nil
end

Hook.Add("think", "Traitormod.Pointshop.RandomizeCrateRoulette", function(deltaTime)
	for crate, state in pairs(openingCrates) do
		if crate.Removed then
			state.finished = true
			state.generation = state.generation + 1
			removePreview(state)
			openingCrates[crate] = nil
		else
			state.elapsed = state.elapsed + deltaTime
			if state.elapsed >= 10 then
				finishRoulette(crate, state)
			else
				local preview = state.preview
				if preview ~= nil and not preview.Removed and preview.body ~= nil and state.elapsed <= 1.5 then
					local position = Vector2(state.x, getRouletteBottom(state) + preview.Prefab.Size.Y * preview.Scale / 2)
					preview.SetTransform(ConvertUnits.ToSimUnits(position), 0, false, false, state.submarine)
					preview.PositionUpdateInterval = 0.1
				end

				local change = false
				while state.nextChange <= #rouletteChangeTimes and state.elapsed >= rouletteChangeTimes[state.nextChange] do
					state.nextChange = state.nextChange + 1
					change = true
				end
				if change then
					spawnPreview(state)
				end
			end
		end
	end
end)

Hook.Add("item.interact", "Traitormod.Pointshop.RandomizeCrateInteract", function (item, character, _, forceSelectKey)
	if item == nil or character == nil or openingCrates[item] then return end

	local crateConfig = crateLists[item.Prefab.Identifier.Value]
	if crateConfig == nil then return end

	local holdable = item.GetComponentString("Holdable")
	if holdable == nil or not holdable.IsAttached then return end
	if not forceSelectKey and not character.IsKeyHit(InputType.Select) then return end

	local floorY = item.Rect.Y - item.Rect.Height
	local state = {
		previewList = crateConfig.preview,
		reward = randomizer.GetRandom(crateConfig.reward),
		submarine = item.Submarine,
		x = item.Position.X,
		floorY = floorY,
		hoverBottomY = item.Rect.Y + 20,
		previewDepth = math.max(0.001, item.SpriteDepth - 0.01),
		elapsed = 0,
		nextChange = 1,
		generation = 0,
		finished = false
	}
	openingCrates[item] = state
	item.NonInteractable = true
	Networking.CreateEntityEvent(item, Item.ChangePropertyEventData(item.SerializableProperties[Identifier("NonInteractable")], item))
	spawnPreview(state)
	return true
end)

---@type Pointshop.Category
local category = {

Identifier = "randomize",

CanAccess = function (client)
	return client.Character and not client.Character.IsDead
end,

Products = {
	{
		Identifier = "randomize_crazy_all",
		Price = 150,
		Limit = 10,
		Items = {"vtcasinocratecrazy"},
	},
	{
		Identifier = "randomize_normal_all",
		Price = 75,
		Limit = 15,
		Items = {"vtcasinocratenormal"},
	},
	{
		Identifier = "randomize_materials",
		Price = 25,
		Limit = 20,
		Items = {"vtcasinocratematerials"},
	},
	{
		Identifier = "randomize_medical",
		Price = 50,
		Limit = 10,
		Items = {"vtcasinocratemedical"},
	},
	{
		Identifier = "randomize_weapons",
		Price = 750,
		Limit = 5,
		Items = {"vtcasinocrateweapons"},
	},
}

}

return category
