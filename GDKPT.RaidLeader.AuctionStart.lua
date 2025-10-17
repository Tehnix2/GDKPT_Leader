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


    -- every /gdkpleader auctioned item gets stored in a new row of the ActiveAuctions table with row index auctionID

    local auctionId = GDKPT.RaidLeader.Core.nextAuctionId
    GDKPT.RaidLeader.Core.nextAuctionId = GDKPT.RaidLeader.Core.nextAuctionId + 1

     

    -- Store item information from /gdkp auction [itemlink] mouseovered item in a table
    GDKPT.RaidLeader.Core.ActiveAuctions[auctionId] = {
        id = auctionId,
        itemID = itemID,
        itemLink = itemLink,
        startTime = GetTime(),
        endTime = GetTime() + GDKPT.RaidLeader.Core.AuctionSettings.duration,
        startBid = GDKPT.RaidLeader.Core.AuctionSettings.startBid,
        currentBid = 0,
        topBidder = "",
        history = {}
    }

    -- Announce to raid and send data to member addons
    local msg =
        string.format(
        "AUCTION_START:%d:%d:%d:%d:%d:%s",
        auctionId,
        itemID,
        GDKPT.RaidLeader.Core.AuctionSettings.startBid,
        GDKPT.RaidLeader.Core.AuctionSettings.minIncrement,
        GDKPT.RaidLeader.Core.ActiveAuctions[auctionId].endTime,
        itemLink
    )

   
    SendChatMessage(
        string.format("[GDKPT] Bidding starts on %s! Starting at %d gold.", itemLink, GDKPT.RaidLeader.Core.AuctionSettings.startBid),
        "RAID"
    )

    C_Timer.After(
        1,
        function()
            GDKPT.RaidLeader.MessageHandler.SafeSendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, msg, "RAID")
        end
    )
end






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