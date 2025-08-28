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
local categoryBucketsTemplate = nil
local sessionCategoryMap = nil

-- Reference --
local menuController = {
	attribute = {
		category = 5,
		pose = 6,
	}
}

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
	local overrides = mod.utility.loadUserSettings()
	applyUserOverrides(overrides)
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

	Override("gameuiPhotoModeMenuController", "OnSetupOptionSelector",
		---@param this gameuiPhotoModeMenuController
		---@param attribute Uint32
		---@param values PhotoModeOptionSelectorData[]
		---@param startData Int32
		---@param doApply Bool
		---@param wrappedMethod function
		---@return Bool
		function(this, attribute, values, startData, doApply, wrappedMethod)
			if not values or #values == 0 then
				return wrappedMethod(attribute, values, startData, doApply)
			end

			-- Modify Category values
			if attribute == menuController.attribute.category then
				-- Setup category bucket template
				if not categoryBucketsTemplate then
					categoryBucketsTemplate = {}
					for _, category in ipairs(poseCategories) do
						local id = category.internalName
						local record = TweakDB:GetRecord(id)
						if record then
							local originalName = Game.GetLocalizedText(record:DisplayName().value)
							local list = categoryBucketsTemplate[originalName]
							if not list then
								list = {}
								categoryBucketsTemplate[originalName] = list
							end
							list[#list + 1] = id
						end
					end
				end

				-- Make working copy of the buckets (prevents mutation of template)
				local buckets = {}
				for k, v in pairs(categoryBucketsTemplate) do
					local copy = {}
					for i = 1, #v do copy[i] = v[i] end
					buckets[k] = copy
				end

				-- Map the UI values in order to IDs
				sessionCategoryMap = {}
				for i = 1, #values do
					local option = values[i].optionText
					local key = Game.GetLocalizedText(option)
					local ids = buckets[key]
					if ids and #ids > 0 then
						sessionCategoryMap[i] = table.remove(ids, 1)
					else
						handleError(("Unresolved Category label: %s at index %d"):format(key or "<nil>", i))
					end
				end

				-- Apply user overrides to values
				local overrides = mod.utility.loadUserSettings() or {}
				local categoryOverrides = overrides.categories or {}
				for i = 1, #values do
					local id = sessionCategoryMap and sessionCategoryMap[i]
					if id then
						local override = categoryOverrides[id]
						local name = override and override.customName and trim(override.customName)
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
