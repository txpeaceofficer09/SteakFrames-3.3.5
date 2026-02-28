local SteakUnitsParent = CreateFrame("Frame", "SteakUnitsParent", UIParent, "SecureHandlerStateTemplate")
SteakUnitsParent:SetAllPoints(UIParent)

local GearScores = {}
local SteakSpecs = {}
local SteakAuras = {}

local DebuffTypeIcons = {
	Magic   = "Interface\\Icons\\Spell_Holy_DispelMagic",
	Curse   = "Interface\\Icons\\Spell_Shadow_CurseOfTounges",
	Disease = "Interface\\Icons\\Spell_Nature_NullifyDisease",
	Poison  = "Interface\\Icons\\Spell_Nature_NullifyPoison",
}

local SteakSpecRoles = {
    -- Warriors
    ["Arms"] = "DAMAGER",
    ["Fury"] = "DAMAGER",
    ["Protection"] = "TANK",

    -- Paladins
    ["Holy"] = "HEALER",
    ["Protection"] = "TANK",
    ["Retribution"] = "DAMAGER",

    -- DKs
    ["Blood"] = "TANK",
    ["Frost"] = "DAMAGER",
    ["Unholy"] = "DAMAGER",

    -- Druids
    ["Balance"] = "DAMAGER",
    ["Feral Combat"] = "TANK",   -- or DPS depending on points; Wrath can't distinguish
    ["Restoration"] = "HEALER",

    -- Priests
    ["Discipline"] = "HEALER",
    ["Holy"] = "HEALER",
    ["Shadow"] = "DAMAGER",

    -- Shamans
    ["Elemental"] = "DAMAGER",
    ["Enhancement"] = "DAMAGER",
    ["Restoration"] = "HEALER",

    -- Rogues
    ["Assassination"] = "DAMAGER",
    ["Combat"] = "DAMAGER",
    ["Subtlety"] = "DAMAGER",

    -- Hunters
    ["Beast Mastery"] = "DAMAGER",
    ["Marksmanship"] = "DAMAGER",
    ["Survival"] = "DAMAGER",

    -- Mages
    ["Arcane"] = "DAMAGER",
    ["Fire"] = "DAMAGER",
    ["Frost"] = "DAMAGER",

    -- Warlocks
    ["Affliction"] = "DAMAGER",
    ["Demonology"] = "DAMAGER",
    ["Destruction"] = "DAMAGER",
}

local SteakUnitEvents = {
	"PLAYER_ENTERING_WORLD",
	"GROUP_ROSTER_UPDATE",
	"PARTY_MEMBERS_CHANGED",
	"RAID_ROSTER_UPDATE",
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
	"UNIT_MAXPOWER",
	"UNIT_FACTION",
	"UNIT_THREAT_SITUATION_UPDATE",
	"UNIT_THREAT_LIST_UPDATE",
	"UNIT_AURA",
	"UNIT_PET",
	"UNIT_HAPPINESS",
	"RAID_TARGET_UPDATE",
	"PLAYER_PET_CHANGED",
	"PLAYER_TARGET_CHANGED",
	"UNIT_TARGET",
	"INSPECT_READY",
	"PLAYER_FOCUS_CHANGED",
	"UNIT_INVENTORY_CHANGED",
	"INSPECT_TALENT_READY",
	"PARTY_LOOT_METHOD_CHANGED",
	"UNIT_COMBO_POINTS"
}

local origNotifyInspect = NotifyInspect

NotifyInspect = function(unit)
	SteakInspectUnitGUID = UnitGUID(unit)
	origNotifyInspect(unit)
end

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

	local guid = UnitGUID(unit)
	local cache = GearScores and guid and GearScores[guid]

	if totalGS == 0 or count == 0 or not CheckInteractDistance(unit, 1) then
		if cache then return math.floor(cache.gs), math.floor(cache.ilvl) end
		
		return 0, 0
	end

	GearScores[UnitGUID(unit)] = { name = UnitName(unit), class = UnitClass(unit), gs = totalGS, ilvl = totalIlvl / count, count = count }
	
	return math.floor(totalGS), math.floor(totalIlvl / count)
