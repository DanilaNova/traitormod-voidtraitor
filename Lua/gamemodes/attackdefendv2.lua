---@class RespawnEntry
---@field timer number
---@field class classFunction?

---@alias classFunction fun(character: Barotrauma.Character)

---@class (partial) AttackDefendV2: Gamemode
---@field DefendTime number config
---@field Respawns table<Barotrauma.Networking.Client, RespawnEntry>
---@field DefendRespawn number config
---@field AttackRespawn number config
---@field DefendCountDown number
---@field Ending boolean
---@field WinningPointsTeam1 integer config
---@field WinningPointsTeam2 integer config
local gm = Traitormod.Gamemodes.Gamemode:new()
local TeamID1 = CharacterTeamType.Team1
local TeamID2 = CharacterTeamType.Team2

gm.Name = "AttackDefendV2"
gm.RequiredGamemode = "pvp"
gm.OutpostInfo = nil

--- Проверяются требования режима
--- 1) В типах миссий есть 'OutpostCombat'
--- 2) В тегах выбранного аванпоста есть 'PVPOutpost'
function gm:CheckRequirements()
	if Game.ServerSettings.MissionTypes:find('OutpostCombat') then
		for sub in SubmarineInfo.SavedSubmarines do
			if sub.Name == Game.ServerSettings.SelectedOutpostName then
				for tag in sub.OutpostTags do
					if tag == "PVPOutpost" then
						self.OutpostInfo = sub
						return true
					end
				end
			end
		end
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
---@param class classFunction?
function SpawnCharacter(client, team, class)
	if client.SpectateOnly or client.CharacterInfo == nil then return false end
	local spawnPoint = team.Spawns[math.random(1, #team.Spawns)]

	local character = Character.Create(client.CharacterInfo, spawnPoint.WorldPosition, client.CharacterInfo.Name, 0, true, true)
	client.SetClientCharacter(character)
	character.GiveJobItems(false)
	character.LoadTalents()

    GearUpCharacter(character, team, class)
end

---Выдаёт экипировку персонажу
---@param character Barotrauma.Character
---@param team AttackDefendV2.Team
---@param class classFunction?
function GearUpCharacter(character, team, class)
    local card = character.Inventory.GetItemInLimbSlot(InvSlotType.Card)
	if card then
		card.NonPlayerTeamInteractable = true
		local lock = card.SerializableProperties[Identifier("NonPlayerTeamInteractable")]
		Networking.CreateEntityEvent(card, Item.ChangePropertyEventData(lock, card))
	else
		Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab("idcard"), character.Inventory, nil, nil, function (card)
			card.GetComponentString("IdCard").Initialize(spawnPoint, character)
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

--#endregion

function gm:PreStart()
	for key, value in pairs(Traitormod.ParseSubmarineConfig(self.OutpostInfo.Description.Value)) do
		Traitormod.SelectedGamemode[key] = value
	end
	Traitormod.Pointshop.Initialize(self.PointshopCategories or {})

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

	for client in Client.ClientList do
		ChooseTeam(client, teams)
	end

	---@param client Barotrauma.Networking.Client
	Hook.Add("client.connected", "Traitormod.AttackDefendV2.ClientConnected", function (client)
		ChooseTeam(client, teams)
	end)

	---@param character Barotrauma.Character
	Hook.Add("character.giveJobItems", "Traitormod.AttackDefendV2.CharacterGiveJobItems", function (character, waypoint)
		local team = self.Teams[character.TeamID]
		if team == nil then
			Traitormod.Error("Created character is on undefined team №"..character.TeamID)
		else 
			GearUpCharacter(character, team)
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
end

function gm:End()
    Hook.Remove("client.connected", "Traitormod.AttackDefendV2.ClientConnected")
	Hook.Remove("character.giveJobItems", "Traitormod.AttackDefendV2.CharacterGiveJobItems")

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
		for _, member in pairs(team.Members) do
            if not member.SpectateOnly and (not member.Character or member.Character.IsDead) then
				local respawn = self.Respawns[member]

                if respawn == nil then
					self.Respawns[member] = {timer = team.RespawnTime}
					
                else
                    respawn.timer = respawn.timer - 1/60
					if respawn.timer <= 0 then
						self.Respawns[member] = nil
						SpawnCharacter(member, team, respawn.class)
					end
                end
            end
        end
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