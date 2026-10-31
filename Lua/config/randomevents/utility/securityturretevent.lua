---@class SecurityTurretEventConfig
---@field Name string
---@field Turret string
---@field Slot string

---@param config SecurityTurretEventConfig
---@return table
local function CreateSecurityTurretEvent(config)
    local event = {}

    event.Name = config.Name
    event.MinRoundTime = 1
    event.MinIntensity = 0
    event.MaxIntensity = 1
    event.ChancePerMinute = 0.01
    event.OnlyOncePerRound = true

    local function hasValidSecurity()
        for _, character in pairs(Character.CharacterList) do
            if character ~= nil
                and character.IsHuman
                and not character.IsDead
                and character.TeamID == CharacterTeamType.Team1
                and character.HasJob("securityofficer")
                and not Traitormod.RoleManager.IsAntagonist(character) then
                return true
            end
        end

        return false
    end

    local function getFreeHardpoints()
        if Submarine.MainSub == nil then
            return {}
        end

        local hardpoints = {}
        for _, item in pairs(Submarine.MainSub.GetItems(true)) do
            if item ~= nil
                and item.Prefab ~= nil
                and item.Prefab.Identifier ~= nil
                and string.lower(item.Prefab.Identifier.Value) == config.Slot then
                table.insert(hardpoints, item)
            end
        end

        return hardpoints
    end

    local function installTurret()
        local hardpoints = getFreeHardpoints()
        if #hardpoints == 0 then
            return false
        end

        local prefab = ItemPrefab.GetItemPrefab(config.Turret)
        if prefab == nil then
            return false
        end

        local hardpoint = hardpoints[math.random(#hardpoints)]
        local success, result = pcall(function()
            hardpoint.ReplaceWithLinkedItems(prefab)
        end)
        if not success then
            Traitormod.Error("Failed to install turret " .. tostring(config.Turret) .. ": " .. tostring(result))
            return false
        end

        local turretName = prefab.Name and prefab.Name.Value or config.Turret
        Traitormod.RoundEvents.SendEventMessage(
            string.format(Traitormod.Language.SecurityTurretInstalled, turretName),
            "GameModeIcon.sandbox",
            Color.Yellow
        )
        return true
    end

    event.CanStart = function()
        return hasValidSecurity() and #getFreeHardpoints() > 0
    end

    event.Start = function()
        installTurret()
        event.End()
    end

    event.End = function()
    end

    return event
end

return CreateSecurityTurretEvent
