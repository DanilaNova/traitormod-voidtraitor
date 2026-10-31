---@class ClientMenu
local cm = {}

local vtNet = {
    Ready = "VoidTraitor_ClientMenuGuiReady",
    Request = "VoidTraitor_ClientMenuRequest",
    Snapshot = "VoidTraitor_ClientMenuSnapshot",
    Run = "VoidTraitor_ClientMenuRun",
}

local adminNet = {
    Request = "VoidTraitor_ClientMenuAdminRequest",
    Snapshot = "VoidTraitor_ClientMenuAdminSnapshot",
    DataRequest = "VoidTraitor_ClientMenuAdminDataRequest",
    DataSnapshot = "VoidTraitor_ClientMenuAdminData",
    RunV2 = "VoidTraitor_ClientMenuAdminRunV2",
}

local voteNet = {
    Ready = "VoidTraitor_LobbyVoteGuiReady",
    Request = "VoidTraitor_LobbyVoteRequest",
    Snapshot = "VoidTraitor_LobbyVoteSnapshot",
    Start = "VoidTraitor_LobbyVoteStart",
    Cast = "VoidTraitor_LobbyVoteCast",
}

local function parseInput(input)
    return Traitormod.ParseCommand(tostring(input or ""))
end

local function runCommand(commandName, client, input)
    local command = Traitormod.Commands[commandName]
    if command == nil or command.Callback == nil then
        Traitormod.SendMessage(client, Traitormod.Language.CommandNotActive)
        return true
    end

    local args = type(input) == "table" and input or parseInput(input)
    return command.Callback(client, args)
end

local function sendActionLog(client, actionId)
    Traitormod.Log(Traitormod.ClientLogName(client) .. " used client menu action: " .. tostring(actionId))
end

local function sendOClock(value)
    local oClock = math.floor(value / 30)
    if oClock == 0 then oClock = 12 end
    return Traitormod.FormatText("CMDOClock", oClock)
end

local function getGamemodeName()
    if Traitormod.SelectedGamemode == nil then return "" end
    return string.lower(tostring(Traitormod.SelectedGamemode.Name or ""))
end

local function isGamemode(name)
    return getGamemodeName() == string.lower(tostring(name or ""))
end

local function isAdmin(client)
    return client ~= nil and client.HasPermission(ClientPermissions.ConsoleCommands)
end

local function isAlive(client)
    return client ~= nil and client.Character ~= nil and not client.Character.IsDead
end

local function canUseAliveCharacter(client)
    if isAlive(client) then return true end
    return false, Traitormod.Language.CMDAliveToUse
end

local function canUseAlive(client)
    if not Game.RoundStarted or Traitormod.SelectedGamemode == nil then
        return false, Traitormod.Language.RoundNotStarted
    end
    if isAdmin(client) or not isAlive(client) then return true end
    return false, Traitormod.Language.CMDAliveDeadOnly
end

local function canLocateSub(client)
    if not isAlive(client) or not client.InGame then
        return false, Traitormod.Language.CMDAliveToUse
    end
    if client.Character.IsHuman and client.Character.TeamID == CharacterTeamType.Team1 then
        return false, Traitormod.Language.CMDOnlyMonsters
    end
    return true
end

local function canDropPoints(client)
    if not isAlive(client) or client.Character.Inventory == nil then
        return false, Traitormod.Language.CMDAliveToUse
    end
    if math.floor(tonumber(Traitormod.GetData(client, "Points") or 0) or 0) < 100 then
        return false, Traitormod.GetText("CMDDropPointsNotEnough")
    end
    return true
end

local function canUseFakeHandcuffs(client)
    if not isAlive(client) or not client.Character.IsHuman or client.Character.Inventory == nil then return false end

    local item = client.Character.Inventory.GetItemInLimbSlot(InvSlotType.RightHand)
    return item ~= nil and item.Prefab.Identifier == "handcuffs" and item.HasTag("fakehandcuffs")
end

