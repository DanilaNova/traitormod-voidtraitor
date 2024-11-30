local discordWebHook = "https://discord.com/api/webhooks/1298661765751509095/EKA5GiuiuGf0fvuM07XRn3qXXNqfGf2dV9X4W4Luz77q83jh2XsxdkJAxsweRHwTdeo9"

local function escapeQuotes(str)
    return str:gsub("\"", "\\\"")
end

local messageBuffer = {}
local messageDelay = 1
local maxSingleMessages = 15

local messageTimer = 0

Hook.Add("serverLog", "prisonRP_discordIntegrationForLogs", function (logMessage, logType)
    local escapedName = escapeQuotes(tostring(logType))
    local escapedMessage = escapeQuotes(tostring(logMessage))

    messageBuffer[escapedMessage] = escapedName
end)

Hook.Add("think", "prisonRP_sendBufferedMessages", function ()
    if Timer.GetTime() < messageTimer then return end

    local appendedMessage = ""

    local totalSent = 0
    for key, value in pairs(messageBuffer) do
        appendedMessage = appendedMessage .. '`' .. value .. '`' .. ": " .. key .. "\\n"

        messageBuffer[key] = nil
        totalSent = totalSent + 1
        if totalSent > maxSingleMessages then break end
    end

    if appendedMessage ~= "" then
        Networking.RequestPostHTTP(discordWebHook, function(result) end, '{\"content\": \"'..appendedMessage..'\", \"username\": \"'..'Server Logs'..'\"}')
    end

    messageTimer = Timer.GetTime() + messageDelay
end)
