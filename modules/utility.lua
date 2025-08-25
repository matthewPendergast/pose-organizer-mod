-- Config --

local USER_SETTINGS = "user-settings.json"
local DATA_MODEL_PATH = "pose-data-model.json"

-- Private Functions --

local function mergeMap(existingMap, updatesMap)
	if not updatesMap then
		return
	end
	for ID, newEntry in pairs(updatesMap) do
		local existingEntry = existingMap[ID]
		if not existingEntry then
			existingMap[ID] = newEntry
		else
			for k, v in pairs(newEntry) do
				existingEntry[k] = v
			end
		end
	end
end

-- Export Functions --

local function loadUserSettings()
	local file = io.open(USER_SETTINGS, "r")
	if not file then
		return {
			categories = {},
			poses = {}
		}
	end
	local contents = file:read("*a")
	file:close()
	return json.decode(contents)
end

local function exportUserSettings(newSettings)
	local currSettings = loadUserSettings()
	currSettings.categories = currSettings.categories or {}
	currSettings.poses = currSettings.poses or {}

	mergeMap(currSettings.categories, newSettings.categories)
	mergeMap(currSettings.poses, newSettings.poses)

	local file = io.open(USER_SETTINGS, "w")
	if not file then
		return false
	end
	file:write(json.encode(currSettings))
	file:close()
	return true
end

local function exportPoseDataModel(poseDataModel)
	local jsonText = json.encode(poseDataModel)
	local file = io.open(DATA_MODEL_PATH, "w")
	if not file then
		return false
	end
	file:write(jsonText)
	file:close()
	return true
end

return {
	loadUserSettings = loadUserSettings,
	exportUserSettings = exportUserSettings,
	exportPoseDataModel = exportPoseDataModel,
}
