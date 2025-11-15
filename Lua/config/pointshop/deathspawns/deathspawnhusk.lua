local category = {}

category.Identifier = "deathspawnhusk"
category.Decoration = "huskinvite"

category.CanAccess = function(client)
    return client.Character == nil or client.Character.IsDead or not client.Character.IsHuman
end

local function SpawnCreature(species, client, product, paidPrice, insideHuman)
    local waypoints = Submarine.MainSub.GetWaypoints(true)

    if LuaUserData.IsTargetType(Game.GameSession.GameMode, "Barotrauma.PvPMode") then
        waypoints = Submarine.MainSubs[math.random(2)].GetWaypoints(true)
    end

    local spawnPositions = {}

    if insideHuman then
        for key, value in pairs(Character.CharacterList) do
            if value.IsHuman and not value.IsDead and value.TeamID == CharacterTeamType.Team1 then
                table.insert(spawnPositions, value.WorldPosition)
            end
        end
    else
        for key, value in pairs(waypoints) do
            if value.CurrentHull == nil then
                local walls = Level.Loaded.GetTooCloseCells(value.WorldPosition, 250)
                if #walls == 0 then
                    table.insert(spawnPositions, value.WorldPosition)
                end
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
        Traitormod.Pointshop.TrackRefund(client, product, paidPrice)
    end)
end

