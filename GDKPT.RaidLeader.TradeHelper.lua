GDKPT.RaidLeader.TradeHelper = {}

local TradeHelperFrame = nil
local itemButtons = {}          

local ITEM_STATE = {
    PENDING = 1,
    IN_TRADE = 2,
    TRADED = 3
}

-------------------------------------------------------------------
-- Create the Trade Helper Frame
-------------------------------------------------------------------


local function CreateTradeHelperFrame()
    if TradeHelperFrame then return TradeHelperFrame end
    
    -- Main frame
    local frame = CreateFrame("Frame", "GDKPTTradeHelperFrame", UIParent)
    frame:SetWidth(300)
    frame:SetHeight(400)
    frame:SetPoint("LEFT", TradeFrame, "RIGHT", 5, 0)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.9)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()
    
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -15)
    title:SetText("Items to Trade")
    title:SetTextColor(1, 0.82, 0)
    frame.title = title
    
    -- Player name
    local playerName = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    playerName:SetPoint("TOP", title, "BOTTOM", 0, -5)
    playerName:SetText("")
    playerName:SetTextColor(0.5, 1, 0.5)
    frame.playerName = playerName
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)
    
    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", "GDKPTTradeHelperScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -60)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 15)
    frame.scrollFrame = scrollFrame
    
    -- Scroll child
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(scrollFrame:GetWidth())
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    frame.scrollChild = scrollChild
    
    TradeHelperFrame = frame
    return frame
end



-------------------------------------------------------------------
-- Find exact item in bags using hash matching
-------------------------------------------------------------------

function GDKPT.RaidLeader.TradeHelper.FindItemInBagsByHash(wonItem)
    if not wonItem.itemInstanceHash then
        return nil, nil
    end
    
    local itemID = wonItem.itemID
    
    -- Search through all bags for matching item
    for bagID = 0, 4 do
        for slotID = 1, GetContainerNumSlots(bagID) do
            local bagItemLink = GetContainerItemLink(bagID, slotID)
            if bagItemLink then
                local bagItemID = tonumber(bagItemLink:match("item:(%d+)"))
                
                -- First check if itemID matches
                if bagItemID == itemID then
                    -- Use the FindMatchingAuction function to check hash match
                    local auctionData = GDKPT.RaidLeader.Utils.FindMatchingAuction(bagID, slotID, bagItemLink)
                    
                    -- Check if this auction data matches our won item
                    if auctionData and auctionData.itemInstanceHash == wonItem.itemInstanceHash then
                        return bagID, slotID
                    end
                end
            end
        end
    end
    
    return nil, nil
end


-------------------------------------------------------------------
-- Find item in bags by Hash - Matching and return bag and slot ID
-------------------------------------------------------------------

local function FindItemInBags(wonItem)

    -- Special handling for loot window items
    if wonItem.isLootWindowItem then
        print(GDKPT.RaidLeader.Core.errorPrintString .. "This item was auctioned from corpse, its already given to the player!")
        return nil, nil
    end

    local bagID, slotID = nil, nil
    
    -- Find item by Hash - Matching
    if wonItem.itemInstanceHash then
        bagID, slotID = GDKPT.RaidLeader.TradeHelper.FindItemInBagsByHash(wonItem)
        
        if bagID and slotID then
            return bagID, slotID 
        end
    end
    
    return nil, nil
end



-------------------------------------------------------------------
-- Find item in bags and place in trade
-------------------------------------------------------------------


