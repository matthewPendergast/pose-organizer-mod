local path = "user-settings.json"

local function loadUserSettings()
	local file = io.open(path, "r")
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

local function mergeMap(existingMap, updatesMap)
	if not updatesMap then
		return
	end
	for id, newEntry in pairs(updatesMap) do
		local existingEntry = existingMap[id]
		if not existingEntry then
			existingMap[id] = newEntry
		else
			for index, value in pairs(newEntry) do
				existingEntry[index] = value
			end
		end
	end
end

local function exportUserSettings(newSettings)
	local currSettings = loadUserSettings()
	currSettings.categories = currSettings.categories or {}
	currSettings.poses = currSettings.poses or {}

	mergeMap(currSettings.categories, newSettings.categories)
	mergeMap(currSettings.poses, newSettings.poses)

	local file = io.open(path, "w")
	if not file then
		return false
	end
	file:write(json.encode(currSettings))
	file:close()
	return true
end

local function exportPoseDataModel(poseDataModel)
	local jsonText = json.encode(poseDataModel)
	local file = io.open(path, "w")
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
