local Interface = {}

-- Config --

local WINDOW_MIN_WIDTH = 400
local WINDOW_MIN_HEIGHT = 200
local TEXT_INPUT_LIMIT = 256

-- State --

local comboCategoryIndex = 0
local lastCategoryIndex = -1
local comboPoseIndex = 0
local inputCategoryRename = ""
local inputPoseRename = ""
local isDebugActive = false

-- Caches --

local localization = {}
local categoryNames, categoryIDs = {}, {}
local currPoseNames, currPoseIDs = {}, {}

-- Misc --

local callbacks = {
	handleCategoryRename = nil,
	handlePoseRename = nil,
	handleExportRequest = nil
}

-- Subviews --

---@param labels table
---@param poseCategories table
---@param posesByCategory table
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

---@param labels table
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

-- Interface Controls --

local function closeInterface()
	ImGui.End()
	ImGui.PopStyleVar()
end

-- Module Functions --

---@param context table
function Interface.init(context)
	localization = context.localization
	callbacks.handleCategoryRename = context.handleCategoryRename
	callbacks.handlePoseRename = context.handlePoseRename
	callbacks.handleExportRequest = context.handleExportRequest
	isDebugActive = context.isDebugActive
	return true
end

---@param poseCategories table
---@param posesByCategory table
function Interface.draw(poseCategories, posesByCategory)
	ImGui.PushStyleVar(ImGuiStyleVar.WindowMinSize, WINDOW_MIN_WIDTH, WINDOW_MIN_HEIGHT)

	if not ImGui.Begin(localization.modName) then
		closeInterface()
		return
	end

	ImGui.Separator()

	drawCategoryCombo(localization.imgui, poseCategories, posesByCategory)
	drawPoseCombo(localization.imgui)

	ImGui.Separator()

	inputCategoryRename = ImGui.InputText("##CategoryRename", inputCategoryRename, TEXT_INPUT_LIMIT)
	ImGui.SameLine()
	if ImGui.Button(localization.imgui.renameCategoryBtn) then
		local selectedCategoryID = categoryIDs[comboCategoryIndex + 1]
		local newName = (inputCategoryRename or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if newName ~= "" and selectedCategoryID and callbacks.handleCategoryRename then
			callbacks.handleCategoryRename(selectedCategoryID, newName)
			categoryNames[comboCategoryIndex + 1] = newName
			inputCategoryRename = ""
		end
	end

	inputPoseRename = ImGui.InputText("##PoseRename", inputPoseRename, TEXT_INPUT_LIMIT)
	ImGui.SameLine()
	if ImGui.Button(localization.imgui.renamePoseBtn) then
		local selectedPoseID = currPoseIDs[comboPoseIndex + 1]
		local newName = (inputPoseRename or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if newName ~= "" and selectedPoseID and callbacks.handlePoseRename then
			callbacks.handlePoseRename(selectedPoseID, newName)
			if currPoseNames[comboPoseIndex + 1] then
				currPoseNames[comboPoseIndex + 1] = newName
			end
			inputPoseRename = ""
		end
	end

	if isDebugActive then
		if ImGui.Button("Export Model") then
			callbacks.handleExportRequest()
		end
	end

	closeInterface()
end

return Interface
