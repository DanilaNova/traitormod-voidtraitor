---@class Gamemodes.HideAndSeekV2: Gamemode
local gm = Traitormod.Gamemodes.Gamemode:new()
local TeamID1 = CharacterTeamType.Team1
local TeamID2 = CharacterTeamType.Team2
local textPromptUtils = require("textpromptutils")

gm.Name = "HideAndSeekV2"
gm.RequiredGamemode = "pvp"
gm.MissionType = "HideAndSeekV2"
gm.TraitormodSettings = { LimitedSuicide = false }

function gm:CheckRequirements()
    for value in Game.ServerSettings.AllowedRandomMissionTypes do
        if value == self.MissionType then return true end
    end
    return false
end

local function cleanRemove(character)
    if not character or character.Removed then return end
    local pos = character.WorldPosition
    if character.Inventory then
        for item in character.Inventory.AllItems do
            Entity.Spawner.AddItemToRemoveQueue(item)
        end
    end
    character.DespawnNow()
    for _, item in pairs(Item.ItemList) do
        if item.Prefab.Identifier.Value == "duffelbag" and Vector2.Distance(item.WorldPosition, pos) < 10 then
            Entity.Spawner.AddItemToRemoveQueue(item)
        end
    end
end

local function colorTeamClothes(character, team)
    local innerClothes = character.Inventory.GetItemInLimbSlot(InvSlotType.InnerClothes)
    if innerClothes then
        innerClothes.SpriteColor = team.Color
        local color = innerClothes.SerializableProperties[Identifier("SpriteColor")]
        Networking.CreateEntityEvent(innerClothes, Item.ChangePropertyEventData(color, innerClothes))
    end
end

