-- types/cet.lua
---@meta

-- Basic Aliases --

---@alias Bool boolean
---@alias Int32 integer
---@alias Uint32 integer
---@alias Float number

-- Common CET Globals ---

---@class GameClass
local Game = {}
_G.Game = Game

---@class SpdlogClass
spdlog = {}

---@class TweakDBClass
local TweakDB = {}
_G.TweakDB = TweakDB

---@class ImGuiClass
local ImGui = {}
_G.ImGui = ImGui

--- @param fmt string
--- @param ... any
function spdlog.error(fmt, ...) end

---@param eventName string
---@param cb fun()
function registerForEvent(eventName, cb) end

---@param class string
---@param method string
---@param cb function
function Override(class, method, cb) end

---@param class string
---@param method string
---@param cb function
function Observe(class, method, cb) end

---@param class string
---@param method string
---@param cb function
function ObserveAfter(class, method, cb) end

---@param textKey string
---@return string
function Game.GetLocalizedText(textKey) end

---@param path string
---@return any
function TweakDB:GetFlat(path) end

---@param path string
---@param newValue any
---@return boolean
function TweakDB:SetFlat(path, newValue) end

---@param path string
---@return any
function TweakDB:GetRecord(path) end
