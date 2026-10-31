local CreateSecurityTurretEvent = dofile(Traitormod.Path .. "/Lua/config/randomevents/utility/securityturretevent.lua")

return CreateSecurityTurretEvent({
    Name = "SecurityTurretCoilgun",
    Turret = "coilgun",
    Slot = "turrethardpoint",
})
