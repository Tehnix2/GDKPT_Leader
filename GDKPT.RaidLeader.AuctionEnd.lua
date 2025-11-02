GDKPT.RaidLeader.AuctionEnd = {}

GDKPT.RaidLeader.Core.PlayerWonItems = GDKPT.RaidLeader.Core.PlayerWonItems or {}


-------------------------------------------------------------------
-- Auction End logic
-------------------------------------------------------------------

local timerFrame = CreateFrame("Frame")




timerFrame:SetScript(
    "OnUpdate",
    function(self, elapsed)
        if GetTime() - (self.lastMessageSent or 0) > 0.2 and #GDKPT.RaidLeader.MessageHandler.MessageQueue > 0 then
            local message = table.remove(GDKPT.RaidLeader.MessageHandler.MessageQueue, 1)
            SendAddonMessage(message.prefix, message.msg, message.channel)
            self.lastMessageSent = GetTime()
        end

        
        self.timeSinceLastCheck = (self.timeSinceLastCheck or 0) + elapsed

        if self.timeSinceLastCheck >= 1 then
            self.timeSinceLastCheck = 0

            local now = GetTime()
            local finishedAuctions = {}

            for id, auction in pairs(GDKPT.RaidLeader.Core.ActiveAuctions) do
                -- Only process auctions that haven't been marked as ended yet
                if not auction.hasEnded and time() >= auction.endTime then
                    table.insert(finishedAuctions, id)
                end
            end

            for _, id in ipairs(finishedAuctions) do
                local auction = GDKPT.RaidLeader.Core.ActiveAuctions[id]

                -- Mark this auction as ended so we don't process it again
                auction.hasEnded = true

                
                if auction.topBidder ~= "" then
                    SendChatMessage(
                        string.format(
                            "[GDKPT] Auction for %s finished! Winner: %s with %d gold!",
                            auction.itemLink,
                            auction.topBidder,
                            auction.currentBid
                        ),
                        "RAID"
                    )
                else
                    auction.topBidder = "Bulk"
                    SendChatMessage(
                        string.format(
                            "[GDKPT] Auction for %s finished! No bids. Adding this item to the bulk.",
                            auction.itemLink
                        ),
                        "RAID"
                    )
                end

                if auction.topBidder ~= "" and auction.currentBid > 0 then
                    GDKPT.RaidLeader.Core.GDKP_Pot = GDKPT.RaidLeader.Core.GDKP_Pot + auction.currentBid
                end

                if auction.topBidder ~= "Bulk" and auction.currentBid > 0 then
                    if not GDKPT.RaidLeader.Core.PlayerWonItems[auction.topBidder] then
                        GDKPT.RaidLeader.Core.PlayerWonItems[auction.topBidder] = {}
                    end
                    table.insert(GDKPT.RaidLeader.Core.PlayerWonItems[auction.topBidder], {
                        itemID = auction.itemID,
                        itemLink = auction.itemLink,
                        stackCount = auction.stackCount,
                        traded = false,
                        auctionId = id,
                        amountPaid = 0,
                        price = auction.currentBid,           -- NEW: Store winning bid
                        winningBid = auction.currentBid,       -- NEW: Alternative field name
                        bid = auction.currentBid               -- NEW: Another alternative
                    }) 
                end

                -- Update the tracked item with winner information
                if auction.itemHash and GDKPT.RaidLeader.Core.AuctionedItems[auction.itemHash] then
                    GDKPT.RaidLeader.Core.AuctionedItems[auction.itemHash].winner = auction.topBidder
                    GDKPT.RaidLeader.Core.AuctionedItems[auction.itemHash].winningBid = auction.currentBid
                    GDKPT.RaidLeader.Core.AuctionedItems[auction.itemHash].hasEnded = true
                end
                
               
                local endMsg =
                    string.format(
                    "AUCTION_END:%d:%d:%d:%s:%d",
                    id,
                    GDKPT.RaidLeader.Core.GDKP_Pot,
                    auction.itemID,
                    auction.topBidder,
                    auction.currentBid
                )

                GDKPT.RaidLeader.MessageHandler.SafeSendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, endMsg, "RAID")

                if not GDKPT.RaidLeader.Core.PlayerBalances[auction.topBidder] then
                    GDKPT.RaidLeader.Core.PlayerBalances[auction.topBidder] = 0
                end

                GDKPT.RaidLeader.Core.PlayerBalances[auction.topBidder] = GDKPT.RaidLeader.Core.PlayerBalances[auction.topBidder] - auction.currentBid

                GDKPT.RaidLeader.UI.UpdateRosterDisplay()

                if GDKPT.RaidLeader.Trading.UpdateReadyForPotSplitButton then
                    GDKPT.RaidLeader.Trading.UpdateReadyForPotSplitButton()
                end
                
            end
        end
    end
)





