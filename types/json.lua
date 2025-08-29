-- types/json.lua
---@meta

---@class JSONClass
json = {}

--- @param value table<any, any>
--- @return string
function json.encode(value) end

--- @param str string
--- @return any
function json.decode(str) end
