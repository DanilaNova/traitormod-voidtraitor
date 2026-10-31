local CreateSkillBoostEvent = dofile(Traitormod.Path .. "/Lua/config/randomevents/utility/skillboostevent.lua")

return CreateSkillBoostEvent({
    Name = "MedicSkillBoost",
    Job = "medicaldoctor",
    Skills = {
        medical = 100,
        surgery = 70,
    },
    Message = "MedicSkillBoost",
})