function GDKPT.RaidLeader.AuctionEnd.UpdateDataAfterManualAdjustment(playerName, adjustmentAmount, auctionIndex)
    
    local oldPlayerBalance = GDKPT.RaidLeader.Core.PlayerBalances[playerName] or 0
    local newPlayerBalance = oldPlayerBalance + adjustmentAmount
    
    GDKPT.RaidLeader.Core.PlayerBalances[playerName] = newPlayerBalance

    -- Adjust pot: if we're reducing player debt (negative adjustment), pot goes down
    -- if we're increasing player debt (positive adjustment), pot goes up
    local newPot = GDKPT.RaidLeader.Core.GDKP_Pot - adjustmentAmount
    GDKPT.RaidLeader.Core.GDKP_Pot = newPot

    -- If this adjustment is for a specific auction, mark the item as manually handled
    if auctionIndex > 0 then
        local wonItems = GDKPT.RaidLeader.Core.PlayerWonItems[playerName]
        if wonItems then
            for i, item in ipairs(wonItems) do
                if item.auctionId == auctionIndex then
                    item.manuallyAdjusted = true
                    item.adjustedAmount = adjustmentAmount
                    -- Mark as fully traded so it won't appear in future trades
                    item.fullyTraded = true
                    item.remainingQuantity = 0
                    print(string.format("|cff00ff00[GDKPT Leader]|r Marked auction #%d as manually adjusted for %s", 
                        auctionIndex, playerName))
                    break
                end
            end
            
            -- Remove fully traded items
            for i = #wonItems, 1, -1 do
                if wonItems[i].fullyTraded then
                    table.remove(wonItems, i)
                end
            end
            
            -- Clean up empty player entries
            if #wonItems == 0 then
                GDKPT.RaidLeader.Core.PlayerWonItems[playerName] = nil
            end
        end
    end

    local manualAdjustmentMessage = string.format("MANUAL_ADJUSTMENT:%s:%d:%d:%d:%d", 
        playerName, 
        adjustmentAmount, 
        newPot,                 
        newPlayerBalance,       
        auctionIndex or -1
    )

    GDKPT.RaidLeader.MessageHandler.SafeSendAddonMessage(
        GDKPT.RaidLeader.Core.addonPrefix, manualAdjustmentMessage, "RAID")
    GDKPT.RaidLeader.UI.UpdateRosterDisplay()
    
    -- Update ready for pot split button
    if GDKPT.RaidLeader.Trading.UpdateReadyForPotSplitButton then
        GDKPT.RaidLeader.Trading.UpdateReadyForPotSplitButton()
    end
end





--[[






function GDKPT.RaidLeader.AuctionEnd.UpdateDataAfterManualAdjustment(playerName, adjustmentAmount, auctionIndex)
    
    local oldPlayerBalance = GDKPT.RaidLeader.Core.PlayerBalances[playerName] or 0
    local newPlayerBalance = oldPlayerBalance + adjustmentAmount
    
    GDKPT.RaidLeader.Core.PlayerBalances[playerName] = newPlayerBalance

    local newPot = GDKPT.RaidLeader.Core.GDKP_Pot - adjustmentAmount
    GDKPT.RaidLeader.Core.GDKP_Pot = newPot

    local manualAdjustmentMessage = string.format("MANUAL_ADJUSTMENT:%s:%d:%d:%d:%d", 
        playerName, 
        adjustmentAmount, 
        newPot,                 
        newPlayerBalance,       
        auctionIndex or -1
    )

    GDKPT.RaidLeader.MessageHandler.SafeSendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, manualAdjustmentMessage, "RAID")
    GDKPT.RaidLeader.UI.UpdateRosterDisplay()
end


]]