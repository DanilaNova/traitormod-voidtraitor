local hud = {}

hud.RoleStates = setmetatable({}, { __mode = "k" })
hud.ObjectiveStates = setmetatable({}, { __mode = "k" })
hud.NextRoleId = 0
hud.NextObjectiveId = 0
hud.UpdateInterval = 15.0
hud.RemoveInterval = 1.0
hud.UpdateTimer = hud.UpdateInterval
hud.RemoveTimer = hud.RemoveInterval
hud.CompletedRemoveDelay = 5.0
hud.Api = nil
hud.ApiChecked = false
hud.Disabled = false
hud.EventLogDisabled = false

local function asIdentifier(value)
    return Identifier(tostring(value or ""))
end

local function disableHud(message)
    if not hud.Disabled then
        Traitormod.Error("Objective HUD disabled: " .. tostring(message))
    end
    hud.Disabled = true
end

local function disableEventLog(message)
    if not hud.EventLogDisabled then
        Traitormod.Error("Objective HUD event log disabled: " .. tostring(message))
    end
    hud.EventLogDisabled = true
end

local function nextRoleId()
    hud.NextRoleId = hud.NextRoleId + 1
    return hud.NextRoleId
end

local function nextObjectiveId()
    hud.NextObjectiveId = hud.NextObjectiveId + 1
    return hud.NextObjectiveId
end

local function getClient(role)
    if role == nil or role.Character == nil or role.Character.IsBot then return nil end
    return Traitormod.FindClientCharacter(role.Character)
end

local function getRoleState(role)
    local state = hud.RoleStates[role]
    if state == nil then
        local id = tostring(Traitormod.RoundNumber) .. "_" .. tostring(nextRoleId())
        state = {
            Id = "voidtraitor_role_" .. id,
            LogId = "voidtraitor_log_" .. id,
            LastLogText = nil,
        }
        hud.RoleStates[role] = state
    end

    return state
end

local function getObjectiveState(objective)
    local state = hud.ObjectiveStates[objective]
    if state == nil then
        state = {
            BaseId = "voidtraitor_objective_" .. tostring(Traitormod.RoundNumber) .. "_" .. tostring(nextObjectiveId()),
            Version = 0,
            Id = nil,
            Text = nil,
            Added = false,
            PendingRemoval = false,
            RemoveAt = nil,
            Client = nil,
        }
        hud.ObjectiveStates[objective] = state
    end

    return state
end

local function resolveApi()
    if hud.Disabled then return nil end
    if hud.ApiChecked then return hud.Api end

    hud.ApiChecked = true

    local ok, apiOrError = pcall(function()
        local segmentActionType = nil
        local okEnum, enumTable = pcall(function()
            return LuaUserData.CreateEnumTable("Barotrauma.EventObjectiveAction+SegmentActionType")
        end)
        if okEnum then segmentActionType = enumTable end
        if segmentActionType == nil and EventObjectiveAction ~= nil then
            segmentActionType = EventObjectiveAction.SegmentActionType
        end

        local eventManager = EventManager
        if eventManager == nil then
            local okManager, manager = pcall(function()
                return LuaUserData.CreateStatic("Barotrauma.EventManager", true)
            end)
            if okManager then eventManager = manager end
        end

        local netObjective = nil
        local okObjective, objectiveCtor = pcall(function()
            return LuaUserData.CreateStatic("Barotrauma.EventManager+NetEventObjective", true)
        end)
        if okObjective then netObjective = objectiveCtor end

        local netEventLogEntry = nil
        local okLog, logCtor = pcall(function()
            return LuaUserData.CreateStatic("Barotrauma.EventManager+NetEventLogEntry", true)
        end)
        if okLog then netEventLogEntry = logCtor end

        if segmentActionType == nil then error("SegmentActionType is nil") end
        if eventManager == nil then error("EventManager is nil") end

        return {
            SegmentActionType = segmentActionType,
            EventManager = eventManager,
            NetEventObjective = netObjective,
            NetEventLogEntry = netEventLogEntry,
        }
    end)

    if not ok then
        disableHud(apiOrError)
        return nil
    end

    hud.Api = apiOrError
    return hud.Api
end

local function getObjectiveActionType(api, name)
    if api == nil or api.SegmentActionType == nil then return nil end
    return api.SegmentActionType[name]
end

