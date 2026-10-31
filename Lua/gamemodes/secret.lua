local weightedRandom = dofile(Traitormod.Path .. "/Lua/gamemodes/weightedrandom.lua")
local gm = Traitormod.Gamemodes.Gamemode:new()

if not LuaUserData.IsRegistered("Barotrauma.CheckDataAction") then LuaUserData.RegisterType("Barotrauma.CheckDataAction") end
local gameServerDescriptor = Descriptors["Barotrauma.Networking.GameServer"] or LuaUserData.RegisterType("Barotrauma.Networking.GameServer")
local transitionTypes = LuaUserData.CreateEnumTable("Barotrauma.CampaignMode+TransitionType")
local voteTypes = LuaUserData.CreateEnumTable("Barotrauma.Networking.VoteType")
LuaUserData.MakePropertyAccessible(gameServerDescriptor, "EndRoundTimer")

local summaryNetMessage = "VoidTraitor_RoundSummary"
local lobbySummaryPending = nil
local missionDescriptors = {}

gm.Name = "Secret"

local function missionWouldComplete(mission, transitionType)
    if mission == nil or mission.ForceFailure then return false end
    if mission.Completed then return true end

    local typeName = LuaUserData.TypeOf(mission)
    if not missionDescriptors[typeName] then
        local descriptor = Descriptors[typeName] or LuaUserData.RegisterType(typeName)
        LuaUserData.MakeMethodAccessible(descriptor, "DetermineCompleted", {"Barotrauma.CampaignMode+TransitionType"})
        LuaUserData.MakeFieldAccessible(descriptor, "completeCheckDataAction")
        missionDescriptors[typeName] = true
    end

    if not mission.DetermineCompleted(transitionType or transitionTypes.None) then return false end

    local completeCheck = mission.completeCheckDataAction
    return completeCheck == nil or completeCheck.GetSuccess()
end

local function getCampaignTransition()
    if Game.GameSession == nil or Game.GameSession.GameMode == nil then
        return nil, transitionTypes.None
    end

    local gameMode = Game.GameSession.GameMode
    if not LuaUserData.IsTargetType(gameMode, "Barotrauma.CampaignMode") then
        return nil, transitionTypes.None
    end

    return gameMode, gameMode.GetAvailableTransition()
end

local function reachedLevelEnd()
    local mainSub = Submarine.MainSub
    local level = Level.Loaded
    if mainSub == nil or level == nil then return false end

    local endOutpost = level.EndOutpost
    if endOutpost == nil then
        return mainSub.AtEndExit
    end

    local charactersInsideOutpost = 0
    local charactersOutsideOutpost = 0
    for _, client in pairs(Client.ClientList) do
        local character = client.Character
        if character ~= nil and not character.IsDead and not character.IsUnconscious then
            if character.Submarine == endOutpost then
                charactersInsideOutpost = charactersInsideOutpost + 1
            else
                charactersOutsideOutpost = charactersOutsideOutpost + 1
            end
        end
    end

    for dockedSub in mainSub.DockedTo do
        if dockedSub == endOutpost then return true end
    end

    return (mainSub.AtEndExit and charactersInsideOutpost > 0)
        or charactersInsideOutpost > charactersOutsideOutpost
end


local function sendSummaryPopup(client, summary)
    if Traitormod.ClientHasLua ~= nil and Traitormod.ClientHasLua(client) then
        local message = Networking.Start(summaryNetMessage)
        message.WriteString(Traitormod.HighlightClientNames(summary, Color.Red))
        Networking.Send(message, client.Connection)
    else
        local chatMessage = ChatMessage.Create(Traitormod.GetText("ChatSenderServer"), summary, ChatMessageType.ServerMessageBox, nil, nil)
        Game.SendDirectChatMessage(chatMessage, client)
    end
end

function gm:CharacterDeath(character)
    if self.Ending then return end
    local client = Traitormod.FindClientCharacter(character)

    -- if character is valid player
    if client == nil or
        character == nil or
        character.IsHuman == false or
        character.ClientDisconnected == true or
        character.TeamID == 0 then
        return
    end

    local accountKey = Traitormod.GetClientAccountKey(client)
    if self.InitialCrew ~= nil and self.InitialCrew[accountKey] then
        self.InitialCrewDeaths[accountKey] = true
    end

    if Traitormod.RoundTime < Traitormod.Config.MinRoundTimeToLooseLives then
        return
    end

    if Traitormod.LostLivesThisRound[accountKey] == nil then
        Traitormod.LostLivesThisRound[accountKey] = true
    else
        return
    end

    local liveMsg, liveIcon = Traitormod.AdjustLives(client, -1)

    Traitormod.SendMessage(client, liveMsg, liveIcon)
