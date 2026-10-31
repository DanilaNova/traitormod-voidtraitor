local c = {}

local promptIDToCallback = {}
local lockedOptions = setmetatable({}, { __mode = "k" })
local pointshopCloseLockNet = "VoidTraitor_PointshopCloseLock"

local function SendEventMessage(msg, options, id, eventSprite, fadeToBlack, client)
    local message = Networking.Start()
    message.WriteByte(Byte(ServerPacketHeader.EVENTACTION)) -- net header
    message.WriteByte(Byte(0)) -- conversation

    message.WriteUInt16(UShort(id)) -- ushort identifier 0
    message.WriteString(eventSprite) -- event sprite
    message.WriteByte(Byte(0)) -- dialog Type
    message.WriteBoolean(false) -- continue conversation

    message.WriteUInt16(UShort(0)) -- speak Id
    message.WriteString(msg)
    message.WriteBoolean(fadeToBlack or false) -- fade to black
    message.WriteByte(Byte(#options))
    for key, value in pairs(options) do
        message.WriteString(value)
    end
    message.WriteByte(Byte(#options))
    for i = 0, #options - 1, 1 do
        message.WriteByte(Byte(i))
    end

    Networking.Send(message, client.Connection, DeliveryMethod.Reliable)
end


Hook.Add("netMessageReceived", "Traitormod.promptResponse", function (msg, header, client)
    if header == ClientPacketHeader.EVENTMANAGER_RESPONSE then 
        local id = msg.ReadUInt16()
        local option = msg.ReadByte()

        if promptIDToCallback[id] ~= nil then
            promptIDToCallback[id](option + 1, client)
            promptIDToCallback[id] = nil
        end

        msg.BitPosition = msg.BitPosition - (8 * 3) -- rewind 3 bytes from the message, so it can be read again
    end
end)

local function SetPointshopCloseLock(client, locked)
    if client.Connection == nil then return end

    local message = Networking.Start(pointshopCloseLockNet)
    message.WriteBoolean(locked)
    Networking.Send(message, client.Connection, DeliveryMethod.Reliable)
end

c.LockOption = function (client, option)
    lockedOptions[client] = option
    SetPointshopCloseLock(client, true)
end

c.UnlockOption = function (client)
    lockedOptions[client] = nil
    SetPointshopCloseLock(client, false)
end

c.Prompt = function (message, options, client, callback, eventSprite, fadeToBlack)
    local lockedOption = lockedOptions[client]
    if lockedOption ~= nil then
        local originalOptions = options
        local optionLookup = {}
        local filteredOptions = {}
        local optionRemoved = false

        for index, option in ipairs(options) do
            if not optionRemoved and option == lockedOption then
                optionRemoved = true
            else
                table.insert(filteredOptions, option)
                optionLookup[#filteredOptions] = index
            end
        end

        if optionRemoved then
            local originalCallback = callback
            callback = function (id, responseClient)
                if id == 256 then
                    Timer.Wait(function ()
                        if lockedOptions[responseClient] == lockedOption then
                            c.Prompt(message, originalOptions, responseClient, originalCallback, eventSprite, fadeToBlack)
                        end
                    end, 1000)
                    return
                end

                originalCallback(optionLookup[id] or id, responseClient)
            end
            options = filteredOptions
        end
    end

    local currentPromptID = math.floor(math.random(0,65535))

    promptIDToCallback[currentPromptID] = callback
    SendEventMessage(message, options, currentPromptID, eventSprite, fadeToBlack, client)
end

return c