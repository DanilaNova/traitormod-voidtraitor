---@alias classFunction fun(character: Barotrauma.Character)

---@class Gamemodes.AttackDefendV2: Gamemode
local gm = Traitormod.Gamemodes.Gamemode:new()
local TeamID1 = CharacterTeamType.Team1
local TeamID2 = CharacterTeamType.Team2

gm.Name = "AttackDefendV2"
gm.RequiredGamemode = "pvp"
gm.MissionType = "AttackDefenceV2"
gm.RandomizeTeams = false

gm.TraitormodSettings.LimitedSuicide = false

function gm:CheckRequirements()
	for value in Game.ServerSettings.AllowedRandomMissionTypes do
		if value == self.MissionType then return true end
	end
	return false
end

--#region Helper functions

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

---Спавнит персонажа для клиента
---@param client Barotrauma.Networking.Client
---@param team AttackDefendV2.Team
---@param class classFunction
---@param jobId string
function SpawnCharacter(client, team, class, jobId)
	if client.CharacterInfo == nil then return false end
	local spawnPoint = team.Spawns[math.random(1, #team.Spawns)]

	local characterInfo = client.characterInfo
	characterInfo.Job = Job(JobPrefab.Get(jobId or "commoner"), true)

	local character = Character.Create(characterInfo, spawnPoint.WorldPosition, client.CharacterInfo.Name, 0, true, true)
	client.SetClientCharacter(character)

    GearUpCharacter(character, team, spawnPoint, class)
end

---Выдаёт экипировку персонажу
---@param character Barotrauma.Character
---@param team AttackDefendV2.Team
---@param waypoint Barotrauma.WayPoint
---@param class classFunction?
function GearUpCharacter(character, team, waypoint, class)
    local card = character.Inventory.GetItemInLimbSlot(InvSlotType.Card)
	if card then
		card.NonPlayerTeamInteractable = true
		local lock = card.SerializableProperties[Identifier("NonPlayerTeamInteractable")]
		Networking.CreateEntityEvent(card, Item.ChangePropertyEventData(lock, card))
	else
		Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab("idcard"), character.Inventory, nil, nil, function (card)
			card.GetComponentString("IdCard")--[[@as Barotrauma.Items.Components.IdCard]].Initialize(waypoint, character)
			card.NonPlayerTeamInteractable = true
			local lock = card.SerializableProperties[Identifier("NonPlayerTeamInteractable")]
			Networking.CreateEntityEvent(card, Item.ChangePropertyEventData(lock, card))
		end, true, false, InvSlotType.Card)
	end

	local innerClothes = character.Inventory.GetItemInLimbSlot(InvSlotType.InnerClothes)
	if innerClothes then
		innerClothes.SpriteColor = team.Color
		local color = innerClothes.SerializableProperties[Identifier("SpriteColor")]
		Networking.CreateEntityEvent(innerClothes, Item.ChangePropertyEventData(color, innerClothes))
	end

	if class then class(character) end
end

---@param client Barotrauma.Networking.Client
---@protected
function gm:__SetNewClient(client)
	local character = client.Character
	if character ~= nil then
		Timer.Wait(function ()
			client.SetClientCharacter(nil)
			character.DespawnNow()
			Traitormod.Pointshop.ShowCategory(client)
		end, 1000)
	end
	self.Respawns[client] = {Timer = 0}
end

--#endregion

function gm:PreStart()
	for sub in SubmarineInfo.SavedSubmarines do
		if sub.Name == Game.ServerSettings.SelectedOutpostName then
			for key, value in pairs(Traitormod.ParseSubmarineConfig(sub.Description.Value)) do
				self[key] = value
			end	
		end
	end
	
	Traitormod.Pointshop.Initialize(self.PointshopCategories or {})

	Traitormod.DisableRespawnShuttle = true
    Traitormod.DisableMidRoundSpawn = true

	self.IsEnding = false
	self.Respawns = {}
	self.ClassCounters = {}
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
		WinningPoints = self.WinningPointsTeam1,

		CheckWinCondition = function ()
			return self.DefendCountDown <= 0
		end
	}
	teams[TeamID2] = {
		Name = "Attackers",
		Spawns = {},
		Members = {},
		TeamID = TeamID2,
		RespawnTime = self.AttackRespawn,
		Color = Color.Red,
		WinningPoints = self.WinningPointsTeam2,

		CheckWinCondition = function ()
			return teams[1].Reactor and teams[1].Reactor.Condition <= 1
		end
	}

	--Hook.Remove("characterCreated", "Traitormod.CharacterCreated")

	---@param client Barotrauma.Networking.Client
	Hook.Add("client.connected", "Traitormod.AttackDefendV2.ClientConnected", function (client)
		ChooseTeam(client, teams)
		self:__SetNewClient(client)
	end)

	---@param character Barotrauma.Character
	---@param waypoint Barotrauma.WayPoint
	Hook.Add("character.giveJobItems", "Traitormod.AttackDefendV2.CharacterGiveJobItems", function (character, waypoint)
		local team = self.Teams[character.TeamID]
		if team == nil then
			Traitormod.Error("Created character is on undefined team №"..character.TeamID)
		else 
			GearUpCharacter(character, team, waypoint)
		end
	end)