end

function gm:Start()
    local this = self

    self.Ending = false
    self.ResultsFinalized = false
    self.AllowRealEndGame = false
    self.EndReason = nil
    self.EndTransitionType = transitionTypes.None
    self.EndViaCampaignTransition = false
    self.EndTransitionStarted = false
    self.FinalSummary = nil
    self.AwardedPoints = {}
    self.InitialCrew = {}
    self.InitialCrewDeaths = {}
    for _, client in pairs(Client.ClientList) do
        local character = client.Character
        if character ~= nil
            and character.IsHuman
            and not client.SpectateOnly
            and character.TeamID == CharacterTeamType.Team1
        then
            self.InitialCrew[Traitormod.GetClientAccountKey(client)] = true
        end
    end
    lobbySummaryPending = nil

    if self.EnableRandomEvents then
        Traitormod.RoundEvents.Initialize()
    end

    Hook.Add("characterDeath", "Traitormod.Secret.CharacterDeath", function(character, affliction)
        this:CharacterDeath(character)
    end)

    self:SelectAntagonists()
end

function gm:AssignAntagonists(antagonists)
    local function AssignCrew()
        for key, value in pairs(Client.ClientList) do
            if value.Character ~= nil and value.Character.IsHuman and not value.SpectateOnly and not value.Character.IsDead and value.Character.TeamID == CharacterTeamType.Team1 then
                local role = Traitormod.RoleManager.GetRole(value.Character)
                if role == nil then
                    role = Traitormod.RoleManager.Roles["Crew"]
                    Traitormod.RoleManager.AssignRole(value.Character, role:new())
                end
            end
        end

        Hook.Add("traitormod.midroundspawn", "Traitormod.Secret.MidRoundSpawn", function (client, character)
            local role = Traitormod.RoleManager.GetRole(character)
            if role == nil then
                role = Traitormod.RoleManager.Roles["Crew"]
                Traitormod.RoleManager.AssignRole(character, role:new())
            end
        end)
    end

    local function Assign(roles)
        for key, role in pairs(roles) do
            if role.Name == "Cultist" then
                self.RoundEndIcon = "oneofus"
                Game.EnableControlHusk(true)
            end
        end

        local newRoles = {}

        for key, value in pairs(antagonists) do
            table.insert(newRoles, roles[key]:new())
        end

        Traitormod.RoleManager.AssignRoles(antagonists, newRoles)

        for _, character in pairs(antagonists) do
            local role = Traitormod.RoleManager.GetRole(character)
            if role ~= nil and role.IsAntagonist then
                local client = Traitormod.FindClientCharacter(character)
                if client ~= nil then
                    self.InitialCrew[Traitormod.GetClientAccountKey(client)] = nil
                end
            end
        end

        AssignCrew()
    end

    if self.TraitorTypeSelectionMode == "Random" then
        local role = Traitormod.RoleManager.Roles[weightedRandom.Choose(self.TraitorTypeChance)]

        local roles = {}
        for key, value in pairs(antagonists) do
            table.insert(roles, role)
        end
        Assign(roles)
    else
        local options = {}
        for key, value in pairs(self.TraitorTypeChance) do
            table.insert(options, key)
        end

        local clients = {}

        for key, value in pairs(antagonists) do
            local client = Traitormod.FindClientCharacter(value)
            if client then
                table.insert(clients, client)
            end
        end

        if #clients == 0 then
            Assign({})
            return
        end

        Traitormod.Voting.StartVote(Traitormod.Language.SecretTraitorAssigned, options, 25, function (results, clientVotes)
            local highestVoted = nil
            local highestedVotedRole = nil
            for key, value in pairs(options) do
                if highestVoted == nil or results[key] > highestVoted then
                    highestVoted = results[key]
                    highestedVotedRole = value
                end
            end

            local roles = {}
            for key, value in pairs(clientVotes) do
                local role = ""
                if value == -1 then
                    role = Traitormod.RoleManager.Roles[highestedVotedRole]
                else
                    role = Traitormod.RoleManager.Roles[options[value]]
                end

                table.insert(roles, role)
            end
            Assign(roles)
        end, clients)
    end
end

