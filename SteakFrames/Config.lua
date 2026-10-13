local Steak = Steak

Steak.VERSION = "2.0.0"

Steak.Config = {
    UnitWidth = 140,
    UnitHeight = 50,
    SmallWidth = 110,
    SmallHeight = 40,
    RaidWidth = 110,
    RaidHeight = 40,

    PartySpacing = 4,
	RaidSpacingX = 4,
	RaidSpacingY = 10,

    UpdateInterval = 0.20,

    HideBlizzardFrames = true,
    ShowAuras = true,
    AuraSize = 16,
    AuraSpacing = 2,
    MaxAuras = 16,

    RaidGroupsPerRow = 5,
    RaidMembersPerGroup = 5,
}

Steak.PowerColors = {
    MANA        = {0.00, 0.55, 1.00},
    RAGE        = {1.00, 0.10, 0.10},
    FOCUS       = {1.00, 0.50, 0.25},
    ENERGY      = {1.00, 1.00, 0.00},
    RUNIC_POWER = {0.00, 0.82, 1.00},
}
