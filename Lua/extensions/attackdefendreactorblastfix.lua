local extension = {}

extension.Identifier = "attackdefendreactorblastfix"
extension.Enabled = true
extension.BlockedExplosives = {"fraggrenade", "40mmgrenade"}
extension.ProtectedGamemodes = {"AttackDefendV2"}
extension.ReactorTag = "deathmatchteam1reactor"
extension.ProtectTaggedReactorsOnly = false
extension.Debug = false

local function toIdentifierString(value)
    if value == nil then return nil end

    if type(value) == "string" then
        return string.lower(value)
    end

    local success, result = pcall(function()
        if value.Value ~= nil then
            return tostring(value.Value)
        end
        return tostring(value)
    end)

    if not success or result == nil then return nil end
    return string.lower(result)
end

local function buildLookup(values)
    local lookup = {}
    if values == nil then return lookup end

    for _, value in pairs(values) do
        local normalized = toIdentifierString(value)
        if normalized ~= nil and normalized ~= "" then
            lookup[normalized] = true
        end
    end

    return lookup
end

local function getCurrentGamemodeName()
    if Traitormod == nil or Traitormod.SelectedGamemode == nil then return nil end
    return Traitormod.SelectedGamemode.Name
end

local function getDamageSourceIdentifier(damageSource)
    if damageSource == nil then return nil end

    local success, identifier = pcall(function()
        if damageSource.Prefab ~= nil and damageSource.Prefab.Identifier ~= nil then
            return damageSource.Prefab.Identifier
        end

        if damageSource.Item ~= nil and damageSource.Item.Prefab ~= nil and damageSource.Item.Prefab.Identifier ~= nil then
            return damageSource.Item.Prefab.Identifier
        end

        return nil
    end)

    if not success then return nil end
    return toIdentifierString(identifier)
end

function extension:IsProtectedRound()
    if self.Enabled == false then return false end

    local gamemodeName = getCurrentGamemodeName()
    if gamemodeName == nil then return false end

    return self.ProtectedGamemodeLookup[toIdentifierString(gamemodeName)] == true
end

function extension:IsBlockedExplosive(damageSource)
    local identifier = getDamageSourceIdentifier(damageSource)
    if identifier == nil then return false end
    return self.BlockedExplosiveLookup[identifier] == true
end

function extension:ShouldProtectReactor(item)
    if item == nil or item.Removed then return false end
    if item.GetComponentString == nil then return false end
    if item.GetComponentString("Reactor") == nil then return false end

    if self.ProtectTaggedReactorsOnly == true then
        return self.ReactorTag ~= nil and self.ReactorTag ~= "" and item.HasTag(self.ReactorTag)
    end

    if self.ReactorTag ~= nil and self.ReactorTag ~= "" and item.HasTag(self.ReactorTag) then
        return true
    end

    return true
end

function extension:CaptureReactors()
    local snapshot = {}

    for _, item in pairs(Item.ItemList) do
        if self:ShouldProtectReactor(item) then
            snapshot[item] = item.Condition
        end
    end

    return snapshot
end

function extension:RestoreReactors(snapshot)
    if snapshot == nil or snapshot == false then return end

    for item, condition in pairs(snapshot) do
        if item ~= nil and not item.Removed and item.Condition < condition then
            item.Condition = condition
        end
    end
end

function extension:DebugLog(message)
    if self.Debug == true and Traitormod ~= nil and Traitormod.Log ~= nil then
        Traitormod.Log("[AttackDefendReactorBlastFix] " .. tostring(message))
    end
end

extension.PendingSnapshots = {}

extension.Init = function ()
    extension.BlockedExplosiveLookup = buildLookup(extension.BlockedExplosives)
    extension.ProtectedGamemodeLookup = buildLookup(extension.ProtectedGamemodes)

    Hook.Patch(
        "Traitormod.AttackDefendReactorBlastFix.BeforeExplode",
        "Barotrauma.Explosion",
        "Explode",
        {"Microsoft.Xna.Framework.Vector2", "Barotrauma.Entity", "Barotrauma.Character"},
        function (_, ptable)
            local snapshot = false

            if extension:IsProtectedRound() and extension:IsBlockedExplosive(ptable["damageSource"]) then
                snapshot = extension:CaptureReactors()
                extension:DebugLog("Captured reactor state for blocked explosive: " .. tostring(getDamageSourceIdentifier(ptable["damageSource"])))
            end

            table.insert(extension.PendingSnapshots, snapshot)
        end,
        Hook.HookMethodType.Before
    )

    Hook.Patch(
        "Traitormod.AttackDefendReactorBlastFix.AfterExplode",
        "Barotrauma.Explosion",
        "Explode",
        {"Microsoft.Xna.Framework.Vector2", "Barotrauma.Entity", "Barotrauma.Character"},
        function (_, _)
            local snapshot = table.remove(extension.PendingSnapshots)
            if snapshot == nil or snapshot == false then return end

            extension:RestoreReactors(snapshot)
        end,
        Hook.HookMethodType.After
    )
end

return extension
