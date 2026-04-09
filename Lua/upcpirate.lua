local helper = {}

local function getDefaultConfig()
    local config = Traitormod.Config
    if config == nil then
        return {}
    end

    return config.UPCPirateConfig or {}
end

local function getNumber(value, default)
    local number = tonumber(value)
    if number == nil then return default end
    return number
end

local function getConfig(event)
    local eventConfig = event.UPCPirateConfig or {}
    local defaultConfig = getDefaultConfig()

    return {
        EliminateCrewReward = getNumber(eventConfig.EliminateCrewReward, getNumber(defaultConfig.EliminateCrewReward, 2000)),
        CaptureReward = getNumber(eventConfig.CaptureReward, getNumber(defaultConfig.CaptureReward, 3000)),
        CaptureDurationSeconds = getNumber(eventConfig.CaptureDurationSeconds, getNumber(defaultConfig.CaptureDurationSeconds, 90)),
        EndRoundDelaySeconds = getNumber(eventConfig.EndRoundDelaySeconds, getNumber(defaultConfig.EndRoundDelaySeconds, 5)),
    }
end

local function isAliveMainCrew(character)
    return character ~= nil
        and character.IsHuman
        and not character.IsDead
        and not character.ClientDisconnected
        and character.TeamID == CharacterTeamType.Team1
end

local function isMainSubOrConnectedPlayerSub(submarine)
    local mainSub = Submarine.MainSub
    if submarine == nil or mainSub == nil then return false end
    if submarine == mainSub then return true end
    if submarine.TeamID ~= mainSub.TeamID then return false end

    local ok, isConnected = pcall(function ()
        return mainSub.IsConnectedTo(submarine)
    end)

    if ok then
        return isConnected
    end

    return false
end

local function isCrewOnMainSub(character)
    return isAliveMainCrew(character) and isMainSubOrConnectedPlayerSub(character.Submarine)
end

local function isPirateOnMainSub(character)
    return character ~= nil
        and not character.IsDead
        and isMainSubOrConnectedPlayerSub(character.Submarine)
end

local function getAliveCrewOnMainSub()
    local crew = {}

    for _, character in pairs(Character.CharacterList) do
        if isCrewOnMainSub(character) then
            table.insert(crew, character)
        end
    end

    return crew
end

local function cleanupHooks(state)
    if state == nil then return end
    if state.DeathHookId ~= nil then
        Hook.Remove("character.death", state.DeathHookId)
    end
end

local function rewardPirate(event, amount)
    if amount <= 0 then return end

    local client = Traitormod.FindClientCharacter(event.Character)
    if client == nil then return end

    local points = Traitormod.AwardPoints(client, amount)
    Traitormod.SendMessage(client, string.format(Traitormod.Language.ReceivedPoints, points), "InfoFrameTabButton.Mission")
end

local function complete(event, successType, reward, message)
    local state = event.UPCPirateState
    if state == nil or state.Completed then return end

    state.Completed = true
    event.SuccessType = successType

    cleanupHooks(state)

    rewardPirate(event, reward)
    Traitormod.RoundEvents.SendEventMessage(message, "CrewWalletIconLarge")

    local delay = math.max(0, state.Config.EndRoundDelaySeconds)
    Timer.Wait(function ()
        if Game.RoundStarted then
            Game.EndGame()
        end
    end, delay * 1000)
end

local function checkEliminationWin(event)
    local state = event.UPCPirateState
    if state == nil or state.Completed or not state.EnteredMainSub then return end

    local trackedCount = 0
    for character in pairs(state.TrackedCrew) do
        trackedCount = trackedCount + 1
        if state.KillStates[character] ~= "pirate" then
            return
        end
    end

    if trackedCount == 0 then return end

    local aliveCrew = getAliveCrewOnMainSub()
    if #aliveCrew > 0 then return end

    complete(
        event,
        "EliminatedCrew",
        state.Config.EliminateCrewReward,
        string.format(Traitormod.Language.PirateEliminatedCrew, state.Config.EliminateCrewReward)
    )
end

helper.Start = function (event)
    local state = {
        Config = getConfig(event),
        EnteredMainSub = false,
        TrackedCrew = {},
        KillStates = {},
        CaptureStartedAt = nil,
        CaptureAnnounced = false,
        Completed = false,
        DeathHookId = event.Name .. ".UPCPirateDeath",
    }

    cleanupHooks(event.UPCPirateState)
    event.UPCPirateState = state

    Hook.Add("character.death", state.DeathHookId, function (character)
        local currentState = event.UPCPirateState
        if currentState == nil or currentState.Completed then return end
        if not currentState.EnteredMainSub then return end
        if character == nil or not currentState.TrackedCrew[character] then return end

        local causeOfDeath = character.CauseOfDeath
        local killer = causeOfDeath and causeOfDeath.Killer or nil

        if killer == event.Character then
            currentState.KillStates[character] = "pirate"
            checkEliminationWin(event)
        elseif currentState.KillStates[character] == nil then
            currentState.KillStates[character] = "other"
        end
    end)

    return state
end

helper.Update = function (event)
    local state = event.UPCPirateState
    if state == nil or state.Completed or event.Character == nil or event.Character.IsDead then
        return
    end

    local pirateOnMainSub = isPirateOnMainSub(event.Character)

    if pirateOnMainSub and not state.EnteredMainSub then
        state.EnteredMainSub = true
        event.EnteredMainSub = true
        Traitormod.RoundEvents.SendEventMessage(Traitormod.Language.PirateInside)
    end

    if not state.EnteredMainSub then
        return
    end

    local aliveCrew = getAliveCrewOnMainSub()
    for _, crewCharacter in pairs(aliveCrew) do
        state.TrackedCrew[crewCharacter] = true
    end

    if #aliveCrew == 0 then
        checkEliminationWin(event)
        if state.Completed then return end
    end

    if pirateOnMainSub and #aliveCrew == 0 then
        if state.CaptureStartedAt == nil then
            state.CaptureStartedAt = Timer.GetTime()
            if not state.CaptureAnnounced then
                state.CaptureAnnounced = true
                Traitormod.RoundEvents.SendEventMessage(string.format(Traitormod.Language.PirateCaptureStarted, math.ceil(state.Config.CaptureDurationSeconds)), "GameModeIcon.PVP")
            end
        elseif Timer.GetTime() >= state.CaptureStartedAt + state.Config.CaptureDurationSeconds then
            complete(
                event,
                "CapturedSubmarine",
                state.Config.CaptureReward,
                string.format(Traitormod.Language.PirateCapturedSubmarine, state.Config.CaptureReward)
            )
        end
        return
    end

    if state.CaptureStartedAt ~= nil then
        state.CaptureStartedAt = nil
        if state.CaptureAnnounced then
            state.CaptureAnnounced = false
            Traitormod.RoundEvents.SendEventMessage(Traitormod.Language.PirateCaptureInterrupted, "GameModeIcon.PVP")
        end
    end
end

helper.Stop = function (event)
    local state = event.UPCPirateState
    cleanupHooks(state)
    event.UPCPirateState = nil
end

helper.GetConfig = function (event)
    return getConfig(event)
end

return helper
