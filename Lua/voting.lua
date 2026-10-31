local vt = {}

local textPromptUtils = require("textpromptutils")

vt.Votes = {}
vt.GameVote = nil
vt.MapVote = nil
vt.GameVoteCooldownUntil = 0
vt.MapVoteCooldownUntil = 0

local serverSettingsDescriptor = Descriptors["Barotrauma.Networking.ServerSettings"] or LuaUserData.RegisterType("Barotrauma.Networking.ServerSettings")
LuaUserData.MakePropertyAccessible(serverSettingsDescriptor, "SelectedOutpostName")
LuaUserData.MakePropertyAccessible(serverSettingsDescriptor, "HiddenSubs")

local SubmarineTags = LuaUserData.CreateEnumTable("Barotrauma.SubmarineTag")

local function getVoteText(key)
    if Traitormod ~= nil and Traitormod.Language ~= nil and Traitormod.Language[key] ~= nil then
        return Traitormod.Language[key]
    end
    return key
end

local function notifyGuiVoteChanged()
    if Traitormod ~= nil and Traitormod.ClientMenu ~= nil and Traitormod.ClientMenu.SendVoteSnapshotEveryone ~= nil then
        Traitormod.ClientMenu.SendVoteSnapshotEveryone()
    end
end

local function getVoteConfig()
    Traitormod.Config.GameVote = Traitormod.Config.GameVote or {}
    return Traitormod.Config.GameVote
end

local function getVoteDurationSeconds()
    local cfg = getVoteConfig()
    local duration = tonumber(cfg.DurationSeconds or cfg.Duration or cfg.VoteDurationSeconds or cfg.VoteDuration)

    if duration == nil then
        return 120
    end

    return math.max(1, math.floor(duration))
end

local function getVoteCooldownSeconds()
    local cooldown = tonumber(getVoteConfig().CooldownSeconds)
    if cooldown == nil then return 300 end
    return math.max(0, math.floor(cooldown))
end

local function isVoteCooldownBypassed(client)
    return client == nil or client.HasPermission(ClientPermissions.ConsoleCommands)
end

local function getVoteCooldownRemaining(voteType, client)
    if isVoteCooldownBypassed(client) then return 0 end

    local cooldownUntil = voteType == "map" and vt.MapVoteCooldownUntil or vt.GameVoteCooldownUntil
    return math.max(0, math.ceil((tonumber(cooldownUntil) or 0) - Timer.GetTime()))
end

local function formatCooldownTime(seconds)
    seconds = math.max(0, math.ceil(tonumber(seconds) or 0))
    return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function isLobbyState()
    return not Game.RoundStarted
end

local function startsWith(text, prefix)
    return string.sub(text, 1, string.len(prefix)) == prefix
end

