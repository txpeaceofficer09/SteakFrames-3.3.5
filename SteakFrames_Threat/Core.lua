local Steak = Steak

local Module = {}

Module.events = {
	"UNIT_THREAT_SITUATION_UPDATE",
	"UNIT_THREAT_LIST_UPDATE",
	"PLAYER_ENTERING_WORLD"
}

function Module:UpdateFrame(frame)
	if not frame.unit or not UnitExists(frame.unit) then return end

	local threat = UnitThreatSituation(frame.unit)

	if threat == 3 then
		frame.bg:SetVertexColor(1, 0, 0, .80)
	elseif threat == 2 then
		frame.bg:SetVertexColor(1, .50, 0, .80)
	elseif threat == 1 then
		frame.bg:SetVertexColor(1, 1, 0, .80)
	else
		frame.bg:SetVertexColor(0, 0, 0, .80)
	end
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

Steak:RegisterModule(Module)
