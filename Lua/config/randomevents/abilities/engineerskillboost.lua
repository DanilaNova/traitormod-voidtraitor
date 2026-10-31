local CreateSkillBoostEvent = dofile(Traitormod.Path .. "/Lua/config/randomevents/utility/skillboostevent.lua")

return CreateSkillBoostEvent({
    Name = "EngineerSkillBoost",
    Job = "engineer",
    Skills = {
        electrical = 100,
    },
    Message = "EngineerSkillBoost",
})
