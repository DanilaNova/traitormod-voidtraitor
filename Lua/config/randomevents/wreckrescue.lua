local CreateRescueEvent = dofile(Traitormod.Path .. "/Lua/config/randomevents/utility/rescueevent.lua")

return CreateRescueEvent({
    Name = "WreckRescue",
    PirateEvent = "WreckPirate",
    Message = "WreckRescue",
    GhostRole = "rescue.wreck",
    HookName = "WreckRescue.Think",
    SpawnSonar = true,
    CanStart = function()
        return #Level.Loaded.Wrecks > 0
    end,
    GetSubmarine = function()
        if #Level.Loaded.Wrecks == 0 then
            return nil
        end

        return Level.Loaded.Wrecks[math.random(#Level.Loaded.Wrecks)]
    end,
})
