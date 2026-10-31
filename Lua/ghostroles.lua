local gr = {}

local config = Traitormod.Config.GhostRoleConfig or {}
local textPromptUtils = require("textpromptutils")

local guiNet = {
    Ready = "VoidTraitor_GhostRolesGuiReady",
    Request = "VoidTraitor_GhostRolesRequest",
    Snapshot = "VoidTraitor_GhostRolesSnapshot",
    Take = "VoidTraitor_GhostRolesTake",
}

gr.Roles = {}
gr.Characters = {}
gr.ExcludedCharacters = setmetatable({}, { __mode = "k" })
gr.Configs = {}
gr.ConfigsBySpecies = {}
gr.AutoRegisterBySpecies = {}
gr.GuiClients = {}
gr.NextRoleId = 1

local ghostRolesAnnounceTimer = 0
local nextAutoRegisterTime = 0
local nextStateCheckTime = 0
local lastStateSignature = ""

local function lang(key)
    return Traitormod.GetText(key)
end

local function formatText(template, ...)
    return string.format(tostring(template or ""), ...)
end

local function normalize(value)
    if value == nil then return nil end

    local text = tostring(value):gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then return nil end
    return string.lower(text)
end

local function resolveText(value)
    if value == nil then return "" end

    if type(value) ~= "string" then
        return tostring(value)
    end

    local currentLanguage = Traitormod.Language or {}
    local defaultLanguage = Traitormod.DefaultLanguage or {}
    if currentLanguage[value] ~= nil or defaultLanguage[value] ~= nil then
        return Traitormod.GetText(value)
    end

    return value
end

local function toNetInt32(value, fallback)
    value = math.floor(tonumber(value) or tonumber(fallback) or 0)
    return math.max(-2147483648, math.min(2147483647, value))
end

local function initializeConfigs()
    for _, group in ipairs(config.Groups or {}) do
        if group.Enabled ~= false then
            local groupIdentifier = normalize(group.Identifier)
            if groupIdentifier == nil then
                Traitormod.Error("Ghost role config group without Identifier.")
            else
                for _, roleConfig in ipairs(group.Roles or {}) do
                    local roleIdentifier = normalize(roleConfig.Identifier)
                    if roleIdentifier == nil then
                        Traitormod.Error("Ghost role config group \"%s\" contains a role without Identifier.", groupIdentifier)
                    else
                        local fullIdentifier = groupIdentifier .. "." .. roleIdentifier
                        if gr.Configs[fullIdentifier] ~= nil then
                            Traitormod.Error("Duplicate ghost role config identifier: %s", fullIdentifier)
                        else
                            roleConfig.GroupIdentifier = groupIdentifier
                            roleConfig.FullIdentifier = fullIdentifier
                            gr.Configs[fullIdentifier] = roleConfig

                            if roleConfig.Species ~= nil then
                                local species = normalize(roleConfig.Species)
                                local speciesIdentifier = groupIdentifier .. ":" .. species
                                if gr.ConfigsBySpecies[speciesIdentifier] ~= nil then
                                    Traitormod.Error("Duplicate ghost role species \"%s\" in group \"%s\".", tostring(roleConfig.Species), groupIdentifier)
                                else
                                    gr.ConfigsBySpecies[speciesIdentifier] = roleConfig
                                end

                                if roleConfig.AutoRegister == true then
                                    if gr.AutoRegisterBySpecies[species] ~= nil then
                                        Traitormod.Error("Duplicate auto ghost role species: %s", tostring(roleConfig.Species))
                                    else
                                        gr.AutoRegisterBySpecies[species] = roleConfig
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

local function getRoleName(role)
    if role == nil then return "" end
    if role.Name ~= nil then return resolveText(role.Name) end
    if role.Config ~= nil and role.Config.Name ~= nil then return resolveText(role.Config.Name) end
    if role.Config ~= nil then return tostring(role.Config.Identifier or role.Config.FullIdentifier or role.Id) end
    return tostring(role.Id)
end

local function getRoleDescription(role)
    if role == nil or role.Config == nil then return "" end
    return resolveText(role.Config.Description)
