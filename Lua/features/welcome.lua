if not Game.IsMultiplayer or (Game.IsMultiplayer and CLIENT) then return end

LuaUserData.RegisterType("Barotrauma.Networking.FileSender")

local luaConfirmed = {}
local clientTrackers = {}

Traitormod.ClientHasLua = function(client)
    return luaConfirmed[client] == true
end

local WAIT_AFTER_DOWNLOAD = 20 
local welcomeUpdateTimer = 0

local function getWelcomeText()
    if Traitormod and Traitormod.GetText then
        return Traitormod.GetText("WelcomeMessage")
    end
    return ""
end

local function getServerSenderText()
    if Traitormod and Traitormod.GetText then
        return Traitormod.GetText("ChatSenderServer")
    end
    return ""
end

local function IsDownloading(client)
    if not Game.Server or not Game.Server.FileSender then return false end
    for key, value in pairs(Game.Server.FileSender.ActiveTransfers) do
        if value.Connection == client.Connection then return true end
    end
    return false
end

Networking.Receive("VoidTraitor_LuaCheck", function(message, client)
    luaConfirmed[client] = true
    clientTrackers[client] = nil
end)

Hook.Add("client.connected", "Welcome_Connect", function(client)
    if not luaConfirmed[client] then
        clientTrackers[client] = { timer = -welcomeUpdateTimer }
    end
end)

Hook.Add("client.disconnected", "Welcome_Disconnect", function(client)
    clientTrackers[client] = nil
    luaConfirmed[client] = nil
end)

Hook.Add("think", "Welcome_Logic", function(deltaTime)
    if next(clientTrackers) == nil then
        welcomeUpdateTimer = 0
        return
    end

    welcomeUpdateTimer = welcomeUpdateTimer + deltaTime
    if welcomeUpdateTimer < 0.25 then return end

    local elapsed = welcomeUpdateTimer
    welcomeUpdateTimer = 0

    for client, data in pairs(clientTrackers) do
        if IsDownloading(client) then
            data.timer = 0
        else
            data.timer = data.timer + elapsed 
            if data.timer > WAIT_AFTER_DOWNLOAD then
                local ok, err = pcall(function()
                    local chatMessage = ChatMessage.Create(getServerSenderText(), getWelcomeText(), ChatMessageType.ServerMessageBox, nil, nil)
                    Game.SendDirectChatMessage(chatMessage, client)
                end)

                if not ok then
                    data.timer = 0
                    Traitormod.Error("Failed to send welcome message to " .. Traitormod.ClientLogName(client) .. ": " .. tostring(err))
                else
                    clientTrackers[client] = nil
                end
            end
        end
    end
end)