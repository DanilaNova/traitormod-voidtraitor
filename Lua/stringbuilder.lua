---@class StringBuilder : tablelib
-- "Utility class for building strings. This is a pure Lua implementation of the StringBuilder class in C#."
-- - Github Copilot
local p = setmetatable({}, {__index=table})

---@type string s
---@vararg string, format arguments
function p:format(s, ...)
    if s == nil then
        print("[VoidTraitor] StringBuilder received a nil format string; skipping this fragment")
        return self
    end

    table.insert(self, string.format(type(s) == "table" and table.concat(s) or s, ...))
    return self
end

function p:append(...)
    table.insert(self, table.concat(table.pack(...)))
    return self
end

---@return StringBuilder
function p:new()
    return setmetatable({}, {
        __call=self.format,
        __index=self,
    })
end

return p