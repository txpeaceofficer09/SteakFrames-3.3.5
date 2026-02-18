local SteakUnitsParent = CreateFrame("Frame", "SteakUnitsParent", UIParent, "SecureHandlerStateTemplate")
SteakUnitsParent:SetAllPoints(UIParent)

local GearScores = {}

local function GetUnitGearData(unit)
	if not UnitIsPlayer(unit) or not CheckInteractDistance(unit, 1) then
		if GearScores and GearScores[UnitGUID(unit)] then
			return math.floor(GearScores[UnitGUID(unit)].gs), math.floor(GearScores[UnitGUID(unit)].ilvl)
		end

		return 0, 0
	end

	local totalIlvl = 0
	local totalGS = 0
	local count = 0

	for i = 1, 18 do
		if i ~= 4 then
			local link = GetInventoryItemLink(unit, i)

			if link then
				local _, _, quality, iLevel = GetItemInfo(link)

				if iLevel then
					totalIlvl = totalIlvl + iLevel

					if IsAddOnLoaded("GearScore") and type(GearScore_GetItemScore) == "function" then
						totalGS = totalGS + GearScore_GetItemScore(link)
					end

					count = count + 1
				end
			end
		end
	end

	if count == 0 then return 0, 0 end

	table.insert(GearScores, UnitGUID(unit), {
		name = UnitName(unit),
		class = UnitClass(unit),
		gs = totalGS,
		ilvl = totalIlvl / count
	})

	return math.floor(totalGS), math.floor(totalIlvl / count)
end

local function Steak_UpdateThreat(self)
	if not UnitExists(self.unit) then return end

	local threat = UnitThreatSituation(self.unit)

	if threat == 3 then
		self.bg:SetVertexColor(1, 0, 0, 0.8)
	elseif threat == 2 then
		self.bg:SetVertexColor(1, 0.5, 0, 0.8)
	elseif threat == 1 then
		self.bg:SetVertexColor(1, 1, 0, 0.8)
	else
		self.bg:SetVertexColor(0, 0, 0, 0.8)
	end
end

local function Steak_UpdateRaidIcon(self)
	local index = GetRaidTargetIndex(self.unit)
	if not index then
		self.raidIcon:Hide()
		return
	end

	self.raidIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. index)
	self.raidIcon:Show()
end

local function Steak_UpdatePvPIcon(self)
	if UnitIsPVP(self.unit) then
		local faction = UnitFactionGroup(self.unit)
		if faction == "Alliance" then
			self.pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-Alliance")
		elseif faction == "Horde" then
			self.pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-Horde")
		else
			self.pvpIcon:SetTexture(nil)
		end
		self.pvpIcon:Show()
	else
		self.pvpIcon:Hide()
	end
end

local function Steak_UpdatePower(self)
	local power = UnitPower(self.unit) or 1
	local powerMax = UnitPowerMax(self.unit) or 1

	self.mana:SetValue((power / powerMax) * 100)

	local pType = UnitPowerType(self.unit)
	local pColor = pType and PowerBarColor[pType] or { r = 0, g = 0, b = 1 }
	self.mana:SetStatusBarColor(pColor.r, pColor.g, pColor.b)
	self.mpText:SetText(power.." / "..powerMax)
end

local function Steak_UpdateHealth(self)
	local hp = UnitHealth(self.unit) or 1
	local hpMax = UnitHealthMax(self.unit) or 1
	local class = select(2, UnitClass(self.unit)) or ""
	local color = class and RAID_CLASS_COLORS[class] or { r = 0, g = 1, b = 0 }

	self.health:SetValue((hp / hpMax) * 100)
	self.health:SetStatusBarColor(color.r, color.g, color.b)
	self.hpText:SetText(hp.." / "..hpMax)
end

local function Steak_UpdateName(self)
	local isDead = UnitIsDeadOrGhost(self.unit)
	local isConnected = UnitIsConnected(self.unit)
	local unitName = UnitName(self.unit) or "Unknown"

	if isDead then
		unitName = unitName.."\nDEAD"
	elseif not isConnected then
		unitName = unitName.."\nOFFLINE"
	end

	self.nameText:SetText(unitName)
end

