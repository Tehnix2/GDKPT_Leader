-----------------------------------------------------------------------------------
-- Smart Manual Gold Balance Adjustments
-- Click player -> Select won item -> Automatically adjusts by that item's price
-----------------------------------------------------------------------------------

-- Default adjustment ID for general adjustments
local GENERAL_ADJUSTMENT_ID = -1

-- Store current adjustment state
local adjustmentState = {
    playerName = nil,
    items = nil,
    selectedIndex = 1,
}


-------------------------------------------------------------------
-- Format item list for display
-------------------------------------------------------------------


local function GetItemListText()
    if not adjustmentState.items then return "" end  -- if there are no items to adjust then just end
    
    local lines = {}
    for i, item in ipairs(adjustmentState.items) do
        local prefix = (i == adjustmentState.selectedIndex) and ">>>> " or "  "
        local color = (i == adjustmentState.selectedIndex) and "|cff00ff00" or "|cff888888"
        local suffix = (i == adjustmentState.selectedIndex) and " <<<<" or "  "
        table.insert(lines, string.format("%s%s[%d] %s - %dg %s|r", 
            prefix, color, item.auctionId, item.itemLink, item.price, suffix))
    end
    
    return table.concat(lines, "\n")
end

-------------------------------------------------------------------
-- Mark auction item as manually adjusted
-------------------------------------------------------------------


local function MarkAuctionAsAdjusted(playerName, auctionId, adjustmentAmount)
    local wonItems = GDKPT.RaidLeader.Core.PlayerWonItems[playerName]
    if not wonItems then return end
    
    for i, item in ipairs(wonItems) do
        if item.auctionId == auctionId then
            item.manuallyAdjusted = true
            item.adjustedAmount = adjustmentAmount
            item.fullyTraded = true
            item.remainingQuantity = 0
            
            print(string.format(GDKPT.RaidLeader.Core.addonPrintString .. "Marked auction #%d as manually adjusted for %s", 
                auctionId, playerName))
            break
        end
    end
    
    -- Remove fully traded items
    for i = #wonItems, 1, -1 do
        if wonItems[i].fullyTraded then
            table.remove(wonItems, i)
        end
    end
    
    -- Clean up empty entries
    if #wonItems == 0 then
        GDKPT.RaidLeader.Core.PlayerWonItems[playerName] = nil
    end
end

-------------------------------------------------------------------
-- Broadcast adjustment to raid
-------------------------------------------------------------------


local function BroadcastAdjustment(playerName, adjustmentAmount, newPot, newBalance, auctionId)
    local message = string.format("%s:%s:%d:%d:%d:%d", 
        "MANUAL_ADJUSTMENT",
        playerName, 
        adjustmentAmount, 
        newPot,
        newBalance,
        auctionId
    )
    
    SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, message, "RAID")
end

-------------------------------------------------------------------
-- Apply the adjustment to core data
-------------------------------------------------------------------

-- Apply adjustment to player balance and pot, mark auction as adjusted, broadcast, update UI
local function ApplyAdjustment(playerName, adjustmentAmount, auctionId)
    -- Update player balance
    local oldBalance = GDKPT.RaidLeader.Core.PlayerBalances[playerName] or 0
    local newBalance = oldBalance + adjustmentAmount
    GDKPT.RaidLeader.Core.PlayerBalances[playerName] = newBalance -- set new balance
    
    -- Update pot (inverse of player balance change)
    local newPot = GDKPT.RaidLeader.Core.GDKP_Pot - adjustmentAmount
    GDKPT.RaidLeader.Core.GDKP_Pot = newPot
    
    -- Mark specific auction as adjusted if applicable
    if auctionId > 0 then
        MarkAuctionAsAdjusted(playerName, auctionId, adjustmentAmount)
    end
    
    -- Broadcast to raid
    BroadcastAdjustment(playerName, adjustmentAmount, newPot, newBalance, auctionId)
    
    -- Update PlayerBalance table
    GDKPT.RaidLeader.PlayerBalance.UpdatePlayerBalance()
    
    -- Log success
    local auctionLabel = (auctionId == GENERAL_ADJUSTMENT_ID) and "General" or tostring(auctionId)
    print(string.format(GDKPT.RaidLeader.Core.addonPrintString .. "Adjustment of %d G applied to %s (Auction ID: %s)", 
        adjustmentAmount, playerName, auctionLabel))
end

-------------------------------------------------------------------
-- Item selection: Select won item to refund
-- The auction ID and price are auto-filled based on selection
-------------------------------------------------------------------


StaticPopupDialogs["GDKPT_ADJUST_PLAYER"] = {
    text = "Select item to refund:",
    button1 = "Confirm",
    button2 = CANCEL,
    hasEditBox = false,
    timeout = 0,
    hideOnEscape = true,
    whileDead = true,
    
    OnShow = function(self, data)
        -- Get player name from parameter or data field or adjustment state
        local playerName = data or self.data or adjustmentState.playerName
                
        -- Store state
        adjustmentState.playerName = playerName
        adjustmentState.items = GDKPT.RaidLeader.Utils.GetPlayerWonItems(playerName)
        adjustmentState.selectedIndex = 1
        
        if adjustmentState.items and #adjustmentState.items > 0 then
            -- Show item selection mode
            self.text:SetText(string.format(
                "Select item to refund for %s:\n\n%s\n\nUse UP/DOWN arrows to select",
                playerName,
                GetItemListText()
            ))
            self.button2:Show()

            if self.button2:IsShown() and self.text then
                -- Hook OnKeyDown
                self:SetScript("OnKeyDown", function(self, key)
                    if not adjustmentState.items then return end

                    if key == "UP" then
                        adjustmentState.selectedIndex = math.max(1, adjustmentState.selectedIndex - 1)
                    elseif key == "DOWN" then
                        adjustmentState.selectedIndex = math.min(#adjustmentState.items, adjustmentState.selectedIndex + 1)
                    else
                        return
                    end

                    self.text:SetText(string.format(
                        "Select item to refund for %s:\n\n%s\n\nUse UP/DOWN arrows to select",
                        adjustmentState.playerName,
                        GetItemListText()
                    ))
                end)
            end
        end
    end,
    
    OnAccept = function(self)
        local playerName = adjustmentState.playerName
        
        if adjustmentState.items and adjustmentState.items[adjustmentState.selectedIndex] then
            local selectedItem = adjustmentState.items[adjustmentState.selectedIndex]
            
            -- Refund: positive adjustment (gives gold back)
            local refundAmount = selectedItem.price
            
            ApplyAdjustment(playerName, refundAmount, selectedItem.auctionId)
        end
    end,
    
    
    OnKeyDown = function(self, key)
        if not adjustmentState.items then return end

        if key == "UP" then
            adjustmentState.selectedIndex = math.max(1, adjustmentState.selectedIndex - 1)
        elseif key == "DOWN" then
            adjustmentState.selectedIndex = math.min(#adjustmentState.items, adjustmentState.selectedIndex + 1)
        else
            return
        end

        -- Update the text after changing selection
        self.text:SetText(string.format(
            "Select item to refund for %s:\n\n%s\n\nUse UP/DOWN arrows to select",
            adjustmentState.playerName,
            GetItemListText()
        ))
    end,
}



-------------------------------------------------------------------
-- Exposing for other files
-------------------------------------------------------------------


GDKPT.RaidLeader.AdjustmentState = adjustmentState
