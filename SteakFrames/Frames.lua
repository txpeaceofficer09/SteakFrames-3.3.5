local Steak = Steak

function Steak:CreateStatusBar(parent)
	local bar = CreateFrame("StatusBar", nil, parent)
	bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	bar:SetMinMaxValues(0, 100)

	bar.bg = bar:CreateTexture(nil, "BACKGROUND")
	bar.bg:SetAllPoints()
	bar.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
	bar.bg:SetVertexColor(0, 0, 0, 0.80)

	return bar
end

function Steak:CreateFont(parent, size)
	local font = parent:CreateFontString(nil, "OVERLAY")
	font:SetFont("Interface\\AddOns\\SteakFrames\\Audiowide-Regular.ttf", size or 10, "OUTLINE")
	font:SetTextColor(1, 1, 1)
	return font
end

function Steak:CreateUnitFrame(name, unit, width, height, parent)
	local frame = CreateFrame("Button", name, parent or self.UnitsParent, "SecureUnitButtonTemplate")
	frame:SetSize(width, height)
	frame.unit = unit

	frame:SetAttribute("unit", unit)
	frame:SetAttribute("*type1", "target")
	frame:SetAttribute("*type2", "menu")
	frame:RegisterForClicks("AnyUp")
	RegisterUnitWatch(frame)

	frame.bg = frame:CreateTexture(nil, "BACKGROUND")
	frame.bg:SetAllPoints()
	frame.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
	frame.bg:SetVertexColor(0, 0, 0, 0.80)

	frame.health = self:CreateStatusBar(frame)
	frame.health:SetPoint("TOPLEFT", 2, -2)
	frame.health:SetPoint("BOTTOMRIGHT", -2, 12)

	frame.mana = self:CreateStatusBar(frame)
	frame.mana:SetPoint("TOPLEFT", frame.health, "BOTTOMLEFT", 0, -1)
	frame.mana:SetPoint("BOTTOMRIGHT", -2, 2)

	frame.nameText = self:CreateFont(frame.health, 10)
	frame.nameText:SetPoint("TOPLEFT", frame.health, "TOPLEFT", 5, -4)
	frame.nameText:SetJustifyH("LEFT")

	frame.hpText = self:CreateFont(frame.health, 9)
	frame.hpText:SetPoint("CENTER", frame.health, "CENTER", 0, -10)

	frame.mpText = self:CreateFont(frame.mana, 8)
	frame.mpText:SetPoint("RIGHT", -2, 0)

	frame:SetScript("OnEnter", function(button)
		if button.unit and UnitExists(button.unit) then
			GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
			GameTooltip:SetUnit(button.unit)
			GameTooltip:Show()
		end
	end)
	frame:SetScript("OnLeave", function() GameTooltip:Hide() end)

	frame:SetScript("OnMouseUp", function(button, mouseButton)
		if mouseButton ~= "RightButton" then return end

		local dropdown
		if button.unit == "player" then
			dropdown = PlayerFrameDropDown
		elseif button.unit == "target" then
			dropdown = TargetFrameDropDown
		elseif button.unit == "focus" then
			dropdown = FocusFrameDropDown
		elseif button.unit == "pet" then
			dropdown = PetFrameDropDown
		elseif button.unit:match("^party") or button.unit:match("^partypet") then
			dropdown = PartyMemberFrame1DropDown
		elseif button.unit:match("^raid") then
			dropdown = PlayerFrameDropDown
		end

		if dropdown then
			ToggleDropDownMenu(1, nil, dropdown, button, 0, 0)
		end
	end)

	frame:SetScript("OnUpdate", function(button, elapsed)
		button.updateTimer = (button.updateTimer or 0) + elapsed
		if button.updateTimer < Steak.Config.UpdateInterval then return end
		button.updateTimer = 0

		if button.unit and UnitExists(button.unit) then
			if UnitIsUnit(button.unit, "player") or CheckInteractDistance(button.unit, 1) then
				button:SetAlpha(1)
			else
				button:SetAlpha(0.40)
			end
		end
	end)

	table.insert(self.Frames, frame)

	-- Modules initialize before frame creation and can decorate each frame here.
	for _, module in ipairs(self.Modules) do
		if module.Initialized and module.CreateFrame then
			module:CreateFrame(frame)
		end
	end

	return frame
