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

---@type Pointshop.Category
local category = {

Identifier = "randomize",

CanAccess = function (client)
	return client.Character and not client.Character.isDead
end,

Products = {
	{
		Identifier = "randomize_crazy_all",
		Price = 150,
		Limit = 10,

		Action = function (client)
			Entity.Spawner.AddItemToSpawnQueue(randomizer.GetRandom("All"), client.Character.Inventory)
		end,
	},
	{
		Identifier = "randomize_normal_all",
		Price = 75,
		Limit = 15,
		
		Action = function (client)
			Entity.Spawner.AddItemToSpawnQueue(randomizer.GetRandom("CanBeBoughtOrSold"), client.Character.Inventory)
		end
	},
	{
		Identifier = "randomize_materials",
		Price = 25,
		Limit = 20,
		
		Action = function (client)
			Entity.Spawner.AddItemToSpawnQueue(randomizer.GetRandom("Material"), client.Character.Inventory)
		end
	},
	{
		Identifier = "randomize_medical",
		Price = 50,
		Limit = 10,
		
		Action = function (client)
			Entity.Spawner.AddItemToSpawnQueue(randomizer.GetRandom("Medical"), client.Character.Inventory)
		end
	},
	{
		Identifier = "randomize_weapons",
		Price = 750,
		Limit = 5,
		
		Action = function (client)
			Entity.Spawner.AddItemToSpawnQueue(randomizer.GetRandom("Weapons"), client.Character.Inventory)
		end
	},
}

}

return category