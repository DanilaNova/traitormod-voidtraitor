-- Admin ghost: an invisible, unkillable body that flies through walls and reaches items at any distance.
-- The admin's client runs the same movement code (Void traitor pack: Lua/client/spectator/adminghost.lua)
-- so prediction matches the server. The vt_adminghost affliction hides the ghost from everyone else;
-- spectators with the client script get a list of ghosts so they can still see them.
local adminGhost = {}

local AFFLICTION = "vt_adminghost"
local NET_PROBE = "VoidTraitor_AdminGhostProbe"
local NET_READY = "VoidTraitor_AdminGhostReady"
local NET_STATE = "VoidTraitor_AdminGhostState"
local NET_LIST = "VoidTraitor_AdminGhostList"
local NET_LIST_REQUEST = "VoidTraitor_AdminGhostListRequest"
local PATCH_ID = "Traitormod.AdminGhost"
local REACH_ARGS = { "Barotrauma.Item", "out System.Single", "System.Boolean", "System.Boolean" }
local REACH_CHARACTER_ARGS = { "Barotrauma.Character", "System.Single", "System.Boolean", "System.Boolean" }
local UPDATE_ANIM_ARGS = { "System.Single" }
local UPDATE_RAGDOLL_ARGS = { "System.Single", "Barotrauma.Camera" }
local VOIP_ARGS = { "Barotrauma.Networking.Client", "Barotrauma.Networking.Client", "out System.Single", "out System.Boolean" }
local BODY_KINEMATIC, BODY_DYNAMIC = 1, 2 -- FarseerPhysics.BodyType
local WALK_SPEED, RUN_SPEED = 5, 15 -- sim units per second (100 display units each)
-- how fast a carried character catches up with the ghost
local CATCH_UP = 10
local PROBE_TIMEOUT_MS = 2000

LuaUserData.RegisterType("Barotrauma.ContentXElement")
local contentElement = LuaUserData.CreateStatic("Barotrauma.ContentXElement")

-- ghost character -> { Client, Body, Info }
local ghosts = {}
-- clients we are waiting on to confirm they have the client script
local probing = {}
-- clients that get the ghost list (spectators with the client script)
local listeners = {}
-- ghost -> true if it selected the character with H (health window) instead of grabbing it
local inspecting = {}
-- ghost -> the character it carries
local carried = {}
local patched = false

-- levitatingCollider makes the ragdoll stand a character up on the floor and turns it into a ragdoll in the air;
-- collider and prevCollisionCategory are needed to give a carried character its physics back.
for _, animType in ipairs({ "Barotrauma.HumanoidAnimController", "Barotrauma.FishAnimController" }) do
    local descriptor = LuaUserData.RegisterType(animType)
    for _, field in ipairs({ "levitatingCollider", "collider", "prevCollisionCategory" }) do
        LuaUserData.MakeFieldAccessible(descriptor, field)
    end
end
LuaUserData.MakeFieldAccessible(LuaUserData.RegisterType("Barotrauma.HumanAIController"), "draggedTimer")

function adminGhost.IsGhost(character)
    return ghosts[character] ~= nil
end

local function isGhostClient(client)
    return client.Character ~= nil and ghosts[client.Character] ~= nil
end

-- Moves a character by its collider, ignoring gravity and floors.
local function fly(anim, velocity)
    -- a kinematic body ignores gravity, water and animation forces; set every frame because crouching swaps the collider
    anim.Collider.BodyType = BODY_KINEMATIC
    anim.Collider.LinearVelocity = velocity
    anim.levitatingCollider = false
    -- in the air the walk animation no longer pulls the limbs along, so pull the main limb here
    anim.MainLimb.PullJointWorldAnchorB = anim.Collider.SimPosition
    anim.MainLimb.PullJointEnabled = true
end

