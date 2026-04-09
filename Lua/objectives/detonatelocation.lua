local objective = Traitormod.RoleManager.Objectives.Objective:new()

objective.Name = "DetonateLocation"
objective.AmountPoints = 1200
objective.AmountPointsWithVictim = 1800
objective.RequireVictimChance = 0.5
objective.MaxVictimDistance = 500
objective.DetonatorIdentifiers = {"detonator", "timeddetonator", "artmod_detonator"}
objective.OwnershipDuration = 600
objective.InteractionOwnershipDuration = 15
objective.MaxOwnershipChainDepth = 8

local locationDefinitions = {
    bridge = {
        LabelKey = "ObjectiveDetonateLocationBridge",
        Keywords = {"commandroom", "bridge", "control", "captain", "navigation", "nav"},
    },
    medbay = {
        LabelKey = "ObjectiveDetonateLocationMedbay",
        Keywords = {"medbay", "medical", "surgical", "medic", "clinic", "med"},
    },
    shield = {
        LabelKey = "ObjectiveDetonateLocationShield",
        Keywords = {"shield", "electrical", "junction", "junctioncompartment", "power"},
    },
}

local function normalize(value)
    if value == nil then return "" end

    if type(value) == "string" then
        return string.lower(value)
    end

    local success, result = pcall(function()
        if value.Value ~= nil then
            return tostring(value.Value)
        end

        return tostring(value)
    end)

    if not success or result == nil then return "" end

    return string.lower(result)
end

local function buildLookup(values)
    local lookup = {}
    for _, value in pairs(values or {}) do
        local normalized = normalize(value)
        if normalized ~= "" then
            lookup[normalized] = true
        end
    end
    return lookup
end

local function isItem(userData)
    return userData ~= nil and LuaUserData.IsTargetType(userData, "Barotrauma.Item")
end

local function isCharacter(userData)
    return userData ~= nil and LuaUserData.IsTargetType(userData, "Barotrauma.Character")
end

local function getItemIdentifier(item)
    if item == nil or item.Prefab == nil then return "" end
    return normalize(item.Prefab.Identifier)
end

local function isExplosiveItem(item)
    return item ~= nil and item.HasTag ~= nil and item.HasTag("explosive")
end

local function isDetonatorItem(item)
    if item == nil then return false end
    return objective.DetonatorIdentifierLookup[getItemIdentifier(item)] == true
end

local function getSourceItem(damageSource)
    if damageSource == nil then return nil end
    if isItem(damageSource) then return damageSource end

    local success, item = pcall(function()
        return damageSource.Item
    end)

    if success and isItem(item) then
        return item
    end

    return nil
end

local function getParentOwnerItem(item)
    if item == nil then return nil end

    local parentInventory = item.ParentInventory
    if parentInventory == nil or parentInventory.Owner == nil then return nil end
    if not isItem(parentInventory.Owner) then return nil end

    return parentInventory.Owner
end

local function markItemOwner(item, character, duration)
    if item == nil or not isCharacter(character) then return end

    objective.ItemOwners[item] = {
        Character = character,
        ExpiresAt = Timer.GetTime() + (duration or objective.OwnershipDuration),
    }
end

local function getMarkedOwner(item)
    local marker = objective.ItemOwners[item]
    if marker == nil then return nil end
    if marker.Character == nil or marker.Character.Removed then
        objective.ItemOwners[item] = nil
        return nil
    end
    if marker.ExpiresAt ~= nil and Timer.GetTime() > marker.ExpiresAt then
        objective.ItemOwners[item] = nil
        return nil
    end

    return marker.Character
end

local function markInteraction(item, character)
    if item == nil or not isCharacter(character) then return end

    objective.LastInteractors[item] = {
        Character = character,
        ExpiresAt = Timer.GetTime() + objective.InteractionOwnershipDuration,
    }
end

local function getRecentInteractor(item)
    local marker = objective.LastInteractors[item]
    if marker == nil then return nil end
    if marker.Character == nil or marker.Character.Removed then
        objective.LastInteractors[item] = nil
        return nil
    end
    if marker.ExpiresAt ~= nil and Timer.GetTime() > marker.ExpiresAt then
        objective.LastInteractors[item] = nil
        return nil
    end

    return marker.Character
end

local function markDetonatorAndContainedExplosives(item, character, duration)
    if item == nil or not isCharacter(character) then return end

    markInteraction(item, character)
    markItemOwner(item, character, duration)

    if item.OwnInventory == nil then return end

    for containedItem in item.OwnInventory.AllItems do
        if containedItem ~= nil and isExplosiveItem(containedItem) then
            markItemOwner(containedItem, character, duration)
        end
    end
