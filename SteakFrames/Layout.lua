local Steak = Steak

function Steak:LayoutPartyFrames()
	if not self.PartyFrames then return end

	for i, frame in ipairs(self.PartyFrames) do
		frame:ClearAllPoints()
		frame:SetPoint("LEFT", self.PartyParent, "LEFT", (i - 1) * (self.Config.UnitWidth + self.Config.PartySpacing), 0)
	end

	for i, frame in ipairs(self.PartyPetFrames or {}) do
		frame:ClearAllPoints()
		frame:SetPoint("TOP", self.PartyFrames[i], "BOTTOM", 0, -2)
	end

	for i, frame in ipairs(self.PartyTargetFrames or {}) do
		if self.PartyFrames[i] then
			frame:ClearAllPoints()
			frame:SetPoint("BOTTOM", self.PartyFrames[i], "TOP", 0, 12)
		end
	end
end

function Steak:GetRaidGroupData()
	local groups = {}
	--for group = 1, 8 do groups[group] = {} end
	for group = 1, 5 do groups[group] = {} end

	for i = 1, GetNumRaidMembers() do
		local _, _, subgroup = GetRaidRosterInfo(i)
		if subgroup and groups[subgroup] then
			table.insert(groups[subgroup], i)
		end
	end
	return groups
end

function Steak:LayoutRaidFrames()
	if not self.RaidFrames or InCombatLockdown() then return end

	local groups = self:GetRaidGroupData()
	local width, height = self.Config.RaidWidth, self.Config.RaidHeight

	--for group = 1, 8 do
	for group = 1, 5 do
		for position, raidIndex in ipairs(groups[group]) do
			local frame = self.RaidFrames[raidIndex]
			if frame then
				frame:ClearAllPoints()
				frame:SetPoint("TOPLEFT", self.RaidParent, "TOPLEFT",
					(position - 1) * (width + self.Config.RaidSpacingX),
					-(group - 1) * (height + self.Config.RaidSpacingY))
			end
		end
	end

	--self.RaidParent:SetSize(5 * (width + self.Config.RaidSpacingX), 8 * (height + self.Config.RaidSpacingY))
	self.RaidParent:SetSize(5 * (width + self.Config.RaidSpacingX), 5 * (height + self.Config.RaidSpacingY))
end

function Steak:LayoutSpecialFrames()
	if self.Player then
		self.Player:ClearAllPoints()
		self.Player:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 350, 420)
	end
	if self.Target then
		self.Target:ClearAllPoints()
		self.Target:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -350, 420)
	end
	if self.Focus and self.Target then
		self.Focus:ClearAllPoints()
		self.Focus:SetPoint("BOTTOMRIGHT", self.Target, "TOPLEFT", -15, 50)
	end
	if self.Pet and self.Player then
		self.Pet:ClearAllPoints()
		self.Pet:SetPoint("TOP", self.Player, "BOTTOM", 0, -30)
	end
	if self.ToT and self.Target then
		self.ToT:ClearAllPoints()
		self.ToT:SetPoint("TOP", self.Target, "BOTTOM", 0, -30)
	end

	for i, frame in ipairs(self.BossFrames or {}) do
		frame:ClearAllPoints()
		frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -350, 450 + ((i - 1) * 80))
	end
	for i, frame in ipairs(self.VehicleFrames or {}) do
		frame:ClearAllPoints()
		frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 350, 450 + ((i - 1) * 80))
	end
end

function Steak:UpdateLayouts()
	if InCombatLockdown() then
		self.layoutPending = true
		return
	end
	self.layoutPending = false
	self:LayoutPartyFrames()
	self:LayoutRaidFrames()
	self:LayoutSpecialFrames()
	if self.UpdateAll then self:UpdateAll() end
end
