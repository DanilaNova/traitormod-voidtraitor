----- USER COMMANDS -----
Traitormod.AddCommand("!help", function (client, args)
    Traitormod.SendMessage(client, Traitormod.Language.Help)

    return true
end)

Traitormod.AddCommand("!helpadmin", function (client, args)
    Traitormod.SendMessage(client, Traitormod.Language.HelpAdmin)

    return true
end)

Traitormod.AddCommand("!helptraitor", function (client, args)
    Traitormod.SendMessage(client, Traitormod.Language.HelpTraitor)

    return true
end)

Traitormod.AddCommand("!version", function (client, args)
    Traitormod.SendMessage(client, string.format(Traitormod.Language.CMDVersion, Traitormod.VERSION))

    return true
end)

Traitormod.AddCommand({"!role", "!traitor"}, function (client, args)
    if client.Character == nil or client.Character.IsDead then
        Traitormod.SendMessage(client, Traitormod.Language.CMDAliveToUse)
        return true
    end

    local role = Traitormod.RoleManager.GetRole(client.Character)
    if role == nil then
        Traitormod.SendMessage(client, Traitormod.Language.CMDNoRole)
    else
        if Traitormod.ObjectiveHud ~= nil then
            Traitormod.ObjectiveHud.SyncRole(role)
        end

        Traitormod.SendMessage(client, role:Greet())
    end

    return true
end)

Traitormod.AddCommand({"!roles", "!traitors"}, function (client, args)
    if not client.HasPermission(ClientPermissions.ConsoleCommands) then return end

    local roles = {}

    for character, role in pairs(Traitormod.RoleManager.RoundRoles) do
        if not roles[role.Name] then
            roles[role.Name] = {}
        end

        table.insert(roles[role.Name], character.Name)
    end

    local message = ""

    for roleName, r in pairs(roles) do
        message = message .. roleName .. ": "
        for _, name in pairs(r) do
            message = message .. "\"" .. name .. "\" "
        end
        message = message .. "\n\n"
    end

    if message == "" then message = "None." end

    Traitormod.SendMessage(client, message)

    return true
end)

Traitormod.AddCommand("!traitoralive", function (client, args)
    if not client.HasPermission(ClientPermissions.ConsoleCommands) then return end

    for _, character in pairs(Traitormod.RoleManager.FindAntagonists()) do
        if not character.IsDead then
            Traitormod.SendMessage(client, Traitormod.Language.TraitorsAlive)
            return true
        end
    end

    Traitormod.SendMessage(client, Traitormod.Language.AllTraitorsDead)
    return true
end)

Traitormod.AddCommand("!toggletraitor", function (client, args)
    local text = Traitormod.Language.CommandNotActive

    if Traitormod.Config.OptionalTraitors then
        local toggle = false
        if #args > 0 then
            toggle = string.lower(args[1]) == "on"
        else
            toggle = Traitormod.GetData(client, "NonTraitor") == true
        end
    
        if toggle then
            text = Traitormod.Language.TraitorOn
        else
            text = Traitormod.Language.TraitorOff
        end
        Traitormod.SetData(client, "NonTraitor", not toggle)
        Traitormod.SaveData() -- move this to player disconnect someday...
        
        Traitormod.Log(Traitormod.ClientLogName(client) .. " can become traitor: " .. tostring(toggle))
    end

    Traitormod.SendMessage(client, text)

    return true
end)

Traitormod.AddCommand({"!point", "!points"}, function (client, args)
    Traitormod.SendMessage(client, Traitormod.GetDataInfo(client, true))

    return true
end)