local function spawnCharacter(client, team, entry)
    if client.CharacterInfo == nil then
        if not entry.CharacterInfoErrorLogged then
            entry.CharacterInfoErrorLogged = true
            Traitormod.Error("HideAndSeekV2: cannot spawn %s because CharacterInfo is nil", client.Name)
        end
        return false
    end

    local spawnPoint = team.Spawns[math.random(1, #team.Spawns)]
    local characterInfo = client.CharacterInfo
    characterInfo.Job = Job(JobPrefab.Get(entry.JobId or "assistant"), true)
    characterInfo.TeamID = team.TeamID

    local character = Character.Create(characterInfo, spawnPoint.WorldPosition, characterInfo.Name, 0, true, true)
    client.SetClientCharacter(character)
    textPromptUtils.UnlockOption(client)
    entry.OnSpawn(character, spawnPoint)
    colorTeamClothes(character, team)
    entry.Spawned = true
    return true
end

local function sendCountdown(languageKey, seconds)
    for _, client in pairs(Client.ClientList) do
        Traitormod.SendChatMessage(client, Traitormod.FormatText(languageKey, math.max(math.ceil(seconds), 0)), Color.GreenYellow)
    end
end

local function sendStatus(languageKey, ...)
    local text = Traitormod.FormatText(languageKey, ...)
    for _, client in pairs(Client.ClientList) do
        Traitormod.SendChatMessage(client, text, Color.GreenYellow)
    end
end

local function syncItemProperty(item, propertyName)
    local property = item.SerializableProperties[Identifier(propertyName)]
    Networking.CreateEntityEvent(item, Item.ChangePropertyEventData(property, item))
end

local function getSeekerCount(playerCount)
    if playerCount < 2 then return 0 end
    return math.max(1, math.floor(playerCount / 4))
end

local function shuffle(clients)
    for i = #clients, 2, -1 do
        local j = math.random(i)
        clients[i], clients[j] = clients[j], clients[i]
    end
end

---@param client Barotrauma.Networking.Client
function gm:_SetNewClient(client, lockClassSelection)
    local character = client.Character
    Timer.Wait(function()
        if not Game.RoundStarted or Traitormod.SelectedGamemode ~= self or self.IsEnding then return end
        if not client or not client.Connection or client.Connection.Status ~= 1 or client.SpectateOnly then return end
        client.SetClientCharacter(nil)
        cleanRemove(character)

        if lockClassSelection then
            textPromptUtils.LockOption(client, Traitormod.Language.PointshopCancel)
        end

        local function openClassSelection()
            if not Game.RoundStarted or Traitormod.SelectedGamemode ~= self or self.IsEnding then return end
            if not client.Connection or client.Connection.Status ~= 1 or client.SpectateOnly then return end
            for _, team in pairs(self.Teams) do
                local entry = team.Respawns[client.AccountId]
                if entry ~= nil and entry.Forfeited then return end
            end

            if not client.InGame then
                Timer.Wait(openClassSelection, 1000)
                return
            end

            if Traitormod.Pointshop.OpenGuiOrFallback ~= nil then
                Traitormod.Pointshop.OpenGuiOrFallback(client, false)
            else
                Traitormod.Pointshop.ShowCategory(client, true)
            end
        end

        openClassSelection()
    end, 1250)
end

function gm:_ChangeTeam(client, teamID)
    local team = self.Teams[teamID]
    local id = client.AccountId
    team.Members[id] = client
    team.Respawns[id] = { Spawned = false }
    client.TeamID = teamID
    client.PreferredTeam = teamID
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

    local toTeamID = fromTeamID == TeamID1 and TeamID2 or TeamID1
    self.Teams[fromTeamID].Members[id] = nil
    self.Teams[fromTeamID].Respawns[id] = nil
    self.DisconnectedAt[id] = nil

    self:_ChangeTeam(client, toTeamID)
    self:_SetNewClient(client)
    return toTeamID
end

function gm:_AssignTeams(clients)
    local teams = {
        [TeamID1] = {},
        [TeamID2] = {},
    }
    local preferredHiders = {}
    local preferredSeekers = {}
    local unassigned = {}

    for _, client in ipairs(clients) do
        if client.PreferredTeam == TeamID2 then
            table.insert(preferredSeekers, client)
        elseif client.PreferredTeam == TeamID1 then
            table.insert(preferredHiders, client)
        else
            table.insert(unassigned, client)
        end
    end

    shuffle(preferredSeekers)
    shuffle(unassigned)
    shuffle(preferredHiders)

    local seekerCount = getSeekerCount(#clients)
    local pools = { preferredSeekers, unassigned, preferredHiders }
    for _, pool in ipairs(pools) do
        while #teams[TeamID2] < seekerCount and #pool > 0 do
            table.insert(teams[TeamID2], table.remove(pool))
        end
    end
    for _, pool in ipairs(pools) do
        for _, client in ipairs(pool) do
            table.insert(teams[TeamID1], client)
        end
    end

    for teamID, members in pairs(teams) do
        for _, client in ipairs(members) do
            self:_ChangeTeam(client, teamID)
        end
    end
end

function gm:_IsPlayerReady(team, id)
    local entry = team.Respawns[id]
    local member = team.Members[id]
    return entry ~= nil and not entry.Forfeited
        and member ~= nil and member.Connection ~= nil and not member.SpectateOnly and member.InGame
        and entry.Spawned
        and member.Character ~= nil and member.Character.IsHuman and not member.Character.IsDead
end

function gm:_AllPlayersSpawned()
    local playerCount = { [TeamID1] = 0, [TeamID2] = 0 }

    for teamID, team in pairs(self.Teams) do
        for id, entry in pairs(team.Respawns) do
            if not entry.Forfeited then
                playerCount[teamID] = playerCount[teamID] + 1
                if not self:_IsPlayerReady(team, id) then
                    return false
                end
            end
        end
    end

    if Traitormod.Config.TestMode then
        return playerCount[TeamID1] + playerCount[TeamID2] > 0
    end

    return playerCount[TeamID1] > 0 and playerCount[TeamID2] > 0
end

function gm:_ForfeitPlayer(team, id, messageKey)
    local entry = team.Respawns[id]
    if entry == nil or entry.Forfeited then return end

    entry.Forfeited = true
    self.DisconnectedAt[id] = nil

    local disconnectedCharacter = entry.DisconnectedCharacter
    entry.DisconnectedCharacter = nil

    local member = team.Members[id]
    if member ~= nil then
        textPromptUtils.UnlockOption(member)
    end
    if messageKey ~= nil then
        sendStatus(messageKey, member ~= nil and member.Name or tostring(id))
    end

    if member == nil then
        cleanRemove(disconnectedCharacter)
        return
    end

    local character = member.Character
    if member.Connection ~= nil then
        member.SetClientCharacter(nil)
    end
    cleanRemove(character)
    if disconnectedCharacter ~= character then
        cleanRemove(disconnectedCharacter)
    end
end

function gm:_RefreshReconnectedPlayers()
    for _, team in pairs(self.Teams) do
        for id, entry in pairs(team.Respawns) do
            local member = team.Members[id]
            if not entry.Forfeited and self.DisconnectedAt[id] ~= nil
                and member ~= nil and member.Connection ~= nil and member.InGame
                and (not entry.Spawned or member.Character ~= nil) then
                self.DisconnectedAt[id] = nil
                entry.DisconnectedCharacter = nil
            end
        end
    end
end

function gm:_ExpireDisconnectedPlayers()
    local now = Timer.GetTime()
    local changed = false

    for _, team in pairs(self.Teams) do
        for id, entry in pairs(team.Respawns) do
            local disconnectedAt = self.DisconnectedAt[id]
            if not entry.Forfeited and disconnectedAt ~= nil
                and now - disconnectedAt >= self.ReconnectGraceSeconds then
                self:_ForfeitPlayer(team, id, "HideAndSeekReconnectForfeit")
                changed = true
            end
        end
    end

    return changed
end

function gm:_ExpireClassSelection()
    if self.CountdownStarted or self.ClassSelectionExpired
        or Timer.GetTime() < self.ClassSelectionDeadline then
        return false
    end

    self.ClassSelectionExpired = true
    for _, team in pairs(self.Teams) do
        for id, entry in pairs(team.Respawns) do
            if not entry.Forfeited and not self:_IsPlayerReady(team, id) then
                self:_ForfeitPlayer(team, id, "HideAndSeekClassSelectionForfeit")
            end
        end
    end

    return true
end

function gm:_GetParticipantCount(teamID)
    local count = 0
    for _, entry in pairs(self.Teams[teamID].Respawns) do
        if not entry.Forfeited then
            count = count + 1
        end
    end
    return count
end

function gm:_CheckForfeitWinner()
    local hiderCount = self:_GetParticipantCount(TeamID1)
    local seekerCount = self:_GetParticipantCount(TeamID2)

    if hiderCount == 0 and seekerCount == 0 then
        sendStatus("HideAndSeekBothTeamsForfeited")
        self.IsEnding = true
        Game.GameSession.WinningTeam = CharacterTeamType.None
        Game.EndGame()
        return true
    end
    if hiderCount == 0 then
        sendStatus("HideAndSeekHidersForfeited")
        self:_FinishRound(TeamID2)
        return true
    end
    if seekerCount == 0 then
        sendStatus("HideAndSeekSeekersForfeited")
        self:_FinishRound(TeamID1)
        return true
    end
    return false
end

function gm:_HasAliveHiders()
    local team = self.Teams[TeamID1]
    local now = Timer.GetTime()

    for id, member in pairs(team.Members) do
        local entry = team.Respawns[id]
        if entry ~= nil and not entry.Forfeited and entry.Spawned then
            local character = member.Character or entry.DisconnectedCharacter
            if character ~= nil and character.IsHuman and not character.IsDead then
                if member.Connection ~= nil and member.InGame and member.Character ~= nil then
                    return true
                end

                local disconnectedAt = self.DisconnectedAt[id]
                if disconnectedAt ~= nil and now - disconnectedAt < self.ReconnectGraceSeconds then
                    return true
                end
            end
        end
    end

    return false
end

function gm:_GetAliveHiders()
    local survivors = {}
    for id, member in pairs(self.Teams[TeamID1].Members) do
        local entry = self.Teams[TeamID1].Respawns[id]
        if entry ~= nil and not entry.Forfeited
            and member.Connection ~= nil and member.InGame and entry.Spawned
            and member.Character ~= nil and member.Character.IsHuman and not member.Character.IsDead then
            table.insert(survivors, member)
        end
    end
    return survivors
end

function gm:_SetGates(open)
    for _, gate in ipairs(self.Gates) do
        gate.Item.NonInteractable = not open
        syncItemProperty(gate.Item, "NonInteractable")
        gate.Door.TrySetState(open, false, true)
    end
end

function gm:_Award(client, amount)
    local points = Traitormod.AwardPoints(client, amount)
    Traitormod.SendMessage(client, string.format(Traitormod.Language.ReceivedPoints, points), "InfoFrameTabButton.Mission")
end

function gm:_FinishRound(winningTeam)
    if self.IsEnding then return end
    self.IsEnding = true
    Game.GameSession.WinningTeam = winningTeam

    for mission in Game.GameSession.Missions do
        if mission.Prefab.Type == self.MissionType then
            mission.State = winningTeam --[[@as number]]
        end
    end

    if Traitormod.Config.TestMode then return end

    if winningTeam == TeamID2 then
        for _, member in pairs(self.Teams[TeamID2].Members) do
            if member.Connection ~= nil and member.InGame then
                self:_Award(member, math.floor(self.WinningPointsRed * self.RewardMultiplier))
            end
        end
        return
    end

    local survivors = self:_GetAliveHiders()
    if #survivors == 0 then return end

    table.sort(survivors, function(a, b)
        return tostring(a.AccountId) < tostring(b.AccountId)
    end)

    local rewardPool = math.floor(self.WinningPointsBlue * self.RewardMultiplier)
    local rewardPerPlayer = math.floor(rewardPool / #survivors)
    local remainder = rewardPool - rewardPerPlayer * #survivors

    for index, member in ipairs(survivors) do
        self:_Award(member, rewardPerPlayer + (index <= remainder and 1 or 0))
    end
end

function gm:PreStart()
    Traitormod.Pointshop.Initialize(self.PointshopCategories or {})

    self.IsEnding = false
    self.CountdownStarted = false
    self.RoundActive = false
    self.ClassCounters = {}
    self.ClassGroupCounters = {}
    self.Gates = {}
    self.DisconnectedAt = {}
    self.CriticalTimers = {}
    self.ClassSelectionExpired = false
    self.ClassSelectionAnnounced = false

    self.Teams = {
        [TeamID1] = {
            Name = Traitormod.GetText("HideAndSeekHiderTeamName"),
            Spawns = {},
            Members = {},
            Respawns = {},
            TeamID = TeamID1,
            Color = Color.Blue,
        },
        [TeamID2] = {
            Name = Traitormod.GetText("HideAndSeekSeekerTeamName"),
            Spawns = {},
            Members = {},
            Respawns = {},
            TeamID = TeamID2,
            Color = Color.Red,
        }
    }

    Hook.Add("character.applyDamage", "Traitormod.HideAndSeekV2.SeekerDamage", function(characterHealth, attackResult, hitLimb, allowStacking)
        local character = characterHealth.Character
        if self.IsEnding or character.TeamID ~= TeamID2 then return end

        for affliction in attackResult.Afflictions do
            if affliction.Prefab.AfflictionType == AfflictionPrefab.StunType then
                characterHealth.ApplyAffliction(hitLimb, affliction, allowStacking)
            end
        end
        return true
    end)

    Hook.Add("character.applyAffliction", "Traitormod.HideAndSeekV2.SeekerNeurotrauma", function(characterHealth, _, affliction)
        if self.IsEnding or characterHealth.Character.TeamID ~= TeamID2 then return end
        if affliction.Prefab.ContentPackage.Name == "Neurotrauma" then
            return true
        end
    end)
end

function gm:Start()
    Traitormod.DisableRespawnShuttle = true
    Traitormod.DisableMidRoundSpawn = true

    local outpost = Game.GameSession.Level.StartOutpost
    local subConfig = Traitormod.ParseSubmarineConfig(outpost.Info.Description.Value)
    for key, value in pairs(subConfig) do
        self[key] = value
    end

    self.StartCountDown = self.StartDelayMinutes * 60
    self.RoundCountDown = self.RoundDurationMinutes * 60
    self.ClassSelectionDeadline = Timer.GetTime() + self.ClassSelectionTimeoutMinutes * 60
    self.LastStartCountDown = self.StartCountDown
    self.LastRoundCountDown = self.RoundCountDown

    for _, waypoint in pairs(outpost.GetWaypoints(true)) do
        for tag in waypoint.Tags do
            if tag == "hideandseekteam1" then
                table.insert(self.Teams[TeamID1].Spawns, waypoint)
            elseif tag == "hideandseekteam2" then
                table.insert(self.Teams[TeamID2].Spawns, waypoint)
            end
        end
    end

    for _, item in pairs(outpost.GetItems(false)) do
        if item.HasTag("hideandseekgate") then
            local door = item.GetComponentString("Door")
            if door ~= nil then
                table.insert(self.Gates, { Item = item, Door = door })
            end
        end
    end

    if #self.Teams[TeamID1].Spawns == 0 then
        Traitormod.Error("HideAndSeekV2: no hideandseekteam1 spawn points on selected outpost")
    end
    if #self.Teams[TeamID2].Spawns == 0 then
        Traitormod.Error("HideAndSeekV2: no hideandseekteam2 spawn points on selected outpost")
    end
    if #self.Gates == 0 then
        Traitormod.Error("HideAndSeekV2: no hideandseekgate item on selected outpost")
    end

    self:_SetGates(false)

    local clients = {}
    for client in Client.ClientList do
        if not client.SpectateOnly and (not client.AFK or not Game.ServerSettings.AllowAFK) then
            table.insert(clients, client)
        end
    end

    Traitormod.Config.TestMode = #clients == 1
    self.RewardMultiplier = #clients < 4 and 0.5 or 1
    if Traitormod.Config.TestMode then
        Traitormod.SendMessageEveryone(Traitormod.Language.TestingMode)
        Traitormod.SendMessageEveryone(Traitormod.GetText("CMDSwitchTestAvailable"))
    end

    self:_AssignTeams(clients)
    for _, client in ipairs(clients) do
        self:_SetNewClient(client, true)
    end

    Hook.Add("client.connected", "Traitormod.HideAndSeekV2.ClientConnected", function(client)
        if client.SpectateOnly then return end
        for _, team in pairs(self.Teams) do
            local entry = team.Respawns[client.AccountId]
            if entry ~= nil then
                if entry.Forfeited then return end

                team.Members[client.AccountId] = client
                client.TeamID = team.TeamID
                client.PreferredTeam = team.TeamID
                if not entry.Spawned then
                    self:_SetNewClient(client)
                end
                return
            end
        end
    end)

    Hook.Add("clientDisconnected", "Traitormod.HideAndSeekV2.ClientDisconnected", function(client)
        for _, team in pairs(self.Teams) do
            local entry = team.Respawns[client.AccountId]
            if entry ~= nil and not entry.Forfeited then
                self.DisconnectedAt[client.AccountId] = Timer.GetTime()
                entry.DisconnectedCharacter = client.Character
                sendStatus("HideAndSeekReconnectStarted", client.Name, math.floor(self.ReconnectGraceSeconds))
                return
            end
        end
    end)

    Hook.Add("netMessageReceived", "Traitormod.HideAndSeekV2.ClientJoined", function(msg, header, client)
        if header ~= ClientPacketHeader.UPDATE_INGAME or client.InGame or client.SpectateOnly then return end

        for _, team in pairs(self.Teams) do
            local entry = team.Respawns[client.AccountId]
            if entry ~= nil then
                if not entry.Forfeited then
                    team.Members[client.AccountId] = client
                    client.TeamID = team.TeamID
                    client.PreferredTeam = team.TeamID
                end
                return
            end
        end
    end)
end

function gm:End()
    self.IsEnding = true
    for _, team in pairs(self.Teams) do
        for _, member in pairs(team.Members) do
            textPromptUtils.UnlockOption(member)
        end
    end

    Hook.Remove("client.connected", "Traitormod.HideAndSeekV2.ClientConnected")
    Hook.Remove("clientDisconnected", "Traitormod.HideAndSeekV2.ClientDisconnected")
    Hook.Remove("character.applyDamage", "Traitormod.HideAndSeekV2.SeekerDamage")
    Hook.Remove("character.applyAffliction", "Traitormod.HideAndSeekV2.SeekerNeurotrauma")
    Hook.Remove("netMessageReceived", "Traitormod.HideAndSeekV2.ClientJoined")

    if self.Gates ~= nil then
        self:_SetGates(true)
    end
end

function gm:Think(deltaTime)
    if self.IsEnding then return end

    for _, team in pairs(self.Teams) do
        for id, entry in pairs(team.Respawns) do
            local member = team.Members[id]
            if not entry.Forfeited and member ~= nil and member.Connection ~= nil and not member.SpectateOnly
                and member.InGame and not entry.Spawned and entry.OnSpawn ~= nil then
                spawnCharacter(member, team, entry)
            end
        end
    end

    if not Traitormod.Config.TestMode and not self.CountdownStarted and not self.ClassSelectionAnnounced then
        for _, team in pairs(self.Teams) do
            for _, member in pairs(team.Members) do
                if member.Connection ~= nil and member.InGame then
                    self.ClassSelectionAnnounced = true
                    sendCountdown("HideAndSeekClassSelectionStarted", self.ClassSelectionDeadline - Timer.GetTime())
                    break
                end
            end
            if self.ClassSelectionAnnounced then break end
        end
    end

    self:_RefreshReconnectedPlayers()
    if not Traitormod.Config.TestMode then
        local disconnectedExpired = self:_ExpireDisconnectedPlayers()
        local classSelectionExpired = self:_ExpireClassSelection()
        if (disconnectedExpired or classSelectionExpired) and self:_CheckForfeitWinner() then return end
    end

    if not self.CountdownStarted then
        if self:_AllPlayersSpawned() then
            self.CountdownStarted = true
            sendCountdown("HideAndSeekCountdownStarted", self.StartCountDown)
        end
        return
    end

    if not self.RoundActive then
        self.StartCountDown = self.StartCountDown - deltaTime
        local interval = self.StartCountDown <= 10 and 1 or 30
        if self.StartCountDown > 0 and self.LastStartCountDown - self.StartCountDown >= interval then
            sendCountdown("HideAndSeekStartCountdown", self.StartCountDown)
            self.LastStartCountDown = self.StartCountDown
        end

        if self.StartCountDown <= 0 then
            self.RoundActive = true
            self:_SetGates(true)
            sendCountdown("HideAndSeekRoundStarted", self.RoundCountDown)
        end
        return
    end

    for _, team in pairs(self.Teams) do
        for id, entry in pairs(team.Respawns) do
            local member = team.Members[id]
            local character = member ~= nil and member.Character or entry.DisconnectedCharacter
            if not entry.Forfeited and entry.Spawned
                and character ~= nil and character.IsHuman and not character.IsDead
                and character.IsUnconscious then
                self.CriticalTimers[id] = (self.CriticalTimers[id] or 0) + deltaTime
                if self.CriticalTimers[id] >= 60 then
                    self.CriticalTimers[id] = nil
                    character.Kill(CauseOfDeathType.Unknown)
                end
            else
                self.CriticalTimers[id] = nil
            end
        end
    end

    if not Traitormod.Config.TestMode and not self:_HasAliveHiders() then
        self:_FinishRound(TeamID2)
        return
    end

    self.RoundCountDown = self.RoundCountDown - deltaTime
    local interval = self.RoundCountDown <= 10 and 1 or 60
    if self.RoundCountDown > 0 and self.LastRoundCountDown - self.RoundCountDown >= interval then
        sendCountdown("HideAndSeekRoundCountdown", self.RoundCountDown)
        self.LastRoundCountDown = self.RoundCountDown
    end

    if self.RoundCountDown <= 0 then
        self:_FinishRound(TeamID1)
    end
end

return gm
