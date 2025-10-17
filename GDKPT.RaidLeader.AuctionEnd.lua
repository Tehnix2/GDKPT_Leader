GDKPT.RaidLeader.AuctionEnd = {}





-------------------------------------------------------------------
-- Auction End logic
-------------------------------------------------------------------




local timerFrame = CreateFrame("Frame")



local timerFrame = CreateFrame("Frame")

-- Timer to process the message queue and check for auction ends
timerFrame:SetScript(
    "OnUpdate",
    function(self, elapsed)
        -- **1. MESSAGE QUEUE LOGIC (Runs every 0.2 seconds)**
        -- Process one message from the queue with a delay to prevent flooding.
        if GetTime() - (self.lastMessageSent or 0) > 0.2 and #GDKPT.RaidLeader.MessageHandler.MessageQueue > 0 then
            local message = table.remove(GDKPT.RaidLeader.MessageHandler.MessageQueue, 1)
            SendAddonMessage(message.prefix, message.msg, message.channel)
            self.lastMessageSent = GetTime()
        end

        -- **2. AUCTION ENDING LOGIC (Throttle to 1 second)**
        self.timeSinceLastCheck = (self.timeSinceLastCheck or 0) + elapsed

        if self.timeSinceLastCheck >= 1 then
            self.timeSinceLastCheck = 0

            local now = GetTime()
            local finishedAuctions = {}

            for id, auction in pairs(GDKPT.RaidLeader.Core.ActiveAuctions) do
                if now >= auction.endTime then
                    table.insert(finishedAuctions, id)
                end
            end

            for _, id in ipairs(finishedAuctions) do
                local auction = GDKPT.RaidLeader.Core.ActiveAuctions[id]

                -- Your Chat Message announcing the winner (uses SendChatMessage, which is fine)
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

                -- Send message to member addon to remove the row of the finished auction

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

                -- Remove from active auctions
                GDKPT.RaidLeader.Core.ActiveAuctions[id] = nil
            end
        end
    end
)





-------------------------------------------------------------------
-- 
-------------------------------------------------------------------



-------------------------------------------------------------------
-- 
-------------------------------------------------------------------


-------------------------------------------------------------------
-- 
-------------------------------------------------------------------


-------------------------------------------------------------------
-- 
-------------------------------------------------------------------


-------------------------------------------------------------------
-- 
-------------------------------------------------------------------