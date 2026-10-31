dofile(Traitormod.Path .. "/Lua/traitormodutil.lua")

local dataDirectory = Traitormod.Path .. "/Lua/data"
if not File.DirectoryExists(dataDirectory) then
    File.CreateDirectory(dataDirectory)
end

for _, fileName in ipairs({"data.json", "stats.json", "discordstate.json"}) do
    local oldPath = Traitormod.Path .. "/Lua/" .. fileName
    local newPath = dataDirectory .. "/" .. fileName
    if File.Exists(oldPath) then
        if not File.Exists(newPath) then
            File.Move(oldPath, newPath)
        elseif File.Read(oldPath) == File.Read(newPath) then
            File.Delete(oldPath)
        else
            local legacyPath = newPath .. ".legacy"
            local suffix = 1
            while File.Exists(legacyPath) do
                legacyPath = newPath .. ".legacy." .. suffix
                suffix = suffix + 1
            end
            File.Move(oldPath, legacyPath)
            Traitormod.Log("Preserved conflicting legacy data file at " .. legacyPath)
        end
    end
end

local discordConfig = Traitormod.Config.Discord
if discordConfig ~= nil then
    if discordConfig.StateFile == Traitormod.Path .. "/Lua/discordstate.json" then
        discordConfig.StateFile = dataDirectory .. "/discordstate.json"
    end
end

dofile(Traitormod.Path .. "/Lua/features/discordwebhooks.lua")
Game.OverrideTraitors(true)

if Traitormod.Config.RagdollOnDisconnect ~= nil then
    Game.DisableDisconnectCharacter(not Traitormod.Config.RagdollOnDisconnect)
end

if Traitormod.Config.EnableControlHusk ~= nil then
    Game.EnableControlHusk(Traitormod.Config.EnableControlHusk)
end

math.randomseed(os.time())

Traitormod.Gamemodes = {}

---Adds a gamemode and loads its config by gamemode.Name
---@param gamemode Gamemode
Traitormod.AddGamemode = function(gamemode)
    Traitormod.Gamemodes[gamemode.Name] = gamemode

    if Traitormod.Config.GamemodeConfig[gamemode.Name] ~= nil then
        for key, value in pairs(Traitormod.Config.GamemodeConfig[gamemode.Name]) do
            gamemode[key] = value
        end
    end
end

if not File.Exists(Traitormod.Path .. "/Lua/data/data.json") then
    File.Write(Traitormod.Path .. "/Lua/data/data.json", "{}")
end

---Number of completed rounds
Traitormod.RoundNumber = 0
---Time of current round in seconds
Traitormod.RoundTime = 0
---Players who lost a live in a current round
---@type table<string, boolean>
Traitormod.LostLivesThisRound = {}
---Commands stored by name as key
---//TODO: Make a 'Command' type
Traitormod.Commands = {}
---Players who respawned with their character as key
---@type table<Barotrauma.Character, Barotrauma.Networking.Client>
Traitormod.RespawnedCharacters = {}

local pointsGiveTimer = -1
local gamemodeThinkInterval = 0.25
local gamemodeThinkTimer

Traitormod.SkillBuffs = dofile(Traitormod.Path .. "/Lua/features/skillbuffs.lua")

Traitormod.LoadData()

if Traitormod.Config.RemotePoints then
    for key, value in pairs(Client.ClientList) do
        Traitormod.LoadRemoteData(value)
    end
end

LuaUserData.RegisterType("Barotrauma.GameModePreset")
LuaUserData.RegisterType("Barotrauma.Voting")