local function canLocatePlayers(client)
    if not isGamemode("SubmarineRoyale") then
        return false, Traitormod.GetText("CMDPlayersSubmarineRoyaleOnly")
    end
    if not isAlive(client) or not client.InGame then
        return false, Traitormod.Language.CMDAliveToUse
    end
    return true
end

local actions = {}
local orderedActions = {}

local function addAction(id, order, callback, inputType, condition, hideWhenUnavailable)
    local action = {
        Id = id,
        Order = order or 0,
        Callback = callback,
        InputType = inputType or "",
        Condition = condition,
        HideWhenUnavailable = hideWhenUnavailable == true,
    }

    actions[id] = action
    table.insert(orderedActions, action)
end

addAction("role", 10, function(client, input)
    return runCommand("!role", client, input)
end, nil, canUseAliveCharacter)

addAction("points", 11, function(client, input)
    return runCommand("!points", client, input)
end)

addAction("status", 12, function(client, input)
    return runCommand("!status", client, input)
end, nil, canUseAliveCharacter)

addAction("toggletraitor", 13, function(client, input)
    return runCommand("!toggletraitor", client, input)
end, nil, function() return Traitormod.Config.OptionalTraitors == true end, true)

addAction("suicide", 20, function(client, input)
    return runCommand("!suicide", client, input)
end, "", canUseAliveCharacter)

addAction("droppoints", 21, function(client, input)
    return runCommand("!droppoints", client, input)
end, "number", canDropPoints)

addAction("freehandcuffs", 23, function(client, input)
    return runCommand("!freehandcuffs", client, input)
end, nil, canUseFakeHandcuffs, true)

addAction("roundtime", 30, function(client, input)
    return runCommand("!roundtime", client, input)
end)

addAction("locatesub", 31, function(client, input)
    return runCommand("!locatesub", client, input)
end, nil, canLocateSub)

addAction("alive", 32, function(client, input)
    return runCommand("!alive", client, input)
end, nil, canUseAlive)

addAction("players", 33, function(client)
    if Traitormod.SelectedGamemode == nil or Traitormod.SelectedGamemode.Name ~= "SubmarineRoyale" then
        Traitormod.SendMessage(client, Traitormod.Language.CommandNotActive)
        return true
    end

    if client.Character == nil or not client.InGame then
        Traitormod.SendMessage(client, Traitormod.Language.CMDAliveToUse)
        return true
    end

    local text = ""
    local center = client.Character.WorldPosition
    for _, targetClient in pairs(Client.ClientList) do
        if targetClient.Character and not targetClient.Character.IsDead then
            local target = targetClient.Character.WorldPosition
            local distance = Vector2.Distance(center, target) * Physics.DisplayToRealWorldRatio
            local diff = center - target
            local angle = math.deg(math.atan2(diff.X, diff.Y)) + 180
            local submarineName = targetClient.Character.Submarine and targetClient.Character.Submarine.Info.Name or Traitormod.Language.Unknown
            text = text .. string.format(Traitormod.Language.CMDLocatePlayer, targetClient.Name, math.floor(distance), sendOClock(angle), submarineName) .. "\n"
        end
    end

    Game.SendDirectChatMessage("", text, nil, ChatMessageType.Error, client)
    return true
end, nil, canLocatePlayers)

addAction("info", 40, function(client, input)
    return runCommand("!info", client, input)
end)

addAction("playtime", 41, function(client, input)
    return runCommand("!playtime", client, input)
end)

addAction("stats", 42, function(client, input)
    return runCommand("!stats", client, input)
end)

addAction("version", 43, function(client, input)
    return runCommand("!version", client, input)
end)

local adminActions = {}
local orderedAdminActions = {}

local function addAdminAction(id, command, order, inputType)
    local action = {
        Id = id,
        Command = command,
        Order = order,
        InputType = inputType or "",
    }
    adminActions[id] = action
    table.insert(orderedAdminActions, action)
end

