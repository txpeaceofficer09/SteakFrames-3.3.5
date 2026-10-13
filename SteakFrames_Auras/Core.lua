local Module = {
    name = "Auras",
    events = {
        UNIT_AURA = true,
        PLAYER_ENTERING_WORLD = true,
        PLAYER_TARGET_CHANGED = true,
    }
}

local Steak = Steak

local DebuffColors = {
    Magic   = {0.20, 0.60, 1.00},
    Curse   = {0.60, 0.00, 1.00},
    Disease = {0.60, 0.40, 0.00},
    Poison  = {0.00, 0.60, 0.00},
}

function Module:CreateAuraIcon(parent)
    local icon = CreateFrame("Frame", nil, parent)
    icon:SetSize(Steak.Config.AuraSize, Steak.Config.AuraSize)

    icon.icon = icon:CreateTexture(nil, "ARTWORK")
    icon.icon:SetAllPoints()

    icon.count = icon:CreateFontString(nil, "OVERLAY")
    --icon.count:SetFont("Fonts\\FRIZQT__.TTF", 7, "OUTLINE")
	icon.count:SetFont("Interface\\AddOns\\SteakFrames\\Audiowide-Regular.ttf", 7, "OUTLINE")
    icon.count:SetPoint("BOTTOMRIGHT", 2, 0)
    icon.count:SetTextColor(1, 1, 1)

    icon.border = icon:CreateTexture(nil, "OVERLAY")
    icon.border:SetAllPoints()
    icon.border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
    icon.border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)

	icon:EnableMouse(true)

    icon:SetScript("OnEnter", function(self)
        if self.spellID then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetSpellByID(self.spellID)
            GameTooltip:Show()
        end
    end)

    icon:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return icon
end

function Module:CreateContainer(frame, name, anchor, relativeTo)
    local container = CreateFrame("Frame", nil, frame)
    container:SetWidth(
        8 * Steak.Config.AuraSize +
        7 * Steak.Config.AuraSpacing
    )
    container:SetHeight(Steak.Config.AuraSize)
    container:SetPoint(anchor, relativeTo or frame, anchor, 0, 0)
    container.icons = {}
    frame.auras[name] = container
    return container
end

function Module:CreateFrame(frame)
    if not Steak.Config.ShowAuras then return end
    if frame.unit ~= "player" and frame.unit ~= "target" then return end

    frame.auras = {}

	frame.auras.buffs = self:CreateContainer(frame, "buffs", "TOPLEFT", nil)
	frame.auras.buffs:ClearAllPoints()
	--frame.auras.buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -2)
	frame.auras.buffs:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 12)

	frame.auras.debuffs = self:CreateContainer(frame, "debuffs", "TOPLEFT", nil)
	frame.auras.debuffs:ClearAllPoints()
	--frame.auras.debuffs:SetPoint("TOPLEFT", frame.auras.buffs, "BOTTOMLEFT", 0, -2)
	frame.auras.debuffs:SetPoint("BOTTOMLEFT", frame.auras.buffs, "TOPLEFT", 0, 12)
end

function Module:UpdateAuraList(frame, container, filter)
    if not container then return end

    for _, icon in ipairs(container.icons) do
        icon:Hide()
    end

    if not frame.unit or not UnitExists(frame.unit) then
        container:SetHeight(Steak.Config.AuraSize)
        return
    end

    local index = 0
    local maxAuras = Steak.Config.MaxAuras

    for auraIndex = 1, 40 do
        if index >= maxAuras then break end

        local name, rank, texture, count, debuffType,
              duration, expirationTime, unitCaster,
              isStealable, shouldConsolidate, spellID =
            UnitAura(frame.unit, auraIndex, filter)

        if not name then break end

        index = index + 1

        local icon = container.icons[index]
        if not icon then
            icon = self:CreateAuraIcon(container)
            container.icons[index] = icon
        end

        local column = (index - 1) % 8
        local row = math.floor((index - 1) / 8)
        local size = Steak.Config.AuraSize + Steak.Config.AuraSpacing

        icon:ClearAllPoints()
        icon:SetPoint("TOPLEFT", container, "TOPLEFT", column * size, -row * size)
        icon.icon:SetTexture(texture)
        icon.spellID = spellID
        icon.count:SetText(count and count > 1 and count or "")

        icon.border:SetVertexColor(1, 1, 1, 1)

        if filter == "HARMFUL" then
            local color = DebuffColors[debuffType]
            if color then
                icon.border:SetVertexColor(color[1], color[2], color[3], 1)
            end
        elseif isStealable then
            icon.border:SetVertexColor(0.20, 0.60, 1.00, 1)
        end

        icon:Show()
    end

    local rows = math.max(1, math.ceil(index / 8))
    container:SetHeight(rows * (Steak.Config.AuraSize + Steak.Config.AuraSpacing))
end

function Module:UpdateFrame(frame)
    if not frame.auras then return end

    self:UpdateAuraList(frame, frame.auras.buffs, "HELPFUL")
    self:UpdateAuraList(frame, frame.auras.debuffs, "HARMFUL")
end

function Module:OnEvent(event, unit)
    if event == "UNIT_AURA" then
        for _, frame in ipairs(Steak.Frames) do
            if frame.unit == unit then
                self:UpdateFrame(frame)
            end
        end
        return
    end

    Steak:ForEachFrame(function(frame)
        self:UpdateFrame(frame)
    end)
end

function Module:Initialize()
	--[[
	local blizzFrames = {BuffFrame, DebuffFrame}

	for _, blizzFrame in ipairs(blizzFrames) do
		blizzFrame:Hide()
		blizzFrame:SetScript("OnShow", function(self) self:Hide() end)
	end
	]]

	BuffFrame:Hide()
	BuffFrame:HookScript("OnShow", function(self) self:Hide() end)
end

Steak:RegisterModule(Module)
