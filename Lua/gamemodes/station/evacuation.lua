local evacuation = {}
local bodyTypes = LuaUserData.CreateEnumTable("FarseerPhysics.BodyType")
local aabb = LuaUserData.CreateStatic("FarseerPhysics.Collision.AABB", true)
LuaUserData.RegisterType("FarseerPhysics.Dynamics.World")
LuaUserData.RegisterType("Barotrauma.SteeringPath")
local collisionMask = bit32.bor(Physics.CollisionLevel, Physics.CollisionWall,
    Physics.CollisionItem, Physics.CollisionItemBlocking, Physics.CollisionRepairableWall)
local announcementColor = Color(255, 215, 0, 255)
local announcementHeaderColor = Color(255, 255, 170, 255)

local function hold(state, position)
    state.Helm.AutoPilot = true
    state.Helm.PosToMaintain = position
    state.Helm.MaintainPos = true
    state.Helm.UnsentChanges = true
end

-- Whether the whole hull fits along the way from 'from' to 'position' (one box around both, with a margin).
local function clear(state, position, from)
    from = from or position
    local bounds = state.Ship.Borders
    local lower = Vector2(math.min(from.X, position.X) + bounds.X - 20,
        math.min(from.Y, position.Y) + bounds.Y - bounds.Height - 20)
    local upper = Vector2(math.max(from.X, position.X) + bounds.X + bounds.Width + 20,
        math.max(from.Y, position.Y) + bounds.Y + 20)
    local fixtures = Game.World.QueryAABB(aabb.__new(ConvertUnits.ToSimUnits(lower), ConvertUnits.ToSimUnits(upper)))
    for _, fixture in ipairs(fixtures) do
        if not fixture.IsSensor and fixture.Body ~= state.Ship.PhysicsBody.FarseerBody
            and bit32.band(fixture.CollisionCategories, collisionMask) ~= 0 then
            return false
        end
    end
    return true
end

local function berth(state, port)
    local offset = state.Port.Item.WorldPosition - state.Ship.WorldPosition
    return port.Item.WorldPosition - offset
        - Vector2(0, state.Port.GetDir(port) * state.Port.DockedDistance * state.Port.Item.Scale)
end

local function park(state)
    state.Port.Undock(false)
    state.Ship.SetPosition(Vector2(Level.Loaded.EndPosition.X, Level.Loaded.Size.Y + state.Ship.Borders.Height))
    state.Ship.Velocity = Vector2.Zero
    state.Ship.PhysicsBody.BodyType = bodyTypes.Static
    hold(state, state.Ship.WorldPosition)
    state.Status = "Parked"
    state.TargetPort, state.Approach, state.Berth, state.Departure = nil, nil, nil, nil
    state.ParkedActive = {}
    for item in Item.ItemList do
        if item.Submarine == state.Ship then
            state.ParkedActive[item] = item.IsActive
            item.IsActive = false
        end
    end
end

