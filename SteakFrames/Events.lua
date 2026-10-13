local Steak = Steak
local eventFrame = Steak.eventFrame

local events = {
    "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "VARIABLES_LOADED",
    "GROUP_ROSTER_UPDATE", "RAID_ROSTER_UPDATE", "PARTY_MEMBERS_CHANGED",
    "PLAYER_TARGET_CHANGED", "PLAYER_FOCUS_CHANGED", "UNIT_PET", "PLAYER_PET_CHANGED",
    "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "PARTY_LOOT_METHOD_CHANGED",
    "PLAYER_ROLES_ASSIGNED", "RAID_TARGET_UPDATE", "PLAYER_XP_UPDATE", "PLAYER_LEVEL_UP",
    "UPDATE_EXHAUSTION", "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_POWER_UPDATE",
    "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER", "UNIT_AURA", "UNIT_FLAGS",
    "UNIT_THREAT_SITUATION_UPDATE", "UNIT_THREAT_LIST_UPDATE", "UNIT_COMBO_POINTS",
    "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED",
    "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_CHANNEL_START",
    "UNIT_SPELLCAST_CHANNEL_UPDATE", "UNIT_SPELLCAST_CHANNEL_STOP", "UNIT_INVENTORY_CHANGED"
}
for _, event in ipairs(events) do eventFrame:RegisterEvent(event) end

function Steak:HideBlizzardFrames()
    local frames = {
        PlayerFrame, TargetFrame, ComboFrame, TargetFrameToT, FocusFrame, PetFrame,
        PartyMemberFrame1, PartyMemberFrame2, PartyMemberFrame3, PartyMemberFrame4,
        PartyMemberBackground, PartyMemberFrame1PetFrame, PartyMemberFrame2PetFrame,
        PartyMemberFrame3PetFrame, PartyMemberFrame4PetFrame, CastingBarFrame,
    }
    for _, frame in ipairs(frames) do
        if frame then
            frame:UnregisterAllEvents()
            frame:Hide()
            frame:SetScript("OnShow", function(self) self:Hide() end)
        end
    end
end

local function IsInRaid()
    return GetNumRaidMembers() > 0
end

local function IsInParty()
    return not IsInRaid() and GetNumPartyMembers() > 0
end

function Steak:BeginStartup()
    if self.StartupQueued then return end
    self.StartupQueued = true

    self:CreateParents()
    self:AppendModuleInitialization()
    self:QueueMainFrames()
    self:QueueInitialization(function()
        if self.Config.HideBlizzardFrames then self:HideBlizzardFrames() end
    end)
    self:StartInitialization()
end

function Steak:HandleGroupChange()
    if IsInRaid() then
        self:EnsureRaidFrames()
    elseif IsInParty() then
        self:EnsurePartyFrames()
    end

    if self.Initialized then self:UpdateLayouts() end
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        Steak:BeginStartup()
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Group state may be populated after login; handle again once in-world.
        Steak:HandleGroupChange()
    elseif event == "GROUP_ROSTER_UPDATE" or event == "RAID_ROSTER_UPDATE"
        or event == "PARTY_MEMBERS_CHANGED" then
        Steak:HandleGroupChange()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if Steak.PendingGroupType == "raid" then
            Steak.PendingGroupType = nil
            Steak:EnsureRaidFrames()
        elseif Steak.PendingGroupType == "party" then
            Steak.PendingGroupType = nil
            Steak:EnsurePartyFrames()
        end
        if Steak.layoutPending then Steak:UpdateLayouts() end
    end

    Steak:DispatchEvent(event, ...)

    if event == "PLAYER_ENTERING_WORLD" or event == "VARIABLES_LOADED"
        or event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED"
        or event == "PLAYER_ROLES_ASSIGNED" or event == "PARTY_LOOT_METHOD_CHANGED"
        or event == "RAID_TARGET_UPDATE" or event == "UNIT_PET" or event == "PLAYER_PET_CHANGED" then
        if Steak.Initialized then Steak:UpdateLayouts() end
    end
end)

eventFrame:SetScript("OnUpdate", function(_, elapsed)
    if Steak.Initializing then
        Steak:RunInitializationStep()
    else
        Steak:UpdateModules(elapsed)
    end
end)