addAdminAction("roundinfo", "!roundinfo", 10)
addAdminAction("roles", "!roles", 11)
addAdminAction("traitoralive", "!traitoralive", 12)
addAdminAction("allpoints", "!allpoints", 13)
addAdminAction("ongoingevents", "!ongoingevents", 14)
addAdminAction("endroundnow", "!endroundnow", 15)
addAdminAction("revive", "!revive", 20, "player")
addAdminAction("void", "!void", 21, "player")
addAdminAction("unvoid", "!unvoid", 22, "player")
addAdminAction("addpoint", "!addpoint", 23, "playeramount")
addAdminAction("addlife", "!addlife", 24, "playeramount")
addAdminAction("giveghostrole", "!giveghostrole", 30, "ghostrole")
addAdminAction("assignrole", "!assignrole", 31, "assignrole")
addAdminAction("triggerevent", "!triggerevent", 32, "event")

table.sort(orderedAdminActions, function(a, b)
    if a.Order ~= b.Order then return a.Order < b.Order end
    return a.Id < b.Id
end)

table.sort(orderedActions, function(a, b)
    if a.Order ~= b.Order then return a.Order < b.Order end
    return a.Id < b.Id
end)

local function getVisibleActions(client)
    local visible = {}

    for _, action in ipairs(orderedActions) do
        local enabled = true
        local disabledReason = ""
        if action.Condition ~= nil then
            local allowed, reason = action.Condition(client)
            enabled = allowed == true
            disabledReason = tostring(reason or "")
        end

        if enabled or not action.HideWhenUnavailable then
            table.insert(visible, {
                Action = action,
                Enabled = enabled,
                DisabledReason = disabledReason,
            })
        end
    end

    return visible
end