Traitormod.AddCommand("!switchtest", function (client, args)
    local activePlayers = 0
    for player in Client.ClientList do
        if not player.SpectateOnly then
            activePlayers = activePlayers + 1
        end
    end

    local gamemode = Traitormod.SelectedGamemode
    if activePlayers ~= 1 or not Traitormod.Config.TestMode or gamemode == nil or gamemode.SwitchTestTeam == nil then
        Traitormod.SendMessage(client, Traitormod.GetText("CMDSwitchTestUnavailable"))
        return true
    end

    local teamID = gamemode:SwitchTestTeam(client)
    if teamID == nil then
        Traitormod.SendMessage(client, Traitormod.GetText("CMDSwitchTestUnavailable"))
        return true
    end

    Traitormod.SendMessage(client, Traitormod.FormatText("CMDSwitchTestChanged", gamemode.Teams[teamID].Name))
    return true
end)

Traitormod.AddCommand("!status", function (client, args)
    if client.Character == nil or client.Character.IsDead then
        Traitormod.SendMessage(client, Traitormod.Language.StatusAliveRequired)
        return true
    end

    Traitormod.SendMessage(client, Traitormod.GetStatusMessage(client.Character))

    return true
end)

Traitormod.AddCommand("!info", function (client, args)
    Traitormod.SendWelcome(client)
    
    return true
end)

Traitormod.AddCommand("!startgamevote", function (client, args)
    return Traitormod.Voting.StartGameVote(client)
end)

Traitormod.AddCommand("!startmapvote", function (client, args)
    return Traitormod.Voting.StartMapVote(client)
end)

Traitormod.AddCommand("!vote", function (client, args)
    if Traitormod.Voting.TryHandleGameVoteCommand(client, args) then
        return true
    end

    if not client.HasPermission(ClientPermissions.ConsoleCommands) then return end
    if not client.InGame then
        Traitormod.SendMessage(client, Traitormod.GetText("CMDInGameToUse"))
        return true
    end

    if #args < 3 then
        Traitormod.SendMessage(client, Traitormod.GetText("CMDVoteUsage"))
        return true
    end

    local text = table.remove(args, 1)

    Traitormod.Voting.StartVote(text, args, 25, function(results)
        local message = Traitormod.StringBuilder:new()
        message(Traitormod.GetText("CMDVoteResultsHeader"), text)
        for key, value in pairs(results) do
            message(Traitormod.GetText("CMDVoteResultsLine"), args[key], value)
        end

        for _, target in pairs(Client.ClientList) do
            local chatMessage = ChatMessage.Create("", message:concat(), ChatMessageType.Default, nil, nil)
            chatMessage.Color = Color(255, 255, 255, 255)
            Game.SendDirectChatMessage(chatMessage, target)
        end
    end)

    return true
end)

Traitormod.AddCommand({"!suicide", "!kill", "!death"}, function (client, args)
    
    if client.Character == nil or client.Character.IsDead then
        Traitormod.SendMessage(client, Traitormod.Language.CMDAlreadyDead)
        return true
    end

    if Traitormod.SelectedGamemode.TraitormodSettings.LimitedSuicide then
        if client.Character.IsHuman then
            local item = client.Character.Inventory.GetItemInLimbSlot(InvSlotType.RightHand)
            if item ~= nil and item.Prefab.Identifier == "handcuffs" then
                Traitormod.SendMessage(client, Traitormod.Language.CMDHandcuffed)
                return true
            end

            if client.Character.IsKnockedDown then
                Traitormod.SendMessage(client, Traitormod.Language.CMDKnockedDown)
                return true
            end
        end
    end

    if Traitormod.GhostRoles.ReturnGhostRole(client.Character) then
        client.SetClientCharacter(nil)
    else
        client.Character.Kill(CauseOfDeathType.Unknown)
    end
    return true
end)

