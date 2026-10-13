local Steak = Steak

local Module = {}

Module.events = {
	"UNIT_INVENTORY_CHANGED",
	"PLAYER_ENTERING_WORLD",
	"CHAT_MSG_ADDON"
}

Module.gearScores = {}

local slots = {
	"HeadSlot",
	"NeckSlot",
	"ShoulderSlot",
	"BackSlot",
	"ChestSlot",
	"WristSlot",
	"HandsSlot",
	"WaistSlot",
	"LegsSlot",
	"FeetSlot",
	"Finger0Slot",
	"Finger1Slot",
	"Trinket0Slot",
	"Trinket1Slot",
	"MainHandSlot",
	"SecondaryHandSlot",
	"RangedSlot"
}

function Module:GetGearScoreColor(score)
	if not score or type(score) ~= "number" then return "|cffb0b0b0" end

	if GearScore_GetQualityColor then
		local r, g, b = GearScore_GetQualityColor(score)

		if r and g and b then
			return ("|cff%02x%02x%02x"):format(r * 255, g * 255, b * 255)
		end
	end

	-- Fallback if the installed GearScore version doesn't expose
	-- a public color function.
	if score >= 5000 then
		return "|cffff8000" -- Orange
	elseif score >= 4000 then
		return "|cffa335ee" -- Purple
	elseif score >= 3000 then
		return "|cff0070dd" -- Blue
	elseif score >= 2000 then
		return "|cff1eff00" -- Green
	end

	return "|cffb0b0b0" -- Gray
end

function Module:CreateFrame(frame)
	frame.gearText = Steak:CreateFont(frame, 8)
	frame.gearText:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 2, 2)
end

function Module:UpdateFrame(frame)
	if not frame.gearText then return end

	if not UnitIsPlayer(frame.unit) then
		frame.gearText:SetText("")
		return
	end

	if not IsAddOnLoaded("GearScore") then
		frame.gearText:SetText("")
		return
	end

	local totalScore = 0
	local totalItemLevel = 0
	local itemCount = 0

	for _, slotName in ipairs(slots) do
		local slotID = GetInventorySlotInfo(slotName)
		local itemLink = GetInventoryItemLink(frame.unit, slotID)

		if itemLink then
			local _, _, _, itemLevel = GetItemInfo(itemLink)
			local score = GearScore_GetItemScore(itemLink)

			if score then
				totalScore = totalScore + score
			end

			if itemLevel then
				totalItemLevel = totalItemLevel + itemLevel
				itemCount = itemCount + 1
			end
		end
	end

	if itemCount == 0 then
		if self.gearScores[UnitName(frame.unit)] then
	 		frame.gearText:SetText(("|cffffff00GS:%s%d|r |cffb0b0ffiLvl:%.1f|r"):format(self.GetGearScoreColor(self.gearScores[UnitName(frame.unit)].gs), self.gearScores[UnitName(frame.unit)].gs, self.gearScores[UnitName(frame.unit)].ilvl))
		else
			frame.gearText:SetText("")
		end
		return
	end

	local gs = totalScore
	local ilvl = totalItemLevel / itemCount

	self.gearScores[UnitName(frame.unit)] = { ["ilvl"] = ilvl, ["gs"] = gs }

	frame.gearText:SetText(("|cffffff00GS:%d|r |cffb0b0ffiLvl:%.1f|r"):format(gs, ilvl))
end

function Module:OnEvent(event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		Steak:ForEachFrame(function(frame)
			self:UpdateFrame(frame)
		end)
		return
	end

	if event == "CHAT_MSG_ADDON" then
		--print(...)
		return
	end

	local unit = ...

	for _, frame in ipairs(Steak.Frames) do
		if frame.unit == unit then
			self:UpdateFrame(frame)
		end
	end
end

Steak:RegisterModule(Module)