end

local function Steak_GetSpec(self)
	if not UnitIsPlayer(self.unit) then return end

	local guid = UnitGUID(self.unit)
	if not guid then return nil end

	if guid ~= SteakInspectUnitGUID then return nil end

	local maxPoints = 0
	local specName = nil

	for tab = 1, GetNumTalentTabs(true) do
		local name, _, points = GetTalentTabInfo(tab, true, nil, self.unit)

		if points and points > maxPoints then
			maxPoints = points
			specName = name
		end
	end

	SteakSpecs[guid] = specName
	return specName
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

local function CreateAuraIcon(parent)
	local f = CreateFrame("Frame", nil, parent)
	f:SetSize(12, 12)

	f.icon = f:CreateTexture(nil, "ARTWORK")
	f.icon:SetAllPoints()

	f.count = f:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
	f.count:SetPoint("BOTTOMRIGHT", 2, 0)

	f.cd = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
	f.cd:SetAllPoints()
	f.cd:SetDrawEdge(false)
	f.cd:SetReverse(true)

	f.border = f:CreateTexture(nil, "OVERLAY")
	f.border:SetAllPoints()
	f.border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
	f.border:SetTexCoord(.296875, .5703125, 0, .515625)

	f:EnableMouse(true)

	f:SetScript("OnEnter", function(self)
		if self.spellID then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetSpellByID(self.spellID)
			GameTooltip:Show()
		end
	end)

	f:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

    return f
end

local function Steak_UpdateRole(self)
	if not self.unit then return end

	local role = UnitGroupRolesAssigned(self.unit)
	local guid = UnitGUID(self.unit)
	local spec = guid and SteakSpecs[guid]

	if role == "NONE" or not role or role == "" then
		if spec then
			if select(2, UnitClass(self.unit)) == "DRUID" and spec == "Feral Combat" then
				local _, _, _, _, tankPoints = GetTalentInfo(2, 26, true)
				local _, _, _, _, thickHidePoints = GetTalentInfo(2, 4, true)
				
				if thickHidePoints > 0 or tankPoints > 0 then
					role = "TANK"
				else
					role = "DAMAGER"
				end
			else
				role = SteakSpecRoles[spec]
			end
		end
	end

	if role == "TANK" then
		self.roleIcon:SetTexture("Interface\\AddOns\\SteakFrames\\tank_32.tga")

		self.roleIcon:Show()

	elseif role == "HEALER" then
		self.roleIcon:SetTexture("Interface\\AddOns\\SteakFrames\\healer_32.tga")

		self.roleIcon:Show()

	elseif role == "DAMAGER" then
		self.roleIcon:SetTexture("Interface\\AddOns\\SteakFrames\\dps_32.tga")

		self.roleIcon:Show()

	else
		self.roleIcon:Hide()
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
	local unitName = ("[%s] %s"):format(UnitLevel(self.unit) or "??", UnitName(self.unit) or "Unknown")

	if isDead then
		unitName = unitName.."\nDEAD"
	elseif not isConnected then
		unitName = unitName.."\nOFFLINE"
	end

	self.nameText:SetText(unitName)
end

local function UnitInGroup(unit)
	if not UnitExists(unit) then return false end
	if UnitIsUnit(unit, "player") then return true end

	for i=1,4 do
		if UnitExists("party"..i) and UnitIsUnit(unit, "party"..i) then return true end
	end

	for i=1,40 do
		if UnitExists("raid"..i) and UnitIsUnit(unit, "raid"..i) then return true end
	end

	return false
end

