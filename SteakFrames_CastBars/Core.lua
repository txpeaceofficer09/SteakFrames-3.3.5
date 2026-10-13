local Steak = Steak

local Module = {}

Module.events = {
	"UNIT_SPELLCAST_START",
	"UNIT_SPELLCAST_STOP",
	"UNIT_SPELLCAST_FAILED",
	"UNIT_SPELLCAST_INTERRUPTED",
	"UNIT_SPELLCAST_CHANNEL_START",
	"UNIT_SPELLCAST_CHANNEL_UPDATE",
	"UNIT_SPELLCAST_CHANNEL_STOP"
}

function Module:CreateFrame(frame)
	frame.castBar = Steak:CreateStatusBar(frame)
	frame.castBar:SetHeight(10)
	frame.castBar:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -20)
	frame.castBar:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, -20)

	frame.castBar.text = Steak:CreateFont(frame.castBar, 8)
	frame.castBar.text:SetPoint("LEFT", 2, 0)

	frame.castBar.time = Steak:CreateFont(frame.castBar, 8)
	frame.castBar.time:SetPoint("RIGHT", -2, 0)

	frame.castBar:Hide()
end

function Module:StartCast(frame, channel)
	if not frame or not frame.castBar or not UnitExists(frame.unit) then
		return
	end

	local name, _, _, _, startTime, endTime

	if channel then
		name, _, _, _, startTime, endTime = UnitChannelInfo(frame.unit)
	else
		name, _, _, _, startTime, endTime = UnitCastingInfo(frame.unit)
	end

	if not name or not startTime or not endTime then
		frame.castBar:Hide()
		return
	end

	startTime = startTime / 1000
	endTime = endTime / 1000

	frame.castBar.startTime = startTime
	frame.castBar.endTime = endTime
	frame.castBar.channeling = channel
	frame.castBar.duration = endTime - startTime

	frame.castBar:SetMinMaxValues(0, frame.castBar.duration)
	frame.castBar:SetValue(channel and frame.castBar.duration or 0)
	frame.castBar.text:SetText(name)

	frame.castBar:ClearAllPoints()
	if frame.druidMana and frame.druidMana:IsShown() then
		frame.castBar:SetPoint("TOPLEFT", frame.druidMana, "BOTTOMLEFT", 0, -2)
		frame.castBar:SetPoint("TOPRIGHT", frame.druidMana, "BOTTOMRIGHT", 0, -2)
	elseif frame.xp and frame.xp:IsShown() then
		frame.castBar:SetPoint("TOPLEFT", frame.xp, "BOTTOMLEFT", 0, -2)
		frame.castBar:SetPoint("TOPRIGHT", frame.xp, "BOTTOMRIGHT", 0, -2)
	else
		frame.castBar:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -2)
		frame.castBar:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, -2)
	end

	frame.castBar:Show()
end

function Module:StopCast(frame)
	if frame and frame.castBar then
		frame.castBar:Hide()
	end
end

function Module:OnEvent(event, unit)
	for _, frame in ipairs(Steak.Frames) do
		if frame.unit == unit then
			if event == "UNIT_SPELLCAST_START" then
				self:StartCast(frame, false)
			elseif event == "UNIT_SPELLCAST_CHANNEL_START"
				or event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
				self:StartCast(frame, true)
			else
				self:StopCast(frame)
			end
		end
	end
end

function Module:Update()
	local now = GetTime()

	for _, frame in ipairs(Steak.Frames) do
		local bar = frame.castBar

		if bar and bar:IsShown() then
			local remaining = bar.endTime - now

			if remaining <= 0 then
				self:StopCast(frame)
			elseif bar.channeling then
				bar:SetValue(remaining)
				bar.time:SetText(string.format("%.1f", remaining))
			else
				local elapsed = now - bar.startTime
				bar:SetValue(elapsed)
				bar.time:SetText(
					string.format("%.1f / %.1f", elapsed, bar.duration)
				)
			end
		end
	end
end

function Module:OnUpdate(elapsed)
	self:Update()
end

--[[
local timer = CreateFrame("Frame")
timer:SetScript("OnUpdate", function(_, elapsed)
	Module:Update()
end)
]]

Steak:RegisterModule(Module)