-- A character that can't move on its own (unconscious, dead) is moved by its main limb; the collider follows it.
local function carry(ghost, target, ghostVelocity)
    local anim = target.AnimController
    local velocity = ghostVelocity + (ghost.WorldPosition - target.WorldPosition) * (CATCH_UP / 100)
    if anim.ColliderControlsMovement then
        fly(anim, velocity)
    else
        anim.MainLimb.body.LinearVelocity = velocity
    end
end

-- Gives a carried character its normal physics back. Speed is reset because a fast body hitting a wall gets hurt;
-- resetting prevCollisionCategory makes the ragdoll restore its collisions.
local function release(target)
    local anim = target.AnimController
    for body in anim.collider do
        body.BodyType = BODY_DYNAMIC
        body.ResetDynamics()
    end
    for limb in anim.Limbs do
        limb.body.FarseerBody.IgnoreGravity = false
        limb.body.ResetDynamics()
    end
    anim.prevCollisionCategory = 0 -- FarseerPhysics.Dynamics.Category.None
end

-- The ghost carries what it grabbed with G instead of dragging it (see skipDrag),
-- so it never lets go and the carried character goes through walls with it.
local function updateCarried(ghost, velocity)
    local target = ghost.SelectedCharacter
    if inspecting[ghost] or (target ~= nil and target.Removed) then target = nil end
    local previous = carried[ghost]
    if previous ~= target then
        if previous ~= nil and not previous.Removed then release(previous) end
        carried[ghost] = target
        -- otherwise the limbs hang far behind under gravity
        if target ~= nil then
            for limb in target.AnimController.Limbs do limb.body.FarseerBody.IgnoreGravity = true end
        end
    end
    if target ~= nil then carry(ghost, target, velocity) end
end

-- Bots break free from a player of another team after a few seconds; keep resetting the timer while a ghost holds one.
local function keepBotHeld(target)
    local ai = target.AIController
    if ai ~= nil and LuaUserData.IsTargetType(ai, "Barotrauma.HumanAIController") then ai.draggedTimer = 0 end
end

-- Runs after the animations set the collider velocity and before the ragdolls use it, so our values win.
local function setVelocities()
    for ghost in pairs(ghosts) do
        if not ghost.Removed then
            local x, y = 0, 0
            if ghost.IsKeyDown(InputType.Left) then x = x - 1 end
            if ghost.IsKeyDown(InputType.Right) then x = x + 1 end
            if ghost.IsKeyDown(InputType.Up) then y = y + 1 end
            if ghost.IsKeyDown(InputType.Down) then y = y - 1 end
            local velocity = Vector2.Zero
            if x ~= 0 or y ~= 0 then
                velocity = Vector2.Normalize(Vector2(x, y)) * (ghost.IsKeyDown(InputType.Run) and RUN_SPEED or WALK_SPEED)
            end
            fly(ghost.AnimController, velocity)
            updateCarried(ghost, velocity)
            if ghost.SelectedCharacter ~= nil then keepBotHeld(ghost.SelectedCharacter) end
        end
    end
end

local function disableCollisions(anim)
    if anim.Collider.CollidesWith == 0 then return end
    anim.Collider.CollidesWith = 0
    -- the same limbs the game updates in Ragdoll.UpdateCollisionCategories
    for limb in anim.Limbs do
        if not limb.IgnoreCollisions and not limb.IsSevered then limb.body.CollidesWith = 0 end
    end
end

-- Runs right before the physics step. The ragdoll restores collisions whenever its category changes
-- (e.g. when leaving a submarine), so they are cleared every frame.
local function clearCollisions()
    for ghost in pairs(ghosts) do
        if not ghost.Removed then disableCollisions(ghost.AnimController) end
    end
    for _, target in pairs(carried) do
        if not target.Removed then disableCollisions(target.AnimController) end
    end
end