local function UpdateRoleIcons(self)
	if not UnitExists(self.unit) or not UnitIsPlayer(self.unit) or not UnitInGroup(self.unit) then return end

	local roleText = ""

	if UnitIsRaidOfficer(self.unit) and UnitIsPartyLeader(self.unit) then
		roleText = string.format("%s|T%s:14:14|t ", roleText, "Interface\\GroupFrame\\UI-Group-LeaderIcon")
	end

	if UnitIsRaidOfficer(self.unit) and not UnitIsPartyLeader(self.unit) then
		roleText = string.format("%s|T%s:14:14|t ", roleText, "Interface\\GroupFrame\\UI-Group-AssistantIcon")
	end

	if GetPartyAssignment("MAINTANK", self.unit) then
		roleText = string.format("%s|T%s:14:14|t ", roleText, "Interface\\GroupFrame\\UI-Group-MainTankIcon")
	end

	if GetPartyAssignment("MAINASSIST", self.unit) then
		roleText = string.format("%s|T%s:14:14|t ", roleText, "Interface\\GroupFrame\\UI-Group-MainAssistIcon")
	end

	local method, mlPartyID, mlRaidID = GetLootMethod()

	if method == "master" then
		local mlUnit

		if mlRaidID then
			mlUnit = "raid"..mlRaidID
		elseif mlPartyID then
			mlUnit = mlPartyID == 0 and "player" or "party"..mlPartyID
		end

		if mlUnit and UnitIsUnit(self.unit, mlUnit) then
			roleText = string.format("%s|T%s:14:14|t ", roleText, "Interface\\GroupFrame\\UI-Group-MasterLooter")
		end
	end

	self.roleText:SetText(roleText)
end

local function Steak_UpdateDebuffs(self)
	local unit = self.unit
	if not UnitExists(unit) then return end

	for _, debuff in ipairs(self.debuffTextures or {}) do
		debuff:Hide()
	end

	local debuffs = {}

	for i=1,40 do
		local name, icon, count, debuffType, duration, expires, _, _, _, spellID = UnitDebuff(unit, i)

		if DebuffTypeIcons[debuffType] then
			debuffs[debuffType] = true 
		end
	end

	local index = 1

	for type, _ in pairs(debuffs) do
		local texture = self.health:CreateTexture(nil, "ARTWORK")

		texture:SetSize(12, 12)
		texture:SetPoint("TOPLEFT", self, "TOPLEFT", 14 * (i-1), 0)
		table.insert(self.debuffTextures, texture)
		texture:SetTexture(DebuffTypeIcons[type])
		texture:Show()
	end
end

--[[
local function UpdateAuras(frame)
	local unit = frame.unit
	if not UnitExists(unit) then return end

	local index = 1
	local y = 0
	local x = 0

	for i = 1, 40 do
		local name, icon, count, debuffType, duration, expires, _, _, _, spellID = UnitBuff(unit, i)
		if not name then break end

		local btn = frame.buffs.icons[index]
		if not btn then
			btn = CreateAuraIcon(frame.buffs)
			frame.buffs.icons[index] = btn
		end

		btn.spellID = spellID

		duration = tonumber(duration) or 0

		if index % 10 == 1 then
			y = math.floor(index / 10) * 14
			x = 0
		else
			x = (index - 1) * 14
		end
	
		btn:SetPoint("TOPLEFT", frame.buffs, "TOPLEFT", x, y)
		btn.icon:SetTexture(icon)

		local stacks = tonumber(count) or 0
		btn.count:SetText(stacks > 1 and stacks or "")
		btn.cd:SetCooldown(expires - duration, duration)
		btn:Show()

		index = index + 1
	end

	frame.buffs:SetHeight(math.ceil(index/10)*22)

	for i = index, #frame.buffs.icons do
		frame.buffs.icons[i]:Hide()
	end

	index = 1
	y = 0
	x = 0

	for i = 1, 40 do
		local name, icon, count, debuffType, duration, expires = UnitDebuff(unit, i)
		if not name then break end

		local btn = frame.debuffs.icons[index]
		if not btn then
			btn = CreateAuraIcon(frame.debuffs)
			frame.debuffs.icons[index] = btn
		end

		duration = tonumber(duration) or 0

		if index % 10 == 1 then
			y = math.floor(index / 10) * 14
			x = 0
		else
			x = (index - 1) * 14
		end

		btn:SetPoint("TOPLEFT", frame.debuffs, "TOPLEFT", x, y)
		btn.icon:SetTexture(icon)
		local stacks = tonumber(count) or 0
		btn.count:SetText(stacks > 1 and stacks or "")
		btn.cd:SetCooldown(expires - duration, duration)

		local color = DebuffTypeColor[debuffType or "none"]
		btn.border:SetVertexColor(color.r, color.g, color.b)

		btn:Show()

		index = index + 1
	end

	frame.debuffs:SetHeight(math.ceil(index/10)*22)

	for i = index, #frame.debuffs.icons do
		frame.debuffs.icons[i]:Hide()
	end
end
]]

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

