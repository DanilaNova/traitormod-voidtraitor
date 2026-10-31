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
Traitormod.SkillBuffStates = {}
Traitormod.NextSkillBuffId = 0

local pointsGiveTimer = -1
local roundSkillGiveTimer = -1
local skillBuffUpdateInterval = 1
local skillBuffUpdateTimer = skillBuffUpdateInterval
local gamemodeThinkInterval = 0.25
local gamemodeThinkTimer

local function isValidBuffCharacter(character)
    return character ~= nil and character.IsHuman and not character.IsDead and character.Info ~= nil and character.Info.Job ~= nil
end

local function getSkillBuffState(character, create)
    local state = Traitormod.SkillBuffStates[character]
    if state == nil and create then
        state = {
            Effects = {},
            Skills = {},
        }
        Traitormod.SkillBuffStates[character] = state
    end

    return state
end

local function getJobSkill(character, skill)
    if character == nil or character.Info == nil or character.Info.Job == nil or skill == nil then
        return nil
    end

    local identifier = Identifier(tostring(skill))
    return character.Info.Job.GetSkill(identifier)
end

local function getJobSkillLevel(character, skill)
    if character == nil or character.Info == nil or character.Info.Job == nil or skill == nil then
        return 0
    end

    local identifier = Identifier(tostring(skill))
    return math.max(0, tonumber(character.Info.Job.GetSkillLevel(identifier)) or 0)
end

local function setJobSkillLevelSilent(character, skill, level)
    if character == nil or character.Info == nil or character.Info.Job == nil or skill == nil then
        return false
    end

    local identifier = Identifier(tostring(skill))
    level = math.max(0, tonumber(level) or 0)

    local jobSkill = getJobSkill(character, skill)
    if jobSkill == nil then
        character.Info.Job.IncreaseSkillLevel(identifier, level, true)
        jobSkill = getJobSkill(character, skill)
        if jobSkill == nil then
            return false
        end
    end

    jobSkill.Level = level
    return true
end

local function getSkillStateBonus(skillState)
    local totalBonus = 0
    for _, bonus in pairs(skillState.Bonuses or {}) do
        totalBonus = totalBonus + (tonumber(bonus) or 0)
    end

    return math.max(0, totalBonus)
end

function Traitormod.GetTrackedSkillBonus(character, skill)
    local state = getSkillBuffState(character, false)
    if state == nil then
        return 0
    end

    local skillState = state.Skills[tostring(skill)]
    if skillState == nil then
        return 0
    end

    return getSkillStateBonus(skillState)
end

function Traitormod.GetBaseSkillLevel(character, skill)
    local state = getSkillBuffState(character, false)
    if state ~= nil then
        local skillState = state.Skills[tostring(skill)]
        if skillState ~= nil then
            return math.max(0, tonumber(skillState.Baseline) or 0)
        end
    end

    return getJobSkillLevel(character, skill)
end

local statusSkills = {
    { Identifier = "weapons", LanguageKey = "StatusSkillWeapons" },
    { Identifier = "mechanical", LanguageKey = "StatusSkillMechanical" },
    { Identifier = "electrical", LanguageKey = "StatusSkillElectrical" },
    { Identifier = "medical", LanguageKey = "StatusSkillMedical" },
    { Identifier = "surgery", LanguageKey = "StatusSkillSurgery" },
    { Identifier = "helm", LanguageKey = "StatusSkillHelm" },
}

local function getStatusSkillName(skillInfo)
    local languageKey = skillInfo.LanguageKey
    if Traitormod.Language ~= nil and Traitormod.Language[languageKey] ~= nil then
        return Traitormod.Language[languageKey]
    end

    return skillInfo.Identifier
end

local function formatStatusTime(seconds)
    seconds = math.max(0, math.ceil(tonumber(seconds) or 0))
    local minutes = math.floor(seconds / 60)
    local remainingSeconds = seconds % 60
    return string.format("%02d:%02d", minutes, remainingSeconds)
end

local function formatSkillEffectBonuses(skillMap)
    local parts = {}

    for _, skillInfo in ipairs(statusSkills) do
        local bonus = tonumber(skillMap[skillInfo.Identifier]) or 0
        if bonus > 0 then
            table.insert(parts, string.format("+%d %s", math.floor(bonus), getStatusSkillName(skillInfo)))
        end
    end

    for skill, bonus in pairs(skillMap) do
        local known = false
        for _, skillInfo in ipairs(statusSkills) do
            if skillInfo.Identifier == tostring(skill) then
                known = true
                break
            end
        end

        bonus = tonumber(bonus) or 0
        if not known and bonus > 0 then
            table.insert(parts, string.format("+%d %s", math.floor(bonus), tostring(skill)))
        end
    end

    if #parts == 0 then
        return Traitormod.GetText("StatusUnknownEffect")
    end

    return table.concat(parts, ", ")
