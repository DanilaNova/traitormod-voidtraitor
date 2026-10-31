local CreateSecurityTurretEvent = dofile(Traitormod.Path .. "/Lua/config/randomevents/utility/securityturretevent.lua")

return CreateSecurityTurretEvent({
    Name = "SecurityTurretChaingun",
    Turret = "chaingun",
    Slot = "turrethardpoint",
})