local SteakUnitEvents = {
	"PLAYER_ENTERING_WORLD",
	"GROUP_ROSTER_UPDATE",
	"UNIT_HEALTH",
	"UNIT_MAXHEALTH",
	"UNIT_POWER_UPDATE",
	"UNIT_MANA",
	"UNIT_RAGE",
	"UNIT_ENERGY",
	"UNIT_RUNIC_POWER",
	"UNIT_MAXMANA",
	"UNIT_MAXRAGE",
	"UNIT_MAXENERGY",
	"UNIT_MAXRUNIC_POWER",
	"UNIT_DISPLAYPOWER",
	"UNIT_FACTION",
	"UNIT_THREAT_SITUATION_UPDATE",
	"UNIT_THREAT_LIST_UPDATE",
	"RAID_TARGET_UPDATE",
	"PLAYER_TARGET_CHANGED",
	"UNIT_TARGET",
	"INSPECT_READY",
	"PLAYER_FOCUS_CHANGED",
	"UNIT_INVENTORY_CHANGED"
}

local function Steak_UpdateGS(self)
	local gs, ilvl = GetUnitGearData(self.unit)
	local color = "ffff00"

	if GS_Quality then
		for i=1,6,1 do
			local index = i*1000

			if gs < index then
				color = string.format("%02x%02x%02x", math.floor(GS_Quality[index].Red.A * 255), math.floor(GS_Quality[index].Green.A * 255), math.floor(GS_Quality[index].Blue.A * 255))
				break
			end
		end
	end

	if gs then
		self.gsText:SetText("GS: |cff"..color..gs)
		self.ilvlText:SetText("iLvl: "..ilvl)
	else
		self.gsText:SetText("")
		self.ilvlText:SetText("")
	end
end

local function Steak_OnEvent(self, event, ...)
	if event == "PLAYER_ENTERING_WORLD" or event == "GROUP_ROSTER_UPDATE" then
		if UnitExists(self.unit) then
			Steak_UpdateHealth(self)
			Steak_UpdatePower(self)
			Steak_UpdateName(self)
			Steak_UpdateRaidIcon(self)
			Steak_UpdatePvPIcon(self)
			Steak_UpdateThreat(self)
			Steak_UpdateGS(self)
		end
	elseif event == "PLAYER_TARGET_CHANGED" then
		if UnitGUID(self.unit) == UnitGUID("target") or UnitGUID(self.unit) == UnitGUID("targettarget") then
			Steak_UpdateHealth(self)
			Steak_UpdatePower(self)
			Steak_UpdateName(self)
			Steak_UpdateRaidIcon(self)
			Steak_UpdatePvPIcon(self)
			Steak_UpdateThreat(self)
			Steak_UpdateGS(self)			
			
			if CanInspect(self.unit) and CheckInteractDistance(self.unit, 1) and not InCombatLockdown() then
				NotifyInspect(self.unit)
			end
		end
	elseif event == "UNIT_TARGET" then
		if UnitGUID(self.unit) == UnitGUID(...) then
			Steak_UpdateHealth(self)
			Steak_UpdatePower(self)
			Steak_UpdateName(self)
			Steak_UpdateRaidIcon(self)
			Steak_UpdatePvPIcon(self)
			Steak_UpdateThreat(self)
			Steak_UpdateGS(self)

			if CanInspect(self.unit) and CheckInteractDistance(self.unit, 1) and not InCombatLockdown() then
				NotifyInspect(self.unit)
			end
		end
	elseif event == "PLAYER_FOCUS_CHANGED" then
		if UnitGUID(self.unit) == UnitGUID("focus") then
			Steak_UpdateHealth(self)
			Steak_UpdatePower(self)
			Steak_UpdateName(self)
			Steak_UpdateRaidIcon(self)
			Steak_UpdatePvPIcon(self)
			Steak_UpdateThreat(self)
			Steak_UpdateGS(self)
		end
	elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
		local unit = ...
		if unit == self.unit then
			Steak_UpdateHealth(self)
			Steak_UpdateName(self)
		end
	elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_DISPLAYPOWER" or event == "UNIT_MANA" or event == "UNIT_RAGE" or event == "UNIT_ENERGY" or event == "UNIT_RUNIC_POWER" or event == "UNIT_MAXMANA" or event == "UNIT_MAXRAGE" or event == "UNIT_MAXENERGY" or event == "UNIT_MAXRUNIC_POWER" or event == "UNIT_DISPLAYPOWER" then
		local unit = ...
		if unit == self.unit then
			Steak_UpdatePower(self)
		end
	elseif event == "UNIT_FACTION" then
		local unit = ...
		if unit == self.unit then
			Steak_UpdatePvPIcon(self)
		end
	elseif event == "UNIT_THREAT_SITUATION_UPDATE" or event == "UNIT_THREAT_LIST_UPDATE" then
		local unit = ...
		if unit == self.unit then
			Steak_UpdateThreat(self)
		end
	elseif event == "RAID_TARGET_UPDATE" then
		Steak_UpdateRaidIcon(self)
	elseif event == "UNIT_INVENTORY_CHANGED" then
		if self.unit == ... then
			Steak_UpdateGS(self)
		end
	elseif event == "NOTIFY_INSPECT" then
		if UnitGUID(self.unit) == ... then
			Steak_UpdateGS(self)
		end
	end