----- ADMIN COMMANDS -----
Traitormod.AddCommand("!alive", function (client, args)
    if not (client.Character == nil or client.Character.IsDead) and not client.HasPermission(ClientPermissions.ConsoleCommands) then
        Traitormod.SendMessage(client, Traitormod.Language.CMDAliveDeadOnly)
        return true
    end

    if not Game.RoundStarted or Traitormod.SelectedGamemode == nil then
        Traitormod.SendMessage(client, Traitormod.Language.RoundNotStarted)

        return true
    end

    local msg = ""
    for index, value in pairs(Character.CharacterList) do
        if value.IsHuman and not value.IsBot then
            if value.IsDead then
                msg = msg .. value.Name .. " ---- " .. Traitormod.Language.Dead .. "\n"
            else
                msg = msg .. value.Name .. " ++++ " .. Traitormod.Language.Alive .. "\n"
            end
        end
    end

    Traitormod.SendMessage(client, msg)

    return true
end)

Traitormod.AddCommand("!roundinfo", function (client, args)
    if not client.HasPermission(ClientPermissions.ConsoleCommands) then return end

    if Game.RoundStarted and Traitormod.SelectedGamemode and Traitormod.SelectedGamemode.RoundSummary then
        local summary = Traitormod.SelectedGamemode:RoundSummary()
        Traitormod.SendMessage(client, summary)
    elseif Game.RoundStarted and not Traitormod.SelectedGamemode then
        Traitormod.SendMessage(client, Traitormod.Language.GamemodeNone)
    elseif Traitormod.LastRoundSummary ~= nil then
        Traitormod.SendMessage(client, Traitormod.LastRoundSummary)
    else
        Traitormod.SendMessage(client, Traitormod.Language.RoundNotStarted)
    end

    return true
end)

Traitormod.AddCommand("!endroundnow", function (client, args)
    if not client.HasPermission(ClientPermissions.ConsoleCommands) then return end

    local selected = Traitormod.SelectedGamemode
    if not Game.RoundStarted or selected == nil or selected.Name ~= "Secret" or not selected.Ending then
        Traitormod.SendMessage(client, Traitormod.Language.CommandNotActive)
        return true
    end

    selected.AllowRealEndGame = true
    Game.EndGame()
    return true
end)

Traitormod.AddCommand({"!allpoint", "!allpoints"}, function (client, args)
    if not client.HasPermission(ClientPermissions.ConsoleCommands) then return end
    
    local messageToSend = ""

    for index, value in pairs(Client.ClientList) do
        messageToSend = messageToSend .. "\n" .. Traitormod.FormatText("CMDAllPointsLine", value.Name, math.floor(Traitormod.GetData(value, "Points") or 0), math.floor(Traitormod.GetData(value, "Weight") or 0))
    end

    Traitormod.SendMessage(client, messageToSend)

    return true
end)

Traitormod.AddCommand({"!addpoint", "!addpoints"}, function (client, args)
    if not client.HasPermission(ClientPermissions.ConsoleCommands) then
        Traitormod.SendMessage(client, Traitormod.Language.CMDPermisionPoints)
        return
    end
    
    if #args < 2 then
        Traitormod.SendMessage(client, Traitormod.GetText("CMDAddPointUsage"))

        return true
    end

    local name = table.remove(args, 1)
    local amount = tonumber(table.remove(args, 1))

    if amount == nil or amount ~= amount then
        Traitormod.SendMessage(client, Traitormod.Language.CMDInvalidNumber)
        return true
    end

    if name == "all" then
        for index, value in pairs(Client.ClientList) do
            Traitormod.AddData(value, "Points", amount)
        end

        Traitormod.SendMessage(client, string.format(Traitormod.Language.PointsAwarded, amount), "InfoFrameTabButton.Mission")

        local msg = string.format(Traitormod.Language.CMDAdminAddedPointsEveryone, amount)
        Traitormod.SendMessageEveryone(msg)
        msg = Traitormod.ClientLogName(client) .. ": " .. msg
        Traitormod.Log(msg)

        return true
    end

    local found = Traitormod.FindClient(name)

    if found == nil then
        Traitormod.SendMessage(client, Traitormod.Language.CMDClientNotFound .. name)
        return true
    end

    Traitormod.AddData(found, "Points", amount)

    Traitormod.SendMessage(client, string.format(Traitormod.Language.PointsAwarded, amount), "InfoFrameTabButton.Mission")

    local msg = string.format(Traitormod.Language.CMDAdminAddedPoints, amount, Traitormod.ClientLogName(found))
    Traitormod.SendMessageEveryone(msg)
    msg = Traitormod.ClientLogName(client) .. ": " .. msg
    Traitormod.Log(msg)

    return true
end)

