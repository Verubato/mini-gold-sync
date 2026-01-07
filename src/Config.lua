local addonName, addon = ...
---@type MiniFramework
local mini = addon.Framework
local verticalSpacing = 20
local db
---@class Db
local dbDefaults = {
	PrintMessages = true,
	DesiredGold = 0,
	---@type Override[]
	Overrides = {},
}
local M = {}
addon.Config = M

local function CreateDesiredGoldInput(parent, anchor, xOffset, yOffset)
	local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", xOffset, yOffset)
	label:SetText("Desired Gold")

	local editBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
	editBox:SetSize(120, 20)
	editBox:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 4, -8)
	editBox:SetAutoFocus(false)
	editBox:SetNumeric(true)
	editBox:SetMaxLetters(12)
	editBox:SetText(tostring(db.DesiredGold or 0))
	editBox:SetCursorPosition(0)

	editBox:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()

		local value = tonumber(self:GetText()) or 0
		value = math.max(0, value)

		db.DesiredGold = value
		self:SetText(value)
	end)

	editBox:SetScript("OnEditFocusLost", function(self)
		local value = tonumber(self:GetText()) or 0
		value = math.max(0, value)

		db.DesiredGold = value
		self:SetText(value)
	end)

	editBox:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine("Desired Gold", 1, 1, 1)
		GameTooltip:AddLine("Enter the amount of gold you want to reach.", 0.8, 0.8, 0.8)
		GameTooltip:Show()
	end)

	editBox:SetScript("OnLeave", GameTooltip_Hide)

	return editBox, label
end

local function CreateRow(parent, y)
	local rowFrame = CreateFrame("Frame", nil, parent)
	rowFrame:SetSize(650, 24)
	rowFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)

	local removeBtn = CreateFrame("Button", nil, rowFrame, "UIPanelCloseButton")
	removeBtn:SetSize(24, 24)
	removeBtn:SetPoint("LEFT", rowFrame, "LEFT", 0, 0)

	local ignore = CreateFrame("CheckButton", nil, rowFrame, "UICheckButtonTemplate")
	ignore:SetSize(24, 24)
	ignore:SetPoint("LEFT", removeBtn, "RIGHT", 4, 0)

	local nameBox = CreateFrame("EditBox", nil, rowFrame, "InputBoxTemplate")
	nameBox:SetSize(220, 20)
	nameBox:SetPoint("LEFT", ignore, "RIGHT", 6, 0)
	nameBox:SetAutoFocus(false)
	nameBox:SetMaxLetters(24)

	local goldBox = CreateFrame("EditBox", nil, rowFrame, "InputBoxTemplate")
	goldBox:SetSize(120, 20)
	goldBox:SetPoint("LEFT", nameBox, "RIGHT", 12, 0)
	goldBox:SetAutoFocus(false)
	goldBox:SetNumeric(true)
	goldBox:SetMaxLetters(12)

	rowFrame.RemoveButton = removeBtn
	rowFrame.IgnoreCheck = ignore
	rowFrame.NameBox = nameBox
	rowFrame.GoldBox = goldBox

	return rowFrame
end