-- Same checks as Character.CanInteractWith(Item), minus the distance.
local function reach(instance, ptable)
    if ghosts[instance] == nil then return end
    ptable.PreventExecution = true
    local item = ptable["item"]
    local allowHidden = ptable["allowHiddenItems"]
    -- skip ladders: pressing up or down would grab the first one in reach and the ghost would start climbing
    if item.GetComponentString("Ladder") ~= nil then return false end
    if not instance.CanInteract or (item.IsHidden and not allowHidden) or not item.IsInteractable(instance, allowHidden) then return false end
    if item.ParentInventory ~= nil then return instance.CanAccessInventory(item.ParentInventory) end
    return item.InteractDistance > 0 or #item.Prefab.Triggers > 0
end

-- Same checks as Character.CanInteractWith(Character), minus distance and line of sight,
-- so the ghost can grab (G) and inspect (H) anyone it points at.
local function reachCharacter(instance, ptable)
    if ghosts[instance] == nil then return end
    ptable.PreventExecution = true
    local c = ptable["c"]
    return c ~= instance and c.Enabled and c.CanBeSelected and c.InvisibleTimer <= 0
end

-- The game lets go of a selected character that is too far away; a ghost keeps it at any distance.
local function keepSelectedInReach(instance, ptable)
    if ghosts[instance.SelectedBy] == nil then return end
    ptable.PreventExecution = true
    return 0
end

-- SetStun checks GodMode but not Unkillable, so an explosion would stun the ghost,
-- make it drop what it holds and throw its ragdoll around.
local function refuseStun(instance, ptable)
    if ghosts[instance] ~= nil and ptable["newStun"] > 0 then ptable.PreventExecution = true end
end

-- Lets ghosts hear dead and spectating players. The sender has no living character,
-- so the ghost's client plays the voice at full volume.
local function hearSpectators(instance, ptable)
    local recipient = ptable["recipient"]
    if not isGhostClient(recipient) then return end
    local sender = ptable["sender"]
    if sender.Muted or (sender.Character ~= nil and not sender.Character.IsDead) then return end
    ptable.PreventExecution = true
    -- the original is skipped, so the out parameters have to be set here
    ptable["distanceFactor"] = Single(0)
    ptable["isRadio"] = false
    return true
end

-- Normally only incapacitated or cuffed characters, pets and bots of the same team can be grabbed (G)
-- or inspected (H); a ghost may take anyone.
local function canBeDragged(instance, ptable)
    if ghosts[ptable["character"]] == nil then return end
    ptable.PreventExecution = true
    return instance.IsDraggable
end

-- Same rule for opening another character's inventory; a ghost opens any.
local function inventoryAccessible(instance, ptable)
    if ghosts[ptable["character"]] == nil then return end
    ptable.PreventExecution = true
    return not instance.Removed and instance.Inventory ~= nil
end

-- G and H both select the character; remember which one it was, since a ghost carries only what it grabbed with G.
local function rememberSelection(instance)
    if ghosts[instance] == nil then return end
    inspecting[instance] = instance.IsKeyHit(InputType.Health)
end

-- Normal dragging lets go behind a wall or when the target walks away; a ghost carries it instead (see updateCarried).
local function skipDrag(instance, ptable)
    if ghosts[instance.Character] ~= nil then ptable.PreventExecution = true end
end

-- Singularities, deconstructors and console commands remove characters through the spawner, which also takes
-- the client off the character. Ghosts are only removed by removeGhost, which forgets them first.
local function keepGhost(instance, ptable)
    if ghosts[ptable["entity"]] ~= nil then ptable.PreventExecution = true end
end