---//TODO
---@param submarineInfo Barotrauma.SubmarineInfo
---@param chooseGamemode unknown
Traitormod.PreRoundStart = function (submarineInfo, chooseGamemode)
    Traitormod.SelectedGamemode = nil
    Traitormod.Config.TestMode = false
    Traitormod.TestModeOverride = nil

    local description = submarineInfo.Description.Value
    local subConfig = Traitormod.ParseSubmarineConfig(description)

    if subConfig.Gamemode and Traitormod.Gamemodes[subConfig.Gamemode] then
        Traitormod.SelectedGamemode = Traitormod.Gamemodes[subConfig.Gamemode]:new()
        for key, value in pairs(subConfig) do
            Traitormod.SelectedGamemode[key] = value
        end
    elseif Game.ServerSettings.GameModeIdentifier == "pvp" then
        local hideAndSeekV2 = Traitormod.Gamemodes.HideAndSeekV2
        local attackDefendV2 = Traitormod.Gamemodes.AttackDefendV2
        if hideAndSeekV2 ~= nil and hideAndSeekV2:CheckRequirements() then
            Traitormod.SelectedGamemode = hideAndSeekV2:new()
        elseif attackDefendV2 ~= nil and attackDefendV2:CheckRequirements() then
            Traitormod.SelectedGamemode = attackDefendV2:new()
        else
            if attackDefendV2 == nil then
                Traitormod.Error("AttackDefendV2 gamemode was not loaded. Falling back to PvP.")
            end
            Traitormod.SelectedGamemode = Traitormod.Gamemodes.PvP:new()
        end
    elseif Game.ServerSettings.GameModeIdentifier == "multiplayercampaign" then
        if Traitormod.Gamemodes.Gamemode ~= nil then
            Traitormod.SelectedGamemode = Traitormod.Gamemodes.Gamemode:new()
        end
    elseif math.random() <= Game.ServerSettings.TraitorProbability and Traitormod.Gamemodes.Secret ~= nil then
        Traitormod.SelectedGamemode = Traitormod.Gamemodes.Secret:new()
    else
        if Traitormod.Gamemodes.Gamemode ~= nil then
            Traitormod.SelectedGamemode = Traitormod.Gamemodes.Gamemode:new()
        end
    end

    if Traitormod.SelectedGamemode == nil then
        Traitormod.Error("No gamemode could be selected. Check Lua load errors above this message.")
        return
    end

    if Traitormod.SelectedGamemode.RequiredGamemode then
        Traitormod.OriginalGamemode = Game.ServerSettings.GameModeIdentifier
        Game.NetLobbyScreen.SelectedModeIdentifier = Traitormod.SelectedGamemode.RequiredGamemode
        chooseGamemode.Gamemode = Game.NetLobbyScreen.SelectedMode
    end

    if Traitormod.SelectedGamemode then
        Traitormod.SelectedGamemode:PreStart()
    end
end

Traitormod.RoundStart = function()
    Traitormod.Log("Starting traitor round - Traitor Mod v" .. Traitormod.VERSION)
    pointsGiveTimer = Timer.GetTime() + Traitormod.Config.ExperienceTimer
    Traitormod.SkillBuffs.RoundStart()

    Traitormod.CodeWords = Traitormod.SelectCodeWords()

    -- give XP to players based on stored points
    for key, value in pairs(Client.ClientList) do
        if value.Character ~= nil then
            Traitormod.SetData(value, "Name", value.Character.Name)
        end

        if not value.SpectateOnly then
            Traitormod.LoadExperience(value)
        else
            Traitormod.Debug("Skipping load experience for spectator " .. value.Name)
        end

        -- Send Welcome message
        Traitormod.SendWelcome(value)
    end

    if Traitormod.Config.HideCrewList
        and (Traitormod.SelectedGamemode == nil or not Traitormod.SelectedGamemode.HandlesCrewListHiding) then
        for key, value in pairs(Character.CharacterList) do
            Networking.CreateEntityEvent(value, Character.RemoveFromCrewEventData.__new(value.TeamID, {}))
        end
    end

    if Traitormod.SelectedGamemode == nil then
        Traitormod.Log("No gamemode selected!")
        return
    end

    Traitormod.Log("Starting gamemode " .. Traitormod.SelectedGamemode.Name)

    if Traitormod.Discord then
        Traitormod.Discord.AnnounceRoundStarted()
    end

    if Traitormod.SubmarineBuilder then
        Traitormod.SubmarineBuilder.RoundStart()
    end

    if Traitormod.SelectedGamemode then
        Traitormod.SelectedGamemode:Start()
    end
