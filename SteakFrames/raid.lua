CreateFrame("Frame", "SteakRaidFrame", UIParent, "SecureHandlerStateTemplate")
SteakRaidFrame:SetSize((100 * 10) + (2 * 9), 40)
SteakRaidFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 320)

RegisterStateDriver(SteakRaidFrame, "visibility", "[group:raid] show; hide")

for i=1,25 do
    local unit = "raid"..i
    local raidFrame = CreateFrame("Button", "SteakRaid"..i, SteakRaidFrame, "SecureUnitButtonTemplate, SecureHandlerStateTemplate")

    raidFrame:SetSize(100, 34)
    
    -- Secure attributes for clicking
    raidFrame:SetAttribute("unit", unit)
    raidFrame.unit = unit
    raidFrame:SetAttribute("*type1", "target") -- Left click targets
    raidFrame:RegisterForClicks("AnyUp")

    -- 1. Health Bar
    local health = CreateFrame("StatusBar", nil, raidFrame)
    health:SetPoint("TOPLEFT", raidFrame, "TOPLEFT", 2, -2)
    health:SetPoint("BOTTOMRIGHT", raidFrame, "BOTTOMRIGHT", -2, 12) -- Leave room for mana
    health:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    health:GetStatusBarTexture():SetHorizTile(false)
    health:SetMinMaxValues(0, 100)
    raidFrame.health = health

    -- 2. Mana Bar
    local mana = CreateFrame("StatusBar", nil, raidFrame)
    mana:SetPoint("TOPLEFT", health, "BOTTOMLEFT", 0, -1)
    mana:SetPoint("BOTTOMRIGHT", raidFrame, "BOTTOMRIGHT", -2, 2)
    mana:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    mana:SetMinMaxValues(0, 100)
    raidFrame.mana = mana

    -- 3. Name Text
    local name = health:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    name:SetPoint("CENTER", health, "CENTER", 0, 0)
    name:SetTextColor(1, 1, 1)
    raidFrame.nameText = name

    -- Grid Positioning Logic
    if i == 1 then
        raidFrame:SetPoint("BOTTOMLEFT", SteakRaidFrame, "BOTTOMLEFT", 0, 0)
    elseif i == 11 then
        raidFrame:SetPoint("BOTTOM", SteakRaid1, "TOP", 0, 2)
    elseif i == 21 then
        raidFrame:SetPoint("BOTTOM", SteakRaid11, "TOP", 0, 2)
    else
        raidFrame:SetPoint("LEFT", _G["SteakRaid"..(i-1)], "RIGHT", 2, 0)
    end

    RegisterStateDriver(raidFrame, "visibility", "[@raid"..i..",exists] show; hide")
end

-- 4. The Update Logic
local function UpdateRaidFrames()
    for i=1, 25 do
        local frame = _G["SteakRaid"..i]
        local unit = frame.unit
        local isDead = UnitIsDeadOrGhost(unit)
        local isConnected = UnitIsConnected(unit)

        if UnitExists(unit) then
            -- Health & Class Color
            local hp = UnitHealth(unit)
            local hpMax = UnitHealthMax(unit)
            frame.health:SetValue((hp/hpMax) * 100)
            
            local _, class = UnitClass(unit)
            local color = RAID_CLASS_COLORS[class] or {r=0, g=1, b=0}
            frame.health:SetStatusBarColor(color.r, color.g, color.b)
            
            -- Name
            if isDead then
                frame.nameText:SetText("DEAD")
            elseif not isConnected then
                frame.nameText:SetText("OFFLINE")
            else
                frame.nameText:SetText(UnitName(unit))
            end
            
            -- Mana
            local power = UnitPower(unit)
            local powerMax = UnitPowerMax(unit)
            frame.mana:SetValue((power/powerMax) * 100)
            
            -- Power Color (Blue for mana, Yellow for rogue, etc.)
            local pType = UnitPowerType(unit)
            local pColor = PowerBarColor[pType] or {r=0, g=0, b=1}
            frame.mana:SetStatusBarColor(pColor.r, pColor.g, pColor.b)
        end
    end
end

-- 5. Event Handling
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
eventFrame:RegisterEvent("UNIT_HEALTH")
eventFrame:RegisterEvent("UNIT_MANA") -- Note: In 3.3.5a UNIT_MANA is separate from UNIT_ENERGY/RAGE
eventFrame:RegisterEvent("UNIT_MAXHEALTH")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", UpdateRaidFrames)