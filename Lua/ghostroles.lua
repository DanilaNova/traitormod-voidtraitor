local gr = {}

local config = Traitormod.Config.GhostRoleConfig
local textPromptUtils = require("textpromptutils")

local function lang(key, fallback)
    local language = Traitormod.Language
    local value = language and language[key]
    if type(value) == "string" and value ~= "" then
        return value
    end
    return fallback
end

local function safeFormat(template, ...)
    template = tostring(template or "")
    local ok, result = pcall(string.format, template, ...)
    if ok then
        return result
    end
    return template
end

local ghostRolesAnnounceTimer = 0

local function normalizeRoleName(name)
    if type(name) ~= "string" then
        return nil
    end

    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then
        return nil
    end

    return string.lower(name)
end

local function getMenuPageSize()
    local pageSize = tonumber(config.MenuPageSize) or 10
    return math.max(4, math.floor(pageSize))
end

local function getRoleDisplayName(name, role)
    if role and role.ExtraData and type(role.ExtraData.DisplayName) == "string" and role.ExtraData.DisplayName ~= "" then
        return role.ExtraData.DisplayName
    end

    return name
end

local function getRolePrice(name, role)
    if role and role.ExtraData and role.ExtraData.Price ~= nil then
        return math.max(0, math.floor(tonumber(role.ExtraData.Price) or 0))
    end

    if config.RolePrices ~= nil then
        local rolePrice = config.RolePrices[normalizeRoleName(name)]
        if rolePrice ~= nil then
            return math.max(0, math.floor(tonumber(rolePrice) or 0))
        end
    end

    return 0
end

local function getRoleState(role)
    if role == nil then
        return "missing"
    end

    if role.Character and role.Character.IsDead then
        return "dead"
    end

    if role.Taken then
        return "taken"
    end

    return "free"
end

local function getRoleStateText(role)
    local state = getRoleState(role)

    if state == "dead" then
        return lang("GhostRolesMenuDead", "(Dead)")
    elseif state == "taken" then
        return lang("GhostRolesMenuTaken", "(Taken)")
    end

    return lang("GhostRolesMenuFree", "(Free)")
end

local function getSortedRoles()
    local roles = {}

    for name, role in pairs(gr.Roles) do
        table.insert(roles, { Name = name, Role = role, DisplayName = getRoleDisplayName(name, role) })
    end

    table.sort(roles, function(a, b)
        return string.lower(a.DisplayName) < string.lower(b.DisplayName)
    end)

    return roles
end

local function buildRolesListText()
    local lines = {}

    for _, entry in ipairs(getSortedRoles()) do
        local line = entry.DisplayName .. " " .. getRoleStateText(entry.Role)
        local price = getRolePrice(entry.Name, entry.Role)
        if price > 0 then
            line = line .. " " .. safeFormat(lang("GhostRolesMenuCost", "(%d points)"), price)
        end
        table.insert(lines, line)
    end

    if #lines == 0 then
        return lang("GhostRolesNone", "No ghost roles available.")
    end

    return table.concat(lines, "\n")
end

local function getRoleCounts()
    local totalRoles = 0
    local freeRoles = 0

    for _, role in pairs(gr.Roles) do
        totalRoles = totalRoles + 1
        if getRoleState(role) == "free" then
            freeRoles = freeRoles + 1
        end
    end

    return freeRoles, totalRoles
end

local function validateGhostRoleClient(client)
    if not config.Enabled then
        Traitormod.SendMessage(client, lang("GhostRolesDisabled", "Ghost roles are disabled."))
        return false
    end

    if client.Character ~= nil and not client.Character.IsDead then
        Traitormod.SendMessage(client, lang("GhostRolesSpectator", "Only spectators can use ghost roles."))
        return false
    end

    if not client.InGame then
        Traitormod.SendMessage(client, lang("GhostRolesInGame", "You must be in game to use ghost roles."))
        return false
    end

    return true
end

local function reopenMenu(client, page)
    Timer.Wait(function()
        if client == nil or not client.InGame then
            return
        end

        gr.ShowMenu(client, page)
    end, 1)
end

gr.Roles = {}
gr.Characters = {}

