local CreateOxygenEvent = dofile(Traitormod.Path .. "/Lua/config/randomevents/utility/oxygenevent.lua")

return CreateOxygenEvent({
    Name = "OxygenCyanide",
    ChancePerMinute = 0.0025,
    Message = "OxygenCyanide",
    Affliction = "cyanidepoisoning",
})
