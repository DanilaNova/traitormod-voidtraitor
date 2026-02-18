---@alias classFunction fun(character: Barotrauma.Character)

---@class Gamemodes.AttackDefendV2: Gamemode
local gm = Traitormod.Gamemodes.Gamemode:new()
local TeamID1 = CharacterTeamType.Team1
local TeamID2 = CharacterTeamType.Team2

gm.Name = "AttackDefendV2"
gm.RequiredGamemode = "pvp"
gm.MissionType = "AttackDefenceV2"
gm.PriorityTeam = CharacterTeamType.None

gm.TraitormodSettings.LimitedSuicide = false

function gm:CheckRequirements()
	for value in Game.ServerSettings.AllowedRandomMissionTypes do
		if value == self.MissionType then return true end
	end
	return false
end

--#region Helper functions

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
	characterInfo.TeamID = team.TeamID

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

-- Функция очистки вещмешки
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
function gm._SetNewClient(client)
	local character = client.Character
	if character ~= nil then
		Timer.Wait(function ()
			client.SetClientCharacter(nil)
			CleanRemove(char)
			Timer.Wait(function ()
				Traitormod.Pointshop.ShowCategory(client)
			end, 4000)
		end, 1000)
	end
end

---@param newClients Barotrauma.Networking.Client[]?
---@return { Client: Barotrauma.Networking.Client, NewTeamID: Barotrauma.CharacterTeamType }[]
---@protected
function gm:_BalanceTeams(newClients)
	local priorityTeamID = self.PriorityTeam
	if priorityTeamID == CharacterTeamType.None then
		priorityTeamID = math.random(1, 2) == 1 and TeamID1 or TeamID2
	end
	local notPriorityTeamID = priorityTeamID == 1 and TeamID2 or TeamID1

	-- Распределяем новых клиентов
	if newClients ~= nil then
		local tempTeams = {
			[priorityTeamID] = {
				Counter = #self.Teams[TeamID1].Members,
				---@type Barotrauma.Networking.Client[]
				Members = {}
			},
			[notPriorityTeamID] = {
				Counter = #self.Teams[TeamID2].Members,
				---@type Barotrauma.Networking.Client[]
				Members = {}
			}
		}
		local priorityTeam = tempTeams[priorityTeamID]
		local priorityTeamMembers = priorityTeam.Members
		local notPriorityTeam = tempTeams[notPriorityTeamID]
		local notPriorityTeamMembers = notPriorityTeam.Members
		---@type Barotrauma.Networking.Client[]
		local freeClients = {}

		-- Вначале пытаемся распеделить по предпочтениям игроков
		for _, client in ipairs(newClients) do
			local preferredTeam = tempTeams[client.PreferredTeam]
			if preferredTeam ~= nil then
				table.insert(preferredTeam.Members, client)
				preferredTeam.Counter = preferredTeam.Counter + 1
			else
				table.insert(freeClients, client)
			end
		end

		-- Назначаем неопределившихся игроков
		for _, client in ipairs(freeClients) do
			if notPriorityTeam.Counter < priorityTeam.Counter then
				table.insert(notPriorityTeamMembers, client)
				notPriorityTeam.Counter = notPriorityTeam.Counter + 1
			else
				table.insert(priorityTeamMembers, client)
				priorityTeam.Counter = priorityTeam.Counter + 1
			end
		end

		-- Балансируем за счёт новых игроков
		while priorityTeam.Counter - notPriorityTeam.Counter < 0 and #notPriorityTeamMembers > 0 do
			local randomPlayerIndex = math.random(#notPriorityTeamMembers)
			local client = table.remove(notPriorityTeamMembers, randomPlayerIndex)
			notPriorityTeam.Counter = notPriorityTeam.Counter - 1
			table.insert(priorityTeamMembers, client)
			priorityTeam.Counter = priorityTeam.Counter + 1
		end
		while priorityTeam.Counter - notPriorityTeam.Counter > 1 and #priorityTeamMembers > 0 do
			local randomPlayerIndex = math.random(#priorityTeamMembers)
			local client = table.remove(priorityTeamMembers, randomPlayerIndex)
			priorityTeam.Counter = priorityTeam.Counter - 1
			table.insert(notPriorityTeamMembers, client)
			notPriorityTeam.Counter = notPriorityTeam.Counter + 1
		end

		-- Записываем полученные списки в комманды
		for teamID, tempTeam in pairs(tempTeams) do
			local team = self.Teams[teamID]
			local teamMembers = team.Members
			for _, client in pairs(tempTeam.Members) do
				self:_ChangeTeam(client, team.TeamID)
			end
		end

		print("Окончательный список команд")
		for teamID, team in pairs(self.Teams) do
			print("  Команда ", teamID)
			for _, member in pairs(team.Members) do
				print("    "..member.Name)
			end
		end
	end

	local priorityTeamMembers = self.Teams[priorityTeamID].Members
	local notPriorityTeamMembers = self.Teams[notPriorityTeamID].Members
	local autobalancedClients = {}
	while #priorityTeamMembers - #notPriorityTeamMembers < 0 do
		local randomPlayerIndex = math.random(#notPriorityTeamMembers)
		local client = notPriorityTeamMembers[randomPlayerIndex]
		self:_ChangeTeam(client, priorityTeamID, notPriorityTeamID)
		table.insert(autobalancedClients, { Client = client, NewTeamID = priorityTeamID })
	end
	while #priorityTeamMembers - #notPriorityTeamMembers > 1 do
		local randomPlayerIndex = math.random(#priorityTeamMembers)
		local client = priorityTeamMembers[randomPlayerIndex]
		self:_ChangeTeam(client, notPriorityTeamID, priorityTeamID)
		table.insert(autobalancedClients, { Client = client, NewTeamID = notPriorityTeamID })
	end

	return autobalancedClients
end

---@param client Barotrauma.Networking.Client
---@return Barotrauma.CharacterTeamType
function gm:_AddNewClient(client)
	local priorityTeamID = self.PriorityTeam
	if priorityTeamID == CharacterTeamType.None then
		priorityTeamID = math.random(1, 2) == 1 and TeamID1 or TeamID2
	end
	local notPriorityTeamID = priorityTeamID == 1 and TeamID2 or TeamID1

	local priorityTeamMembers = self.Teams[priorityTeamID].Members
	local notPriorityTeamMembers = self.Teams[notPriorityTeamID].Members

	if #priorityTeamMembers > #notPriorityTeamMembers then
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
---@return boolean error в изначальной команде не нашёлся указанный участник
function gm:_ChangeTeam(client, to, from)
	local error = false
	local team = self.Teams[to]
	local id = client.AccountId

	if from ~= nil then
		local oldTeam = self.Teams[from]
		local teamMembers = oldTeam.Members
		local deleteId
		for i, member in pairs(teamMembers) do
			if member == client then
				deleteId = i
				break
			end
		end
		if deleteId ~= nil then
			teamMembers[deleteId] = nil
		else
			print(("[AttackDefenceV2] WARNING: Cannot find %s in original team"):format(client.Name))
			error = true
		end
		
		oldTeam.Respawns[id] = nil
		team.Respawns[id] = { Timer = nil }
	else
		team.Respawns[id] = { Timer = 0 }
	end
	team.Members[id] = client
	client.TeamID = to
	client.PreferredTeam = to
	print(("[AttackDefenceV2]: %s team is set to %s"):format(client.Name, to))
	return error
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

	self.IsEnding = false
	self.ClassCounters = {}
    self.DefendCountDown = self.DefendTime * 60
    self.LastDefendCountDown = self.DefendTime * 60

	---@type AttackDefendV2.Team[]
	local teams = {}
	self.Teams = teams

	local mtMembers = {
		---@param obj AttackDefendV2.Members
		__len = function (obj)
			local i = 0
			for _ in pairs(obj) do
				i = i + 1
			end
			return i
		end,
		---@param obj AttackDefendV2.Members
		---@param key any
		__index = function (obj, key)
			if type(key) ~= "number" then
				return nil
			end
			local i
			for _, value in pairs(obj) do
				if i == key then
					return value
				end
				i = i + 1
			end
			return nil
		end
	}

	---@class AttackDefendV2.Team
	---@field Reactor Barotrauma.Item?
	teams[TeamID1] = {
		Name = "Defenders",
		---@type Barotrauma.WayPoint[]
		Spawns = {},
		---@type { [Barotrauma.Networking.AccountId]: Barotrauma.Networking.Client }
		Members = setmetatable({}, mtMembers),
		---@type { [Barotrauma.Networking.AccountId]: RespawnEntry }
		Respawns = {},
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
		Members = setmetatable({}, mtMembers),
		Respawns = {},
		TeamID = TeamID2,
		RespawnTime = self.AttackRespawn,
		Color = Color.Red,
		WinningPoints = self.WinningPointsTeam2,

		CheckWinCondition = function ()
			return teams[1].Reactor and teams[1].Reactor.Condition <= 1
		end
	}

	--Hook.Remove("characterCreated", "Traitormod.CharacterCreated")

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
    -- Traitormod.DisableMidRoundSpawn = true
	
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

	
	local newClients = {}
	for client in Client.ClientList do
		---@cast client Barotrauma.Networking.Client
		if not client.SpectateOnly then
			table.insert(newClients, client)
		end
	end
	local autobalancedClients = self:_BalanceTeams(newClients)
	for _, client in ipairs(autobalancedClients) do
		print(("Client %s is autobalanced to team %s"):format(client.Client.Name, client.NewTeamID))
	end
	for _, client in ipairs(newClients) do
		self._SetNewClient(client)
	end

	---@param client Barotrauma.Networking.Client
	Hook.Add("client.connected", "Traitormod.AttackDefendV2.ClientConnected", function (client)
		local teams = self.Teams
		for _, team in pairs(teams) do
			if team.Members[client.AccountId] ~= nil then
				team.Members[client.AccountId] = client
			end
		end
	end)

	---@param msg Barotrauma.Networking.IReadMessage
	---@param header Barotrauma.Networking.ServerPacketHeader
	---@param client Barotrauma.Networking.Client
	Hook.Add("netMessageReceived", "Traitormod.AttackDefendV2.ClientJoined", function (msg, header, client)
		if header ~= ClientPacketHeader.UPDATE_INGAME or client.InGame then
			return
		end

		for _, team in pairs(self.Teams) do
			local teamMembers = team.Members
			for id, member in pairs(teamMembers) do
				if member == client then return end
				if id == client.AccountId then
					teamMembers[id] = client
					return
				end
			end
		end

		print(("Player %s joined the game"):format(client.Name))
		self:_AddNewClient(client)
		self:_SetNewClient(client)
	end)
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

	for _, team in pairs(self.Teams) do
		
		for id, entry in pairs(team.Respawns) do
			local member = team.Members[id]
			if (member.Character == nil or member.Character.IsDead) and member.InGame then
				if entry.Timer == nil then
					entry.Timer = team.RespawnTime
				end
				entry.Timer = entry.Timer - 1/60
				if entry.Timer <= 0 and entry.OnSpawn ~= nil and member.InGame then
					SpawnCharacter(member, team, entry.OnSpawn, entry.JobId)
					entry.Timer = nil
					local prevClassId = entry.PrevClassId
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