local function PlaceItemInTrade(itemID, itemLink, wonItem)
    -- Prevent placing if already in trade
    if wonItem.inTradeSlot then
        print(GDKPT.RaidLeader.Core.errorPrintString .. "This item is already in the trade window!")
        return false
    end
    -- Check for empty slot in trade frame
    local tradeSlot = GDKPT.RaidLeader.Utils.GetNextEmptyTradeSlot()
    if not tradeSlot then
        print(GDKPT.RaidLeader.Core.errorPrintString .. "Trade window is full! Remove items or complete trade first.")
        return false
    end
    
    -- Find the item using hash-aware search
    local foundBag, foundSlot = FindItemInBags(wonItem)
    
    if not foundBag or not foundSlot then
        print(GDKPT.RaidLeader.Core.errorPrintString .. "Could not find " .. itemLink .. " in your bags!")
        return false
    end
    
    local _, stackSize = GetContainerItemInfo(foundBag, foundSlot)
    stackSize = stackSize or 1
    
    -- Validate stack size matches expected quantity
    if wonItem.remainingQuantity and stackSize < wonItem.remainingQuantity then
        print(string.format(GDKPT.RaidLeader.Core.errorPrintString .. "Found stack of %d but need %d. Placing anyway.", 
            stackSize, wonItem.remainingQuantity))
    end
    
    -- Place in trade
    PickupContainerItem(foundBag, foundSlot)
    ClickTradeButton(tradeSlot)
    
    -- Mark item as in trade
    wonItem.inTradeSlot = tradeSlot
    wonItem.itemState = ITEM_STATE.IN_TRADE
    
    -- Track this placement
    if not GDKPT.RaidLeader.ItemTrading.CurrentTrade.itemsOffered then
        GDKPT.RaidLeader.ItemTrading.CurrentTrade.itemsOffered = {}
    end
    
    table.insert(GDKPT.RaidLeader.ItemTrading.CurrentTrade.itemsOffered, {
        wonItem = wonItem,
        stackSize = stackSize,
        itemID = itemID,
        itemLink = itemLink,
        placementOrder = tradeSlot,
        auctionHash = wonItem.auctionHash,
        itemInstanceHash = wonItem.itemInstanceHash
    })
    
    print(string.format(GDKPT.RaidLeader.Core.addonPrintString .. "Placed %s in trade slot %d (Auction #%d)", 
        itemLink, tradeSlot, wonItem.auctionId))
    
    -- Refresh the helper frame
    C_Timer.After(0.1, function()
        GDKPT.RaidLeader.TradeHelper.Update()
    end)
    
    return true
end




-------------------------------------------------------------------
-- Check what's actually in trade slots
-------------------------------------------------------------------

local function GetItemsCurrentlyInTrade()
    local itemsInTrade = {}
    for slot = 1, 6 do
        local itemLink = GetTradePlayerItemLink(slot)
        if itemLink then
            local itemID = tonumber(itemLink:match("item:(%d+)"))
            if itemID then
                itemsInTrade[itemID] = slot
            end
        end
    end
    return itemsInTrade
end




-------------------------------------------------------------------
-- Create item row button
-------------------------------------------------------------------