function gm:SelectAntagonists()
    local this = self
    local thisRoundNumber = Traitormod.RoundNumber

    local delay = math.random(self.TraitorSelectDelayMin, self.TraitorSelectDelayMax)

    Timer.Wait(function()
        if thisRoundNumber ~= Traitormod.RoundNumber or not Game.RoundStarted then return end

        local clientWeight = {}
        local traitorChoices = 0
        local playerInGame = 0
        for key, value in pairs(Client.ClientList) do
            -- valid traitor choices must be ingame, player was spawned before (has a character), is no spectator
            if value.InGame and value.Character and not value.SpectateOnly then
                -- filter by config
                if this.TraitorFilter(value) > 0 and Traitormod.GetData(value, "NonTraitor") ~= true then
                    -- players are alive or if respawning is on and config allows dead traitors (not supported yet)
                    if not value.Character.IsDead and Traitormod.RoleManager.GetRole(value.Character) == nil then
                        clientWeight[value] = (Traitormod.GetData(value, "Weight") or 0) * this.TraitorFilter(value)
                        traitorChoices = traitorChoices + 1
                    end
                end
                playerInGame = playerInGame + 1
            end
        end

        if traitorChoices == 0 then
            this:AssignAntagonists({})
            Traitormod.Log("No players to assign traitors")
            return
        end

        local amountTraitors = this.AmountTraitors(playerInGame)
        if amountTraitors > traitorChoices then
            amountTraitors = traitorChoices
            Traitormod.Log("Not enough valid players to assign all traitors... New amount: " .. tostring(amountTraitors))
        end

        local antagonists = {}

        for i = 1, amountTraitors, 1 do
            local index = weightedRandom.Choose(clientWeight)

            if index ~= nil then
                Traitormod.Log("Chose " ..
                    index.Character.Name .. " as traitor. Weight: " .. math.floor(clientWeight[index] * 100) / 100)

                table.insert(antagonists, index.Character)

                clientWeight[index] = nil

                Traitormod.SetData(index, "Weight", 0)
            end
        end

        self:AssignAntagonists(antagonists)
    end, delay * 1000)
end

function gm:AwardCrew(missions, transitionType)
    local missionReward = 0
    local failedMissionReward = 0
    local missionCompleted = false
    for _, mission in pairs(missions or {}) do
        local missionValue = self.MissionPoints.Default

        for key, value in pairs(self.MissionPoints) do
            if key == mission.Prefab.Type then
                missionValue = value
            end
        end

        if missionWouldComplete(mission, transitionType) then
            missionReward = missionReward + missionValue
            missionCompleted = true
        else
            failedMissionReward = failedMissionReward + missionValue
        end
    end

    if self.MissionEndAdditionalReward then
        missionReward = missionReward + self.MissionEndAdditionalReward()
    end

    local initialCrewCount = 0
    local deadInitialCrewCount = 0
    for accountKey in pairs(self.InitialCrew or {}) do
        initialCrewCount = initialCrewCount + 1
        if self.InitialCrewDeaths[accountKey] then
            deadInitialCrewCount = deadInitialCrewCount + 1
        end
    end

    local survivorReward = 0
    if self.SurvivorRewardEnabled
        and not missionCompleted
        and failedMissionReward > 0
        and initialCrewCount > 0
        and deadInitialCrewCount < initialCrewCount
        and deadInitialCrewCount / initialCrewCount * 100 >= self.SurvivorRewardRequiredDeathsPercent
    then
        survivorReward = math.floor(failedMissionReward * self.SurvivorRewardPercent / 100)
    end

    local reachedEnd = self.EndReason == "crew"
    for key, value in pairs(Client.ClientList) do
        if value.Character ~= nil
            and value.Character.IsHuman
            and not value.SpectateOnly
            and not value.Character.IsDead
            and value.Character.TeamID == CharacterTeamType.Team1
        then
            local role = Traitormod.RoleManager.GetRole(value.Character)

            local wasAntagonist = false
            if role ~= nil then
                wasAntagonist = role.IsAntagonist
            end

            -- if client was no traitor and the crew reached the destination, gain a live
            if not wasAntagonist and reachedEnd then
                local msg = ""

                -- award points for mission completion
                if missionReward > 0 then
                    local points = Traitormod.AwardPoints(value, missionReward
                        , true)
                    msg = msg ..
                        Traitormod.Language.CrewWins ..
                        " " .. string.format(Traitormod.Language.PointsAwarded, points) .. "\n\n"
                end

                local lifeMsg, icon = Traitormod.AdjustLives(value,
                    (self.LivesGainedFromCrewMissionsCompleted or 1))
                if lifeMsg then
                    msg = msg .. lifeMsg .. "\n\n"
                end

                if msg ~= "" then
                    Traitormod.SendMessage(value, msg, icon)
                end
            end

            local accountKey = Traitormod.GetClientAccountKey(value)
            if survivorReward > 0
                and self.InitialCrew ~= nil
                and self.InitialCrew[accountKey]
                and reachedEnd
                and (role == nil or not role.IsAntagonist)
            then
                local points = Traitormod.AwardPoints(value, survivorReward, true)
                Traitormod.SendMessage(value, string.format(Traitormod.Language.PointsAwarded, points),
                    "InfoFrameTabButton.Mission")
            end
        end
    end
