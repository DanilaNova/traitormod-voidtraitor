local CreateSecurityTurretEvent = dofile(Traitormod.Path .. "/Lua/config/randomevents/utility/securityturretevent.lua")

return CreateSecurityTurretEvent({
    Name = "SecurityTurretFlakcannon",
    Turret = "flakcannon",
    Slot = "largeturrethardpoint",
})
