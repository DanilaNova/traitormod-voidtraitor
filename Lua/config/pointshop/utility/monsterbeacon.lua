local monsterBeacon = {}

local monsterBeacons = {}
local monsterBeaconConfig = {}
local timer = 0

local function IsCharacterSpeciesAvailable(species)
    return CharacterPrefab.FindBySpeciesName(Identifier(species)) ~= nil
end

local function IsMonsterBeaconPoolValid(pool)
    if pool == nil or pool.Creatures == nil or #pool.Creatures == 0 then return false end

    for _, species in ipairs(pool.Creatures) do
        if not IsCharacterSpeciesAvailable(species) then
            return false
        end
    end

    return true
end

local function GetAvailableMonsterBeaconPools()
    local pools = {}

    for _, pool in ipairs(monsterBeaconConfig.Pools or {}) do
        if IsMonsterBeaconPoolValid(pool) then
            table.insert(pools, pool)
        end
    end

    if monsterBeaconConfig.UseOptionalHuskPools then
        for _, pool in ipairs(monsterBeaconConfig.OptionalHuskPools or {}) do
            if IsMonsterBeaconPoolValid(pool) then
                table.insert(pools, pool)
            end
        end
    end

    return pools
end

local function GetBeaconInterfaceState(item)
    local interface = item.GetComponentString("CustomInterface")
    return interface ~= nil and interface.customInterfaceElementList[1].State
end

local function GetBeaconTargetSubmarine(item, sourceCharacter)
    if item ~= nil and item.Submarine ~= nil then
        return item.Submarine
    end

    if sourceCharacter ~= nil and sourceCharacter.Submarine ~= nil then
        return sourceCharacter.Submarine
    end

    if Submarine.MainSub ~= nil then
        return Submarine.MainSub
    end

    local closestSubmarine = nil
    local closestDistance = math.huge

    for _, submarine in pairs(Submarine.Loaded) do
        local distance = Vector2.Distance(submarine.WorldPosition, item.WorldPosition)
        if distance < closestDistance then
            closestSubmarine = submarine
            closestDistance = distance
        end
    end

    return closestSubmarine
end

local function GetSubmarineDirection(submarine)
    local success, direction = pcall(function()
        return submarine.SubBody.Dir
    end)

    if success and direction ~= nil and direction < 0 then
        return -1
    end

    return 1
end

local function ShuffleArray(values)
    for i = #values, 2, -1 do
        local j = math.random(i)
        values[i], values[j] = values[j], values[i]
    end
end

local function GetFallbackMonsterSpawnPositions(submarine)
    local center = submarine.WorldPosition
    local halfWidth = math.max(submarine.Borders.Width / 2, 500)
    local halfHeight = math.max(submarine.Borders.Height / 2, 300)
    local direction = GetSubmarineDirection(submarine)
    local rearX = halfWidth + 350
    local sideY = halfHeight + 250

    return {
        center + Vector2(-direction * rearX, -sideY),
        center + Vector2(-direction * rearX, 0),
        center + Vector2(-direction * rearX, sideY),
        center + Vector2(0, -sideY),
        center + Vector2(0, sideY),
        center + Vector2(direction * (halfWidth + 200), -sideY),
        center + Vector2(direction * (halfWidth + 200), sideY),
    }
end