end

local function findDetonatorInChain(item)
    local current = item
    local depth = 0

    while current ~= nil and depth < objective.MaxOwnershipChainDepth do
        if isDetonatorItem(current) then
            return current
        end

        current = getParentOwnerItem(current)
        depth = depth + 1
    end

    return nil
end

local function findResponsibleCharacter(item)
    local current = item
    local depth = 0

    while current ~= nil and depth < objective.MaxOwnershipChainDepth do
        local character = getMarkedOwner(current)
        if character ~= nil then
            return character
        end

        current = getParentOwnerItem(current)
        depth = depth + 1
    end

    return nil
end

local function getHullLocationId(hull)
    if hull == nil then return nil end

    local roomName = normalize(hull.RoomName)
    if roomName == "" then return nil end

    for locationId, definition in pairs(locationDefinitions) do
        for _, keyword in pairs(definition.Keywords) do
            if string.find(roomName, keyword, 1, true) ~= nil then
                return locationId
            end
        end
    end

    return nil
end

local function getLocationLabel(locationId)
    local definition = locationDefinitions[locationId]
    if definition == nil then return locationId end

    local label = Traitormod.Language[definition.LabelKey]
    if label ~= nil and label ~= "" then return label end

    return locationId
end

local function getAvailableLocations()
    local available = {}
    local mainSub = Submarine.MainSub
    if mainSub == nil then return available end

    for _, hull in pairs(mainSub.GetHulls(true)) do
        local locationId = getHullLocationId(hull)
        if locationId ~= nil then
            available[locationId] = true
        end
    end

    return available
end

local function captureVictimStates(worldPosition)
    local states = {}
    if worldPosition == nil then return states end

    for _, character in pairs(Character.CharacterList) do
        if not character.Removed and Vector2.Distance(character.WorldPosition, worldPosition) <= objective.MaxVictimDistance then
            states[character] = {
                WasDead = character.IsDead,
                WasIncapacitated = character.IsIncapacitated,
            }
        end
    end

    return states
end

local function isVictimDownByExplosion(context, target)
    if context == nil or target == nil or target.Removed then return false end

    local before = context.TargetState
    if before == nil then return false end
    if before.WasDead or before.WasIncapacitated then return false end

    if Vector2.Distance(target.WorldPosition, context.WorldPosition) > objective.MaxVictimDistance then
        return false
    end

    return target.IsDead or target.IsIncapacitated
end

objective.PendingExplosions = {}

