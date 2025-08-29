local Model = {}

--- Local Functions --

---@param data table
---@param poseCategories table
---@param poseDataModel table
local function buildCategories(data, poseCategories, poseDataModel)
	local flat = TweakDB:GetFlat(data.tweakDB.categoryFlat)
	for _, id in ipairs(flat) do
		local record = TweakDB:GetRecord(id)
		if record then
			local name = Game.GetLocalizedText(record:DisplayName().value)
			table.insert(poseCategories, {
				internalName = id,
				displayName = name
			})
			poseDataModel.categories[id] = name
		end
	end
end

---@param data table
---@param posesByCategory table
---@param poseDataModel table
local function buildPoses(data, posesByCategory, poseDataModel)
	local flat = TweakDB:GetFlat(data.tweakDB.poseFlat)
	for _, id in ipairs(flat) do
		local poseRecord = TweakDB:GetRecord(id)
		if poseRecord then
			local category = poseRecord:Category().value
			local categoryRecord = TweakDB:GetRecord(category)
			if categoryRecord then
				local name = Game.GetLocalizedText(poseRecord:DisplayName().value)

				if not posesByCategory[category] then
					posesByCategory[category] = {}
				end

				table.insert(posesByCategory[category], {
					internalName = id,
					displayName = name
				})

				poseDataModel.poses[id] = {
					category    = category,
					displayName = name,
				}
			end
		end
	end
end

-- Module Functions --

---@param data table
function Model.build(data)
	local poseCategories = {}
	local posesByCategory = {}
	local poseDataModel = {
		categories = {},
		poses = {}
	}

	buildCategories(data, poseCategories, poseDataModel)
	buildPoses(data, posesByCategory, poseDataModel)

	return poseCategories, posesByCategory, poseDataModel
end

return Model
