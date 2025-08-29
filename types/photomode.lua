-- types/photomode.lua
---@meta

---@class gameuiPhotoModeMenuController
local gameuiPhotoModeMenuController = {}

---@class PhotoModeOptionSelectorData
---@field optionText string
---@field optionData integer

---@alias SetupOptionSelectorWrapped
---| fun(this: gameuiPhotoModeMenuController, attribute: Uint32, values: PhotoModeOptionSelectorData[], startData: Int32, doApply: Bool): Bool