local function CreateItemButton(parent, index)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetWidth(260)
    btn:SetHeight(30)
    btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")

    -- Background
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(btn)
    if index % 2 == 0 then
        bg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
    else
        bg:SetColorTexture(0.15, 0.15, 0.15, 0.5)
    end
    btn.bg = bg

    -- Item icon
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(24, 24)
    icon:SetPoint("LEFT", btn, "LEFT", 5, 0)
    btn.icon = icon

    -- Item name
    local name = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    name:SetPoint("LEFT", icon, "RIGHT", 5, 0)
    name:SetPoint("RIGHT", btn, "RIGHT", -80, 0)
    name:SetJustifyH("LEFT")
    name:SetWordWrap(false)
    btn.name = name

    -- Status indicator (for trade progress)
    local status = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    status:SetPoint("RIGHT", btn, "RIGHT", -40, 0)
    status:SetTextColor(1, 0.84, 0)
    btn.status = status

    -- Price
    local price = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    price:SetPoint("RIGHT", btn, "RIGHT", -5, 0)
    price:SetTextColor(1, 0.84, 0)
    btn.price = price

    -- Checkmark (when fully traded)
    local check = btn:CreateTexture(nil, "OVERLAY")
    check:SetSize(20, 20)
    check:SetPoint("RIGHT", btn, "RIGHT", -5, 0)
    check:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    check:Hide()
    btn.check = check

    -- Partial trade indicator texture
    btn.partialOverlay = btn:CreateTexture(nil, "BACKGROUND", nil, 1)
    btn.partialOverlay:SetAllPoints()
    btn.partialOverlay:SetColorTexture(1, 0.7, 0, 0.2)
    btn.partialOverlay:Hide()

    -- Fully traded overlay
    btn.tradedOverlay = btn:CreateTexture(nil, "BACKGROUND", nil, 1)
    btn.tradedOverlay:SetAllPoints()
    btn.tradedOverlay:SetColorTexture(0, 0.7, 0, 0.3)
    btn.tradedOverlay:Hide()

    -- Enhanced tooltip with trade status
    btn:SetScript("OnEnter", function(self)
        if self.itemLink then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(self.itemLink)

            -- Add trade status information
            if self.wonItem then
                GameTooltip:AddLine(" ")
                
                local remaining = self.wonItem.remainingQuantity or self.wonItem.stackCount or 1
                local total = self.wonItem.stackCount or 1
                
                if self.wonItem.fullyTraded then
                    GameTooltip:AddLine("|cff00ff00Fully Traded|r", 1, 1, 1)
                elseif self.wonItem.traded then
                    GameTooltip:AddLine(string.format("|cffffaa00Partially Traded: %d/%d remaining|r", remaining, total), 1, 1, 1)
                    local paidAmount = self.wonItem.amountPaid or 0
                    if paidAmount > 0 then
                        GameTooltip:AddLine(string.format("Paid: %dg of %dg", paidAmount, self.wonItem.price), 0.7, 0.7, 0.7)
                    end
                else
                    GameTooltip:AddLine("|cffaaaaaNot Yet Traded|r", 1, 1, 1)
                end
                
                if self.wonItem.inTradeSlot then
                    GameTooltip:AddLine(string.format("|cffffff00Currently in trade slot %d|r", self.wonItem.inTradeSlot), 1, 1, 1)
                end
            end

            GameTooltip:Show()
        end
    end)

    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    btn:SetScript("OnClick", function(self)
        if not self.wonItem then return end
        if self.wonItem.fullyTraded then
            print(GDKPT.RaidLeader.Core.errorPrintString .. "This item has already been fully traded.")
            return
        end

        if not TradeFrame or not TradeFrame:IsShown() then
            print(GDKPT.RaidLeader.Core.errorPrintString .. "Open the trade window before placing items.")
            return
        end

        -- Attempt to place the item in trade
        PlaceItemInTrade(self.itemID, self.itemLink, self.wonItem)
    end)

    return btn
end



--[[







local function CreateItemButton(parent, index)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetWidth(260)
    btn:SetHeight(30)
    btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")

    -- Background
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(btn)
    if index % 2 == 0 then
        bg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
    else
        bg:SetColorTexture(0.15, 0.15, 0.15, 0.5)
    end
    btn.bg = bg

    -- Item icon
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(24, 24)
    icon:SetPoint("LEFT", btn, "LEFT", 5, 0)
    btn.icon = icon

    -- Item name
    local name = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    name:SetPoint("LEFT", icon, "RIGHT", 5, 0)
    name:SetPoint("RIGHT", btn, "RIGHT", -80, 0)
    name:SetJustifyH("LEFT")
    name:SetWordWrap(false)
    btn.name = name

    -- Status indicator
    local status = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    status:SetPoint("RIGHT", btn, "RIGHT", -40, 0)
    status:SetTextColor(1, 0.84, 0)
    btn.status = status

    -- Price
    local price = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    price:SetPoint("RIGHT", btn, "RIGHT", -5, 0)
    price:SetTextColor(1, 0.84, 0)
    btn.price = price

    -- Checkmark (when traded)
    local check = btn:CreateTexture(nil, "OVERLAY")
    check:SetSize(20, 20)
    check:SetPoint("RIGHT", btn, "RIGHT", -5, 0)
    check:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    check:Hide()
    btn.check = check

    -- Enhanced tooltip with hash-based auction info
    btn:SetScript("OnEnter", function(self)
        if self.itemLink then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(self.itemLink)

            -- Add auction information using hash lookup
            if self.wonItem and self.wonItem.itemInstanceHash then
                -- Find the exact auction data by itemInstanceHash
                local auctionData = nil
                for hash, data in pairs(GDKPT.RaidLeader.Core.AuctionedItems) do
                    if data.itemInstanceHash == self.wonItem.itemInstanceHash then
                        auctionData = data
                        break
                    end
                end

                if auctionData then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("|cff00ff00 This item has been auctioned|r", 1, 1, 1)

                    if auctionData.auctionId then
                        GameTooltip:AddLine(
                            "|cffaaaaaa  Auction ID: " .. auctionData.auctionId .. "|r",
                            0.7, 0.7, 0.7
                        )
                    end

                    if auctionData.winner and auctionData.winner ~= "Bulk" then
                        GameTooltip:AddLine("|cff00ccff  Winner: " .. auctionData.winner .. "|r", 0, 0.8, 1)

                        if auctionData.winningBid and auctionData.winningBid > 0 then
                            GameTooltip:AddLine(
                                string.format("|cffffd700  Winning Bid: %d gold|r", auctionData.winningBid),
                                1, 0.84, 0
                            )
                        end
                    end
                end
            end

            -- Show trade status
            if self.wonItem and self.wonItem.inTradeSlot then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(
                    "|cffffaa00Currently in trade slot " .. self.wonItem.inTradeSlot .. "|r",
                    1, 0.7, 0
                )
            end

            GameTooltip:Show()
        end
    end)

    btn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    btn:SetScript("OnClick", function(self)
        if not self.wonItem then return end
        if self.wonItem.fullyTraded then
            print(GDKPT.RaidLeader.Core.errorPrintString .. "This item has already been traded.")
            return
        end

        if not TradeFrame or not TradeFrame:IsShown() then
            print(GDKPT.RaidLeader.Core.errorPrintString .. "Open the trade window before placing items.")
            return
        end

        -- Attempt to place the item in trade
        PlaceItemInTrade(self.itemID, self.itemLink, self.wonItem)
    end)

    return btn
end

]]



