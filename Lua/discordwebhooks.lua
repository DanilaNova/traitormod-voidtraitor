local json = dofile(Traitormod.Path .. "/Lua/json.lua")

Traitormod.Discord = Traitormod.Discord or {}

local discord = Traitormod.Discord
local cfg = Traitormod.Config.Discord or {}
local statusCfg = cfg.Status or {}
local presenceCfg = cfg.Presence or {}
local roundCfg = cfg.Round or {}

local TeamID1 = CharacterTeamType.Team1
local TeamID2 = CharacterTeamType.Team2

local DEFAULT_SERVER_NAME = "VoidTraitor"
local DEFAULT_PRESENCE_USERNAME = "VoidTraitor Server"
local DEFAULT_ROUND_USERNAME = "VoidTraitor Round Logger"
local DEFAULT_STATUS_USERNAME = "VoidTraitor Status"

local MODE_LANGUAGE_KEYS = {
    secret = "DiscordModeSecret",
    mission = "DiscordModeMission",
    attackdefend = "DiscordModeAttackDefend",
    attackdefendv2 = "DiscordModeAttackDefend",
    attackdefendwatter = "DiscordModeAttackDefend",
    hideandseek = "DiscordModeHideAndSeek",
    pvp = "DiscordModePvP",
    multiplayercampaign = "DiscordModeMultiplayerCampaign",
    unknown = "DiscordModeUnknown",
}

local function text(key)
    return Traitormod.GetText(key)
end

local function formatText(key, ...)
    return Traitormod.FormatText(key, ...)
end

local function isNonEmptyString(value)
    return type(value) == "string" and value ~= ""
end

local function safeJsonDecode(value)
    local ok, result = pcall(json.decode, value or "")
    if ok and type(result) == "table" then
        return result
    end
    return nil
end

local function readJsonFile(path, fallback)
    fallback = fallback or {}

    if not isNonEmptyString(path) then
        return fallback
    end

    if not File.Exists(path) then
        File.Write(path, json.encode(fallback))
        return fallback
    end

    local data = safeJsonDecode(File.Read(path))
    if data then
        return data
    end

    Traitormod.Error(formatText("DiscordReadJsonFailed", tostring(path)))
    File.Write(path, json.encode(fallback))
    return fallback
end

local function writeJsonFile(path, value)
    if not isNonEmptyString(path) then return end
    File.Write(path, json.encode(value or {}))
end

discord.CounterFile = cfg.RoundCounterFile or (Traitormod.Path .. "/Lua/roundcounter.json")
discord.StateFile = cfg.StateFile or (Traitormod.Path .. "/Lua/discordstate.json")
discord.StartupAnnounced = false
discord.CurrentRoundNumber = 0
discord.State = readJsonFile(discord.StateFile, {})
discord.Status = {
    Dirty = true,
    LastHash = nil,
    NextUpdateTime = 0,
    CreatingMessage = false,
    Updating = false,
    MissingConfigLogged = false,
    ManualBootstrapSent = discord.State.StatusManualBootstrapSent == true,
    MessageId = tostring(statusCfg.MessageId or discord.State.StatusMessageId or ""),
}
discord.RoundStats = {
    StartPlayers = 0,
}

local function logHttpResponse(context, body, statusCode)
    if cfg.DebugResponses then
        Traitormod.Debug(formatText("DiscordDebugResponse", tostring(context), tostring(statusCode), tostring(body)))
    end
end

local function httpRequest(method, url, payload, callback)
    if not isNonEmptyString(url) then return false end

    local requestBody = payload and json.encode(payload) or nil
    local ok, err = pcall(function()
        Networking.HttpRequest(url, function(body, statusCode, headers)
            logHttpResponse(method .. " " .. url, body, statusCode)
            if callback then
                callback(body, tonumber(statusCode), headers)
            end
        end, requestBody, method, "application/json")
    end)

    if not ok then
        Traitormod.Error(formatText("DiscordWebhookFailed", tostring(err)))
        return false
    end

    return true