local function Steak_OnUpdate(self, elapsed)
	if UnitExists(self.unit) and not UnitIsUnit("player", self.unit) then
		if CheckInteractDistance(self.unit, 1) or UnitIsUnit(self.unit, "player") then
			self:SetAlpha(1)
		else
			self:SetAlpha(0.2)
		end
	end
end

local function Steak_OnEvent(self, event, ...)
	if event == "PLAYER_TARGET_CHANGED" then
		if UnitExists(self.unit) and UnitIsPlayer(self.unit) and ( UnitExists("target") and UnitIsUnit(self.unit, "target") ) then
			if CanInspect(self.unit) and CheckInteractDistance(self.unit, 1) and not InCombatLockdown() then
				if not SteakInspectUnitGUID then
					--SteakInspectUnitGUID = UnitGUID(self.unit)
					NotifyInspect(self.unit)
				end
			end
		end
	elseif event == "UNIT_TARGET" then
		if UnitExists(self.unit) and UnitIsPlayer(self.unit) and UnitExists(...) and UnitIsUnit(self.unit, ...) then
			if CanInspect(self.unit) and CheckInteractDistance(self.unit, 1) and not InCombatLockdown() then
				if not SteakInspectUnitGUID then
					--SteakInspectUnitGUID = UnitGUID(self.unit)
					NotifyInspect(self.unit)
				end
			end
		end
	elseif event == "PLAYER_FOCUS_CHANGED" then
		if UnitExists(self.unit) and UnitIsPlayer(self.unit) and UnitExists("focus") and UnitIsUnit(self.unit, "focus") then
			if CanInspect(self.unit) and CheckInteractDistance(self.unit, 1) and not InCombatLockdown() then
				if not SteakInspectUnitGUID then
					--SteakInspectUnitGUID = UnitGUID(self.unit)
					NotifyInspect(self.unit)
				end
			end
		end
	end

	if event == "PLAYER_ROLES_ASSIGNED" then
		if UnitExists(self.unit) and UnitExists(...) and UnitIsUnit(self.unit, ...) then
			Steak_UpdateRole(self)
		end
	elseif event == "INSPECT_TALENT_READY" then
		if SteakInspectUnitGUID and UnitGUID(self.unit) == SteakInspectUnitGUID then
			local spec = Steak_GetSpec(self)
			Steak_UpdateRole(self)
			
			if spec then
				self.specText:SetText(spec:sub(1, 3))
				SteakInspectUnitGUID = nil
			end
		end
	elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
		if UnitExists(self.unit) then
			Steak_UpdateHealth(self)
		end
	elseif event == "UNIT_THREAT_SITUATION_UPDATE" or event == "UNIT_THREAT_LIST_UPDATE" then
		if UnitExists(self.unit) then
			Steak_UpdateThreat(self)
		end
	elseif event == "PARTY_LOOT_METHOD_CHANGED" then
		if UnitExists(self.unit) then
			UpdateRoleIcons(self)
		end
	elseif event == "UNIT_COMBO_POINTS" then
		if self.unit == "target" then
			self.cp = self.cp or {}
			local comboPoints = GetComboPoints("player", "target")
			for i=1,5 do
				local cp = self.cp[i]
				if not cp then
					cp = self:CreateTexture(nil, "OVERLAY")
					cp:SetSize(26, 6)
					cp:SetPoint("TOPLEFT", self, "BOTTOMLEFT", (i-1) * 28, -2)
					--cp:SetTexture("Interface\\ComboFrame\\ComboPoint")
					cp:SetTexture(1, 0.6, 0, 1)
					cp:SetTexCoord(0.375, 0.5625, 0, 0.375)
					self.cp[i] = cp
				end
				
				if comboPoints >= i then
					cp:Show()
				else
					cp:Hide()
				end
			end
		end
	else
		if UnitExists(self.unit) then
			Steak_UpdateHealth(self)
			Steak_UpdatePower(self)
			Steak_UpdateName(self)
			Steak_UpdateRaidIcon(self)
			Steak_UpdatePvPIcon(self)
			Steak_UpdateThreat(self)
			Steak_UpdateGS(self)
			Steak_UpdateRole(self)
			UpdateRoleIcons(self)
			--Steak_GetSpec(self)
			if SteakSpecs[UnitGUID(self.unit)] then
				self.specText:SetText(SteakSpecs[UnitGUID(self.unit)])
			end

			local index = tonumber(self.unit:match("^raid(%d+)$"))
			if index then
				local subgroup = select(3, GetRaidRosterInfo(index))

				self.groupText:SetText(subgroup)
			else
				self.groupText:SetText("")
			end
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
	frame.health = health

	local mana = CreateFrame("StatusBar", nil, frame)
	mana:SetPoint("TOPLEFT", health, "BOTTOMLEFT", 0, -1)
	mana:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
	mana:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	mana:SetMinMaxValues(0, 100)
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

	local raidIcon = health:CreateTexture(nil, "OVERLAY")
	raidIcon:SetSize(16, 16)
	raidIcon:SetPoint("CENTER", frame, "TOP", 0, 0)
	frame.raidIcon = raidIcon

	local pvpIcon = health:CreateTexture(nil, "OVERLAY")
	pvpIcon:SetSize(24, 24)
	pvpIcon:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
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

	local roleIcon = health:CreateTexture(nil, "OVERLAY")
	roleIcon:SetSize(14, 14)
	roleIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
	frame.roleIcon = roleIcon
	
	local roleText = health:CreateFontString(nil, "OVERLAY")
	roleText:SetFont("Interface\\AddOns\\SteakFrames\\Audiowide-Regular.ttf", 8, "OUTLINE")
	roleText:SetPoint("LEFT", frame.roleIcon, "RIGHT", 0, 0)
	roleText:SetTextColor(1, 1, 1)
	frame.roleText = roleText

	local specText = mana:CreateFontString(nil, "OVERLAY")
	specText:SetFont("Interface\\AddOns\\SteakFrames\\Audiowide-Regular.ttf", 8, "OUTLINE")
	specText:SetPoint("LEFT", mana, "LEFT", 2, 0)
	specText:SetTextColor(1, 1, 1)
	frame.specText = specText

	local groupText = health:CreateFontString(nil, "OVERLAY")
	groupText:SetFont("Interface\\AddOns\\SteakFrames\\Audiowide-Regular.ttf", 12, "OUTLINE")
	groupText:SetPoint("CENTER", frame, "TOP", 0, 0)
	groupText:SetText("")
	frame.groupText = groupText

	--[[
	local threatText = frame:CreateFontString(nil, "OVERLAY")
	threatText:SetFont("Interface\\AddOns\\SteakFrames\\Audiowide-Regular.ttf", 8, "OUTLINE")
	threatText:SetPoint("BOTTOM", frame, "TOP", 0, 2)
	threatText:SetTextColor(1, 1, 1)
	frame.threatText = threatText
	]]

	--local buffFrame = CreateFrame("Frame", nil, frame)
	--[[
	local buffFrame = CreateFrame("Frame", nil, UIParent)
	buffFrame:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -2)
	buffFrame:SetSize(frame:GetWidth(), 20)
	buffFrame:EnableMouse(false)
	frame.buffs = buffFrame
	frame.buffs.icons = {}
	]]

	--local debuffFrame = CreateFrame("Frame", nil, frame)
	--[[
	local debuffFrame = CreateFrame("Frame", nil, UIParent)
	debuffFrame:SetPoint("TOPLEFT", buffFrame, "BOTTOMLEFT", 0, -2)
	debuffFrame:SetSize(frame:GetWidth(), 20)
	debuffFrame:EnableMouse(false)
	frame.debuffs = debuffFrame
	frame.debuffs.icons = {}
	]]

	for _, ev in ipairs(SteakUnitEvents) do
		frame:RegisterEvent(ev)
	end
	frame:SetScript("OnEvent", Steak_OnEvent)
	frame:SetScript("OnUpdate", Steak_OnUpdate)

	frame:SetScript("OnEnter", function(self)
		if not self.unit then return end

		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetUnit(self.unit)
		GameTooltip:Show()
	end)

	frame:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

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

	local petFrame = CreateSteakUnitFrame("SteakPartyPet"..i, "party"..i.."pet", 110, 40, partyParent)
	petFrame:SetPoint("BOTTOM", partyFrame, "TOP", 0, 20)
