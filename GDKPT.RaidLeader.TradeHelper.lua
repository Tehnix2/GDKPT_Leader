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
    
    -- Scroll child (content)
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(scrollFrame:GetWidth())
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    frame.scrollChild = scrollChild
    
    TradeHelperFrame = frame
    return frame
end

-------------------------------------------------------------------
-- Find next empty trade slot
-------------------------------------------------------------------
local function GetNextEmptyTradeSlot()
    for i = 1, 6 do
        local itemLink = GetTradePlayerItemLink(i)
        if not itemLink then
            return i
        end
    end
    return nil -- All slots full
end





-------------------------------------------------------------------
-- Find item in bags and place in trade
-------------------------------------------------------------------

local function PlaceItemInTrade(itemID, itemLink, wonItem)
    -- Prevent placing if already in trade
    if wonItem.inTradeSlot then
        print("|cffff8800[GDKPT]|r This item is already in the trade window!")
        return false
    end
    
    local tradeSlot = GetNextEmptyTradeSlot()
    if not tradeSlot then
        print("|cffff0000[GDKPT]|r Trade window is full! Remove items or complete trade first.")
        return false
    end
    
    -- Try to find item by hash if available
    local foundBag, foundSlot = nil, nil
    
    if wonItem.itemHash then
        -- Search for item matching this specific hash
        for bagID = 0, 4 do
            for slotID = 1, GetContainerNumSlots(bagID) do
                local bagItemLink = GetContainerItemLink(bagID, slotID)
                if bagItemLink then
                    local bagItemID = tonumber(bagItemLink:match("item:(%d+)"))
                    if bagItemID == itemID then
                        -- Check if this specific instance matches the hash
                        local texture, count = GetContainerItemInfo(bagID, slotID)
                        local itemString = bagItemLink:match("item:([%-?%d:]+)")

                        -- Extract key parts from both hashes for comparison
                        local wonHashParts = {wonItem.itemHash:match("^([^_]+)_(%d+)_(%d+)")}
                        local bagHashString = string.format("%s_%d_%d", itemString or "", bagID, slotID)
                        
                        -- Match if itemString matches AND it's the right quantity
                        if wonItem.itemHash:find(itemString) and count == wonItem.remainingQuantity then
                            foundBag = bagID
                            foundSlot = slotID
                            break
                        end
                    end
                end
            end
            if foundBag then break end
        end
    end
    
    -- Fallback: Find by itemID only (for items added before hash tracking)
    if not foundBag then
        for bagID = 0, 4 do
            for slotID = 1, GetContainerNumSlots(bagID) do
                local bagItemLink = GetContainerItemLink(bagID, slotID)
                if bagItemLink and tonumber(bagItemLink:match("item:(%d+)")) == itemID then
                    foundBag = bagID
                    foundSlot = slotID
                    break
                end
            end
            if foundBag then break end
        end
    end
    
    if not foundBag or not foundSlot then
        print("|cffff0000[GDKPT]|r Could not find " .. itemLink .. " in your bags!")
        return false
    end
    
    local _, stackSize = GetContainerItemInfo(foundBag, foundSlot)
    stackSize = stackSize or 1
    
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
        itemHash = wonItem.itemHash  -- NEW: Track which specific instance was placed
    })
    
    print(string.format("|cff00ff00[GDKPT]|r Placed %s in trade slot %d (Auction #%d)", 
        itemLink, tradeSlot, wonItem.auctionId or 0))
    
    -- Refresh the helper frame
    C_Timer.After(0.1, function()
        GDKPT.RaidLeader.TradeHelper.Update()
    end)
    
    return true
end






-- Add this new function to check what's actually in trade slots:
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


-- Replace CreateItemButton function - add tooltip support:
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

    -- Update the tooltip in CreateItemButton to show auction-specific info:
    btn:SetScript(
        "OnEnter",
        function(self)
            if self.itemLink then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(self.itemLink)

                -- Add auction information if available
                if self.wonItem and self.wonItem.itemHash then
                    -- Find the specific auction by hash
                    local auctionData = GDKPT.RaidLeader.Core.AuctionedItems[self.wonItem.itemHash]

                    if auctionData and auctionData.hasEnded then
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddLine("|cff00ff00 This item has been auctioned|r", 1, 1, 1)

                        if auctionData.auctionId then
                            GameTooltip:AddLine(
                                "|cffaaaaaa  Auction ID: " .. auctionData.auctionId .. "|r",
                                0.7,
                                0.7,
                                0.7
                            )
                        end

                        if auctionData.winner and auctionData.winner ~= "Bulk" then
                            GameTooltip:AddLine("|cff00ccff  Winner: " .. auctionData.winner .. "|r", 0, 0.8, 1)

                            if auctionData.winningBid and auctionData.winningBid > 0 then
                                GameTooltip:AddLine(
                                    string.format("|cffffd700  Winning Bid: %d gold|r", auctionData.winningBid),
                                    1,
                                    0.84,
                                    0
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
                        1,
                        0.7,
                        0
                    )
                end

                GameTooltip:Show()
            end
        end
    )


    btn:SetScript("OnClick", function(self)
    if not self.wonItem then return end
    if self.wonItem.fullyTraded then
        print("|cffff0000[GDKPT]|r This item has already been traded.")
        return
    end

    if not TradeFrame or not TradeFrame:IsShown() then
        print("|cffff8800[GDKPT]|r Open the trade window before placing items.")
        return
    end

    -- Attempt to place the item in trade
    PlaceItemInTrade(self.itemID, self.itemLink, self.wonItem)

end)




    return btn
end




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
    
    --  Get fresh won items data
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
        
        -- IMPROVED: Show status based on current state
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
helperEventFrame:RegisterEvent("TRADE_SHOW")
helperEventFrame:RegisterEvent("TRADE_CLOSED")
helperEventFrame:RegisterEvent("TRADE_PLAYER_ITEM_CHANGED")
helperEventFrame:RegisterEvent("TRADE_TARGET_ITEM_CHANGED")




helperEventFrame:SetScript("OnEvent", function(self, event, slotID)
    if event == "TRADE_SHOW" then
        -- Only show in raid and if master looter
        if IsInRaid() then
            local lootMethod = select(1, GetLootMethod())
            if lootMethod == "master" then
                local partner = UnitName("NPC")
                if partner and GDKPT.RaidLeader.Core.PlayerWonItems[partner] then
                    C_Timer.After(0.2, function()
                        GDKPT.RaidLeader.TradeHelper.Show()
                    end)
                end
            end
        end
        
    elseif event == "TRADE_CLOSED" then
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
        
    elseif event == "TRADE_PLAYER_ITEM_CHANGED" or event == "TRADE_TARGET_ITEM_CHANGED" then
        -- Update when items change in trade window
        C_Timer.After(0.05, function()
            if TradeHelperFrame and TradeHelperFrame:IsShown() then
                GDKPT.RaidLeader.TradeHelper.Update()
            end
        end)
    end
end)



-------------------------------------------------------------------
-- Manual toggle command
-------------------------------------------------------------------
SLASH_GDKPTTRADEHELPER1 = "/gdkpthelper"
SlashCmdList["GDKPTTRADEHELPER"] = function(msg)
    if msg == "show" then
        GDKPT.RaidLeader.TradeHelper.Show()
    elseif msg == "hide" then
        GDKPT.RaidLeader.TradeHelper.Hide()
    else
        if TradeHelperFrame and TradeHelperFrame:IsShown() then
            GDKPT.RaidLeader.TradeHelper.Hide()
        else
            GDKPT.RaidLeader.TradeHelper.Show()
        end
    end
end