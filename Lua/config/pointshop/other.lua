local category = {}

category.Identifier = "other"

local randomItems = {}
for prefab in ItemPrefab.Prefabs do
    if prefab.CanBeSold or prefab.CanBeBought then
        table.insert(randomItems, prefab)
    end
end

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
        Identifier = "randomitem",
        Price = 100,
        Limit = 15,
        Action = function (client, product, items)
            local item = randomItems[math.random(1, #randomItems)]
            Entity.Spawner.AddItemToSpawnQueue(item, client.Character.WorldPosition, nil, nil, function () end)
        end
    },

    {
        Price = 300,
        Limit = 5,
        Items = {"skillbooksubmarinewarfare"}
    },

    {
        Price = 300,
        Limit = 5,
        Items = {"skillbookeuropanmedicine"}
    },

    {
        Price = 300,
        Limit = 5,
        Items = {"skillbookhandyseaman"}
    },

    {
        Price = 300,
        Limit = 5,
        Items = {"skillbooksailorsguide"}
    },
	
    {
        Price = 300,
        Limit = 5,
        Items = {"skillbooksurgery"}
    },

	{
		Identifier = "firstaidkit",
		Price = 750,
		Limit = 1,
		IsLimitGlobal = false,
		Action = function(client)
			local medToolbox = ItemPrefab.GetItemPrefab("medtoolbox")
			Entity.Spawner.AddItemToSpawnQueue(medToolbox, client.Character.Inventory, nil, nil, function(item)
				local items = {
					{ "blunttraumaointment",    1 },
					{ "ringerssolution",        2 },
					{ "needle",                 1 },
					{ "ointment",               1 },
					{ "antibleeding1", 		    4 },
					{ "antibloodloss1",         1 },
					{ "ethanol",                1 },
					{ "pills1",                 2 },
				}
				addItems(items, item.OwnInventory)
			end)
		end
    },

    {
        Identifier = "clownsuit",
        Price = 450,
        Limit = 2,
        Items = {"clowncostume", "clownmask"}
    },

    {
        Price = 10,
        Limit = 50,
        Items = {"banana"}
    },
	
    {
        Price = 340,
        Limit = 1,
        Items = {"shellshield"}
    },

    {
        Price = 400,
        Limit = 1,
        Items = {"respawndivingsuit"}
    },

    {
        Price = 50,
        Limit = 1,
        Items = {"divingmask"}
    },

    {
        Price = 250,
        Limit = 10,
        Items = {"bikehorn"}
    },

    {
        Price = 50,
        Limit = 2,
        Items = {"guitar"}
    },

    {
        Price = 50,
        Limit = 2,
        Items = {"harmonica"}
    },

    {
        Price = 50,
        Limit = 2,
        Items = {"accordion"}
    },

    {
        Price = 30,
        Limit = 5,
        Items = {"petnametag"}
    },

    {
        Price = 10,
        Limit = 16,
        Items = {"poop"},
    },

    {
        Identifier = "randomegg",
        Price = 50,
        Limit = 5,
        Items = {"smallmudraptoregg", "tigerthresheregg", "crawleregg", "peanutegg", "psilotoadegg", "orangeboyegg", "balloonegg"},
        ItemRandom = true
    },

    {
        Identifier = "assistantbot",
        Price = 600,
        Limit = 5,
        Action = function (client, product, items)
			local info = CharacterInfo(Identifier("human"))
			info.Name = "Assistant " .. info.Name
			info.Job = Job(JobPrefab.Get("assistant"), false)
			
            local character = Character.Create(info, client.Character.WorldPosition, info.Name, 0, false, true)
			
			character.CanSpeak = false
            character.TeamID = CharacterTeamType.Team1
            character.GiveJobItems(false, nil)
			
			Traitormod.GhostRoles.Ask("assistant", function (client)
			Traitormod.LostLivesThisRound[client.SteamID] = false
			client.SetClientCharacter(character)
			end, character)
        end
    },
}

return category