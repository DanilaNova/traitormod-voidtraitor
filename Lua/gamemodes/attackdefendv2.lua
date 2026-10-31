---@alias classFunction fun(character: Barotrauma.Character)

---@class Gamemodes.AttackDefendV2: Gamemode
local gm = Traitormod.Gamemodes.Gamemode:new()
local TeamID1 = CharacterTeamType.Team1
local TeamID2 = CharacterTeamType.Team2
local textPromptUtils = require("textpromptutils")

local function GetOppositeTeamID(teamID)
	return (teamID == TeamID1 or teamID == 1) and TeamID2 or TeamID1
end

gm.Name = "AttackDefendV2"
gm.RequiredGamemode = "pvp"
gm.MissionType = "AttackDefenceV2"
gm.PriorityTeam = CharacterTeamType.None

gm.TraitormodSettings = { LimitedSuicide = false }

function gm:CheckRequirements()
	for value in Game.ServerSettings.AllowedRandomMissionTypes do
		if value == self.MissionType then return true end
	end
	return false
end

--#region Helper functions

---Выдаёт экипировку персонажу
---@param character Barotrauma.Character
---@param team AttackDefendV2.Team
---@param waypoint Barotrauma.WayPoint
---@param class classFunction?
local function GearUpCharacter(character, team, waypoint, class)
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