function hud.SendObjectiveAction(client, actionName, identifier, text, parentIdentifier, canBeCompleted)
    if client == nil or identifier == nil or hud.Disabled then return false end

    local api = resolveApi()
    if api == nil then return false end

    local actionType = getObjectiveActionType(api, actionName)
    if actionType == nil then
        disableHud("unknown objective action type " .. tostring(actionName))
        return false
    end

    local ok, err = pcall(function()
        local args = {
            actionType,
            asIdentifier(identifier),
            asIdentifier(text),
            asIdentifier(""),
            asIdentifier(parentIdentifier or ""),
            canBeCompleted == true
        }

        local entry = nil
        if api.NetEventObjective ~= nil then
            local okCtor, result = pcall(function()
                return api.NetEventObjective(args[1], args[2], args[3], args[4], args[5], args[6])
            end)
            if okCtor then entry = result end
        end
        if entry == nil and api.EventManager.NetEventObjective ~= nil then
            entry = api.EventManager.NetEventObjective(args[1], args[2], args[3], args[4], args[5], args[6])
        end
        if entry == nil then error("NetEventObjective constructor is nil") end

        api.EventManager.ServerWriteObjective(client, entry)
    end)

    if not ok then
        disableHud(err)
        return false
    end

    return true
end

function hud.SendEventLog(client, logId, text)
    if client == nil or logId == nil or text == nil or hud.Disabled or hud.EventLogDisabled then return false end

    local api = resolveApi()
    if api == nil then return false end

    local ok, err = pcall(function()
        local entry = nil
        if api.NetEventLogEntry ~= nil then
            local okCtor, result = pcall(function()
                return api.NetEventLogEntry(
                    asIdentifier("voidtraitor_objectives"),
                    asIdentifier(logId),
                    tostring(text))
            end)
            if okCtor then entry = result end
        end
        if entry == nil and api.EventManager.NetEventLogEntry ~= nil then
            entry = api.EventManager.NetEventLogEntry(
                asIdentifier("voidtraitor_objectives"),
                asIdentifier(logId),
                tostring(text))
        end
        if entry == nil then error("NetEventLogEntry constructor is nil") end

        api.EventManager.ServerWriteEventLog(client, entry)
    end)

    if not ok then
        disableEventLog(err)
        return false
    end

    return true
end

function hud.GetRoleHeader(role)
    if role == nil then return nil end

    if role.Name == "Traitor" then
        return Traitormod.Language.ObjectiveHudTraitorSummary
    elseif role.Name == "Cultist" then
        return Traitormod.Language.ObjectiveHudCultistSummary
    elseif role.Name == "Clown" then
        return Traitormod.Language.ObjectiveHudClownSummary
    elseif role.Name == "Saboteur" then
        return Traitormod.Language.ObjectiveHudSaboteurSummary
    elseif role.Name == "HuskServant" then
        return Traitormod.Language.ObjectiveHudHuskServantSummary
    elseif role.Name == "Crew" then
        return Traitormod.Language.ObjectiveHudCrewSummary
    end

    return Traitormod.Language.ObjectiveHudGenericSummary
end

function hud.GetObjectiveText(objective)
    if objective == nil then return "" end

    local text = tostring(objective.Text or "")
    if objective.Failed then
        return text .. Traitormod.Language.Failed
    elseif objective.Awarded then
        return text .. Traitormod.Language.Completed
    elseif objective.AmountPoints ~= nil and objective.AmountPoints > 0 then
        return text .. string.format(Traitormod.Language.Points, objective.AmountPoints)
    end

    return text
end

function hud.AddObjective(role, objective)
    local client = getClient(role)
    if client == nil or objective == nil or objective.Awarded or objective.Failed then return end

    local state = getObjectiveState(objective)
    if state.PendingRemoval then return end

    local text = hud.GetObjectiveText(objective)

    if text == "" then return end

    if state.Added and state.Text == text then
        state.Client = client
        return
    end

    if state.Added and state.Id ~= nil then
        hud.SendObjectiveAction(client, "Remove", state.Id, nil, nil, false)
    end

    state.Version = state.Version + 1
    state.Id = state.BaseId .. "_" .. tostring(state.Version)
    state.Text = text
    state.Client = client
    state.Added = hud.SendObjectiveAction(client, "Add", state.Id, text, nil, true)
end

function hud.RefreshObjective(role, objective)
    local state = hud.ObjectiveStates[objective]
    if state ~= nil and state.PendingRemoval then return end

    if state == nil or not state.Added then
        hud.AddObjective(role, objective)
        return
    end

    local text = hud.GetObjectiveText(objective)
    if text == "" or text == state.Text then return end

    hud.AddObjective(role, objective)
