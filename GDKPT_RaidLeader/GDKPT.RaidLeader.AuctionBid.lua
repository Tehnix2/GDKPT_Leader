GDKPT.RaidLeader.AuctionBid = {}

-------------------------------------------------------------------
--- Function to handle incoming bids from raid members
-------------------------------------------------------------------

local function HandleBid(sender, auctionId, bidAmount)

    local auction = GDKPT.RaidLeader.Core.ActiveAuctions[auctionId]
    
    if not auction then
        return
    end 
    
    -- Reject bids on ended auctions
    if auction.hasEnded then
        print(string.format(GDKPT.RaidLeader.Core.errorPrintString .. "Rejected late bid from %s on auction %d.", sender, auctionId))
        return
    end



    -- Reject bids if auction time has expired
    if time() >= auction.endTime then
        print(string.format(GDKPT.RaidLeader.Core.errorPrintString .. "Rejected late bid from %s on auction %d (time expired)", sender, auctionId))
        return
    end


    -- Validate bid amount
    -- If a players' bid amount is deemed invalid (probably because another player clicked the button very shortly before them), then their bidButton is re-enabled

    if bidAmount and bidAmount < auction.currentBid + GDKPT.RaidLeader.Core.AuctionSettings.minIncrement and not auction.hasEnded then
        print(string.format(GDKPT.RaidLeader.Core.errorPrintString .. "%s did an invalid bid, their bidButton is enabled again.",sender))
        SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix,"AUCTION_BID_REENABLE","WHISPER",sender)
        return
    end

    
    -- Accept the bid
    if bidAmount and sender then
        auction.currentBid = bidAmount 
        auction.topBidder = sender     

        -- Timer Cap System
        -- Calculate timer cap (half of original duration)
        local timerCap = math.floor(auction.duration / 2)
        local currentRemaining = auction.endTime - time()

        -- Always add the extra time first
        local newRemaining = currentRemaining + GDKPT.RaidLeader.Core.AuctionSettings.extraTime

        -- Cap at timer cap OR full duration, whichever is appropriate
        if currentRemaining <= timerCap then
            -- Already in final stretch - cap at timerCap
            newRemaining = math.min(newRemaining, timerCap)
        else
            -- Still in first half - cap at full duration
            newRemaining = math.min(newRemaining, auction.duration)
        end
        
        auction.endTime = time() + newRemaining

        
        -- Calculate remaining time from current server time
        local remainingTime = auction.endTime - time()   
        
        local updateMsg = string.format(
            "AUCTION_UPDATE:%d:%d:%s:%d:%d:%s",
            auctionId,
            auction.currentBid,
            auction.topBidder,
            remainingTime, 
            auction.itemID,
            auction.itemLink
        )
        
        SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, updateMsg, "RAID")
        SendChatMessage(string.format("[GDKPT] %s is now the highest bidder on %s with %d gold! ",auction.topBidder,auction.itemLink,auction.currentBid),"RAID")
    end
end



-------------------------------------------------------------------
--- Frame to receive and process incoming bid messages
-------------------------------------------------------------------


local bidReceiverFrame = CreateFrame("Frame")
bidReceiverFrame:RegisterEvent("CHAT_MSG_ADDON")

bidReceiverFrame:SetScript(
    "OnEvent",
    function(self, event, prefix, msg, channel, sender)

        if not IsRaidLeader() and not IsRaidOfficer() then
            return
        end

        if prefix ~= GDKPT.RaidLeader.Core.addonPrefix or not GDKPT.RaidLeader.Utils.IsSenderInMyRaid(sender) then
            return
        end

        local cmd, data = msg:match("([^:]+):(.*)")
        if cmd == "BID" then
            local auctionId, bidAmount = data:match("([^:]+):([^:]+)")
            HandleBid(sender, tonumber(auctionId), tonumber(bidAmount))
        end
    end
)




