local CreateRescueEvent = dofile(Traitormod.Path .. "/Lua/config/randomevents/utility/rescueevent.lua")

return CreateRescueEvent({
    Name = "BeaconRescue",
    PirateEvent = "BeaconPirate",
    Message = "BeaconRescue",
    GhostRole = "rescue.beacon",
    HookName = "BeaconRescue.Think",
    SpawnSonar = true,
    CanStart = function()
        return Level.Loaded.BeaconStation ~= nil
    end,
    GetSubmarine = function()
        return Level.Loaded.BeaconStation
    end,
})
