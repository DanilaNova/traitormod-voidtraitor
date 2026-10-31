local CreateSecurityTurretEvent = dofile(Traitormod.Path .. "/Lua/config/randomevents/utility/securityturretevent.lua")

return CreateSecurityTurretEvent({
    Name = "SecurityTurretDoubleCoilgun",
    Turret = "doublecoilgun",
    Slot = "largeturrethardpoint",
})
