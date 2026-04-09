local timer = Timer.GetTime()

local huskBeacons = {}
local monsterBeacons = {}
local ghostRoleNumber = 1
local monsterBeaconConfig = Traitormod.Config.MonsterBeaconConfig or {}
local pirateMissionDebugTimer = 0

local function IsCharacterSpeciesAvailable(species)
    local success, prefab = pcall(function()
        return CharacterPrefab.FindBySpeciesName(Identifier(species))
    end)

    return success and prefab ~= nil
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

    Traitormod.GhostRoles.Ask(character.Name .. " " .. ghostRoleNumber, function (client)
        client.SetClientCharacter(character)
    end, character)
    ghostRoleNumber = ghostRoleNumber + 1
end

local function IsPirateMissionActive()
    if Game.GameSession == nil or Game.GameSession.Missions == nil then
        return false
    end

    for _, mission in pairs(Game.GameSession.Missions) do
        if mission ~= nil and mission.Prefab ~= nil then
            local missionType = string.lower(tostring(mission.Prefab.Type or ""))
            local missionIdentifier = string.lower(tostring(mission.Prefab.Identifier or ""))
            if missionType == "pirate" or string.find(missionIdentifier, "pirate", 1, true) ~= nil then
                return true
            end
        end
    end

    return false
end

local function IsOutpostSubmarine(submarine)
    if submarine == nil or Level == nil or Level.Loaded == nil then
        return false
    end

    return submarine == Level.Loaded.StartOutpost or submarine == Level.Loaded.EndOutpost
end

local function GetLowerSafe(value)
    local ok, text = pcall(function()
        if type(value) == "function" then
            return tostring(value() or "")
        end

        return tostring(value or "")
    end)

    if not ok then
        return ""
    end

    return string.lower(text)
end

local function GetPirateMissionEnemySubmarineInfo()
    if Game.GameSession == nil or Game.GameSession.Missions == nil then
        return nil
    end

    for _, mission in pairs(Game.GameSession.Missions) do
        if mission ~= nil and mission.Prefab ~= nil then
            local missionType = string.lower(tostring(mission.Prefab.Type or ""))
            local missionIdentifier = string.lower(tostring(mission.Prefab.Identifier or ""))
            if missionType == "pirate" or string.find(missionIdentifier, "pirate", 1, true) ~= nil then
                local enemySubmarineInfo = nil
                local okMissionInfo = pcall(function()
                    enemySubmarineInfo = mission.EnemySubmarineInfo
                end)

                if okMissionInfo and enemySubmarineInfo ~= nil then
                    return enemySubmarineInfo
                end
            end
        end
    end

    local enemySubmarineInfo = nil
    local okSessionInfo = pcall(function()
        enemySubmarineInfo = Game.GameSession.EnemySubmarineInfo
    end)

    if okSessionInfo then
        return enemySubmarineInfo
    end

    return nil
end

local function IsEnemySubmarineInfo(submarineInfo)
    if submarineInfo == nil then
        return false
    end

    local okEnemySubmarine, isEnemySubmarine = pcall(function()
        return submarineInfo.IsEnemySubmarine
    end)

    if okEnemySubmarine and isEnemySubmarine ~= nil then
        return isEnemySubmarine == true
    end

    local lowerType = GetLowerSafe(function()
        return submarineInfo.Type
    end)

    return lowerType == "enemysubmarine"
end

local function AreSubmarineInfosEquivalent(leftInfo, rightInfo)
    if leftInfo == nil or rightInfo == nil then
        return false
    end

    if leftInfo == rightInfo then
        return true
    end

    local leftPath = GetLowerSafe(function()
        return leftInfo.FilePath
    end)
    local rightPath = GetLowerSafe(function()
        return rightInfo.FilePath
    end)
    if leftPath ~= "" and leftPath == rightPath then
        return true
    end

    local leftName = GetLowerSafe(function()
        return leftInfo.Name
    end)
    local rightName = GetLowerSafe(function()
        return rightInfo.Name
    end)

    return leftName ~= "" and leftName == rightName
end

local function IsPirateMissionCharacter(character)
    if character == nil or not character.IsHuman or character.IsDead then
        return false
    end

    if Traitormod.FindClientCharacter(character) ~= nil or Traitormod.GhostRoles.IsGhostRole(character) then
        return false
    end

    local submarine = character.Submarine
    if submarine == nil or submarine == Submarine.MainSub or IsOutpostSubmarine(submarine) then
        return false
    end

    local submarineInfo = submarine.Info
    local pirateEnemySubmarineInfo = GetPirateMissionEnemySubmarineInfo()
    if not IsEnemySubmarineInfo(submarineInfo) or not AreSubmarineInfosEquivalent(submarineInfo, pirateEnemySubmarineInfo) then
        return false
    end

    local teamId = character.TeamID
    if teamId == CharacterTeamType.Team1 or teamId == CharacterTeamType.FriendlyNPC then
        return false
    end

    return true
end

local function DebugPirateMissionGhostRoleScan(totalCharacters, createdRoles)
    if not Traitormod.Config.DebugLogs then
        return
    end

    if pirateMissionDebugTimer > Timer.GetTime() then
        return
    end

    pirateMissionDebugTimer = Timer.GetTime() + 30
    Traitormod.Debug(string.format(
        "Pirate mission ghost role scan: %s candidate(s), %s new role(s) created.",
        tonumber(totalCharacters) or 0,
        tonumber(createdRoles) or 0
    ))
end