end

local function postWebhook(url, payload, callback)
    return httpRequest("POST", url, payload, callback)
end

local function patchWebhookMessage(url, messageId, payload, callback)
    if not isNonEmptyString(messageId) then return false end
    return httpRequest("PATCH", url .. "/messages/" .. tostring(messageId), payload, callback)
end

local function getRetryAfterSeconds(body, headers)
    local data = safeJsonDecode(body)
    if data and type(data.retry_after) == "number" then
        return tonumber(data.retry_after)
    end

    if headers then
        local headerValue = headers["retry-after"] or headers["Retry-After"] or headers["x-ratelimit-reset-after"] or headers["X-RateLimit-Reset-After"]
        if headerValue ~= nil then
            local seconds = tonumber(headerValue)
            if seconds then
                return seconds
            end
        end
    end

    return nil
end

local function getStatusInterval()
    local interval = tonumber(statusCfg.UpdateInterval) or 15
    if interval < 5 then
        interval = 5
    end
    return interval
end

local function scheduleStatusUpdate(seconds, minimum)
    local delay = tonumber(seconds) or getStatusInterval()
    if minimum ~= nil then
        delay = math.max(delay, tonumber(minimum) or 0)
    end

    if delay < 0 then
        delay = 0
    end

    discord.Status.NextUpdateTime = Timer.GetTime() + delay
end

local function markStatusUpdated(snapshotHash)
    discord.Status.LastHash = snapshotHash
    discord.Status.Dirty = false
    scheduleStatusUpdate(getStatusInterval())
end

local function scheduleStatusRetryFrom429(body, headers)
    local retryAfter = getRetryAfterSeconds(body, headers) or 1
    if retryAfter < 1 then
        retryAfter = 1
    end

    scheduleStatusUpdate(retryAfter + 1)
    Traitormod.Error(formatText("DiscordStatusRateLimited", tostring(retryAfter)))
end

local function scheduleGenericStatusRetry()
    scheduleStatusUpdate(getStatusInterval(), 10)
end

local function getCharacterClientName(character)
    if not character then return nil end

    local client = Traitormod.FindClientCharacter(character)
    if client and client.Name then
        return tostring(client.Name)
    end

    if character.Name then
        return tostring(character.Name)
    end

    return nil
end

local function getAllRoundPlayers()
    local players = {}

    for _, client in pairs(Client.ClientList) do
        if client and client.Character and client.Character.IsHuman and not client.SpectateOnly and client.Character.TeamID == TeamID1 then
            table.insert(players, client.Character)
        end
    end

    return players
end

local function getRoundRoleCharacters()
    local characters = {}
    local roleManager = Traitormod and Traitormod.RoleManager
    local roundRoles = roleManager and roleManager.RoundRoles or nil

    if type(roundRoles) ~= "table" then
        return characters
    end

    for character, role in pairs(roundRoles) do
        if character and role and character.IsHuman and character.TeamID == TeamID1 then
            table.insert(characters, {
                Character = character,
                Role = role,
            })
        end
    end

    return characters
end

local function captureRoundStartStats()
    discord.RoundStats.StartPlayers = discord.GetPlayerCount()
end

local function getSelectedSubmarineName()
    if Game and Game.NetLobbyScreen and Game.NetLobbyScreen.SelectedSub and Game.NetLobbyScreen.SelectedSub.Name then
        return tostring(Game.NetLobbyScreen.SelectedSub.Name)
    end

    if Game and Game.ServerSettings and Game.ServerSettings.SelectedSubmarine then
        return tostring(Game.ServerSettings.SelectedSubmarine)
    end

    return nil
end

local function getSelectedMapName()
    if Game and Game.ServerSettings and Game.ServerSettings.SelectedOutpostName then
        return tostring(Game.ServerSettings.SelectedOutpostName)
    end

    return nil
end

