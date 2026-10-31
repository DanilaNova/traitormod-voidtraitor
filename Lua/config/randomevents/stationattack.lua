local event = { Name = "StationAttack", ChancePerMinute = 1, OnlyOncePerRound = false }
local eventSets = LuaUserData.CreateStatic("Barotrauma.EventSet", true)
local eventManager = LuaUserData.CreateStatic("Barotrauma.EventManager", true)
local positionTypes = LuaUserData.CreateEnumTable("Barotrauma.Level+PositionType")
local outdoorMask = positionTypes.MainPath.flagsOr(positionTypes.MainPath, positionTypes.SidePath)
LuaUserData.RegisterType("Barotrauma.EventSet+SubEventPrefab")
LuaUserData.RegisterType("Barotrauma.MonsterEvent")

event.Init = function()
    Hook.Patch("Traitormod.Station.OutdoorWaves", "Barotrauma.MonsterEvent", "InitEventSpecific",
        { "Barotrauma.EventSet" }, function(monsterEvent, parameters)
            local mode = Traitormod.SelectedGamemode
            if mode == nil or mode.Name ~= "Station" or not mode.SuppressOutdoorWaves then return end
            if parameters["parentSet"] ~= nil and monsterEvent.SpawnPosType.hasAny(monsterEvent.SpawnPosType, outdoorMask) then
                monsterEvent.Finish()
                parameters.PreventExecution = true
            end
        end, Hook.HookMethodType.Before)
end

local function chooseWeighted(entries)
    local total = 0
    for _, entry in ipairs(entries) do total = total + entry.Weight end
    if total <= 0 then return nil end
    local roll = math.random() * total
    for index, entry in ipairs(entries) do
        roll = roll - entry.Weight
        if roll < 0 then return entry.Value, index end
    end
end

local function playerCount()
    local count = 0
    for _, client in pairs(Client.ClientList) do
        local character = client.Character
        if character ~= nil and not character.Removed and not character.IsDead
            and character.IsHuman and character.TeamID == CharacterTeamType.Team1 then
            count = count + 1
        end
    end
    return count
end

local function amountMultiplier(mode, players)
    if players < mode.WaveMinPlayers then
        return mode.WaveMinAmountMultiplier * players / mode.WaveMinPlayers
    end
    local fraction = math.min((players - mode.WaveMinPlayers)
        / (mode.WaveMaxPlayers - mode.WaveMinPlayers), 1)
    return mode.WaveMinAmountMultiplier
        + (mode.WaveMaxAmountMultiplier - mode.WaveMinAmountMultiplier) * fraction
end

