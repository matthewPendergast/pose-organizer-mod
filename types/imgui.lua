-- types/imgui.lua
---@meta

---@class ImGuiClass
ImGui = {}

---@class ImGuiStyleVar
ImGuiStyleVar = {}

ImGuiStyleVar.WindowMinSize = 0
ImGuiStyleVar.Alpha = 1
ImGuiStyleVar.WindowPadding = 2

-- Window --

--- @param width number
--- @param height number
--- @param cond? integer
function ImGui.SetNextWindowSize(width, height, cond) end

--- @param name string
--- @param p_open? boolean
--- @param flags? integer
--- @return boolean visible
function ImGui.Begin(name, p_open, flags) end

function ImGui.End() end

-- Layout/Spacing --

function ImGui.SameLine() end

function ImGui.Separator() end

function ImGui.Spacing() end

---@param idx integer
---@param value_x number
---@param value_y number
function ImGui.PushStyleVar(idx, value_x, value_y) end

function ImGui.PopStyleVar(count) end

function ImGui.BeginDisabled() end

function ImGui.EndDisabled() end

-- Widgets --

--- @param text string
function ImGui.Text(text) end

--- @param label string
--- @param current string
--- @param max_len integer
--- @return string newValue
function ImGui.InputText(label, current, max_len) end

--- @param label string
--- @return boolean pressed
function ImGui.Button(label) end

--- @param label string
--- @param current integer
--- @param items string[]
--- @param items_count integer
--- @return integer selectedIndex
function ImGui.Combo(label, current, items, items_count) end
