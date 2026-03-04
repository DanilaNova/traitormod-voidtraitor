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
randomizer.CreateList("Weapons", function (prefab)
	return
		btest(prefab.Category, categories.Weapon)
		and not btest(prefab.Category, categories.Machine)
		and (prefab.CanBeBought or prefab.CanBeSold)
		and (prefab.ConfigElement.GetAttributeBool('NonInteractable', false))
end)

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

randomizer.CreateList("Materials", function (prefab)
	return btest(prefab.Category, categories.Material)
end)

randomizer.CreateList("All")

randomizer.GetRandom("Materials")

---@type Pointshop.Category
local category = {

Identifier = "randomize",

CanAccess = function (client)
	return client.Character and not client.Character.isDead
end,

Products = {
	{
		Identifier = "randomizeall",
		Price = 1,
		Limit = math.huge,

		Action = function (client)
			Entity.Spawner.AddItemToSpawnQueue(randomizer.GetRandom("CanBeBoughtOrSold"), client.Character.Inventory)
		end,
	},
	{
		Identifier = "randomizeweapons",
		Price = 1,
		Limit = math.huge,
		
		Action = function (client)
			Entity.Spawner.AddItemToSpawnQueue(randomizer.GetRandom("Weapons"), client.Character.Inventory)
		end
	},
}

}

return category