local Steak = Steak

local Module = {}

Module.events = {
	"UNIT_HEALTH",
	"UNIT_MAXHEALTH",
	"UNIT_HEALTH_FREQUENT",
	"UNIT_FLAGS",
	"PLAYER_ENTERING_WORLD",
	"UNIT_TARGET"
}

function Module:CreateFrame(frame)
	-- Core owns the health bar; this module only owns its behavior.
end

function Module:UpdateFrame(frame)
	if not frame.unit or not UnitExists(frame.unit) then return end

	local hp = UnitHealth(frame.unit) or 0
	local maxHP = UnitHealthMax(frame.unit) or 1
	if maxHP <= 0 then maxHP = 1 end

	local percent = hp / maxHP
	if UnitIsDeadOrGhost(frame.unit) then percent = 0 end

	frame.health:SetMinMaxValues(0, 100)
	frame.health:SetValue(percent * 100)

	local _, class = UnitClass(frame.unit)
	local color = RAID_CLASS_COLORS[class]

	if not UnitIsConnected(frame.unit) then
		frame.health:SetStatusBarColor(0.5, 0.5, 0.5)
	elseif color then
		frame.health:SetStatusBarColor(color.r, color.g, color.b)
	else
		frame.health:SetStatusBarColor(0.20, 0.80, 0.20)
	end

	frame.hpText:SetText(string.format("%d / %d", hp, maxHP))

	local name = UnitName(frame.unit) or "Unknown"
	local level = UnitLevel(frame.unit) or "??"

	local text = string.format("[%s] %s", level, name)

	if UnitIsDeadOrGhost(frame.unit) then
		text = text .. "\nDEAD"
	elseif not UnitIsConnected(frame.unit) then
		text = text .. "\nOFFLINE"
	end

	frame.nameText:SetText(text)
end

function Module:OnEvent(event, unit)
	for _, frame in ipairs(Steak.Frames) do
		if not unit then
			self:UpdateFrame(frame)
			return
		end

		if event == "UNIT_TARGET" and UnitIsUnit(frame.unit, ("%starget"):format(unit)) then
			self:UpdateFrame(frame)
		elseif UnitIsUnit(frame.unit, unit) then
			self:UpdateFrame(frame)
		end
	end
end

Steak:RegisterModule(Module)