end

SteakPlayer:ClearAllPoints()
SteakPlayer:SetPoint("BOTTOM", UIParent, "BOTTOM", -150, 220)

SteakTarget:ClearAllPoints()
SteakTarget:SetPoint("BOTTOM", UIParent, "BOTTOM", 150, 220)

SteakFocus:ClearAllPoints()
SteakFocus:SetPoint("LEFT", SteakTarget, "RIGHT", 40, 0)

SteakToT:ClearAllPoints()
SteakToT:SetPoint("TOP", SteakTarget, "BOTTOM", 40, -25)

SteakPet:ClearAllPoints()
SteakPet:SetPoint("TOP", SteakPlayer, "BOTTOM", 10, -25)

local targetBuffs = CreateFrame("Frame", nil, UIParent)

targetBuffs:SetPoint("TOPLEFT", SteakTarget, "BOTTOMLEFT", 0, -18)

targetBuffs:RegisterEvent("UNIT_AURA")

targetBuffs:SetScript("OnEvent", function(self, event, unit)
	if unit == "target" then
		local index = 1

		for _, buff in ipairs(self.buffs or {}) do
			buff:Hide()
		end

		for i=1,40 do
			local name, icon, stacks, _, _, _, caster = UnitDebuff("target", i)
			
			if not name then break end

			if caster == "player" then			
				local buff = self.buffs[index]
			
				if not buff then
					buff = CreateFrame("Frame", nil, self)
					buff:SetSize(16, 16)
					
					buff.tex = buff:CreateTexture(nil, "ARTWORK")
					buff.tex:SetAllPoints(buff)
					buff.stacks = buff:CreateFontString(nil, "OVERLAY")
					buff.stacks:SetJustifyH("CENTER")
					buff.stacks:SetFont("Interface\\AddOns\\SteakFrames\\Audiowide-Regular.ttf", 6, "OUTLINE")
					buff.stacks:SetAllPoints(buff)
					buff:SetPoint("TOPLEFT", self, "TOPLEFT", (index-1)*18, 0)
				end

				buff.tex:SetTexture(icon)
				if stacks == 0 then
					buff.stacks:SetText("")
				else
					buff.stacks:SetText(stacks)
				end
				buff:Show()

				index = index + 1
			end
		end
		
		for i=1,40 do
			local name, icon, stacks, _, _, _, caster = UnitBuff("target", i)
			
			if not name then break end
			
			if caster == "player" then
				local buff = self.buffs[index]
			
				if not buff then
					buff = CreateFrame("Frame", nil, self)
					buff:SetSize(16, 16)
					
					buff.tex = buff:CreateTexture(nil, "ARTWORK")
					buff.tex:SetAllPoints(buff)
					buff.stacks = buff:CreateFontString(nil, "OVERLAY")
					buff.stacks:SetJustifyH("CENTER")
					buff.stacks:SetFont("Interface\\AddOns\\SteakFrames\\Audiowide-Regular.ttf", 6, "OUTLINE")
					buff.stacks:SetAllPoints(buff)
					buff:SetPoint("TOPLEFT", self, "TOPLEFT", (index-1)*18, 0)
				end

				buff.tex:SetTexture(icon)
				if stacks == 0 then
					buff.stacks:SetText("")
				else
					buff.stacks:SetText(stacks)
				end
				buff:Show()

				index = index + 1			
			end
		end
	end
end)

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
