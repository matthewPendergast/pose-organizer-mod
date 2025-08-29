local Controller = {}

-- Injected References --

local poseCategories, posesByCategory, poseDataModel, utility

-- Cache --

local overridesCache = {
	categories = {},
	poses = {}
}

-- Module Functions --

---@param context table
function Controller.init(context)
	poseCategories = context.poseCategories
	posesByCategory = context.posesByCategory
	poseDataModel = context.poseDataModel
	utility = context.utility
	overridesCache = context.utility.loadUserSettings()
end

function Controller.getOverrides()
	return overridesCache
end

---@param overrides table
function Controller.applyUserOverrides(overrides)
	overridesCache = overrides
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
function Controller.handleCategoryRename(selectedCategoryID, newDisplayName)
	utility.exportUserSettings({
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

	overridesCache.categories[selectedCategoryID] = {
		customName = newDisplayName
	}

	poseDataModel.categories[selectedCategoryID] = newDisplayName
end

---@param selectedPoseID string
---@param newDisplayName string
function Controller.handlePoseRename(selectedPoseID, newDisplayName)
	utility.exportUserSettings({
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

	overridesCache.poses[selectedPoseID] = {
		customName = newDisplayName
	}
end

function Controller.handleExportRequest()
	return utility.exportPoseDataModel(poseDataModel)
end

return Controller