local function containsTextIgnoreCase(haystack, needle)
    if not isNonEmptyString(haystack) or not isNonEmptyString(needle) then
        return false
    end

    return string.find(string.lower(haystack), string.lower(needle), 1, true) ~= nil
end

local function resolveLobbyModeName()
    local gameModeId = "unknown"
    if Game and Game.ServerSettings and Game.ServerSettings.GameModeIdentifier then
        gameModeId = string.lower(tostring(Game.ServerSettings.GameModeIdentifier))
    end

    local missionTypes = Game and Game.ServerSettings and tostring(Game.ServerSettings.MissionTypes or "") or ""
    local selectedSub = getSelectedSubmarineName() or ""
    local selectedMap = getSelectedMapName() or ""
    local traitorProbability = tonumber(Game and Game.ServerSettings and Game.ServerSettings.TraitorProbability or 0) or 0

    if containsTextIgnoreCase(selectedSub, "#hide and seek") or containsTextIgnoreCase(selectedMap, "#hide and seek") then
        return "hideandseek"
    end

    if gameModeId == "pvp" then
        if containsTextIgnoreCase(missionTypes, "attackdefence")
            or containsTextIgnoreCase(selectedSub, "attack&defend")
            or containsTextIgnoreCase(selectedMap, "attack&defend") then
            return "attackdefend"
        end

        return "pvp"
    end

    if gameModeId == "mission" and traitorProbability > 0 then
        return "secret"
    end

    return gameModeId
end

local function getResolvedModeName()
    if Game and Game.RoundStarted and Traitormod.SelectedGamemode and Traitormod.SelectedGamemode.Name then
        return string.lower(tostring(Traitormod.SelectedGamemode.Name))
    end

    return resolveLobbyModeName()
end

local function getModeDisplayName(modeName)
    modeName = string.lower(tostring(modeName or "unknown"))

    if cfg.ModeNames and cfg.ModeNames[modeName] then
        return tostring(cfg.ModeNames[modeName])
    end

    local languageKey = MODE_LANGUAGE_KEYS[modeName] or MODE_LANGUAGE_KEYS.unknown
    return text(languageKey)
end

local function getSecretRoundSummary(durationSeconds)
    local aliveTraitors = 0
    local totalTraitors = 0
    local aliveCrew = 0
    local totalCrewFromRoles = 0
    local traitorNames = {}
    local startPlayers = tonumber(discord.RoundStats and discord.RoundStats.StartPlayers) or 0

    for _, entry in pairs(getRoundRoleCharacters()) do
        local character = entry.Character
        local role = entry.Role
        local isAntagonist = role and role.IsAntagonist == true

        if isAntagonist then
            totalTraitors = totalTraitors + 1
            if not character.IsDead then
                aliveTraitors = aliveTraitors + 1
            end

            local name = getCharacterClientName(character)
            if name then
                table.insert(traitorNames, name)
            end
        else
            totalCrewFromRoles = totalCrewFromRoles + 1
            if not character.IsDead then
                aliveCrew = aliveCrew + 1
            end
        end
    end

    table.sort(traitorNames, function(a, b)
        return string.lower(a) < string.lower(b)
    end)

    local totalCrew = totalCrewFromRoles
    if startPlayers > 0 and startPlayers >= totalTraitors then
        totalCrew = startPlayers - totalTraitors
        aliveCrew = math.min(aliveCrew, totalCrew)
    end

    local traitorText = #traitorNames > 0 and table.concat(traitorNames, ", ") or text("DiscordUnknownTraitors")

    return formatText(
        "DiscordRoundEndedSecret",
        discord.CurrentRoundNumber,
        aliveTraitors,
        totalTraitors,
        aliveCrew,
        totalCrew,
        discord.FormatDuration(durationSeconds),
        traitorText
    )
end