end

function gm:CheckHandcuffedTraitors(character)
    if character.IsDead then return end
    
    local item = character.Inventory.GetItemInLimbSlot(InvSlotType.RightHand)
    if item ~= nil and item.Prefab.Identifier == "handcuffs" then
        for key, value in pairs(Client.ClientList) do
            local role = Traitormod.RoleManager.GetRole(value.Character)
            if (role == nil or not role.IsAntagonist) and value.Character and not value.Character.IsDead and value.Character.TeamID == CharacterTeamType.Team1 then
                local points = Traitormod.AwardPoints(value, self.PointsGainedFromHandcuffedTraitors)
                local text = string.format(Traitormod.Language.TraitorHandcuffed, character.Name)
                text = text .. "\n\n" .. string.format(Traitormod.Language.PointsAwarded, points)
                Traitormod.SendMessage(value, text, "InfoFrameTabButton.Mission")
            end
        end
    end
end

function gm:TraitorResults()
    local success = false

    local sb = Traitormod.StringBuilder:new()

    local antagonists = {}
    for character, role in pairs(Traitormod.RoleManager.RoundRoles) do
        if role.IsAntagonist then
            table.insert(antagonists, character)
        end

        if role.IsAntagonist then
            sb("%s %s", role.Name, character.Name)
            sb("\n")

            local objectives = 0
            local pointsGained = 0

            for key, value in pairs(role.Objectives) do
                if not value.Failed and (value:IsCompleted() or value.Awarded) then
                    objectives = objectives + 1
                    pointsGained = pointsGained + value.AmountPoints
                end
            end

            if objectives > 0 then
                success = true
            end

            sb(Traitormod.Language.SecretSummary, objectives, pointsGained)
        end
    end

    if success then
        Traitormod.Stats.AddStat("Rounds", "Traitor rounds won", 1)
    else
        Traitormod.Stats.AddStat("Rounds", "Crew rounds won", 1)
    end

    -- first arg = mission id, second = message, third = completed, forth = list of characters
    return {TraitorMissionResult(self.RoundEndIcon or Traitormod.MissionIdentifier, sb:concat(), success, antagonists)}
end

function gm:FinalizeResults(transitionType)
    if self.ResultsFinalized then return end

    for client, value in pairs(Traitormod.PointsToBeGiven) do
        if value > 0 then
            local points = Traitormod.AwardPoints(client, value)
            if client.Character ~= nil and Traitormod.GiveExperience(client.Character, Traitormod.Config.AmountExperienceWithPoints(points)) then
                local text = Traitormod.Language.SkillsIncreased ..
                    "\n" .. string.format(Traitormod.Language.PointsAwarded, math.floor(points))
                Game.SendDirectChatMessage("", text, nil, Traitormod.Config.ChatMessageType, client)
            end
            Traitormod.PointsToBeGiven[client] = 0
        end
    end

    Traitormod.RoleManager.CheckObjectives(false, true)
    Traitormod.RoleManager.CheckObjectives(true, true)

    for _, role in pairs(Traitormod.RoleManager.RoundRoles) do
        for _, objective in pairs(role.Objectives or {}) do
            if not objective.Awarded and not objective.Failed then
                objective:Fail(true)
            end
        end
    end

    for _, character in pairs(Traitormod.RoleManager.FindAntagonists()) do
        self:CheckHandcuffedTraitors(character)
    end

    local missions = Game.GameSession ~= nil and Game.GameSession.Missions or {}
    self:AwardCrew(missions, transitionType)

    Traitormod.Pointshop.FinalizeRefunds()
    Traitormod.Pointshop.Refunds = {}
    Traitormod.RoundEvents.EndRound()

    self.ResultsFinalized = true
