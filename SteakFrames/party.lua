CreateFrame("Frame", "SteakPartyFrame", UIParent, "SecureHandlerStateTemplate")
SteakPartyFrame:SetSize((100 * 4) + (2 * 3), 40)
SteakPartyFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 320)

RegisterStateDriver(SteakPartyFrame, "visibility", "[group:party] show; hide")

local events = {
	"PLAYER_ENTERING_WORLD",
	"PLAYER_ROLES_ASSIGNED",
	"PARTY_MEMBERS_CHANGED",
	"PARTY_LEADER_CHANGED",
	"PARTY_LOOT_METHOD_CHANGED",
	"GROUP_ROSTER_UPDATE",
	"RAID_TARGET_UPDATE",
	"UNIT_HEALTH",
	"UNIT_MANA",
	"UNIT_ENERGY",
	"UNIT_RAGE",
	"UNIT_RUNIC_POWER",
	"UNIT_DISPLAYPOWER",
	"UNIT_MAXHEALTH",
	"UNIT_FACTION",
	"UNIT_THREAT_SITUATION_UPDATE",
	"UNIT_THREAT_LIST_UPDATE",
    "UNIT_INVENTORY_CHANGED",
	"UNIT_TARGET"
}

local function UpdateThreat(self)
    local threat = UnitThreatSituation(self.unit)

    if threat == 3 then
        -- securely tanking
        self.bg:SetVertexColor(1, 0, 0, 0.8)   -- red glow
    elseif threat == 2 then
        self.bg:SetVertexColor(1, 0.5, 0, 0.8) -- orange
    elseif threat == 1 then
        self.bg:SetVertexColor(1, 1, 0, 0.8)   -- yellow
    else
        self.bg:SetVertexColor(0, 0, 0, 0.8)   -- normal
    end
end

local function UpdateRaidIcon(self)
    local iconIndex = GetRaidTargetIndex(self.unit)

    if iconIndex then
        local idx = iconIndex - 1
        local left = (idx % 4) * 0.25
        local right = left + 0.25
        local top = math.floor(idx / 4) * 0.25
        local bottom = top + 0.25

        -- Clamp to avoid 1.0 (invalid)
        if right >= 1 then right = 0.9999 end
        if bottom >= 1 then bottom = 0.9999 end

        self.raidIcon:SetTexCoord(left, right, top, bottom)
        self.raidIcon:Show()
    else
        self.raidIcon:Hide()
    end
end

local function UpdatePvPIcon(self)
    if UnitIsPVP(self.unit) then
        local faction = UnitFactionGroup(self.unit)

        if faction == "Alliance" then
            self.pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-Alliance")
        elseif faction == "Horde" then
            self.pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-Horde")
        end

        self.pvpIcon:Show()
    else
        self.pvpIcon:Hide()
    end
end

local function UpdateRoleIcon(self)
    local role = UnitGroupRolesAssigned(self.unit)

    if role and role ~= "NONE" then
        if role == "TANK" then 
            self.roleIcon:SetTexCoord(0, 19/64, 22/64, 41/64)
        elseif role == "HEALER" then 
            self.roleIcon:SetTexCoord(20/64, 39/64, 1/64, 20/64)
        elseif role == "DAMAGER" then 
            self.roleIcon:SetTexCoord(20/64, 39/64, 22/64, 41/64) 
        end

        self.roleIcon:Show()
    else
        self.roleIcon:Hide()
    end
end

local function UpdatePower(self)
    local power = UnitPower(self.unit) or 1
    local powerMax = UnitPowerMax(self.unit) or 1

    self.mana:SetValue((power/powerMax) * 100)
            
    local pType = UnitPowerType(self.unit)
    local pColor = pType and PowerBarColor[pType] or {r=0, g=0, b=1}

    self.mana:SetStatusBarColor(pColor.r, pColor.g, pColor.b)
end

local function UpdateHealth(self)
    local hp = UnitHealth(self.unit) or 1
    local hpMax = UnitHealthMax(self.unit) or 1
    local class = select(2, UnitClass(self.unit)) or ""
    local color = class and RAID_CLASS_COLORS[class] or {r=0, g=1, b=0}

    self.health:SetValue((hp/hpMax) * 100)
    self.health:SetStatusBarColor(color.r, color.g, color.b)
