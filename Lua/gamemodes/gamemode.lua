---@class Gamemode
---@field RequiredGamemode string?
local gm = {}

gm.Name = "Gamemode"

---@return boolean
function gm:CheckRequirements()
    return true
end

function gm:PreStart()
    Traitormod.Pointshop.Initialize(self.PointshopCategories or {})
end

---Invoked on round start
function gm:Start()

end

function gm:Think()

end

function gm:End()

end

function gm:TraitorResults()

end

function gm:RoundSummary()
    local sb = Traitormod.StringBuilder:new()

    sb("Gamemode: %s\n", self.Name)

    for character, role in pairs(Traitormod.RoleManager.RoundRoles) do
        local text = role:OtherGreet()
        if text then
            sb("\n%s\n", role:OtherGreet())
        end
    end

    return sb:concat()
end

---Creates new instance of Gamemode with self as metatable and makes a proxy for missing fields to self
---@param o table? returned table with self as metatable(default empty table)
---@return Gamemode
function gm:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    return o
end

return gm
