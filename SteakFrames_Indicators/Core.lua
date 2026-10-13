local Steak = Steak

local Module = {}

Module.events = {
	"UNIT_FLAGS",
	"UNIT_AURA",
	"RAID_TARGET_UPDATE",
	"PLAYER_TARGET_CHANGED",
	"PLAYER_ENTERING_WORLD",
	"PARTY_LOOT_METHOD_CHANGED",
	"GROUP_ROSTER_UPDATE",
	"RAID_ROSTER_UPDATE",
	"PARTY_MEMBERS_CHANGED",
	"UNIT_TARGET",
	"READY_CHECK",
	"READY_CHECK_CONFIRM",
	"READY_CHECK_FINISHED",
	"PLAYER_ROLES_ASSIGNED"
}

-- Spell names are localized through GetSpellInfo where possible.
local SOULSTONE_AURA = GetSpellInfo(47883)

local FLAG_AURAS = {
	[GetSpellInfo(23333)] = true, -- Warsong Flag
	[GetSpellInfo(23335)] = true, -- Silverwing Flag
	[GetSpellInfo(34976)] = true, -- Netherstorm Flag
}

local ROLE_TEXCOORDS = {
	leader = { 0.00, 0.25, 0, 1 },
	dps = { 0.25, 0.50, 0, 1 },
	tank = { 0.50, 0.75, 0, 1 },
	healer = { 0.75, 1.00, 0, 1 }
}

local function CreateIndicator(parent, texture, size, point, relativeTo, relativePoint, x, y)
	local icon = parent:CreateTexture(nil, "OVERLAY")
	icon:SetSize(size, size)
	icon:SetPoint(point, relativeTo, relativePoint, x, y)
	icon:SetTexture(texture)
	icon:Hide()
	return icon
end

function Module:CreateFrame(frame)
	frame.indicators = {}

	frame.pvpIcon = CreateIndicator(frame.health, nil, 20, "CENTER", frame.health, "TOPRIGHT", -2, -2)
	frame.leaderIcon = CreateIndicator(frame.health, "Interface\\GroupFrame\\UI-Group-LeaderIcon", 14, "RIGHT", frame.pvpIcon, "LEFT", -2, 2)
	frame.raIcon = CreateIndicator(frame.health, "Interface\\GroupFrame\\UI-Group-AssistantIcon", 14, "RIGHT", frame.leaderIcon, "LEFT", -2, 0)
	frame.mlIcon = CreateIndicator(frame.health, "Interface\\Icons\\INV_Misc_Coin_01", 14, "RIGHT", frame.raIcon, "LEFT", -2, 0)
	frame.rcIcon = CreateIndicator(frame.health, "Interface\\RaidFrame\\ReadyCheck-NotReady", 14, "TOP", frame.pvpIcon, "BOTTOM", 0, -2)

	frame.roleIcon = CreateIndicator(frame.health, "Interface\\LFGFrame\\lfgrole", 20, "CENTER", frame.health, "TOPLEFT", 2, -2)

	frame.raidIcon = CreateIndicator(frame.health, nil, 18, "CENTER", frame.health, "TOP", 0, 0)

	frame.combatIcon = CreateIndicator(frame.health, "Interface\\CharacterFrame\\UI-StateIcon", 14, "CENTER", frame.health, "LEFT", 0, 0)
	frame.combatIcon:SetTexCoord(0.5, 1, 0, 0.5)

	frame.taggedText = Steak:CreateFont(frame, 8)
	frame.taggedText:SetPoint("BOTTOMLEFT", frame.health, "BOTTOMLEFT", 18, 3)
	frame.taggedText:Hide()

	frame.soulstoneIcon = CreateIndicator(frame.health, "Interface\\Icons\\Spell_Shadow_SoulGem", 14, "BOTTOMRIGHT", frame.health, "BOTTOMRIGHT", -2, 2)
	frame.flagCarrierIcon = CreateIndicator(frame.health, nil, 16, "TOPLEFT", frame.health, "TOPLEFT", 2, -2)
end

function Module:IsTaggedByOther(unit)
	return UnitExists(unit) and UnitIsEnemy("player", unit) and UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit)
end

function Module:HasAura(unit, auraName)
	if not auraName or not UnitExists(unit) then
		return false
	end

	for index = 1, 40 do
		local name = UnitBuff(unit, index)

		if not name then
			break
		end

		if name == auraName then
			return true
		end
	end

	return false
end