end

local function CreateSteakUnitFrame(name, unit, width, height, parent)
	local frame = CreateFrame("Button", name, parent or SteakUnitsParent, "SecureUnitButtonTemplate")
	frame:SetSize(width, height)

	frame:SetAttribute("unit", unit)
	frame.unit = unit
	frame:SetAttribute("*type1", "target")
	frame:SetAttribute("type2", "menu")
	frame:RegisterForClicks("AnyUp")

	frame:SetScript("OnMouseUp", function(self, button)
		if button ~= "RightButton" then return end

		local dropdown, x, y

		if self.unit == "player" then
			dropdown = PlayerFrameDropDown
			x, y = 0, 0
		elseif self.unit == "pet" then
			dropdown = PetFrameDropDown
			x, y = 0, 0
		elseif self.unit and self.unit:match("^party") then
			dropdown = PartyMemberFrame1DropDown
			x, y = 0, 0
		elseif self.unit and self.unit:match("^raid") then
			dropdown = PlayerFrameDropDown
			x, y = 0, 0
		elseif self.unit == "target" then
			dropdown = TargetFrameDropDown
			x, y = 0, 0
		elseif self.unit == "focus" then
			dropdown = FocusFrameDropDown
			x, y = 0, 0
		else
			dropdown = PlayerFrameDropDown
			x, y = 0, 0
		end

		if dropdown then
			ToggleDropDownMenu(1, nil, dropdown, self, x, y)
		end
	end)

	local bg = frame:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints(frame)
	bg:SetTexture("Interface\\Buttons\\WHITE8x8")
	bg:SetVertexColor(0, 0, 0, 0.8)
	frame.bg = bg

	local health = CreateFrame("StatusBar", nil, frame)
	health:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
	health:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 12)
	health:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	health:SetMinMaxValues(0, 100)
	health:EnableMouse(false)
	frame.health = health

	local mana = CreateFrame("StatusBar", nil, frame)
	mana:SetPoint("TOPLEFT", health, "BOTTOMLEFT", 0, -1)
	mana:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
	mana:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	mana:SetMinMaxValues(0, 100)
	mana:EnableMouse(false)
	frame.mana = mana

	local mpText = mana:CreateFontString(nil, "OVERLAY")
	mpText:SetFont("Interface\\AddOns\\SteakFrames\\Audiowide-Regular.ttf", 8, "OUTLINE")
	mpText:SetPoint("RIGHT", mana, "RIGHT", -2, 0)
	mpText:SetTextColor(1, 1, 1)
	frame.mpText = mpText

	local nameText = health:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	nameText:SetFont("Interface\\AddOns\\SteakFrames\\Audiowide-Regular.ttf", 10, "OUTLINE")
	nameText:SetPoint("CENTER", health, "CENTER", 0, 5)
	nameText:SetTextColor(1, 1, 1)
	frame.nameText = nameText

	local hpText = health:CreateFontString(nil, "OVERLAY")
	hpText:SetFont("Interface\\AddOns\\SteakFrames\\Audiowide-Regular.ttf", 8, "OUTLINE")
	hpText:SetPoint("BOTTOMRIGHT", health, "BOTTOMRIGHT", -2, 2)
	hpText:SetTextColor(1, 1, 1)
	frame.hpText = hpText

	local raidIcon = frame:CreateTexture(nil, "OVERLAY")
	raidIcon:SetSize(16, 16)
	raidIcon:SetPoint("CENTER", frame, "TOP", 0, 0)
	frame.raidIcon = raidIcon

	local pvpIcon = health:CreateTexture(nil, "OVERLAY")
	pvpIcon:SetSize(24, 24)
	pvpIcon:SetPoint("CENTER", frame, "TOPLEFT", 0, 0)
	frame.pvpIcon = pvpIcon

	local gsText = frame:CreateFontString(nil, "OVERLAY")
	gsText:SetFont("Interface\\AddOns\\SteakFrames\\Audiowide-Regular.ttf", 8, "OUTLINE")
	gsText:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -2, 2)
	gsText:SetTextColor(1, 1, 0)
	frame.gsText = gsText

	local ilvlText = frame:CreateFontString(nil, "OVERLAY")
	ilvlText:SetFont("Interface\\AddOns\\SteakFrames\\Audiowide-Regular.ttf", 8, "OUTLINE")
	ilvlText:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 2, 2)
	ilvlText:SetTextColor(0.7, 0.7, 1)
	frame.ilvlText = ilvlText

	for _, ev in ipairs(SteakUnitEvents) do
		frame:RegisterEvent(ev)
	end
	frame:SetScript("OnEvent", Steak_OnEvent)

	RegisterUnitWatch(frame)

	return frame