Traitormod.AddCommand({"!addlife", "!addlive", "!addlifes", "!addlives"}, function (client, args)
    if not client.HasPermission(ClientPermissions.ConsoleCommands) then return end

    if #args < 1 then
        Traitormod.SendMessage(client, Traitormod.GetText("CMDAddLifeUsage"))

        return true
    end

    local name = table.remove(args, 1)

    local amount = 1
    if #args > 0 then
        amount = tonumber(table.remove(args, 1))
    end

    if amount == nil or amount ~= amount then
        Traitormod.SendMessage(client, Traitormod.Language.CMDInvalidNumber)
        return true
    end

    local gainLifeClients = {}
    if string.lower(name) == "all" then
        for lifeClient in Client.ClientList do
            table.insert(gainLifeClients, lifeClient)
        end
    else
        local found = Traitormod.FindClient(name)

        if found == nil then
            Traitormod.SendMessage(client, Traitormod.Language.CMDClientNotFound .. name)
            return true
        end
        table.insert(gainLifeClients, found)
    end

    for _, lifeClient in ipairs(gainLifeClients) do
        local lifeMsg, lifeIcon = Traitormod.AdjustLives(lifeClient, amount)
        local msg = string.format(Traitormod.Language.CMDAdminAddedLives, amount, Traitormod.ClientLogName(lifeClient))

        if lifeMsg then
            Traitormod.SendMessage(lifeClient, lifeMsg, lifeIcon)
            Traitormod.SendMessageEveryone(msg)
        else
            Game.SendDirectChatMessage("", Traitormod.FormatText("CMDAlreadyMaximumLives", Traitormod.ClientLogName(lifeClient)), nil, ChatMessageType.Error, client)
        end
    end

    return true
end)

local voidPos = {}

Traitormod.AddCommand("!void", function (client, args)
    if not client.HasPermission(ClientPermissions.ConsoleCommands) then return end

    local target = Traitormod.FindClient(args[1])

    if not target then
        Traitormod.SendMessage(client, Traitormod.Language.CMDClientNotFound)
        return true
    end

    if target.Character == nil or target.Character.IsDead then
        Traitormod.SendMessage(client, Traitormod.GetText("CMDCharacterDeadOrMissing"))
        return true
    end

    voidPos[target.Character] = target.Character.WorldPosition
    target.Character.TeleportTo(Vector2(0, Level.Loaded.Size.Y + 100000))
    target.Character.GodMode = true

    Traitormod.SendMessage(client, Traitormod.GetText("CMDVoidSent"))

    return true
end)

Traitormod.AddCommand("!unvoid", function (client, args)
    if not client.HasPermission(ClientPermissions.ConsoleCommands) then return end

    local target = Traitormod.FindClient(args[1])

    if not target then
        Traitormod.SendMessage(client, Traitormod.Language.CMDClientNotFound)
        return true
    end

    if target.Character == nil or target.Character.IsDead then
        Traitormod.SendMessage(client, Traitormod.GetText("CMDCharacterDeadOrMissing"))
        return true
    end

    local originalPosition = voidPos[target.Character]
    if originalPosition == nil then
        Traitormod.SendMessage(client, Traitormod.GetText("CMDVoidNotInVoid"))
        return true
    end

    target.Character.TeleportTo(originalPosition)
    target.Character.GodMode = false
    voidPos[target.Character] = nil
    
    Traitormod.SendMessage(client, Traitormod.GetText("CMDVoidRemoved"))

    return true
end)

