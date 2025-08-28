----------------------------------------------------------------
-- Pose Organizer
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
local lastCategoryID = nil
local categoryGroupsTemplate = nil
local sessionCategoryMap = nil
local poseGroupsTemplate = nil
local sessionPoseMap = nil

-- Helper Functions --

---@param errorMsg string
local function handleError(errorMsg)
	print(string.format("[%s] ", mod.localization.modName), errorMsg)
end

local function trim(s)
	return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
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

-- Initialization --

local function buildCategories()
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
end

local function buildPoses()
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
end

local function initializeInternalData()
	buildCategories()
	buildPoses()
	applyUserOverrides(mod.utility.loadUserSettings())
end

-- Event Handlers --

registerForEvent("onOverlayOpen", function()
	isOverlayVisible = true
end)

registerForEvent("onOverlayClose", function()
	isOverlayVisible = false
end)

registerForEvent("onInit", function()
	initializeInternalData()

	mod.state.isInterfaceInitialized = mod.interface.initializeInterface(
		mod.localization,
		handleRename,
		handleExportRequest
	)

	Observe("gameuiPhotoModeMenuController", "OnAttributeUpdated",
		---@param this gameuiPhotoModeMenuController
		---@param attributeKey Uint32
		---@param attributeValue Float
		---@param doApply? Bool
		function(this, attributeKey, attributeValue, doApply)
			if attributeKey == mod.data.menuController.attribute.category and sessionCategoryMap then
				-- Track selected Category when changed
				lastCategoryID = sessionCategoryMap[attributeValue + 1]
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
			-- Category OptionSelector --
			if attribute == mod.data.menuController.attribute.category then
				-- Initial setup for category groups template
				if not categoryGroupsTemplate then
					categoryGroupsTemplate = {}
					for _, category in ipairs(poseCategories) do
						local id = category.internalName
						local record = TweakDB:GetRecord(id)
						if record then
							local originalName = Game.GetLocalizedText(record:DisplayName().value)
							local list = categoryGroupsTemplate[originalName]
							if not list then
								list = {}
								categoryGroupsTemplate[originalName] = list
							end
							list[#list + 1] = id
						end
					end
				end
				-- Make working copy of the category groups template to avoid mutating template
				local categoryGroups = {}
				for k, v in pairs(categoryGroupsTemplate) do
					local copy = {}
					for i = 1, #v do
						copy[i] = v[i]
					end
					categoryGroups[k] = copy
				end
				-- Map UI values to IDs for referencing changes
				sessionCategoryMap = {}
				for i = 1, #values do
					local key = values[i].optionText
					local ids = categoryGroups[key]
					if ids and #ids > 0 then
						sessionCategoryMap[i] = table.remove(ids, 1)
					else
						handleError(("Unresolved Category label: %s at index %d"):format(key or "<nil>", i))
					end
				end
				-- Apply user overrides to in-game UI display values
				local overrides = mod.utility.loadUserSettings() or {}
				local categoryOverrides = overrides.categories or {}
				for i = 1, #values do
					local id = nil
					if sessionCategoryMap then
						id = sessionCategoryMap[i]
					end
					if id then
						local override = categoryOverrides[id]
						local name = nil
						if override and override.customName then
							name = trim(override.customName)
						end
						if name and name ~= "" then
							values[i].optionText = name
						end
					end
				end
			end

			-- Pose OptionSelector --
			if attribute == mod.data.menuController.attribute.pose then
				local activeCategoryID = lastCategoryID
				if not activeCategoryID then
					if sessionCategoryMap then
						activeCategoryID = sessionCategoryMap[1]
					else
						return wrappedMethod(attribute, values, startData, doApply)
					end
				end
				-- Initial setup for pose groups template
				if not poseGroupsTemplate then
					poseGroupsTemplate = {}
				end
				if not poseGroupsTemplate[activeCategoryID] then
					local poseMap = {}
					local list = posesByCategory[activeCategoryID] or {}
					for _, pose in ipairs(list) do
						local id = pose.internalName
						local record = TweakDB:GetRecord(id)
						if record then
							local originalName = Game.GetLocalizedText(record:DisplayName().value)
							local list = poseMap[originalName]
							if not list then
								list = {}
								poseMap[originalName] = list
							end
							list[#list + 1] = id
						end
					end
					poseGroupsTemplate[activeCategoryID] = poseMap
				end
				-- Make working copy of the pose groups template to avoid mutating template
				local poseGroups = {}
				for k, v in pairs(poseGroupsTemplate[activeCategoryID]) do
					local copy = {}
					for i = 1, #v do
						copy[i] = v[i]
					end
					poseGroups[k] = copy
				end
				-- Map UI values to IDs for referencing changes
				sessionPoseMap = {}
				for i = 1, #values do
					local key = values[i].optionText
					local ids = poseGroups[key]
					if ids and #ids > 0 then
						sessionPoseMap[i] = table.remove(ids, 1)
					else
						handleError(("Unresolved Pose label: %s at index %d"):format(key or "<nil>", i))
					end
				end
				-- Apply user overrides to in-game UI display values
				local overrides = mod.utility.loadUserSettings() or {}
				local poseOverrides = overrides.poses or {}
				for i = 1, #values do
					local id = nil
					if sessionPoseMap then
						id = sessionPoseMap[i]
					end
					if id then
						local override = poseOverrides[id]
						local name = nil
						if override and override.customName then
							name = trim(override.customName)
						end
						if name and name ~= "" then
							values[i].optionText = name
						end
					end
				end
			end

			return wrappedMethod(attribute, values, startData, doApply)
		end)
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
