----------------------------------------------------------------
-- PoseOrganizer
-- Author: Matthew Pendergast
-- Brief: Organize & rename custom photo mode poses by category
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

---@param errorMsg string
local function handleError(errorMsg)
	print(string.format("[%s] ", mod.localization.modName), errorMsg)
end

-- Controllers --

---@param overrides table
local function applyUserOverrides(overrides)
	for categoryID, entry in pairs(overrides.categories or {}) do
		if entry and entry.customName then
			if poseDataModel.categories[categoryID] then
				for _, category in ipairs(poseCategories) do
					if category.internalName == categoryID then
						category.displayName = entry.customName
					end
				end
				poseDataModel.categories[categoryID] = entry.customName
			end
		end
	end

	for poseID, entry in pairs(overrides.poses or {}) do
		local info = poseDataModel.poses[poseID]
		if info and entry and entry.customName then
			info.displayName = entry.customName
			local categoryID = info.category
			local list = posesByCategory[categoryID]
			if list then
				for _, pose in ipairs(list) do
					if pose.internalName == poseID then
						pose.displayName = entry.customName
						break
					end
				end
			end
		end
	end
end

---@param selectedCategoryID string
---@param newDisplayName string
local function handleCategoryRename(selectedCategoryID, newDisplayName)
	mod.utility.exportUserSettings({
		categories = {
			[selectedCategoryID] = { customName = newDisplayName }
		}
	})

	for _, entry in ipairs(poseCategories) do
		if entry.internalName == selectedCategoryID then
			entry.displayName = newDisplayName
			break
		end
	end

	poseDataModel.categories[selectedCategoryID] = newDisplayName
end

---@param selectedPoseID string
---@param newDisplayName string
local function handlePoseRename(selectedPoseID, newDisplayName)
	mod.utility.exportUserSettings({
		poses = {
			[selectedPoseID] = { customName = newDisplayName }
		}
	})

	local info = poseDataModel.poses[selectedPoseID]
	if info then
		info.displayName = newDisplayName
		local list = posesByCategory[info.category]
		if list then
			for _, entry in ipairs(list) do
				if entry.internalName == selectedPoseID then
					entry.displayName = newDisplayName
					break
				end
			end
		end
	end
end

local function handleRename(inputText, selectedID, route, updateLabelFunction)
	local newName = (inputText or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if newName ~= "" and selectedID then
		if route == "category" then
			handleCategoryRename(selectedID, newName)
		elseif route == "pose" then
			handlePoseRename(selectedID, newName)
		end
		if updateLabelFunction then
			updateLabelFunction(newName)
		end
		return ""
	end
	return inputText
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
		if not categoryRecord then
			handleError(("nil categoryRecord for: %s"):format(category))
		else
			local localizedCategoryName = Game.GetLocalizedText(categoryRecord:DisplayName().value)
			table.insert(poseCategories, {
				internalName = category,
				displayName = localizedCategoryName
			})
			poseDataModel.categories[category] = localizedCategoryName
		end
	end

	local poseFlat = TweakDB:GetFlat(mod.data.tweakDB.poseFlat)
	for _, pose in ipairs(poseFlat) do
		local poseRecord = TweakDB:GetRecord(pose)
		if not poseRecord then
			handleError(("nil poseRecord for: %s"):format(pose))
		else
			local poseCategory = poseRecord:Category().value
			local categoryRecord = TweakDB:GetRecord(poseCategory)
			if not categoryRecord then
				handleError(("nil categoryRecord for: %s"):format(poseCategory))
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

	local overrides = mod.utility.loadUserSettings()
	applyUserOverrides(overrides)

	mod.state.isInterfaceInitialized = mod.interface.initializeInterface(
		mod.localization,
		handleRename,
		handleExportRequest
	)
end)

registerForEvent("onDraw", function()
	if not isOverlayVisible then
		return
	else
		if mod.state.isInterfaceInitialized then
			mod.interface.drawInterface(poseCategories, posesByCategory)
		end
	end
end)
