----------------------------------------------------------------
-- PoseOrganizer
-- Author: Matthew Pendergast
-- Brief: Organize & rename custom Photo Mode poses by category.
----------------------------------------------------------------

-- Constants
local MOD_NAME = "PoseOrganizer"

-- Mod State
local module = {
	data = require("modules/data.lua")
}

-- CET State
local isOverlayVisible = false

-- Internal Data
local poseCategories = {}
local posesByCategory = {}
local currPoseList = {}

-- ImGui
local windowMinWidth = 300
local windowMinHeight = 150
local comboCategoryIndex = 0
local lastCategoryIndex = -1
local comboPoseIndex = 0

-- Localization
local localizable = {
	imgui = {
		categoryLabel = "Category",
		poseLabel = "Pose"
	}
}

-- Event Handlers
registerForEvent("onOverlayOpen", function()
	isOverlayVisible = true
end)

registerForEvent("onOverlayClose", function()
	isOverlayVisible = false
end)

registerForEvent("onInit", function()
	local poseCategoryFlat = TweakDB:GetFlat(module.data.TweakDB.categoryFlat)
	for _, category in ipairs(poseCategoryFlat) do
		local localizedCategoryName = Game.GetLocalizedText(TweakDB:GetRecord(category):DisplayName().value)
		table.insert(poseCategories, localizedCategoryName)
	end

	local poseFlat = TweakDB:GetFlat(module.data.TweakDB.poseFlat)
	for _, pose in ipairs(poseFlat) do
		local poseRecord = TweakDB:GetRecord(pose)
		local categoryRecord = TweakDB:GetRecord(poseRecord:Category().value)
		local localizedCategoryName = Game.GetLocalizedText(categoryRecord:DisplayName().value)
		local localizedPoseName = Game.GetLocalizedText(poseRecord:DisplayName().value)

		if not posesByCategory[localizedCategoryName] then
			posesByCategory[localizedCategoryName] = {}
		end

		table.insert(posesByCategory[localizedCategoryName], {
			id = pose,
			displayName = localizedPoseName
		})
	end
end)

registerForEvent("onDraw", function()
	if not isOverlayVisible then
		return
	end

	ImGui.PushStyleVar(ImGuiStyleVar.WindowMinSize, windowMinWidth, windowMinHeight)

	if not ImGui.Begin(MOD_NAME) then
		ImGui.End()
		return
	end

	ImGui.Separator()

	-- Category Combo
	comboCategoryIndex = ImGui.Combo(
		localizable.imgui.categoryLabel, comboCategoryIndex, poseCategories, #poseCategories
	)

	if comboCategoryIndex ~= lastCategoryIndex then
		local newCategory = poseCategories[comboCategoryIndex + 1]
		local newPoses = posesByCategory[newCategory]
		for index, pose in ipairs(newPoses) do
			currPoseList[index] = pose.displayName
		end
		lastCategoryIndex = comboCategoryIndex
	end

	-- Pose Combo
	comboPoseIndex = ImGui.Combo(
		localizable.imgui.poseLabel, comboPoseIndex, currPoseList, #currPoseList
	)

	ImGui.End()
end)