-- Added on first use and never removed: Hook.RemovePatch can't remove them because LuaCs uses the class name
-- as the patch id. While there are no ghosts they return right away.
local function ensurePatches()
    if patched then return end
    patched = true
    Hook.Patch(PATCH_ID, "Barotrauma.Character", "CanInteractWith", REACH_ARGS, reach, Hook.HookMethodType.Before)
    Hook.Patch(PATCH_ID, "Barotrauma.Character", "UpdateAnimAll", UPDATE_ANIM_ARGS, setVelocities, Hook.HookMethodType.After)
    Hook.Patch(PATCH_ID, "Barotrauma.Ragdoll", "UpdateAll", UPDATE_RAGDOLL_ARGS, clearCollisions, Hook.HookMethodType.After)
    Hook.Patch(PATCH_ID, "Barotrauma.Networking.VoipServer", "CanReceive", VOIP_ARGS, hearSpectators, Hook.HookMethodType.Before)
    Hook.Patch(PATCH_ID, "Barotrauma.Character", "CanBeDraggedBy", canBeDragged, Hook.HookMethodType.Before)
    Hook.Patch(PATCH_ID, "Barotrauma.Character", "IsInventoryAccessibleTo", inventoryAccessible, Hook.HookMethodType.Before)
    Hook.Patch(PATCH_ID, "Barotrauma.Character", "SelectCharacter", rememberSelection, Hook.HookMethodType.Before)
    Hook.Patch(PATCH_ID, "Barotrauma.HumanoidAnimController", "DragCharacter", skipDrag, Hook.HookMethodType.Before)
    Hook.Patch(PATCH_ID, "Barotrauma.EntitySpawner", "AddEntityToRemoveQueue", keepGhost, Hook.HookMethodType.Before)
    Hook.Patch(PATCH_ID, "Barotrauma.Character", "CanInteractWith", REACH_CHARACTER_ARGS, reachCharacter, Hook.HookMethodType.Before)
    Hook.Patch(PATCH_ID, "Barotrauma.Character", "GetDistanceToClosestLimb", keepSelectedInReach, Hook.HookMethodType.Before)
    Hook.Patch(PATCH_ID, "Barotrauma.Character", "SetStun", refuseStun, Hook.HookMethodType.Before)
end

local function sendList(connection)
    local message = Networking.Start(NET_LIST)
    local count = 0
    for _ in pairs(ghosts) do count = count + 1 end
    message.WriteByte(count)
    for ghost in pairs(ghosts) do message.WriteUInt16(ghost.ID) end
    Networking.Send(message, connection)
end

local function sendListToListeners()
    for client in pairs(listeners) do sendList(client.Connection) end
end

local function sendState(client, ghost, active)
    local message = Networking.Start(NET_STATE)
    message.WriteUInt16(ghost.ID)
    message.WriteBoolean(active)
    if active then
        message.WriteSingle(WALK_SPEED)
        message.WriteSingle(RUN_SPEED)
    end
    Networking.Send(message, client.Connection)
end