function cm.SendSnapshot(client)
    if client == nil or client.Connection == nil then return false end

    local visibleActions = getVisibleActions(client)
    local netMessage = Networking.Start(vtNet.Snapshot)
    netMessage.WriteInt32(#visibleActions)

    for _, entry in ipairs(visibleActions) do
        netMessage.WriteString(entry.Action.Id)
        netMessage.WriteBoolean(entry.Enabled)
        netMessage.WriteString(entry.DisabledReason)
        netMessage.WriteString(entry.Action.InputType)
    end

    Networking.Send(netMessage, client.Connection)
    return true
end

function cm.SendAdminSnapshot(client)
    if client == nil or client.Connection == nil then return false end

    local hasAccess = isAdmin(client)
    local netMessage = Networking.Start(adminNet.Snapshot)
    netMessage.WriteBoolean(hasAccess)
    netMessage.WriteInt32(hasAccess and #orderedAdminActions or 0)

    if hasAccess then
        for _, action in ipairs(orderedAdminActions) do
            netMessage.WriteString(action.Id)
            netMessage.WriteString(action.InputType)
        end
    end

    Networking.Send(netMessage, client.Connection)
    return true
end


function cm.SendAdminData(client)
    if client == nil or client.Connection == nil then return false end

    local hasAccess = isAdmin(client)
    local netMessage = Networking.Start(adminNet.DataSnapshot)
    netMessage.WriteBoolean(hasAccess)

    if hasAccess then
        local players = {}
        for _, target in pairs(Client.ClientList) do
            table.insert(players, {
                Key = Traitormod.GetClientAccountKey(target),
                Name = tostring(target.Name or ""),
                CharacterName = target.Character ~= nil and tostring(target.Character.Name or "") or "",
                HasCharacter = target.Character ~= nil,
                IsDead = target.Character ~= nil and target.Character.IsDead == true,
            })
        end
        table.sort(players, function(a, b) return string.lower(a.Name) < string.lower(b.Name) end)

        netMessage.WriteInt32(#players)
        for _, target in ipairs(players) do
            netMessage.WriteString(target.Key)
            netMessage.WriteString(target.Name)
            netMessage.WriteString(target.CharacterName)
            netMessage.WriteBoolean(target.HasCharacter)
            netMessage.WriteBoolean(target.IsDead)
        end

        local roles = {}
        for identifier, role in pairs(Traitormod.RoleManager.Roles or {}) do
            table.insert(roles, {
                Id = tostring(identifier),
                Name = tostring(role.Name or identifier),
            })
        end
        table.sort(roles, function(a, b) return string.lower(a.Name) < string.lower(b.Name) end)

        netMessage.WriteInt32(#roles)
        for _, role in ipairs(roles) do
            netMessage.WriteString(role.Id)
            netMessage.WriteString(role.Name)
        end

        local events = {}
        local eventConfigs = Traitormod.RoundEvents
            and Traitormod.RoundEvents.EventConfigs
            and Traitormod.RoundEvents.EventConfigs.Events
            or {}
        for _, event in pairs(eventConfigs) do
            if event.Name ~= nil then table.insert(events, tostring(event.Name)) end
        end
        table.sort(events, function(a, b) return string.lower(a) < string.lower(b) end)

        netMessage.WriteInt32(#events)
        for _, eventName in ipairs(events) do
            netMessage.WriteString(eventName)
        end

    end

    Networking.Send(netMessage, client.Connection)
    return true
end

function cm.RunAdminActionV2(client, actionId, targetKey, value)
    if not isAdmin(client) then return true end

    local action = adminActions[tostring(actionId or "")]
    if action == nil then return true end

    local inputType = action.InputType
    local args = {}
    local target = nil
    if inputType == "player" or inputType == "playeramount" or inputType == "assignrole" then
        target = Traitormod.FindClient(tostring(targetKey or ""))
        if target == nil then
            Traitormod.SendMessage(client, Traitormod.Language.CMDClientNotFound)
            return true
        end
    end

    if inputType == "player" then
        args = { Traitormod.GetClientAccountKey(target) }
    elseif inputType == "playeramount" then
        args = { Traitormod.GetClientAccountKey(target), tostring(value or "") }
    elseif inputType == "ghostrole" then
        args = { tostring(value or ""), tostring(targetKey or "") }
    elseif inputType == "assignrole" then
        args = { Traitormod.GetClientAccountKey(target), tostring(value or "") }
    elseif inputType == "event" then
        args = { tostring(value or "") }
    end

    sendActionLog(client, "admin:" .. action.Id)
    local result = runCommand(action.Command, client, args)
    if action.Id == "revive" then cm.SendAdminData(client) end
    return result
end

function cm.RunAction(client, actionId, input)
    if client == nil then return true end

    actionId = tostring(actionId or "")
    local action = actions[actionId]
    if action == nil or action.Callback == nil then return true end
    if action.Condition ~= nil and action.Condition(client) ~= true then return true end

    sendActionLog(client, actionId)
    return action.Callback(client, input)
end

Networking.Receive(vtNet.Ready, function(message, client)
    return cm.SendSnapshot(client)
end)

Networking.Receive(vtNet.Request, function(message, client)
    return cm.SendSnapshot(client)
end)

Networking.Receive(vtNet.Run, function(message, client)
    local actionId = message.ReadString()
    local input = message.ReadString()
    return cm.RunAction(client, actionId, input)
end)

Networking.Receive(adminNet.Request, function(message, client)
    return cm.SendAdminSnapshot(client)
end)

Networking.Receive(adminNet.DataRequest, function(message, client)
    return cm.SendAdminData(client)
end)

Networking.Receive(adminNet.RunV2, function(message, client)
    local actionId = message.ReadString()
    local targetKey = message.ReadString()
    local value = message.ReadString()
    return cm.RunAdminActionV2(client, actionId, targetKey, value)
end)

local function writeVoteSnapshot(netMessage, client)
    local snapshot = nil
    if Traitormod.Voting ~= nil and Traitormod.Voting.GetGuiSnapshot ~= nil then
        snapshot = Traitormod.Voting.GetGuiSnapshot(client)
    end

    snapshot = snapshot or {}
    netMessage.WriteString(tostring(snapshot.StartBlockedReason or ""))
    netMessage.WriteBoolean(snapshot.CanStart == true)

    local active = snapshot.Active
    netMessage.WriteBoolean(active ~= nil)
    if active ~= nil then
        netMessage.WriteString(tostring(active.Id or ""))
        netMessage.WriteString(tostring(active.Type or ""))
        netMessage.WriteString(tostring(active.StartedBy or ""))
        netMessage.WriteInt32(math.max(0, math.floor(tonumber(active.Remaining or 0) or 0)))
        netMessage.WriteInt32(math.max(1, math.floor(tonumber(active.Duration or 1) or 1)))

        local options = active.Options or {}
        netMessage.WriteInt32(#options)
        for _, option in ipairs(options) do
            netMessage.WriteInt32(tonumber(option.Index or 0) or 0)
            netMessage.WriteString(tostring(option.Text or ""))
            netMessage.WriteInt32(math.max(0, math.floor(tonumber(option.Votes or 0) or 0)))
            netMessage.WriteBoolean(option.Selected == true)
        end
    end

    netMessage.WriteInt32(math.max(0, math.floor(tonumber(snapshot.GameCooldownRemaining or 0) or 0)))
    netMessage.WriteInt32(math.max(0, math.floor(tonumber(snapshot.MapCooldownRemaining or 0) or 0)))
end

function cm.SendVoteSnapshot(client)
    if client == nil or client.Connection == nil then return false end

    local netMessage = Networking.Start(voteNet.Snapshot)
    writeVoteSnapshot(netMessage, client)
    Networking.Send(netMessage, client.Connection)
    return true
end

function cm.SendVoteSnapshotEveryone()
    for _, client in pairs(Client.ClientList) do
        cm.SendVoteSnapshot(client)
    end
end

Networking.Receive(voteNet.Ready, function(message, client)
    return cm.SendVoteSnapshot(client)
end)

Networking.Receive(voteNet.Request, function(message, client)
    return cm.SendVoteSnapshot(client)
end)

Networking.Receive(voteNet.Start, function(message, client)
    local voteType = message.ReadString()
    if Traitormod.Voting ~= nil and Traitormod.Voting.StartGuiVote ~= nil then
        Traitormod.Voting.StartGuiVote(client, voteType)
    end
    return cm.SendVoteSnapshot(client)
end)

Networking.Receive(voteNet.Cast, function(message, client)
    local optionId = message.ReadInt32()
    if Traitormod.Voting ~= nil and Traitormod.Voting.CastGuiVote ~= nil then
        Traitormod.Voting.CastGuiVote(client, optionId)
    end
    -- An accepted vote already reaches everyone through Voting's change notification.
    return cm.SendVoteSnapshot(client)
end)

local pointshopNet = Traitormod.Pointshop and Traitormod.Pointshop.GuiNet or nil
if pointshopNet ~= nil then
    Networking.Receive(pointshopNet.Ready, function(message, client)
        return Traitormod.Pointshop.MarkGuiClientReady(client)
    end)

    Networking.Receive(pointshopNet.Request, function(message, client)
        return Traitormod.Pointshop.RequestGuiSnapshot(client)
    end)

    Networking.Receive(pointshopNet.BuyCart, function(message, client)
        local count = math.clamp(message.ReadInt32(), 0, 32)
        local entries = {}
        for i = 1, count do
            table.insert(entries, {
                Id = message.ReadString(),
                Quantity = message.ReadInt32(),
            })
        end

        return Traitormod.Pointshop.HandleGuiCart(client, entries)
    end)
end

Hook.Add("client.disconnected", "Traitormod.ClientMenu.Disconnect", function(client)
    if Traitormod.Pointshop ~= nil and Traitormod.Pointshop.ForgetGuiClient ~= nil then
        Traitormod.Pointshop.ForgetGuiClient(client)
    end
end)

return cm
