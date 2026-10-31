local NET_KILLFEED = "VoidTraitor_KillFeed"
local DISPLAY_DELAY_MS = 100

local pendingDamageCalls = {}
local damageHistory = {}

local function isEnabledMode()
    if not Game.RoundStarted or Traitormod.SelectedGamemode == nil then return false end

    local name = Traitormod.SelectedGamemode.Name
    return name == "PvP" or name == "AttackDefendV2"
end

local function getJobIdentifier(character)
    if character == nil or character.Info == nil or character.Info.Job == nil or character.Info.Job.Prefab == nil then
        return ""
    end
    return tostring(character.Info.Job.Prefab.Identifier)
end

local function writeCharacter(message, character)
    message.WriteString(character ~= nil and character.DisplayName or "")
    message.WriteString(character ~= nil and tostring(character.TeamID) or "")
    message.WriteString(getJobIdentifier(character))
end

local function resolveWeaponFromSource(source, attacker)
    if source == nil or attacker == nil or not LuaUserData.IsTargetType(source, "Barotrauma.Item") then return "" end

    local projectile = source.GetComponentString("Projectile")
    if projectile ~= nil then
        local weapon = projectile.Launcher
        return weapon ~= nil and weapon.Prefab ~= nil and tostring(weapon.Prefab.Identifier) or ""
    end

    if source.Equipper == attacker or (source.ParentInventory ~= nil and source.ParentInventory.Owner == attacker) then
        return source.Prefab ~= nil and tostring(source.Prefab.Identifier) or ""
    end

    return ""
end

local function rememberDamage(victim, attacker, weaponIdentifier, afflictions, causesBloodloss)
    if victim == nil or attacker == nil then return end

    local victimHistory = damageHistory[victim]
    if victimHistory == nil then
        victimHistory = {}
        damageHistory[victim] = victimHistory
    end

    local attackerHistory = victimHistory[attacker]
    if attackerHistory == nil then
        attackerHistory = { ByAffliction = {} }
        victimHistory[attacker] = attackerHistory
    end

    local event = {
        WeaponIdentifier = weaponIdentifier,
    }

    attackerHistory.Last = event
    if weaponIdentifier ~= "" then
        attackerHistory.LastWeapon = event
    end

    for identifier in pairs(afflictions) do
        attackerHistory.ByAffliction[identifier] = event
    end

    if causesBloodloss then
        attackerHistory.Bloodloss = event
    end
end

local function resolveTrackedWeapon(victim, causeOfDeath)
    local killer = causeOfDeath ~= nil and causeOfDeath.Killer or nil
    if killer == nil then return "" end

    local direct = resolveWeaponFromSource(causeOfDeath.DamageSource, killer)
    local victimHistory = damageHistory[victim]
    local history = victimHistory ~= nil and victimHistory[killer] or nil
    if history == nil then return direct end

    local causeIdentifier = causeOfDeath.Affliction ~= nil and tostring(causeOfDeath.Affliction.Identifier) or ""
    if causeIdentifier ~= "" then
        local exact = history.ByAffliction[causeIdentifier]
        if exact ~= nil then
            return exact.WeaponIdentifier
        end

        if causeIdentifier == "bloodloss" and history.Bloodloss ~= nil then
            return history.Bloodloss.WeaponIdentifier
        end
    end

    if history.Last ~= history.LastWeapon and history.Last ~= nil and history.Last.WeaponIdentifier == "" then return "" end
    if history.LastWeapon ~= nil then return history.LastWeapon.WeaponIdentifier end
    return direct
end

local function sendKillFeed(victim, causeOfDeath)
    local message = Networking.Start(NET_KILLFEED)
    local killer = causeOfDeath.Killer

    message.WriteBoolean(killer ~= nil)
    if killer ~= nil then
        writeCharacter(message, killer)
    end

    writeCharacter(message, victim)
    message.WriteString(resolveTrackedWeapon(victim, causeOfDeath))
    message.WriteString(causeOfDeath.Affliction ~= nil and tostring(causeOfDeath.Affliction.Identifier) or "")

    for _, client in pairs(Client.ClientList) do
        if client.Connection ~= nil then
            Networking.Send(message, client.Connection)
        end
    end
end

Hook.Patch("Traitormod.KillFeed.DamageLimb.Before", "Barotrauma.Character", "DamageLimb", function(character, ptable)
    if not isEnabledMode() or character == nil or character.IsDead then return end

    local stack = pendingDamageCalls[character]
    if stack == nil then
        stack = {}
        pendingDamageCalls[character] = stack
    end

    table.insert(stack, {
        Attacker = ptable["attacker"],
        Source = character.LastDamageSource,
    })
end, Hook.HookMethodType.Before)

Hook.Patch("Traitormod.KillFeed.DamageLimb.After", "Barotrauma.Character", "DamageLimb", function(character, ptable)
    local stack = pendingDamageCalls[character]
    if stack == nil then return end

    local context = table.remove(stack)
    if #stack == 0 then
        pendingDamageCalls[character] = nil
    end
    if context == nil then return end

    local attackResult = ptable.OriginalReturnValue or ptable.ReturnValue
    if attackResult == nil then return end

    local byAttacker = {}
    if attackResult.Afflictions ~= nil then
        for affliction in attackResult.Afflictions do
            local prefab = affliction.Prefab
            if prefab ~= nil and not prefab.IsBuff and (tonumber(affliction.Strength) or 0) > 0 then
                local attacker = affliction.Source or context.Attacker
                if attacker ~= nil then
                    local entry = byAttacker[attacker]
                    if entry == nil then
                        entry = { Afflictions = {}, CausesBloodloss = false }
                        byAttacker[attacker] = entry
                    end

                    entry.Afflictions[tostring(prefab.Identifier)] = true
                    if tostring(prefab.AfflictionType) == "bleeding" then
                        entry.CausesBloodloss = true
                    end
                end
            end
        end
    end

    if next(byAttacker) == nil and (tonumber(attackResult.Damage) or 0) > 0 and context.Attacker ~= nil then
        byAttacker[context.Attacker] = { Afflictions = {}, CausesBloodloss = false }
    end

    for attacker, entry in pairs(byAttacker) do
        rememberDamage(
            character,
            attacker,
            resolveWeaponFromSource(context.Source, attacker),
            entry.Afflictions,
            entry.CausesBloodloss
        )
    end
end, Hook.HookMethodType.After)

Hook.Add("character.death", "Traitormod.KillFeed.CharacterDeath", function(character)
    if not isEnabledMode() or character == nil then return end

    Timer.Wait(function()
        if not isEnabledMode() or character == nil then return end
        local causeOfDeath = character.CauseOfDeath
        if causeOfDeath == nil then return end
        sendKillFeed(character, causeOfDeath)
        damageHistory[character] = nil
        pendingDamageCalls[character] = nil
    end, DISPLAY_DELAY_MS)
end)

Hook.Add("roundStart", "Traitormod.KillFeed.RoundStart", function()
    pendingDamageCalls = {}
    damageHistory = {}
end)

Hook.Add("roundEnd", "Traitormod.KillFeed.RoundEnd", function()
    pendingDamageCalls = {}
    damageHistory = {}
end)