local function TryCreatePirateMissionGhostRoles()
    local ghostRoleConfig = Traitormod.Config.GhostRoleConfig or {}
    if not ghostRoleConfig.Enabled or ghostRoleConfig.PirateMissionGhostRoles == false then
        return
    end

    if not IsPirateMissionActive() then
        return
    end

    local candidates = 0
    local created = 0

    for _, character in pairs(Character.CharacterList) do
        if IsPirateMissionCharacter(character) then
            candidates = candidates + 1
            local roleName = "pirate crew " .. ghostRoleNumber
            local displayName = character.Name

            local roleCreated = Traitormod.GhostRoles.Ask(roleName, function (ghostClient)
                Traitormod.LostLivesThisRound[ghostClient.SteamID] = false
                ghostClient.SetClientCharacter(character)
                Traitormod.SendMessageCharacter(character, Traitormod.Language.PirateCrewYou, "InfoFrameTabButton.Mission")
            end, character, {
                DisplayName = displayName,
            })

            if roleCreated then
                created = created + 1
                ghostRoleNumber = ghostRoleNumber + 1
            end
        end
    end

    DebugPirateMissionGhostRoleScan(candidates, created)
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

Traitormod.AddHuskBeacon = function (item, time)
    huskBeacons[item] = time
end

Traitormod.AddMonsterBeacon = function (item, sourceCharacter)
    if monsterBeaconConfig.Enabled == false then return end

    monsterBeacons[item] = {
        TimeLeft = monsterBeaconConfig.ActivationTime or 30,
        SourceCharacter = sourceCharacter
    }
end


local peopleInOutpost = 0
Hook.Add("think", "Traitormod.MiscThink", function ()
    if timer > Timer.GetTime() then return end
    if not Game.RoundStarted then return end

    for item, timeLeft in pairs(huskBeacons) do
        if item == nil or item.Removed then
            huskBeacons[item] = nil
        else
            if GetBeaconInterfaceState(item) then
                huskBeacons[item] = timeLeft - 5
            end

            if huskBeacons[item] ~= nil and huskBeacons[item] <= 0 then
                for i = 1, 4, 1 do
                    Entity.Spawner.AddCharacterToSpawnQueue("husk", item.WorldPosition)
                end

                Entity.Spawner.AddEntityToRemoveQueue(item)
                huskBeacons[item] = nil
            end
        end
    end

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

    if Traitormod.Config.GhostRoleConfig.Enabled then
        for key, character in pairs(Character.CharacterList) do
            local client = Traitormod.FindClientCharacter(character)
            if not Traitormod.GhostRoles.IsGhostRole(character) and not client then
                if Traitormod.Config.GhostRoleConfig.MiscGhostRoles[character.SpeciesName.Value] then
                    Traitormod.GhostRoles.Ask(character.Name .. " " .. ghostRoleNumber, function (client)
                        client.SetClientCharacter(character)
                    end, character)
                    ghostRoleNumber = ghostRoleNumber + 1
                end
            end
        end
    end

    TryCreatePirateMissionGhostRoles()

    if not Traitormod.RoundEvents.EventExists("OutpostPirateAttack") then return end
    if Traitormod.RoundEvents.IsEventActive("OutpostPirateAttack") then return end
    if Traitormod.SelectedGamemode == nil or Traitormod.SelectedGamemode.Name ~= "Secret" then return end
    if not Level.Loaded.EndOutpost then return end

    local targets = {}
    local outpost = Level.Loaded.EndOutpost.WorldPosition

    for key, character in pairs(Character.CharacterList) do
        if character.IsRemotePlayer and character.IsHuman and not character.IsDead and Vector2.Distance(character.WorldPosition, outpost) < 5000 then
            table.insert(targets, character)
        end
    end

    if #targets > 0 then
        peopleInOutpost = peopleInOutpost + 1
    end

    if peopleInOutpost > 30 then
        Traitormod.RoundEvents.TriggerEvent("OutpostPirateAttack")
    end
end)

Hook.Add("roundEnd", "Traitormod.MiscEnd", function ()
    peopleInOutpost = 0
    ghostRoleNumber = 1
    pirateMissionDebugTimer = 0
    huskBeacons = {}
    monsterBeacons = {}
end)

if Traitormod.Config.DeathLogBook then
    local messages = {}

    Hook.Add("roundEnd", "Traitormod.DeathLogBook", function ()
        messages = {}
    end)

    Hook.Add("character.death", "Traitormod.DeathLogBook", function (character)
        if messages[character] == nil then return end

        Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab("logbook"), character.Inventory, nil, nil, function(item)
            local terminal = item.GetComponentString("Terminal")

            local text = ""
            for key, value in pairs(messages[character]) do
                text = text .. value .. "\n"
            end

            terminal.TextColor = Color.MidnightBlue
            terminal.ShowMessage = text
            terminal.SyncHistory()
        end)
    end)

    Traitormod.AddCommand("!write", function (client, args)
        if client.Character == nil or client.Character.IsDead or client.Character.SpeechImpediment > 0 or not client.Character.IsHuman then
            Traitormod.SendChatMessage(client, "You are unable to write to your death logbook.", Color.Red)
            return true
        end

        if messages[client.Character] == nil then
            messages[client.Character] = {}
        end

        if #messages[client.Character] > 255 then return end

        local message = table.concat(args, " ")
        table.insert(messages[client.Character], message)

        Traitormod.SendChatMessage(client, "Wrote \"" .. message .. "\" to the death logbook.", Color.Green)

        return true
    end)
end
