local event = {}

event.Name = "VentCreatures"
event.MinRoundTime = 8
event.MinIntensity = 0
event.MaxIntensity = 1
event.ChancePerMinute = 0.006
event.OnlyOncePerRound = true

local monsterPool = { "crawler_hatchling", "tigerthresher_hatchling", "mudraptor_hatchling" }
local huskPool = {"Crawler_hatchlinghusk", "Tigerthresher_hatchlinghusk", "Mudraptor_hatchlinghusk"}
local petPool = { "orangeboy", "balloon", "psilotoad" }
local clownPetPool = {
    orangeboy = "Clown_Orangeboy",
    balloon = "Clown_Peanut",
    psilotoad = "Clown_Psilotoad",
}

local function isSpeciesAvailable(species)
    local ok, prefab = pcall(function()
        return CharacterPrefab.FindBySpeciesName(Identifier(species))
    end)

    return ok and prefab ~= nil
end

local function getVentItems()
    local vents = {}

    if Submarine.MainSub == nil then
        return vents
    end

    for _, item in pairs(Submarine.MainSub.GetItems(true)) do
        if item ~= nil and item.Prefab ~= nil and item.Prefab.Identifier ~= nil then
            local identifier = string.lower(item.Prefab.Identifier.Value)
            if item.HasTag("vent") or string.find(identifier, "vent", 1, true) ~= nil then
                table.insert(vents, item)
            end
        end
    end

    return vents
end

local function getAvailablePool(pool)
    local available = {}

    for _, species in ipairs(pool or {}) do
        if isSpeciesAvailable(species) then
            table.insert(available, species)
        end
    end

    return available
end

local function getAvailableMappedPool(map)
    local available = {}

    for _, species in pairs(map or {}) do
        if isSpeciesAvailable(species) then
            table.insert(available, species)
        end
    end

    return available
end

local function assignGhostRole(character, prefix)
    event.SpawnedRoles = (event.SpawnedRoles or 0) + 1

    Traitormod.GhostRoles.Ask(prefix .. " " .. tostring(event.SpawnedRoles), function(client)
        Traitormod.LostLivesThisRound[client.SteamID] = false
        client.SetClientCharacter(character)
    end, character)
end

local function spawnCreature(species, position, giveGhostRole)
    Entity.Spawner.AddCharacterToSpawnQueue(species, position, function(character)
        if giveGhostRole and character ~= nil then
            assignGhostRole(character, "Vent Creature")
        end
    end)
end

local function chooseMonsterSpecies(availableMonsters)
    return availableMonsters[math.random(#availableMonsters)], math.random() <= 0.50
end

local function chooseHuskSpecies(availableHusks)
    return availableHusks[math.random(#availableHusks)], math.random() <= 0.50
end

local function choosePetSpecies(availablePets)
    local baseSpecies = availablePets[math.random(#availablePets)]

    if math.random() <= 0.10 then
        local clownSpecies = clownPetPool[baseSpecies]
        if clownSpecies ~= nil and isSpeciesAvailable(clownSpecies) then
            return clownSpecies, true
        end
    end

    return baseSpecies, true
end

local function removeRandomVent(vents)
    if #vents == 0 then
        return nil
    end

    local index = math.random(#vents)
    local vent = vents[index]
    table.remove(vents, index)
    return vent
end

event.CanStart = function()
    local availableMonsters = getAvailablePool(monsterPool)
    local availableHusks = getAvailableMappedPool(huskPool)
    local availablePets = getAvailablePool(petPool)

    return #getVentItems() > 0 and (#availableMonsters > 0 or #availableHusks > 0 or #availablePets > 0)
end

event.Start = function()
    event.Token = (event.Token or 0) + 1
    local token = event.Token

    Traitormod.RoundEvents.SendEventMessage(Traitormod.Language.VentCreaturesWarning, "GameModeIcon.PVP", Color(255, 190, 70, 255))

    Timer.Wait(function()
        if event.Token ~= token then
            return
        end

        local allVents = getVentItems()
        if #allVents == 0 then
            event.End()
            return
        end

        local availableMonsters = getAvailablePool(monsterPool)
        local availableHusks = getAvailableMappedPool(huskPool)
        local availablePets = getAvailablePool(petPool)
        if #availableMonsters == 0 and #availableHusks == 0 and #availablePets == 0 then
            event.End()
            return
        end

        local selectedPool = nil
        local poolOptions = {
            { Name = "monsters", Available = #availableMonsters > 0 },
            { Name = "husks", Available = #availableHusks > 0 },
            { Name = "pets", Available = #availablePets > 0 },
        }
        local possiblePools = {}
        for _, poolInfo in ipairs(poolOptions) do
            if poolInfo.Available then
                table.insert(possiblePools, poolInfo.Name)
            end
        end
        selectedPool = possiblePools[math.random(#possiblePools)]

        local freeVents = {}
        for _, vent in ipairs(allVents) do
            table.insert(freeVents, vent)
        end

        local amount = math.random(1, 7)

        for i = 1, amount do
            local vent = removeRandomVent(freeVents)
            if vent == nil then
                vent = allVents[math.random(#allVents)]
            end

            local species, giveGhostRole
            if selectedPool == "monsters" then
                species, giveGhostRole = chooseMonsterSpecies(availableMonsters)
            elseif selectedPool == "husks" then
                species, giveGhostRole = chooseHuskSpecies(availableHusks)
            else
                species, giveGhostRole = choosePetSpecies(availablePets)
            end

            local offset = Vector2(math.random(-24, 24), math.random(-24, 24))
            spawnCreature(species, vent.WorldPosition + offset, giveGhostRole)
        end

        event.End()
    end, 15000)
end

event.End = function()
    event.Token = (event.Token or 0) + 1
end

return event