end

local SteakPlayer = CreateSteakUnitFrame("SteakPlayerFrame", "player", 140, 50)
local SteakPet = CreateSteakUnitFrame("SteakPetFrame", "pet", 110, 40)
local SteakTarget = CreateSteakUnitFrame("SteakTargetFrame", "target", 140, 50)
local SteakToT = CreateSteakUnitFrame("SteakToTFrame", "targettarget", 110, 40)
local SteakFocus = CreateSteakUnitFrame("SteakFocusFrame", "focus", 140, 50)

local raidParent = CreateFrame("Frame", "SteakRaidHeader", UIParent, "SecureHandlerStateTemplate")
raidParent:SetSize((110*10)+(4*9), 40)
raidParent:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 300)
RegisterStateDriver(raidParent, "visibility", "[group:raid] show; hide")

for i=1,10 do
	local raidFrame = CreateSteakUnitFrame("SteakRaid"..i, "raid"..i, 110, 40, raidParent)
	raidFrame:SetPoint("LEFT", raidParent, "LEFT", 114*(i-1), 0)
end

local partyParent = CreateFrame("Frame", "SteakPartyHeader", UIParent, "SecureHandlerStateTemplate")
partyParent:SetSize((140*4)+(4*3), 50)
partyParent:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 300)
RegisterStateDriver(partyParent, "visibility", "[group:raid] hide; [group:party] show; hide")

for i=1,4 do
	local partyFrame = CreateSteakUnitFrame("SteakParty"..i, "party"..i, 140, 50, partyParent)
	partyFrame:SetPoint("LEFT", partyParent, "LEFT", 144*(i-1), 0)
end

SteakPlayer:ClearAllPoints()
SteakPlayer:SetPoint("BOTTOM", UIParent, "BOTTOM", -150, 220)

SteakTarget:ClearAllPoints()
SteakTarget:SetPoint("BOTTOM", UIParent, "BOTTOM", 150, 220)

SteakFocus:ClearAllPoints()
SteakFocus:SetPoint("BOTTOM", UIParent, "BOTTOM", -250, 340)

SteakToT:ClearAllPoints()
SteakToT:SetPoint("TOP", SteakTarget, "BOTTOM", 40, -10)

SteakPet:ClearAllPoints()
SteakPet:SetPoint("TOP", SteakPlayer, "BOTTOM", 10, -10)

local h = CreateFrame("Frame")

h:RegisterEvent("PLAYER_LOGIN")
h:RegisterEvent("PLAYER_REGEN_ENABLED")

h:SetScript("OnEvent", function()
	local frames = {
		PlayerFrame,
		TargetFrame,
		TargetFrameToT,
		FocusFrame,
		PetFrame,
		PartyMemberFrame1,
		PartyMemberFrame2,
		PartyMemberFrame3,
		PartyMemberFrame4,
		PartyMemberBackground,
		PartyMemberFrame1PetFrame,
		PartyMemberFrame2PetFrame,
		PartyMemberFrame3PetFrame,
		PartyMemberFrame4PetFrame
	}

	for _, f in ipairs(frames) do
		if f then
			f:UnregisterAllEvents()
			f:Hide()
			f:SetParent(UIParent)
		end
	end
end)
