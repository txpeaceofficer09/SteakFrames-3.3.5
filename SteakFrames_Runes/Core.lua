local Steak = Steak

local Module = {}

Module.events = {
	"PLAYER_ENTERING_WORLD",
	"PLAYER_DEAD",
	"PLAYER_ALIVE",
	"RUNE_POWER_UPDATE",
	"RUNE_TYPE_UPDATE"
}

local RUNE_COUNT = 6
local RUNE_WIDTH = 32
local RUNE_HEIGHT = 12
local RUNE_SPACING = 3
local UPDATE_INTERVAL = 0.03

local RUNE_TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar"
local RUNE_FRAME_TEXTURE = "Interface\\Tooltips\\UI-Tooltip-Background"

local RUNE_COLORS = {
	[1] = { 0.85, 0.15, 0.15 }, -- Blood
	[2] = { 0.20, 0.55, 1.00 }, -- Frost
	[3] = { 0.20, 0.80, 0.25 }, -- Unholy
	[4] = { 0.75, 0.35, 1.00 }  -- Death
}

local DEFAULT_RUNE_TYPES = {
	1, 1, 2, 2, 3, 3
}

local function HideBlizzardRunes()
	if not RuneFrame then
		return
	end

	RuneFrame:Hide()

	if not Module.HookedRuneFrame then
		Module.HookedRuneFrame = true

		RuneFrame:HookScript("OnShow", function(frame)
			frame:Hide()
		end)
	end
end

function Module:CreateRuneBar(index)
	local bar = CreateFrame(
		"StatusBar",
		"SteakRuneBar" .. index,
		self.frame
	)

	bar:SetSize(RUNE_WIDTH, RUNE_HEIGHT)
	bar:SetStatusBarTexture(RUNE_TEXTURE)
	bar:SetMinMaxValues(0, 1)
	bar:SetValue(1)
	bar:SetFrameLevel(self.frame:GetFrameLevel() + 2)

	bar:SetPoint(
		"LEFT",
		self.frame,
		"LEFT",
		(index - 1) * (RUNE_WIDTH + RUNE_SPACING),
		0
	)

	bar.bg = bar:CreateTexture(nil, "BACKGROUND")
	bar.bg:SetAllPoints(bar)
	bar.bg:SetTexture(RUNE_FRAME_TEXTURE)
	bar.bg:SetVertexColor(0.08, 0.08, 0.08, 1)

	bar.border = CreateFrame("Frame", nil, bar)
	bar.border:SetPoint("TOPLEFT", bar, "TOPLEFT", -1, 1)
	bar.border:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 1, -1)
	bar.border:SetBackdrop({
		bgFile = nil,
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 8,
		insets = {
			left = 2,
			right = 2,
			top = 2,
			bottom = 2
		}
	})
	bar.border:SetBackdropBorderColor(0.15, 0.15, 0.15, 1)

	bar.index = index
	bar.runeType = DEFAULT_RUNE_TYPES[index]

	self.runes[index] = bar

	return bar
end

function Module:Initialize()
	if self.frame then
		return
	end

	self.runes = {}
	self.elapsed = 0

	self.frame = CreateFrame("Frame", "SteakRunesFrame", UIParent)
	self.frame:SetSize(
		RUNE_COUNT * RUNE_WIDTH + (RUNE_COUNT - 1) * RUNE_SPACING,
		RUNE_HEIGHT
	)

	-- Position beneath the Steak player frame when available.
	if SteakPlayerFrame then
		self.frame:SetPoint("TOP", SteakPlayerFrame, "BOTTOM", 0, -8)
	else
		self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
	end

	self.frame:SetFrameStrata("MEDIUM")

	for index = 1, RUNE_COUNT do
		self:CreateRuneBar(index)
	end

	HideBlizzardRunes()

	self:UpdateRunes()
	self.frame:Show()
end

function Module:GetRuneColor(index)
	local runeType

	if GetRuneType then
		runeType = GetRuneType(index)
	end

	if not runeType or not RUNE_COLORS[runeType] then
		runeType = DEFAULT_RUNE_TYPES[index]
	end

	return RUNE_COLORS[runeType] or RUNE_COLORS[4]
end

function Module:UpdateRune(index)
	local bar = self.runes[index]

	if not bar then
		return
	end

	local start, duration, ready = GetRuneCooldown(index)
	local r, g, b = unpack(self:GetRuneColor(index))

	bar:SetStatusBarColor(r, g, b)

	if ready or not start or not duration or duration <= 0 then
		bar:SetMinMaxValues(0, 1)
		bar:SetValue(1)
		bar:SetAlpha(1)
		return
	end

	-- Progress from empty to full while the rune regenerates.
	local progress = (GetTime() - start) / duration

	if progress < 0 then
		progress = 0
	elseif progress > 1 then
		progress = 1
	end

	bar:SetMinMaxValues(0, 1)
	bar:SetValue(progress)
	bar:SetAlpha(1)
end

function Module:UpdateRunes()
	for index = 1, RUNE_COUNT do
		self:UpdateRune(index)
	end
end

function Module:OnEvent(event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		HideBlizzardRunes()

		if not self.frame then
			self:Initialize()
		end

		self:UpdateRunes()
		return
	end

	if event == "PLAYER_DEAD" or event == "PLAYER_ALIVE" then
		self:UpdateRunes()
		return
	end

	if event == "RUNE_POWER_UPDATE" or event == "RUNE_TYPE_UPDATE" then
		local runeIndex = ...

		if runeIndex and runeIndex >= 1 and runeIndex <= RUNE_COUNT then
			self:UpdateRune(runeIndex)
		else
			self:UpdateRunes()
		end
	end
end

function Module:OnUpdate(elapsed)
	if not self.frame or not self.frame:IsShown() then
		return
	end

	self.elapsed = self.elapsed + elapsed

	if self.elapsed < UPDATE_INTERVAL then
		return
	end

	self.elapsed = 0
	self:UpdateRunes()
end

Steak:RegisterModule(Module)
