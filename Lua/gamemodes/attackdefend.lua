local weightedRandom = dofile(Traitormod.Path .. "/Lua/weightedrandom.lua")
local gm = Traitormod.Gamemodes.Gamemode:new()

gm.Name = "AttackDefend"
gm.RequiredGamemode = "sandbox"

local function SpawnCharacter(client, team)
    if client.SpectateOnly or client.CharacterInfo == nil then return false end
    local submarine = Submarine.MainSub

    local spawnWayPoints = WayPoint.SelectCrewSpawnPoints({client.CharacterInfo}, submarine)

    local potentialPosition = submarine.WorldPosition

    if spawnWayPoints[1] == nil then
        for i, waypoint in pairs(WayPoint.WayPointList) do
            if waypoint.Submarine == submarine and waypoint.CurrentHull ~= nil then
                potentialPosition = waypoint.WorldPosition
                break
            end
        end
    else
        potentialPosition = spawnWayPoints[1].WorldPosition
    end

    local character = Character.Create(client.CharacterInfo, potentialPosition, client.CharacterInfo.Name, 0, true, true)

    character.TeamID = team.TeamID

    client.SetClientCharacter(character)

    character.GiveJobItems()
    character.LoadTalents()

    character.TeleportTo(team.Spawns[math.random(1, #team.Spawns)].WorldPosition)
end

function gm:Start()
    Traitormod.DisableRespawnShuttle = true
    Traitormod.DisableMidRoundSpawn = true
    
    self.Respawns = {}
    self.DefendCountDown = self.DefendTime * 60
    self.LastDefendCountDown = self.DefendTime * 60

    local teams = {}
    self.Teams = teams
    teams[1] = {}
    teams[1].Name = "Defender Team"
    teams[1].Spawns = {}
    teams[1].TeamID = CharacterTeamType.Team1
    teams[1].RespawnTime = self.DefendRespawn
    teams[2] = {}
    teams[2].Name = "Attacker Team"
    teams[2].Spawns = {}
    teams[2].TeamID = CharacterTeamType.Team2
    teams[2].RespawnTime = self.AttackRespawn

    for key, value in pairs(Item.ItemList) do
        if value.GetComponentString("Reactor") then
            if value.HasTag("redteam") then
                teams[1].Reactor = value
            end
        end
    end

    teams[1].CheckWinCondition = function ()
        if self.DefendCountDown <= 0 then
            return true
        end
        return false
    end

    teams[1].GetMembers = function ()
        local members = {}
        for index, client in ipairs(Client.ClientList) do
            if not client.SpectateOnly then
                if client.PreferredJob == "captain" or client.PreferredJob == "securityofficer" or client.PreferredJob == "medicaldoctor" then
                    table.insert(members, client)
                end
            end
        end
        return members
    end

    teams[2].CheckWinCondition = function ()
        if teams[1].Reactor and teams[1].Reactor.Condition <= 1 then
            return true
        end
        return false
    end

    teams[2].GetMembers = function ()
        local members = {}
        for index, client in ipairs(Client.ClientList) do
            if not client.SpectateOnly then
                if client.PreferredJob == "captain" or client.PreferredJob == "securityofficer" or client.PreferredJob == "medicaldoctor" then else
                    table.insert(members, client)
                end
            end
        end
        return members
    end

    for key, value in pairs(Submarine.MainSub.GetWaypoints(true)) do
        if value.AssignedJob.Identifier == "mechanic" then
            table.insert(teams[1].Spawns, value)
        elseif value.AssignedJob.Identifier == "engineer" then
            table.insert(teams[2].Spawns, value)
        end
    end

    for key, value in pairs(Character.CharacterList) do
        if value.Submarine == Submarine.MainSub then
            Entity.Spawner.AddEntityToRemoveQueue(value)
        end
    end

    for _, team in pairs(teams) do
        for _, member in pairs(team.GetMembers()) do
            SpawnCharacter(member, team)
        end
    end
end

function gm:End()
    Hook.Remove("characterDeath", "Traitormod.AttackDefend.CharacterDeath")

    -- first arg = mission id, second = message, third = completed, forth = list of characters
    return nil
end

function gm:Think()
    if self.Ending then return end
    self.DefendCountDown = self.DefendCountDown - 1/60

    local max = 30
    if self.DefendCountDown <= 10 then max = 1 end
    if self.LastDefendCountDown - self.DefendCountDown > max then
        for _, client in pairs(Client.ClientList) do
            Traitormod.SendChatMessage(client, "The defender team has " .. math.floor(self.DefendCountDown) .. " seconds left to defend the reactor!", Color.GreenYellow)
        end
        self.LastDefendCountDown = self.DefendCountDown
    end

    for _, team in pairs(self.Teams) do
        for _, member in pairs(team.GetMembers()) do
            if not member.Character or member.Character.IsDead then
                if self.Respawns[member] == nil then
                    self.Respawns[member] = team.RespawnTime
                else
                    self.Respawns[member] = self.Respawns[member] - 1/60
                end

                if self.Respawns[member] <= 0 then
                    SpawnCharacter(member, team)
                    self.Respawns[member] = nil
                end
            end
        end

        if team.CheckWinCondition() then
            self.Ending = true
            for _, client in pairs(Client.ClientList) do
                Traitormod.SendMessage(client, team.Name .. " won the game!", "InfoFrameTabButton.Mission")
            end

            for _, member in pairs(team.GetMembers()) do
                local points = Traitormod.AwardPoints(member, self.WinningPoints)
                Traitormod.SendMessage(member, string.format(Traitormod.Language.ReceivedPoints, points), "InfoFrameTabButton.Mission")    
            end
            Timer.Wait(function ()
                Game.EndGame()
            end, 5000)
        end
    end
end


return gm
