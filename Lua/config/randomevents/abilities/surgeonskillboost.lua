local CreateSkillBoostEvent = dofile(Traitormod.Path .. "/Lua/config/randomevents/utility/skillboostevent.lua")

return CreateSkillBoostEvent({
    Name = "SurgeonSkillBoost",
    Job = "surgeon",
    Skills = {
        surgery = 100,
        medical = 70,
    },
    Message = "SurgeonSkillBoost",
})
