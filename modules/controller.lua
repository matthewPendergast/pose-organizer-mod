local Controller = {}

-- Injected References --

local poseCategories, posesByCategory, poseDataModel, utility

-- Cache --

local overridesCache = {
	categories = {},
	poses = {}
}

-- Helper Functions --

local function ensureOverridesShape()
	overridesCache = overridesCache or {}
	overridesCache.categories = overridesCache.categories or {}
	overridesCache.poses = overridesCache.poses or {}
end

-- Module Functions --

---@param context table
function Controller.init(context)
	poseCategories = context.poseCategories
	posesByCategory = context.posesByCategory
	poseDataModel = context.poseDataModel
	utility = context.utility
	overridesCache = context.utility.loadUserSettings()
	ensureOverridesShape()
end

function Controller.getUIPoseMap()
	local map = {}

	for categoryID, _list in pairs(posesByCategory) do
		map[categoryID] = {}
	end

	for categoryID, list in pairs(posesByCategory) do
		for _, entry in ipairs(list) do
			local poseID = entry.internalName
			local override = overridesCache.poses[poseID]
			local targetCategory = (override and override.newCategory) or
				(poseDataModel.poses[poseID] and poseDataModel.poses[poseID].category) or categoryID
			map[targetCategory] = map[targetCategory] or {}
			table.insert(map[targetCategory], entry)
		end
	end

	return map
end

function Controller.getOverrides()
	return overridesCache
end

---@param overrides table
function Controller.applyUserOverrides(overrides)
	overridesCache = overrides
	ensureOverridesShape()
	for categoryID, entry in pairs(overrides.categories) do
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

	for poseID, entry in pairs(overrides.poses) do
		local info = poseDataModel.poses[poseID]
		if info then
			if entry.customName then
				info.displayName = entry.customName
				local list = posesByCategory[info.category]
				if list then
					for _, pose in ipairs(list) do
						if pose.internalName == poseID then
							pose.displayName = entry.customName
							break
						end
					end
				end
			end
			if entry.newCategory and entry.newCategory ~= "" then
				info.category = entry.newCategory
			end
		end
	end
end

---@param poseID string
---@param categoryID string
function Controller.applyPoseCategoryPatch(poseID, categoryID)
	if not poseID or not categoryID or categoryID == "" then
		return false
	end

	local poseRec = poseID:find("^PhotoModePoses%.") and poseID or ("PhotoModePoses." .. poseID)
	local categoryRec = categoryID:find("^PhotoModePoseCategories%.") and categoryID or
		("PhotoModePoseCategories." .. categoryID)

	local flatPath = poseRec .. ".category"
	local ok = TweakDB:SetFlat(flatPath, categoryRec)

	return ok
end

---@param overridesOpt table
function Controller.applyAllPoseCategoryPatches(overridesOpt)
	local srcPoses = (overridesOpt and overridesOpt.poses) or overridesCache.poses
	if not srcPoses then return end

	for poseID, entry in pairs(srcPoses) do
		local category = entry and entry.newCategory
		if category and category ~= "" then
			Controller.applyPoseCategoryPatch(poseID, category)
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

	poseDataModel.categories[selectedCategoryID] = newDisplayName

	for _, entry in ipairs(poseCategories) do
		if entry.internalName == selectedCategoryID then
			entry.displayName = newDisplayName
			break
		end
	end

	overridesCache.categories[selectedCategoryID] = {
		customName = newDisplayName
	}
end

---@param selectedPoseID string
---@param newDisplayName string
function Controller.handlePoseRename(selectedPoseID, newDisplayName)
	utility.exportUserSettings({
		poses = {
			[selectedPoseID] = { customName = newDisplayName }
		}
	})

	local pose = overridesCache.poses[selectedPoseID] or {}
	pose.customName = newDisplayName
	overridesCache.poses[selectedPoseID] = pose

	local info = poseDataModel.poses[selectedPoseID]
	if info then
		info.displayName = newDisplayName
		for _, list in pairs(posesByCategory) do
			for _, entry in ipairs(list) do
				if entry.internalName == selectedPoseID then
					entry.displayName = newDisplayName
				end
			end
		end
	end
end

---@param selectedPoseID string
---@param newCategoryID string
function Controller.handlePoseReassign(selectedPoseID, newCategoryID)
	if not selectedPoseID or not newCategoryID then return end

	utility.exportUserSettings({
		poses = { [selectedPoseID] = { newCategory = newCategoryID } }
	})
	overridesCache.poses[selectedPoseID] = overridesCache.poses[selectedPoseID] or {}
	overridesCache.poses[selectedPoseID].newCategory = newCategoryID

	if poseDataModel.poses[selectedPoseID] then
		poseDataModel.poses[selectedPoseID].category = newCategoryID
	end

	Controller.applyPoseCategoryPatch(selectedPoseID, newCategoryID)
end

function Controller.handleExportRequest()
	return utility.exportPoseDataModel(poseDataModel)
end

return Controller