local function enable(client)
    local body = client.Character
    local position = body ~= nil and not body.IsDead and body.WorldPosition or client.SpectatePos
    -- copy the look, name and job of the admin's character, same as station cloning does
    local source = body ~= nil and body.IsHuman and body.Info or client.CharacterInfo
    local info
    if source ~= nil then
        info = CharacterInfo(contentElement.__new(nil, source.Save(nil)))
        info.PermanentlyDead = false
    else
        info = CharacterInfo("human", client.Name)
    end
    info.Name = string.format(Traitormod.Language.AdminGhostName, info.Name)
    local ghost = Character.Create(info, position, info.Name, 0, true, true)
    -- friendly to every team: bots ignore it and clients leave it out of the crew list
    -- (team None also made every bot's AI several times slower)
    ghost.TeamID = CharacterTeamType.FriendlyNPC
    -- unlike GodMode, Unkillable still lets afflictions and buffs work
    ghost.Unkillable = true
    ghost.CharacterHealth.ApplyAffliction(nil, AfflictionPrefab.Prefabs[AFFLICTION].Instantiate(1))
    -- the game never resets IgnoreGravity on limbs; the collider is kept kinematic in setVelocities
    for limb in ghost.AnimController.Limbs do limb.body.FarseerBody.IgnoreGravity = true end

    ghosts[ghost] = { Client = client, Body = body, Info = client.CharacterInfo }
    client.SetClientCharacter(ghost)
    ensurePatches()
    sendState(client, ghost, true)
    sendListToListeners()
end

-- returnControl is false when the round ends or the admin disconnects
local function removeGhost(ghost, returnControl)
    local state = ghosts[ghost]
    ghosts[ghost] = nil
    inspecting[ghost] = nil
    if carried[ghost] ~= nil and not carried[ghost].Removed then release(carried[ghost]) end
    carried[ghost] = nil

    -- Character.Remove would drop the ghost's items into the world, so remove them too
    for item in ghost.Inventory.AllItems do
        Entity.Spawner.AddItemToRemoveQueue(item)
    end

    local client = state.Client
    if returnControl then
        local body = state.Body
        client.SetClientCharacter(body ~= nil and not body.Removed and not body.IsDead and body or nil)
        sendState(client, ghost, false)
    end
    -- SetClientCharacter gave the client the ghost's CharacterInfo; put the real one back for the next spawn
    client.CharacterInfo = state.Info
    Entity.Spawner.AddEntityToRemoveQueue(ghost)
    sendListToListeners()
end

function adminGhost.Toggle(client)
    for ghost, state in pairs(ghosts) do
        if state.Client == client then
            removeGhost(ghost, true)
            return
        end
    end
    if probing[client] then return end

    -- movement prediction needs the client script; wait for it to answer the probe
    probing[client] = true
    Networking.Send(Networking.Start(NET_PROBE), client.Connection)
    Timer.Wait(function()
        if not probing[client] then return end
        probing[client] = nil
        Traitormod.SendMessage(client, Traitormod.Language.CMDAdminGhostNoClientLua)
    end, PROBE_TIMEOUT_MS)
end

Networking.Receive(NET_LIST_REQUEST, function(message, client)
    listeners[client] = true
    sendList(client.Connection)
end)

Networking.Receive(NET_READY, function(message, client)
    if not probing[client] then return end
    probing[client] = nil
    if Game.RoundStarted then enable(client) end
end)

-- Dead chat from a ghost: the server would drop it because the ghost is alive,
-- so send it to everyone who can read dead chat here.
Hook.Add("chatMessage", "Traitormod.AdminGhost.DeadChat", function(message, client)
    if client == nil or not isGhostClient(client) then return end
    local command, text = ChatMessage.GetChatMessageCommand(message)
    command = string.lower(command)
    if command ~= "d" and command ~= "dead" then return end

    for _, recipient in pairs(Client.ClientList) do
        if recipient.Character == nil or recipient.Character.IsDead or isGhostClient(recipient) then
            Game.SendDirectChatMessage(ChatMessage.Create(client.Character.Name, text, ChatMessageType.Dead, nil, client), recipient)
        end
    end
    Game.Server.AddChatMessage(text, ChatMessageType.Dead, client.Character.Name, client)
    return true
end)

-- Dead chat only reaches clients without a living character; send ghosts a copy.
Hook.Add("modifyChatMessage", "Traitormod.AdminGhost.DeadChatCopy", function(message)
    if message.Type ~= ChatMessageType.Dead then return end
    for _, state in pairs(ghosts) do
        if state.Client ~= message.SenderClient then
            Game.SendDirectChatMessage(ChatMessage.Create(message.SenderName, message.Text, ChatMessageType.Dead, nil, message.SenderClient), state.Client)
        end
    end
end)

Hook.Add("roundEnd", "Traitormod.AdminGhost.RoundEnd", function()
    for ghost in pairs(ghosts) do removeGhost(ghost, false) end
    probing = {}
    listeners = {}
end)

Hook.Add("client.disconnected", "Traitormod.AdminGhost.Disconnect", function(client)
    probing[client] = nil
    listeners[client] = nil
    for ghost, state in pairs(ghosts) do
        if state.Client == client then removeGhost(ghost, false) end
    end
end)

return adminGhost
