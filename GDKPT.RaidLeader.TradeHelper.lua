GDKPT.RaidLeader.TradeHelper = {}

local TradeHelperFrame = nil
local itemButtons = {}

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
    local tradeSlot = GetNextEmptyTradeSlot()
    if not tradeSlot then
        print("|cffff0000[GDKPT]|r Trade window is full! Remove items or complete trade first.")
        return false
    end
    
    -- Find the item in bags
    for bagID = 0, 4 do
        for slotID = 1, GetContainerNumSlots(bagID) do
            local bagItemLink = GetContainerItemLink(bagID, slotID)
            if bagItemLink and tonumber(bagItemLink:match("item:(%d+)")) == itemID then
                local _, stackSize = GetContainerItemInfo(bagID, slotID)
                stackSize = stackSize or 1
                
                -- Place in trade
                PickupContainerItem(bagID, slotID)
                ClickTradeButton(tradeSlot)
                
                -- Track this placement
                if not GDKPT.RaidLeader.Trading.CurrentTrade.itemsOffered then
                    GDKPT.RaidLeader.Trading.CurrentTrade.itemsOffered = {}
                end
                
                table.insert(GDKPT.RaidLeader.Trading.CurrentTrade.itemsOffered, {
                    wonItem = wonItem,
                    stackSize = stackSize,
                    itemID = itemID,
                    itemLink = itemLink,
                    placementOrder = tradeSlot
                })
                
                print(string.format("|cff00ff00[GDKPT]|r Placed %s in trade slot %d", itemLink, tradeSlot))
                
                -- Refresh the helper frame to show updated status
                C_Timer.After(0.1, function()
                    GDKPT.RaidLeader.TradeHelper.Update()
                end)
                
                return true
            end
        end
    end
    
    print("|cffff0000[GDKPT]|r Could not find " .. itemLink .. " in your bags!")
    return false
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
    name:SetPoint("RIGHT", btn, "RIGHT", -60, 0)
    name:SetJustifyH("LEFT")
    name:SetWordWrap(false)
    btn.name = name
    
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
    
    -- Tooltip
    btn:SetScript("OnEnter", function(self)
        if self.itemLink then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(self.itemLink)
            GameTooltip:Show()
        end
    end)
    btn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    -- Click handler
    btn:SetScript("OnClick", function(self)
        if self.wonItem and self.itemID and self.itemLink then
            if self.wonItem.fullyTraded then
                print("|cffff8800[GDKPT]|r This item has already been traded!")
            else
                PlaceItemInTrade(self.itemID, self.itemLink, self.wonItem)
            end
        end
    end)
    
    return btn
end

-------------------------------------------------------------------
-- Update the Trade Helper Frame with current trade partner's items
-------------------------------------------------------------------
function GDKPT.RaidLeader.TradeHelper.Update()
    local frame = TradeHelperFrame
    if not frame or not frame:IsShown() then return end
    
    local partner = GDKPT.RaidLeader.Trading.CurrentTrade.partner
    if not partner then
        frame:Hide()
        return
    end
    
    -- Update player name
    frame.playerName:SetText("Trading with: " .. partner)
    
    -- Get won items for this player
    local wonItems = GDKPT.RaidLeader.Core.PlayerWonItems[partner]
    if not wonItems or #wonItems == 0 then
        frame.playerName:SetText(partner .. " - No items to trade")
        -- Clear all buttons
        for _, btn in ipairs(itemButtons) do
            btn:Hide()
        end
        return
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
        
        -- Show price or checkmark
        if wonItem.fullyTraded then
            btn.price:Hide()
            btn.check:Show()
            btn:SetAlpha(0.5)
            btn:Disable()
        else
            btn.check:Hide()
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

helperEventFrame:SetScript("OnEvent", function(self, event, ...)
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
        GDKPT.RaidLeader.TradeHelper.Hide()
        
    elseif event == "TRADE_PLAYER_ITEM_CHANGED" then
        -- Update when items change in trade window
        C_Timer.After(0.1, function()
            GDKPT.RaidLeader.TradeHelper.Update()
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

print("|cff00ff00[GDKPT]|r Trade Helper loaded. Use /gdkpthelper to toggle.")