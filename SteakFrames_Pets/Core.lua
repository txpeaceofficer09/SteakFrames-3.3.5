local Steak = Steak

local Module = {}

Module.events = {
	"UNIT_PET",
	"PLAYER_PET_CHANGED",
	"PLAYER_ENTERING_WORLD"
}

function Module:UpdateFrame(frame)
	if frame.unit == "pet" then
		if UnitExists("pet") then frame:Show() else frame:Hide() end
	elseif frame.unit:match("^party%d+$") then
		-- Party pet frames are deliberately not created by Core.
		-- This module can be expanded without changing the base addon.
	end
end

function Module:OnEvent()
	if Steak.Pet then self:UpdateFrame(Steak.Pet) end
end

Steak:RegisterModule(Module)
