local statistics = {}
statistics.stats = {}
local textPromptUtils = require("textpromptutils")

local ItemsShown = 30 -- Sets how many lines will be shown. Should not be much more than 50
local spairs
local playtimeUpdateTimer = 0

Hook.Add("think", "Traitormod.Playtime.think", function(deltaTime)
    playtimeUpdateTimer = playtimeUpdateTimer + deltaTime
    if playtimeUpdateTimer < 1 then return end

    local elapsed = playtimeUpdateTimer
    playtimeUpdateTimer = 0

    for _, client in pairs(Client.ClientList) do
        Traitormod.AddData(client, "Playtime", elapsed)
    end
end)

statistics.LoadData = function ()
    if Traitormod.Config.PermanentStatistics then
        statistics.stats = Traitormod.ReadJsonFile(Traitormod.Path .. "/Lua/data/stats.json", {})
    else
        statistics.stats = {}
    end
end

statistics.SaveData = function ()
    if Traitormod.Config.PermanentStatistics then
        Traitormod.WriteJsonFile(Traitormod.Path .. "/Lua/data/stats.json", statistics.stats)
    end
end

statistics.GetRoundNumber = function ()
    local rounds = statistics.stats["Rounds"]
    return math.max(0, math.floor(tonumber(rounds and rounds["Rounds finished"]) or 0))
end

statistics.SetStat = function (category, key, value)
    if statistics.stats[category] == nil then statistics.stats[category] = {} end
    statistics.stats[category][key] = value

    if category == "Rounds" and key == "Rounds finished" then
        Traitormod.RoundNumber = statistics.GetRoundNumber()
    end
end

statistics.AddStat = function (category, key, value)
    if statistics.stats[category] == nil then statistics.stats[category] = {} end
    statistics.SetStat(category, key, (statistics.stats[category][key] or 0) + value)
    return statistics.stats[category][key]
end

statistics.GetStat = function (category, key)
    return statistics.stats[category][key]
end

statistics.SetListStat = function (category, key, value, name)
    if statistics.stats[category] == nil then 
        statistics.stats[category] = {}
    end

    if statistics.stats[category][key] == nil then 
        statistics.stats[category][key] = {} 
    end

    statistics.stats[category][key].Name = name or key
    statistics.stats[category][key].Score = value
end

statistics.AddListStat = function (category, key, value, name)
    local oldValue = 0
    if statistics.stats[category] and statistics.stats[category][key] then
        oldValue = statistics.stats[category][key].Score or 0
    end
    statistics.SetListStat(category, key, (oldValue + value), name)
end

statistics.AddClientStat = function(category, client, value)
    if client then
        local accountKey = Traitormod.GetClientAccountKey(client)
        local legacySteamId = Traitormod.GetClientLegacySteamId(client)

        if legacySteamId ~= nil and legacySteamId ~= accountKey and statistics.stats[category] ~= nil and statistics.stats[category][accountKey] == nil and statistics.stats[category][legacySteamId] ~= nil then
            statistics.stats[category][accountKey] = statistics.stats[category][legacySteamId]
            statistics.stats[category][legacySteamId] = nil
        end

        statistics.AddListStat(category, accountKey, value, client.Name)
    else
        Traitormod.Error("AddClientStat failed for " .. category .. " - Client was null")
    end
end

statistics.AddCharacterStat = function(category, character, value)
    local client = Traitormod.FindClientCharacter(character)
    if client ~= nil then
        statistics.AddClientStat(category, client, value)
    end
end

statistics.ShowStats = function(client, category)
    local text = Traitormod.GetText("CMDStatsNoStats")
    local elem = statistics.stats[category]

    if elem then
        local firstKey = next(elem)
        if firstKey ~= nil then
            local itemLimit = ItemsShown
            local compare = function(t,a,b) return t[b] < t[a] end
            local isTable = false
            local topic = category .. " - " .. (Traitormod.Language[category] or Traitormod.GetText("CMDStatsDefaultCategory"))
            text = ""

            if elem[firstKey] and type(elem[firstKey]) == "table" and elem[firstKey].Score ~= nil then
                compare = function(t,a,b) return t[b].Score < t[a].Score end
                isTable = true
            end

            for key, value in spairs(elem, compare) do
                if isTable then
                    text = text .. "\n" .. math.floor(value.Score) .. " - " .. (value.Name or key)
                else
                    text = text .. "\n" .. value .. " - " ..  key
                end

                itemLimit = itemLimit - 1
                if itemLimit == 0 then
                    break
                end
            end

            text = topic .. ":\n" .. text
        end
    end

    Traitormod.SendMessage(client, text)
end

statistics.Command = function (client, args)
    if #args > 0 then
        statistics.ShowStats(client, args[1])
    else
        local text = Traitormod.GetText("CMDStatsAvailable") .. "\n"

        if next(statistics.stats) == nil  then
            text = Traitormod.GetText("CMDStatsNoneAvailable")
        else
            local options = {}
            if not client.InGame then
                for key, value in pairs(statistics.stats) do
                    text = text .. "\n>> " .. key
                end
                text = text .. "\n\n" .. Traitormod.GetText("CMDStatsUsage")
            elseif client.HasPermission(ClientPermissions.ConsoleCommands) then
                -- if in game show convenient prompt
                for key, value in pairs(statistics.stats) do
                    table.insert(options, key)
                end
                table.insert(options, "")
                table.insert(options, "")
                
                textPromptUtils.Prompt(text, options, client, function (id, client2)
                    statistics.ShowStats(client2, options[id])
                end)
                return true
            else
                text = Traitormod.GetText("CMDStatsLobbyOnly")
            end
        end

        Traitormod.SendMessage(client, text)
    end

    return true
end

spairs = function(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

statistics.LoadData()
Traitormod.RoundNumber = statistics.GetRoundNumber()
Traitormod.Stats = statistics

return statistics
