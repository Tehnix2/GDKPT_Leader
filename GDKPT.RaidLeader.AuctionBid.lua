GDKPT.RaidLeader.AuctionBid = {}



-------------------------------------------------------------------
-- HandleBid() function is triggered from the event frame below
-- whenever a raidmember is bidding on an item
-------------------------------------------------------------------

local function HandleBid(sender, auctionId, bidAmount)
    -- auctionId and bidAmount get sent over as string, so need to conver to number
    auctionId = tonumber(auctionId)
    bidAmount = tonumber(bidAmount)

    local auction = GDKPT.RaidLeader.Core.ActiveAuctions[auctionId]

    if not auction then
        return
    end -- Auction doesn't exist or is over

    -- Validate the incoming bid once more for safety reasons

    if bidAmount and bidAmount < auction.currentBid + GDKPT.RaidLeader.Core.AuctionSettings.minIncrement then
        print("Incoming bid is incorrect")
        return
    end

    -- If the incoming bid is validated, then update the currentBid and topBidder for this auction
    if bidAmount and sender then
        auction.currentBid = bidAmount
        auction.topBidder = sender

        -- Adding a bid increases the duration of the auction by extraTime
        auction.endTime = auction.endTime + GDKPT.RaidLeader.Core.AuctionSettings.extraTime

        -- Send the update to all members
        local updateMsg =
            string.format(
            "AUCTION_UPDATE:%d:%d:%s:%d",
            auctionId,
            auction.currentBid,
            auction.topBidder,
            auction.endTime
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


-- Event handler for addon messages
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