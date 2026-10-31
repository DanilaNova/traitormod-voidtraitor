local extension = {}

extension.Identifier = "stationragdollplatforms"

local function isStationCharacter(character)
    local selected = Traitormod.SelectedGamemode
    return selected ~= nil and selected.Name == "Station"
        and character.Enabled and not character.IsDead and character.IsHuman
        and not character.AnimController.InWater and character.SelectedBy == nil
end

local patched = false

function extension.Init()
    LuaUserData.RegisterType("FarseerPhysics.ConvertUnits")
    local units = LuaUserData.CreateStatic("FarseerPhysics.ConvertUnits")

    -- Patched only once a Station round starts: the patch then runs for every character each frame for the rest of the session.
    Hook.Add("roundStart", "VoidTraitor.StationRagdollPlatforms", function()
        local selected = Traitormod.SelectedGamemode
        if patched or selected == nil or selected.Name ~= "Station" then return end
        patched = true

        Hook.Patch("Barotrauma.Character", "Update", function(character)
            if not isStationCharacter(character) then return end
            if (character.IsRagdolled or not character.CanMove) and not character.AnimController.IsHangingWithRope then
                character.AnimController.IgnorePlatforms = false
            end
        end, Hook.HookMethodType.After)

        Hook.Patch("VoidTraitor.StationRagdollPlatforms.Stand", "Barotrauma.HumanoidAnimController", "UpdateAnim", {"System.Single"}, function(anim)
            local character = anim.Character
            if not isStationCharacter(character) or not character.CanMove or anim.Collider.Enabled
                or anim.IsHangingWithRope then return end

            local lowest = anim.FindLowestLimb()
            if lowest == nil then return end
            local x = anim.Collider.Position.X
            local y = lowest.Position.Y
            local platformY
            for _, wall in pairs(Structure.WallList) do
                if wall.IsPlatform and wall.HasBody and wall.Submarine == character.Submarine
                    and x >= wall.Rect.X and x <= wall.Rect.Right
                    and math.abs(y - wall.Rect.Y) <= 16
                    and (platformY == nil or wall.Rect.Y > platformY) then
                    platformY = wall.Rect.Y
                end
            end
            if platformY == nil then return end

            local collider = anim.Collider
            local targetY = units.ToSimUnits(platformY) + collider.Height / 2 + collider.Radius + anim.ColliderHeightFromFloor
            if collider.SimPosition.Y < targetY then
                collider.SetTransformIgnoreContacts(Vector2(collider.SimPosition.X, targetY), collider.Rotation)
                anim.ForceRefreshFloorY()
            end
        end, Hook.HookMethodType.Before)
    end)
end

return extension
