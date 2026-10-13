local Steak = Steak

local Module = {}

Module.events = {
	"PLAYER_XP_UPDATE",
	"PLAYER_LEVEL_UP",
	"UPDATE_EXHAUSTION",
	"PLAYER_ENTERING_WORLD"
}

function Module:CreateFrame(frame)
	if frame.unit ~= "player" then return end

	frame.xp = Steak:CreateStatusBar(frame)
	frame.xp:SetHeight(8)
	frame.xp:SetPoint("TOPLEFT", frame.mana, "BOTTOMLEFT", 0, -2)
	frame.xp:SetPoint("TOPRIGHT", frame.mana, "BOTTOMRIGHT", 0, -2)
	frame.xp:SetMinMaxValues(0, 1)

	frame.xpText = Steak:CreateFont(frame.xp, 7)
	frame.xpText:SetPoint("CENTER")

	frame.xp.tick = frame.xp:CreateTexture(nil, "OVERLAY")
	frame.xp.tick:SetSize(2, 10)
	frame.xp.tick:SetTexture("Interface\\Buttons\\WHITE8x8")
end

function Module:UpdateFrame(frame)
	if frame.unit ~= "player" then return end

	local current = UnitXP("player")
	local maximum = UnitXPMax("player")
	local rested = GetXPExhaustion() or 0

	if maximum <= 0 then
		frame.xp:SetValue(1)
		frame.xpText:SetText("MAX LEVEL")
		frame.xp.tick:Hide()
		return
	end

	frame.xp:SetMinMaxValues(0, maximum)
	frame.xp:SetValue(current)
	frame.xpText:SetText(string.format("%d%%", math.floor(current / maximum * 100)))

	if rested > 0 then
		frame.xp:SetStatusBarColor(0, .40, 1)

		local percent = math.min(1, (current + rested) / maximum)

		frame.xp.tick:ClearAllPoints()
		frame.xp.tick:SetPoint("CENTER", frame.xp, "LEFT", percent * frame.xp:GetWidth(), 0)
		frame.xp.tick:Show()
	else
		frame.xp:SetStatusBarColor(0, .80, 1)
		frame.xp.tick:Hide()
	end
end

function Module:OnEvent()
	self:UpdateFrame(Steak.Player)
end

Steak:RegisterModule(Module)