end

function Steak:CreateParents()
	if self.UnitsParent then return end

	self.UnitsParent = CreateFrame("Frame", "SteakUnitsParent", UIParent, "SecureHandlerStateTemplate")
	self.UnitsParent:SetAllPoints(UIParent)

	-- Parents are created up front; actual party/raid unit buttons are lazy-created.
	self.PartyParent = CreateFrame("Frame", "SteakPartyParent", UIParent, "SecureHandlerStateTemplate")
	self.PartyParent:SetSize(568, 50)
	self.PartyParent:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 200)
	RegisterStateDriver(self.PartyParent, "visibility", "[group:raid] hide; [group:party] show; hide")

	self.RaidParent = CreateFrame("Frame", "SteakRaidParent", UIParent, "SecureHandlerStateTemplate")
	self.RaidParent:SetSize(570, 250)
	self.RaidParent:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 150)
	RegisterStateDriver(self.RaidParent, "visibility", "[group:raid] show; hide")
end

function Steak:QueueMainFrames()
	local specs = {
		{ "Player", "SteakPlayerFrame", "player", "UnitWidth", "UnitHeight" },
		{ "Target", "SteakTargetFrame", "target", "UnitWidth", "UnitHeight" },
		{ "Focus", "SteakFocusFrame", "focus", "UnitWidth", "UnitHeight" },
		{ "Pet", "SteakPetFrame", "pet", "SmallWidth", "SmallHeight" },
		{ "ToT", "SteakToTFrame", "targettarget", "SmallWidth", "SmallHeight" },
	}

	for _, spec in ipairs(specs) do
		local item = spec
		self:QueueInitialization(function()
			self[item[1]] = self:CreateUnitFrame(item[2], item[3], self.Config[item[4]], self.Config[item[5]])
		end)
	end

	for i = 1, 4 do
		local index = i
		self:QueueInitialization(function()
			self.BossFrames = self.BossFrames or {}
			self.BossFrames[index] = self:CreateUnitFrame(
				"SteakBoss" .. index, "boss" .. index,
				self.Config.SmallWidth, self.Config.SmallHeight
			)
		end)
	end

	for i = 1, 3 do
		local index = i
		self:QueueInitialization(function()
			self.VehicleFrames = self.VehicleFrames or {}
			self.VehicleFrames[index] = self:CreateUnitFrame(
				"SteakPassenger" .. index, "vehiclepassenger" .. index, 90, 40
			)
		end)
	end
end

function Steak:EnsurePartyFrames()
	if self.PartyFramesCreated then return end
	if InCombatLockdown() then
		self.PendingGroupType = "party"
		return
	end

	self.PartyFramesCreated = true
	self.PartyFrames = {}
	self.PartyPetFrames = {}
	self.PartyTargetFrames = {}

	for i = 1, 4 do
		local index = i
		self:QueueInitialization(function()
			self.PartyFrames[index] = self:CreateUnitFrame("SteakParty" .. index, "party" .. index, self.Config.UnitWidth, self.Config.UnitHeight, self.PartyParent)
		end)
		self:QueueInitialization(function()
			self.PartyPetFrames[index] = self:CreateUnitFrame("SteakPartyPet" .. index, "partypet" .. index, self.Config.SmallWidth, self.Config.SmallHeight, self.PartyParent)
		end)
		self:QueueInitialization(function()
			self.PartyTargetFrames[index] = self:CreateUnitFrame("SteakPartyTarget" .. index, "party" .. index .. "target", self.Config.SmallWidth, self.Config.SmallHeight, self.PartyParent)
		end)
	end

	self:StartInitialization()
end

function Steak:EnsureRaidFrames()
	if self.RaidFramesCreated then return end
	if InCombatLockdown() then
		self.PendingGroupType = "raid"
		return
	end

	self.RaidFramesCreated = true
	self.RaidFrames = {}

	for i = 1, 25 do
		local index = i
		self:QueueInitialization(function()
			self.RaidFrames[index] = self:CreateUnitFrame(
				"SteakRaid" .. index, "raid" .. index,
				self.Config.RaidWidth, self.Config.RaidHeight, self.RaidParent
			)
		end)
	end

	self:StartInitialization()
end
