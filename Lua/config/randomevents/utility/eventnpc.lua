if Traitormod.EventNPC ~= nil then return Traitormod.EventNPC end

local npc = {}
local homeSubmarines = {}
local returnObjectives = {}
local idleBehavior = LuaUserData.CreateEnumTable("Barotrauma.AIObjectiveIdle+BehaviorType")
local idleDescriptor = LuaUserData.RegisterType("Barotrauma.AIObjectiveIdle")
LuaUserData.MakeFieldAccessible(idleDescriptor, "targetHulls")
LuaUserData.MakeFieldAccessible(idleDescriptor, "hullWeights")
LuaUserData.MakeFieldAccessible(LuaUserData.RegisterType("Barotrauma.HumanAIController"), "steeringManager")

local function getSpawnPoints(submarine)
    local waypoints = submarine.GetWaypoints(false)
    local threats = {}

    for _, character in pairs(Character.CharacterList) do
        if not character.IsHuman and not character.IsDead and not character.Removed then
            table.insert(threats, { Hull = character.CurrentHull or Hull.FindHull(character.WorldPosition), Position = character.WorldPosition, Radius = 300 })
        end
    end

    for _, waypoint in pairs(waypoints) do
        if bit32.band(waypoint.SpawnType, SpawnType.Enemy) ~= 0 then
            table.insert(threats, { Hull = waypoint.CurrentHull, Position = waypoint.WorldPosition, Radius = 300 })
        end
    end

    for _, item in pairs(submarine.GetItems(false)) do
        local spawner = item.GetComponentString("EntitySpawnerComponent")
        if spawner ~= nil and spawner.SpeciesName ~= nil and string.find(spawner.SpeciesName, "%S") ~= nil then
            local offset = spawner.SpawnAreaOffset
            table.insert(threats, {
                Hull = item.CurrentHull,
                Position = Vector2(item.WorldPosition.X + offset.X, item.WorldPosition.Y + offset.Y),
                Radius = math.max(spawner.SpawnAreaRadius, spawner.SpawnAreaBounds.X, spawner.SpawnAreaBounds.Y),
            })
        end
    end

    local points = {}
    for _, waypoint in pairs(waypoints) do
        local hull = waypoint.CurrentHull
        if hull ~= nil and hull.Submarine == submarine and not hull.AvoidStaying
            and not waypoint.IsObstructed and waypoint.Ladders == nil and waypoint.ConnectedDoor == nil then
            local danger = hull.FireCount
            local distance = math.huge
            for _, threat in ipairs(threats) do
                local threatDistance = Vector2.DistanceSquared(waypoint.WorldPosition, threat.Position)
                distance = math.min(distance, threatDistance)
                local linked = false
                for _, linkedHull in pairs(hull.linkedTo) do
                    if linkedHull == threat.Hull then linked = true; break end
                end
                if threat.Hull == hull or linked or threatDistance <= threat.Radius ^ 2 then
                    danger = danger + 1
                end
            end

            table.insert(points, { Waypoint = waypoint, Danger = danger, Water = hull.WaterPercentage, Distance = distance })
        end
    end
    return points
end

