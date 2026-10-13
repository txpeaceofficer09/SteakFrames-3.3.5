local Steak = Steak

local Module = {}

Module.events = {
	"UNIT_POWER_UPDATE",
	"UNIT_MAXPOWER",
	"UPDATE_SHAPESHIFT_FORM",
	"PLAYER_ENTERING_WORLD"
}

function Module:CreateFrame(frame)
	if frame.unit ~= "player" or select(2, UnitClass("player")) ~= "DRUID" then return end

	frame.druidMana = Steak:CreateStatusBar(frame)
	frame.druidMana:SetHeight(8)
	frame.druidMana:SetPoint("TOPLEFT", frame.mana, "BOTTOMLEFT", 0, -2)
	frame.druidMana:SetPoint("TOPRIGHT", frame.mana, "BOTTOMRIGHT", 0, -2)

	frame.druidMana:SetStatusBarColor(0, .55, 1)

	frame.druidManaText = Steak:CreateFont(frame.druidMana, 7)
	frame.druidManaText:SetPoint("RIGHT", -2, 0)

	RegisterStateDriver(frame.druidMana, "visibility", "[form:1][form:3] show; hide")
end

function Module:UpdateFrame(frame)
	if frame.unit ~= "player" or not frame.druidMana then return end

	local mana = UnitPower("player", SPELL_POWER_MANA) or 0
	local maxMana = UnitPowerMax("player", SPELL_POWER_MANA) or 1

	if maxMana <= 0 then maxMana = 1 end

	if frame.xp and frame.xp:IsVisible() then
		frame.druidMana:ClearAllPoints()
		frame.druidMana:SetPoint("TOPLEFT", frame.xp, "BOTTOMLEFT", 0, -2)
		frame.druidMana:SetPoint("TOPRIGHT", frame.xp, "BOTTOMRIGHT", 0, -2)
	else
		frame.druidMana:ClearAllPoints()
		frame.druidMana:SetPoint("TOPLEFT", frame.mana, "BOTTOMLEFT", 0, -2)
		frame.druidMana:SetPoint("TOPRIGHT", frame.mana, "BOTTOMRIGHT", 0, -2)
	end

	frame.druidMana:SetMinMaxValues(0, maxMana)
	frame.druidMana:SetValue(mana)
	frame.druidManaText:SetText(string.format("%d / %d", mana, maxMana))
end

function Module:OnEvent()
	self:UpdateFrame(Steak.Player)
end

Steak:RegisterModule(Module)
