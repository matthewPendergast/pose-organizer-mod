local Utility = {}

-- Config --

local USER_OVERRIDES_PATH = "user/user-overrides.json"
local DATA_MODEL_PATH = "user/pose-data-model.json"

-- Local Functions --

---@param existingMap table
---@param updatesMap table
local function mergeMap(existingMap, updatesMap)
	if not updatesMap then
		return
	end
	for id, newEntry in pairs(updatesMap) do
		local existingEntry = existingMap[id]
		if not existingEntry then
			existingMap[id] = newEntry
		else
			for k, v in pairs(newEntry) do
				existingEntry[k] = v
			end
		end
	end
end

-- Module Functions --

function Utility.loadUserSettings()
	local file = io.open(USER_OVERRIDES_PATH, "r")
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

---@param newSettings table
function Utility.exportUserSettings(newSettings)
	local currSettings = Utility.loadUserSettings()
	currSettings.categories = currSettings.categories or {}
	currSettings.poses = currSettings.poses or {}

	mergeMap(currSettings.categories, newSettings.categories)
	mergeMap(currSettings.poses, newSettings.poses)

	local file = io.open(USER_OVERRIDES_PATH, "w")
	if not file then
		return false
	end
	file:write(json.encode(currSettings))
	file:close()
	return true
end

---@param poseDataModel table
function Utility.exportPoseDataModel(poseDataModel)
	local jsonText = json.encode(poseDataModel)
	local file = io.open(DATA_MODEL_PATH, "w")
	if not file then
		return false
	end
	file:write(jsonText)
	file:close()
	return true
end

return Utility
