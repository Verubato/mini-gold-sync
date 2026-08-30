-- Loads the whole addon into a mocked client and drives it through login.
-- The shared body lives in build/Lua/SmokeTest.lua.

local fw = require("TestFramework")
local smoke = require("SmokeTest")
local WowMock = require("WowMock")

---The section rule is built by the framework and never handed back to the addon, so a test
---finds it the way a player sees it, by its label.
---@param text string
---@return boolean
local function HasDivider(text)
	for _, frame in ipairs(WowMock.Frames) do
		if frame.Label and frame.Label.GetText and frame.Label:GetText() == text then
			return true
		end
	end

	return false
end

---The confirmation dialog is a frame the framework owns, so a test reaches it by its button label.
---@param label string
---@return table?
local function FindButton(label)
	for _, frame in ipairs(WowMock.Frames) do
		if frame.GetText and frame:GetText() == label and frame.Click then
			return frame
		end
	end

	return nil
end

---The desired gold box is the only edit box in the addon with a tooltip, so that is how a
---test finds it without a handle back from Config.lua.
---@return table?
local function FindDesiredGoldEditBox()
	for _, frame in ipairs(WowMock.Frames) do
		if frame.__objectType == "EditBox" and frame.GetScript and frame:GetScript("OnEnter") then
			return frame
		end
	end

	return nil
end

smoke.Run("MiniGoldSync", {
	extra = function(context)
		fw.eq(context.Addon.Framework.CustomStyling, true, "custom styling on")
		fw.eq(context.Addon.Framework.CustomStylingOverrides.Button, false, "stock buttons")
		fw.truthy(HasDivider("SETTINGS"), "the settings section rule under the header")
		fw.truthy(HasDivider("CHARACTER OVERRIDES"), "the character overrides section rule")

		local goldBox = FindDesiredGoldEditBox()
		fw.not_nil(goldBox, "the desired gold edit box")

		local _, _, _, x = goldBox:GetPoint()
		-- The flattened field's border draws 6px left of the box's own frame, so anything
		-- smaller pokes past the panel's edge and gets clipped by the scroll frame.
		fw.truthy(x >= 6, "the desired gold box clears the flattened border's left overhang")

		local db = _G["MiniGoldSyncDB"]
		db.PrintMessages = false
		db.DesiredGold = 999

		local resetBtn = FindButton("Reset to Defaults")
		fw.not_nil(resetBtn, "reset button exists")
		resetBtn:Click()

		local confirmAccept = FindButton("Reset")
		fw.not_nil(confirmAccept, "the confirmation dialog opened")
		confirmAccept:Click()

		fw.eq(db.PrintMessages, true, "reset restored PrintMessages")
		fw.eq(db.DesiredGold, 0, "reset restored DesiredGold")
	end,
})
