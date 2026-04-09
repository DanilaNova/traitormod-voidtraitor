local event = {}

event.Name = "OxygenParalyzant"
event.MinRoundTime = 10
event.MinIntensity = 0
event.MaxIntensity = 1
event.ChancePerMinute = 0.0005
event.OnlyOncePerRound = true

local DELAY_MS = 20000
local DURATION_MS = 30000

local function getItemIdentifier(item)
    if item == nil or item.Prefab == nil or item.Prefab.Identifier == nil then
        return nil
    end

    return string.lower(item.Prefab.Identifier.Value)
end

local function applyAffliction(character, afflictionIdentifier, amount)
    if character == nil or character.CharacterHealth == nil or character.AnimController == nil then
        return
    end

    local prefab = AfflictionPrefab.Prefabs[afflictionIdentifier]
    if prefab == nil then
        return
    end

    character.CharacterHealth.ApplyAffliction(character.AnimController.MainLimb, prefab.Instantiate(amount))
end

local function canBreatheMainSubOxygen(character)
    if character == nil or not character.IsHuman or character.IsDead then
        return false
    end

    if character.Submarine ~= Submarine.MainSub or character.IsProtectedFromPressure then
        return false
    end

    local headGear = character.Inventory and character.Inventory.GetItemInLimbSlot(InvSlotType.Head)
    if headGear ~= nil then
        local identifier = getItemIdentifier(headGear)
        if identifier == "divingmask" or identifier == "clowndivingmask" then
            return false
        end
    end

    return true
end

event.Start = function()
    event.Token = (event.Token or 0) + 1
    local token = event.Token

    Traitormod.RoundEvents.SendEventMessage(Traitormod.Language.OxygenParalyzant, "GameModeIcon.PVP", Color.Red)

    Timer.Wait(function()
        if event.Token ~= token then
            return
        end

        for _, character in pairs(Character.CharacterList) do
            if canBreatheMainSubOxygen(character) then
                applyAffliction(character, "paralysis", 20)
            end
        end
    end, DELAY_MS)

    Timer.Wait(function()
        if event.Token ~= token then
            return
        end

        event.End(false)
    end, DURATION_MS)
end

event.End = function(isEndRound)
    event.Token = (event.Token or 0) + 1

    if not isEndRound then
        Traitormod.RoundEvents.SendEventMessage(Traitormod.Language.OxygenSafe, "GameModeIcon.MultiplayerCampaign")
    end
end

return event