Traitormod.AddCommand("!revive", function (client, args)
    if not client.HasPermission(ClientPermissions.ConsoleCommands) then return end

    local reviveClient = client

    if #args > 0 then
        -- if client name is given, revive related character
        local name = table.remove(args, 1)
        -- find character by client name or account id
        for player in Client.ClientList do
            if player.Name == name or Traitormod.GetClientAccountKey(player) == name or Traitormod.GetClientLegacySteamId(player) == name then
                reviveClient = player
            end
        end
    end

    if reviveClient.Character and reviveClient.Character.IsDead then
        reviveClient.Character.Revive()
        Timer.Wait(function ()
            reviveClient.SetClientCharacter(reviveClient.Character)
        end, 1500)
        local liveMsg, liveIcon = Traitormod.AdjustLives(reviveClient, 1)

        if liveMsg then
            Traitormod.SendMessage(reviveClient, liveMsg, liveIcon)
        end

        Game.SendDirectChatMessage("", Traitormod.FormatText("CMDReviveSuccess", Traitormod.ClientLogName(reviveClient)), nil, ChatMessageType.Error, client)
        Traitormod.SendMessageEveryone(Traitormod.FormatText("CMDReviveAnnounce", Traitormod.ClientLogName(reviveClient)))

    elseif reviveClient.Character then
        Game.SendDirectChatMessage("", Traitormod.FormatText("CMDReviveNotDead", Traitormod.ClientLogName(reviveClient)), nil, ChatMessageType.Error, client)
    else
        Game.SendDirectChatMessage("", Traitormod.FormatText("CMDReviveNotFound", Traitormod.ClientLogName(reviveClient)), nil, ChatMessageType.Error, client)
    end

    return true
end)

Traitormod.AddCommand("!ongoingevents", function (client, args)
    if not client.HasPermission(ClientPermissions.ConsoleCommands) then return end

    local text = Traitormod.GetText("CMDOngoingEvents")
    for key, value in pairs(Traitormod.RoundEvents.OnGoingEvents) do
        text = text .. "\"" .. value.Name .. "\" "
    end

    Traitormod.SendMessage(client, text)

    return true
end)

Traitormod.AddCommand("!giveghostrole", function (client, args)
    if not client.HasPermission(ClientPermissions.ConsoleCommands) then return end

    if #args < 2 then
        Traitormod.SendMessage(client, Traitormod.GetText("CMDGiveGhostRoleUsage"))
        return true
    end

    local target

    for key, value in pairs(Character.CharacterList) do
        if value.Name == args[2] and not value.IsDead then
            target = value
            break
        end
    end

    if not target then
        Traitormod.SendMessage(client, Traitormod.Language.CMDCharacterNotFound)
        return true
    end

    Traitormod.GhostRoles.Create("system.manual", target, { Name = args[1] })

    return true
end)

Traitormod.AddCommand("!roundtime", function (client, args)
    Traitormod.SendMessage(client, string.format(Traitormod.Language.CMDRoundTime, Traitormod.FormatTime(math.ceil(Traitormod.RoundTime))))

    return true
end)

Traitormod.AddCommand("!assignrolecharacter", function (client, args)
    if not client.HasPermission(ClientPermissions.ConsoleCommands) then return end
    
    if #args < 2 then
        Traitormod.SendMessage(client, Traitormod.GetText("CMDAssignRoleCharacterUsage"))
        return true
    end

    local target

    for key, value in pairs(Character.CharacterList) do
        if value.Name == args[1] then
            target = value
            break
        end
    end

    if not target then
        Traitormod.SendMessage(client, Traitormod.Language.CMDCharacterNotFound)
        return true
    end

    if target == nil or target.IsDead then
        Traitormod.SendMessage(client, Traitormod.GetText("CMDCharacterDeadOrMissing"))
        return true
    end

    local role = Traitormod.RoleManager.Roles[args[2]]

    if role == nil then
        Traitormod.SendMessage(client, Traitormod.GetText("CMDAssignRoleNotFound"))
        return true
    end

    if Traitormod.RoleManager.GetRole(target) ~= nil then
        Traitormod.RoleManager.RemoveRole(target)
    end
    Traitormod.RoleManager.AssignRole(target, role:new())

    Traitormod.SendMessage(client, Traitormod.FormatText("CMDAssignRoleSuccess", target.Name, role.Name))

    return true
end)