category.Products = {
    -- Начало пункта поинтшопа
    --{
        --Identifier = "spawnascrawler", -- Название пункта в поинтшопе, не существа, нужно для перевода
        --Price = 400, -- Цена
        --Limit = 5, -- Лимит
		--IsLimitGlobal = true, -- Глобальный лимит или нет
        --PricePerLimit = 100, -- На сколько увеличивается цена с каждым новым спавном (например первый - 400, второй - 500 и т.д.)
        --Timeout = 300, -- Время отката

        --RoundPrice = {
            --PriceReduction = 300, -- Сколько ценна отнимаеться при оконачение падение
            --StartTime = 15, -- Через сколько времени после начала раунда цена начинает падать (вероятно в минутах)
            --EndTime = 30, -- Через сколько времени цена упадёт до минимума(PriceReduction)
        --},

        -- Действие при покупке
        --Action = function (client, product, items, paidPrice)
            --SpawnCreature("crawler", client, product, paidPrice)
            -- SpawnCreature(
            -- существо,
            -- клиент(игрок),
            -- продукт(вероятно ссылка на этот пункт поинтшопа),
            -- Заплаченная цена
            -- )
            -- Сдесь лучше ничего кроме названия существа не трогать
       --end
    --},
     -- Конец пункта поинтшопа
	{
        Identifier = "spawnascrawlerhusk",
        Price = 500,
        Limit = 3,
        IsLimitGlobal = true,
        PricePerLimit = 100,
        Timeout = 300,

        RoundPrice = {
            PriceReduction = 200,
            StartTime = 10,
            EndTime = 20,
        },

        Action = function (client, product, items, paidPrice)
            SpawnCreature("Crawlerhusk", client, product, paidPrice)
        end
    },
	
    {
        Identifier = "spawnaslegacyhusk",
        Price = 400,
        Limit = 5,
        IsLimitGlobal = true,
        PricePerLimit = 100,
        Timeout = 300,

        RoundPrice = {
            PriceReduction = 150,
            StartTime = 10,
            EndTime = 20,
        },

        Action = function (client, product, items, paidPrice)
            SpawnCreature("legacyhusk", client, product, paidPrice)
        end
    },

    {
        Identifier = "spawnasHammerhead_mhusk",
        Price = 2900,
        Limit = 2,
        IsLimitGlobal = true,
        PricePerLimit = 500,
        Timeout = 300,

        RoundPrice = {
            PriceReduction = 1750,
            StartTime = 15,
            EndTime = 35,
        },

        Action = function (client, product, items, paidPrice)
            SpawnCreature("Hammerhead_mhusk", client, product, paidPrice)
        end
    },
	
    {
        Identifier = "spawnasHammerheadmatriarchhusk",
        Price = 3500,
        Limit = 1,
        IsLimitGlobal = true,
        PricePerLimit = 0,
        Timeout = 300,

        RoundPrice = {
            PriceReduction = 1950,
            StartTime = 15,
            EndTime = 35,
        },

        Action = function (client, product, items, paidPrice)
            SpawnCreature("Hammerhead_mhusk", client, product, paidPrice)
        end
    },
	
    {
        Identifier = "spawnasCoelanthhusk",
        Price = 1600,
        Limit = 3,
        IsLimitGlobal = true,
        PricePerLimit = 250,
        Timeout = 300,

        RoundPrice = {
            PriceReduction = 750,
            StartTime = 15,
            EndTime = 35,
        },

        Action = function (client, product, items, paidPrice)
            SpawnCreature("Coelanthhusk", client, product, paidPrice)
        end
    },
	
    {
        Identifier = "spawnasBonethresherhusk",
        Price = 2250,
        Limit = 2,
        IsLimitGlobal = true,
        PricePerLimit = 500,
        Timeout = 300,

        RoundPrice = {
            PriceReduction = 1000,
            StartTime = 15,
            EndTime = 35,
        },

        Action = function (client, product, items, paidPrice)
            SpawnCreature("Bonethresherhusk", client, product, paidPrice)
        end
    },
	
    {
        Identifier = "spawnasTigerthresherhusk",
        Price = 2850,
        Limit = 3,
        IsLimitGlobal = true,
        PricePerLimit = 500,
        Timeout = 300,

        RoundPrice = {
            PriceReduction = 1500,
            StartTime = 20,
            EndTime = 40,
        },

        Action = function (client, product, items, paidPrice)
            SpawnCreature("Tigerthresherhusk", client, product, paidPrice)
        end
    },	
	
    {
        Identifier = "spawnasSnatcher",
        Price = 500,
        Limit = 1,
        IsLimitGlobal = false,
        PricePerLimit = 0,
        Timeout = 300,

        RoundPrice = {
            PriceReduction = 250,
            StartTime = 10,
            EndTime = 20,
        },

        Action = function (client, product, items, paidPrice)
            SpawnCreature("Snatcher", client, product, paidPrice)
        end
    },
	
    {
        Identifier = "spawnasMolochhusk",
        Price = 7500,
        Limit = 1,
        IsLimitGlobal = true,
        PricePerLimit = 0,
        Timeout = 300,

        RoundPrice = {
            PriceReduction = 3000,
            StartTime = 25,
            EndTime = 45,
        },

        Action = function (client, product, items, paidPrice)
            SpawnCreature("Molochhusk", client, product, paidPrice)
        end
    },
	
    {
        Identifier = "spawnasMolochblackhusk",
        Price = 10000,
        Limit = 1,
        IsLimitGlobal = true,
        PricePerLimit = 0,
        Timeout = 300,

        RoundPrice = {
            PriceReduction = 4500,
            StartTime = 30,
            EndTime = 45,
        },

        Action = function (client, product, items, paidPrice)
            SpawnCreature("Molochblackhusk", client, product, paidPrice)
        end
    },
	
    {
        Identifier = "spawnasMantishusk",
        Price = 1800,
        Limit = 2,
        IsLimitGlobal = true,
        PricePerLimit = 500,
        Timeout = 300,

        RoundPrice = {
            PriceReduction = 1000,
            StartTime = 25,
            EndTime = 45,
        },

        Action = function (client, product, items, paidPrice)
            SpawnCreature("Mantishusk", client, product, paidPrice)
        end
    },	
	
    {
        Identifier = "spawnasLegacycrawlerhusk",
        Price = 800,
        Limit = 3,
        IsLimitGlobal = true,
        PricePerLimit = 400,
        Timeout = 300,

        RoundPrice = {
            PriceReduction = 300,
            StartTime = 15,
            EndTime = 30,
        },

        Action = function (client, product, items, paidPrice)
            SpawnCreature("Legacycrawlerhusk", client, product, paidPrice)
        end
    },
	
    {
        Identifier = "spawnasHuskmutanthunterranged",
        Price = 12000,
        Limit = 1,
        IsLimitGlobal = true,
        PricePerLimit = 0,
        Timeout = 300,

        RoundPrice = {
            PriceReduction = 5500,
            StartTime = 30,
            EndTime = 45,
        },

        Action = function (client, product, items, paidPrice)
            SpawnCreature("Huskmutanthunterranged", client, product, paidPrice)
        end
    },	
	
    {
        Identifier = "spawnasHuskmutanttigerthresher",
        Price = 6000,
        Limit = 1,
        IsLimitGlobal = true,
        PricePerLimit = 0,
        Timeout = 300,

        RoundPrice = {
            PriceReduction = 3500,
            StartTime = 25,
            EndTime = 40,
        },

        Action = function (client, product, items, paidPrice)
            SpawnCreature("Huskmutanttigerthresher", client, product, paidPrice)
        end
    },
	
    {
        Identifier = "spawnasHuskmutantcrawler",
        Price = 2250,
        Limit = 2,
        IsLimitGlobal = true,
        PricePerLimit = 500,
        Timeout = 300,

        RoundPrice = {
            PriceReduction = 1650,
            StartTime = 25,
            EndTime = 40,
        },

        Action = function (client, product, items, paidPrice)
            SpawnCreature("Huskmutantcrawler", client, product, paidPrice)
        end
    },
	
    {
        Identifier = "spawnasHuskmutantmudraptor",
        Price = 2250,
        Limit = 2,
        IsLimitGlobal = true,
        PricePerLimit = 500,
        Timeout = 300,

        RoundPrice = {
            PriceReduction = 1250,
            StartTime = 25,
            EndTime = 40,
        },

        Action = function (client, product, items, paidPrice)
            SpawnCreature("Huskmutantmudraptor", client, product, paidPrice)
        end
    },	
	
    {
        Identifier = "spawnasHuskmutantarmoredpucs",
        Price = 18000,
        Limit = 2,
        IsLimitGlobal = true,
        PricePerLimit = 500,
        Timeout = 300,

        RoundPrice = {
            PriceReduction = 9500,
            StartTime = 35,
            EndTime = 50,
        },

        Action = function (client, product, items, paidPrice)
            SpawnCreature("Huskmutantmudraptor", client, product, paidPrice)
        end
    },	
	
    {
        Identifier = "spawnasEndwormhuskhead",
        Price = 5500,
        Limit = 1,
        IsLimitGlobal = true,
        PricePerLimit = 0,
        Timeout = 300,

        RoundPrice = {
            PriceReduction = 3500,
            StartTime = 20,
            EndTime = 40,
        },

        Action = function (client, product, items, paidPrice)
            SpawnCreature("Endwormhuskhead", client, product, paidPrice)
        end
    },	
	
   {
        Identifier = "spawnasEndwormhusk",
        Price = 80000,
        Limit = 1,
        IsLimitGlobal = true,
        PricePerLimit = 0,
        Timeout = 300,

        RoundPrice = {
            PriceReduction = 77000,
            StartTime = 50,
            EndTime = 60,
        },

        Action = function (client, product, items, paidPrice)
            SpawnCreature("Endwormhusk", client, product, paidPrice)
        end
    },	
   {
        Identifier = "spawnasCharybdishusk",
        Price = 65000,
        Limit = 1,
        IsLimitGlobal = true,
        PricePerLimit = 0,
        Timeout = 300,

        RoundPrice = {
            PriceReduction = 62500,
            StartTime = 50,
            EndTime = 60,
        },

        Action = function (client, product, items, paidPrice)
            SpawnCreature("Charybdishusk", client, product, paidPrice)
        end
    },	

   {
        Identifier = "spawnasWatcherhusk",
        Price = 7500,
        Limit = 1,
        IsLimitGlobal = true,
        PricePerLimit = 0,
        Timeout = 300,

        RoundPrice = {
            PriceReduction = 4500,
            StartTime = 25,
            EndTime = 45,
        },

        Action = function (client, product, items, paidPrice)
            SpawnCreature("Charybdishusk", client, product, paidPrice)
        end
    },
	
    {
        Identifier = "spawnashuskedhuman",
        Price = 2000,
        Limit = 3,
        IsLimitGlobal = true,
        PricePerLimit = 400,
        Timeout = 300,

        RoundPrice = {
            PriceReduction = 1250,
            StartTime = 25,
            EndTime = 45,
        },

        Action = function (client, product, items, paidPrice)
            SpawnCreature("Humanhusk", client, product, paidPrice)
        end
    },	
	
}

return category