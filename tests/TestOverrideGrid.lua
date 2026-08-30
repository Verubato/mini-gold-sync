-- The character override grid on the settings panel, and the section that sits below it.

local fw = require("TestFramework")
local harness = require("AddonHarness")
local WowMock = require("WowMock")

local ROW_HEIGHT = 26
local THREE_OVERRIDES = {
	{ CharacterName = "Alt-Realm", Order = 1, Gold = 100, Ignore = false },
	{ CharacterName = "Bank-Realm", Order = 2, Gold = 200, Ignore = false },
	{ CharacterName = "Main-Realm", Order = 3, Gold = 300, Ignore = false },
}

---Logs in with the given overrides already saved, then opens the settings so the grid builds.
---@param overrides table
---@return table context
local function OpenSettingsWith(overrides)
	local context = harness.Load("MiniGoldSync")

	_G.MiniGoldSyncDB = { Overrides = overrides }

	harness.Login(context)

	for _, name in ipairs(WowMock.SlashCommands()) do
		_G.SlashCmdList[name]("")
	end

	return context
end

---@param frame table
---@param text string
---@return boolean
local function IsRule(frame, text)
	return frame and frame.Label ~= nil and frame.Label.GetText ~= nil and frame.Label:GetText() == text
end

---The grid container is a local, so a test finds it as the frame the misc rule hangs beneath.
---@return table?
local function FindGridContainer()
	for _, frame in ipairs(WowMock.Frames) do
		if IsRule(frame, "MISC") then
			local _, relativeTo = frame:GetPoint()

			return relativeTo
		end
	end
end

fw.describe("MiniGoldSync - the override grid", function()
	fw.it("is one row tall when there is nothing to override", function()
		OpenSettingsWith({})

		local container = FindGridContainer()

		fw.not_nil(container, "the grid container above the misc rule")
		fw.eq(container:GetHeight(), ROW_HEIGHT, "one row of height")
	end)

	fw.it("grows a row for every override", function()
		OpenSettingsWith(THREE_OVERRIDES)

		fw.eq(FindGridContainer():GetHeight(), 3 * ROW_HEIGHT, "three rows of height")
	end)
end)

fw.describe("MiniGoldSync - the scroll child", function()
	fw.it("stays at the settings height with a single row", function()
		local context = OpenSettingsWith({})
		local _, minimum = context.Addon.Framework:SettingsSize()

		fw.eq(FindGridContainer():GetParent():GetHeight(), minimum, "nothing to scroll")
	end)

	fw.it("grows by every row past the first, so the misc section stays reachable", function()
		local context = OpenSettingsWith(THREE_OVERRIDES)
		local _, minimum = context.Addon.Framework:SettingsSize()

		fw.eq(FindGridContainer():GetParent():GetHeight(), minimum + 2 * ROW_HEIGHT, "two rows of scroll")
	end)
end)
