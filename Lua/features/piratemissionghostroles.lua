local timer = Timer.GetTime()
local pirateMissionDebugTimer = 0

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

local function IsPirateMissionCharacter(character, clientCharacters, pirateEnemySubmarineInfo)
    if character == nil or not character.IsHuman or character.IsDead then
        return false
    end

    if clientCharacters[character] or Traitormod.GhostRoles.IsGhostRole(character) then
        return false
    end

    local submarine = character.Submarine
    if submarine == nil or submarine == Submarine.MainSub or IsOutpostSubmarine(submarine) then
        return false
    end

    local submarineInfo = submarine.Info
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
    local roleConfig = Traitormod.GhostRoles.GetConfig("pirates.mission.pirate")
    if roleConfig == nil or roleConfig.Enabled == false or not IsPirateMissionActive() then
        return
    end

    local clientCharacters = {}
    for _, client in pairs(Client.ClientList) do
        if client.Character ~= nil then
            clientCharacters[client.Character] = true
        end
    end

    local pirateEnemySubmarineInfo = GetPirateMissionEnemySubmarineInfo()
    local candidates = 0
    local created = 0

    for _, character in pairs(Character.CharacterList) do
        if IsPirateMissionCharacter(character, clientCharacters, pirateEnemySubmarineInfo) then
            candidates = candidates + 1

            local roleCreated = Traitormod.GhostRoles.Create("pirates.mission.pirate", character, {
                Name = character.Name,
                OnAssigned = function ()
                    Traitormod.SendMessageCharacter(character, Traitormod.Language.PirateCrewYou, "InfoFrameTabButton.Mission")
                end
            })

            if roleCreated then
                created = created + 1
            end
        end
    end

    DebugPirateMissionGhostRoleScan(candidates, created)
end

Hook.Add("think", "Traitormod.PirateMissionGhostRoles.Think", function ()
    if timer > Timer.GetTime() then return end
    if not Game.RoundStarted then return end

    timer = Timer.GetTime() + 5
    TryCreatePirateMissionGhostRoles()
end)

Hook.Add("roundEnd", "Traitormod.PirateMissionGhostRoles.RoundEnd", function ()
    pirateMissionDebugTimer = 0
end)