---Спавнит персонажа для клиента
---@param client Barotrauma.Networking.Client
---@param team AttackDefendV2.Team
---@param class classFunction
---@param jobId string
local function SpawnCharacter(client, team, class, jobId)
	if client.CharacterInfo == nil then client.CharacterInfo = CharacterInfo("human", client.Name) end
	local spawnPoint = team.Spawns[math.random(1, #team.Spawns)]

	local characterInfo = client.CharacterInfo
	characterInfo.Job = Job(JobPrefab.Get(jobId or "commoner"), true)
	characterInfo.TeamID = team.TeamID

	local character = Character.Create(characterInfo, spawnPoint.WorldPosition, characterInfo.Name, 0, true, true)
	client.SetClientCharacter(character)
	textPromptUtils.UnlockOption(client)

    GearUpCharacter(character, team, spawnPoint, class)
end

local NET_RESPAWNS = "VoidTraitor_AttackDefendRespawns"

local function SyncRespawnTeam(team)
	local respawning = {}
	for id, entry in pairs(team.Respawns) do
		local member = team.Members[id]
		if entry.Timer ~= nil and member.InGame and member.Connection ~= nil and not member.SpectateOnly
			and not member.NeedsMidRoundSync and member.CharacterInfo ~= nil then
			table.insert(respawning, { InfoId = member.CharacterInfo.ID, Timer = math.max(0, entry.Timer) })
		end
	end

	local message = Networking.Start(NET_RESPAWNS)
	message.WriteByte(Byte(#respawning))
	for _, data in ipairs(respawning) do
		message.WriteUInt16(UShort(data.InfoId))
		message.WriteSingle(data.Timer)
	end

	for _, member in pairs(team.Members) do
		if member.Connection ~= nil and not member.SpectateOnly then
			Networking.Send(message, member.Connection)
		end
	end
end

-- Функция очистки (оставляем, она работает отлично)
local function CleanRemove(char)
	if not char or char.Removed then return end
	local pos = char.WorldPosition
	if char.Inventory then for item in char.Inventory.AllItems do Entity.Spawner.AddItemToRemoveQueue(item) end end
	char.DespawnNow()
	for _, item in pairs(Item.ItemList) do
		if item.Prefab.Identifier.Value == "duffelbag" and Vector2.Distance(item.WorldPosition, pos) < 10 then
			Entity.Spawner.AddItemToRemoveQueue(item)
		end
	end
end

---@param client Barotrauma.Networking.Client
---@protected
function gm:_SetNewClient(client, lockClassSelection)
	local char = client.Character
	Timer.Wait(function()
		if not Game.RoundStarted or Traitormod.SelectedGamemode ~= self or self.IsEnding then return end
		if not client or not client.Connection or client.Connection.Status ~= 1 or client.SpectateOnly then return end
		client.SetClientCharacter(nil)
		CleanRemove(char)

		if lockClassSelection then
			textPromptUtils.LockOption(client, Traitormod.Language.PointshopCancel)
		end

		local function loop()
			if not Game.RoundStarted or Traitormod.SelectedGamemode ~= self or self.IsEnding then return end
			if not client.Connection or client.Connection.Status ~= 1 or client.SpectateOnly then return end
			if not client.InGame then
				Timer.Wait(loop, 1000)
			else
				if Traitormod.Pointshop.OpenGuiOrFallback ~= nil then
					Traitormod.Pointshop.OpenGuiOrFallback(client, false)
				else
					Traitormod.Pointshop.ShowCategory(client, true)
				end
			end
		end
		
		loop()
	end, 1250)
end

---@param newClients Barotrauma.Networking.Client[]
---@protected
function gm:_BalanceTeams(newClients)
	local priorityTeamID = self.PriorityTeam
	if priorityTeamID == CharacterTeamType.None then
		priorityTeamID = math.random(1, 2) == 1 and TeamID1 or TeamID2
	end
	local notPriorityTeamID = GetOppositeTeamID(priorityTeamID)
	local tempTeams = {
		[priorityTeamID] = {},
		[notPriorityTeamID] = {},
	}
	local freeClients = {}

	-- Вначале пытаемся распеделить по предпочтениям игроков
	for _, client in ipairs(newClients) do
		local preferredTeam = tempTeams[client.PreferredTeam]
		if preferredTeam ~= nil then
			table.insert(preferredTeam, client)
		else
			table.insert(freeClients, client)
		end
	end

	-- Назначаем неопределившихся игроков
	for _, client in ipairs(freeClients) do
		if #tempTeams[notPriorityTeamID] < #tempTeams[priorityTeamID] then
			table.insert(tempTeams[notPriorityTeamID], client)
		else
			table.insert(tempTeams[priorityTeamID], client)
		end
	end

	-- Балансируем команды, сохраняя преимущество приоритетной команды максимум в одного игрока
	while #tempTeams[priorityTeamID] < #tempTeams[notPriorityTeamID] do
		local randomPlayerIndex = math.random(#tempTeams[notPriorityTeamID])
		table.insert(tempTeams[priorityTeamID], table.remove(tempTeams[notPriorityTeamID], randomPlayerIndex))
	end
	while #tempTeams[priorityTeamID] - #tempTeams[notPriorityTeamID] > 1 do
		local randomPlayerIndex = math.random(#tempTeams[priorityTeamID])
		table.insert(tempTeams[notPriorityTeamID], table.remove(tempTeams[priorityTeamID], randomPlayerIndex))
	end

	for teamID, members in pairs(tempTeams) do
		for _, client in ipairs(members) do
			self:_ChangeTeam(client, teamID)
		end
	end
end

---@param client Barotrauma.Networking.Client
---@return Barotrauma.CharacterTeamType
function gm:_AddNewClient(client)
	local priorityTeamID = self.PriorityTeam
	if priorityTeamID == CharacterTeamType.None then
		priorityTeamID = math.random(1, 2) == 1 and TeamID1 or TeamID2
	end
	local notPriorityTeamID = GetOppositeTeamID(priorityTeamID)

	local teamCounts = { [TeamID1] = 0, [TeamID2] = 0 }
	for member in Client.ClientList do
		if member ~= client and not member.SpectateOnly and (not member.AFK or not Game.ServerSettings.AllowAFK) then
			local team = self.Teams[member.TeamID]
			if team ~= nil and team.Members[member.AccountId] ~= nil then
				teamCounts[member.TeamID] = teamCounts[member.TeamID] + 1
			end
		end
	end

	if teamCounts[priorityTeamID] > teamCounts[notPriorityTeamID] then
		self:_ChangeTeam(client, notPriorityTeamID)
		return notPriorityTeamID
	else
		self:_ChangeTeam(client, priorityTeamID)
		return priorityTeamID
	end
end

---@protected
---@param client Barotrauma.Networking.Client
---@param to Barotrauma.CharacterTeamType
---@param from Barotrauma.CharacterTeamType?
function gm:_ChangeTeam(client, to, from)
	local team = self.Teams[to]
	local id = client.AccountId

	if from ~= nil then
		local oldTeam = self.Teams[from]
		oldTeam.Members[id] = nil
		oldTeam.Respawns[id] = nil
		team.Respawns[id] = { Timer = nil }
	else
		team.Respawns[id] = { Timer = 0 }
	end

	team.Members[id] = client
	client.TeamID = to
	client.PreferredTeam = to
end

function gm:SwitchTestTeam(client)
	local id = client.AccountId
	local fromTeamID = nil

	for teamID, team in pairs(self.Teams) do
		if team.Respawns[id] ~= nil then
			fromTeamID = teamID
			break
		end
	end

	if fromTeamID == nil then return nil end

	local toTeamID = GetOppositeTeamID(fromTeamID)
	self:_ChangeTeam(client, toTeamID, fromTeamID)
	self.Teams[toTeamID].Respawns[id].Timer = 0
	self:_SetNewClient(client)
	SyncRespawnTeam(self.Teams[fromTeamID])
	SyncRespawnTeam(self.Teams[toTeamID])
	return toTeamID
end

--#endregion

function gm:PreStart()
	self.IsEnding = false
	self.ClassCounters = {}
	self.ClassGroupCounters = {}

	---@type AttackDefendV2.Team[]
	local teams = {}
	self.Teams = teams

	---@class AttackDefendV2.Team
	---@field Reactor Barotrauma.Item?
	teams[TeamID1] = {
		Name = Traitormod.GetText("AttackDefendDefenderTeamName"),
		---@type Barotrauma.WayPoint[]
		Spawns = {},
		---@type { [Barotrauma.Networking.AccountId]: Barotrauma.Networking.Client }
		Members = {},
		---@type { [Barotrauma.Networking.AccountId]: RespawnEntry }
		Respawns = {},
		TeamID = TeamID1,
		Color = Color.Blue,

		CheckWinCondition = function ()
			return self.DefendCountDown <= 0
		end
	}
	teams[TeamID2] = {
		Name = Traitormod.GetText("AttackDefendAttackerTeamName"),
		Spawns = {},
		Members = {},
		Respawns = {},
		TeamID = TeamID2,
		Color = Color.Red,

		CheckWinCondition = function ()
			return teams[TeamID1].Reactor and teams[TeamID1].Reactor.Condition <= 1
		end
	}


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
	Traitormod.DisableRespawnShuttle = true
	Traitormod.DisableMidRoundSpawn = true

	local outpost = Game.GameSession.Level.StartOutpost
	for key, value in pairs(Traitormod.ParseSubmarineConfig(outpost.Info.Description.Value)) do
		self[key] = value
	end
	Traitormod.Pointshop.Initialize(self.PointshopCategories or {})

	self.DefendCountDown = self.DefendTime * 60
	self.LastDefendCountDown = self.DefendTime * 60
	self.Teams[TeamID1].RespawnTime = self.DefendRespawn
	self.Teams[TeamID1].WinningPoints = self.WinningPointsTeam1
	self.Teams[TeamID2].RespawnTime = self.AttackRespawn
	self.Teams[TeamID2].WinningPoints = self.WinningPointsTeam2
	
	for _, item in pairs(Item.ItemList) do
		if item.GetComponentString("Reactor") and item.HasTag("deathmatchteam1reactor") then
			self.Teams[TeamID1].Reactor = item --[[@as Barotrauma.Item]]
			break
		end
	end

	for _, waypoint in pairs(outpost.GetWaypoints(true)) do
		for tag in waypoint.Tags do
			if tag == "deathmatchteam1" then
                table.insert(self.Teams[TeamID1].Spawns, waypoint)
        	elseif tag == "deathmatchteam2" then
                table.insert(self.Teams[TeamID2].Spawns, waypoint)
        	end
		end
    end
	
	local newClients = {}
	for client in Client.ClientList do
		---@cast client Barotrauma.Networking.Client
		if not client.SpectateOnly and (not client.AFK or not Game.ServerSettings.AllowAFK) then
			table.insert(newClients, client)
		end
	end
	Traitormod.Config.TestMode = #newClients == 1
	if Traitormod.Config.TestMode then
		Traitormod.SendMessageEveryone(Traitormod.Language.TestingMode)
		Traitormod.SendMessageEveryone(Traitormod.GetText("CMDSwitchTestAvailable"))
	end

	self:_BalanceTeams(newClients)
	for _, client in ipairs(newClients) do
		self:_SetNewClient(client, true)
	end

	---@param client Barotrauma.Networking.Client
	Hook.Add("client.connected", "Traitormod.AttackDefendV2.ClientConnected", function (client)
		if client.SpectateOnly then return end
		for _, team in pairs(self.Teams) do
			if team.Members[client.AccountId] ~= nil then
				if client.CharacterInfo == nil then
					client.CharacterInfo = team.Members[client.AccountId].CharacterInfo
				end
				team.Members[client.AccountId] = client
				client.TeamID = team.TeamID
				client.PreferredTeam = team.TeamID
				if team.Respawns[client.AccountId].OnSpawn == nil then
					self:_SetNewClient(client)
				end
			end
		end
	end)

	---@param msg Barotrauma.Networking.IReadMessage
	---@param header Barotrauma.Networking.ServerPacketHeader
	---@param client Barotrauma.Networking.Client
	Hook.Add("netMessageReceived", "Traitormod.AttackDefendV2.ClientJoined", function (msg, header, client)
		if header ~= ClientPacketHeader.UPDATE_INGAME or client.InGame or client.SpectateOnly then
			return
		end

		for _, team in pairs(self.Teams) do
			if team.Members[client.AccountId] ~= nil then
				team.Members[client.AccountId] = client
				client.TeamID = team.TeamID
				client.PreferredTeam = team.TeamID
				team.Respawns[client.AccountId].SyncRespawns = true
				return
			end
		end
		local teamID = self:_AddNewClient(client)
		self:_SetNewClient(client)
		self.Teams[teamID].Respawns[client.AccountId].SyncRespawns = true
	end)
end

function gm:End()
	self.IsEnding = true
	for _, team in pairs(self.Teams) do
		for _, member in pairs(team.Members) do
			textPromptUtils.UnlockOption(member)
		end
	end

    Hook.Remove("client.connected", "Traitormod.AttackDefendV2.ClientConnected")
	Hook.Remove("character.giveJobItems", "Traitormod.AttackDefendV2.CharacterGiveJobItems")
	Hook.Remove("netMessageReceived", "Traitormod.AttackDefendV2.ClientJoined")

end

function gm:Think(deltaTime)
	if self.IsEnding then return end

	self.DefendCountDown = self.DefendCountDown - deltaTime

	local max = 30
    if self.DefendCountDown <= 10 then max = 1 end
    if self.LastDefendCountDown - self.DefendCountDown > max then
        for _, client in pairs(Client.ClientList) do
            Traitormod.SendChatMessage(client, Traitormod.FormatText("AttackDefendDefenderCountdown", math.ceil(self.DefendCountDown)), Color.GreenYellow)
        end
        self.LastDefendCountDown = self.DefendCountDown
    end

	for _, team in pairs(self.Teams) do
		local respawnChanged = false
		
		for id, entry in pairs(team.Respawns) do
			local member = team.Members[id]
			if entry.SyncRespawns and member.InGame and not member.NeedsMidRoundSync then
				entry.SyncRespawns = nil
				respawnChanged = true
			end
			if member.Connection ~= nil and not member.SpectateOnly
				and (member.Character == nil or member.Character.IsDead) and member.InGame and not member.NeedsMidRoundSync then
				if entry.Timer == nil then
					entry.Timer = team.RespawnTime
					respawnChanged = true
				end
				entry.Timer = entry.Timer - deltaTime
				if entry.Timer <= 0 and entry.OnSpawn ~= nil then
					SpawnCharacter(member, team, entry.OnSpawn, entry.JobId)
					entry.Timer = nil
					respawnChanged = true
				end
			end
		end
		if respawnChanged then SyncRespawnTeam(team) end

		if team.CheckWinCondition() then
            self.IsEnding = true
			Game.GameSession.WinningTeam = team.TeamID
			for mission in Game.GameSession.Missions do
				if mission.Prefab.Type == self.MissionType then
					mission.State = team.TeamID --[[@as number]]
				end
			end

            if not Traitormod.Config.TestMode then
                for _, member in pairs(team.Members) do
                    local points = Traitormod.AwardPoints(member, team.WinningPoints)
                    Traitormod.SendMessage(member, string.format(Traitormod.Language.ReceivedPoints, points), "InfoFrameTabButton.Mission")
                end
            end
            return
        end
	end
end

return gm