local function getAttackDefendRoundSummary(durationSeconds)
    local winnerText = text("DiscordWinnerTeamUnknown")
    local winningTeam = Game and Game.GameSession and Game.GameSession.WinningTeam or nil

    if winningTeam == TeamID1 then
        winnerText = text("DiscordWinnerTeamBlue")
    elseif winningTeam == TeamID2 then
        winnerText = text("DiscordWinnerTeamRed")
    end

    return formatText(
        "DiscordRoundEndedAttackDefend",
        discord.CurrentRoundNumber,
        discord.FormatDuration(durationSeconds),
        winnerText
    )
end

local function getGenericRoundSummary(durationSeconds)
    return formatText(
        "DiscordRoundEndedGeneric",
        discord.CurrentRoundNumber,
        discord.FormatDuration(durationSeconds)
    )
end

local function buildTextPayload(username, bodyText)
    return {
        username = tostring(username),
        content = tostring(bodyText),
        allowed_mentions = { parse = {} },
    }
end

function discord.LoadCounter()
    local data = readJsonFile(discord.CounterFile, {})
    discord.CurrentRoundNumber = tonumber(data.CurrentRoundNumber) or 0
end

function discord.SaveCounter()
    writeJsonFile(discord.CounterFile, { CurrentRoundNumber = discord.CurrentRoundNumber })
end

function discord.SaveState()
    discord.State.StatusMessageId = discord.Status.MessageId
    discord.State.StatusManualBootstrapSent = discord.Status.ManualBootstrapSent == true
    writeJsonFile(discord.StateFile, discord.State)
end

function discord.GetPlayerCount(adjustment)
    local amount = 0
    for _, client in pairs(Client.ClientList) do
        if client then
            amount = amount + 1
        end
    end

    amount = amount + (tonumber(adjustment) or 0)
    if amount < 0 then amount = 0 end
    return amount
end

function discord.GetMaxPlayers()
    if Game and Game.ServerSettings and Game.ServerSettings.MaxPlayers then
        return Game.ServerSettings.MaxPlayers
    end
    return 0
end

function discord.GetCurrentModeName()
    return getResolvedModeName()
end

function discord.GetModeDisplayName()
    return getModeDisplayName(discord.GetCurrentModeName())
end

function discord.FormatDuration(seconds)
    seconds = math.max(math.floor(seconds or 0), 0)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60

    if hours > 0 then
        return formatText("DiscordDurationHoursMinutes", hours, minutes)
    end

    if minutes > 0 then
        return formatText("DiscordDurationMinutesSeconds", minutes, secs)
    end

    return formatText("DiscordDurationSeconds", secs)
end

function discord.GetRoundDurationText()
    if Game and Game.RoundStarted then
        return discord.FormatDuration(Traitormod.RoundTime or 0)
    end

    return text("DiscordNoDurationText")
end

function discord.GetRoundLabel()
    if Game and Game.RoundStarted then
        return string.format("#%d", math.max(discord.CurrentRoundNumber, 1))
    end

    local nextRound = math.max(discord.CurrentRoundNumber + 1, 1)
    if statusCfg.ShowNextRoundInLobby ~= false then
        return string.format("%s #%d", text("DiscordNextRoundPrefix"), nextRound)
    end

    return text("DiscordStatusLobbyText")
end

function discord.GetSelectionData()
    local submarineName = getSelectedSubmarineName()
    local mapName = getSelectedMapName()

    if not isNonEmptyString(submarineName) then
        submarineName = nil
    end

    if not isNonEmptyString(mapName) then
        mapName = nil
    end

    return {
        submarineName = submarineName,
        mapName = mapName,
    }
end

function discord.GetRoundStateText()
    if Game == nil then
        return text("DiscordStatusUnknownText")
    end

    if Game.RoundStarted then
        return text("DiscordStatusRoundText")
    end

    return text("DiscordStatusLobbyText")
end