end

local function getRolePrice(role)
    if role == nil or role.Config == nil then return 0 end
    return math.max(0, math.floor(tonumber(role.Config.Price) or 0))
end

local function getRoleIcon(role)
    if role == nil or role.Config == nil then return "" end
    return tostring(role.Config.Icon or "character")
end

local function getRoleState(role)
    if role == nil then return "missing" end
    if role.Character == nil or role.Character.Removed or role.Character.IsDead then return "dead" end
    if role.Taken then return "taken" end
    return "free"
end

local function getRoleStateText(role)
    local state = getRoleState(role)
    if state == "dead" then return lang("GhostRolesMenuDead") end
    if state == "taken" then return lang("GhostRolesMenuTaken") end
    return lang("GhostRolesMenuFree")
end

local function getSortedRoles()
    local roles = {}
    for _, role in pairs(gr.Roles) do
        table.insert(roles, role)
    end

    table.sort(roles, function(a, b)
        local aName = string.lower(getRoleName(a))
        local bName = string.lower(getRoleName(b))
        if aName ~= bName then return aName < bName end
        return a.Id < b.Id
    end)

    return roles
end

local function getVisibleRoles()
    local roles = {}
    for _, role in ipairs(getSortedRoles()) do
        if getRoleState(role) ~= "taken" then
            table.insert(roles, role)
        end
    end
    return roles
end

local function getRoleCounts()
    local freeRoles = 0
    local totalRoles = 0
    for _, role in pairs(gr.Roles) do
        local state = getRoleState(role)
        if state ~= "taken" then
            totalRoles = totalRoles + 1
            if state == "free" then
                freeRoles = freeRoles + 1
            end
        end
    end
    return freeRoles, totalRoles
end

local function buildStateSignature()
    local states = {}
    for _, role in ipairs(getSortedRoles()) do
        table.insert(states, tostring(role.Id) .. ":" .. getRoleState(role))
    end
    return table.concat(states, "|")
end

local function canUseGhostRoles(client)
    if client == nil or not config.Enabled or not Game.RoundStarted or not client.InGame then return false end
    return client.Character == nil or client.Character.IsDead
end

local function validateGhostRoleClient(client)
    if not config.Enabled then
        Traitormod.SendMessage(client, lang("GhostRolesDisabled"))
        return false
    end

    if client == nil or not client.InGame then
        Traitormod.SendMessage(client, lang("GhostRolesInGame"))
        return false
    end

    if client.Character ~= nil and not client.Character.IsDead then
        Traitormod.SendMessage(client, lang("GhostRolesSpectator"))
        return false
    end

    return true
end

local function findRole(reference)
    if type(reference) == "table" and reference.Id ~= nil then
        return gr.Roles[reference.Id]
    end

    local numericId = tonumber(reference)
    if numericId == nil and type(reference) == "string" then
        numericId = tonumber(string.match(reference, "^#(%d+)$"))
    end
    if numericId ~= nil then
        return gr.Roles[math.floor(numericId)]
    end

    local query = normalize(reference)
    if query == nil then return nil end

    local firstMatch = nil
    for _, role in ipairs(getSortedRoles()) do
        local configIdentifier = role.Config and role.Config.FullIdentifier or ""
        if normalize(configIdentifier) == query or normalize(getRoleName(role)) == query then
            if getRoleState(role) == "free" then
                return role
            end
            firstMatch = firstMatch or role
        end
    end

    return firstMatch
end

local function buildRolesListText()
    local lines = {}
    for _, role in ipairs(getVisibleRoles()) do
        local line = "#" .. tostring(role.Id) .. " " .. getRoleName(role) .. " " .. getRoleStateText(role)
        local price = getRolePrice(role)
        if price > 0 then
            line = line .. " " .. formatText(lang("GhostRolesMenuCost"), price)
        end
        table.insert(lines, line)
    end

    if #lines == 0 then
        return lang("GhostRolesNone")
    end

    return table.concat(lines, "\n")
end