-------------------------------------------------------------------
-- Update the Trade Helper Frame with current trade partner's items
-------------------------------------------------------------------

function GDKPT.RaidLeader.TradeHelper.Update()
    local frame = TradeHelperFrame
    if not frame or not frame:IsShown() then return end
    
    local partner = GDKPT.RaidLeader.ItemTrading.CurrentTrade.partner
    if not partner then
        frame:Hide()
        return
    end
    
    -- Update player name
    frame.playerName:SetText("Trading with: " .. partner)
    
    -- Get fresh won items data
    local wonItems = GDKPT.RaidLeader.Core.PlayerWonItems[partner]
    if not wonItems or #wonItems == 0 then
        frame.playerName:SetText(partner .. " - No items to trade")
        -- Clear all buttons
        for _, btn in ipairs(itemButtons) do
            btn:Hide()
        end
        return
    end
    
    -- Check what's currently in trade slots
    local itemsInTrade = GetItemsCurrentlyInTrade()
    
    -- Update all won items with current trade status
    for _, wonItem in ipairs(wonItems) do
        local itemID = wonItem.itemID
        if itemsInTrade[itemID] then
            wonItem.inTradeSlot = itemsInTrade[itemID]
            wonItem.itemState = ITEM_STATE.IN_TRADE
        else
            wonItem.inTradeSlot = nil
            if not wonItem.fullyTraded then
                wonItem.itemState = ITEM_STATE.PENDING
            else
                wonItem.itemState = ITEM_STATE.TRADED
            end
        end
    end
    
    -- Update scroll child height
    local totalHeight = #wonItems * 32
    frame.scrollChild:SetHeight(math.max(totalHeight, frame.scrollFrame:GetHeight()))
    
    -- Create or update buttons
    for i = 1, #wonItems do
        local wonItem = wonItems[i]
        
        -- Create button if needed
        if not itemButtons[i] then
            itemButtons[i] = CreateItemButton(frame.scrollChild, i)
        end
        
        local btn = itemButtons[i]
        btn:SetPoint("TOPLEFT", frame.scrollChild, "TOPLEFT", 0, -(i-1) * 32)
        btn:Show()
        
        -- Get item info
        local itemName, itemLink, itemQuality, _, _, _, _, _, _, itemTexture = GetItemInfo(wonItem.itemID)
        
        -- Update button data
        btn.wonItem = wonItem
        btn.itemID = wonItem.itemID
        btn.itemLink = wonItem.itemLink or itemLink
        
        -- Set icon
        if itemTexture then
            btn.icon:SetTexture(itemTexture)
        else
            btn.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end
        
        -- Set name with quality color
        if itemQuality and itemLink then
            local _, _, _, colorCode = GetItemQualityColor(itemQuality)
            btn.name:SetText(colorCode .. (itemName or "Unknown Item") .. "|r")
        else
            btn.name:SetText(itemName or "Unknown Item")
        end
        
        -- Initialize remaining quantity
        wonItem.remainingQuantity = wonItem.remainingQuantity or wonItem.stackCount
        
        -- Hide all overlays and indicators first
        btn.tradedOverlay:Hide()
        btn.partialOverlay:Hide()
        btn.check:Hide()
        btn.status:Hide()
        btn.price:Show()
        
        -- Update background color based on trade status
        if wonItem.fullyTraded then
            -- Fully traded - green overlay with checkmark
            btn.tradedOverlay:Show()
            btn.check:Show()
            btn.price:Hide()
            btn:SetAlpha(0.5)
            btn:Disable()
            
        elseif wonItem.inTradeSlot then
            -- Item is currently in trade window
            btn.status:Show()
            btn.status:SetText("|cffffaa00[Slot " .. wonItem.inTradeSlot .. "]|r")
            btn.price:Hide()
            btn:SetAlpha(0.7)
            btn:Disable()
            
        elseif wonItem.traded then
            -- Partially traded
            btn.partialOverlay:Show()
            btn.status:Show()
            btn.status:SetText(string.format("|cffffaa00%d/%d left|r", wonItem.remainingQuantity, wonItem.stackCount))
            btn:SetAlpha(1)
            btn:Enable()
            
            -- Show remaining cost based on partial trade
            local costPerItem = wonItem.price / wonItem.stackCount
            local remainingCost = math.floor(costPerItem * wonItem.remainingQuantity)
            btn.price:SetText(string.format("%dg", remainingCost))
            
        else
            -- Item is pending - not yet traded
            btn:SetAlpha(1)
            btn:Enable()
            
            -- Show full price
            if wonItem.remainingQuantity < wonItem.stackCount then
                btn.price:SetText(string.format("%dg (%d/%d)", 
                    wonItem.price or 0, 
                    wonItem.remainingQuantity,
                    wonItem.stackCount))
            else
                btn.price:SetText(string.format("%dg", wonItem.price or 0))
            end
        end
    end
    
    -- Hide unused buttons
    for i = #wonItems + 1, #itemButtons do
        itemButtons[i]:Hide()
    end
