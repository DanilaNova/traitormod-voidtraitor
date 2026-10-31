local CreateSkillBoostEvent = dofile(Traitormod.Path .. "/Lua/config/randomevents/utility/skillboostevent.lua")

return CreateSkillBoostEvent({
    Name = "CaptainHelmBoost",
    Job = "captain",
    Skills = {
        helm = 100,
    },
    Message = "CaptainHelmBoost",
})
