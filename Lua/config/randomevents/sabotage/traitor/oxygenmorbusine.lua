local CreateOxygenEvent = dofile(Traitormod.Path .. "/Lua/config/randomevents/utility/oxygenevent.lua")

return CreateOxygenEvent({
    Name = "OxygenMorbusine",
    ChancePerMinute = 0.0005,
    Message = "OxygenMorbusine",
    Affliction = "morbusinepoisoning",
})
