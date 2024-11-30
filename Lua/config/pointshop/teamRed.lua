local category = {}

category.Identifier = "teamRed"

-- Проверка что это подходящий игрок:
-- 1) У него есть персонаж
-- 2) Этот персонаж жив(не мёртв)
-- 3) Этот персонаж находится во 2-й команде (Attacker Team)
---@param client Client
---@return boolean
category.CanAccess = function(client)
	return client.Character and not client.Character.IsDead and client.Character.TeamID == CharacterTeamType.Team2
end

---Добавляет указаные в таблице предметы в инвентарь
---@param items table
---@param inventory Inventory
local function addItems(items, inventory)
	for value in items do
		if type(value) == "table" then
			for _ = 1, value[2] do
				Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs[value[1]], inventory)
			end
		else
			Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs[value], inventory)
		end
	end
end

category.Products = {
	{
		Identifier = "redArmor",
		Price = 0,
		Limit = 30,
		IsLimitGlobal = true,

		---@param client Client
		Action = function(client)
			local helmet = ItemPrefab.GetItemPrefab("ballistichelmet1") -- Шаблон предмета
			Entity.Spawner.AddItemToSpawnQueue(helmet, client.Character.Inventory, nil, nil, function(item)
				item.set_InventoryIconColor(Color(150, 0, 0, 255))
				item.SpriteColor = Color(150, 0, 0, 255)
				item.Tags = "smallitem"

				local color = item.SerializableProperties[Identifier("SpriteColor")]
				Networking.CreateEntityEvent(item, Item.ChangePropertyEventData(color, item))
				local invColor = item.SerializableProperties[Identifier("InventoryIconColor")]
				Networking.CreateEntityEvent(item, Item.ChangePropertyEventData(invColor, item))
			end, nil, nil, InvSlotType.Head)

			local uniform = ItemPrefab.GetItemPrefab("securityuniform1")
			Entity.Spawner.AddItemToSpawnQueue(uniform, client.Character.Inventory, nil, nil, function(item)
				item.set_InventoryIconColor(Color(150, 0, 0, 255))
				item.SpriteColor = Color(150, 0, 0, 255)
				item.Tags = "smallitem"

				local color = item.SerializableProperties[Identifier("SpriteColor")]
				Networking.CreateEntityEvent(item, Item.ChangePropertyEventData(color, item))
				local invColor = item.SerializableProperties[Identifier("InventoryIconColor")]
				Networking.CreateEntityEvent(item, Item.ChangePropertyEventData(invColor, item))
			end, nil, nil, InvSlotType.InnerClothes)

			local armor = ItemPrefab.GetItemPrefab("bodyarmor")
			Entity.Spawner.AddItemToSpawnQueue(armor, client.Character.Inventory, nil, nil, function(item)
				-- Цвет предмета RGBA (A - прозрачность)
				item.set_InventoryIconColor(Color(150, 0, 0, 255)) -- Цвет иконки в инвентаре
				item.SpriteColor = Color(150, 0, 0, 255) -- Цвет спрайта (предмета в игре)
				item.Tags = "smallitem"

				-- Вероятно синхронизация цвета между клиентами
				local color = item.SerializableProperties[Identifier("SpriteColor")]
				Networking.CreateEntityEvent(item, Item.ChangePropertyEventData(color, item))
				local invColor = item.SerializableProperties[Identifier("InventoryIconColor")]
				Networking.CreateEntityEvent(item, Item.ChangePropertyEventData(invColor, item))
			end, nil, nil, InvSlotType.OuterClothes)

			local injector = ItemPrefab.GetItemPrefab("autoinjectorheadset") -- Шаблон инжектора
				if headset then
					local wifi = headset.GetComponentString("WifiComponent")
					if wifi then
						wifi.TeamID = CharacterTeamType.Team2
					end
				end
			Entity.Spawner.AddItemToSpawnQueue(injector, client.Character.Inventory, nil, nil, function(item)
				Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs["combatstimulantsyringe"], item.OwnInventory)
			end, nil, nil, InvSlotType.Headset)

			local injector = ItemPrefab.GetItemPrefab("advancedgenesplicer") -- Шаблон генетики
			Entity.Spawner.AddItemToSpawnQueue(injector, client.Character.Inventory, nil, nil, function(item)
				Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs["geneticmaterialmoloch"], item.OwnInventory)
				Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs["geneticmaterialmantis"], item.OwnInventory)
			end, nil, nil, InvSlotType.HealthInterface)
		end
	},

	{
		Identifier = "medicine",
		Price = 0,
		Limit = 20,
		IsLimitGlobal = true,
		Action = function(client)
			local medToolbox = ItemPrefab.GetItemPrefab("medtoolbox")
			Entity.Spawner.AddItemToSpawnQueue(medToolbox, client.Character.Inventory, nil, nil, function(item)
				--#region Старый алгоритм добавления предметов
				-- local items = {
				-- 	"antibleeding1", "antibleeding1", "antibleeding1",	-- 8 бинтов
				-- 	"antibleeding1", "antibleeding1", "antibleeding1",
				-- 	"antibleeding1", "antibleeding1",
				-- 	"antidama1", "antidama1", "antidama1", "antidama1",	-- 8 морфина
				-- 	"antidama1", "antidama1", "antidama1", "antidama1",
				-- 	"antibiotics", "antibiotics", "antibiotics",		-- 8 антибиотиков
				-- 	"antibiotics", "antibiotics", "antibiotics",
				-- 	"antibiotics", "antibiotics",
				-- 	"antibleeding3", "antibleeding3", "antibleeding3",	-- 16 антибиотического клея
				-- 	"antibleeding3", "antibleeding3", "antibleeding3",
				-- 	"antibleeding3", "antibleeding3", "antibleeding3",
				-- 	"antibleeding3", "antibleeding3", "antibleeding3",
				-- 	"antibleeding3", "antibleeding3", "antibleeding3",
				-- 	"antibleeding3",
				-- 	"combatstimulantsyringe", "combatstimulantsyringe",	-- 8 боевых стимуляторов
				-- 	"combatstimulantsyringe", "combatstimulantsyringe",
				-- 	"combatstimulantsyringe", "combatstimulantsyringe",
				-- 	"combatstimulantsyringe", "combatstimulantsyringe",
				-- 	"ointment", "ointment", "ointment",	"ointment",		-- 8 антибиотической мазь
				-- 	"ointment", "ointment", "ointment", "ointment",
				-- 	"gypsum", "gypsum", "gypsum", "gypsum",				-- 4 гипса
				-- 	"antibloodloss2", "antibloodloss2",					-- 8 пакетов с кровью
				-- 	"antibloodloss2", "antibloodloss2",
				-- 	"antibloodloss2", "antibloodloss2",
				-- 	"antibloodloss2", "antibloodloss2"
				-- }

				-- for key, value in pairs(items) do
				-- 	Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs[value], item.OwnInventory)
				-- end
				--#endregion

				local items = {
					{ "antibleeding1",          8 }, -- бинты
					{ "antidama1",              8 }, -- морфин
					{ "antibiotics",            8 }, -- антибиотики
					{ "blunttraumaointment",          1 }, -- антибиотический клей
					{ "suture", 				16 },-- швы
					{ "combatstimulantsyringe", 8 }, -- боевые стимуляторы
					{ "ointment",               1 }, -- антибиотическая мазь
					{ "gypsum",                 4 }, -- гипс
					{ "antibloodloss2",         8 }, -- пакеты с кровью
				}
				addItems(items, item.OwnInventory)
			end)

			local surgeryToolbox = ItemPrefab.GetItemPrefab("surgerytoolbox")
			Entity.Spawner.AddItemToSpawnQueue(surgeryToolbox, client.Character.Inventory, nil, nil, function(item)
				local items = {
					"advscalpel",
					"advhemostat",
					"advretractors",
					"surgicaldrill",
					"surgerysaw",
					{ "suture", 16 },
					"traumashears",
					"endovascballoon",
					"medstent",
					"tweezers",
					{"drainage", 4 },
				}
				addItems(items, item.OwnInventory)
			end)

			local medkit = ItemPrefab.GetItemPrefab("medkit")
			Entity.Spawner.AddItemToSpawnQueue(medkit, client.Character.Inventory, nil, nil, function(item)
				local items = {
					{"redjellymedS" ,	2 },
					{"greenjellymedS", 	2 },
				}
				addItems(items, item.OwnInventory)
			end)
			
			local toolbelt = ItemPrefab.GetItemPrefab("artmod_toolbelt")
			Entity.Spawner.AddItemToSpawnQueue(toolbelt, client.Character.Inventory, nil, nil, function(item)
				local items = {
					"aed",
					"healthscanner",
					"osteosynthesisimplants",
					"spinalimplant",
					{ "tourniquet",           4 },
					{ "fulguriumbatterycell", 3 },
					"heavywrench",
				}
				addItems(items, item.OwnInventory)
			end)
		end
	},

	{
		Identifier = "ShotGun",
		Price = 0,
		Limit = 20,
		IsLimitGlobal = true,
		Action = function(client)
			local shotgun = ItemPrefab.GetItemPrefab("shotgun")
			Entity.Spawner.AddItemToSpawnQueue(shotgun, client.Character.Inventory, nil, nil, function(item)
				for _ = 1, 6 do -- Повторить 6 раз (начать отсчёт с 1, и считать до 6 включительно)
					Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs["shotgunshell"], item.OwnInventory)
				end
			end)
			for _ = 1, 12 do
				Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs["shotgunshell"], client.Character.Inventory)
			end
			-- Сигнатура функции -
			-- функция(
			--	предмет или префаб,
			--	инвентарь,
			--	-- Далее необязательные [так указано значение по умолчанию] --
			--	состояние[100%],
			--	качество[1],
			--	функция вызываемая при спавне предмета[пусто],
			--	спавнить ли при полном инвентаре(true или false)[true],
			--	игнорировать слоты конечностей(непонятно)[],
			--	Тип слота куда поместить предмет[InvSlotType.Any]
			-- )
		end
	},

	{
		Identifier = "rifle",
		Price = 0,
		Limit = 20,
		IsLimitGlobal = true,
		Action = function(client)
			local rifle = ItemPrefab.GetItemPrefab("rifle")
			Entity.Spawner.AddItemToSpawnQueue(rifle, client.Character.Inventory, nil, nil, function(item)
				for _ = 1, 6 do
					Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs["riflebullet"], item.OwnInventory)
				end
			end)
			for _ = 1, 12 do
				Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs["riflebullet"], client.Character.Inventory)
			end
		end
	},
	
	{
		Identifier = "revolver",
		Price = 0,
		Limit = 10,
		IsLimitGlobal = true,
		Action = function(client)
			local revolver = ItemPrefab.GetItemPrefab("revolver")
			Entity.Spawner.AddItemToSpawnQueue(revolver, client.Character.Inventory, nil, nil, function(item)
				for _ = 1, 6 do
					Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs["revolverround"], item.OwnInventory)
				end
			end)
			for _ = 1, 12 do
				Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs["revolverround"], client.Character.Inventory)
			end
		end
	},

	{
		Identifier = "maxSkills",
		Price = 0,
		Limit = 1,
		IsLimitGlobal = false,
		Action = function(client)
			for skill in client.Character.Info.Job.GetSkills() do
				client.Character.Info.SetSkillLevel(skill.Identifier, 100)
			end
		end
	},

}

return category