end

function gm:RoundSummary()
    if self.FinalSummary ~= nil then return self.FinalSummary end

    local sb = Traitormod.StringBuilder:new()
    sb("%s\n", Traitormod.Language.RoundSummary)
    sb(Traitormod.Language.Gamemode, self.Name)
    sb("\n")
    sb("%s: %s\n", Traitormod.Language.DiscordFieldRound, Traitormod.RoundNumber + 1)
    sb("%s: %s\n", Traitormod.Language.DiscordFieldDuration, Traitormod.FormatTime(math.ceil(Traitormod.RoundTime)))

    local antagonistCount = 0
    local antagonistAlive = 0
    local antagonistDead = 0
    local antagonistEntries = {}

    for character, role in pairs(Traitormod.RoleManager.RoundRoles) do
        if role.IsAntagonist then
            local entry = { Character = character, Role = role }
            antagonistCount = antagonistCount + 1
            if character.IsDead then
                antagonistDead = antagonistDead + 1
            else
                antagonistAlive = antagonistAlive + 1
            end
            table.insert(antagonistEntries, entry)
        end
    end
    table.sort(antagonistEntries, function(a, b)
        return string.lower(tostring(a.Character.Name)) < string.lower(tostring(b.Character.Name))
    end)

    if Traitormod.RoundStats ~= nil then
        local distinctions = Traitormod.RoundStats.BuildSecretSummary()
        if distinctions ~= "" then
            sb("\n%s\n", distinctions)
        end
    end

    sb("\n%s %d\n", Traitormod.Language.TraitorsRound, antagonistCount)
    sb("%s: %d | %s: %d\n", Traitormod.Language.Alive, antagonistAlive, Traitormod.Language.Dead, antagonistDead)
    if antagonistCount == 0 then
        sb("%s\n", Traitormod.Language.NoTraitors)
    end

    for _, entry in ipairs(antagonistEntries) do
        local character = entry.Character
        local role = entry.Role
        local state = character.IsDead and Traitormod.Language.Dead or Traitormod.Language.Alive

        sb("\n%s — %s (%s)\n", character.Name, role.Name, state)

        local objectivesCompleted = 0
        for _, objective in ipairs(role.Objectives or {}) do
            if objective.Awarded then objectivesCompleted = objectivesCompleted + 1 end
        end
        sb(Traitormod.Language.SecretRoundObjectivesSummary, objectivesCompleted)

        for _, objective in ipairs(role.Objectives or {}) do
            local objectiveState
            if objective.Failed then
                objectiveState = Traitormod.Language.Failed
            elseif objective.Awarded then
                objectiveState = Traitormod.Language.Completed .. string.format(Traitormod.Language.Points, objective.AmountPoints or 0)
            else
                objectiveState = ""
            end
            sb(" > %s %s\n", objective.Text, string.gsub(objectiveState, "^%s+", ""))
        end
    end

    return sb:concat()
end

function gm:FinishEnding()
    if self.EndTransitionStarted or not self.Ending or not Game.RoundStarted or Traitormod.SelectedGamemode ~= self then return end

    self.EndTransitionStarted = true
    self.AllowRealEndGame = true

    if self.EndViaCampaignTransition then
        local gameMode = Game.GameSession ~= nil and Game.GameSession.GameMode or nil
        if gameMode ~= nil
            and LuaUserData.IsTargetType(gameMode, "Barotrauma.CampaignMode")
            and gameMode.GetAvailableTransition() == self.EndTransitionType
        then
            gameMode.LoadNewLevel()
            return
        end
    end

    Game.Server.EndGame(self.EndTransitionType or transitionTypes.None)
end