end

local function UpdateLeaderIcon(self)
    if UnitIsPartyLeader(self.unit) then
        self.leaderIcon:Show()
    else
        self.leaderIcon:Hide()
    end
end

local function UpdateName(self)
    local isDead = UnitIsDeadOrGhost(self.unit)
    local isConnected = UnitIsConnected(self.unit)

    if isDead then
        self.nameText:SetText("DEAD")
    elseif not isConnected then
        self.nameText:SetText("OFFLINE")
    else
        self.nameText:SetText(UnitName(self.unit) or "Unknown")
    end
end

local function CalculateItemLevel(unit)
    local total, count = 0, 0

    for slot = 1, 17 do
        if slot ~= 4 then -- skip shirt
            local link = GetInventoryItemLink(unit, slot)
            if link then
                local _, _, _, ilvl = GetItemInfo(link)
                if ilvl then
                    total = total + ilvl
                    count = count + 1
                end
            end
        end
    end

    if count > 0 then
        return math.floor(total / count)
    end
end

local function CalculateGearScore(unit)
    local total = 0

    for slot = 1, 17 do
        if slot ~= 4 then
            local link = GetInventoryItemLink(unit, slot)
            if link then
                if IsAddOnLoaded("GearScore") then
                    total = total + GearScore_GetItemScore(link)
                else
                    local _, _, quality, ilvl = GetItemInfo(link)
                    if ilvl and quality then
                        local slotMod = (slot == 16 or slot == 17) and 0.3164 or 1
                        total = total + (ilvl * (quality + 1) * slotMod)
                    end
                end
            end
        end
    end

    return math.floor(total)
end

local function UpdateGearInfo(frame)
    local unit = frame.unit
    if not UnitExists(unit) or not UnitIsPlayer(unit) then
        frame.ilvlText:SetText("")
        frame.gsText:SetText("")
        return
    end

    if CheckInteractDistance(unit, 1) then
        local ilvl = CalculateItemLevel(unit)
        local gs = CalculateGearScore(unit)
        frame.needInspect = nil
    else
        frame.needInspect = true
    end

    frame.ilvlText:SetText(ilvl and ("iLvl: "..ilvl) or "iLvl: ?")
    frame.gsText:SetText(gs and ("GS: "..gs) or "GS: ?")
end

local function OnEvent(self, event, ...)
    if self[event] then
        self[event](self, event, ...)
    else
        print("|cffff8040[SteakFrames]:|r unhandled event (|cff00ff00"..event.."|r)")
    end
end

