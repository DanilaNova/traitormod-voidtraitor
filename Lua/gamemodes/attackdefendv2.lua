---@class (partial) AttackDefendV2: Gamemode
---@field DefendTime number
---@field Respawns table<Barotrauma.Networking.Client, number>
---@field DefendRespawn number
---@field AttackRespawn number
---@field DefendCountDown number
---@field Ending boolean
---@field WinningPoints integer?
---@field WinningPointsTeam1 integer?
---@field WinningPointsTeam2 integer?
local gm = Traitormod.Gamemodes.Gamemode:new()
local TeamID1 = CharacterTeamType.Team1
local TeamID2 = CharacterTeamType.Team2

gm.Name = "AttackDefendV2"
gm.RequiredGamemode = "pvp"

---Adds client to team members
---@param client Barotrauma.Networking.Client
---@param teams AttackDefendV2.Team[]
local function ChooseTeam(client, teams)
	local clientTeam = teams[client.TeamID]
	if(clientTeam) then
		table.insert(clientTeam.Members, client)
	else
		Traitormod.Error("Client " .. client.Name .. " belongs to the unknown team №".. client.TeamID)
	end
end

function gm:Start()
	Traitormod.DisableRespawnShuttle = true
    Traitormod.DisableMidRoundSpawn = true


	self.Ending = false
	self.Respawns = {}
    self.DefendCountDown = self.DefendTime * 60
    self.LastDefendCountDown = self.DefendTime * 60

	---@type AttackDefendV2.Team[]
	local teams = {}
	self.Teams = teams

	---@class AttackDefendV2.Team
	---@field Reactor Barotrauma.Item?
	teams[TeamID1] = {
		Name = "Defenders",
		---@type Barotrauma.WayPoint[]
		Spawns = {},
		---@type Barotrauma.Networking.Client[]
		Members = {},
		TeamID = TeamID1,
		RespawnTime = self.DefendRespawn,
		Color = Color.Blue,
		WinningPoints = self.WinningPointsTeam1 or self.WinningPoints or 0,

		CheckWinCondition = function ()
			return self.DefendCountDown <= 0
		end
	}
	teams[TeamID2] = {
		Name = "Defenders",
		Spawns = {},
		Members = {},
		TeamID = TeamID2,
		RespawnTime = self.AttackRespawn,
		Color = Color.Blue,
		WinningPoints = self.WinningPointsTeam2 or self.WinningPoints or 0,

		CheckWinCondition = function ()
			return teams[1].Reactor and teams[1].Reactor.Condition <= 1
		end
	}


	for _, item in pairs(Item.ItemList) do
		if item.GetComponentString("Reactor") then
			if item.HasTag("deathmatchteam1reactor") then
				teams[1].Reactor = item --[[@as Barotrauma.Item]]
			end
		end
	end

	for _, waypoint in pairs(Submarine.MainSub.GetWaypoints(true)) do
		for tag in waypoint.Tags do
			if tag == "deathmatchteam1" then
                table.insert(teams[1].Spawns, waypoint)
        	elseif tag == "deathmatchteam2" then
                table.insert(teams[2].Spawns, waypoint)
        	end
		end
    end

	
	for client in Client.ClientList do
		ChooseTeam(client, teams)
	end

	---@param client Barotrauma.Networking.Client
	Hook.Add("client.connected", "Traitormod.AttackDefendV2.ClientConnected", function (client)
		ChooseTeam(client, teams)
	end)
end

function gm:End()
    Hook.Remove("client.connected", "Traitormod.AttackDefendV2.ClientConnected")

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
            Traitormod.SendChatMessage(client, "The defender team has " .. math.ceil(self.DefendCountDown) .. " seconds left to defend the reactor!", Color.GreenYellow)
        end
        self.LastDefendCountDown = self.DefendCountDown
    end

	for _, team in pairs(self.Teams) do
		if team.CheckWinCondition() then
            self.Ending = true
            for _, client in pairs(Client.ClientList) do
                Traitormod.SendMessage(client, team.Name .. " won the game!", "InfoFrameTabButton.Mission")
            end

            for _, member in pairs(team.Members) do
                local points = Traitormod.AwardPoints(member, team.WinningPoints)
                Traitormod.SendMessage(member, string.format(Traitormod.Language.ReceivedPoints, points), "InfoFrameTabButton.Mission")    
            end
            Timer.Wait(function ()
                Game.EndGame()
            end, 5000)
        end
	end
end

return gm