function discord.BuildStatusSnapshot()
    local serverName = DEFAULT_SERVER_NAME
    if Game and Game.ServerSettings and Game.ServerSettings.ServerName then
        serverName = tostring(Game.ServerSettings.ServerName)
    end

    local selection = discord.GetSelectionData()

    return {
        serverName = serverName,
        players = discord.GetPlayerCount(),
        maxPlayers = discord.GetMaxPlayers(),
        roundLabel = discord.GetRoundLabel(),
        mapName = selection.mapName or text("DiscordNoSelectionText"),
        submarineName = selection.submarineName or text("DiscordNoSelectionText"),
        hasMap = selection.mapName ~= nil,
        hasSubmarine = selection.submarineName ~= nil,
        stateText = discord.GetRoundStateText(),
        modeText = discord.GetModeDisplayName(),
        durationText = discord.GetRoundDurationText(),
    }
end

function discord.GetStatusHash(snapshot)
    return table.concat({
        tostring(snapshot.serverName),
        tostring(snapshot.players),
        tostring(snapshot.maxPlayers),
        tostring(snapshot.roundLabel),
        tostring(snapshot.mapName),
        tostring(snapshot.submarineName),
        tostring(snapshot.stateText),
        tostring(snapshot.modeText),
        tostring(snapshot.durationText),
        tostring(snapshot.hasMap),
        tostring(snapshot.hasSubmarine),
    }, "|")
end

function discord.BuildStatusPayload(snapshot)
    local fields = {
        {
            name = text("DiscordFieldRound"),
            value = tostring(snapshot.roundLabel),
            inline = true,
        },
        {
            name = text("DiscordFieldStatus"),
            value = tostring(snapshot.stateText),
            inline = true,
        },
        {
            name = text("DiscordFieldPlayers"),
            value = formatText("DiscordPlayersValue", tonumber(snapshot.players) or 0, tonumber(snapshot.maxPlayers) or 0),
            inline = true,
        },
    }

    if statusCfg.ShowModeField ~= false then
        table.insert(fields, {
            name = text("DiscordFieldMode"),
            value = tostring(snapshot.modeText),
            inline = true,
        })
    end

    if statusCfg.ShowMapField ~= false then
        table.insert(fields, {
            name = text("DiscordFieldMap"),
            value = tostring(snapshot.mapName),
            inline = true,
        })
    end

    if statusCfg.ShowSubmarineField ~= false then
        table.insert(fields, {
            name = text("DiscordFieldSubmarine"),
            value = tostring(snapshot.submarineName),
            inline = true,
        })
    end

    table.insert(fields, {
        name = text("DiscordFieldDuration"),
        value = tostring(snapshot.durationText),
        inline = true,
    })

    return {
        username = tostring(statusCfg.Username or DEFAULT_STATUS_USERNAME),
        content = "",
        allowed_mentions = { parse = {} },
        embeds = {
            {
                title = tostring(snapshot.serverName),
                color = tonumber(statusCfg.EmbedColor) or 16753920,
                fields = fields,
                footer = {
                    text = tostring(statusCfg.FooterText or text("DiscordFooterText")),
                },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            }
        }
    }
end

function discord.IsStatusEnabled()
    return cfg.Enabled ~= false and statusCfg.Enabled ~= false and isNonEmptyString(statusCfg.Webhook)
end

function discord.MarkStatusDirty(force)
    discord.Status.Dirty = true
    if force then
        discord.Status.NextUpdateTime = 0
    end
end

function discord.SendPresenceMessage(bodyText)
    if cfg.Enabled == false or presenceCfg.Enabled == false or not isNonEmptyString(presenceCfg.Webhook) then
        return false
    end

    return postWebhook(presenceCfg.Webhook, buildTextPayload(presenceCfg.Username or DEFAULT_PRESENCE_USERNAME, bodyText))
end

function discord.SendRoundMessage(bodyText)
    if cfg.Enabled == false or roundCfg.Enabled == false or not isNonEmptyString(roundCfg.Webhook) then
        return false
    end

    return postWebhook(roundCfg.Webhook, buildTextPayload(roundCfg.Username or DEFAULT_ROUND_USERNAME, bodyText))