end


--[[





function GDKPT.RaidLeader.TradeHelper.Update()
    local frame = TradeHelperFrame
    if not frame or not frame:IsShown() then return end
    
    local partner = GDKPT.RaidLeader.ItemTrading.CurrentTrade.partner
    if not partner then
        frame:Hide()
        return
    end
    
    -- Update player name
    frame.playerName:SetText("Trading with: " .. partner)
    
    -- Get fresh won items data
    local wonItems = GDKPT.RaidLeader.Core.PlayerWonItems[partner]
    if not wonItems or #wonItems == 0 then
        frame.playerName:SetText(partner .. " - No items to trade")
        -- Clear all buttons
        for _, btn in ipairs(itemButtons) do
            btn:Hide()
        end
        return
    end
    
    -- Check what's currently in trade slots
    local itemsInTrade = GetItemsCurrentlyInTrade()
    
    -- Update all won items with current trade status
    for _, wonItem in ipairs(wonItems) do
        local itemID = wonItem.itemID
        if itemsInTrade[itemID] then
            wonItem.inTradeSlot = itemsInTrade[itemID]
            wonItem.itemState = ITEM_STATE.IN_TRADE
        else
            wonItem.inTradeSlot = nil
            if not wonItem.fullyTraded then
                wonItem.itemState = ITEM_STATE.PENDING
            else
                wonItem.itemState = ITEM_STATE.TRADED
            end
        end
    end
    
    -- Update scroll child height
    local totalHeight = #wonItems * 32
    frame.scrollChild:SetHeight(math.max(totalHeight, frame.scrollFrame:GetHeight()))
    
    -- Create or update buttons
    for i = 1, #wonItems do
        local wonItem = wonItems[i]
        
        -- Create button if needed
        if not itemButtons[i] then
            itemButtons[i] = CreateItemButton(frame.scrollChild, i)
        end
        
        local btn = itemButtons[i]
        btn:SetPoint("TOPLEFT", frame.scrollChild, "TOPLEFT", 0, -(i-1) * 32)
        btn:Show()
        
        -- Get item info
        local itemName, itemLink, itemQuality, _, _, _, _, _, _, itemTexture = GetItemInfo(wonItem.itemID)
        
        -- Update button data
        btn.wonItem = wonItem
        btn.itemID = wonItem.itemID
        btn.itemLink = wonItem.itemLink or itemLink
        
        -- Set icon
        if itemTexture then
            btn.icon:SetTexture(itemTexture)
        else
            btn.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end
        
        -- Set name with quality color
        if itemQuality and itemLink then
            local _, _, _, colorCode = GetItemQualityColor(itemQuality)
            btn.name:SetText(colorCode .. (itemName or "Unknown Item") .. "|r")
        else
            btn.name:SetText(itemName or "Unknown Item")
        end
        
        -- Initialize remaining quantity
        wonItem.remainingQuantity = wonItem.remainingQuantity or wonItem.stackCount
        
        -- Show status based on current state
        if wonItem.fullyTraded then
            btn.status:Hide()
            btn.price:Hide()
            btn.check:Show()
            btn:SetAlpha(0.5)
            btn:Disable()
        elseif wonItem.inTradeSlot then
            -- Item is currently in trade window
            btn.check:Hide()
            btn.price:Hide()
            btn.status:Show()
            btn.status:SetText("|cffffaa00[Slot " .. wonItem.inTradeSlot .. "]|r")
            btn:SetAlpha(0.7)
            btn:Disable()
        else
            -- Item is pending
            btn.check:Hide()
            btn.status:Hide()
            btn.price:Show()
            btn:SetAlpha(1)
            btn:Enable()
            
            -- Show remaining quantity if partial trade
            if wonItem.remainingQuantity < wonItem.stackCount then
                btn.price:SetText(string.format("%dg (%d/%d)", 
                    wonItem.price or 0, 
                    wonItem.remainingQuantity,
                    wonItem.stackCount))
            else
                btn.price:SetText(string.format("%dg", wonItem.price or 0))
            end
        end
    end
    
    -- Hide unused buttons
    for i = #wonItems + 1, #itemButtons do
        itemButtons[i]:Hide()
    end
end


]]



