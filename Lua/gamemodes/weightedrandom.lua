local weightedRandom = {}

weightedRandom.Choose = function (subjects, variable, subVariable)
    local total = 0
    for key, value in pairs(subjects) do
        local weight = value
        if variable ~= nil then
            weight = value[variable]
            if subVariable ~= nil then
                weight = weight[subVariable]
            end
        end
        total = total + weight
    end

    if total <= 0 then
        for key in pairs(subjects) do
            return key
        end
        return nil
    end

    local rng = math.random() * total

    local step = 0
    for key, value in pairs(subjects) do
        local weight = value
        if variable ~= nil then
            weight = value[variable]
            if subVariable ~= nil then
                weight = weight[subVariable]
            end
        end
        step = step + weight

        if rng < step then
            return key
        end
    end

    return nil
end

return weightedRandom