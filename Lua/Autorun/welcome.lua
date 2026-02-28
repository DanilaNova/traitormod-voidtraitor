if not Game.IsMultiplayer or (Game.IsMultiplayer and CLIENT) then return end

LuaUserData.RegisterType("Barotrauma.Networking.FileSender")

local luaConfirmed = {}
local clientTrackers = {}

local WAIT_AFTER_DOWNLOAD = 20 

local welcomemessage = [[
Добро пожаловать в Void Traitor!

Это не обычный сервер с предателями, а довольно разнообразный и уникальный в своем роде сервер.
Так как здесь стоит собственный Traitor Mod с кучами разными изменениями и даже с целыми режимами.
Здесь мы играем в «Миссии с предателями», «attack & defend», иногда страдаем шизой!

Также у меня есть дискорд-сервер, где я упоминаю, когда сервер открыт, и там можно скачать мод на меню для Traitor Mod. 
P.S. Еще там есть гайды, и вы можете предложить, что можно добавить еще на сервер:
мой сервер - https://discord.gg/rFrwmXg8DQ
сервер партнеров Project Encelada - https://discord.gg/encelada

Если хотите легче покупать, то можно поставить:
Traitor menu (Для работы нужен клиентский LUA вместе С#)
https://steamcommunity.com/sharedfiles/filedetails/?id=2990694897

(ВВОДИТЬ В ЧАТ И БЕЗ "/") Команды:
!help - выводит список команд
!point - показывает поинты, шанс и жизни
!pointshop / !shop / !ps - магазин
!traitor - выводит список заданий
!suicide / !kill - чтобы умереть.

Правила!!!
Запрещено быть мудаком.
Запрещено гриферить и убивать, когда ты не предатель.
СБ И КАПИТАНЫ НЕ МОГУТ БЫТЬ ПРЕДАТЕЛЯМИ!!
]]

local function IsDownloading(client)
    if not Game.Server or not Game.Server.FileSender then return false end
    for key, value in pairs(Game.Server.FileSender.ActiveTransfers) do
        if value.Connection == client.Connection then return true end
    end
    return false
end

Networking.Receive("VoidTraitor_LuaCheck", function(message, client)
    luaConfirmed[client] = true
end)

Hook.Add("client.connected", "Welcome_Connect", function(client)
    clientTrackers[client] = { timer = 0, sent = false }
end)

Hook.Add("client.disconnected", "Welcome_Disconnect", function(client)
    clientTrackers[client] = nil
    luaConfirmed[client] = nil
end)

Hook.Add("think", "Welcome_Logic", function()
    for client, data in pairs(clientTrackers) do
        if not data.sent then
            if luaConfirmed[client] then
                data.sent = true 
            elseif IsDownloading(client) then
                data.timer = 0
            else
                data.timer = data.timer + 0.0166 
                if data.timer > WAIT_AFTER_DOWNLOAD then
                    if not luaConfirmed[client] then
                        pcall(function()
                            local chatMessage = ChatMessage.Create("Server", welcomemessage, ChatMessageType.ServerMessageBox, nil, nil)
                            Game.SendDirectChatMessage(chatMessage, client)
                        end)
                    end
                    data.sent = true
                end
            end
        end
    end
end)