local function CreateOverrideGrid(parent, anchor, xOffset, yOffset)
	local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", xOffset, yOffset)
	title:SetText("Character Overrides")

	local lines = {
		"A list of gold amounts per character to use instead of the default desired gold amount.",
		"You can also ignore characters entirely from the gold sync process.",
		"It's recommended (but not required) to include the server name for each character.",
	}

	anchor = title

	for i = 1, #lines do
		local description = parent:CreateFontString(nil, "ARTWORK", "GameFontWhite")
		description:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -8)
		description:SetText(lines[i])

		anchor = description
	end

	local headerIgnore = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	headerIgnore:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 30, -verticalSpacing)
	headerIgnore:SetText("Ignore")

	local headerName = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	headerName:SetPoint("LEFT", headerIgnore, "LEFT", 44, 0)
	headerName:SetText("Character Name")

	local headerGold = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	headerGold:SetPoint("LEFT", headerName, "LEFT", 232, 0)
	headerGold:SetText("Override Gold")

	local container = CreateFrame("Frame", nil, parent)
	container:SetPoint("TOPLEFT", headerIgnore, "BOTTOMLEFT", -30, -6)
	container:SetSize(620, 220)

	local addBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	addBtn:SetSize(90, 22)
	addBtn:SetText("Add")

	local rows = {}
	local rowHeight = 26

	local function EnsureAtLeastOneRow()
		if type(db.Overrides) ~= "table" then
			db.Overrides = {}
		end

		if #db.Overrides == 0 then
			db.Overrides[1] = { CharacterName = "", Order = 1, Gold = 0, Ignore = false }
		end
	end

	local function NormalizeOrder()
		table.sort(db.Overrides, function(left, right)
			local leftOrder = tonumber(left and left.Order) or 0
			local rightOrder = tonumber(right and right.Order) or 0
			return leftOrder < rightOrder
		end)

		-- Normalize to 1..n so adds/removes remain predictable
		for i = 1, #db.Overrides do
			db.Overrides[i].Order = i
		end
	end

	local function GetMaxOrder()
		-- After NormalizeOrder, max order is just #db.Overrides,
		-- but keep this safe anyway.
		local maxOrder = 0
		for i = 1, #db.Overrides do
			local o = tonumber(db.Overrides[i] and db.Overrides[i].Order) or 0
			if o > maxOrder then
				maxOrder = o
			end
		end
		return maxOrder
	end

	local function CommitRow(i)
		local row = rows[i]
		if not row then
			return
		end

		local entry = db.Overrides[i]
		if not entry then
			return
		end

		local name = (row.NameBox:GetText() or ""):gsub("^%s+", ""):gsub("%s+$", "")
		local gold = math.max(0, tonumber(row.GoldBox:GetText()) or 0)
		local ignore = row.IgnoreCheck:GetChecked() and true or false

		entry.CharacterName = name
		entry.Gold = gold
		entry.Ignore = ignore

		row.NameBox:SetText(name)
		row.GoldBox:SetText(tostring(gold))
		row.GoldBox:SetCursorPosition(0)
	end

	local function RefreshRow(i)
		local row = rows[i]
		local entry = db.Overrides[i]
		if not row or not entry then
			return
		end

		-- keep checkbox in sync (CommitRow already set entry.Ignore, but this is harmless)
		row.IgnoreCheck:SetChecked(entry.Ignore == true)

		local ignored = entry.Ignore == true
		row.GoldBox:SetEnabled(not ignored)
		row.GoldBox:SetAlpha(ignored and 0.5 or 1)
	end

	local function Refresh()
		EnsureAtLeastOneRow()
		NormalizeOrder()

		-- hide extra rows
		for i = #db.Overrides + 1, #rows do
			rows[i]:Hide()
		end

		for i = 1, #db.Overrides do
			local entry = db.Overrides[i]

			if not rows[i] then
				rows[i] = CreateRow(container, -((i - 1) * rowHeight))
			end

			local row = rows[i]
			row:Show()

			row.NameBox:SetText(entry.CharacterName or "")
			row.NameBox:SetCursorPosition(0)

			row.GoldBox:SetText(tostring(tonumber(entry.Gold) or 0))
			row.GoldBox:SetCursorPosition(0)

			row.NameBox:SetScript("OnEnterPressed", function(self)
				self:ClearFocus()
				CommitRow(i)
			end)
			row.NameBox:SetScript("OnEditFocusLost", function()
				CommitRow(i)
			end)

			row.GoldBox:SetScript("OnEnterPressed", function(self)
				self:ClearFocus()
				CommitRow(i)
			end)
			row.GoldBox:SetScript("OnEditFocusLost", function()
				CommitRow(i)
			end)
			row.IgnoreCheck:SetChecked(entry.Ignore == true)

			row.IgnoreCheck:SetScript("OnClick", function()
				CommitRow(i)
				RefreshRow(i)
			end)

			local ignored = entry.Ignore == true
			row.GoldBox:SetEnabled(not ignored)
			row.GoldBox:SetAlpha(ignored and 0.5 or 1)

			-- Row 1 is not deletable
			if i == 1 then
				row.RemoveButton:Hide()
				row.RemoveButton:SetScript("OnClick", nil)
			else
				row.RemoveButton:Show()
				row.RemoveButton:SetScript("OnClick", function()
					table.remove(db.Overrides, i)
					Refresh()
				end)
			end
		end

		-- Position Add button to the right of row 1
		if rows[1] then
			addBtn:ClearAllPoints()
			addBtn:SetPoint("LEFT", rows[1].GoldBox, "RIGHT", 12, 0)
			addBtn:Show()
		else
			addBtn:Hide()
		end
	end

	addBtn:SetScript("OnClick", function()
		EnsureAtLeastOneRow()
		local nextOrder = GetMaxOrder() + 1
		db.Overrides[#db.Overrides + 1] = { CharacterName = "", Order = nextOrder, Gold = 0, Ignore = false }
		Refresh()

		-- optional: focus the new row's name box
		local idx = #db.Overrides
		if rows[idx] and rows[idx].NameBox then
			rows[idx].NameBox:SetFocus()
			rows[idx].NameBox:HighlightText()
		end
	end)

	Refresh()
end

function M:Init()
	db = mini:GetSavedVars(dbDefaults)

	local scroll = CreateFrame("ScrollFrame", nil, nil, "UIPanelScrollFrameTemplate")
	scroll.name = addonName

	local category = mini:AddCategory(scroll)
	local panel = CreateFrame("Frame")
	local width, height = mini:SettingsSize()

	panel:SetWidth(width)
	panel:SetHeight(height)

	scroll:SetScrollChild(panel)

	if not category then
		return
	end

	local version = C_AddOns.GetAddOnMetadata(addonName, "Version")
	local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 0, -verticalSpacing)
	title:SetText(string.format("%s - %s", addonName, version))

	local lines = {
		"Automate withdrawing and depositing gold across your characters.",
		"Each time you visit the bank, gold will automatically withdraw/deposit based on your settings.",
	}

	local anchor = title

	for i = 1, #lines do
		local description = panel:CreateFontString(nil, "ARTWORK", "GameFontWhite")
		description:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -8)
		description:SetText(lines[i])

		anchor = description
	end

	local printMessagesChk = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "Print chat messages",
		GetValue = function ()
			return  db.PrintMessages
		end,
		SetValue = function (enabled)
			db.PrintMessages = enabled
		end,
		Tooltip = "Whether to print messages to the chat frame when things happen."
	})

	printMessagesChk:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -verticalSpacing)

	anchor, _ = CreateDesiredGoldInput(panel, printMessagesChk, 0, -verticalSpacing)

	CreateOverrideGrid(panel, anchor, 0, -verticalSpacing)

	SLASH_MINIGOLDSYNC1 = "/minigoldsync"
	SLASH_MINIGOLDSYNC2 = "/minigold"
	SLASH_MINIGOLDSYNC3 = "/mgs"
	SLASH_MINIGOLDSYNC4 = "/mg"

	mini:RegisterSlashCommand(category, panel)
end

---@class Override
---@field CharacterName string
---@field Order number
---@field Gold number
---@field Ignore boolean