Traitormod.AddCommand("!assignrole", function (client, args)
    if not client.HasPermission(ClientPermissions.ConsoleCommands) then return end
    
    if #args < 2 then
        Traitormod.SendMessage(client, Traitormod.GetText("CMDAssignRoleClientUsage"))
        return true
    end

    local target = Traitormod.FindClient(args[1])

    if not target then
        Traitormod.SendMessage(client, Traitormod.Language.CMDClientNotFound)
        return true
    end

    if target.Character == nil or target.Character.IsDead then
        Traitormod.SendMessage(client, Traitormod.GetText("CMDCharacterDeadOrMissing"))
        return true
    end

    local role = Traitormod.RoleManager.Roles[args[2]]

    if role == nil then
        Traitormod.SendMessage(client, Traitormod.GetText("CMDAssignRoleNotFound"))
        return true
    end

    local targetCharacter = target.Character

    if Traitormod.RoleManager.GetRole(targetCharacter) ~= nil then
        Traitormod.RoleManager.RemoveRole(targetCharacter)
    end
    Traitormod.RoleManager.AssignRole(targetCharacter, role:new())

    Traitormod.SendMessage(client, Traitormod.FormatText("CMDAssignRoleSuccess", target.Name, role.Name))

    return true
end)

Traitormod.AddCommand("!triggerevent", function (client, args)
    if not client.HasPermission(ClientPermissions.ConsoleCommands) then return end

    if #args < 1 then
        Traitormod.SendMessage(client, Traitormod.GetText("CMDTriggerEventUsage"))
        return true
    end

    local event = nil
    for _, value in pairs(Traitormod.RoundEvents.EventConfigs.Events) do
        if value.Name == args[1] then
            event = value
        end
    end

    if event == nil then
        Traitormod.SendMessage(client, Traitormod.FormatText("CMDTriggerEventNotFound", args[1]))
        return true
    end

    Traitormod.RoundEvents.TriggerEvent(event.Name)
    Traitormod.SendMessage(client, Traitormod.FormatText("CMDTriggerEventSuccess", event.Name))

    return true
end)

Traitormod.AddCommand({"!locatesub", "!locatesubmarine"}, function (client, args)
    local mainSub = Submarine.MainSub
    if client.Character == nil or not client.InGame or mainSub == nil then
        Traitormod.SendMessage(client, Traitormod.Language.CMDAliveToUse)
        return true
    end

    if client.Character.IsHuman and client.Character.TeamID == CharacterTeamType.Team1 then
        Traitormod.SendMessage(client, Traitormod.Language.CMDOnlyMonsters)
        return true
    end

    local center = client.Character.WorldPosition
    local target = mainSub.WorldPosition

    local distance = Vector2.Distance(center, target) * Physics.DisplayToRealWorldRatio

    local diff = center - target

    local angle = math.deg(math.atan2(diff.X, diff.Y)) + 180

    local function degreeToOClock(v)
        local oClock = math.floor(v / 30)
        if oClock == 0 then oClock = 12 end
        return Traitormod.FormatText("CMDOClock", oClock)
    end

    Game.SendDirectChatMessage("", string.format(Traitormod.Language.CMDLocateSub, math.floor(distance), degreeToOClock(angle)), nil, ChatMessageType.Error, client)

    return true
end)


