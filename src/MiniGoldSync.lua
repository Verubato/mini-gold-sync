local _, addon = ...
---@type MiniFramework
local mini = addon.Framework
local eventsFrame
local playerFullName = GetUnitName("player") .. "-" .. GetRealmName()
local playerShortName = GetUnitName("player")
local copperPerSilver = 100
local silverPerGOld = 100
local copperPerGold = copperPerSilver * silverPerGOld
local accountBankType = 2
---@type Db
local db

local function Notify(msg, ...)
	if not db.PrintMessages then
		return
	end

	mini:Notify(msg, ...)
end

local function FormatWithCommas(value)
	if not value then
		return "0"
	end

	value = math.floor(tonumber(value) or 0)
	local numString = tostring(value)
	local result = numString:reverse():gsub("(%d%d%d)", "%1,"):reverse()

	if result:sub(1, 1) == "," then
		result = result:sub(2)
	end

	return result
end

local function GetOverrideGold()
	for i = 1, #db.Overrides do
		local o = db.Overrides[i]

		if o and o.CharacterName == playerFullName or o.CharacterName == playerShortName then
			return tonumber(o.Gold)
		end
	end

	return nil
end

local function IsIgnored()
	for i = 1, #db.Overrides do
		local o = db.Overrides[i]

		if o and o.CharacterName == playerFullName or o.CharacterName == playerShortName then
			return o.Ignore
		end
	end

	return false
end

local function Withdraw(copper)
	if not C_Bank.CanWithdrawMoney(accountBankType) then
		return
	end

	local maxDeposited = C_Bank.FetchDepositedMoney(accountBankType)

	local amount = math.min(maxDeposited, copper)
	C_Bank.WithdrawMoney(accountBankType, amount)

	return amount > 0
end

local function Deposit(copper)
	if not C_Bank.CanDepositMoney(accountBankType) then
		return false
	end

	C_Bank.DepositMoney(accountBankType, copper)

	return true
end

local function Run()
	if IsIgnored() then
		Notify("Ignoring current character.")
		return
	end

	local desiredGold = GetOverrideGold() or db.DesiredGold

	if not desiredGold then
		return
	end

	if desiredGold == 0 then
		return
	end

	if desiredGold < 0 then
		Notify("Invalid desired gold value of %d.", desiredGold)
		return
	end

	local currentCopper = GetMoney()
	local desiredCopper = desiredGold * copperPerGold
	local delta = desiredCopper - currentCopper

	Notify(
		"You have %s gold, desired gold = %s, difference = %s.",
		FormatWithCommas(currentCopper / copperPerGold),
		FormatWithCommas(db.DesiredGold),
		FormatWithCommas(delta / copperPerGold)
	)

	if delta == 0 then
		return
	end

	local success
	local amount = math.abs(delta)

	if delta > 0 then
		success = Withdraw(amount)
	else
		success = Deposit(amount)
	end

	if success then
		Notify("Successfully synchronised gold.")
	else
		Notify("Failed to synchronise gold.")
	end
end

local function OnEvent(_, event)
	if event ~= "BANKFRAME_OPENED" then
		return
	end

	Run()
end

local function OnAddonLoaded()
	addon.Config:Init()

	db = mini:GetSavedVars()

	eventsFrame = CreateFrame("Frame")
	eventsFrame:SetScript("OnEvent", OnEvent)
	eventsFrame:RegisterEvent("BANKFRAME_OPENED")
end

mini:WaitForAddonLoad(OnAddonLoaded)
