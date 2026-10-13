local Steak = Steak

local Module = {}

Module.events = {
	"UNIT_POWER_UPDATE",
	"UNIT_POWER",
	"UNIT_MAXPOWER",

	"UNIT_MANA",
	"UNIT_RAGE",
	"UNIT_FOCUS",
	"UNIT_ENERGY",
	"UNIT_RUNIC_POWER",

	"UNIT_MAXMANA",
	"UNIT_MAXRAGE",
	"UNIT_MAXFOCUS",
	"UNIT_MAXENERGY",
	"UNIT_MAXRUNIC_POWER",

	"UNIT_DISPLAYPOWER",

	"PLAYER_ENTERING_WORLD"
}

function Module:UpdateFrame(frame)
	if not frame.unit or not UnitExists(frame.unit) then return end

	local power = UnitPower(frame.unit) or 0
	local maxPower = UnitPowerMax(frame.unit) or 1
	if maxPower <= 0 then maxPower = 1 end

	frame.mana:SetMinMaxValues(0, maxPower)
	frame.mana:SetValue(power)

	local powerType, token = UnitPowerType(frame.unit)
	token = token or powerType

	local color = Steak.PowerColors[token]
	if color then
		frame.mana:SetStatusBarColor(color[1], color[2], color[3])
	else
		frame.mana:SetStatusBarColor(0.20, 0.50, 1.00)
	end

	frame.mpText:SetText(string.format("%d / %d", power, maxPower))
end

function Module:OnEvent(event, unit)
	if event == "PLAYER_ENTERING_WORLD" then
		Steak:ForEachFrame(function(frame)
			self:UpdateFrame(frame)
		end)
		return
	end

	for _, frame in ipairs(Steak.Frames) do
		if frame.unit == unit then
			self:UpdateFrame(frame)
		end
	end
end

function Module:OnUpdate(elapsed)
	self.timer = (self.timer or 0) + elapsed
	if self.timer < 0.1 then return end

	self.timer = 0

	for _, frame in ipairs(Steak.Frames) do
		self:UpdateFrame(frame)
	end
end

Steak:RegisterModule(Module)