function npc.GetSpawnPoint(submarine)
    local points = getSpawnPoints(submarine)
    local safest = {}
    local bestDanger = math.huge
    local bestWater = math.huge
    local bestDistance = -1
    for _, point in ipairs(points) do
        if point.Danger < bestDanger or (point.Danger == bestDanger and point.Water < bestWater)
            or (point.Danger == bestDanger and point.Water == bestWater and point.Distance > bestDistance) then
            safest = {}
            bestDanger = point.Danger
            bestWater = point.Water
            bestDistance = point.Distance
        end
        if point.Danger == bestDanger and point.Water == bestWater and point.Distance == bestDistance then
            table.insert(safest, point.Waypoint)
        end
    end
    if #safest == 0 then return nil end
    return safest[math.random(#safest)]
end

function npc.Stay(character, submarine)
    homeSubmarines[character] = submarine
    for _, objective in pairs(character.AIController.ObjectiveManager.Objectives) do
        if objective.Identifier == "idle" then
            objective.Behavior = idleBehavior.Patrol
        end
    end
end

local function clearReturn(character)
    local state = returnObjectives[character]
    if state == nil then return end
    local manager = character.AIController.ObjectiveManager
    if manager.ForcedOrder == state.Objective then manager.SetForcedOrder(state.PreviousOrder) end
    returnObjectives[character] = nil
end

function npc.Release(character)
    if character ~= nil then
        homeSubmarines[character] = nil
        clearReturn(character)
    end
end

local function getHome(character)
    local home = homeSubmarines[character]
    if home ~= nil and not character.LockHands and character.SelectedBy == nil
        and Traitormod.FindClientCharacter(character) == nil then return home end
    return nil
end

local function distanceToSubmarine(character, submarine)
    local rect = submarine.Borders
    local x = character.WorldPosition.X - submarine.WorldPosition.X
    local y = character.WorldPosition.Y - submarine.WorldPosition.Y
    local dx = math.max(rect.X - x, 0, x - rect.X - rect.Width)
    local dy = math.max(rect.Y - rect.Height - y, 0, y - rect.Y)
    return dx * dx + dy * dy
end

-- NPCs away from home are sent back with a forced GoTo order, which also paths from outside.
Hook.Patch("Barotrauma.AIObjectiveManager", "UpdateObjectives", function(instance, ptable)
    local character = instance.HumanAIController.Character
    local home = getHome(character)
    if home == nil or (character.CurrentHull ~= nil and character.Submarine == home) then
        clearReturn(character)
        return
    end

    -- don't interrupt combat, it uses the same steering
    if instance.CurrentObjective ~= nil and instance.CurrentObjective.Identifier == "combat" then return end

    -- more than 50 m from home: go to the nearest allowed submarine instead
    if distanceToSubmarine(character, home) > 5000 ^ 2 then
        local nearest, distance = home, distanceToSubmarine(character, home)
        for _, submarine in pairs(Submarine.Loaded) do
            if submarine == Submarine.MainSub or submarine == Level.Loaded.BeaconStation or submarine.Info.IsWreck then
                local d = distanceToSubmarine(character, submarine)
                if d < distance then nearest = submarine; distance = d end
            end
        end
        if nearest ~= home then
            clearReturn(character)
            home = nearest
            homeSubmarines[character] = home
        end
    end

    local state = returnObjectives[character]
    if state == nil or (state.Objective.IsCompleted or not state.Objective.CanBeCompleted or state.Exterior)
        and Timer.GetTime() >= state.RetryAt then
        clearReturn(character)
        local target, path, distance
        local entrance, entranceDistance
        local steering = character.AIController.PathSteering
        local unreachableHulls = {}
        for hull in character.AIController.UnreachableHulls do unreachableHulls[hull] = true end
        for _, hull in pairs(home.GetHulls(false)) do
            local d = Vector2.DistanceSquared(character.WorldPosition, hull.WorldPosition)
            if hull.IsAirlock or hull.LeadsOutside(character) then
                if entrance == nil or d < entranceDistance then entrance = hull; entranceDistance = d end
            end
            if not unreachableHulls[hull] and (target == nil or hull.IsAirlock and not target.IsAirlock or hull.IsAirlock == target.IsAirlock and d < distance) then
                local route = steering.PathFinder.FindPath(character.SimPosition, character.GetRelativeSimPosition(hull), character.Submarine, nil, 0, nil, nil, nil, false)
                if not route.Unreachable then
                    target = hull; path = route; distance = d
                end
            end
        end
        local exterior = target == nil
        if target == nil then
            -- If every entry is blocked, approach a reachable exterior point and retry.
            for _, waypoint in pairs(home.GetWaypoints(false)) do
                if waypoint.CurrentHull == nil and not waypoint.IsObstructed then
                    local d = Vector2.DistanceSquared(waypoint.WorldPosition, entrance and entrance.WorldPosition or home.WorldPosition)
                    if target == nil or d < distance then
                        local route = steering.PathFinder.FindPath(character.SimPosition, character.GetRelativeSimPosition(waypoint), character.Submarine, nil, 0, nil, nil, nil, false)
                        if not route.Unreachable then target = waypoint; path = route; distance = d end
                    end
                end
            end
        end
        if target == nil then
            for _, waypoint in pairs(home.GetWaypoints(false)) do
                if waypoint.CurrentHull == nil and not waypoint.IsObstructed then
                    local d = Vector2.DistanceSquared(character.WorldPosition, waypoint.WorldPosition)
                    if target == nil or d < distance then target = waypoint; distance = d end
                end
            end
        end
        if target == nil then target = npc.GetSpawnPoint(home) end
        if target == nil then return end
        local objective = AIObjectiveGoTo(target, character, instance, exterior)
        objective.AllowGoingOutside = true
        -- above ordinary tasks, below combat and urgent treatment
        objective.OverridePriority = 89
        returnObjectives[character] = { Objective = objective, PreviousOrder = instance.ForcedOrder, Exterior = exterior, RetryAt = Timer.GetTime() + 5 }
        instance.SetForcedOrder(objective)
        instance.WaitTimer = 0
        instance.SortObjectives()
        if path ~= nil then steering.SetPath(character.GetRelativeSimPosition(target), path) end
    end
end, Hook.HookMethodType.Before)

Hook.Patch("Barotrauma.AIObjectiveFindSafety", "GetPriority", function(instance, ptable)
    local character = instance.character
    if returnObjectives[character] ~= nil and getHome(character) ~= nil
        and character.IsProtectedFromPressure and not character.IsLowInOxygen then
        return 0
    end
end, Hook.HookMethodType.After)

-- With the list type registered we get the C# list instead of a table copy; it is unregistered again
-- so other mods still get tables.
local function getList(instance, field, typeName)
    local registered = LuaUserData.IsRegistered(typeName)
    if not registered then LuaUserData.RegisterType(typeName) end
    local list = instance[field]
    if not registered then LuaUserData.UnregisterType(typeName) end
    return list
end

-- idle wandering normally skips wrecks, but event NPCs should patrol them too
Hook.Patch("Barotrauma.AIObjectiveIdle", "FindTargetHulls", function(instance, ptable)
    local home = getHome(instance.character)
    if home == nil then return end

    local targetHulls = getList(instance, "targetHulls", "System.Collections.Generic.List`1[Barotrauma.Hull]")
    local hullWeights = getList(instance, "hullWeights", "System.Collections.Generic.List`1[System.Single]")
    targetHulls.Clear()
    hullWeights.Clear()
    local unsafeHulls = {}
    for hull in instance.character.AIController.UnsafeHulls do unsafeHulls[hull] = true end
    for _, point in ipairs(getSpawnPoints(home)) do
        local hull = point.Waypoint.CurrentHull
        if point.Danger == 0 and not unsafeHulls[hull]
            and hull.RectWidth >= 200 and hull.CeilingHeight >= ConvertUnits.ToDisplayUnits(Single(instance.character.AnimController.HeadPosition))
            and not targetHulls.Contains(hull) then
            targetHulls.Add(hull)
            hullWeights.Add(math.max(0.01, 1 - point.Water / 100))
        end
    end
end, Hook.HookMethodType.After)

Hook.Patch("Barotrauma.AIObjectiveFindSafety", "FindBestHull", function(instance, ptable)
    if getHome(instance.character) ~= nil then
        ptable["allowChangingSubmarine"] = false
    end
end, Hook.HookMethodType.Before)

Hook.Patch("Barotrauma.AIObjectiveGoTo", "Act", function(instance, ptable)
    local home = getHome(instance.character)
    if home == nil then return end

    local source = instance.SourceObjective
    while source ~= nil do
        if source.Identifier == "combat" then return end
        source = source.SourceObjective
    end

    instance.AllowGoingOutside = instance.character.CurrentHull == nil or instance.character.Submarine ~= home
    local state = returnObjectives[instance.character]
    if state ~= nil and state.Objective == instance then
        instance.character.AIController.steeringManager = instance.character.AIController.PathSteering
    end
    if instance.Target ~= nil and instance.Target.Submarine ~= home then
        instance.Abandon = true
        ptable.PreventExecution = true
    end
end, Hook.HookMethodType.Before)

Hook.Add("roundEnd", "Traitormod.EventNPC.EndRound", function()
    homeSubmarines = {}
    returnObjectives = {}
end)

Traitormod.EventNPC = npc
return npc