function Module:GetFlagAura(unit)
	if not UnitExists(unit) then
		return nil
	end

	for index = 1, 40 do
		local name, _, texture = UnitBuff(unit, index)

		if not name then
			break
		end

		if FLAG_AURAS[name] then
			return texture
		end
	end

	return nil
end

function Module:UpdateReadyCheck(frame)
	if not frame.unit or not UnitExists(frame.unit) or not GetReadyCheckTimeLeft() then
		frame.rcIcon:Hide()
	end

	local status = GetReadyCheckStatus(frame.unit)

	if status == "ready" then
		frame.rcIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
		frame.rcIcon:Show()
	elseif status == "notready" then
		frame.rcIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
		frame.rcIcon:Show()
	elseif status == "waiting" then
		frame.rcIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Waiting")
		frame.rcIcon:Show()
	else
		frame.rcIcon:Hide()
	end
end

function Module:UpdateFrame(frame)
	if not frame.unit or not UnitExists(frame.unit) then
		frame.pvpIcon:Hide()
		frame.raidIcon:Hide()
		frame.combatIcon:Hide()
		frame.taggedText:Hide()
		frame.soulstoneIcon:Hide()
		frame.flagCarrierIcon:Hide()
		frame.roleIcon:Hide()
		frame.raIcon:Hide()
		frame.mlIcon:Hide()
		frame.leaderIcon:Hide()

		return
	end

	local raidTarget = GetRaidTargetIndex(frame.unit)

	if raidTarget then
		frame.raidIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. raidTarget)
		frame.raidIcon:Show()
	else
		frame.raidIcon:Hide()
	end

	if UnitIsPVP(frame.unit) then
		local faction = UnitFactionGroup(frame.unit)

		if faction == "Alliance" then
			frame.pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-Alliance")
			frame.pvpIcon:Show()
		elseif faction == "Horde" then
			frame.pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-Horde")
			frame.pvpIcon:Show()
		else
			frame.pvpIcon:Hide()
		end
	else
		frame.pvpIcon:Hide()
	end

	if UnitAffectingCombat(frame.unit) then
		frame.combatIcon:Show()
	else
		frame.combatIcon:Hide()
	end

	if self:IsTaggedByOther(frame.unit) then
		frame.taggedText:SetText("|cffff2020TAGGED|r")
		frame.taggedText:Show()
	else
		frame.taggedText:Hide()
	end

	if UnitIsPartyLeader(frame.unit) and (GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0) then
		frame.leaderIcon:Show()
	else
		frame.leaderIcon:Hide()
	end

	local method, partyID, raidID = GetLootMethod()
	local masterLooter

	if method == "master" then
		if raidID then
			masterLooter = "raid" .. raidID
		elseif partyID ~= nil then
			masterLooter = partyID == 0 and "player" or "party" .. partyID
		end
	end

	if masterLooter and UnitIsUnit(frame.unit, masterLooter) then
		frame.mlIcon:Show()
	else
		frame.mlIcon:Hide()
	end

	if GetNumRaidMembers() > 0 and UnitIsRaidOfficer(frame.unit) then
		frame.raIcon:Show()
	else
		frame.raIcon:Hide()
	end

	if self:HasAura(frame.unit, SOULSTONE_AURA) then
		frame.soulstoneIcon:Show()
	else
		frame.soulstoneIcon:Hide()
	end

	local flagTexture = self:GetFlagAura(frame.unit)

	if flagTexture then
		frame.flagCarrierIcon:SetTexture(flagTexture)
		frame.flagCarrierIcon:Show()
	else
		frame.flagCarrierIcon:Hide()
	end

	if UnitGroupRolesAssigned then
		role = UnitGroupRolesAssigned(frame.unit)
	end

	if not role or role == "NONE" then
		frame.roleIcon:Hide()
	else
		frame.roleIcon:SetTexCoord(unpack(ROLE_TEXCOORDS[role]))
	end
end

function Module:OnEvent(event, unit)
	Steak:ForEachFrame(function(frame)
		if event:match("^READY_CHECK") then
			self:UpdateReadyCheck(frame)
			return
		end

		if not unit then
			self:UpdateFrame(frame)
		elseif event == "UNIT_TARGET" then
			if frame.unit and UnitIsUnit(frame.unit, unit .. "target") then
				self:UpdateFrame(frame)
			end
		elseif frame.unit and UnitIsUnit(frame.unit, unit) then
			self:UpdateFrame(frame)
		end
	end)
end

Steak:RegisterModule(Module)