local function intervalMinutes(mode, players)
    for _, interval in ipairs(mode.WaveIntervals) do
        if players <= interval.Players then
            return interval.Min + math.random() * (interval.Max - interval.Min)
        end
    end
    local interval = mode.WaveIntervals[#mode.WaveIntervals]
    return interval.Min + math.random() * (interval.Max - interval.Min)
end

local function difficulty(mode, players)
    if event.AttackNumber == 0 then
        local band = mode.WaveDifficultyBands[1]
        return band.Min + math.random() * (math.min(band.Max, mode.WaveMaxDifficulty) - band.Min)
    end
    local minutes = Traitormod.RoundTime / 60
    local curve = mode.WaveDifficultyCurve
    local weights = {}
    local first, last = curve[1], curve[#curve]
    for index = 2, #curve do
        if minutes < curve[index].Minutes then
            first, last = curve[index - 1], curve[index]
            break
        end
    end
    local fraction = 0
    if first ~= last then
        fraction = math.max(0, math.min((minutes - first.Minutes) / (last.Minutes - first.Minutes), 1))
    end
    local maximumBand = #mode.WaveDifficultyBands
    for _, limit in ipairs(mode.WavePopulationLimits) do
        if players / mode.WaveMinPlayers <= limit.Fraction then
            maximumBand = limit.Band
            break
        end
    end
    while maximumBand > 1 and mode.WaveDifficultyBands[maximumBand].Min > mode.WaveMaxDifficulty do
        maximumBand = maximumBand - 1
    end
    for index, weight in ipairs(first.Weights) do
        local band = math.min(index, maximumBand)
        weights[band] = weights[band] or { Value = band, Weight = 0 }
        weights[band].Weight = weights[band].Weight + weight
            + (last.Weights[index] - weight) * fraction
    end
    local band = mode.WaveDifficultyBands[chooseWeighted(weights)]
    return band.Min + math.random() * (math.min(band.Max, mode.WaveMaxDifficulty) - band.Min)
end

local function outdoorTree(set)
    local tree = { Set = set, Groups = {}, Children = {} }
    for _, group in ipairs(set.EventPrefabs) do
        local candidates = {}
        for prefab in group.EventPrefabs do
            if prefab.ConfigElement.Name.LocalName == "MonsterEvent" and eventManager.IsSuitable(prefab, Level.Loaded) then
                local monster = prefab.CreateInstance(Game.GameSession.EventManager.RandomSeed)
                if monster ~= nil and monster.SpawnPosType.hasAny(monster.SpawnPosType, outdoorMask) then
                    local enabled = Game.ServerSettings.MonsterEnabled
                    if enabled[monster.SpeciesName] ~= false then
                        candidates[#candidates + 1] = { Value = monster, Weight = prefab.Commonness }
                    end
                end
            end
        end
        if #candidates > 0 then
            tree.Groups[#tree.Groups + 1] = {
                Value = { Candidates = candidates, Probability = group.Probability }, Weight = group.Commonness,
            }
        end
    end
    for _, child in ipairs(set.ChildSets) do
        local subtree = outdoorTree(child)
        if subtree ~= nil then
            tree.Children[#tree.Children + 1] = { Value = subtree, Weight = child.GetCommonness(Level.Loaded) }
        end
    end
    if #tree.Groups == 0 and #tree.Children == 0 then return nil end
    return tree
end

local function selectEncounter(tree, result)
    local groups = tree.Groups
    if tree.Set.ChooseRandom then
        for _ = 1, tree.Set.GetEventCount(Level.Loaded) do
            local group, index = chooseWeighted(groups)
            if group == nil then break end
            if math.random() <= group.Probability then
                result[#result + 1] = chooseWeighted(group.Candidates)
                table.remove(groups, index)
            end
        end
        for _ = 1, tree.Set.SubSetCount do
            local child, index = chooseWeighted(tree.Children)
            if child == nil then break end
            selectEncounter(child, result)
            table.remove(tree.Children, index)
        end
    else
        for _, entry in ipairs(groups) do
            if math.random() <= entry.Value.Probability then
                result[#result + 1] = chooseWeighted(entry.Value.Candidates)
            end
        end
        for _, entry in ipairs(tree.Children) do selectEncounter(entry.Value, result) end
    end
end

local function selectPool(mode, difficulty)
    local families = {}
    for _, family in ipairs(mode.WavePools) do
        local roots = {}
        for set in eventSets.Prefabs do
            for _, identifier in ipairs(family.Sets) do
                if set.Identifier == Identifier(identifier)
                    and difficulty >= set.MinLevelDifficulty and difficulty <= set.MaxLevelDifficulty then
                    local tree = outdoorTree(set)
                    if tree ~= nil then roots[#roots + 1] = { Value = tree, Weight = set.GetCommonness(Level.Loaded) } end
                end
            end
        end
        if #roots > 0 then families[#families + 1] = { Value = roots, Weight = family.Weight } end
    end
    local family = chooseWeighted(families)
    if family == nil then return {} end
    local tree = chooseWeighted(family)
    local encounter = chooseWeighted(tree.Children)
    local result = {}
    if encounter ~= nil then selectEncounter(encounter, result) end
    return result
end

local function scaleEncounter(encounter, multiplier)
    local original, result = {}, {}
    for _, monster in ipairs(encounter) do
        for _ = 1, math.random(monster.MinAmount, monster.MaxAmount) do
            original[#original + 1] = monster
            for _ = 1, math.floor(multiplier) do
                result[#result + 1] = monster
            end
        end
    end
    local remaining = math.floor(#original * (multiplier % 1) + math.random())
    for _ = 1, remaining do
        local index = math.random(#original)
        local monster = table.remove(original, index)
        result[#result + 1] = monster
    end
    local capped, counts, included = {}, {}, {}
    for _, monster in ipairs(result) do
        local species = monster.SpeciesName.Value
        if counts[species] == nil then
            counts[species] = 0
            for character in Character.CharacterList do
                if character.SpeciesName == monster.SpeciesName then counts[species] = counts[species] + 1 end
            end
        end
        if counts[species] < monster.MaxAmountPerLevel then
            capped[#capped + 1] = monster
            counts[species] = counts[species] + 1
            included[monster] = true
        end
    end
    for _, monster in ipairs(encounter) do
        if monster.MinAmount > 0 and not included[monster] then return {} end
    end
    return capped
end

local function spawnPositions(mode)
    local station = Submarine.MainSub
    local borders = station.Borders
    local origin = station.WorldPosition
    local positions = {}
    for waypoint in WayPoint.WayPointList do
        if waypoint.Submarine == nil and waypoint.CurrentHull == nil and waypoint.Ruin == nil then
            local position = waypoint.WorldPosition
            local dx = math.max(origin.X + borders.X - position.X, 0, position.X - origin.X - borders.Right)
            local dy = math.max(origin.Y + borders.Y - borders.Height - position.Y, 0, position.Y - origin.Y - borders.Y)
            local distance = math.sqrt(dx * dx + dy * dy)
            if distance >= mode.WaveSpawnMinDistance * 100 and distance <= mode.WaveSpawnMaxDistance * 100
                and #Level.Loaded.GetTooCloseCells(position, mode.WaveWallClearance * 100) == 0 then
                local inside = false
                for submarine in Submarine.Loaded do
                    local box, offset = submarine.Borders, submarine.WorldPosition
                    if position.X >= offset.X + box.X and position.X <= offset.X + box.Right
                        and position.Y <= offset.Y + box.Y and position.Y >= offset.Y + box.Y - box.Height then
                        inside = true
                        break
                    end
                end
                if not inside then positions[#positions + 1] = position end
            end
        end
    end
    return positions
end

local function initializeRound(mode)
    event.AttackNumber = 0
    event.Monsters = nil
    event.NextAttackTime = Traitormod.RoundTime + 60 * (mode.WaveInitialDelayMinMinutes
        + math.random() * (mode.WaveInitialDelayMaxMinutes - mode.WaveInitialDelayMinMinutes))
end

local function canStart(mode)
    return mode.WavesEnabled and not mode.Ending and event.NextAttackTime ~= nil
        and Traitormod.RoundTime >= event.NextAttackTime and playerCount() > 0
end

local function start(mode)
    local players = playerCount()
    local difficulty = difficulty(mode, players)
    local monsters = scaleEncounter(selectPool(mode, difficulty), amountMultiplier(mode, players))
    local positions = spawnPositions(mode)
    local spawned = {}
    event.NextAttackTime = Traitormod.RoundTime + intervalMinutes(mode, players) * 60
    if #positions > 0 then
        for _, monster in ipairs(monsters) do
            local position = positions[math.random(#positions)]
            local character = Character.Create(monster.SpeciesName, position,
                tostring(math.random()), nil, 0, false, true, true)
            if character ~= nil then
                spawned[#spawned + 1] = character
            end
        end
    end
    if #spawned == 0 then
        event.End()
        return
    end
    event.Monsters = spawned
    event.AttackNumber = event.AttackNumber + 1
    mode:SendAlertMessage(Traitormod.GetText("StationAttackWarning"), Color(255, 215, 0, 255), Color(255, 255, 170, 255))
    mode:PlayAlertSound("attack")
    Traitormod.Log(string.format("Station attack %d: %d players, %.1f difficulty, %d creatures",
        event.AttackNumber, players, difficulty, #spawned))
end

local function think(mode)
    if event.Monsters == nil then return end
    for _, character in ipairs(event.Monsters) do
        if not character.Removed and not character.IsDead
            and Vector2.Distance(character.WorldPosition, Submarine.MainSub.WorldPosition)
                <= mode.WaveActiveDistance * 100 then return end
    end
    event.End()
end


event.RoundStart = function()
    local mode = Traitormod.SelectedGamemode
    if mode ~= nil and mode.Name == "Station" then initializeRound(mode) end
end

event.CanStart = function()
    local mode = Traitormod.SelectedGamemode
    return mode ~= nil and mode.Name == "Station" and canStart(mode)
end

event.Start = function()
    start(Traitormod.SelectedGamemode)
end

event.Think = function()
    think(Traitormod.SelectedGamemode)
end

event.End = function(isRoundEnd)
    event.Monsters = nil
    if isRoundEnd then event.NextAttackTime, event.AttackNumber = nil, nil end
end

return event