end

Hook.Patch("Barotrauma.Networking.GameServer", "InitiateStartGame", function (instance, ptable)
    local mode = {}
    Traitormod.PreRoundStart(ptable["selectedSub"], mode)
    if mode.Gamemode then
        ptable["selectedMode"] = mode.Gamemode
    end

    if Traitormod.SubmarineBuilder then
        ptable["selectedShuttle"] = Traitormod.SubmarineBuilder.BuildSubmarines()
    end
end)

Hook.Add("roundStart", "Traitormod.RoundStart", function()
    Traitormod.ClearTemporarySkillBuffs()
    Traitormod.RoundStart()
end)

---@param missions Barotrauma.Mission[]
Hook.Add("missionsEnded", "Traitormod.MissionsEnded", function(missions)
    Traitormod.RoundMissions = missions
    Traitormod.Debug("missionsEnded with " .. #Traitormod.RoundMissions .. " missions.")

    for key, value in pairs(Client.ClientList) do
        -- add weight according to points and config conversion
        Traitormod.AddData(value, "Weight", Traitormod.Config.AmountWeightWithPoints(Traitormod.GetData(value, "Points") or 0))
    end

    if Traitormod.Discord then
        Traitormod.Discord.AnnounceRoundEnded(Traitormod.RoundTime)
    end

    Traitormod.Debug("Round " .. Traitormod.RoundNumber .. " ended.")
    Traitormod.RoundNumber = Traitormod.RoundNumber + 1
    Traitormod.Stats.AddStat("Rounds", "Rounds finished", 1)

    Traitormod.PointsToBeGiven = {}
    Traitormod.AbandonedCharacters = {}
    Traitormod.PointItems = {}
    Traitormod.RoundTime = 0
    Traitormod.LostLivesThisRound = {}

    local endMessage = ""
    if Traitormod.SelectedGamemode then
        endMessage = Traitormod.SelectedGamemode:RoundSummary()

        if not Traitormod.SelectedGamemode.UsesSecretRules or Traitormod.SelectedGamemode.FinalSummary == nil then
            Traitormod.SendMessageEveryone(Traitormod.HighlightClientNames(endMessage, Color.Red))
        end
    end
    Traitormod.LastRoundSummary = endMessage

    if Traitormod.SelectedGamemode then
        Traitormod.SelectedGamemode:End(missions)
    end

    Traitormod.RoleManager.EndRound()
    Traitormod.RoundEvents.EndRound()

    Traitormod.SelectedGamemode = nil

    Traitormod.SaveData()
    Traitormod.Stats.SaveData()

    if Traitormod.Config.RemotePoints then
        for key, value in pairs(Client.ClientList) do
            Traitormod.PublishRemoteData(value)
        end
    end
end)

Hook.Add("roundEnd", "Traitormod.RoundEnd", function()
    Traitormod.ClearTemporarySkillBuffs()
    pointsGiveTimer = -1
    Traitormod.SkillBuffs.RoundEnd()

    if Traitormod.OriginalGamemode then
        Game.NetLobbyScreen.SelectedModeIdentifier = Traitormod.OriginalGamemode
        Traitormod.OriginalGamemode = nil
    end

    Traitormod.RespawnedCharacters = {}

    if Traitormod.SelectedGamemode then
        --return Traitormod.SelectedGamemode:TraitorResults()
        return nil
    end
end)

---@param character Barotrauma.Character
Hook.Add("characterCreated", "Traitormod.CharacterCreated", function(character)
    -- if character is valid player
    if character == nil or
        character.IsBot == true or
        character.IsHuman == false or
        character.ClientDisconnected == true then
        return
    end

    -- delay handling, otherwise client won't be found
    Timer.Wait(function()
        local client = Traitormod.FindClientCharacter(character)

        if client ~= nil then
            Traitormod.Stats.AddClientStat("Spawns", client, 1)
            -- set experience of respawned character to stored value - note initial spawn may not call this hook (on local server)
            Traitormod.LoadExperience(client)
        else
            Traitormod.Error("Loading experience on characterCreated failed! Client was nil after 1sec")
        end
    end, 1000)
end)

local tipDelay = 0

Hook.Add("think", "Traitormod.Think", function(deltaTime)
    Traitormod.SkillBuffs.Think(deltaTime)

    if Timer.GetTime() > tipDelay then
        tipDelay = Timer.GetTime() + 500
        Traitormod.SendTip()
    end

    if not Game.RoundStarted or Traitormod.SelectedGamemode == nil then
        gamemodeThinkTimer = nil
        return
    end

    if not Traitormod.IsRoundFinalizing() then
        Traitormod.RoundTime = Traitormod.RoundTime + deltaTime
    end

    local gamemodeDeltaTime
    if gamemodeThinkTimer == nil then
        gamemodeThinkTimer = 0
        gamemodeDeltaTime = deltaTime
    else
        gamemodeThinkTimer = gamemodeThinkTimer + deltaTime
        if gamemodeThinkTimer >= gamemodeThinkInterval then
            gamemodeDeltaTime = gamemodeThinkTimer
            gamemodeThinkTimer = 0
        end
    end

    if gamemodeDeltaTime ~= nil then
        Traitormod.SelectedGamemode:Think(gamemodeDeltaTime)
    end

    if Traitormod.IsRoundFinalizing() then return end

    -- give points/xp on the configured experience timer
    if pointsGiveTimer and Timer.GetTime() > pointsGiveTimer then
        for key, value in pairs(Traitormod.PointsToBeGiven) do
            if value > 100 then
                local points = Traitormod.AwardPoints(key, value)
                if Traitormod.GiveExperience(key.Character, Traitormod.Config.AmountExperienceWithPoints(points)) then
                    local text = Traitormod.Language.SkillsIncreased ..
                        "\n" .. string.format(Traitormod.Language.PointsAwarded, math.floor(points))
                    Game.SendDirectChatMessage("", text, nil, Traitormod.Config.ChatMessageType, key)

                    Traitormod.PointsToBeGiven[key] = 0
                end
            end
        end

        -- if configured, give temporary experience to all characters
        if Traitormod.Config.FreeExperience and Traitormod.Config.FreeExperience > 0 then
            for key, value in pairs(Client.ClientList) do
                Traitormod.GiveExperience(value.Character, Traitormod.Config.FreeExperience)
            end
        end

        pointsGiveTimer = Timer.GetTime() + Traitormod.Config.ExperienceTimer
    end

    Traitormod.SkillBuffs.UpdateRoundSkillGain()
end)

-- when a character gains skill level, add PointsToBeGiven according to config
Traitormod.PointsToBeGiven = {}
Hook.HookMethod("Barotrauma.CharacterInfo", "IncreaseSkillLevel", function(instance, ptable)
    if Traitormod.IsRoundFinalizing() then return end
    if not ptable or ptable.gainedFromAbility or instance.Character == nil or instance.Character.IsDead then return end

    Traitormod.OnTrackedSkillIncrease(instance.Character, tostring(ptable.skillIdentifier), ptable.increase, ptable.gainedFromAbility)

    local client = Traitormod.FindClientCharacter(instance.Character)

    if client == nil then return end

    local points = Traitormod.Config.PointsGainedFromSkill[tostring(ptable.skillIdentifier)]

    if points == nil then return end

    points = points * ptable.increase

    Traitormod.PointsToBeGiven[client] = (Traitormod.PointsToBeGiven[client] or 0) + points
end)

Traitormod.AbandonedCharacters = {}

-- new player connected to the server
Hook.Add("clientConnected", "Traitormod.ClientConnected", function (client)
    if Traitormod.Config.RemotePoints then
        Traitormod.LoadRemoteData(client, function ()
            Traitormod.SendWelcome(client)
        end)
    else
        Traitormod.SendWelcome(client)
    end

    if Traitormod.Discord then
        Traitormod.Discord.AnnounceClientConnected(client)
    end

    Traitormod.GhostRoles.HandleReconnect(client)
end)

-- player disconnected from server
Hook.Add("clientDisconnected", "Traitormod.ClientDisconnected", function (client)
    if Traitormod.Config.RemotePoints then
        Traitormod.PublishRemoteData(client)
    end

    if Traitormod.Discord then
        Traitormod.Discord.AnnounceClientDisconnected(client)
    end

    Traitormod.GhostRoles.HandleDisconnect(client)
end)

-- Traitormod.Commands hook
Hook.Add("chatMessage", "Traitormod.ChatMessage", function(message, client)
    local split = Traitormod.ParseCommand(message)

    if #split == 0 then return end

    local command = string.lower(table.remove(split, 1))

    if Traitormod.Commands[command] then
        Traitormod.Log(Traitormod.ClientLogName(client) .. " used command: " .. message)
        local result = { pcall(Traitormod.Commands[command].Callback, client, split) }
        if not result[1] then
            Traitormod.SendChatMessage(client, string.format(Traitormod.GetText("CommandError"), tostring(result[2])))
            return true
        end
        return table.unpack(result, 2)
    end

    if string.sub(command, 1, 1) == "!" then
        Traitormod.SendChatMessage(client, Traitormod.GetText("UnknownCommand"))
        return true
    end
end)


Hook.Patch("Barotrauma.Items.Components.Terminal", "ServerEventRead", function(instance, ptable)
    local msg = ptable["msg"]
    local client = ptable["c"]

    local rewindBit = msg.BitPosition
    local output = msg.ReadString()
    msg.BitPosition = rewindBit -- this is so the game can still read the net message, as you cant read the same bit twice

    local item = instance.Item

    Hook.Call("traitormod.terminalWrite", item, client, output)
end, Hook.HookMethodType.Before)


if Traitormod.Config.OverrideRespawnSubmarine then
    Traitormod.SubmarineBuilder = dofile(Traitormod.Path .. "/Lua/submarinebuilder.lua")
end

---@module "Lua.stringbuilder"
Traitormod.StringBuilder = dofile(Traitormod.Path .. "/Lua/stringbuilder.lua")
---@module "Lua.voting"
Traitormod.Voting = dofile(Traitormod.Path .. "/Lua/voting.lua")
---@module "Lua.rolemanager"
Traitormod.RoleManager = dofile(Traitormod.Path .. "/Lua/rolemanager.lua")
---@module "Lua.pointshop"
---@class Pointshop.Ref: Pointshop
Traitormod.Pointshop = dofile(Traitormod.Path .. "/Lua/pointshop.lua")
---@module "Lua.roundevents"
Traitormod.RoundEvents = dofile(Traitormod.Path .. "/Lua/roundevents.lua")
---@module "Lua.features.midroundspawn"
Traitormod.MidRoundSpawn = dofile(Traitormod.Path .. "/Lua/features/midroundspawn.lua")
---@module "Lua.ghostroles"
Traitormod.GhostRoles = dofile(Traitormod.Path .. "/Lua/ghostroles.lua")
Traitormod.RoundStats = dofile(Traitormod.Path .. "/Lua/roundstats.lua")
Traitormod.CameraTeleport = dofile(Traitormod.Path .. "/Lua/features/camerateleport.lua")
Traitormod.AdminGhost = dofile(Traitormod.Path .. "/Lua/features/adminghost.lua")

Traitormod.Stats = dofile(Traitormod.Path .. "/Lua/statistics.lua")
dofile(Traitormod.Path .. "/Lua/features/pointitems.lua")
dofile(Traitormod.Path .. "/Lua/features/respawnshuttle.lua")
dofile(Traitormod.Path .. "/Lua/features/welcome.lua")
dofile(Traitormod.Path .. "/Lua/features/deathlogbook.lua")
dofile(Traitormod.Path .. "/Lua/features/killfeed.lua")
dofile(Traitormod.Path .. "/Lua/features/serverlogs.lua")
dofile(Traitormod.Path .. "/Lua/features/piratemissionghostroles.lua")

Traitormod.AddGamemode(dofile(Traitormod.Path .. "/Lua/gamemodes/gamemode.lua"))
Traitormod.AddGamemode(dofile(Traitormod.Path .. "/Lua/gamemodes/secret.lua"))
Traitormod.AddGamemode(dofile(Traitormod.Path .. "/Lua/gamemodes/station/station.lua"))
Traitormod.AddGamemode(dofile(Traitormod.Path .. "/Lua/gamemodes/pvp.lua"))
Traitormod.AddGamemode(dofile(Traitormod.Path .. "/Lua/gamemodes/submarineroyale.lua"))
Traitormod.AddGamemode(dofile(Traitormod.Path .. "/Lua/gamemodes/attackdefendv2.lua"))
Traitormod.AddGamemode(dofile(Traitormod.Path .. "/Lua/gamemodes/hideandseekv2.lua"))

Traitormod.RoleManager.AddObjective(dofile(Traitormod.Path .. "/Lua/objectives/objective.lua"))
Traitormod.RoleManager.AddObjective(dofile(Traitormod.Path .. "/Lua/objectives/assassinate.lua"))
Traitormod.RoleManager.AddObjective(dofile(Traitormod.Path .. "/Lua/objectives/kidnap.lua"))
Traitormod.RoleManager.AddObjective(dofile(Traitormod.Path .. "/Lua/objectives/poisoncaptain.lua"))
Traitormod.RoleManager.AddObjective(dofile(Traitormod.Path .. "/Lua/objectives/stealcaptainid.lua"))
Traitormod.RoleManager.AddObjective(dofile(Traitormod.Path .. "/Lua/objectives/survive.lua"))
Traitormod.RoleManager.AddObjective(dofile(Traitormod.Path .. "/Lua/objectives/husk.lua"))
Traitormod.RoleManager.AddObjective(dofile(Traitormod.Path .. "/Lua/objectives/turnhusk.lua"))
Traitormod.RoleManager.AddObjective(dofile(Traitormod.Path .. "/Lua/objectives/destroycaly.lua"))
Traitormod.RoleManager.AddObjective(dofile(Traitormod.Path .. "/Lua/objectives/assassinatedrunk.lua"))
Traitormod.RoleManager.AddObjective(dofile(Traitormod.Path .. "/Lua/objectives/bananaslip.lua"))
Traitormod.RoleManager.AddObjective(dofile(Traitormod.Path .. "/Lua/objectives/suffocatecrew.lua"))
Traitormod.RoleManager.AddObjective(dofile(Traitormod.Path .. "/Lua/objectives/growmudraptors.lua"))
Traitormod.RoleManager.AddObjective(dofile(Traitormod.Path .. "/Lua/objectives/assassinatepressure.lua"))
Traitormod.RoleManager.AddObjective(dofile(Traitormod.Path .. "/Lua/objectives/stealidcard.lua"))
Traitormod.RoleManager.AddObjective(dofile(Traitormod.Path .. "/Lua/objectives/detonatelocation.lua"))
Traitormod.RoleManager.AddObjective(dofile(Traitormod.Path .. "/Lua/objectives/sabotage.lua"))
Traitormod.RoleManager.AddObjective(dofile(Traitormod.Path .. "/Lua/objectives/sabotagereactor.lua"))
Traitormod.RoleManager.AddObjective(dofile(Traitormod.Path .. "/Lua/objectives/floodsubmarine.lua"))
Traitormod.RoleManager.AddObjective(dofile(Traitormod.Path .. "/Lua/objectives/destroyfuelrods.lua"))
Traitormod.RoleManager.AddObjective(dofile(Traitormod.Path .. "/Lua/objectives/crew/killmonsters.lua"))
Traitormod.RoleManager.AddObjective(dofile(Traitormod.Path .. "/Lua/objectives/crew/killsmallmonsters.lua"))
Traitormod.RoleManager.AddObjective(dofile(Traitormod.Path .. "/Lua/objectives/crew/killlargemonsters.lua"))
Traitormod.RoleManager.AddObjective(dofile(Traitormod.Path .. "/Lua/objectives/crew/killpets.lua"))
Traitormod.RoleManager.AddObjective(dofile(Traitormod.Path .. "/Lua/objectives/crew/killabyssmonster.lua"))
Traitormod.RoleManager.AddObjective(dofile(Traitormod.Path .. "/Lua/objectives/crew/repair.lua"))
Traitormod.RoleManager.AddObjective(dofile(Traitormod.Path .. "/Lua/objectives/crew/finishroundfast.lua"))
Traitormod.RoleManager.AddObjective(dofile(Traitormod.Path .. "/Lua/objectives/crew/securityteamsurvival.lua"))
Traitormod.RoleManager.AddObjective(dofile(Traitormod.Path .. "/Lua/objectives/crew/repairmechanical.lua"))
Traitormod.RoleManager.AddObjective(dofile(Traitormod.Path .. "/Lua/objectives/crew/repairelectrical.lua"))
Traitormod.RoleManager.AddObjective(dofile(Traitormod.Path .. "/Lua/objectives/crew/repairhull.lua"))
Traitormod.RoleManager.AddObjective(dofile(Traitormod.Path .. "/Lua/objectives/crew/healcharacters.lua"))
Traitormod.RoleManager.AddObjective(dofile(Traitormod.Path .. "/Lua/objectives/crew/finishallobjectives.lua"))

Traitormod.RoleManager.AddRole(dofile(Traitormod.Path .. "/Lua/roles/role.lua"))
Traitormod.RoleManager.AddRole(dofile(Traitormod.Path .. "/Lua/roles/antagonist.lua"))
Traitormod.RoleManager.AddRole(dofile(Traitormod.Path .. "/Lua/roles/traitor.lua"))
Traitormod.RoleManager.AddRole(dofile(Traitormod.Path .. "/Lua/roles/cultist.lua"))
Traitormod.RoleManager.AddRole(dofile(Traitormod.Path .. "/Lua/roles/huskservant.lua"))
Traitormod.RoleManager.AddRole(dofile(Traitormod.Path .. "/Lua/roles/crew.lua"))
Traitormod.RoleManager.AddRole(dofile(Traitormod.Path .. "/Lua/roles/clown.lua"))
Traitormod.RoleManager.AddRole(dofile(Traitormod.Path .. "/Lua/roles/saboteur.lua"))

---@module "Lua.objectivehud"
Traitormod.ObjectiveHud = dofile(Traitormod.Path .. "/Lua/objectivehud.lua")
Traitormod.ClientMenu = dofile(Traitormod.Path .. "/Lua/clientmenu.lua")

dofile(Traitormod.Path .. "/Lua/commands.lua")

if Traitormod.Config.Extensions then
    for key, extension in pairs(Traitormod.Config.Extensions) do
        local config = Traitormod.Config.ExtensionConfig[extension.Identifier or ""]
        if config then
            for key, value in pairs(config) do
                extension[key] = value
            end
        end
        if extension.Init then
            extension.Init()
        end
    end
end

-- Round start call for reload during round
if Game.RoundStarted then
    Traitormod.PreRoundStart(Submarine.MainSub.Info, {})
    Traitormod.RoundStart()
end