end

function Traitormod.GetStatusMessage(character)
    if not isValidBuffCharacter(character) then
        return Traitormod.GetText("StatusAliveRequired")
    end

    local lines = {}
    table.insert(lines, Traitormod.GetText("StatusTitle"))
    table.insert(lines, "")
    table.insert(lines, Traitormod.GetText("StatusSkillsHeader"))

    for _, skillInfo in ipairs(statusSkills) do
        local base = math.floor(Traitormod.GetBaseSkillLevel(character, skillInfo.Identifier))
        local bonus = math.floor(Traitormod.GetTrackedSkillBonus(character, skillInfo.Identifier))
        local current = math.floor(getJobSkillLevel(character, skillInfo.Identifier))
        local skillName = getStatusSkillName(skillInfo)

        if bonus > 0 then
            table.insert(lines, string.format(Traitormod.GetText("StatusSkillLineWithBonus"), skillName, base, bonus, current))
        else
            table.insert(lines, string.format(Traitormod.GetText("StatusSkillLine"), skillName, current))
        end
    end

    table.insert(lines, "")
    table.insert(lines, Traitormod.GetText("StatusEffectsHeader"))

    local effects = {}
    local state = getSkillBuffState(character, false)
    if state ~= nil then
        local now = Timer.GetTime()
        for _, effect in pairs(state.Effects or {}) do
            if effect.ExpiresAt ~= nil then
                table.insert(effects, {
                    Text = formatSkillEffectBonuses(effect.Skills or {}),
                    Remaining = math.max(0, effect.ExpiresAt - now),
                })
            end
        end
    end

    table.sort(effects, function(a, b) return a.Remaining < b.Remaining end)

    if #effects == 0 then
        table.insert(lines, Traitormod.GetText("StatusNoEffects"))
    else
        for _, effect in ipairs(effects) do
            table.insert(lines, string.format(Traitormod.GetText("StatusEffectLine"), effect.Text, formatStatusTime(effect.Remaining)))
        end
    end

    return table.concat(lines, "\n")
end

function Traitormod.OnTrackedSkillIncrease(character, skill, amount, gainedFromAbility)
    if gainedFromAbility or character == nil or skill == nil then
        return
    end

    local state = getSkillBuffState(character, false)
    if state == nil then
        return
    end

    local skillState = state.Skills[tostring(skill)]
    if skillState == nil then
        return
    end

    local totalBonus = getSkillStateBonus(skillState)
    local current = getJobSkillLevel(character, skill)
    skillState.Baseline = math.max(0, current - totalBonus)
end

function Traitormod.ApplyTemporarySkillBuff(character, skillMap, durationSeconds)
    if not isValidBuffCharacter(character) then
        return false
    end

    durationSeconds = tonumber(durationSeconds)
    if durationSeconds == nil then
        durationSeconds = 300
    end

    local state = getSkillBuffState(character, true)
    local effect = {
        Character = character,
        ExpiresAt = durationSeconds > 0 and (Timer.GetTime() + durationSeconds) or nil,
        Skills = {},
    }

    Traitormod.NextSkillBuffId = Traitormod.NextSkillBuffId + 1
    effect.Id = Traitormod.NextSkillBuffId

    for skill, bonus in pairs(skillMap or {}) do
        skill = tostring(skill)
        bonus = tonumber(bonus) or 0

        if bonus > 0 then
            local current = getJobSkillLevel(character, skill)
            local skillState = state.Skills[skill]

            if skillState == nil then
                skillState = {
                    Baseline = current,
                    Bonuses = {},
                }
                state.Skills[skill] = skillState
            else
                local totalBonus = getSkillStateBonus(skillState)
                if current > (skillState.Baseline or 0) + totalBonus then
                    skillState.Baseline = current - totalBonus
                end
            end

            effect.Skills[skill] = bonus
            skillState.Bonuses[effect.Id] = bonus

            local targetLevel = (skillState.Baseline or 0) + getSkillStateBonus(skillState)
            if not setJobSkillLevelSilent(character, skill, targetLevel) then
                skillState.Bonuses[effect.Id] = nil
                effect.Skills[skill] = nil
            end
        end
    end

    if next(effect.Skills) == nil then
        return false
    end

    state.Effects[effect.Id] = effect
    return true