function evacuation.Start(mode)
    local state = { AvailableAt = Timer.GetTime() + mode.Evacuation.InitialDelay, Ports = {}, Engines = {} }
    for item in Item.ItemList do
        if item.HasTag("vt_evac_helm") then
            state.Ship = item.Submarine
            state.Helm = item.GetComponentString("Steering")
        elseif item.HasTag("vt_evac_port") then
            state.Port = item.GetComponentString("DockingPort")
        end
        if item.Submarine == Submarine.MainSub then
            local port = item.GetComponentString("DockingPort")
            if port ~= nil and not port.IsHorizontal and port.Door ~= nil then
                state.Ports[#state.Ports + 1] = port
            end
        end
    end
    mode.EvacuationState = state
    if state.Ship == nil or state.Port == nil or state.Helm == nil or Level.Loaded.EndOutpost == nil then
        state.Status = "Unavailable"
        return
    end
    state.Ship.ImmuneToBallastFlora = true
    table.sort(state.Ports, function(a, b)
        if a.Item.HasTag("vt_evac_home") ~= b.Item.HasTag("vt_evac_home") then
            return a.Item.HasTag("vt_evac_home")
        end
        return a.Item.ID < b.Item.ID
    end)
    for item in Item.ItemList do
        if item.Submarine == state.Ship then
            local engine = item.GetComponentString("Engine")
            local pump = item.GetComponentString("Pump")
            if engine ~= nil then
                state.Engines[#state.Engines + 1] = engine
            elseif pump ~= nil then
                pump.MaxFlow = pump.MaxFlow * mode.Evacuation.PumpFlowMultiplier
                Networking.CreateEntityEvent(item, Item.ChangePropertyEventData(pump.SerializableProperties[Identifier("MaxFlow")], pump))
            end
        end
    end
    park(state)
end

function evacuation.Estimate(mode)
    local state = mode.EvacuationState
    local force = 0
    for _, engine in ipairs(state.Engines) do
        if not engine.Item.Removed and engine.HasPower then
            force = force + engine.MaxForce * math.min(engine.Voltage, 2) ^ (2 / 3)
                * (0.5 + 1.5 * engine.Item.ConditionPercentage / 100)
        end
    end
    if force <= 0 then
        return nil
    end
    -- rough cruise speed: half throttle, engine force multiplier 0.1, hull drag 0.01 * v^2
    local speed = math.sqrt(5 * force / (0.01 * state.Ship.PhysicsBody.Mass)) * 100
    local position, distance = state.Ship.WorldPosition, 0
    if state.Helm.MaintainPos then
        return math.ceil(Vector2.Distance(position, state.Helm.PosToMaintain) / speed)
    end
    local path = state.Helm.SteeringPath
    if path == nil or path.Unreachable then
        return nil
    end
    for index, node in ipairs(path.Nodes) do
        if index > path.CurrentIndex then
            distance = distance + Vector2.Distance(position, node.WorldPosition)
            position = node.WorldPosition
        end
    end
    if state.Status == "Inbound" then
        distance = distance + Vector2.Distance(position, Submarine.MainSub.WorldPosition)
    else
        distance = distance + Vector2.Distance(position, Level.Loaded.EndExitPosition)
    end
    return math.ceil(distance / speed)
end

function evacuation.Action(mode)
    evacuation.Think(mode)
    local state = mode.EvacuationState
    local now = Timer.GetTime()
    if state.Status == "Parked" and now >= state.AvailableAt then
        for item, wasActive in pairs(state.ParkedActive) do
            if not item.Removed then
                item.Condition = item.MaxCondition
                local battery = item.GetComponentString("PowerContainer")
                if battery ~= nil then battery.Charge = battery.Capacity end
                local reactor = item.GetComponentString("Reactor")
                if reactor ~= nil then reactor.PowerOn, reactor.AutoTemp = true, true end
                item.IsActive = wasActive
            end
        end
        state.ParkedActive = nil
        state.Ship.PhysicsBody.BodyType = bodyTypes.Dynamic
        state.Ship.SetPosition(Game.Server.RespawnManager.FindSpawnPos(state.Ship, Level.Loaded.EndOutpost))
        state.Ship.Velocity = Vector2.Zero
        state.Helm.SetDestinationLevelStart()
        state.Helm.UnsentChanges = true
        state.Status, state.RecallAt = "Inbound", now + mode.Evacuation.RecallDelay
        local estimate = evacuation.Estimate(mode)
        if estimate ~= nil then
            local forceMultiplier = (estimate / mode.Evacuation.TravelTime) ^ 2
            for _, engine in ipairs(state.Engines) do
                engine.MaxForce = engine.MaxForce * forceMultiplier
                Networking.CreateEntityEvent(engine.Item, Item.ChangePropertyEventData(engine.SerializableProperties[Identifier("MaxForce")], engine))
            end
        end
        mode:SendAlertMessage(Traitormod.GetText("EvacCalled"), announcementColor, announcementHeaderColor)
        mode:PlayAlertSound("evacCalled")
    elseif state.Status == "Inbound" and not state.Port.Docked and now >= state.RecallAt then
        state.Status = "Returning"
        state.TargetPort, state.Approach, state.Berth = nil, nil, nil
        state.Helm.SetDestinationLevelEnd()
        state.Helm.UnsentChanges = true
        mode:SendAlertMessage(Traitormod.GetText("EvacRecalled"), announcementColor, announcementHeaderColor)
        mode:PlayAlertSound("evacRecalled")
    end
end

local function arrive(mode, nearby)
    local state = mode.EvacuationState
    local duration = mode.Evacuation.BoardingTime
    if nearby then
        duration = mode.Evacuation.NoDockBoardingTime
    elseif not state.TargetPort.Item.HasTag("vt_evac_home") then
        duration = mode.Evacuation.OtherDockBoardingTime
    end
    state.Status, state.DepartAt = "Boarding", Timer.GetTime() + duration
    local message
    if nearby then
        message = Traitormod.FormatText("EvacNearby", math.ceil(duration))
    else
        local station = Submarine.MainSub
        local borders = station.Borders
        local centerY = station.WorldPosition.Y + borders.Y - borders.Height / 2
        local direction = state.TargetPort.Item.WorldPosition.Y >= centerY and "EvacNorth" or "EvacSouth"
        message = Traitormod.FormatText("EvacDocked", mode.StationAnnouncementName,
            Traitormod.GetText(direction), math.ceil(duration))
    end
    mode:SendAlertMessage(message, announcementColor, announcementHeaderColor)
    if not nearby then mode:PlayAlertSound("evacDocked") end
end

local function navigate(state, ports)
    local position = state.Ship.WorldPosition
    local blockedPort = state.TargetPort ~= nil and (state.TargetPort.Item.Removed
        or state.TargetPort.Docked and state.TargetPort.DockingTarget ~= state.Port
        or not state.Port.Docked and not clear(state, state.Berth))
    local blockedApproach = state.Approach ~= nil and not state.Port.Docked
        and not clear(state, state.Helm.PosToMaintain, position)
    if blockedPort or blockedApproach then
        state.TargetPort, state.Approach, state.Berth = nil, nil, nil
        state.Helm.SetDestinationLevelStart()
        state.Helm.UnsentChanges = true
    end
    if state.Approach == nil then
        local availableBerth = false
        for _, port in ipairs(ports) do
            if not port.Item.Removed and not port.Docked and port.GetDir(state.Port) == -1 then
                local target = berth(state, port)
                local approach = target - Vector2(0, state.Ship.Borders.Height)
                if clear(state, target, approach) then
                    availableBerth = true
                    if math.abs(position.X - approach.X) < state.Ship.Borders.Width * 4
                        and clear(state, approach, position) then
                        state.TargetPort, state.Berth, state.Approach = port, target, approach
                        hold(state, approach)
                        break
                    end
                end
            end
        end
        if state.Approach == nil and not availableBerth then
            local bounds = Submarine.MainSub.Borders
            local nearby = Submarine.MainSub.WorldPosition + Vector2(bounds.X + bounds.Width / 2,
                bounds.Y - bounds.Height - state.Ship.Borders.Height * 2)
            if Vector2.Distance(position, nearby) < state.Ship.Borders.Width * 4 and clear(state, nearby, position) then
                state.Approach = nearby
                hold(state, nearby)
            end
        end
    elseif state.TargetPort == nil then
        if Vector2.Distance(position, state.Approach) < 200 and state.Ship.Velocity.Length() < 0.6 then
            return true, true
        end
    elseif state.Port.Docked and state.Port.DockingTarget == state.TargetPort then
        if state.Port.IsLocked then
            return true, false
        end
    else
        if Vector2.Distance(position, state.Approach) < 200 and state.Helm.PosToMaintain ~= state.Berth then
            hold(state, state.Berth)
        end
        local delta = state.TargetPort.Item.WorldPosition - state.Port.Item.WorldPosition
        local tolerance = state.Port.DistanceTolerance
        if math.abs(delta.X) <= tolerance.X and math.abs(delta.Y) <= tolerance.Y
            and state.Ship.Velocity.Length() < 0.6 and clear(state, state.Berth) then
            state.Port.Dock(state.TargetPort)
        end
    end
    return false
end

function evacuation.Think(mode)
    local state = mode.EvacuationState
    if state.Status == "Unavailable" or state.Status == "Parked" or mode.Ending then
        return
    end
    if state.Ship.Removed or state.Port.Item.Removed or state.Helm.Item.Removed then
        state.Status = "Unavailable"
        return
    end
    local position = state.Ship.WorldPosition
    if state.Status == "Inbound" then
        local arrived, nearby = navigate(state, state.Ports)
        if arrived then
            arrive(mode, nearby)
        end
    elseif state.Status == "Boarding" or state.Status == "Departing" then
        local remaining = state.DepartAt - Timer.GetTime()
        if state.Status == "Boarding" and remaining <= 10 and remaining > 0 then
            state.Status = "Departing"
            mode:SendAlertMessage(Traitormod.FormatText("EvacLaunchSoon", math.ceil(remaining)),
                announcementColor, announcementHeaderColor)
            mode:PlayAlertSound("evacLaunching")
        end
        if remaining <= 0 then
            state.Status = "Outbound"
            if state.Port.Docked then
                state.Port.Undock(false)
                state.TargetPort, state.Approach, state.Berth = nil, nil, nil
                state.Departure = position - Vector2(0, state.Ship.Borders.Height)
                hold(state, state.Departure)
                mode:SendAlertMessage(Traitormod.GetText("EvacUndocked"), announcementColor, announcementHeaderColor)
            else
                state.TargetPort, state.Approach, state.Berth = nil, nil, nil
                state.Helm.SetDestinationLevelEnd()
                state.Helm.UnsentChanges = true
                mode:SendAlertMessage(Traitormod.GetText("EvacDeparted"), announcementColor, announcementHeaderColor)
            end
            mode:PlayAlertSound("evacDeparted")
        end
    elseif state.Status == "Returning" or state.Status == "Outbound" then
        if state.Departure ~= nil and Vector2.Distance(position, state.Departure) < 200 then
            state.Departure = nil
            state.Helm.SetDestinationLevelEnd()
            state.Helm.UnsentChanges = true
        end
        if state.Departure == nil and not state.Helm.MaintainPos then
            local destination = Level.Loaded.EndExitPosition - Vector2(0, Level.ExitDistance / 2)
            if math.abs(position.X - destination.X) < state.Ship.Borders.Width * 4
                and clear(state, destination, position) then
                hold(state, destination)
            end
        end
        if state.Ship.AtEndExit and state.Ship.Velocity.Length() < 0.6 then
            if state.Status == "Returning" then
                park(state)
            else
                hold(state, position)
                mode:BeginEnding("crew")
            end
        end
    end
end

function evacuation.Snapshot(mode)
    local state = mode.EvacuationState
    local now = Timer.GetTime()
    local status, enabled = state.Status, false
    local text = Traitormod.GetText("Evac" .. (status == "Departing" and "Boarding" or status))
    local action = Traitormod.GetText("EvacCall")
    if status == "Parked" then
        local remaining = math.max(0, math.ceil(state.AvailableAt - now))
        enabled = remaining == 0
        if not enabled then
            text = Traitormod.FormatText("EvacAvailableIn", remaining)
        end
    elseif status == "Inbound" then
        local remaining = math.max(0, math.ceil(state.RecallAt - now))
        action, enabled = Traitormod.GetText("EvacRecall"), remaining == 0
        if not enabled then
            action = Traitormod.FormatText("EvacRecallIn", remaining)
        end
    elseif status == "Boarding" or status == "Departing" then
        text = Traitormod.FormatText("EvacBoarding", math.max(0, math.ceil(state.DepartAt - now)))
    end
    if status == "Inbound" or status == "Returning" or status == "Outbound" then
        local estimate = evacuation.Estimate(mode)
        if estimate ~= nil then
            text = text .. "\n" .. Traitormod.FormatText("EvacETA", estimate)
        end
    end
    return { Status = text, Action = action, Enabled = enabled }
end

Hook.Patch("Traitormod.Station.EvacuationBuoyancy", "Barotrauma.SubmarineBody", "CalculateBuoyancy", function(body, parameters)
    local selected = Traitormod.SelectedGamemode
    if selected == nil or selected.Name ~= "Station" then return end
    local state = selected.EvacuationState
    if state == nil or state.Status == "Parked" or state.Status == "Unavailable"
        or body.Submarine ~= state.Ship or state.Port.Docked then return end
    local desiredSpeed = state.Helm.TargetVelocity.Y * 0.05
    local acceleration = math.max(-5, math.min(5, (desiredSpeed - state.Ship.Velocity.Y) * 1.5))
    parameters.ReturnValue = Vector2(0, body.Body.Mass * acceleration)
end, Hook.HookMethodType.After)

return evacuation