end

function discord.SendStatusBootstrapMessage()
    if not discord.IsStatusEnabled() then return false end
    if discord.Status.CreatingMessage then return false end
    if discord.Status.ManualBootstrapSent then return false end

    discord.Status.CreatingMessage = true

    local payload = discord.BuildStatusPayload(discord.BuildStatusSnapshot())
    payload.content = text("DiscordStatusManualSetup")

    local requestOk = postWebhook(statusCfg.Webhook, payload, function(body, statusCode, headers)
        discord.Status.CreatingMessage = false

        if statusCode == 429 then
            scheduleStatusRetryFrom429(body, headers)
            return
        end

        if statusCode ~= 200 and statusCode ~= 201 and statusCode ~= 204 then
            scheduleGenericStatusRetry()
            Traitormod.Error(formatText("DiscordTestMessageFailed", tostring(statusCode), tostring(body)))
            return
        end

        discord.Status.ManualBootstrapSent = true
        discord.SaveState()
        scheduleStatusUpdate(getStatusInterval())

        Traitormod.Log(text("DiscordTestMessageSent"))
    end)

    if not requestOk then
        discord.Status.CreatingMessage = false
        scheduleGenericStatusRetry()
    end

    return requestOk
end

function discord.EnsureStatusMessage(callback)
    if not discord.IsStatusEnabled() then return false end

    if isNonEmptyString(discord.Status.MessageId) then
        if callback then
            callback(discord.Status.MessageId)
        end
        return true
    end

    if statusCfg.AutoCreateMessageIfMissing ~= false then
        if discord.Status.CreatingMessage then
            return false
        end

        discord.Status.CreatingMessage = true
        local payload = discord.BuildStatusPayload(discord.BuildStatusSnapshot())
        local requestOk = postWebhook(statusCfg.Webhook .. "?wait=true", payload, function(body, statusCode, headers)
            discord.Status.CreatingMessage = false

            if statusCode == 429 then
                scheduleStatusRetryFrom429(body, headers)
                return
            end

            if statusCode ~= 200 and statusCode ~= 201 then
                scheduleGenericStatusRetry()
                Traitormod.Error(formatText("DiscordCreateMessageFailed", tostring(statusCode), tostring(body)))
                return
            end

            local data = safeJsonDecode(body)
            if not data or not data.id then
                scheduleGenericStatusRetry()
                Traitormod.Error(text("DiscordParseMessageIdFailed"))
                return
            end

            discord.Status.MessageId = tostring(data.id)
            if statusCfg.AutoSaveMessageId ~= false then
                discord.SaveState()
            end

            Traitormod.Log(formatText("DiscordStatusMessageCreated", discord.Status.MessageId))

            if callback then
                callback(discord.Status.MessageId)
            end
        end)

        if not requestOk then
            discord.Status.CreatingMessage = false
            scheduleGenericStatusRetry()
        end

        return requestOk
    end

    local sentManualBootstrap = false
    if statusCfg.SendTestMessageOnceIfMissing ~= false and not discord.Status.ManualBootstrapSent then
        sentManualBootstrap = discord.SendStatusBootstrapMessage() == true
    end

    if statusCfg.SendTestMessageOnceIfMissing ~= false then
        if not discord.Status.MissingConfigLogged then
            discord.Status.MissingConfigLogged = true
            Traitormod.Log(text("DiscordStatusMessageIdMissingManual"))
        end

        if not sentManualBootstrap then
            scheduleStatusUpdate(getStatusInterval(), 5)
        end
        return false
    end

    if not discord.Status.MissingConfigLogged then
        discord.Status.MissingConfigLogged = true
        Traitormod.Log(text("DiscordStatusMessageIdMissingAuto"))
    end

    scheduleStatusUpdate(getStatusInterval(), 5)
    return false
end

