local Steak = Steak

local Module = {}

Module.events = {
	"UNIT_COMBO_POINTS",
	"PLAYER_TARGET_CHANGED"
}

function Module:CreateFrame(frame)
	if frame.unit ~= "target" then return end

	frame.comboPoints = {}

	for i = 1, 5 do
		local point = frame:CreateTexture(nil, "OVERLAY")
		point:SetSize(26, 6)
		point:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", (i - 1) * 28, -2)
		point:SetTexture("Interface\\Buttons\\WHITE8x8")
		point:SetVertexColor(1, .60, 0, 1)
		point:Hide()
		frame.comboPoints[i] = point
	end
end

function Module:UpdateFrame(frame)
	if frame.unit ~= "target" then return end

	local points = GetComboPoints("player", "target") or 0

	for i = 1, 5 do
		if points >= i then
			frame.comboPoints[i]:Show()
		else
			frame.comboPoints[i]:Hide()
		end
	end
end

function Module:OnEvent()
	self:UpdateFrame(Steak.Target)
end

Steak:RegisterModule(Module)
