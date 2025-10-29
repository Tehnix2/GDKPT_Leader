GDKPT.RaidLeader.AuctionBid = {}



-------------------------------------------------------------------
-- HandleBid() function is triggered from the event frame below
-- whenever a raidmember is bidding on an item
-------------------------------------------------------------------

local function HandleBid(sender, auctionId, bidAmount)
    auctionId = tonumber(auctionId)
    bidAmount = tonumber(bidAmount)
    local auction = GDKPT.RaidLeader.Core.ActiveAuctions[auctionId]
    
    if not auction then
        return
    end 
    

    --  Check if auction has already ended
    -- This prevents late bids from being processed after the auction timer expires
    if auction.hasEnded then
        print(string.format("|cffff8800[GDKPT Leader]|r Rejected late bid from %s on auction %d (already ended)", sender, auctionId))
        return
    end

    if bidAmount and bidAmount < auction.currentBid + GDKPT.RaidLeader.Core.AuctionSettings.minIncrement then
        print("Incoming bid is incorrect")
        return
    end

    -- Additional safety check: reject bids if auction time has expired
    if time() >= auction.endTime then
        print(string.format("|cffff8800[GDKPT Leader]|r Rejected late bid from %s on auction %d (time expired)", sender, auctionId))
        return
    end
    
    if bidAmount and sender then
        auction.currentBid = bidAmount
        auction.topBidder = sender
        
        -- Add extra time
        auction.endTime = auction.endTime + GDKPT.RaidLeader.Core.AuctionSettings.extraTime
        
        -- Calculate remaining time from current server time
        local remainingTime = auction.endTime - time()
        
        -- Send the update with remaining time instead of absolute endTime
        local updateMsg = string.format(
            "AUCTION_UPDATE:%d:%d:%s:%d:%d:%s",
            auctionId,
            auction.currentBid,
            auction.topBidder,
            remainingTime, -- Send remaining time, not absolute endTime
            auction.itemID,
            auction.itemLink
        )
        
        GDKPT.RaidLeader.MessageHandler.SafeSendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, updateMsg, "RAID")
        SendChatMessage(
            string.format(
                "[GDKPT] %s is now the highest bidder on %s with %d gold! ",
                auction.topBidder,
                auction.itemLink,
                auction.currentBid
            ),
            "RAID"
        )
    end
end



-------------------------------------------------------------------
-- eventFrame that receives incoming messages from raid member Addon
-- gets called when a player is bidding on an item (manual or bidButton)
-------------------------------------------------------------------


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")

eventFrame:SetScript(
    "OnEvent",
    function(self, event, prefix, msg, channel, sender)
        if prefix ~= GDKPT.RaidLeader.Core.addonPrefix or not GDKPT.RaidLeader.Utils.IsSenderInMyRaid(sender) then
            return
        end

        local cmd, data = msg:match("([^:]+):(.*)")
        if cmd == "BID" then
            local auctionId, bidAmount = data:match("([^:]+):([^:]+)")
            HandleBid(sender, auctionId, bidAmount)
        end
    end
)