function discord.UpdateStatus(force)
    if not discord.IsStatusEnabled() then return end
    if not Game or not Game.ServerSettings then return end
    if discord.Status.Updating then return end
    if Timer.GetTime() < discord.Status.NextUpdateTime then return end

    local snapshot = discord.BuildStatusSnapshot()
    local snapshotHash = discord.GetStatusHash(snapshot)

    if not force and not discord.Status.Dirty and snapshotHash == discord.Status.LastHash then
        scheduleStatusUpdate(getStatusInterval())
        return
    end

    if not discord.EnsureStatusMessage(function(messageId)
        local payload = discord.BuildStatusPayload(snapshot)
        discord.Status.Updating = true

        local requestOk = patchWebhookMessage(statusCfg.Webhook, messageId, payload, function(body, statusCode, headers)
            discord.Status.Updating = false

            if statusCode == 200 then
                markStatusUpdated(snapshotHash)
                return
            end

            if statusCode == 429 then
                scheduleStatusRetryFrom429(body, headers)
                return
            end

            scheduleGenericStatusRetry()
            Traitormod.Error(formatText("DiscordStatusUpdateFailed", tostring(statusCode), tostring(body)))
        end)

        if not requestOk then
            discord.Status.Updating = false
            scheduleGenericStatusRetry()
        end
    end) then
        scheduleStatusUpdate(getStatusInterval(), 5)
    end
end

function discord.AnnounceServerStarted()
    if discord.StartupAnnounced then return end
    discord.StartupAnnounced = true

    local serverName = DEFAULT_SERVER_NAME
    if Game and Game.ServerSettings and Game.ServerSettings.ServerName then
        serverName = tostring(Game.ServerSettings.ServerName)
    end

    discord.SendRoundMessage(formatText("DiscordServerStarted", serverName))
    discord.MarkStatusDirty(true)
end

function discord.AnnounceClientConnected(client)
    if not client then return end

    local bodyText = formatText(
        "DiscordPlayerConnected",
        tostring(client.Name),
        discord.GetPlayerCount(),
        discord.GetMaxPlayers()
    )

    discord.SendPresenceMessage(bodyText)
    discord.MarkStatusDirty()
end

function discord.AnnounceClientDisconnected(client)
    if not client then return end

    local bodyText = formatText(
        "DiscordPlayerDisconnected",
        tostring(client.Name),
        discord.GetPlayerCount(-1),
        discord.GetMaxPlayers()
    )

    discord.SendPresenceMessage(bodyText)
    discord.MarkStatusDirty()
end

function discord.AnnounceRoundStarted()
    discord.CurrentRoundNumber = discord.CurrentRoundNumber + 1
    discord.SaveCounter()
    captureRoundStartStats()

    local bodyText = formatText(
        "DiscordRoundStarted",
        discord.CurrentRoundNumber,
        discord.GetModeDisplayName(),
        discord.RoundStats.StartPlayers,
        discord.GetMaxPlayers()
    )

    discord.SendRoundMessage(bodyText)
    discord.MarkStatusDirty(true)
end

function discord.BuildRoundEndMessage(durationSeconds)
    local modeName = string.lower(tostring(discord.GetCurrentModeName() or ""))

    if modeName == "secret" then
        return getSecretRoundSummary(durationSeconds)
    end

    if modeName == "attackdefend" or modeName == "attackdefendv2" or modeName == "attackdefendwatter" then
        return getAttackDefendRoundSummary(durationSeconds)
    end

    return getGenericRoundSummary(durationSeconds)
end

function discord.AnnounceRoundEnded(durationSeconds)
    discord.SendRoundMessage(discord.BuildRoundEndMessage(durationSeconds))
    discord.MarkStatusDirty(true)
end

discord.LoadCounter()
discord.SaveState()

Hook.Add("think", "Traitormod.Discord.ServerStarted", function ()
    if not discord.StartupAnnounced and Game and Game.ServerSettings then
        discord.AnnounceServerStarted()
    end

    discord.UpdateStatus(false)
end)
