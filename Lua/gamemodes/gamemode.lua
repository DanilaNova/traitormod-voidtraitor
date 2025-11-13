---@class Gamemode
local gm = {}

gm.Name = "Gamemode"
gm.TraitormodSettings = {
    LimitedSuicide = true -- Can a player use suicide command if knocked down/handcuffed
}

function gm:CheckRequirements()
    return true
end

function gm:PreStart()
    Traitormod.Pointshop.Initialize(self.PointshopCategories or {})
end

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

function gm:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    return o
end

return gm