gr.Ask = function (name, callback, character, extraData)
    if not config.Enabled then return false end

    name = normalizeRoleName(name)
    if name == nil then
        return false
    end

    gr.Roles[name] = {Callback = callback, Taken = false, Character = character, ExtraData = extraData}

    local text = safeFormat(lang("GhostRoleAvailable", "[Ghost Role] New ghost role available: %s (type in chat !ghostrole %s to accept)"), getRoleDisplayName(name, gr.Roles[name]), name)

    for _, client in pairs(Client.ClientList) do
        if client.Character == nil or client.Character.IsDead then
            local chatMessage = ChatMessage.Create("Ghost Roles", text, ChatMessageType.Default, nil, nil)
            chatMessage.Color = Color(255, 100, 10, 255)
            Game.SendDirectChatMessage(chatMessage, client)
        end
    end

    if character then
        gr.Characters[character] = name
    end

    ghostRolesAnnounceTimer = Timer.GetTime() + 80
    return true
end

gr.IsGhostRole = function (character)
    if character == nil then return false end

    if gr.Characters[character] and gr.Roles[gr.Characters[character]] then
        return true
    end

    return false
end

gr.ReturnGhostRole = function (character)
    if character == nil then return false end

    if gr.Characters[character] and gr.Roles[gr.Characters[character]] then
        gr.Roles[gr.Characters[character]].Taken = false

        return true
    end

    return false
end

gr.Remove = function (nameOrCharacter)
    local roleName = nil
    local character = nil

    if type(nameOrCharacter) == "string" then
        roleName = normalizeRoleName(nameOrCharacter)
    else
        character = nameOrCharacter
        roleName = gr.Characters[character]
    end

    if roleName == nil then
        return false
    end

    local role = gr.Roles[roleName]
    if role and role.Character then
        gr.Characters[role.Character] = nil
    elseif character ~= nil then
        gr.Characters[character] = nil
    end

    gr.Roles[roleName] = nil
    return true
end

gr.TryTake = function (client, roleName)
    if not validateGhostRoleClient(client) then
        return false
    end

    roleName = normalizeRoleName(roleName)
    if roleName == nil then
        Traitormod.SendMessage(client, lang("GhostRolesNotFound", "Ghost role not found, did you type the name correctly? Available roles: \n\n") .. buildRolesListText())
        return false
    end

    local role = gr.Roles[roleName]
    if role == nil then
        Traitormod.SendMessage(client, lang("GhostRolesNotFound", "Ghost role not found, did you type the name correctly? Available roles: \n\n") .. buildRolesListText())
        return false
    end

    if role.Taken then
        Traitormod.SendMessage(client, lang("GhostRolesTook", "Someone already took this ghost role."))
        return false
    end

    if role.Character and role.Character.IsDead then
        Traitormod.SendMessage(client, lang("GhostRolesAlreadyDead", "Seems this ghost role is already dead, too bad!"))
        return false
    end

    local price = getRolePrice(roleName, role)
    if price > 0 and not Traitormod.Config.TestMode then
        local points = math.floor(Traitormod.GetData(client, "Points") or 0)
        if points < price then
            Traitormod.SendMessage(client, safeFormat(lang("GhostRolesNoPoints", "You need %d points for this ghost role. You currently have %d."), price, points))
            return false
        end
    end

    Traitormod.Log(Traitormod.ClientLogName(client) .. " took the ghost role of " .. roleName .. ".")

    role.Taken = true

    local paid = false
    if price > 0 and not Traitormod.Config.TestMode then
        local points = math.floor(Traitormod.GetData(client, "Points") or 0)
        Traitormod.SetData(client, "Points", points - price)
        paid = true
    end

    local success, errorMessage = pcall(function ()
        Traitormod.MidRoundSpawn.SetSpawnedClient(client, true)
        role.Callback(client, role.ExtraData)
    end)

    if not success then
        role.Taken = false

        if paid then
            local points = math.floor(Traitormod.GetData(client, "Points") or 0)
            Traitormod.SetData(client, "Points", points + price)
        end

        Traitormod.Error("Ghost role assignment failed for \"%s\": %s", tostring(roleName), tostring(errorMessage))
        Traitormod.SendMessage(client, lang("GhostRolesAssignFailed", "Failed to assign ghost role."))
        return false
    end

    if paid then
        Traitormod.SendMessage(client, safeFormat(lang("GhostRolesPurchased", "Purchased ghost role for %d points. New balance: %d."), price, math.floor(Traitormod.GetData(client, "Points") or 0)))
    end

    if role.ExtraData and role.ExtraData.OnAssigned then
        local ok, onAssignedError = pcall(function ()
            role.ExtraData.OnAssigned(client, role.Character, role.ExtraData)
        end)

        if not ok then
            Traitormod.Error("Ghost role OnAssigned failed for \"%s\": %s", tostring(roleName), tostring(onAssignedError))
        end
    end

    return true
