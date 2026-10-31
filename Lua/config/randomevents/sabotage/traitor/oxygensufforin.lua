local CreateOxygenEvent = dofile(Traitormod.Path .. "/Lua/config/randomevents/utility/oxygenevent.lua")

return CreateOxygenEvent({
    Name = "OxygenSufforin",
    ChancePerMinute = 0.0025,
    Message = "OxygenSufforin",
    Affliction = "sufforinpoisoning",
})