local function trim(text)
    return (tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function splitCsv(text)
    local result = {}
    for part in string.gmatch(tostring(text or ""), "([^,]+)") do
        local value = trim(part)
        if value ~= "" then
            table.insert(result, value)
        end
    end
    return result
end

local function getServerSettingsFileCandidates()
    local candidates = {
        "serversettings.xml",
        "ServerSettings.xml",
        Traitormod.Path .. "/../../serversettings.xml",
        Traitormod.Path .. "/../../../serversettings.xml"
    }

    local unique = {}
    local result = {}
    for _, candidate in ipairs(candidates) do
        if candidate ~= nil and candidate ~= "" and not unique[candidate] then
            unique[candidate] = true
            table.insert(result, candidate)
        end
    end
    return result
end

local function getHiddenSubNamesFromFile()
    for _, filePath in ipairs(getServerSettingsFileCandidates()) do
        if File.Exists(filePath) then
            local xml = File.Read(filePath)
            if xml ~= nil and xml ~= "" then
                local hiddenAttr = string.match(xml, 'HiddenSubs%s*=%s*"([^"]*)"')
                if hiddenAttr ~= nil then
                    local hidden = {}
                    for _, name in ipairs(splitCsv(hiddenAttr)) do
                        hidden[name] = true
                    end
                    return hidden
                end
            end
        end
    end

    return {}
end

local function getHiddenSubNames()
    local hidden = {}

    if Game ~= nil and Game.ServerSettings ~= nil and Game.ServerSettings.HiddenSubs ~= nil then
        for name in Game.ServerSettings.HiddenSubs do
            local text = trim(name)
            if text ~= "" then
                hidden[text] = true
            end
        end
    end

    local fromFile = getHiddenSubNamesFromFile()
    for name, value in pairs(fromFile) do
        hidden[name] = value
    end

    return hidden
end

local function isHiddenSubmarine(sub)
    if sub == nil then return false end

    local name = trim(sub.Name)
    if name == "" then return false end

    return getHiddenSubNames()[name] == true
end

local function syncLobby()
    for _, client in pairs(Client.ClientList) do
        client.LastRecvLobbyUpdate = 0
        Networking.ClientWriteLobby(client)
    end
end

local function markServerSettingsDirty()
    if Game == nil or Game.ServerSettings == nil then return end

    Game.ServerSettings.ServerDetailsChanged = true
    Game.ServerSettings:ForcePropertyUpdate()
end

local function applyCommonLobbySync()
    markServerSettingsDirty()
    syncLobby()
end

local function countVotePlayers()
    local amount = 0
    for _, client in pairs(Client.ClientList) do
        if not client.SpectateOnly then
            amount = amount + 1
        end
    end
    return math.max(amount, 1)
end

local function getCapacityMin(sub)
    if sub == nil then return 0 end
    return tonumber(sub.RecommendedCrewSizeMin) or tonumber(sub.RecommendedCrewSizeMax) or 0
end

local function getCapacityMax(sub)
    if sub == nil then return 0 end
    return tonumber(sub.RecommendedCrewSizeMax) or 0
end

local function getCapacityText(sub)
    local minCap = getCapacityMin(sub)
    local maxCap = getCapacityMax(sub)

    if minCap <= 0 and maxCap <= 0 then
        return "?"
    end

    if minCap <= 0 then
        return tostring(maxCap)
    end

    if maxCap <= 0 then
        return tostring(minCap)
    end

    if minCap == maxCap then
        return tostring(maxCap)
    end

    return string.format("%s-%s", minCap, maxCap)
end

local function getPreferredSubmarineCandidates(candidates, playerCount)
    if candidates == nil or #candidates == 0 then return {} end

    local exactFits = {}
    local aboveFits = {}
    local bestAboveMin = nil
    local belowFits = {}
    local bestBelowMax = nil

    for _, sub in pairs(candidates) do
        local minCap = getCapacityMin(sub)
        local maxCap = getCapacityMax(sub)

        if maxCap <= 0 then
            maxCap = minCap
        end
        if minCap <= 0 then
            minCap = maxCap
        end

        if minCap <= playerCount and playerCount <= maxCap then
            table.insert(exactFits, sub)
        elseif playerCount < minCap then
            if bestAboveMin == nil or minCap < bestAboveMin then
                bestAboveMin = minCap
                aboveFits = { sub }
            elseif minCap == bestAboveMin then
                table.insert(aboveFits, sub)
            end
        else
            if bestBelowMax == nil or maxCap > bestBelowMax then
                bestBelowMax = maxCap
                belowFits = { sub }
            elseif maxCap == bestBelowMax then
                table.insert(belowFits, sub)
            end
        end
    end

    if #exactFits > 0 then
        return exactFits
    end

    if #aboveFits > 0 then
        return aboveFits
    end

    if #belowFits > 0 then
        return belowFits
    end

    return {}
end

local function sortSubmarinesForVote(submarines)
    table.sort(submarines, function(a, b)
        local minA = getCapacityMin(a)
        local minB = getCapacityMin(b)
        if minA ~= minB then
            return minA < minB
        end

        local maxA = getCapacityMax(a)
        local maxB = getCapacityMax(b)
        if maxA ~= maxB then
            return maxA < maxB
        end

        return tostring(a.Name or "") < tostring(b.Name or "")
    end)

    return submarines
end

local function chooseBestSubmarine(candidates, playerCount)
    local preferredCandidates = getPreferredSubmarineCandidates(candidates, playerCount)
    if preferredCandidates == nil or #preferredCandidates == 0 then return nil end
    return preferredCandidates[math.random(1, #preferredCandidates)]
end

local function getLower(value)
    return string.lower(tostring(value or ""))
end

local function hasWord(text, word)
    if text == nil or text == "" then return false end
    return string.find(text, word, 1, true) ~= nil
end

local function hasSubTag(sub, tagName)
    if sub == nil or tagName == nil then return false end

    if SubmarineTags[tagName] ~= nil and sub:HasTag(SubmarineTags[tagName]) then
        return true
    end

    local lowerTags = getLower(sub.Tags)
    if lowerTags == "" then return false end

    local normalized = string.gsub(lowerTags, "[%s_%-]+", "")
    local wanted = string.gsub(string.lower(tagName), "[%s_%-]+", "")
    return string.find(normalized, wanted, 1, true) ~= nil
end

local function isForbiddenSecretSub(sub)
    local cfg = getVoteConfig()

    if not sub.IsCampaignCompatible then return true end

    local name = tostring(sub.Name or "")
    if name == "" then return true end
    if isHiddenSubmarine(sub) then return true end

    for _, prefix in ipairs(cfg.SecretBlockedPrefixes or {}) do
        if startsWith(name, prefix) then
            return true
        end
    end

    for _, tagName in ipairs(cfg.SecretBlockedTags or {}) do
        if hasSubTag(sub, tagName) then
            return true
        end
    end

    local lowerPath = getLower(sub.FilePath)
    if lowerPath ~= "" then
        if hasWord(lowerPath, "/tutorial/") or hasWord(lowerPath, "\\tutorial\\") then return true end
        if hasWord(lowerPath, "/debugonlytest/") or hasWord(lowerPath, "\\debugonlytest\\") then return true end
        if hasWord(lowerPath, "/animeditor") or hasWord(lowerPath, "\\animeditor") then return true end
    end

    return false
end

local function getEligibleSecretSubs()
    local result = {}
    for sub in SubmarineInfo.SavedSubmarines do
        if sub.IsPlayer and not isForbiddenSecretSub(sub) then
            table.insert(result, sub)
        end
    end
    return result
end

local function buildMissionTypeUnion(baseList, extraList)
    local result = {}
    local exists = {}

    for _, value in ipairs(baseList or {}) do
        local text = trim(value)
        if text ~= "" and not exists[text] then
            exists[text] = true
            table.insert(result, text)
        end
    end

    for _, value in ipairs(extraList or {}) do
        local text = trim(value)
        if text ~= "" and not exists[text] then
            exists[text] = true
            table.insert(result, text)
        end
    end

    return result
end

local function setMissionTypeList(missionTypes)
    missionTypes = missionTypes or {}
    local joined = table.concat(missionTypes, ",")
    Game.ServerSettings.MissionTypes = joined
end

local function applySecretSelection(playerCount)
    local cfg = getVoteConfig()
    local submarine = chooseBestSubmarine(getEligibleSecretSubs(), playerCount)
    if submarine == nil then
        return false, getVoteText("GameVoteNoSecretSub")
    end

    Game.NetLobbyScreen.SelectedModeIdentifier = cfg.SecretModeIdentifier or "mission"
    Game.NetLobbyScreen.SelectedSub = submarine
    Game.ServerSettings.GameModeIdentifier = cfg.SecretModeIdentifier or "mission"
    Game.ServerSettings.SelectedSubmarine = tostring(submarine.Name)
    Game.ServerSettings.TraitorProbability = tonumber(cfg.SecretTraitorProbability) or 1
    Game.ServerSettings.SelectedLevelDifficulty = tonumber(cfg.SecretDifficulty) or 50

    setMissionTypeList(cfg.SecretMissionTypes)
    applyCommonLobbySync()

    return true, string.format(
        getVoteText("GameVoteSelectedSecret"),
        tostring(submarine.Name),
        getCapacityText(submarine)
    )
end

local function applyHideSelection(playerCount)
    local cfg = getVoteConfig()
    local submarine = chooseBestSubmarine(getEligibleSecretSubs(), playerCount)
    if submarine == nil then
        return false, getVoteText("GameVoteNoHideMap")
    end

    Game.NetLobbyScreen.SelectedModeIdentifier = cfg.HideModeIdentifier or "pvp"
    Game.NetLobbyScreen.SelectedSub = submarine
    Game.ServerSettings.GameModeIdentifier = cfg.HideModeIdentifier or "pvp"
    Game.ServerSettings.SelectedSubmarine = tostring(submarine.Name)
    Game.ServerSettings.TraitorProbability = tonumber(cfg.HideTraitorProbability) or 0

    local missionTypes = cfg.HideMissionTypes or {}
    if cfg.HideKeepSecretMissionTypes ~= false then
        missionTypes = buildMissionTypeUnion(cfg.SecretMissionTypes, missionTypes)
    end
    setMissionTypeList(missionTypes)

    local selectedOutpost = cfg.HideOutpostName or "Random"
    Game.ServerSettings.SelectedOutpostName = Identifier(selectedOutpost)

    applyCommonLobbySync()

    return true, string.format(
        getVoteText("GameVoteSelectedHide"),
        selectedOutpost
    )
end

local function applyAttackDefendSelection(playerCount)
    local cfg = getVoteConfig()

    if Game == nil or Game.NetLobbyScreen == nil or Game.ServerSettings == nil then
        return false, getVoteText("GameVoteApplyFailed")
    end

    local submarine = chooseBestSubmarine(getEligibleSecretSubs(), playerCount)
    if submarine == nil then
        return false, getVoteText("GameVoteNoAttackDefendSub")
    end

    Game.NetLobbyScreen.SelectedModeIdentifier = cfg.AttackDefendModeIdentifier or "pvp"
    Game.NetLobbyScreen.SelectedSub = submarine
    Game.ServerSettings.GameModeIdentifier = cfg.AttackDefendModeIdentifier or "pvp"
    Game.ServerSettings.SelectedSubmarine = tostring(submarine.Name)
    Game.ServerSettings.TraitorProbability = tonumber(cfg.AttackDefendTraitorProbability) or 0

    local missionTypes = cfg.AttackDefendMissionTypes or {}
    if cfg.AttackDefendKeepSecretMissionTypes ~= false then
        missionTypes = buildMissionTypeUnion(cfg.SecretMissionTypes, missionTypes)
    end
    setMissionTypeList(missionTypes)

    local selectedOutpost = cfg.AttackDefendOutpostName or "Random"
    Game.ServerSettings.SelectedOutpostName = Identifier(selectedOutpost)

    applyCommonLobbySync()
    return true, string.format(
        getVoteText("GameVoteSelectedAttackDefend"),
        tostring(submarine.Name),
        getCapacityText(submarine)
    )
end

local applyHandlers = {
    Secret = applySecretSelection,
    AttackDefend = applyAttackDefendSelection,
    HideAndSeek = applyHideSelection
}

local function getConfiguredGameVoteModes()
    local cfg = getVoteConfig()
    local configuredModes = cfg.Modes or {}
    local modes = {}

    for _, entry in ipairs(configuredModes) do
        local modeId = entry.Apply or entry.Name
        local applyHandler = applyHandlers[modeId]
        if applyHandler ~= nil then
            table.insert(modes, {
                Name = entry.Name or modeId,
                LanguageKey = entry.LanguageKey,
                Text = function()
                    return getVoteText(entry.LanguageKey, entry.Name or modeId)
                end,
                Apply = applyHandler
            })
        end
    end

    return modes
end

local function getVoteOptionNumbersText(options)
    local optionNumbers = {}
    for index = 1, #options do
        table.insert(optionNumbers, string.format("!vote %s", index))
    end
    return table.concat(optionNumbers, " / ")
end

local function sendVoteOptions(client)
    local gameVoteModes = getConfiguredGameVoteModes()
    Traitormod.SendChatMessage(client, getVoteText("GameVoteOptionsHeader"), Color.LightGreen)
    for index, mode in ipairs(gameVoteModes) do
        Traitormod.SendChatMessage(client, string.format("%s — %s", index, mode.Text()), Color.White)
    end
    Traitormod.SendChatMessage(
        client,
        string.format(
            getVoteText("GameVoteHowToVote"),
            getVoteOptionNumbersText(gameVoteModes)
        ),
        Color.LightBlue
    )
end

local function sendMapVoteOptions(client, candidates)
    Traitormod.SendChatMessage(client, getVoteText("MapVoteOptionsHeader"), Color.LightGreen)
    for index, submarine in ipairs(candidates) do
        Traitormod.SendChatMessage(
            client,
            string.format("%s — %s (%s)", index, tostring(submarine.Name), getCapacityText(submarine)),
            Color.White
        )
    end
    Traitormod.SendChatMessage(
        client,
        string.format(
            getVoteText("MapVoteHowToVote"),
            getVoteOptionNumbersText(candidates)
        ),
        Color.LightBlue
    )
end

local function getModeNames(gameVoteModes, modeIds)
    local names = {}
    for _, modeId in ipairs(modeIds) do
        if gameVoteModes[modeId] ~= nil then
            table.insert(names, gameVoteModes[modeId].Text())
        end
    end
    return names
end

local function getSubmarineNames(candidates, candidateIds)
    local names = {}
    for _, candidateId in ipairs(candidateIds) do
        if candidates[candidateId] ~= nil then
            table.insert(names, tostring(candidates[candidateId].Name or ""))
        end
    end
    return names
end

local function joinModeNames(modeNames)
    return table.concat(modeNames, ", ")
end

local function applySubmarineSelection(submarine)
    if submarine == nil then
        return false, getVoteText("MapVoteNoCandidates")
    end

    if Game == nil or Game.NetLobbyScreen == nil or Game.ServerSettings == nil then
        return false, getVoteText("GameVoteApplyFailed")
    end

    Game.NetLobbyScreen.SelectedSub = submarine
    Game.ServerSettings.SelectedSubmarine = tostring(submarine.Name)

    applyCommonLobbySync()

    return true, string.format(
        getVoteText("MapVoteSelected"),
        tostring(submarine.Name),
        getCapacityText(submarine)
    )
end

local function finishGameVote(cancelledText)
    local vote = vt.GameVote
    if vote == nil then return end

    vt.GameVote = nil
    vt.GameVoteCooldownUntil = Timer.GetTime() + getVoteCooldownSeconds()

    if cancelledText ~= nil then
        Traitormod.SendMessageEveryone(cancelledText)
        notifyGuiVoteChanged()
        return
    end

    local gameVoteModes = getConfiguredGameVoteModes()
    if #gameVoteModes == 0 then
        Traitormod.SendMessageEveryone(getVoteText("GameVoteApplyFailed"))
        notifyGuiVoteChanged()
        return
    end

    local highest = -1
    local winners = {}
    for i = 1, #gameVoteModes do
        local result = vote.Results[i] or 0
        if result > highest then
            highest = result
            winners = { i }
        elseif result == highest then
            table.insert(winners, i)
        end
    end

    local winnerId = winners[math.random(1, #winners)]
    local winner = gameVoteModes[winnerId]
    local playerCount = countVotePlayers()

    if highest <= 0 then
        Traitormod.SendMessageEveryone(string.format(
            getVoteText("GameVoteNoVotes"),
            winner.Text()
        ))
    elseif #winners > 1 then
        Traitormod.SendMessageEveryone(string.format(
            getVoteText("GameVoteTie"),
            joinModeNames(getModeNames(gameVoteModes, winners)),
            winner.Text()
        ))
    else
        Traitormod.SendMessageEveryone(string.format(
            getVoteText("GameVoteFinished"),
            winner.Text()
        ))
    end

    local success, selectionText = winner.Apply(playerCount)
    if not success then
        Traitormod.SendMessageEveryone(selectionText)
        notifyGuiVoteChanged()
        return
    end

    Traitormod.SendMessageEveryone(selectionText)
    notifyGuiVoteChanged()
end

local function finishMapVote(cancelledText)
    local vote = vt.MapVote
    if vote == nil then return end

    vt.MapVote = nil
    vt.MapVoteCooldownUntil = Timer.GetTime() + getVoteCooldownSeconds()

    if cancelledText ~= nil then
        Traitormod.SendMessageEveryone(cancelledText)
        notifyGuiVoteChanged()
        return
    end

    local candidates = vote.Candidates or {}
    if #candidates == 0 then
        Traitormod.SendMessageEveryone(string.format(getVoteText("MapVoteNoCandidates"), tostring(vote.PlayerCount or 0)))
        notifyGuiVoteChanged()
        return
    end

    local highest = -1
    local winners = {}

    for i = 1, #candidates do
        local result = vote.Results[i] or 0
        if result > highest then
            highest = result
            winners = { i }
        elseif result == highest then
            table.insert(winners, i)
        end
    end

    local winnerId = winners[math.random(1, #winners)]
    local winner = candidates[winnerId]

    if highest <= 0 then
        Traitormod.SendMessageEveryone(string.format(
            getVoteText("MapVoteNoVotes"),
            tostring(winner.Name)
        ))
    elseif #winners > 1 then
        Traitormod.SendMessageEveryone(string.format(
            getVoteText("MapVoteTie"),
            joinModeNames(getSubmarineNames(candidates, winners)),
            tostring(winner.Name)
        ))
    else
        Traitormod.SendMessageEveryone(string.format(
            getVoteText("MapVoteFinished"),
            tostring(winner.Name)
        ))
    end

    local success, selectionText = applySubmarineSelection(winner)
    if not success then
        Traitormod.SendMessageEveryone(selectionText)
        notifyGuiVoteChanged()
        return
    end

    Traitormod.SendMessageEveryone(selectionText)
    notifyGuiVoteChanged()
end

---@param text string
---@param options unknown[]
---@param time number
---@param completed fun(results: table, clients: table)
---@param clients Barotrauma.Networking.Client[]?
vt.StartVote = function(text, options, time, completed, clients)
    if clients == nil then clients = Client.ClientList end

    local voteData = {}

    table.insert(vt.Votes, voteData)

    local voteId = #vt.Votes

    voteData.Time = Timer.GetTime() + time
    voteData.OnCompleted = completed
    voteData.Results = {}
    voteData.Clients = {}
    for i = 1, #options, 1 do
        voteData.Results[i] = 0
    end
    for _, value in ipairs(clients) do
        voteData.Clients[value] = -1
    end

    local max = 0
    local amount = 0

    for _, client1 in pairs(clients) do
        max = max + 1
        textPromptUtils.Prompt(text, options, client1, function(id, client2)
            if voteData.Completed then return end

            local option = options[id]
            if option == nil then return end

            voteData.Results[id] = voteData.Results[id] + 1
            voteData.Clients[client2] = id

            amount = amount + 1

            if amount == max then
                voteData.Completed = true
                table.remove(vt.Votes, voteId)
                voteData.OnCompleted(voteData.Results, voteData.Clients)
            end
        end)
    end
end

Hook.Add("think", "Traitormod.Voting.Think", function()
    for key, voteData in pairs(vt.Votes) do
        if Timer.GetTime() > voteData.Time then
            voteData.Completed = true
            table.remove(vt.Votes, key)
            voteData.OnCompleted(voteData.Results, voteData.Clients)
            break
        end
    end

    if vt.GameVote ~= nil then
        if Game.RoundStarted then
            finishGameVote(getVoteText("GameVoteCancelledRoundStarted"))
        elseif Timer.GetTime() > vt.GameVote.Time then
            finishGameVote()
        end
    end

    if vt.MapVote ~= nil then
        if Game.RoundStarted then
            finishMapVote(getVoteText("MapVoteCancelledRoundStarted"))
        elseif Timer.GetTime() > vt.MapVote.Time then
            finishMapVote()
        end
    end
end)

vt.StartGameVote = function(client, silent)
    if not isLobbyState() then
        Traitormod.SendMessage(client, getVoteText("GameVoteLobbyOnly"))
        return true
    end

    if vt.GameVote ~= nil or vt.MapVote ~= nil then
        Traitormod.SendMessage(client, getVoteText("LobbyVoteAlreadyActive"))
        return true
    end

    local cooldownRemaining = getVoteCooldownRemaining("game", client)
    if cooldownRemaining > 0 then
        Traitormod.SendMessage(client, string.format(getVoteText("GameVoteCooldown"), formatCooldownTime(cooldownRemaining)))
        return true
    end

    local gameVoteModes = getConfiguredGameVoteModes()
    if #gameVoteModes == 0 then
        Traitormod.SendMessage(client, getVoteText("GameVoteApplyFailed"))
        return true
    end

    local voteDuration = getVoteDurationSeconds()
    local results = {}
    for index = 1, #gameVoteModes do
        results[index] = 0
    end

    vt.GameVote = {
        Time = Timer.GetTime() + voteDuration,
        Duration = voteDuration,
        GuiId = "game:" .. tostring(Timer.GetTime()),
        StartedBy = client and client.Name or getVoteText("GameVoteStartedByServer"),
        Results = results,
        ClientVotes = {}
    }

    if not silent then
        local startedText = string.format(
            getVoteText("GameVoteStarted"),
            vt.GameVote.StartedBy,
            tostring(voteDuration)
        )
        Traitormod.SendMessageEveryone(startedText)

        for _, target in pairs(Client.ClientList) do
            sendVoteOptions(target)
        end
    end

    notifyGuiVoteChanged()
    return true
end

vt.StartMapVote = function(client, silent)
    if not isLobbyState() then
        Traitormod.SendMessage(client, getVoteText("GameVoteLobbyOnly"))
        return true
    end

    if vt.GameVote ~= nil or vt.MapVote ~= nil then
        Traitormod.SendMessage(client, getVoteText("LobbyVoteAlreadyActive"))
        return true
    end

    local cooldownRemaining = getVoteCooldownRemaining("map", client)
    if cooldownRemaining > 0 then
        Traitormod.SendMessage(client, string.format(getVoteText("MapVoteCooldown"), formatCooldownTime(cooldownRemaining)))
        return true
    end

    local playerCount = countVotePlayers()
    local candidates = sortSubmarinesForVote(getPreferredSubmarineCandidates(getEligibleSecretSubs(), playerCount))

    if #candidates == 0 then
        Traitormod.SendMessage(client, string.format(getVoteText("MapVoteNoCandidates"), tostring(playerCount)))
        return true
    end

    local voteDuration = getVoteDurationSeconds()
    local results = {}
    for index = 1, #candidates do
        results[index] = 0
    end

    vt.MapVote = {
        Time = Timer.GetTime() + voteDuration,
        Duration = voteDuration,
        GuiId = "map:" .. tostring(Timer.GetTime()),
        StartedBy = client and client.Name or getVoteText("GameVoteStartedByServer"),
        Results = results,
        Candidates = candidates,
        ClientVotes = {},
        PlayerCount = playerCount
    }

    if not silent then
        Traitormod.SendMessageEveryone(string.format(
            getVoteText("MapVoteStarted"),
            vt.MapVote.StartedBy,
            tostring(voteDuration)
        ))

        for _, target in pairs(Client.ClientList) do
            sendMapVoteOptions(target, candidates)
        end
    end

    notifyGuiVoteChanged()
    return true
end

local function tryHandleIndexedLobbyVote(client, args, voteData, options, getOptionName, acceptedKey, invalidKey, silentAccepted)
    if voteData == nil then
        return false
    end

    local optionId = tonumber(args[1])
    if optionId ~= nil and options[optionId] ~= nil then
        local previousVote = voteData.ClientVotes[client]
        if previousVote ~= nil then
            voteData.Results[previousVote] = math.max(0, (voteData.Results[previousVote] or 0) - 1)
        end

        voteData.ClientVotes[client] = optionId
        voteData.Results[optionId] = (voteData.Results[optionId] or 0) + 1

        if not silentAccepted then
            Traitormod.SendMessage(client, string.format(getVoteText(acceptedKey), getOptionName(options[optionId])))
        end
        notifyGuiVoteChanged()
        return true
    end

    if optionId ~= nil then
        Traitormod.SendMessage(
            client,
            string.format(
                getVoteText(invalidKey),
                getVoteOptionNumbersText(options)
            )
        )
        return true
    end

    return false
end

vt.TryHandleGameVoteCommand = function(client, args)
    if vt.GameVote ~= nil then
        local gameVoteModes = getConfiguredGameVoteModes()
        return tryHandleIndexedLobbyVote(
            client,
            args,
            vt.GameVote,
            gameVoteModes,
            function(option) return option.Text() end,
            "GameVoteAccepted",
            "GameVoteInvalidOption"
        )
    end

    if vt.MapVote ~= nil then
        return tryHandleIndexedLobbyVote(
            client,
            args,
            vt.MapVote,
            vt.MapVote.Candidates or {},
            function(option) return tostring(option.Name) end,
            "MapVoteAccepted",
            "MapVoteInvalidOption"
        )
    end

    return false
end

vt.TryHandleGuiVote = function(client, optionId)
    local args = { tostring(optionId or "") }

    if vt.GameVote ~= nil then
        local gameVoteModes = getConfiguredGameVoteModes()
        return tryHandleIndexedLobbyVote(
            client,
            args,
            vt.GameVote,
            gameVoteModes,
            function(option) return option.Text() end,
            "GameVoteAccepted",
            "GameVoteInvalidOption",
            true
        )
    end

    if vt.MapVote ~= nil then
        return tryHandleIndexedLobbyVote(
            client,
            args,
            vt.MapVote,
            vt.MapVote.Candidates or {},
            function(option) return tostring(option.Name) end,
            "MapVoteAccepted",
            "MapVoteInvalidOption",
            true
        )
    end

    return false
end

local function buildGuiVoteOption(index, text, votes, selected)
    return {
        Index = index,
        Text = tostring(text or ""),
        Votes = math.max(0, tonumber(votes or 0) or 0),
        Selected = selected == true
    }
end

local function getRemainingSeconds(vote)
    if vote == nil or vote.Time == nil then return 0 end
    return math.max(0, math.ceil(vote.Time - Timer.GetTime()))
end

local function getGuiStartBlockedReason()
    if not isLobbyState() then
        return getVoteText("LobbyVoteLobbyOnly")
    end
    if vt.GameVote ~= nil or vt.MapVote ~= nil then
        return getVoteText("LobbyVoteAlreadyActive")
    end
    return ""
end

vt.HasActiveGuiVote = function()
    return vt.GameVote ~= nil or vt.MapVote ~= nil
end

vt.GetGuiSnapshot = function(client)
    local snapshot = {
        StartBlockedReason = getGuiStartBlockedReason(),
        CanStart = isLobbyState() and vt.GameVote == nil and vt.MapVote == nil,
        GameCooldownRemaining = getVoteCooldownRemaining("game", client),
        MapCooldownRemaining = getVoteCooldownRemaining("map", client),
        Active = nil
    }

    if vt.GameVote ~= nil then
        local options = {}
        local modes = getConfiguredGameVoteModes()
        for index, mode in ipairs(modes) do
            table.insert(options, buildGuiVoteOption(
                index,
                mode.Text(),
                vt.GameVote.Results[index] or 0,
                vt.GameVote.ClientVotes[client] == index
            ))
        end

        snapshot.Active = {
            Id = vt.GameVote.GuiId or "game",
            Type = "game",
            StartedBy = tostring(vt.GameVote.StartedBy or ""),
            Remaining = getRemainingSeconds(vt.GameVote),
            Duration = tonumber(vt.GameVote.Duration or getVoteDurationSeconds()) or 1,
            Options = options
        }
    elseif vt.MapVote ~= nil then
        local options = {}
        for index, submarine in ipairs(vt.MapVote.Candidates or {}) do
            table.insert(options, buildGuiVoteOption(
                index,
                string.format("%s (%s)", tostring(submarine.Name or ""), getCapacityText(submarine)),
                vt.MapVote.Results[index] or 0,
                vt.MapVote.ClientVotes[client] == index
            ))
        end

        snapshot.Active = {
            Id = vt.MapVote.GuiId or "map",
            Type = "map",
            StartedBy = tostring(vt.MapVote.StartedBy or ""),
            Remaining = getRemainingSeconds(vt.MapVote),
            Duration = tonumber(vt.MapVote.Duration or getVoteDurationSeconds()) or 1,
            Options = options
        }
    end

    return snapshot
end

vt.StartGuiVote = function(client, voteType)
    voteType = string.lower(tostring(voteType or ""))
    -- votes started from the GUI are still announced in chat, so players without the pack can use !vote
    if voteType == "game" then
        return vt.StartGameVote(client, false)
    elseif voteType == "map" then
        return vt.StartMapVote(client, false)
    end

    return true
end

vt.CastGuiVote = function(client, optionId)
    optionId = tonumber(optionId)
    if optionId == nil then return true end
    return vt.TryHandleGuiVote(client, optionId)
end

return vt
