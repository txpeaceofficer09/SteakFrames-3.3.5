local BagFrame = CreateFrame("Frame", "SteakAllInOneBag", UIParent)
BagFrame:SetSize(400, 400) -- Initial size, will adjust below
BagFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -50, 260)
BagFrame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
BagFrame:SetBackdropColor(0, 0, 0, 0.8)
BagFrame:SetMovable(true)
BagFrame:EnableMouse(true)
BagFrame:RegisterForDrag("LeftButton")
BagFrame:SetScript("OnDragStart", BagFrame.StartMoving)
BagFrame:SetScript("OnDragStop", BagFrame.StopMovingOrSizing)
BagFrame:Hide()

local ITEM_SIZE = 37
local SPACING = 4
local COLUMNS = 12

local function UpdateBagLayout()
    local slotID = 0
    -- Container 0 is Backpack, 1-4 are the extra bags
    for bag = 0, 4 do
        local slots = GetContainerNumSlots(bag)
        for slot = 1, slots do
            -- The default item buttons are named "ContainerFrameXItemY"
            -- Note: ContainerFrame ID mapping is slightly different from bag ID
            local frameID = bag + 1
            local item = _G["ContainerFrame"..frameID.."Item".. (slots - slot + 1)]
            
            if item then
                item:SetParent(BagFrame)
                item:ClearAllPoints()
                
                local col = slotID % COLUMNS
                local row = math.floor(slotID / COLUMNS)
                
                item:SetPoint("TOPLEFT", BagFrame, "TOPLEFT", 10 + (col * (ITEM_SIZE + SPACING)), -10 - (row * (ITEM_SIZE + SPACING)))
                item:Show()
                slotID = slotID + 1
            end
        end
    end
    
    -- Adjust container size based on total slots
    local totalRows = math.ceil(slotID / COLUMNS)
    BagFrame:SetSize((COLUMNS * (ITEM_SIZE + SPACING)) + 20, (totalRows * (ITEM_SIZE + SPACING)) + 20)
end

-- Toggle the bag with the standard 'B' or 'I' keys
hooksecurefunc("OpenAllBags", function() BagFrame:Show() UpdateBagLayout() end)
hooksecurefunc("CloseAllBags", function() BagFrame:Hide() end)
--[[
hooksecurefunc("ToggleAllBags", function() 
    if BagFrame:IsShown() then BagFrame:Hide() else BagFrame:Show() UpdateBagLayout() end 
end)
]]

-- Hide the default Blizzard Bag Frames
for i=1, 5 do
    local bag = _G["ContainerFrame"..i]

    bag:SetClampedToScreen(false)
    bag:EnableMouse(false)
    bag:SetAlpha(0)
    bag:SetUserPlaced(true)
    bag:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -500, 500) -- Move off-screen
    --_G["ContainerFrame"..i]:HookScript("OnShow", function(self) self:Hide() end)
end