end

function Traitormod.RemoveTemporarySkillBuff(character, effectId)
    local state = getSkillBuffState(character, false)
    if state == nil then
        return false
    end

    local effect = state.Effects[effectId]
    if effect == nil then
        return false
    end

    state.Effects[effectId] = nil

    for skill in pairs(effect.Skills) do
        local skillState = state.Skills[skill]
        if skillState ~= nil then
            local totalBonus = getSkillStateBonus(skillState)
            local current = getJobSkillLevel(character, skill)
            if current > (skillState.Baseline or 0) + totalBonus then
                skillState.Baseline = current - totalBonus
            end

            skillState.Bonuses[effectId] = nil

            local remainingBonus = getSkillStateBonus(skillState)
            if remainingBonus <= 0 then
                setJobSkillLevelSilent(character, skill, skillState.Baseline or 0)
                state.Skills[skill] = nil
            else
                setJobSkillLevelSilent(character, skill, (skillState.Baseline or 0) + remainingBonus)
            end
        end
    end

    if next(state.Effects) == nil and next(state.Skills) == nil then
        Traitormod.SkillBuffStates[character] = nil
    end

    return true
end

function Traitormod.ClearTemporarySkillBuffs()
    for character, state in pairs(Traitormod.SkillBuffStates) do
        if character ~= nil and character.Info ~= nil and character.Info.Job ~= nil then
            for skill, skillState in pairs(state.Skills or {}) do
                setJobSkillLevelSilent(character, skill, skillState.Baseline or 0)
            end
        end
    end

    Traitormod.SkillBuffStates = {}
    Traitormod.NextSkillBuffId = 0
end

local function hasAliveTeam1Job(jobIdentifier)
    for _, character in pairs(Character.CharacterList) do
        if character ~= nil and character.IsHuman and not character.IsDead and character.TeamID == CharacterTeamType.Team1 and character.HasJob(jobIdentifier) then
            return true
        end
    end

    return false
end

local function applyRoundSkillGain()
    local config = Traitormod.Config.RoundSkillGain
    if config == nil or not config.Enabled then
        return
    end

    if config.SecretOnly and (Traitormod.SelectedGamemode == nil or Traitormod.SelectedGamemode.Name ~= "Secret") then
        return
    end

    for _, roleConfig in pairs(config.Roles or {}) do
        local hasAliveRole = hasAliveTeam1Job(roleConfig.Job)
        local minGain = hasAliveRole and config.AliveRoleMin or config.MissingRoleMin
        local maxGain = hasAliveRole and config.AliveRoleMax or config.MissingRoleMax
        local cap = hasAliveRole and config.AliveRoleCap or config.MissingRoleCap

        for _, character in pairs(Character.CharacterList) do
            if character ~= nil and character.IsHuman and not character.IsDead then
                if (not config.AliveTeam1Only) or character.TeamID == CharacterTeamType.Team1 then
                    local baseSkill = Traitormod.GetBaseSkillLevel(character, roleConfig.Skill)
                    if baseSkill < cap then
                        local amount = math.random(minGain, maxGain)
                        amount = math.min(amount, cap - baseSkill)
                        if amount > 0 then
                            Traitormod.ApplyTemporarySkillBuff(character, { [roleConfig.Skill] = amount }, -1)
                        end
                    end
                end
            end
        end
    end
end

Traitormod.LoadData()

if Traitormod.Config.RemotePoints then
    for key, value in pairs(Client.ClientList) do
        Traitormod.LoadRemoteData(value)
    end
end

LuaUserData.RegisterType("Barotrauma.GameModePreset")
LuaUserData.RegisterType("Barotrauma.Voting")

Voting = LuaUserData.CreateStatic("Barotrauma.Voting") --[[@as Barotrauma.Voting]]
---//TODO
---@param submarineInfo Barotrauma.SubmarineInfo
---@param chooseGamemode unknown
Traitormod.PreRoundStart = function (submarineInfo, chooseGamemode)
    Traitormod.SelectedGamemode = nil

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
    if Traitormod.Config.RoundSkillGain ~= nil and Traitormod.Config.RoundSkillGain.Enabled then
        roundSkillGiveTimer = Timer.GetTime() + (tonumber(Traitormod.Config.RoundSkillGain.Timer) or Traitormod.Config.ExperienceTimer)
    else
        roundSkillGiveTimer = -1
    end

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

    if Traitormod.Config.HideCrewList then
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

        if Traitormod.SelectedGamemode.Name ~= "Secret" or Traitormod.SelectedGamemode.FinalSummary == nil then
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
    roundSkillGiveTimer = -1

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
local updateAbandonedCharacters
local abandonedCharacterUpdateInterval = 0.25
local abandonedCharacterUpdateTimer = abandonedCharacterUpdateInterval

