-- Mod State --

local mod = {
	controller = require("modules/controller.lua"),
	data = require("modules/data.lua"),
	hooks = require("modules/hooks.lua"),
	interface = require("modules/interface.lua"),
	localization = require("modules/localization.lua"),
	model = require("modules/model.lua"),
	utility = require("modules/utility.lua"),
	state = {
		isInterfaceInitialized = false,
		isDebugActive = false
	}
}

-- CET State --

local isOverlayVisible = false

-- Internal Data --

local poseCategories = {}
local posesByCategory = {}
local poseDataModel = {
	categories = {},
	poses = {}
}

-- Helper Functions --

---@param errorMsg string
local function handleError(errorMsg)
	print(string.format("[Pose Organizer] %s", errorMsg))
	spdlog.error(string.format("[Pose Organizer] %s", errorMsg))
end

-- Initialization --

local function init()
	-- Check debug state
	local file = io.open("dev/debug.lua", "r")
	if file then
		file:close()
		mod.state.isDebugActive = true
	end

	-- Build model
	poseCategories, posesByCategory, poseDataModel = mod.model.build(mod.data)

	-- Initialize controller
	mod.controller.init({
		poseCategories = poseCategories,
		posesByCategory = posesByCategory,
		poseDataModel = poseDataModel,
		utility = mod.utility,
	})

	-- Apply user overrides
	mod.controller.applyUserOverrides(mod.utility.loadUserSettings())

	-- Initialize hooks
	mod.hooks.init({
		poseCategories = poseCategories,
		posesByCategory = posesByCategory,
		controller = mod.controller,
		handleError = handleError,
		isDebugActive = mod.state.isDebugActive,
	})

	-- Initialize interface
	mod.state.isInterfaceInitialized = mod.interface.init({
		localization = mod.localization,
		handleCategoryRename = mod.controller.handleCategoryRename,
		handlePoseRename = mod.controller.handlePoseRename,
		handlePoseReassign = mod.controller.handlePoseReassign,
		handleExportRequest = mod.controller.handleExportRequest,
		isDebugActive = mod.state.isDebugActive
	})
end

-- Event Handlers --

registerForEvent("onOverlayOpen", function()
	isOverlayVisible = true
end)

registerForEvent("onOverlayClose", function()
	isOverlayVisible = false
end)

registerForEvent("onTweak", function()
	mod.controller.applyAllPoseCategoryPatches(mod.utility.loadUserSettings())
end)


registerForEvent("onInit", function()
	init()

	Observe("gameuiPhotoModeMenuController", "OnAttributeUpdated",
		---@param this gameuiPhotoModeMenuController
		---@param attributeKey Uint32
		---@param attributeValue Float
		---@param doApply? Bool
		function(this, attributeKey, attributeValue, doApply)
			if attributeKey == mod.data.menuController.attribute.category then
				mod.hooks.updateSelectedCategory(attributeValue)
			end
		end)

	Override("gameuiPhotoModeMenuController", "OnSetupOptionSelector",
		---@param this gameuiPhotoModeMenuController
		---@param attribute Uint32
		---@param values PhotoModeOptionSelectorData[]
		---@param startData Int32
		---@param doApply Bool
		---@param wrappedMethod function
		---@return Bool
		function(this, attribute, values, startData, doApply, wrappedMethod)
			if attribute == mod.data.menuController.attribute.category then
				mod.hooks.applyCategoryOverrides(values)
			end

			if attribute == mod.data.menuController.attribute.pose then
				mod.hooks.applyPoseOverrides(values)
			end

			return wrappedMethod(attribute, values, startData, doApply)
		end)
end)

registerForEvent("onDraw", function()
	if not isOverlayVisible then
		return
	else
		if mod.state.isInterfaceInitialized then
			mod.interface.draw(poseCategories, mod.controller.getUIPoseMap())
		end
	end
end)

return mod
