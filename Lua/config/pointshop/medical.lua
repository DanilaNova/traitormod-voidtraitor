local category = {}

category.Identifier = "medical"

category.CanAccess = function(client)
    return client.Character and not client.Character.IsDead and 
    (client.Character.HasJob("medicaldoctor") or client.Character.HasJob("surgeon"))
end

-- this is just so i don't need to type out all the 34 different unresearched genetic materials
local geneticMaterials = {}
for prefab in ItemPrefab.Prefabs do
    if string.find(prefab.Identifier.Value, "_unresearched") then
        table.insert(geneticMaterials, prefab.Identifier.Value)
    end
end

category.Products = {
    {
        Price = 250,
        Limit = 4,
        Items = {"antibiotics"}
    },
	
	{
        Price = 300,
        Limit = 3,
        Items = {"thiamine"}
    },
	
	{
        Price = 300,
        Limit = 3,
        Items = {"immunosuppressant"}
    },
	
	{
        Price = 300,
        Limit = 3,
        Items = {"mannitol"}
    },
	
    {
        Price = 600,
        Limit = 2,
        Items = {"mannitolplus"}
    },
	
	{
        Price = 600,
        Limit = 2,
        Items = {"antinarc"}
    },
	
	{
        Price = 600,
        Limit = 2,
        Items = {"antiparalysis"}
    },
	
    {
        Price = 100,
        Limit = 4,
        Items = {"bandage","bandage","bandage", "bandage"}
    },

	{
        Price = 100,
        Limit = 5,
        Items = {"gypsum"}
    },

    {
        Price = 150,
        Limit = 5,
        Items = {"opium", "opium"}
    },
	
	{
        Price = 250,
        Limit = 3,
        Items = {"antidama2"}
    },
	
    {
        Price = 300,
        Limit = 2,
        Items = {"suture", "suture", "suture", "suture", "suture", "suture", "suture", "suture"}
    },
    
    {
        Price = 125,
        Limit = 4,
        Items = {"antibloodloss1"}
    },
	
    {
        Price = 150,
        Limit = 4,
        Items = {"needle"}
    },
    
	{
        Price = 75 ,
        Limit = 4,
        Items = {"ointment", "ointment", "ointment", "ointment"}
    },

    {
        Price = 75,
        Limit = 4,
        Items = {"skinaid", "skinaid", "skinaid", "skinaid"}
    },
    
    {
        Price = 75,
        Limit = 8,
        Items = {"meth"}
    },
    
    {
        Price = 70,
        Limit = 4,
        Items = {"chlorine"}
    },

    {
        Price = 60,
        Limit = 4,
        Items = {"sulphuricacid"}
    },
    
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
        Price = 1000,
        Limit = 2,
        Items = {"genesplicer"}
    },
    
    {
        Price = 1500,
        Limit = 1,
        Items = {"advancedgenesplicer"}
    },

    {
        Price = 150,
        Limit = 10,
        ItemRandom = true,
        Items = geneticMaterials
    }
}

return category