-------------------------------------------------------------------
-- Show the Trade Helper Frame
-------------------------------------------------------------------
function GDKPT.RaidLeader.TradeHelper.Show()
    local frame = CreateTradeHelperFrame()
    frame:Show()
    GDKPT.RaidLeader.TradeHelper.Update()
end

-------------------------------------------------------------------
-- Hide the Trade Helper Frame
-------------------------------------------------------------------
function GDKPT.RaidLeader.TradeHelper.Hide()
    if TradeHelperFrame then
        TradeHelperFrame:Hide()
    end
end

-------------------------------------------------------------------
-- Hook into trade events
-------------------------------------------------------------------

local helperEventFrame = CreateFrame("Frame")
helperEventFrame:RegisterEvent("TRADE_PLAYER_ITEM_CHANGED")
helperEventFrame:RegisterEvent("TRADE_TARGET_ITEM_CHANGED")

helperEventFrame:SetScript("OnEvent", function(self, event, slotID)
    -- Note: TRADE_SHOW and TRADE_CLOSED are handled by ItemTrading.lua
    -- This frame only handles item change events to update the UI
    
    if event == "TRADE_PLAYER_ITEM_CHANGED" or event == "TRADE_TARGET_ITEM_CHANGED" then
        -- Update when items change in trade window
        C_Timer.After(0.05, function()
            if TradeHelperFrame and TradeHelperFrame:IsShown() then
                GDKPT.RaidLeader.TradeHelper.Update()
            end
        end)
    end
end)




-------------------------------------------------------------------
-- Clean up function called when trade closes
-------------------------------------------------------------------

function GDKPT.RaidLeader.TradeHelper.OnTradeClosed()
    -- Clear all inTradeSlot markers when trade closes
    if GDKPT.RaidLeader.ItemTrading.CurrentTrade.partner then
        local wonItems = GDKPT.RaidLeader.Core.PlayerWonItems[GDKPT.RaidLeader.ItemTrading.CurrentTrade.partner]
        if wonItems then
            for _, item in ipairs(wonItems) do
                item.inTradeSlot = nil
            end
        end
    end
    GDKPT.RaidLeader.TradeHelper.Hide()
end