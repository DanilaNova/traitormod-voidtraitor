local extension = {}

extension.Identifier = "servermessageutf8fix"

local function getUtf8CharSize(value, index)
    local code = string.unicode(value, index)

    if code <= 0x7F then
        return 1, 1
    elseif code <= 0x7FF then
        return 2, 1
    elseif code >= 0xD800 and code <= 0xDBFF and index < #value then
        local low = string.unicode(value, index + 1)
        if low >= 0xDC00 and low <= 0xDFFF then
            return 4, 2
        end
    elseif code > 0xFFFF then
        return 4, 1
    end

    return 3, 1
end

extension.Init = function ()
    local descriptor
    if LuaUserData.IsRegistered("Barotrauma.Steam.SteamManager") then
        descriptor = Descriptors["Barotrauma.Steam.SteamManager"]
    else
        descriptor = LuaUserData.RegisterType("Barotrauma.Steam.SteamManager")
    end

    LuaUserData.MakeMethodAccessible(
        descriptor,
        "SetServerListInfo",
        {"Barotrauma.Identifier", "System.Object"}
    )

    local steamManager = LuaUserData.CreateStatic("Barotrauma.Steam.SteamManager")
    local logged = false

    Hook.Patch(
        "Traitormod.ServerMessageUTF8Fix",
        "Barotrauma.Steam.SteamManager",
        "SetServerListInfo",
        {"Barotrauma.Identifier", "System.Object"},
        function (_, ptable)
            local key = ptable["key"]
            if key == nil or tostring(key) ~= "message" then return end

            local value = ptable["value"]
            local chunkStart = 1
            local charIndex = 1
            local chunkBytes = 0
            local chunkIndex = 0

            while charIndex <= #value do
                local charBytes, charLength = getUtf8CharSize(value, charIndex)

                if chunkBytes + charBytes > 127 then
                    steamManager.SetServerListInfo(
                        Identifier("message" .. chunkIndex),
                        string.sub(value, chunkStart, charIndex - 1)
                    )
                    chunkIndex = chunkIndex + 1
                    chunkStart = charIndex
                    chunkBytes = 0
                else
                    chunkBytes = chunkBytes + charBytes
                    charIndex = charIndex + charLength
                end
            end

            if chunkStart <= #value then
                steamManager.SetServerListInfo(
                    Identifier("message" .. chunkIndex),
                    string.sub(value, chunkStart)
                )
                chunkIndex = chunkIndex + 1
            end

            steamManager.SetServerListInfo(Identifier("message" .. chunkIndex), "")
            ptable.PreventExecution = true

            if not logged then
                logged = true
                Traitormod.Log("[ServerMessageUTF8Fix] Published server message in " .. tostring(chunkIndex) .. " UTF-8-safe chunks")
            end
        end,
        Hook.HookMethodType.Before
    )
end

return extension
