local CreateOxygenEvent = dofile(Traitormod.Path .. "/Lua/config/randomevents/utility/oxygenevent.lua")

return CreateOxygenEvent({
    Name = "OxygenParalyzant",
    ChancePerMinute = 0.0025,
    Message = "OxygenParalyzant",
    Affliction = "paralysis",
})
