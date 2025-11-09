GDKPT.RaidLeader.AuctionStart = {}


------------------------------------------------------------------------
-- Function to start an auction for a given item link and bag/slot
------------------------------------------------------------------------



function GDKPT.RaidLeader.AuctionStart.StartAuction(itemLink, bagID, slotID)

    if not bagID or not slotID then
        print(GDKPT.RaidLeader.Core.errorPrintString .. "Could not detect item bag/slot.")
        return
    end

    if not IsRaidLeader() and not IsRaidOfficer() then
        print(GDKPT.RaidLeader.Core.errorPrintString .. "Only the Raid Leader or an Officer can start auctions.")
        return
    end
    
    local itemID = tonumber(itemLink:match("item:(%d+)"))
    if not itemID then
        print(GDKPT.RaidLeader.Core.errorPrintString .. "Invalid item link. Cannot start an auction for this item.")
        return
    end

    -- If the pot has been finalized, do not allow new auctions
    if GDKPT.RaidLeader.Core.PotFinalized then
        print(GDKPT.RaidLeader.Core.errorPrintString .. "Cannot start auction - pot has been finalized!")
        return
    end

    -- Verify the item is still in the specified slot
    local currentLink = GetContainerItemLink(bagID, slotID)
    if not currentLink or currentLink ~= itemLink then
        print(GDKPT.RaidLeader.Core.errorPrintString .. "Item has moved or been removed from that slot.")
        return
    end

    -- Get stackCount for that specific bag/slot
    local stackCount = 1
    local _, _, _, _, _, _, _, maxStack = GetItemInfo(itemID)
    if maxStack and maxStack > 1 then
        local _, count = GetContainerItemInfo(bagID, slotID)
        stackCount = count or 1
    end


    -- Generate unique hash for THIS specific item instance in order to track duplicate items
    local itemHash = GDKPT.RaidLeader.Utils.CreateItemHash(bagID, slotID, itemLink)

    -- Assign a new auction ID

    local auctionId = GDKPT.RaidLeader.Core.nextAuctionId
    GDKPT.RaidLeader.Core.nextAuctionId = GDKPT.RaidLeader.Core.nextAuctionId + 1

    -- Assign auction duration and endTime based on serverTime + duration setting
     
    local duration = GDKPT.RaidLeader.Core.AuctionSettings.duration
    local serverTime = time()
    
    -- Store auction data in ActiveAuctions table
    GDKPT.RaidLeader.Core.ActiveAuctions[auctionId] = {
        id = auctionId,
        itemID = itemID,
        itemLink = itemLink,
        startTime = serverTime,
        endTime = serverTime + duration,
        duration = duration,
        startBid = GDKPT.RaidLeader.Core.AuctionSettings.startBid,
        currentBid = 0,
        topBidder = "",
        stackCount = stackCount,
        itemHash = itemHash
    }
    
    -- Track this specific item instance by its hash
    GDKPT.RaidLeader.Core.AuctionedItems[itemHash] = {
        auctioned = true,
        auctionId = auctionId,
        timestamp = serverTime,
        itemLink = itemLink,
        stackCount = stackCount,
        itemHash = itemHash,
        winner = nil,        -- Will be set when auction ends
        winningBid = nil,    -- Will be set when auction ends
        itemID = itemID
    }


    -- Construct and send AUCTION_START addon message to raid after short delay

    local msg = string.format(
        "AUCTION_START:%d:%d:%d:%d:%d:%d:%s",
        auctionId,
        itemID,
        GDKPT.RaidLeader.Core.AuctionSettings.startBid,
        GDKPT.RaidLeader.Core.AuctionSettings.minIncrement,
        duration,
        stackCount,
        itemLink
    )

    C_Timer.After(0.5, function()
        SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, msg, "RAID")
    end)
   
    SendChatMessage(string.format("[GDKPT] Bidding starts on %s! Starting at %d gold.", itemLink, GDKPT.RaidLeader.Core.AuctionSettings.startBid),"RAID")
end






------------------------------------------------------------------------
-- Function to start auction from slash command /gdkpleader auction
------------------------------------------------------------------------

function GDKPT.RaidLeader.AuctionStart.StartAuctionFromSlashCommand()
    local bagID, slotID = GDKPT.RaidLeader.Utils.GetMouseoverBagSlot()

    if not bagID or not slotID then
        print(GDKPT.RaidLeader.Core.errorPrintString .. "Could not detect bag/slot. Make sure you're hovering over an item.")
        return
    end

    local itemLink = GetContainerItemLink(bagID, slotID)
    if not itemLink then
        print(GDKPT.RaidLeader.Core.errorPrintString .. "No item found in that slot.")
        return
    end
        
    GDKPT.RaidLeader.AuctionStart.StartAuction(itemLink, bagID, slotID)
end 




