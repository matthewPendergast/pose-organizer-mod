local Hooks = {}

-- Injected References --

local poseCategories, posesByCategory, controller, handleError

-- State --

local lastCategoryID = nil
local categoryGroupsTemplate = nil
local sessionCategoryMap = nil
local poseGroupsTemplate = nil
local sessionPoseMap = nil
local isDebugActive = false

-- Helper Functions --

---@param s string
local function trim(s)
	return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function copyQueue(src)
	local data = {}
	for i = 1, #src do
		data[i] = src[i]
	end
	return { data = data, head = 1 }
end

local function queuePop(q)
	if q and q.head <= #q.data then
		local v = q.data[q.head]
		q.head = q.head + 1
		return v
	end
end

-- Export Functions --

---@param context table
function Hooks.init(context)
	poseCategories = context.poseCategories
	posesByCategory = context.posesByCategory
	controller = context.controller
	handleError = context.handleError
	isDebugActive = context.isDebugActive
end

---@param attributeValue integer
function Hooks.updateSelectedCategory(attributeValue)
	if sessionCategoryMap then
		lastCategoryID = sessionCategoryMap[attributeValue + 1]
	end
end

---@param values PhotoModeOptionSelectorData[]
function Hooks.applyCategoryOverrides(values)
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
		categoryGroups[k] = copyQueue(v)
	end
	-- Map UI values to IDs for referencing changes
	sessionCategoryMap = {}
	for i = 1, #values do
		local key = values[i].optionText
		local id = queuePop(categoryGroups[key])
		if id then
			sessionCategoryMap[i] = id
		else
			if isDebugActive then
				handleError(("Unresolved Category label: %s at index %d"):format(key or "<nil>", i))
			end
		end
	end
	-- Apply user overrides to in-game UI display values
	local overrides = controller.getOverrides() or {}
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

---@param values PhotoModeOptionSelectorData[]
function Hooks.applyPoseOverrides(values)
	local activeCategoryID = lastCategoryID
	if not activeCategoryID then
		if sessionCategoryMap then
			activeCategoryID = sessionCategoryMap[1]
		else
			return
		end
	end
	-- Initial setup for pose groups template
	if not poseGroupsTemplate then
		poseGroupsTemplate = {}
	end
	if not poseGroupsTemplate[activeCategoryID] then
		local poseMap = {}
		local currPoses = posesByCategory[activeCategoryID] or {}
		for _, pose in ipairs(currPoses) do
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
		poseGroups[k] = copyQueue(v)
	end
	-- Map UI values to IDs for referencing changes
	sessionPoseMap = {}
	for i = 1, #values do
		local key = values[i].optionText
		local id = queuePop(poseGroups[key])
		if id then
			sessionPoseMap[i] = id
		else
			if isDebugActive then
				handleError(("Unresolved Pose label: %s at index %d"):format(key or "<nil>", i))
			end
		end
	end
	-- Apply user overrides to in-game UI display values
	local overrides = controller.getOverrides() or {}
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

return Hooks
