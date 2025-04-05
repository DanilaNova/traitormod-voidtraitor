local category = {}

category.Identifier = "surgery"

category.CanAccess = function(client)
    return client.Character and not client.Character.IsDead and 
    (client.Character.HasJob("surgeon"))
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
        Price = 100,
        Limit = 5,
        Items = {"bodybag"}
    },
	
    {
        Price = 400,
        Limit = 2,
        Items = {"stasisbag"}
    },
	
    {
        Price = 200,
        Limit = 4,
        Items = {"needle"}
    },
	
    {
        Price = 300,
        Limit = 5,
        Items = {"osteosynthesisimplants"}
    },
	
    {
        Price = 400,
        Limit = 5,
        Items = {"spinalimplant"}
    },
	
    {
        Price = 750,
        Limit = 1,
        Items = {"organscalpel_brain"}
    },
	
    {
        Price = 250,
        Limit = 2,
        Items = {"brainjar"}
    },
	
    {
        Price = 750,
        Limit = 1,
        Items = {"aed"}
    },
	
	{
		Identifier = "organs",
		Price = 1250,
		Limit = 1,
		IsLimitGlobal = false,
		Action = function(client)
			local organtoolbox = ItemPrefab.GetItemPrefab("organtoolbox")
			Entity.Spawner.AddItemToSpawnQueue(organtoolbox, client.Character.Inventory, nil, nil, function(item)
				local items = {
					{ "kidneytransplant",  2 },
					{ "lungtransplant",    1 },
					{ "livertransplant",   1 },
					{ "hearttransplant",   1 },
					{ "immunosuppressant", 1 },
				}
				addItems(items, item.OwnInventory)
			end)
		end
    },
	
    {
        Price = 500,
        Limit = 2,
        Items = {"cyberleg"}
    },
	
    {
        Price = 500,
        Limit = 2,
        Items = {"cyberarm"}
    },
	
    {
        Price = 1000,
        Limit = 1,
        Items = {"llegp"}
    },
	
    {
        Price = 1000,
        Limit = 1,
        Items = {"rlegp"}
    },
	
    {
        Price = 1000,
        Limit = 1,
        Items = {"rarmp"}
    },
	
    {
        Price = 1000,
        Limit = 1,
        Items = {"larmp"}
    }
}

return category