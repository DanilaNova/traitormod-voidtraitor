local abilities = {}

local supportedAbilityJobs = {
    captain = true,
    securityofficer = true,
    mechanic = true,
    engineer = true,
    medicaldoctor = true,
    surgeon = true,
}
local mechanicalIdentifiers = {
    smallpump = true,
    pump = true,
    oxygenerator = true,
    shuttleoxygenerator = true,
    outpostoxygenerator = true,
    deconstructor = true,
    fabricator = true,
    engine = true,
    largeengine = true,
    shuttleengine = true,
    coilgunloader = true,
    pulselaserloader = true,
    depthchargeloader = true,
    railgunloader = true,
    chaingunloader = true,
    flakcannonloader = true,
}
local electricalIdentifiers = {
    junctionbox = true,
    statusmonitor = true,
    sonarmonitor = true,
    shuttlenavterminal = true,
    navterminal = true,
    battery = true,
    shuttlebattery = true,
    supercapacitor = true,
    reactor1 = true,
    outpostreactor = true,
}

local function isValidHumanCharacter(character)
    return character ~= nil and character.IsHuman and not character.IsDead
end

local function getItemIdentifier(item)
    if item == nil or item.Prefab == nil or item.Prefab.Identifier == nil then
        return nil
    end

    return string.lower(item.Prefab.Identifier.Value)
end

local function syncItemCondition(item)
    local property = item.SerializableProperties[Identifier("Condition")]
    if property ~= nil then
        Networking.CreateEntityEvent(item, Item.ChangePropertyEventData(property, item))
    end
end

local function applyAffliction(character, afflictionIdentifier, amount)
    if character == nil or character.CharacterHealth == nil or character.AnimController == nil then
        return false
    end

    local prefab = AfflictionPrefab.Prefabs[afflictionIdentifier]
    if prefab == nil then
        return false
    end

    character.CharacterHealth.ApplyAffliction(character.AnimController.MainLimb, prefab.Instantiate(amount))
    return true
end

function abilities.IsEligibleCharacter(character)
    if not isValidHumanCharacter(character) then
        return false
    end

    if character.TeamID ~= CharacterTeamType.Team1 then
        return false
    end

    if character.Info == nil or character.Info.Job == nil or character.Info.Job.Prefab == nil then
        return false
    end

    if not supportedAbilityJobs[string.lower(tostring(character.Info.Job.Prefab.Identifier))] then
        return false
    end

    return not Traitormod.RoleManager.IsAntagonist(character)
end

local function repairItems(identifierLookup, percent, message)
    if Submarine.MainSub == nil then
        return false
    end

    local repaired = 0

    for _, item in pairs(Submarine.MainSub.GetItems(true)) do
        local identifier = getItemIdentifier(item)
        if identifier ~= nil and identifierLookup[identifier] then
            local newCondition = math.min(item.MaxCondition, item.Condition + item.MaxCondition * percent)
            if newCondition > item.Condition then
                item.Condition = newCondition
                syncItemCondition(item)
                repaired = repaired + 1
            end
        end
    end

    if repaired > 0 then
        Traitormod.RoundEvents.SendEventMessage(message, "GameModeIcon.sandbox", Color.Yellow)
    end

    return repaired > 0
end

function abilities.RepairMechanicalDevices(percent)
    return repairItems(mechanicalIdentifiers, percent, Traitormod.Language.MechanicMechanicalRepair)
end

function abilities.RepairElectricalDevices(percent)
    return repairItems(electricalIdentifiers, percent, Traitormod.Language.EngineerElectricalRepair)
end

function abilities.RepairHull(percent)
    if Submarine.MainSub == nil then
        return false
    end

    local repaired = 0

    for _, wall in pairs(Structure.WallList) do
        if wall.Submarine == Submarine.MainSub then
            for i = 0, wall.SectionCount, 1 do
                wall.AddDamage(i, -(wall.MaxHealth * percent))
            end
            repaired = repaired + 1
        end
    end

    if repaired > 0 then
        Traitormod.RoundEvents.SendEventMessage(Traitormod.Language.MechanicHullRepair, "GameModeIcon.sandbox", Color.Yellow)
    end

    return repaired > 0
end

local function getFreeTurretHardpoints(slotIdentifier)
    if Submarine.MainSub == nil then
        return {}
    end

    local hardpoints = {}

    for _, item in pairs(Submarine.MainSub.GetItems(true)) do
        if getItemIdentifier(item) == slotIdentifier then
            table.insert(hardpoints, item)
        end
    end

    return hardpoints
end

function abilities.CanInstallTurret(slotIdentifier)
    if slotIdentifier == nil then
        return false
    end

    return #getFreeTurretHardpoints(slotIdentifier) > 0
end

function abilities.InstallTurret(turretIdentifier, slotIdentifier)
    local hardpoints = getFreeTurretHardpoints(slotIdentifier)
    if #hardpoints == 0 then
        return false, Traitormod.Language.AbilityNoTurretSlots
    end

    local prefab = ItemPrefab.GetItemPrefab(turretIdentifier)
    if prefab == nil then
        Traitormod.Error("Turret prefab not found: " .. tostring(turretIdentifier))
        return false, Traitormod.Language.PointshopCannotBeUsed
    end

    local hardpoint = hardpoints[math.random(#hardpoints)]
    local success, result = pcall(function()
        hardpoint.ReplaceWithLinkedItems(prefab)
    end)
    if not success then
        Traitormod.Error("Failed to install turret " .. tostring(turretIdentifier) .. ": " .. tostring(result))
        return false, Traitormod.Language.PointshopCannotBeUsed
    end

    local turretName = prefab.Name and prefab.Name.Value or turretIdentifier
    Traitormod.RoundEvents.SendEventMessage(string.format(Traitormod.Language.SecurityTurretInstalled, turretName), "GameModeIcon.sandbox", Color.Yellow)
    return true
end

function abilities.CanBuyTurretAbility(_, slotIdentifier)
    if not abilities.CanInstallTurret(slotIdentifier) then
        return false, Traitormod.Language.AbilityNoTurretSlots
    end

    return true
end

function abilities.ApplySkillBuff(character, skillMap, durationSeconds, message)
    if not Traitormod.ApplyTemporarySkillBuff(character, skillMap, durationSeconds) then
        return false
    end

    Traitormod.SendMessageCharacter(character, message, "InfoFrameTabButton.Mission")
    return true
end

function abilities.ApplyAfflictions(character, afflictionMap, message)
    if not isValidHumanCharacter(character) then
        return false
    end

    local applied = false
    for afflictionIdentifier, amount in pairs(afflictionMap or {}) do
        if applyAffliction(character, afflictionIdentifier, amount) then
            applied = true
        end
    end

    if not applied then
        return false
    end

    Traitormod.SendMessageCharacter(character, message, "InfoFrameTabButton.Mission")
    return true
end

return abilities
