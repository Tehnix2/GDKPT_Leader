GDKPT.RaidLeader.AuctionStart = {}



------------------------------------------------------------------------
-- StartAuction(itemLink)
-- Function that handles starting a new auction on the member frame
-- called through ingame mouseover /gdkpleader auction [itemlink] macro
------------------------------------------------------------------------



function GDKPT.RaidLeader.AuctionStart.StartAuction(itemLink)
    if not IsRaidLeader() and not IsRaidOfficer() then
        print("|cffff0000Only the Raid Leader or an Officer can start auctions.|r")
        return
    end
    local itemID = tonumber(itemLink:match("item:(%d+)"))
    if not itemID then
        print("|cffff0000Invalid item link. Cannot start an auction for this item.|r")
        return
    end

    if GDKPT.RaidLeader.Core.PotFinalized then
        print("|cffff3333[GDKPT Leader]|r Cannot start auction - pot has been finalized!")
        return
    end


    local stackCount =  GDKPT.RaidLeader.Utils.GetInventoryStackCount(itemLink)



    local auctionId = GDKPT.RaidLeader.Core.nextAuctionId
    GDKPT.RaidLeader.Core.nextAuctionId = GDKPT.RaidLeader.Core.nextAuctionId + 1
     
    local duration = GDKPT.RaidLeader.Core.AuctionSettings.duration
    local serverTime = time() -- Unix timestamp, synchronized across clients
    
    -- Store item information
    GDKPT.RaidLeader.Core.ActiveAuctions[auctionId] = {
        id = auctionId,
        itemID = itemID,
        itemLink = itemLink,
        startTime = serverTime,
        endTime = serverTime + duration, -- Use server time instead of GetTime()
        startBid = GDKPT.RaidLeader.Core.AuctionSettings.startBid,
        currentBid = 0,
        topBidder = "",
        stackCount = stackCount,
        history = {}
    }
    
    -- Send the message with duration instead of absolute endTime
    local msg = string.format(
        "AUCTION_START:%d:%d:%d:%d:%d:%d:%s",
        auctionId,
        itemID,
        GDKPT.RaidLeader.Core.AuctionSettings.startBid,
        GDKPT.RaidLeader.Core.AuctionSettings.minIncrement,
        duration, -- Send duration, not endTime
        stackCount,
        itemLink
    )
   
    SendChatMessage(
        string.format("[GDKPT] Bidding starts on %s! Starting at %d gold.", itemLink, GDKPT.RaidLeader.Core.AuctionSettings.startBid),
        "RAID"
    )
    
    C_Timer.After(1, function()
        GDKPT.RaidLeader.MessageHandler.SafeSendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, msg, "RAID")
    end)
end