Hook.Add("think", "Traitormod.Think", function(deltaTime)
    skillBuffUpdateTimer = skillBuffUpdateTimer + deltaTime
    if skillBuffUpdateTimer >= skillBuffUpdateInterval then
        skillBuffUpdateTimer = 0
        local now = Timer.GetTime()

        for character, state in pairs(Traitormod.SkillBuffStates) do
            if not isValidBuffCharacter(character) then
                if character ~= nil and character.Info ~= nil and character.Info.Job ~= nil then
                    for skill, skillState in pairs(state.Skills or {}) do
                        setJobSkillLevelSilent(character, skill, skillState.Baseline or 0)
                    end
                end
                Traitormod.SkillBuffStates[character] = nil
            else
                for effectId, effect in pairs(state.Effects) do
                    if effect.ExpiresAt ~= nil and now >= effect.ExpiresAt then
                        Traitormod.RemoveTemporarySkillBuff(character, effectId)
                    end
                end

                state = Traitormod.SkillBuffStates[character]
                if state ~= nil then
                    for skill, skillState in pairs(state.Skills) do
                        local totalBonus = 0
                        for _, bonus in pairs(skillState.Bonuses or {}) do
                            totalBonus = totalBonus + (tonumber(bonus) or 0)
                        end
                        local expected = (skillState.Baseline or 0) + totalBonus

                        local current = getJobSkillLevel(character, skill)
                        if current > expected then
                            skillState.Baseline = current - totalBonus
                            expected = current
                        elseif current < expected then
                            setJobSkillLevelSilent(character, skill, expected)
                        end

                        if next(skillState.Bonuses or {}) == nil then
                            state.Skills[skill] = nil
                        end
                    end

                    if next(state.Effects) == nil and next(state.Skills) == nil then
                        Traitormod.SkillBuffStates[character] = nil
                    end
                end
            end
        end
    end

    if Timer.GetTime() > tipDelay then
        tipDelay = Timer.GetTime() + 500
        Traitormod.SendTip()
    end

    abandonedCharacterUpdateTimer = abandonedCharacterUpdateTimer + deltaTime
    if abandonedCharacterUpdateTimer >= abandonedCharacterUpdateInterval then
        abandonedCharacterUpdateTimer = 0
        updateAbandonedCharacters()
    end

    if not Game.RoundStarted or Traitormod.SelectedGamemode == nil then
        gamemodeThinkTimer = nil
        return
    end

    if not Traitormod.IsSecretEnding() then
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

    if Traitormod.IsSecretEnding() then return end

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

    if roundSkillGiveTimer and roundSkillGiveTimer > 0 and Timer.GetTime() > roundSkillGiveTimer then
        applyRoundSkillGain()
        roundSkillGiveTimer = Timer.GetTime() + (tonumber(Traitormod.Config.RoundSkillGain.Timer) or Traitormod.Config.ExperienceTimer)
    end
end)

-- when a character gains skill level, add PointsToBeGiven according to config
Traitormod.PointsToBeGiven = {}
Hook.HookMethod("Barotrauma.CharacterInfo", "IncreaseSkillLevel", function(instance, ptable)
    if Traitormod.IsSecretEnding() then return end
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

updateAbandonedCharacters = function()
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

    local accountKey = Traitormod.GetClientAccountKey(client)
    local abandonedCharacter = Traitormod.AbandonedCharacters[accountKey]
    if abandonedCharacter then
        if abandonedCharacter.Character and abandonedCharacter.Character.IsDead then
            -- client left while char was alive -> but char is dead
            Traitormod.Debug(string.format("%s connected, but his character died in the meantime...", Traitormod.ClientLogName(client)))
        end

        clearAbandonedCharacter(accountKey)
    end
end)