for i=1,4 do
    local unit = "party"..i
    local partyFrame = CreateFrame("Button", "SteakParty"..i, SteakPartyFrame, "SecureUnitButtonTemplate, SecureHandlerStateTemplate")

    partyFrame:SetSize(100, 50)

    local bg = partyFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(partyFrame)
    bg:SetTexture(0, 0, 0, 0.8)
    partyFrame.bg = bg

    local leftText = partyFrame:CreateFontString(nil, "GameFontNormalSmall")
    leftText:SetPoint("TOPLEFT", partyFrame, "TOPLEFT", 2, -2)
    partyFrame.leftText = leftText

    local rightText = partyFrame:CreateFontString(nil, "GameFontNormalSmall")
    rightText:SetPoint("TOPRIGHT", partyFrame, "TOPRIGHT", -2, -2)
    --rightText:JustifyH("RIGHT")
    partyFrame.rightText = rightText

    partyFrame:SetAttribute("unit", unit)
    partyFrame.unit = unit
    partyFrame:SetAttribute("*type1", "target") -- Left click targets
    partyFrame:SetAttribute("*type2", "menu")
    partyFrame:RegisterForClicks("AnyUp")

    partyFrame.menu = function(self)
        HideDropDownMenu(1)
        GroupMenu:SetParent(self)
        ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..i.."DropDown"], "cursor", 0, 0)
    end
    
    partyFrame:SetAttribute("type2", "menu")
    partyFrame.SetAttribute(partyFrame, "menu", function(self)
        UnitPopup_ShowMenu(self, "PARTY", self.unit, UnitName(self.unit))
    end)

    local health = CreateFrame("StatusBar", nil, partyFrame)
    health:SetPoint("TOPLEFT", partyFrame, "TOPLEFT", 2, -18)
    health:SetPoint("BOTTOMRIGHT", partyFrame, "BOTTOMRIGHT", -2, 12) -- Leave room for mana
    health:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    health:GetStatusBarTexture():SetHorizTile(false)
    health:SetMinMaxValues(0, 100)
    partyFrame.health = health

    local mana = CreateFrame("StatusBar", nil, partyFrame)
    mana:SetPoint("TOPLEFT", health, "BOTTOMLEFT", 0, -1)
    mana:SetPoint("BOTTOMRIGHT", partyFrame, "BOTTOMRIGHT", -2, 2)
    mana:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    mana:SetMinMaxValues(0, 100)
    partyFrame.mana = mana

    local name = health:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    name:SetPoint("CENTER", health, "CENTER", 0, 0)
    --name:SetPoint("TOPLEFT", health, "TOPLEFT", 2, -2)
    name:SetTextColor(1, 1, 1)
    partyFrame.nameText = name

    local gsText = partyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    gsText:SetPoint("TOPLEFT", partyFrame, "TOPLEFT", 2, -2)
    gsText:SetTextColor(1, 1, 1)
    partyFrame.gsText = gsText

    local ilvlText = partyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ilvlText:SetPoint("TOPRIGHT", partyFrame, "TOPRIGHT", -2, -2)
    gsText:SetTextColor(1, 1, 1)
    partyFrame.ilvlText = ilvlText

    --local roleIcon = health:CreateTexture(nil, "OVERLAY")
    local roleIcon = partyFrame:CreateTexture(nil, "OVERLAY")
    roleIcon:SetSize(14, 14)
    roleIcon:SetPoint("LEFT", health, "LEFT", 2, 0)
    roleIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
    partyFrame.roleIcon = roleIcon

    --local raidIcon = health:CreateTexture(nil, "OVERLAY")
    local raidIcon = partyFrame:CreateTexture(nil, "OVERLAY")
    raidIcon:SetSize(14, 14)
    raidIcon:SetPoint("RIGHT", health, "RIGHT", -2, 0)
    raidIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    partyFrame.raidIcon = raidIcon

    local leaderIcon = health:CreateTexture(nil, "OVERLAY")
    leaderIcon:SetSize(14, 14)
    leaderIcon:SetPoint("TOPLEFT", partyFrame, "TOPLEFT", 0, 10) -- Adjust to your liking
    leaderIcon:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
    partyFrame.leaderIcon = leaderIcon

    local pvpIcon = health:CreateTexture(nil, "OVERLAY")
    pvpIcon:SetSize(24, 24) -- PvP icons usually look better slightly larger
    pvpIcon:SetPoint("LEFT", partyFrame, "RIGHT", -5, 0)
    partyFrame.pvpIcon = pvpIcon

    if i == 1 then
        partyFrame:SetPoint("BOTTOMLEFT", SteakPartyFrame, "BOTTOMLEFT", 0, 0)
    else
        partyFrame:SetPoint("LEFT", _G["SteakParty"..(i-1)], "RIGHT", 2, 0)
    end

    RegisterStateDriver(partyFrame, "visibility", "[@party"..i..",exists] show; hide")

    for _, event in ipairs(events) do
        partyFrame:RegisterEvent(event)
    end

    partyFrame:HookScript("OnEnter", function(self)
        if CheckInteractDistance(self.unit, 1) and not self.inspecting then
            NotifyInspect(self.unit)
            self.inspecting = true
        end
    end)

    partyFrame:HookScript("OnUpdate", function(self, elapsed)
        self.timer = (self.timer or 0) + elapsed

        if self.timer >= 0.2 then
            if CheckInteractDistance(self.unit, 1) and not self.inspecting and self.needsInspect then
                NotifyInspect(self.unit)
                UpdateGearInfo(self)
                self.inspecting = true
                self.needsInspect = nil
            end

            self.timer = 0
        end
    end)

    function partyFrame:PLAYER_ENTERING_WORLD(_, ...)
        local unit = self.unit

        if UnitExists(unit) then
            UpdateHealth(self)
            UpdateName(self)
            UpdatePower(self)
            UpdateRoleIcon(self)
            UpdateRaidIcon(self)
            UpdateLeaderIcon(self)
            UpdatePvPIcon(self)
            UpdateThreat(self)
            UpdateGearInfo(self)
        end
    end

    function partyFrame:PLAYER_ROLES_ASSIGNED(_, ...)
        UpdateRoleIcon(self)
    end

    function partyFrame:PARTY_MEMBERS_CHANGED(_, ...)
        local unit = self.unit

        if UnitExists(unit) then
            UpdateHealth(self)
            UpdateName(self)
            UpdatePower(self)
            UpdateRoleIcon(self)
            UpdateRaidIcon(self)
            UpdateLeaderIcon(self)
            UpdatePvPIcon(self)
            UpdateThreat(self)
            UpdateGearInfo(self)
        end

        if CheckInteractDistance(unit, 1) and not self.inspecting then
            NotifyInspect(unit)
            self.inspecting = true
        else
            self.needsInspect = true
        end
    end

    function partyFrame:PARTY_LEADER_CHANGED(_, ...)
        UpdateLeaderIcon(self)
    end

    function partyFrame:PARTY_LOOT_METHOD_CHANGED(_, ...)

    end

    function partyFrame:GROUP_ROSTER_UPDATE(_, ...)
        local unit = self.unit

        if UnitExists(unit) then
            UpdateHealth(self)
            UpdateName(self)
            UpdatePower(self)
            UpdateRoleIcon(self)
            UpdateRaidIcon(self)
            UpdateLeaderIcon(self)
            UpdatePvPIcon(self)
            UpdateThreat(self)
            UpdateGearInfo(self)
        end
    end

    function partyFrame:RAID_TARGET_UPDATE(_, ...)
        if unit == self.unit then
            UpdateRaidIcon(self)
        end
    end

    function partyFrame:UNIT_HEALTH(_, unit)
        if unit == self.unit then
            UpdateHealth(self)
            UpdateName(self)
        end
    end

    function partyFrame:UNIT_MANA(_, unit)
        if unit == self.unit then
            UpdatePower(self)
        end
    end

    function partyFrame:UNIT_ENERGY(_, unit)
        if unit == self.unit then
            UpdatePower(self)
        end
    end

    function partyFrame:UNIT_RAGE(_, unit)
        if unit == self.unit then
            UpdatePower(self)
        end
    end

    function partyFrame:UNIT_RUNIC_POWER(_, unit)
        if unit == self.unit then
            UpdatePower(self)
        end
    end

    function partyFrame:UNIT_DISPLAYPOWER(_, unit)
        if unit == self.unit then
            UpdatePower(self)
        end
    end

    function partyFrame:UNIT_MAXHEALTH(_, unit)
        if unit == self.unit then
            UpdateHealth(self)
        end
    end

    function partyFrame:UNIT_FACTION(_, unit)
        if unit == self.unit then
            UpdatePvPIcon(self)
        end
    end

    function partyFrame:UNIT_THREAT_SITUATION_UPDATE(_, unit)
        if unit == self.unit then
            UpdateThreat(self)
        end
    end

    function partyFrame:UNIT_THREAT_LIST_UPDATE(_, unit)
        if unit == self.unit then
            UpdateThreat(self)
        end
    end

    function partyFrame:UNIT_TARGET(_, unit)

    end

    function partyFrame:UNIT_INVENTORY_CHANGED(_, unit)
        if unit == self.unit then
            UpdateGearInfo(self)
        end
    end

    function partyFrame:INSPECT_READY(_, guid)
        local unit = self.unit
        local unitGUID = UnitGUID(unit)

        if guid == unitGUID then
            UpdateGearInfo(self)

            self.needsInspect = nil
            self.inspecting = nil
        end
    end

    partyFrame:SetScript("OnEvent", OnEvent)
end

for i=1,4 do
    local frame = _G["PartyMemberFrame"..i]

    frame:UnregisterAllEvents()
    frame:HookScript("OnShow", function(self) self:Hide() end)
    frame:Hide()
end 