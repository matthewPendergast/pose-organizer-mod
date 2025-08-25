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
local categoryNames, categoryIDs = {}, {}
local currPoseNames, currPoseIDs = {}, {}

-- Misc --

local callbacks = {
	handleRename = nil,
	handleExportRequest = nil
}

-- Subviews --

local function drawCategoryCombo(labels, poseCategories, posesByCategory)
	-- Rebuild category arrays
	categoryNames, categoryIDs = {}, {}
	for i, category in ipairs(poseCategories) do
		categoryNames[i] = category.displayName
		categoryIDs[i] = category.internalName
	end

	comboCategoryIndex = ImGui.Combo(
		labels.categoryLabel, comboCategoryIndex, categoryNames, #categoryNames
	)

	-- Rebuild pose arrays if category changes
	if comboCategoryIndex ~= lastCategoryIndex then
		local newCategory = categoryIDs[comboCategoryIndex + 1]
		local newPoses = posesByCategory[newCategory] or {}
		currPoseNames, currPoseIDs = {}, {}
		for i, pose in ipairs(newPoses) do
			currPoseNames[i] = pose.displayName
			currPoseIDs[i] = pose.internalName
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
local function initializeInterface(localizationModule, handleRename, handleExportRequest)
	localization = localizationModule
	callbacks.handleRename = handleRename
	callbacks.handleExportRequest = handleExportRequest
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
	if ImGui.Button(localization.imgui.renameCategoryBtn) then
		local selectedCategoryID = categoryIDs[comboCategoryIndex + 1]
		local route = "category"
		inputCategoryRename = callbacks.handleRename(
			inputCategoryRename,
			selectedCategoryID,
			route,
			function(newName)
				categoryNames[comboCategoryIndex + 1] = newName
			end
		)
	end

	inputPoseRename = ImGui.InputText("##PoseRename", inputPoseRename, 256)
	ImGui.SameLine()
	if ImGui.Button(localization.imgui.renamePoseBtn) then
		local selectedPoseID = currPoseIDs[comboPoseIndex + 1]
		local route = "pose"
		inputPoseRename = callbacks.handleRename(
			inputPoseRename,
			selectedPoseID,
			route,
			function(newName)
				if currPoseNames[comboPoseIndex + 1] then
					currPoseNames[comboPoseIndex + 1] = newName
				end
			end
		)
	end

	if ImGui.Button("Export (development only)") then
		callbacks.handleExportRequest()
	end

	closeInterface()
end

return {
	initializeInterface = initializeInterface,
	drawInterface = drawInterface
}
