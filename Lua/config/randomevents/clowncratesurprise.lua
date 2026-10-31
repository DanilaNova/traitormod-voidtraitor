local randomizer = dofile(Traitormod.Path .. "/Lua/config/pointshop/utility/randomizer.lua")
local event = {}

event.Name = "ClownCrateSurprise"
event.MinRoundTime = 10
event.MinIntensity = 0
event.MaxIntensity = 1
event.ChancePerMinute = 0.005
event.OnlyOncePerRound = true

local monsterPool = { "crawler_hatchling", "tigerthresher_hatchling", "mudraptor_hatchling" }
local huskPool = {"Crawler_hatchlinghusk", "Tigerthresher_hatchlinghusk", "Mudraptor_hatchlinghusk"}
local petPool = { "orangeboy", "balloon", "psilotoad" }
local clownPetPool = {
    orangeboy = "Clown_Orangeboy",
    balloon = "Clown_Peanut",
    psilotoad = "Clown_Psilotoad",
}
local namedNpcIds = nil

local function isSpeciesAvailable(species)
    return CharacterPrefab.FindBySpeciesName(Identifier(species)) ~= nil
end

local function getSpawnPosition()
    if Submarine.MainSub == nil then
        return nil
    end

    local positions = {}
    for _, waypoint in pairs(Submarine.MainSub.GetWaypoints(true)) do
        if waypoint.CurrentHull ~= nil then
            table.insert(positions, waypoint.WorldPosition)
        end
    end

    if #positions == 0 then
        return Submarine.MainSub.WorldPosition
    end

    return positions[math.random(#positions)]
end

local function assignGhostRole(character, identifier, name)
    if character == nil or character.Removed or character.IsDead then
        return
    end

    if identifier == nil then
        local roleConfig = Traitormod.GhostRoles.GetConfigBySpecies("clowncrate", character.SpeciesName.Value)
        if roleConfig == nil then return end
        identifier = roleConfig.FullIdentifier
    end

    Traitormod.GhostRoles.Create(identifier, character, { Name = name })
end

local function spawnCreature(species, position, guaranteedGhostRole, randomGhostChance)
    Entity.Spawner.AddCharacterToSpawnQueue(species, position, function(character)
        if character == nil then
            return
        end

        if guaranteedGhostRole or (randomGhostChance ~= nil and math.random() <= randomGhostChance) then
            assignGhostRole(character)
        end
    end)
end

local function loadNamedNpcIds()
    if namedNpcIds ~= nil then
        return namedNpcIds
    end

    namedNpcIds = {}

    local ok = pcall(function()
        local xml = XDocument.Parse(File.Read("Content/NPCPrefabs/SpecialNpcs.xml"))
        for npcSet in xml.Root.Elements() do
            local identifier = npcSet.Attribute("identifier")
            if identifier ~= nil and identifier.Value == "customnpcs1" then
                for npc in npcSet.Elements() do
                    local npcIdentifier = npc.Attribute("identifier")
                    if npcIdentifier ~= nil then
                        table.insert(namedNpcIds, npcIdentifier.Value)
                    end
                end
            end
        end
    end)

    if not ok then
        namedNpcIds = {}
    end

    return namedNpcIds
end

local function findNamedNpcPrefab(npcId)
    if npcId == nil then
        return nil
    end

    local targetId = Identifier(npcId)
    local ok, humanPrefab = pcall(function()
        for _, npcSet in pairs(NPCSet.Sets) do
            for _, candidate in pairs(npcSet.Humans) do
                if candidate.Identifier == targetId then
                    return candidate
                end
            end
        end
    end)

    if ok then
        return humanPrefab
    end

    return nil
end

local function spawnNamedNpc(position)
    local npcIds = loadNamedNpcIds()
    if #npcIds == 0 then
        return false
    end

    local npcId = npcIds[math.random(#npcIds)]
    local humanPrefab = findNamedNpcPrefab(npcId)
    if humanPrefab ~= nil then
        Entity.Spawner.AddCharacterToSpawnQueue("human", position, humanPrefab.CreateCharacterInfo(), function(character)
            character.HumanPrefab = humanPrefab
            character.TeamID = CharacterTeamType.FriendlyNPC
            humanPrefab.GiveItems(character, character.Submarine, nil)
            humanPrefab.InitializeCharacter(character)
            assignGhostRole(character, "clowncrate.npc", character.Name)
        end)
        return true
    end

    local info = CharacterInfo(Identifier("human"))
    info.Job = Job(JobPrefab.Get("assistant"), false)
    local character = Character.Create(info, position, info.Name, 0, false, true)
    character.TeamID = CharacterTeamType.FriendlyNPC
    character.GiveJobItems(false, nil)
    assignGhostRole(character, "clowncrate.npc", character.Name)
    return true
end

local function spawnLoot(crate)
    if crate == nil then
        return false
    end

    for _ = 1, 5 do
        local prefab = randomizer.GetRandom("CanBeBoughtOrSold")
        if prefab ~= nil then
            if crate.OwnInventory ~= nil then
                Entity.Spawner.AddItemToSpawnQueue(prefab, crate.OwnInventory)
            else
                Entity.Spawner.AddItemToSpawnQueue(prefab, crate.WorldPosition)
            end
        end
    end

    Traitormod.RoundEvents.SendEventMessage(Traitormod.Language.ClownCrateLoot, "GameModeIcon.PVP", Color(255, 140, 210, 255))
    return true
end

local function chooseMonsterSpecies()
    local index = math.random(#monsterPool)
    local species = monsterPool[index]

    if math.random() <= 0.10 then
        local huskSpecies = huskPool[index]
        if huskSpecies ~= nil and isSpeciesAvailable(huskSpecies) then
            species = huskSpecies
        end
    end

    return species
end

local function choosePetSpecies()
    local baseSpecies = petPool[math.random(#petPool)]

    if math.random() <= 0.10 then
        local clownSpecies = clownPetPool[baseSpecies]
        if clownSpecies ~= nil and isSpeciesAvailable(clownSpecies) then
            return clownSpecies, true
        end
    end

    return baseSpecies, false
end

local function removeCrate()
    if event.Crate ~= nil and not event.Crate.Removed then
        Entity.Spawner.AddEntityToRemoveQueue(event.Crate)
    end
end

local function openCrate(crate)
    if crate == nil or crate.Removed or event.Opened then
        return
    end

    event.Opened = true
    local position = crate.WorldPosition
    local roll = math.random()

    if roll <= 0.40 then
        removeCrate()
        spawnCreature(chooseMonsterSpecies(), position, false, 0.50)
        Traitormod.RoundEvents.SendEventMessage(Traitormod.Language.ClownCrateMonster, "GameModeIcon.PVP", Color(255, 140, 210, 255))
    elseif roll <= 0.65 then
        local species, guaranteedGhostRole = choosePetSpecies()
        removeCrate()
        spawnCreature(species, position, guaranteedGhostRole, 0)
        Traitormod.RoundEvents.SendEventMessage(Traitormod.Language.ClownCratePet, "GameModeIcon.PVP", Color(255, 140, 210, 255))
    elseif roll <= 0.75 then
        if spawnNamedNpc(position) then
            removeCrate()
            Traitormod.RoundEvents.SendEventMessage(Traitormod.Language.ClownCrateNpc, "GameModeIcon.PVP", Color(255, 140, 210, 255))
        else
            spawnLoot(crate)
        end
    else
        spawnLoot(crate)
    end

    event.End()
end

event.CanStart = function()
    return Submarine.MainSub ~= nil and getSpawnPosition() ~= nil
end

event.Start = function()
    local position = getSpawnPosition()
    if position == nil or Submarine.MainSub == nil then
        event.End()
        return
    end

    event.Crate = nil
    event.Opened = false

    local prefab = ItemPrefab.GetItemPrefab("clowncrate") or ItemPrefab.GetItemPrefab("metalcrate")
    if prefab == nil then
        event.End()
        return
    end

    Entity.Spawner.AddItemToSpawnQueue(prefab, position - Submarine.MainSub.Position, Submarine.MainSub, nil, nil, function(item)
        event.Crate = item
    end)

    Hook.Add("item.interact", "Traitormod.ClownCrateSurprise.Interact", function(item)
        if event.Crate ~= nil and item == event.Crate then
            openCrate(item)
        end
    end)

    Hook.Add("think", "Traitormod.ClownCrateSurprise.Think", function()
        if event.Opened then
            return
        end

        if event.Crate ~= nil and event.Crate.Removed then
            event.End()
        end
    end)

    Traitormod.RoundEvents.SendEventMessage(Traitormod.Language.ClownCrateWarning, "GameModeIcon.PVP", Color(255, 140, 210, 255))
end

event.End = function()
    Hook.Remove("item.interact", "Traitormod.ClownCrateSurprise.Interact")
    Hook.Remove("think", "Traitormod.ClownCrateSurprise.Think")
    event.Crate = nil
    event.Opened = false
end

return event
