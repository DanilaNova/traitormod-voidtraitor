local category = {}

category.Name = "Death Spawn"
category.IsTraitorOnly = false
category.IsDeadOnly = true

local function SpawnCreature(species, client, insideHuman)
    local waypoints = Submarine.MainSub.GetWaypoints(true)
    local spawnPositions = {}

    if insideHuman then
        for key, value in pairs(Character.CharacterList) do
            if value.IsHuman and not value.IsDead then
                table.insert(spawnPositions, value.WorldPosition)
            end
        end
    else
        for key, value in pairs(waypoints) do
            if value.CurrentHull == nil then
                table.insert(spawnPositions, value.WorldPosition)
            end
        end
    end

    local spawnPosition

    if #spawnPositions == 0 then
        -- no waypoints? https://c.tenor.com/RgExaLgYIScAAAAC/megamind-megamind-meme.gif
        spawnPosition = Submarine.MainSub.WorldPosition -- spawn it in the middle of the sub

        Traitormod.Log("Couldnt find any good waypoints, spawning in the middle of the sub.")
    else
        spawnPosition = spawnPositions[math.random(#spawnPositions)]
    end

    Entity.Spawner.AddCharacterToSpawnQueue(species, spawnPosition, function (character)
        client.SetClientCharacter(character)
    end)
end

category.Products = {
    {
        Name = "Spawn as Crawler",
        Price = 100,
        Limit = 6,
        IsLimitGlobal = true,

        Action = function (client, product, items)
            SpawnCreature("crawler", client)
        end
    },

    {
        Name = "Spawn as Mudraptor",
        Price = 400,
        Limit = 4,
        IsLimitGlobal = true,

        Action = function (client, product, items)
            SpawnCreature("mudraptor", client)
        end
    },

    {
        Name = "Spawn as Husk",
        Price = 900,
        Limit = 2,
        IsLimitGlobal = true,

        Action = function (client, product, items)
            SpawnCreature("husk", client)
        end
    },

    {
        Name = "Spawn as Peanut",
        Price = 50,
        Limit = 2,
        IsLimitGlobal = false,

        Action = function (client, product, items)
            SpawnCreature("peanut", client, true)
        end
    },

    {
        Name = "Spawn as Orange Boy",
        Price = 50,
        Limit = 2,
        IsLimitGlobal = false,

        Action = function (client, product, items)
            SpawnCreature("orangeboy", client, true)
        end
    },

    {
        Name = "Spawn as Cthulhu",
        Price = 50,
        Limit = 2,
        IsLimitGlobal = false,

        Action = function (client, product, items)
            SpawnCreature("balloon", client, true)
        end
    },

    {
        Name = "Spawn as Psilotoad",
        Price = 50,
        Limit = 2,
        IsLimitGlobal = false,

        Action = function (client, product, items)
            SpawnCreature("psilotoad", client, true)
        end
    },
}

return category