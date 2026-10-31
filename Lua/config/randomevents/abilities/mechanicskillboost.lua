local CreateSkillBoostEvent = dofile(Traitormod.Path .. "/Lua/config/randomevents/utility/skillboostevent.lua")

return CreateSkillBoostEvent({
    Name = "MechanicSkillBoost",
    Job = "mechanic",
    Skills = {
        mechanical = 100,
    },
    Message = "MechanicSkillBoost",
})
