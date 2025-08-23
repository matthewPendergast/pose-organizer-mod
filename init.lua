----------------------------------------------------------------
-- PoseOrganizer
-- Author: Matthew Pendergast
-- Brief: Organize & rename custom photo mode poses by category.
----------------------------------------------------------------

-- Mod State --

local mod = {
	data = require("modules/data.lua"),
	interface = require("modules/interface.lua"),
	localization = require("modules/localization.lua"),
	utility = require("modules/utility.lua"),
	debug = require("dev/debug.lua"),
	state = {
		isInterfaceInitialized = false
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

---@param error string
local function handleError(error)
	print(string.format("[%s] ", mod.localization.modName), error)
end

local function handleExportRequest()
	mod.utility.exportPoseDataModel(poseDataModel)
end

-- Event Handlers --

registerForEvent("onOverlayOpen", function()
	isOverlayVisible = true
end)

registerForEvent("onOverlayClose", function()
	isOverlayVisible = false
end)

registerForEvent("onInit", function()
	local poseCategoryFlat = TweakDB:GetFlat(mod.data.tweakDB.categoryFlat)
	for _, category in ipairs(poseCategoryFlat) do
		local categoryRecord = TweakDB:GetRecord(category)
		local localizedCategoryName = Game.GetLocalizedText(categoryRecord:DisplayName().value)
		table.insert(poseCategories, {
			internalName = category,
			displayName = localizedCategoryName
		})
		poseDataModel.categories[category] = localizedCategoryName
	end

	local poseFlat = TweakDB:GetFlat(mod.data.tweakDB.poseFlat)
	for _, pose in ipairs(poseFlat) do
		local poseRecord = TweakDB:GetRecord(pose)
		if not poseRecord then
			handleError(string.format("nil poseRecord for: %s", pose))
		else
			local poseCategory = poseRecord:Category().value
			local categoryRecord = TweakDB:GetRecord(poseCategory)
			if not categoryRecord then
				handleError(string.format("nil categoryRecord for: %s", poseCategory))
			else
				local localizedPoseName = Game.GetLocalizedText(poseRecord:DisplayName().value)

				if not posesByCategory[poseCategory] then
					posesByCategory[poseCategory] = {}
				end

				table.insert(posesByCategory[poseCategory], {
					internalName = pose,
					displayName = localizedPoseName
				})

				poseDataModel.poses[pose] = {
					category    = poseCategory,
					displayName = localizedPoseName,
				}
			end
		end
	end

	mod.state.isInterfaceInitialized = mod.interface.initializeInterface(
		mod.localization,
		handleExportRequest
	)
end)

registerForEvent("onDraw", function()
	if not isOverlayVisible and not mod.state.isInterfaceInitialized then
		return
	else
		if mod.state.isInterfaceInitialized then
			mod.interface.drawInterface(poseCategories, posesByCategory)
		end
	end
end)
