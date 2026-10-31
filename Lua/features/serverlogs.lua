if CLIENT then return end

local function getLogsConfig()
    if not Traitormod or not Traitormod.Config or not Traitormod.Config.Discord then
        return nil
    end

    return Traitormod.Config.Discord.Logs
end

local function escapeJsonString(value)
    value = tostring(value or "")
    value = value:gsub("\\", "\\\\")
    value = value:gsub('"', '\\"')
    value = value:gsub("\n", "\\n")
    value = value:gsub("\r", "\\r")
    return value
end

local function hasWebhook(config)
    return config and config.Enabled ~= false and type(config.Webhook) == "string" and config.Webhook ~= ""
end

local queue = {}
local queueStart = 1
local nextFlushTime = 0

local function queueSize()
    return #queue - queueStart + 1
end

local function pushQueue(entry)
    queue[#queue + 1] = entry
end

local function peekQueue()
    return queue[queueStart]
end

local function popQueue()
    local entry = queue[queueStart]
    queue[queueStart] = nil
    queueStart = queueStart + 1

    if queueStart > #queue then
        queue = {}
        queueStart = 1
    elseif queueStart > 64 and queueStart > math.floor(#queue / 2) then
        local compacted = {}
        local index = 1
        for i = queueStart, #queue do
            compacted[index] = queue[i]
            index = index + 1
        end
        queue = compacted
        queueStart = 1
    end

    return entry
end

Hook.Add("serverLog", "voidtraitor_discordIntegrationForLogs", function(logMessage, logType)
    local config = getLogsConfig()
    if not hasWebhook(config) then return end

    pushQueue({
        type = tostring(logType),
        message = tostring(logMessage),
    })
end)

Hook.Add("think", "voidtraitor_sendBufferedMessages", function()
    local config = getLogsConfig()
    if not hasWebhook(config) then return end

    if Timer.GetTime() < nextFlushTime then return end
    if queueSize() <= 0 then
        nextFlushTime = Timer.GetTime() + (tonumber(config.FlushInterval) or 1)
        return
    end

    local maxMessages = math.max(1, tonumber(config.MaxMessagesPerBatch) or 15)
    local maxPayloadLength = math.max(256, tonumber(config.MaxPayloadLength) or 1800)
    local payloadLines = {}
    local payloadLength = 0
    local pulled = 0

    while pulled < maxMessages and queueSize() > 0 do
        local entry = peekQueue()
        local line = string.format('`%s`: %s', tostring(entry.type), tostring(entry.message))
        local lineLength = #line + 2

        if pulled > 0 and payloadLength + lineLength > maxPayloadLength then
            break
        end

        popQueue()
        payloadLines[#payloadLines + 1] = line
        payloadLength = payloadLength + lineLength
        pulled = pulled + 1
    end

    if #payloadLines > 0 then
        local content = table.concat(payloadLines, "\n")
        local username = escapeJsonString(config.Username or "Server Logs")
        local jsonPayload = string.format(
            '{"content":"%s","username":"%s"}',
            escapeJsonString(content),
            username
        )

        Networking.HttpPost(config.Webhook, function() end, jsonPayload)
    end

    nextFlushTime = Timer.GetTime() + (tonumber(config.FlushInterval) or 1)
end)