local function GetMonsterSpawnPositions(submarine, amount)
    local rearCandidates = {}
    local sideCandidates = {}
    local direction = GetSubmarineDirection(submarine)
    local maxXDistance = submarine.Borders.Width * 1.35
    local maxYDistance = submarine.Borders.Height * 1.65

    for _, waypoint in pairs(submarine.GetWaypoints(true)) do
        if waypoint.CurrentHull == nil then
            local relative = waypoint.WorldPosition - submarine.WorldPosition
            if math.abs(relative.X) <= maxXDistance and math.abs(relative.Y) <= maxYDistance then
                local walls = Level.Loaded.GetTooCloseCells(waypoint.WorldPosition, monsterBeaconConfig.SpawnWallDistance or 250)
                if #walls == 0 then
                    if relative.X * direction <= 0 then
                        table.insert(rearCandidates, waypoint.WorldPosition)
                    else
                        table.insert(sideCandidates, waypoint.WorldPosition)
                    end
                end
            end
        end
    end

    ShuffleArray(rearCandidates)
    ShuffleArray(sideCandidates)

    local orderedCandidates = {}
    for _, position in ipairs(rearCandidates) do
        table.insert(orderedCandidates, position)
    end
    for _, position in ipairs(sideCandidates) do
        table.insert(orderedCandidates, position)
    end

    if #orderedCandidates == 0 then
        orderedCandidates = GetFallbackMonsterSpawnPositions(submarine)
        ShuffleArray(orderedCandidates)
    end

    local positions = {}
    local jitter = monsterBeaconConfig.SpawnJitter or 150

    for index = 1, amount do
        local basePosition = orderedCandidates[((index - 1) % #orderedCandidates) + 1]
        positions[index] = basePosition + Vector2(math.random(-jitter, jitter), math.random(-jitter, jitter))
    end

    return positions
end

local function TryCreateMonsterGhostRole(characters)
    if not Traitormod.Config.GhostRoleConfig.Enabled then return end
    if #characters == 0 then return end

    local chance = monsterBeaconConfig.GhostRoleChance or 0
    if chance <= 0 or math.random() > chance then return end

    local character = characters[math.random(#characters)]
    if character == nil or character.Removed or character.IsDead then return end

    local roleConfig = Traitormod.GhostRoles.GetConfigBySpecies("monsterbeacon", character.SpeciesName.Value)
    if roleConfig ~= nil then
        Traitormod.GhostRoles.Create(roleConfig.FullIdentifier, character)
    else
        Traitormod.GhostRoles.Create("monsterbeacon.default", character, { Name = character.Name })
    end
end

local function TriggerMonsterBeacon(item, sourceCharacter)
    local submarine = GetBeaconTargetSubmarine(item, sourceCharacter)
    if submarine == nil then
        Traitormod.Error("Monster beacon failed: no valid submarine found.")
        return
    end

    local pools = GetAvailableMonsterBeaconPools()
    if #pools == 0 then
        Traitormod.Error("Monster beacon failed: no valid monster pools available.")
        return
    end

    local selectedPool = pools[math.random(#pools)]
    local spawnPositions = GetMonsterSpawnPositions(submarine, #selectedPool.Creatures)
    local spawnedCharacters = {}

    for index, species in ipairs(selectedPool.Creatures) do
        Entity.Spawner.AddCharacterToSpawnQueue(species, spawnPositions[index], function (character)
            table.insert(spawnedCharacters, character)

            if #spawnedCharacters >= #selectedPool.Creatures then
                TryCreateMonsterGhostRole(spawnedCharacters)
            end
        end)
    end
end

function monsterBeacon.Init()
    monsterBeaconConfig = Traitormod.Config.MonsterBeaconConfig or {}
    timer = Timer.GetTime()

    Hook.Add("think", "Traitormod.MonsterBeacon.Think", function ()
        if timer > Timer.GetTime() then return end
        if not Game.RoundStarted then return end

        for item, data in pairs(monsterBeacons) do
            if item == nil or item.Removed then
                monsterBeacons[item] = nil
            else
                if GetBeaconInterfaceState(item) then
                    data.TimeLeft = data.TimeLeft - 5
                end

                if data.TimeLeft <= 0 then
                    TriggerMonsterBeacon(item, data.SourceCharacter)
                    Entity.Spawner.AddEntityToRemoveQueue(item)
                    monsterBeacons[item] = nil
                end
            end
        end

        timer = Timer.GetTime() + 5
    end)

    Hook.Add("roundEnd", "Traitormod.MonsterBeacon.RoundEnd", function ()
        monsterBeacons = {}
    end)
end

function monsterBeacon.Add(item, sourceCharacter)
    if monsterBeaconConfig.Enabled == false then return end

    monsterBeacons[item] = {
        TimeLeft = monsterBeaconConfig.ActivationTime or 30,
        SourceCharacter = sourceCharacter
    }
end

return monsterBeacon
