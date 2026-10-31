local cameraTeleport = {}

local guiNet = {
    Ready = "VoidTraitor_CameraTeleportGuiReady",
    Request = "VoidTraitor_CameraTeleportRequest",
    Snapshot = "VoidTraitor_CameraTeleportSnapshot",
}

local function toNetInt32(value, fallback)
    value = math.floor(tonumber(value) or tonumber(fallback) or 0)
    return math.max(-2147483648, math.min(2147483647, value))
end

local function canUse(client)
    if client == nil or not client.InGame or not Game.RoundStarted then return false end
    return client.Character == nil or client.Character.IsDead
end

local function getCharacterIcon(character)
    local ghostRoles = Traitormod.GhostRoles
    if ghostRoles ~= nil then
        local roleId = ghostRoles.Characters[character]
        local role = roleId ~= nil and ghostRoles.Roles[roleId] or nil
        if role ~= nil and role.Config ~= nil and role.Config.Icon ~= nil then
            return tostring(role.Config.Icon)
        end

        local species = string.lower(tostring(character.SpeciesName or ""))
        local roleConfig = ghostRoles.AutoRegisterBySpecies[species]
        if roleConfig ~= nil and roleConfig.Icon ~= nil then
            return tostring(roleConfig.Icon)
        end
    end

    if character.Info ~= nil and character.Info.Job ~= nil and character.Info.Job.Prefab ~= nil then
        return "job:" .. tostring(character.Info.Job.Prefab.Identifier)
    end

    return "character"
end

local function getTargets()
    local targets = {}

    for _, client in pairs(Client.ClientList) do
        local character = client.Character
        if client.InGame and character ~= nil and not character.Removed and not character.IsDead then
            table.insert(targets, {
                Character = character,
                CharacterName = tostring(character.Name or client.Name or ""),
                PlayerName = tostring(client.Name or ""),
                Icon = getCharacterIcon(character),
            })
        end
    end

    table.sort(targets, function(a, b)
        local aName = string.lower(a.CharacterName)
        local bName = string.lower(b.CharacterName)
        if aName ~= bName then return aName < bName end
        return a.PlayerName < b.PlayerName
    end)

    return targets
end

function cameraTeleport.SendSnapshot(client, openMenu)
    if client == nil or client.Connection == nil then return false end

    local allowed = canUse(client)
    local targets = allowed and getTargets() or {}
    local message = Networking.Start(guiNet.Snapshot)

    message.WriteBoolean(openMenu == true)
    message.WriteBoolean(allowed)
    message.WriteInt32(toNetInt32(#targets, 0))

    for _, target in ipairs(targets) do
        local character = target.Character
        message.WriteInt32(toNetInt32(character.ID, 0))
        message.WriteString(target.CharacterName)
        message.WriteString(target.PlayerName)
        message.WriteSingle(tonumber(character.WorldPosition.X) or 0)
        message.WriteSingle(tonumber(character.WorldPosition.Y) or 0)
        message.WriteString(target.Icon)
    end


    Networking.Send(message, client.Connection)
    return true
end

Networking.Receive(guiNet.Ready, function(message, client)
    return cameraTeleport.SendSnapshot(client, false)
end)

Networking.Receive(guiNet.Request, function(message, client)
    return cameraTeleport.SendSnapshot(client, message.ReadBoolean())
end)

return cameraTeleport