end

gr.ShowMenu = function (client, page)
    if not validateGhostRoleClient(client) then
        return false
    end

    local roles = getSortedRoles()
    local freeRoles, totalRoles = getRoleCounts()
    local pageSize = getMenuPageSize()
    local totalPages = math.max(1, math.ceil(math.max(1, totalRoles) / pageSize))

    page = math.max(1, math.min(math.floor(tonumber(page) or 1), totalPages))

    local options = {
        lang("GhostRolesMenuCancel", "Close"),
        lang("GhostRolesMenuRefresh", "Refresh")
    }
    local roleLookup = {}

    local hasPreviousPage = page > 1
    local hasNextPage = page < totalPages

    if hasPreviousPage then
        table.insert(options, lang("GhostRolesMenuPreviousPage", "Previous page"))
    end

    if hasNextPage then
        table.insert(options, lang("GhostRolesMenuNextPage", "Next page"))
    end

    local firstRoleIndex = ((page - 1) * pageSize) + 1
    local lastRoleIndex = math.min(firstRoleIndex + pageSize - 1, totalRoles)

    for index = firstRoleIndex, lastRoleIndex do
        local entry = roles[index]
        if entry ~= nil then
            local optionText = safeFormat(
                lang("GhostRolesMenuEntry", "%s %s"),
                entry.DisplayName,
                getRoleStateText(entry.Role)
            )

            local price = getRolePrice(entry.Name, entry.Role)
            if price > 0 then
                optionText = optionText .. " " .. safeFormat(lang("GhostRolesMenuCost", "(%d points)"), price)
            end

            table.insert(options, optionText)
            roleLookup[#options] = entry.Name
        end
    end

    local message
    if totalRoles == 0 then
        message = safeFormat(
            lang("GhostRolesMenuEmpty", "Ghost roles are currently unavailable. Your points: %d"),
            math.floor(Traitormod.GetData(client, "Points") or 0)
        )
    else
        message = safeFormat(
            lang("GhostRolesMenuTitle", "Ghost roles (%d/%d free) | Page %d/%d | Your points: %d"),
            freeRoles,
            totalRoles,
            page,
            totalPages,
            math.floor(Traitormod.GetData(client, "Points") or 0)
        )
    end

    textPromptUtils.Prompt(message, options, client, function (id, client2)
        if id == 1 then
            return
        end

        if id == 2 then
            reopenMenu(client2, page)
            return
        end

        local navigationOffset = 2
        if hasPreviousPage then
            navigationOffset = navigationOffset + 1
            if id == navigationOffset then
                reopenMenu(client2, page - 1)
                return
            end
        end

        if hasNextPage then
            navigationOffset = navigationOffset + 1
            if id == navigationOffset then
                reopenMenu(client2, page + 1)
                return
            end
        end

        local selectedRole = roleLookup[id]
        if selectedRole == nil then
            return
        end

        if not gr.TryTake(client2, selectedRole) then
            reopenMenu(client2, page)
        end
    end, "gambler")

    return true
end

Traitormod.AddCommand({"!ghostrole", "!ghostroles"}, function(client, args)
    if #args == 0 then
        gr.ShowMenu(client)
        return true
    end

    gr.TryTake(client, table.concat(args, " "))
    return true
end)

Hook.Add("think", "Traitormod.GhostRoles.Think", function (...)
    if not config.Enabled then return end
    if Timer.GetTime() < ghostRolesAnnounceTimer then return end
    ghostRolesAnnounceTimer = Timer.GetTime() + 200

    local roles = ""
    for name, role in pairs(gr.Roles) do
        if getRoleState(role) == "free" then
            roles = roles .. "\"‖color:gui.orange‖" .. getRoleDisplayName(name, role) .. "\"‖color:end‖ "
        end
    end

    if roles == "" then return end

    for _, client in pairs(Client.ClientList) do
        if client.Character == nil or client.Character.IsDead then
            local chatMessage = ChatMessage.Create("Ghost Roles", safeFormat(lang("GhostRolesReminder", "Ghost roles available: %s"), roles), ChatMessageType.Default, nil, nil)
            chatMessage.Color = Color(255, 100, 10, 255)
            Game.SendDirectChatMessage(chatMessage, client)
        end
    end
end)

Hook.Add("roundEnd", "TraitorMod.GhostRoles.RoundEnd", function ()
    gr.Roles = {}
    gr.Characters = {}
end)

return gr