end

function gm:Start()
	for _, item in pairs(Item.ItemList) do
		if item.GetComponentString("Reactor") and item.HasTag("deathmatchteam1reactor") then
			self.Teams[1].Reactor = item --[[@as Barotrauma.Item]]
			break
		end
	end

	for _, waypoint in pairs(Game.GameSession.Level.StartOutpost.GetWaypoints(true)) do
		for tag in waypoint.Tags do
			if tag == "deathmatchteam1" then
                table.insert(self.Teams[1].Spawns, waypoint)
        	elseif tag == "deathmatchteam2" then
                table.insert(self.Teams[2].Spawns, waypoint)
        	end
		end
    end

	for client in Client.ClientList do
		ChooseTeam(client, self.Teams)
		---@cast client Barotrauma.Networking.Client
		self:__SetNewClient(client)
	end

end

function gm:End()
    Hook.Remove("client.connected", "Traitormod.AttackDefendV2.ClientConnected")
	Hook.Remove("character.giveJobItems", "Traitormod.AttackDefendV2.CharacterGiveJobItems")
	
	-- local entry = Traitormod.DefaultHooks["Traitormod.CharacterCreated"]
	-- Hook.Add(entry[1], "Traitormod.CharacterCreated", entry[2])
end

function gm:Think()
	if self.IsEnding then return end
	self.DefendCountDown = self.DefendCountDown - 1/60

	local max = 30
    if self.DefendCountDown <= 10 then max = 1 end
    if self.LastDefendCountDown - self.DefendCountDown > max then
        for _, client in pairs(Client.ClientList) do
            Traitormod.SendChatMessage(client, "The defender team has " .. math.ceil(self.DefendCountDown) .. " seconds left to defend the reactor!", Color.GreenYellow)
        end
        self.LastDefendCountDown = self.DefendCountDown
    end

	for _, team in ipairs(self.Teams) do
		for _, member in ipairs(team.Members) do
            if not member.SpectateOnly and (not member.Character or member.Character.IsDead) then
				local respawn = self.Respawns[member]

                if respawn == nil then
					self.Respawns[member] = {Timer = team.RespawnTime}
					
                else
					if respawn.Timer == nil then
						respawn.Timer = team.RespawnTime
					end
                    respawn.Timer = respawn.Timer - 1/60
					if respawn.Timer <= 0 and respawn.OnSpawn ~= nil then

						SpawnCharacter(member, team, respawn.OnSpawn, respawn.JobId)
						self.Respawns[member].Timer = nil

						local prevClassId = self.Respawns[member].PrevClassId
						if prevClassId ~= nil then
							local classCounter = self.ClassCounters[prevClassId]
							if classCounter == nil then
								Traitormod.Error(("Class counter '%s' was empty"):format(prevClassId))
							else
								self.ClassCounters[prevClassId] = classCounter - 1
							end
						end

					end
                end
            end
        end
		if team.CheckWinCondition() then
            self.IsEnding = true
			Game.GameSession.WinningTeam = team.TeamID
			for mission in Game.GameSession.Missions do
				if mission.Prefab.Type == self.MissionType then
					mission.State = team.TeamID --[[@as number]]
				end
			end

            for _, member in pairs(team.Members) do
                local points = Traitormod.AwardPoints(member, team.WinningPoints)
                Traitormod.SendMessage(member, string.format(Traitormod.Language.ReceivedPoints, points), "InfoFrameTabButton.Mission")
            end
            -- Timer.Wait(function ()
            --     Game.EndGame()
            -- end, 5000)
        end
	end
end

return gm