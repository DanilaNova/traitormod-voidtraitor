local extension = {}

extension.Identifier = "paralysisnerf"

extension.CureTime = 60 * 7 -- 7 minutes

extension.Init = function ()
    local timer = {}
    local updateTimer = 0

    local function GetParalysisAmount(character)
        local paralysis = character.CharacterHealth.GetAfflictionStrengthByIdentifier("paralysis")
        if paralysis > 0 then
            return paralysis
        end

        local slowParalysis = character.CharacterHealth.GetAfflictionStrengthByIdentifier("slowparalysis")
        if slowParalysis > 0 then
            return slowParalysis
        end
        return 0
    end

    Hook.Add("think", "ParalysisNerf", function (deltaTime)
        updateTimer = updateTimer + deltaTime
        if updateTimer < 0.25 then return end

        local elapsed = updateTimer
        updateTimer = 0

        for _, client in pairs(Client.ClientList) do
            local character = client.Character
            if character then
                if GetParalysisAmount(character) > 0 then
                    if not timer[character] then
                        timer[character] = 0
                    end

                    timer[character] = timer[character] + elapsed

                    if timer[character] > extension.CureTime then -- 7 minutes
                        character.CharacterHealth.ApplyAffliction(character.AnimController.MainLimb, AfflictionPrefab.Prefabs["paralysis"].Instantiate(-60 * elapsed))
                    end
                elseif timer[character] then
                    timer[character] = 0
                end

                local affResistance = character.CharacterHealth.GetAffliction("paralysisresistance")
                if affResistance and affResistance.Strength > 0 then
                    local affliction = character.CharacterHealth.GetAffliction("paralysis", true)
                    if affliction == nil then
                        affliction = character.CharacterHealth.GetAffliction("slowparalysis", true)
                    end
                    if affliction then
                        affliction._strength = affliction._strength - (3 * elapsed)
                    end
                end
            end
        end
    end)

    Hook.Add("roundEnd", "ParalysisNerf.RoundEnd", function (...)
        timer = {}
        updateTimer = 0
    end)
end


return extension