local function announceRole(role)
    local text = formatText(lang("GhostRoleAvailable"), getRoleName(role))
    for _, client in pairs(Client.ClientList) do
        if client.Character == nil or client.Character.IsDead then
            local chatMessage = ChatMessage.Create(lang("GhostRolesChatSender"), text, ChatMessageType.Default, nil, nil)
            chatMessage.Color = Color(255, 100, 10, 255)
            Game.SendDirectChatMessage(chatMessage, client)
        end
    end

    ghostRolesAnnounceTimer = Timer.GetTime() + 80
end

local function broadcastGuiSnapshots()
    if gr.SendGuiSnapshot == nil then return end

    for client in pairs(gr.GuiClients) do
        if client ~= nil and client.Connection ~= nil and canUseGhostRoles(client) then
            gr.SendGuiSnapshot(client, false)
        end
    end
end

function gr.GetConfig(identifier)
    return gr.Configs[normalize(identifier)]
end

function gr.GetConfigBySpecies(groupIdentifier, species)
    local group = normalize(groupIdentifier)
    species = normalize(species)
    if group == nil or species == nil then return nil end
    return gr.ConfigsBySpecies[group .. ":" .. species]
end

function gr.Create(configIdentifier, character, options)
    if not config.Enabled or character == nil then return false end
    if character.Removed or character.IsDead or gr.ExcludedCharacters[character] then return false end

    local roleConfig = gr.GetConfig(configIdentifier)
    if roleConfig == nil then
        Traitormod.Error("Ghost role config not found: %s", tostring(configIdentifier))
        return false
    end
    if roleConfig.Enabled == false then return false end

    local existingRole = gr.Roles[gr.Characters[character]]
    if existingRole ~= nil then
        if existingRole.Config.AutoRegister ~= true or existingRole.Taken then
            return false
        end
        gr.Roles[existingRole.Id] = nil
        gr.Characters[character] = nil
    end

    options = options or {}

    local role = {
        Id = gr.NextRoleId,
        Config = roleConfig,
        Character = character,
        Taken = false,
        Name = options.Name,
        OnAssigned = options.OnAssigned,
    }

    gr.NextRoleId = gr.NextRoleId + 1
    gr.Roles[role.Id] = role
    gr.Characters[character] = role.Id

    announceRole(role)
    broadcastGuiSnapshots()
    return role
end

function gr.IsGhostRole(character)
    if character == nil then return false end
    local roleId = gr.Characters[character]
    return roleId ~= nil and gr.Roles[roleId] ~= nil
end

function gr.ReturnGhostRole(character)
    if character == nil then return false end

    local role = gr.Roles[gr.Characters[character]]
    if role == nil then return false end

    role.Taken = false
    broadcastGuiSnapshots()
    return true
end

function gr.Remove(reference)
    local role = nil

    if type(reference) == "table" and reference.Id ~= nil then
        role = gr.Roles[reference.Id]
    elseif type(reference) == "number" or type(reference) == "string" then
        role = gr.Roles[math.floor(tonumber(reference) or -1)]
    else
        role = gr.Roles[gr.Characters[reference]]
    end

    if role == nil then return false end

    if role.Character ~= nil then
        gr.Characters[role.Character] = nil
    end
    gr.Roles[role.Id] = nil

    broadcastGuiSnapshots()
    return true
end

