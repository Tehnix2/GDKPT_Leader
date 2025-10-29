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
                        traded = false,
                        auctionId = id,
                        amountPaid = 0
                    }) 
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
                
            end
        end
    end
)






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

