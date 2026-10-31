local CreateSecurityTurretEvent = dofile(Traitormod.Path .. "/Lua/config/randomevents/utility/securityturretevent.lua")

return CreateSecurityTurretEvent({
    Name = "SecurityTurretPulseLaser",
    Turret = "pulselaser",
    Slot = "turrethardpoint",
})