function gm:BeginEnding(reason, transitionType, viaCampaignTransition)
    if self.Ending or not Game.RoundStarted then return end

    self.EndTransitionType = transitionType or transitionTypes.None
    self.EndViaCampaignTransition = viaCampaignTransition == true
    self.EndReason = reason
    self:FinalizeResults(self.EndTransitionType)
    self.Ending = true
    for _, client in pairs(Client.ClientList) do
        client.SetVote(voteTypes.EndRound, false)
    end

    self.FinalSummary = self:RoundSummary()
    Traitormod.LastRoundSummary = self.FinalSummary
    lobbySummaryPending = self.FinalSummary

    local delay = self.EndGameDelaySeconds or 0
    local message = string.format(Traitormod.Language.SecretRoundEndingCountdown, delay)
    if reason == "traitors" then
        message = Traitormod.Language.TraitorsWin .. "\n" .. message
    elseif reason == "crew" then
        message = Traitormod.Language.SecretCrewReachedStation .. "\n" .. message
    end

    Traitormod.SendMessageEveryone(message)

    for _, client in pairs(Client.ClientList) do
        sendSummaryPopup(client, self.FinalSummary)
    end

    if Traitormod.Discord then
        Traitormod.Discord.AnnounceRoundEnded(Traitormod.RoundTime)
    end

    Traitormod.Log("Secret round result finalized. Ending round in " .. delay .. " seconds.")

    local endingRoundNumber = Traitormod.RoundNumber
    Timer.Wait(function ()
        if Traitormod.RoundNumber ~= endingRoundNumber or Traitormod.SelectedGamemode ~= self then return end
        self:FinishEnding()
    end, delay * 1000)
end

function gm:End()
    if not self.ResultsFinalized then
        self:FinalizeResults(self.EndTransitionType)
    end

    Game.EnableControlHusk(false)

    Hook.Remove("characterDeath", "Traitormod.Secret.CharacterDeath")
    Hook.Remove("traitormod.midroundspawn", "Traitormod.Secret.MidRoundSpawn")
end

function gm:Think()
    if not Game.RoundStarted then return end

    if self.Ending then return end

    if reachedLevelEnd() then
        local gameMode, transitionType = getCampaignTransition()
        if gameMode == nil then
            self:BeginEnding("crew", transitionTypes.None, false)
            return
        elseif transitionType ~= transitionTypes.None then
            self:BeginEnding("crew", transitionType, true)
            return
        end
    end

    if not self.EndOnComplete then return end

    local ended = true
    local anyTraitorMission = false

    for _, value in pairs(Character.CharacterList) do
        if not value.IsDead and value.IsHuman and value.TeamID == CharacterTeamType.Team1 then
            local role = Traitormod.RoleManager.GetRole(value)
            if role == nil or not role.IsAntagonist then
                ended = false
            elseif role.Objectives then
                for _, objective in pairs(role.Objectives) do
                    if objective.Name == "Assassinate" or objective.Name == "Husk" then
                        anyTraitorMission = true
                    end
                end
            end
        end
    end

    if anyTraitorMission and ended then
        self:BeginEnding("traitors", transitionTypes.None, false)
    end
end

Hook.Patch("Traitormod.Secret.LoadNewLevel.Before", "Barotrauma.CampaignMode", "LoadNewLevel", function (instance, ptable)
    local selected = Traitormod.SelectedGamemode
    if selected == nil or selected.Name ~= "Secret" or not Game.RoundStarted or selected.AllowRealEndGame then return end

    if selected.Ending then
        ptable.PreventExecution = true
        return
    end

    local transitionType = instance.GetAvailableTransition()
    if transitionType == transitionTypes.None then return end

    local reason = "manual"
    if transitionType == transitionTypes.ProgressToNextLocation
        or transitionType == transitionTypes.ProgressToNextEmptyLocation
        or transitionType == transitionTypes.End
    then
        reason = "crew"
    end

    selected:BeginEnding(reason, transitionType, true)
    ptable.PreventExecution = true
end, Hook.HookMethodType.Before)

Hook.Patch("Traitormod.Secret.EndGame.Before", "Barotrauma.Networking.GameServer", "EndGame", function (instance, ptable)
    local selected = Traitormod.SelectedGamemode
    if selected == nil or selected.Name ~= "Secret" then return end

    if selected.AllowRealEndGame then
        if selected.Ending and not selected.EndTransitionStarted then
            selected.AllowRealEndGame = false
            ptable.PreventExecution = true
            selected:FinishEnding()
        end
        return
    end

    if selected.Ending then
        instance.EndRoundTimer = 0.1
        ptable.PreventExecution = true
        return
    end

    selected:BeginEnding("manual", ptable["transitionType"] or transitionTypes.None, false)
    ptable.PreventExecution = true
end, Hook.HookMethodType.Before)

Hook.Patch("Traitormod.Secret.EndGame.After", "Barotrauma.Networking.GameServer", "EndGame", function ()
    if lobbySummaryPending == nil or Game.RoundStarted then return end

    Traitormod.SendMessageEveryone(Traitormod.HighlightClientNames(lobbySummaryPending, Color.Red))
    lobbySummaryPending = nil
end, Hook.HookMethodType.After)


return gm