function gr.TryTake(client, reference)
    if not validateGhostRoleClient(client) then return false end

    local role = findRole(reference)
    if role == nil then
        Traitormod.SendMessage(client, lang("GhostRolesNotFound") .. buildRolesListText())
        return false
    end

    local state = getRoleState(role)
    if state == "taken" then
        Traitormod.SendMessage(client, lang("GhostRolesTook"))
        return false
    elseif state == "dead" then
        Traitormod.SendMessage(client, lang("GhostRolesAlreadyDead"))
        return false
    end

    local price = getRolePrice(role)
    if price > 0 and not Traitormod.Config.TestMode then
        local points = math.floor(Traitormod.GetData(client, "Points") or 0)
        if points < price then
            Traitormod.SendMessage(client, formatText(lang("GhostRolesNoPoints"), price, points))
            return false
        end
    end

    Traitormod.MidRoundSpawn.SetSpawnedClient(client, true)
    client.SetClientCharacter(role.Character)
    role.Taken = true

    local paid = false
    if price > 0 and not Traitormod.Config.TestMode and not Traitormod.IsRoundFinalizing() then
        local points = math.floor(Traitormod.GetData(client, "Points") or 0)
        Traitormod.SetData(client, "Points", points - price)
        paid = true
    end

    Traitormod.Log(Traitormod.ClientLogName(client) .. " took ghost role #" .. tostring(role.Id) .. " (" .. tostring(role.Config.FullIdentifier) .. ").")

    if role.Config.Action ~= nil then
        role.Config.Action(client, role.Character, role)
    end

    if role.OnAssigned ~= nil then
        role.OnAssigned(client, role.Character, role)
    end

    if paid then
        Traitormod.SendMessage(client, formatText(lang("GhostRolesPurchased"), price, math.floor(Traitormod.GetData(client, "Points") or 0)))
    end

    broadcastGuiSnapshots()
    return true
end

local function getMenuPageSize()
    local pageSize = tonumber(config.MenuPageSize) or 10
    return math.max(4, math.floor(pageSize))
end

local function reopenMenu(client, page)
    Timer.Wait(function()
        if client == nil or not client.InGame then return end
        gr.ShowMenu(client, page)
    end, 1)
end

