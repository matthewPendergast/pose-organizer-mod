-- Config --
local windowMinWidth = 300
local windowMinHeight = 150

-- State --
local comboCategoryIndex = 0
local lastCategoryIndex = -1
local comboPoseIndex = 0
local inputCategoryRename = ""
local inputPoseRename = ""

-- UI Caches --

local localization = {}
local categoryNames, categoryIds = {}, {}
local currPoseNames, currPoseIds = {}, {}

-- Misc --

local callbacks = {
	requestExport = nil
}

-- Subviews --

local function drawCategoryCombo(labels, poseCategories, posesByCategory)
	-- Rebuild category arrays
	categoryNames, categoryIds = {}, {}
	for i, category in ipairs(poseCategories) do
		categoryNames[i] = category.displayName
		categoryIds[i] = category.internalName
	end

	comboCategoryIndex = ImGui.Combo(
		labels.categoryLabel, comboCategoryIndex, categoryNames, #categoryNames
	)

	-- Rebuild pose arrays if category changes
	if comboCategoryIndex ~= lastCategoryIndex then
		local newCategory = categoryIds[comboCategoryIndex + 1]
		local newPoses = posesByCategory[newCategory] or {}
		currPoseNames, currPoseIds = {}, {}
		for index, pose in ipairs(newPoses) do
			currPoseNames[index] = pose.displayName
			currPoseIds[index] = pose.internalName
		end
		comboPoseIndex = 0
		lastCategoryIndex = comboCategoryIndex
	end
end

local function drawPoseCombo(labels)
	local isComboDisabled = #currPoseNames <= 0
	if isComboDisabled then
		currPoseNames = { labels.emptyPoseList }
		ImGui.BeginDisabled()
	end

	comboPoseIndex = ImGui.Combo(
		labels.poseLabel, comboPoseIndex, currPoseNames, #currPoseNames
	)

	if isComboDisabled then
		ImGui.EndDisabled()
		comboPoseIndex = 0
	end
end

-- Interface controls --

local function closeInterface()
	ImGui.End()
	ImGui.PopStyleVar()
end

-- Export functions --

---@param localizationModule table
local function initializeInterface(localizationModule, handleExportRequest)
	localization = localizationModule
	callbacks.requestExport = handleExportRequest
	return true
end

local function drawInterface(poseCategories, posesByCategory)
	ImGui.PushStyleVar(ImGuiStyleVar.WindowMinSize, windowMinWidth, windowMinHeight)

	if not ImGui.Begin(localization.modName) then
		closeInterface()
		return
	end

	ImGui.Separator()

	drawCategoryCombo(localization.imgui, poseCategories, posesByCategory)
	drawPoseCombo(localization.imgui)

	ImGui.Separator()

	inputCategoryRename = ImGui.InputText("##CategoryRename", inputCategoryRename, 256)
	ImGui.SameLine()
	if ImGui.Button("Rename Category") then
		--TODO
	end

	inputPoseRename = ImGui.InputText("##PoseRename", inputPoseRename, 256)
	ImGui.SameLine()
	if ImGui.Button("Rename Pose") then
		--TODO
	end

	if ImGui.Button("Export") then
		callbacks.requestExport()
	end

	closeInterface()
end

return {
	initializeInterface = initializeInterface,
	drawInterface = drawInterface
}
