local f = CreateFrame("Frame")

-- 1. CLASS COLORS FOR HEALTHBARS
local function ApplyClassColor(frame, unit)
    if not UnitExists(unit) then return end
    
    local _, class = UnitClass(unit)
    if class then
        local color = RAID_CLASS_COLORS[class]
        frame.healthbar:SetStatusBarColor(color.r, color.g, color.b)
    end
end

-- 2. ROLE ICONS FOR PORTRAITS
local function ApplyRoleIcon(portrait, unit)
    local role = UnitGroupRolesAssigned(unit)
    
    -- Only change if they actually have a role assigned
    if role == "TANK" or role == "HEALER" or role == "DAMAGER" then
        portrait:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
        portrait:SetTexCoord(GetTexCoordsForRoleSmallCircle(role))
    else
        -- Fallback to standard portrait if no role
        portrait:SetTexCoord(0, 1, 0, 1)
        SetPortraitTexture(portrait, unit)
    end
end

-- Hook the actual update function used in 3.3.5a
hooksecurefunc("PartyMemberFrame_UpdateMember", function(self)
    local unit = "party"..self:GetID()
    ApplyClassColor(self, unit)
    --ApplyRoleIcon(self, unit)
end)

hooksecurefunc("HealthBar_OnValueChanged", function(self, value)
    local parent = self:GetParent()
    if parent and parent:GetName() then
        if parent:GetName():find("PartyMemberFrame") then
            ApplyClassColor(parent, "party"..parent:GetID())
        elseif parent:GetName() == "PlayerFrame" then
            ApplyClassColor(parent, "player")
        elseif parent:GetName() == "TargetFrame" then
            ApplyClassColor(parent, "target")
        end
    end
end)

local function ReanchorPlayerFrame()
    --print("Reanchoring player frame.")
    PlayerFrame:ClearAllPoints()
    PlayerFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", -150, 200)
end

local function MoveUnitFrames()
    -- SetPoint(Point, RelativeFrame, RelativePoint, X, Y)
    
    -- Player Frame
    PlayerFrame:SetMovable(true)
    PlayerFrame:ClearAllPoints()
    PlayerFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", -150, 200)
    PlayerFrame:SetUserPlaced(true)
    PlayerFrame:SetDontSavePosition(true)

    -- Target Frame
    TargetFrame:SetMovable(true)
    TargetFrame:ClearAllPoints()
    TargetFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 150, 200)
    TargetFrame:SetUserPlaced(true)

    -- Focus Frame
    FocusFrame:SetMovable(true)
    FocusFrame:ClearAllPoints()
    FocusFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", -250, 320)
    FocusFrame:SetUserPlaced(true)

    -- Target of Target Frame
    TargetFrameToT:SetMovable(true)
    TargetFrameToT:ClearAllPoints()
    TargetFrameToT:SetPoint("BOTTOM", TargetFrame, "BOTTOM", 40, -15)
    TargetFrameToT:SetUserPlaced(true)

	for i=1,4,1 do
		local frame = _G["PartyMemberFrame"..i]

		if frame then
			frame:SetMovable(true)
			frame:ClearAllPoints()
			if i == 1 then
				frame:SetPoint("BOTTOM", UIParent, "BOTTOM", -275, 300)
			else
				frame:SetPoint("LEFT", _G["PartyMemberFrame"..(i-1)], "RIGHT", 40, 0)
			end
			frame:SetUserPlaced(true)
		end
	end
end

local function OnEvent(self, event, ...)
	MoveUnitFrames()
	ReanchorPlayerFrame()

	if event == "UNIT_EXITED_VEHICLE" or event == "UNIT_ENTERED_VEHICLE" or event == "VEHICLE_UPDATED" then
		self.lastExit = GetTime()
	end
end

local function OnUpdate(self, elapsed)
    self.timer = (self.timer or 0) + elapsed

    if self.timer >= 0.5 then
        if GetNumPartyMembers() > 0 then
            for i=1,MAX_PARTY_MEMBERS do
                local unit = "party"..i
                local unitFrame = _G["PartyMemberFrame"..i]

                if unitFrame and UnitExists(unit) then
                    if UnitInRange(unit) then
                        unitFrame:SetAlpha(1)
                    else
                        unitFrame:SetAlpha(0.4)
                    end
                end
            end
        end

	if not InCombatLockdown() then
		if self.needMove then
			MoveUnitFrames()

			self.needMove = nil
		end

		if self.lastExit and GetTime() - self.lastExit > 0.2 then
			ReanchorPlayerFrame()
			self.lastExit = nil
		end
	end

        self.timer = 0
    end
end

hooksecurefunc("PlayerFrame_ToPlayerArt", ReanchorPlayerFrame)
hooksecurefunc("PlayerFrame_ToVehicleArt", ReanchorPlayerFrame)

f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("UNIT_ENTERED_VEHICLE")
f:RegisterEvent("UNIT_EXITED_VEHICLE")
f:RegisterEvent("VEHICLE_UPDATED")

f:SetScript("OnEvent", OnEvent)
f:SetScript("OnUpdate", OnUpdate)

hooksecurefunc("CastingBarFrame_OnShow", function(self)
    self:ClearAllPoints()
    if GetNumPartyMembers() > 0 then
        self:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 370)
    else
        self:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 350)
    end
end)