function gr.ShowMenu(client, page)
    if not validateGhostRoleClient(client) then return false end

    local roles = getVisibleRoles()
    local freeRoles, totalRoles = getRoleCounts()
    local pageSize = getMenuPageSize()
    local totalPages = math.max(1, math.ceil(math.max(1, totalRoles) / pageSize))
    page = math.max(1, math.min(math.floor(tonumber(page) or 1), totalPages))

    local options = {
        lang("GhostRolesMenuCancel"),
        lang("GhostRolesMenuRefresh"),
    }
    local roleLookup = {}

    local hasPreviousPage = page > 1
    local hasNextPage = page < totalPages

    if hasPreviousPage then table.insert(options, lang("GhostRolesMenuPreviousPage")) end
    if hasNextPage then table.insert(options, lang("GhostRolesMenuNextPage")) end

    local firstRoleIndex = ((page - 1) * pageSize) + 1
    local lastRoleIndex = math.min(firstRoleIndex + pageSize - 1, totalRoles)

    for index = firstRoleIndex, lastRoleIndex do
        local role = roles[index]
        if role ~= nil then
            local optionText = formatText(lang("GhostRolesMenuEntry"), getRoleName(role), getRoleStateText(role))
            local price = getRolePrice(role)
            if price > 0 then
                optionText = optionText .. " " .. formatText(lang("GhostRolesMenuCost"), price)
            end

            table.insert(options, optionText)
            roleLookup[#options] = role.Id
        end
    end

    local message
    if totalRoles == 0 then
        message = formatText(lang("GhostRolesMenuEmpty"), math.floor(Traitormod.GetData(client, "Points") or 0))
    else
        message = formatText(
            lang("GhostRolesMenuTitle"),
            freeRoles,
            totalRoles,
            page,
            totalPages,
            math.floor(Traitormod.GetData(client, "Points") or 0)
        )
    end

    textPromptUtils.Prompt(message, options, client, function(id, client2)
        if id == 1 then return end
        if id == 2 then
            reopenMenu(client2, page)
            return
        end

        local navigationIndex = 2
        if hasPreviousPage then
            navigationIndex = navigationIndex + 1
            if id == navigationIndex then
                reopenMenu(client2, page - 1)
                return
            end
        end

        if hasNextPage then
            navigationIndex = navigationIndex + 1
            if id == navigationIndex then
                reopenMenu(client2, page + 1)
                return
            end
        end

        local roleId = roleLookup[id]
        if roleId ~= nil and not gr.TryTake(client2, roleId) then
            reopenMenu(client2, page)
        end
    end, "gambler")

    return true
end

function gr.SendGuiSnapshot(client, openMenu)
    if client == nil or client.Connection == nil then return false end

    local allowed = canUseGhostRoles(client)
    local roles = {}
    local freeRoles = 0
    if allowed then
        roles = getVisibleRoles()
        freeRoles = getRoleCounts()
    end

    local points = math.floor(Traitormod.GetData(client, "Points") or 0)
    local netMessage = Networking.Start(guiNet.Snapshot)

    netMessage.WriteBoolean(openMenu == true)
    netMessage.WriteBoolean(allowed)
    netMessage.WriteInt32(toNetInt32(points, 0))
    netMessage.WriteInt32(toNetInt32(freeRoles, 0))
    netMessage.WriteInt32(toNetInt32(#roles, 0))

    for _, role in ipairs(roles) do
        local characterId = 0
        if role.Character ~= nil and not role.Character.Removed then
            characterId = tonumber(role.Character.ID) or 0
        end

        local state = getRoleState(role)
        local price = getRolePrice(role)

        netMessage.WriteInt32(toNetInt32(role.Id, 0))
        netMessage.WriteString(getRoleName(role))
        netMessage.WriteString(getRoleDescription(role))
        netMessage.WriteInt32(toNetInt32(price, 0))
        local worldX, worldY = 0, 0
        if role.Character ~= nil and not role.Character.Removed then
            worldX = tonumber(role.Character.WorldPosition.X) or 0
            worldY = tonumber(role.Character.WorldPosition.Y) or 0
        end

        netMessage.WriteString(state)
        netMessage.WriteInt32(toNetInt32(characterId, 0))
        netMessage.WriteSingle(worldX)
        netMessage.WriteSingle(worldY)
        netMessage.WriteString(getRoleIcon(role))
        netMessage.WriteBoolean(state == "free" and (Traitormod.Config.TestMode or price <= points))
    end


    Networking.Send(netMessage, client.Connection)
    return true
end

function gr.MarkGuiClientReady(client)
    if client == nil then return false end
    gr.GuiClients[client] = true
    return gr.SendGuiSnapshot(client, false)
end

function gr.RequestGuiSnapshot(client)
    if client == nil then return false end
    gr.GuiClients[client] = true
    return gr.SendGuiSnapshot(client, true)
end

function gr.NotifyGuiBalanceChanged(client)
    if client ~= nil and gr.GuiClients[client] and canUseGhostRoles(client) then
        gr.SendGuiSnapshot(client, false)
    end
end

function gr.ForgetGuiClient(client)
    gr.GuiClients[client] = nil
end

function gr.Command(client, args)
    if #args == 0 then
        if gr.GuiClients[client] then
            return gr.SendGuiSnapshot(client, true)
        end
        return gr.ShowMenu(client)
    end

    return gr.TryTake(client, table.concat(args, " "))
end

local function autoRegisterCharacters()
    local clientCharacters = {}
    for _, client in pairs(Client.ClientList) do
        if client.Character ~= nil then
            clientCharacters[client.Character] = true
        end
    end

    for _, character in pairs(Character.CharacterList) do
        if character ~= nil and not character.Removed and not character.IsDead and not gr.IsGhostRole(character) and not clientCharacters[character] then
            local species = normalize(character.SpeciesName)
            local roleConfig = species and gr.AutoRegisterBySpecies[species] or nil
            if roleConfig ~= nil and roleConfig.Enabled ~= false then
                gr.Create(roleConfig.FullIdentifier, character)
            end
        end
    end
end

local function removeExpiredDeadRoles(now)
    local lifetime = math.max(0, tonumber(config.DeadRoleLifetimeSeconds) or 180)
    local removeIds = {}

    for roleId, role in pairs(gr.Roles) do
        if getRoleState(role) == "dead" then
            if role.DeadSince == nil then
                role.DeadSince = now
            elseif now - role.DeadSince >= lifetime then
                table.insert(removeIds, roleId)
            end
        else
            role.DeadSince = nil
        end
    end

    if #removeIds == 0 then return false end

    for _, roleId in ipairs(removeIds) do
        local role = gr.Roles[roleId]
        if role ~= nil then
            if role.Character ~= nil then
                gr.Characters[role.Character] = nil
            end
            gr.Roles[roleId] = nil
        end
    end

    return true
end

local abandonedCharacterUpdateInterval = 0.25
local abandonedCharacterUpdateTimer = abandonedCharacterUpdateInterval

local function getDisconnectedCharacterGhostRoleDelay()
    local ghostRoleConfig = Traitormod.Config.GhostRoleConfig or {}
    local delaySeconds = tonumber(ghostRoleConfig.DisconnectedCharacterDelaySeconds)

    if delaySeconds == nil then
        return 180
    end

    return math.max(0, delaySeconds)
end

local function sendDisconnectedGhostRoleInfo(client, character)
    if client == nil or character == nil or character.IsDead then
        return
    end

    local role = Traitormod.RoleManager.GetRole(character)
    if role == nil or role.Greet == nil then
        return
    end

    Timer.Wait(function ()
        if client == nil or client.Character ~= character or not client.InGame then
            return
        end

        local message = role:Greet()
        if type(message) == "string" and message ~= "" then
            Traitormod.SendMessage(client, message)
        end
    end, 500)
end

local function clearAbandonedCharacter(accountKey)
    local abandonedCharacter = Traitormod.AbandonedCharacters[accountKey]
    if abandonedCharacter == nil then
        return nil
    end

    if abandonedCharacter.GhostRoleId and Traitormod.GhostRoles then
        Traitormod.GhostRoles.Remove(abandonedCharacter.GhostRoleId)
    end

    Traitormod.AbandonedCharacters[accountKey] = nil
    return abandonedCharacter
end

local function createDisconnectedGhostRole(abandonedCharacter)
    if abandonedCharacter == nil or abandonedCharacter.GhostRoleCreated or Traitormod.GhostRoles == nil then
        return false
    end

    local character = abandonedCharacter.Character
    if character == nil or character.IsDead or not character.ClientDisconnected then
        return false
    end

    local role = Traitormod.GhostRoles.Create("system.disconnected", character, {
        Name = character.Name,
        OnAssigned = function (ghostClient, assignedCharacter)
            Traitormod.AbandonedCharacters[abandonedCharacter.AccountKey] = nil
            sendDisconnectedGhostRoleInfo(ghostClient, assignedCharacter)
        end
    })

    if not role then
        return false
    end

    abandonedCharacter.GhostRoleCreated = true
    abandonedCharacter.GhostRoleId = role.Id
    return true
end

local function updateAbandonedCharacters()
    if not Game.RoundStarted then
        return
    end

    local ghostRoleConfig = Traitormod.Config.GhostRoleConfig
    if ghostRoleConfig == nil or not ghostRoleConfig.Enabled or next(Traitormod.AbandonedCharacters) == nil then
        return
    end

    local connectedAccountKeys = {}
    for _, connectedClient in pairs(Client.ClientList) do
        local accountKey = Traitormod.GetClientAccountKey(connectedClient)
        if accountKey ~= nil then
            connectedAccountKeys[accountKey] = true
        end
    end

    local now = Timer.GetTime()
    local toRemove = {}
    local toCreate = {}

    for accountKey, abandonedCharacter in pairs(Traitormod.AbandonedCharacters) do
        local character = abandonedCharacter.Character

        if character == nil or character.IsDead then
            table.insert(toRemove, accountKey)
        elseif connectedAccountKeys[accountKey] then
            table.insert(toRemove, accountKey)
        elseif not abandonedCharacter.GhostRoleCreated and now >= abandonedCharacter.AvailableAt then
            table.insert(toCreate, abandonedCharacter)
        end
    end

    for _, accountKey in ipairs(toRemove) do
        clearAbandonedCharacter(accountKey)
    end

    for _, abandonedCharacter in ipairs(toCreate) do
        createDisconnectedGhostRole(abandonedCharacter)
    end
end

function gr.HandleReconnect(client)
    local accountKey = Traitormod.GetClientAccountKey(client)
    local abandonedCharacter = Traitormod.AbandonedCharacters[accountKey]
    if abandonedCharacter then
        if abandonedCharacter.Character and abandonedCharacter.Character.IsDead then
            -- client left while char was alive -> but char is dead
            Traitormod.Debug(string.format("%s connected, but his character died in the meantime...", Traitormod.ClientLogName(client)))
        end

        clearAbandonedCharacter(accountKey)
    end
end

function gr.HandleDisconnect(client)
    -- if character was alive while disconnecting, make sure player looses live if he rejoins the round
    if client.Character and not client.Character.IsDead and client.Character.IsHuman then
        Traitormod.Debug(string.format("%s disconnected with an alive character. Remembering for rejoin...", Traitormod.ClientLogName(client)))
        local accountKey = Traitormod.GetClientAccountKey(client)
        Traitormod.AbandonedCharacters[accountKey] = {
            AccountKey = accountKey,
            Character = client.Character,
            AvailableAt = Timer.GetTime() + getDisconnectedCharacterGhostRoleDelay(),
            GhostRoleCreated = false,
            GhostRoleId = nil,
        }
    end
end

initializeConfigs()

Networking.Receive(guiNet.Ready, function(message, client)
    return gr.MarkGuiClientReady(client)
end)

Networking.Receive(guiNet.Request, function(message, client)
    return gr.RequestGuiSnapshot(client)
end)

Networking.Receive(guiNet.Take, function(message, client)
    gr.GuiClients[client] = true
    local roleId = message.ReadInt32()
    local success = gr.TryTake(client, roleId)
    return gr.SendGuiSnapshot(client, not success and canUseGhostRoles(client))
end)

Hook.Add("think", "Traitormod.GhostRoles.Think", function(deltaTime)
    if not config.Enabled or not Game.RoundStarted then return end

    abandonedCharacterUpdateTimer = abandonedCharacterUpdateTimer + deltaTime
    if abandonedCharacterUpdateTimer >= abandonedCharacterUpdateInterval then
        abandonedCharacterUpdateTimer = 0
        updateAbandonedCharacters()
    end

    local now = Timer.GetTime()

    if now >= nextAutoRegisterTime then
        nextAutoRegisterTime = now + 5
        autoRegisterCharacters()
    end

    if now >= nextStateCheckTime then
        nextStateCheckTime = now + 1
        local removedDeadRoles = removeExpiredDeadRoles(now)
        local stateSignature = buildStateSignature()
        if removedDeadRoles or stateSignature ~= lastStateSignature then
            lastStateSignature = stateSignature
            broadcastGuiSnapshots()
        end
    end

    if now < ghostRolesAnnounceTimer then return end
    ghostRolesAnnounceTimer = now + 200

    local roleNames = {}
    for _, role in ipairs(getSortedRoles()) do
        if getRoleState(role) == "free" then
            table.insert(roleNames, "\"‖color:gui.orange‖" .. getRoleName(role) .. "\"‖color:end‖")
        end
    end

    if #roleNames == 0 then return end

    local text = formatText(lang("GhostRolesReminder"), table.concat(roleNames, " "))
    for _, client in pairs(Client.ClientList) do
        if client.Character == nil or client.Character.IsDead then
            local chatMessage = ChatMessage.Create(lang("GhostRolesChatSender"), text, ChatMessageType.Default, nil, nil)
            chatMessage.Color = Color(255, 100, 10, 255)
            Game.SendDirectChatMessage(chatMessage, client)
        end
    end
end)

Hook.Add("client.disconnected", "Traitormod.GhostRoles.Disconnect", function(client)
    gr.ForgetGuiClient(client)
end)

Hook.Add("roundEnd", "TraitorMod.GhostRoles.RoundEnd", function()
    gr.Roles = {}
    gr.Characters = {}
    gr.ExcludedCharacters = setmetatable({}, { __mode = "k" })
    gr.NextRoleId = 1
    lastStateSignature = ""
    broadcastGuiSnapshots()
end)

return gr