objective.Static = function ()
    objective.DetonatorIdentifierLookup = buildLookup(objective.DetonatorIdentifiers)
    objective.ItemOwners = setmetatable({}, { __mode = "k" })
    objective.LastInteractors = setmetatable({}, { __mode = "k" })

    Hook.Add("item.interact", "Traitormod.Objective.DetonateLocation.ItemInteract", function(item, character)
        if item == nil or not isCharacter(character) then return end

        if isDetonatorItem(item) then
            markDetonatorAndContainedExplosives(item, character)
            return
        end

        if isExplosiveItem(item) then
            local ownerItem = getParentOwnerItem(item)
            if ownerItem ~= nil and isDetonatorItem(ownerItem) then
                markItemOwner(item, character)
                markDetonatorAndContainedExplosives(ownerItem, character)
            end
        end
    end)

    Hook.Add("item.use", "Traitormod.Objective.DetonateLocation.ItemUse", function(item, character)
        if item == nil or not isCharacter(character) then return end

        if isDetonatorItem(item) then
            markDetonatorAndContainedExplosives(item, character)
        end
    end)

    Hook.Add("inventoryPutItem", "Traitormod.Objective.DetonateLocation.InventoryPutItem", function(inventory, item, characterUser)
        if inventory == nil or item == nil or not isCharacter(characterUser) then return end
        if not isExplosiveItem(item) then return end

        local owner = inventory.Owner
        if owner == nil or not isItem(owner) or not isDetonatorItem(owner) then return end

        markItemOwner(item, characterUser)
        markDetonatorAndContainedExplosives(owner, characterUser)
    end)

    Hook.Add("inventoryItemSwap", "Traitormod.Objective.DetonateLocation.InventoryItemSwap", function(inventory, item, characterUser)
        if inventory == nil or item == nil or not isCharacter(characterUser) then return end
        if not isExplosiveItem(item) then return end

        local owner = inventory.Owner
        if owner == nil or not isItem(owner) or not isDetonatorItem(owner) then return end

        markItemOwner(item, characterUser)
        markDetonatorAndContainedExplosives(owner, characterUser)
    end)

    local function handleDetonatorStatusEffect(item)
        if item == nil or not isDetonatorItem(item) then return end

        local interactor = getRecentInteractor(item)
        if interactor ~= nil then
            markDetonatorAndContainedExplosives(item, interactor)
        end
    end

    Hook.Add("statusEffect.apply.detonator", "Traitormod.Objective.DetonateLocation.StatusEffectDetonator", function(_, _, item)
        handleDetonatorStatusEffect(item)
    end)

    Hook.Add("statusEffect.apply.timeddetonator", "Traitormod.Objective.DetonateLocation.StatusEffectTimedDetonator", function(_, _, item)
        handleDetonatorStatusEffect(item)
    end)

    Hook.Patch(
        "Traitormod.Objective.DetonateLocation.BeforeExplode",
        "Barotrauma.Explosion",
        "Explode",
        {"Microsoft.Xna.Framework.Vector2", "Barotrauma.Entity", "Barotrauma.Character"},
        function (_, ptable)
            local worldPosition = ptable["worldPosition"]
            local context = {
                WorldPosition = worldPosition,
                DamageSource = ptable["damageSource"],
                Hull = worldPosition ~= nil and Hull.FindHull(worldPosition) or nil,
                NearbyStates = captureVictimStates(worldPosition),
            }

            table.insert(objective.PendingExplosions, context)
            Traitormod.RoleManager.CallObjectiveFunction("ExplosionBegin", context)
        end,
        Hook.HookMethodType.Before
    )

    Hook.Patch(
        "Traitormod.Objective.DetonateLocation.AfterExplode",
        "Barotrauma.Explosion",
        "Explode",
        {"Microsoft.Xna.Framework.Vector2", "Barotrauma.Entity", "Barotrauma.Character"},
        function (_, _)
            local context = table.remove(objective.PendingExplosions)
            if context == nil then return end

            Traitormod.RoleManager.CallObjectiveFunction("ExplosionEnd", context)
        end,
        Hook.HookMethodType.After
    )
end

function objective:Start(target)
    local availableLocations = getAvailableLocations()
    local locationPool = {}

    for locationId, _ in pairs(availableLocations) do
        table.insert(locationPool, locationId)
    end

    if #locationPool == 0 then return false end

    self.LocationId = locationPool[math.random(1, #locationPool)]
    self.RequireVictim = math.random() < self.RequireVictimChance
    self.Target = nil
    self.Completed = false
    self.ActiveExplosionContexts = {}

    if self.RequireVictim then
        if target == nil then return false end
        self.Target = target
        self.AmountPoints = self.AmountPointsWithVictim
        self.Text = string.format(
            Traitormod.Language.ObjectiveDetonateLocationWithVictim,
            getLocationLabel(self.LocationId),
            self.Target.Name
        )
    else
        self.AmountPoints = self.AmountPoints or 1200
        self.Text = string.format(
            Traitormod.Language.ObjectiveDetonateLocation,
            getLocationLabel(self.LocationId)
        )
    end

    return true
end

function objective:ExplosionBegin(context)
    if self.Completed then return end
    if context == nil then return end

    local sourceItem = getSourceItem(context.DamageSource)
    if sourceItem == nil then return end

    context.SourceItem = sourceItem
    context.DetonatorItem = findDetonatorInChain(sourceItem)
    if context.DetonatorItem == nil then return end

    context.ResponsibleCharacter = findResponsibleCharacter(sourceItem)
    if context.ResponsibleCharacter ~= self.Character then return end

    if context.Hull == nil or context.Hull.Submarine ~= Submarine.MainSub then return end

    context.LocationId = getHullLocationId(context.Hull)
    if context.LocationId == nil or context.LocationId ~= self.LocationId then return end

    if self.RequireVictim then
        context.TargetState = context.NearbyStates[self.Target]
        if context.TargetState == nil then return end
    end

    self.ActiveExplosionContexts[context] = true
end

function objective:ExplosionEnd(context)
    if self.Completed then return end
    if context == nil or self.ActiveExplosionContexts == nil or self.ActiveExplosionContexts[context] ~= true then return end

    self.ActiveExplosionContexts[context] = nil

    if self.RequireVictim then
        if isVictimDownByExplosion(context, self.Target) then
            self.Completed = true
        end
        return
    end

    self.Completed = true
end

function objective:IsCompleted()
    return self.Completed == true
end

function objective:IsFailed()
    if self.RequireVictim and self.Target ~= nil then
        return self.Target.IsDead
    end

    return false
end

return objective