-- player disconnected from server
Hook.Add("clientDisconnected", "Traitormod.ClientDisconnected", function (client)
    if Traitormod.Config.RemotePoints then
        Traitormod.PublishRemoteData(client)
    end

    if Traitormod.Discord then
        Traitormod.Discord.AnnounceClientDisconnected(client)
    end

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


LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.Item"], "set_InventoryIconColor")

Traitormod.PointItems = {}

local function setupPointItem(item, amount, text, onUsed)
    text = text or ""

    Traitormod.PointItems[item] = {}
    Traitormod.PointItems[item].Amount = amount
    Traitormod.PointItems[item].OnUsed = onUsed

    local terminal = item.GetComponentString("Terminal")
    terminal.ShowMessage = text .. "\n" .. Traitormod.FormatText("PointItemTerminalText", amount)
    terminal.SyncHistory()

    item.set_InventoryIconColor(Color(0, 0, 255))
    item.SpriteColor = Color(0, 0, 255, 255)
    item.Scale = 0.5

    local color = item.SerializableProperties[Identifier("SpriteColor")]
    Networking.CreateEntityEvent(item, Item.ChangePropertyEventData(color, item))

    local scale = item.SerializableProperties[Identifier("Scale")]
    Networking.CreateEntityEvent(item, Item.ChangePropertyEventData(scale, item))

    local invColor = item.SerializableProperties[Identifier("InventoryIconColor")]
    Networking.CreateEntityEvent(item, Item.ChangePropertyEventData(invColor, item))
end

Traitormod.SpawnPointItem = function(inventory, amount, text, onSpawn, onUsed)
    local prefab = ItemPrefab.GetItemPrefab("handheldterminal")
    if prefab == nil then return false end

    Entity.Spawner.AddItemToSpawnQueue(prefab, inventory, nil, nil, function(item)
        setupPointItem(item, amount, text, onUsed)
        if onSpawn then
            onSpawn(item)
        end
    end)

    return true
end

Traitormod.DropPointItem = function(client, amount)
    if Traitormod.IsSecretEnding() or client == nil or client.Character == nil or client.Character.IsDead then
        return false
    end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    local currentPoints = math.floor(tonumber(Traitormod.GetData(client, "Points") or 0) or 0)
    if currentPoints < amount then return false end

    local prefab = ItemPrefab.GetItemPrefab("handheldterminal")
    if prefab == nil then return false end

    local character = client.Character
    local position = character.WorldPosition

    local ok = pcall(function()
        Entity.Spawner.AddItemToSpawnQueue(prefab, position, nil, nil, function(item)
            local latestPoints = math.floor(tonumber(Traitormod.GetData(client, "Points") or 0) or 0)
            if latestPoints < amount then
                pcall(function() item.Remove() end)
                return
            end

            setupPointItem(item, amount, "", nil)
            Traitormod.SetData(client, "Points", latestPoints - amount)
            Traitormod.SendMessage(client, Traitormod.FormatText("CMDDropPointsDropped", amount))
        end)
    end)

    return ok
end

Hook.Patch("Barotrauma.Items.Components.Terminal", "ServerEventRead", function(instance, ptable)
    local msg = ptable["msg"]
    local client = ptable["c"]

    local rewindBit = msg.BitPosition
    local output = msg.ReadString()
    msg.BitPosition = rewindBit -- this is so the game can still read the net message, as you cant read the same bit twice

    local item = instance.Item

    Hook.Call("traitormod.terminalWrite", item, client, output)
end, Hook.HookMethodType.Before)


Hook.Add("traitormod.terminalWrite", "Traitormod.PointItem", function (item, client, output)
    if string.lower(tostring(output or "")) ~= Traitormod.GetText("PointItemClaimCommand") then return end

    local data = Traitormod.PointItems[item]

    if data == nil then return end

    Traitormod.AwardPoints(client, data.Amount)
    Traitormod.SendMessage(client, Traitormod.FormatText("ReceivedPoints", data.Amount), "InfoFrameTabButton.Mission")

    if data.OnUsed then
        data.OnUsed(client)
    end

    local terminal = item.GetComponentString("Terminal")
    terminal.ShowMessage = Traitormod.FormatText("PointItemClaimedBy", client.Name)
    terminal.SyncHistory()

    Traitormod.PointItems[item] = nil
end)

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

Traitormod.Stats = dofile(Traitormod.Path .. "/Lua/statistics.lua")
dofile(Traitormod.Path .. "/Lua/features/respawnshuttle.lua")
dofile(Traitormod.Path .. "/Lua/features/welcome.lua")
dofile(Traitormod.Path .. "/Lua/features/deathlogbook.lua")
dofile(Traitormod.Path .. "/Lua/features/killfeed.lua")
dofile(Traitormod.Path .. "/Lua/features/serverlogs.lua")
dofile(Traitormod.Path .. "/Lua/features/piratemissionghostroles.lua")

Traitormod.AddGamemode(dofile(Traitormod.Path .. "/Lua/gamemodes/gamemode.lua"))
Traitormod.AddGamemode(dofile(Traitormod.Path .. "/Lua/gamemodes/secret.lua"))
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