end

function hud.CompleteObjective(character, objective, failed)
    if character == nil or character.IsBot or objective == nil then return end

    local client = Traitormod.FindClientCharacter(character)
    if client == nil then return end

    local state = hud.ObjectiveStates[objective]
    if state == nil or not state.Added or state.Id == nil or state.PendingRemoval then return end

    local action = failed and "Fail" or "Complete"
    if hud.SendObjectiveAction(client, action, state.Id, nil, nil, true) then
        state.Client = client
        state.PendingRemoval = true
        state.RemoveAt = Timer.GetTime() + hud.CompletedRemoveDelay
    end
end

function hud.SyncRoleLog(role)
    local client = getClient(role)
    if client == nil then return end

    local state = getRoleState(role)
    local sb = Traitormod.StringBuilder:new()
    sb("Void Traitor\n")
    sb(hud.GetRoleHeader(role) or "")

    if role.Objectives ~= nil and #role.Objectives > 0 then
        sb("\n\n%s", Traitormod.Language.ObjectiveHudCurrentObjectives)
        for _, objective in pairs(role.Objectives) do
            if objective ~= nil and not objective.Awarded and not objective.Failed then
                sb("\n> %s", hud.GetObjectiveText(objective))
            end
        end
    end

    local text = sb:concat("")
    if state.LastLogText == text then return end

    if hud.SendEventLog(client, state.LogId, text) then
        state.LastLogText = text
    end
end

function hud.SyncRole(role)
    if role == nil or role.Character == nil or role.Character.IsDead then return end

    if role.Objectives ~= nil then
        for _, objective in pairs(role.Objectives) do
            hud.AddObjective(role, objective)
        end
    end

    hud.SyncRoleLog(role)
end

function hud.UpdateRole(role)
    if role == nil or role.Character == nil or role.Character.IsDead then return end

    if role.Objectives ~= nil then
        for _, objective in pairs(role.Objectives) do
            hud.RefreshObjective(role, objective)
        end
    end

    hud.SyncRoleLog(role)
end

function hud.ClearRole(role)
    if role == nil then return end

    local client = getClient(role)
    if client ~= nil and role.Objectives ~= nil then
        for _, objective in pairs(role.Objectives) do
            local objectiveState = hud.ObjectiveStates[objective]
            if objectiveState ~= nil and objectiveState.Added and objectiveState.Id ~= nil then
                hud.SendObjectiveAction(client, "Remove", objectiveState.Id, nil, nil, false)
                objectiveState.Added = false
            end
        end
    end

end

function hud.RemoveCompletedObjectives()
    local now = Timer.GetTime()

    for objective, state in pairs(hud.ObjectiveStates) do
        if state ~= nil and state.PendingRemoval and state.RemoveAt ~= nil and now >= state.RemoveAt then
            if state.Client ~= nil and state.Id ~= nil then
                hud.SendObjectiveAction(state.Client, "Remove", state.Id, nil, nil, false)
            end
            state.Added = false
            state.PendingRemoval = false
            state.RemoveAt = nil
            state.Client = nil
        end
    end
end

function hud.UpdateAll(deltaTime)
    hud.RemoveTimer = hud.RemoveTimer + deltaTime
    if hud.RemoveTimer >= hud.RemoveInterval then
        hud.RemoveTimer = 0
        hud.RemoveCompletedObjectives()
    end

    hud.UpdateTimer = hud.UpdateTimer + deltaTime
    if hud.UpdateTimer < hud.UpdateInterval then return end
    hud.UpdateTimer = 0

    if Traitormod.RoleManager == nil then return end

    for character, role in pairs(Traitormod.RoleManager.RoundRoles) do
        if character ~= nil and role ~= nil and not character.IsDead then
            hud.UpdateRole(role)
        end
    end
end

Hook.Add("think", "Traitormod.ObjectiveHud.Think", function(deltaTime)
    if not Game.RoundStarted then return end
    hud.UpdateAll(deltaTime)
end)

function hud.Reset()
    hud.RoleStates = setmetatable({}, { __mode = "k" })
    hud.ObjectiveStates = setmetatable({}, { __mode = "k" })
    hud.ApiChecked = false
    hud.Api = nil
    hud.Disabled = false
    hud.EventLogDisabled = false
    hud.UpdateTimer = hud.UpdateInterval
    hud.RemoveTimer = hud.RemoveInterval
end

Hook.Add("roundStart", "Traitormod.ObjectiveHud.RoundStart", function()
    hud.Reset()
end)

return hud