Traitormod.AddCommand({"!monster", "!m"}, function (client, args)
    if client.Character == nil or client.Character.IsHuman then
        Traitormod.SendMessage(client, Traitormod.Language.CMDOnlyMonsters)
        return true
    end

    if #args < 1 then
        Traitormod.SendMessage(client, Traitormod.GetText("CMDMonsterUsage"))
        return true
    end

    local msg = ""
    for _, word in ipairs(args) do
        msg = msg .. " " .. word
    end

    for _, targetClient in pairs(Client.ClientList) do
        if (not targetClient.Character or targetClient.Character.IsDead) or not targetClient.Character.IsHuman then
            Game.SendDirectChatMessage("",
                string.format(Traitormod.Language.CMDMonsterBroadcast, client.Character.Name, Traitormod.ClientLogName(client), msg), nil,
                ChatMessageType.Error, targetClient)
        end
    end

    return true
end)

local preventSpam = {}
Traitormod.AddCommand({"!droppoints", "!droppoint", "!dropoint", "!dropoints"}, function (client, args)
    if preventSpam[client] ~= nil and Timer.GetTime() < preventSpam[client] then
        Traitormod.SendMessage(client, Traitormod.GetText("CMDCommandCooldown"))
        return true
    end

    if client.Character == nil or client.Character.IsDead or client.Character.Inventory == nil then
        Traitormod.SendMessage(client, Traitormod.Language.CMDAliveToUse)
        return true
    end

    if #args < 1 then
        Traitormod.SendMessage(client, Traitormod.GetText("CMDDropPointsUsage"))
        return true
    end

    local amount = tonumber(args[1])

    if amount == nil or amount ~= amount or amount < 100 or amount > 100000 then
        Traitormod.SendMessage(client, Traitormod.GetText("CMDDropPointsInvalidAmount"))
        return true
    end

    local availablePoints = Traitormod.GetData(client, "Points") or 0

    if amount > availablePoints then
        Traitormod.SendMessage(client, Traitormod.GetText("CMDDropPointsNotEnough"))
        return true
    end

    if Traitormod.DropPointItem == nil or not Traitormod.DropPointItem(client, amount) then
        Traitormod.SendMessage(client, Traitormod.GetText("CMDDropPointsFailed"))
        return true
    end

    preventSpam[client] = Timer.GetTime() + 5

    return true
end)

----- MODULE COMMANDS -----
Traitormod.AddCommand({"!pointshop", "!pointsshop", "!ps", "!shop"}, function (client, args)
    return Traitormod.Pointshop.Command(client, args)
end)

Traitormod.AddCommand({"!playtime", "!pt"}, function (client, args)
    Traitormod.SendChatMessage(
        client,
        string.format(Traitormod.Language.CMDPlaytime, Traitormod.FormatTime(math.ceil(Traitormod.GetData(client, "Playtime") or 0))),
        Color.Green
    )
    return true
end)

Traitormod.AddCommand("!stats", function (client, args)
    if Traitormod.Stats ~= nil and Traitormod.Stats.Command ~= nil then
        return Traitormod.Stats.Command(client, args)
    end

    Traitormod.SendMessage(client, Traitormod.GetText("CMDStatsUnavailable"))
    return true
end)

Traitormod.AddCommand({"!ghostrole", "!ghostroles"}, function(client, args)
    return Traitormod.GhostRoles.Command(client, args)
end)

Traitormod.AddCommand("!welcome", function (client, args)
    local message = Networking.Start("VoidTraitor_WelcomeMenuOpen")
    Networking.Send(message, client.Connection)
    return true
end)

Traitormod.AddCommand({"!freehandcuffs", "!freehandcuff", "!fhc"}, function (client, args)
    if client.Character == nil or client.Character.IsDead then
        Traitormod.SendMessage(client, Traitormod.Language.CMDFreeHandcuffsDead)
        return true
    end
    if not client.Character.IsHuman then return true end

    local item = client.Character.Inventory.GetItemInLimbSlot(InvSlotType.RightHand)

    if item ~= nil and item.Prefab.Identifier == "handcuffs" then
        if not item.HasTag("fakehandcuffs") then
            Traitormod.SendMessage(client, Traitormod.Language.CMDFreeHandcuffsNotFake)
            return true
        end
        item.Drop(client.Character)
    end

    return true
end)
