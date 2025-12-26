GDKPT.RaidLeader.BulkAuction = {}

-------------------------------------------------------------------
-- Toggle item in/out of bulk list (mouseover function)
-------------------------------------------------------------------

function GDKPT.RaidLeader.BulkAuction.ToggleItemInBulkList()
    local bagID, slotID = GDKPT.RaidLeader.Utils.GetMouseoverBagSlot()
    
    if not bagID or not slotID then
        print(GDKPT.RaidLeader.Core.errorPrintString .. "No item under cursor.")
        return
    end
    
    local itemLink = GetContainerItemLink(bagID, slotID)
    if not itemLink then
        print(GDKPT.RaidLeader.Core.errorPrintString .. "No item found in that slot.")
        return
    end
    
    local itemID = tonumber(itemLink:match("item:(%d+)"))
    if not itemID then return end
    
    -- Get stack count
    local _, count = GetContainerItemInfo(bagID, slotID)
    local stackCount = count or 1
    
    -- Create hash for this specific item instance
    local _, itemInstanceHash = GDKPT.RaidLeader.Utils.CreateItemHash(bagID, slotID, itemLink)
    
    -- Check if already in bulk list
    local existingIndex = nil
    for i, bulkItem in ipairs(GDKPT.RaidLeader.Core.BulkAuctionList) do
        if bulkItem.itemInstanceHash == itemInstanceHash then
            existingIndex = i
            break
        end
    end
    
    if existingIndex then
        -- Remove from list
        table.remove(GDKPT.RaidLeader.Core.BulkAuctionList, existingIndex)
        print(GDKPT.RaidLeader.Core.addonPrintString .. "Removed " .. itemLink .. " from bulk list.")
    else
        -- Add to list
        table.insert(GDKPT.RaidLeader.Core.BulkAuctionList, {
            itemID = itemID,
            itemLink = itemLink,
            stackCount = stackCount,
            itemInstanceHash = itemInstanceHash,
            bagID = bagID,
            slotID = slotID
        })
        print(GDKPT.RaidLeader.Core.addonPrintString .. "Added " .. itemLink .. " x" .. stackCount .. " to bulk list.")
    end
end


-------------------------------------------------------------------
-- Show current bulk list
-------------------------------------------------------------------

function GDKPT.RaidLeader.BulkAuction.ShowBulkList()
    if #GDKPT.RaidLeader.Core.BulkAuctionList == 0 then
        print(GDKPT.RaidLeader.Core.addonPrintString .. "Bulk list is empty.")
        return
    end
    
    print(GDKPT.RaidLeader.Core.addonPrintString .. "Current Bulk Auction List:")
    for i, item in ipairs(GDKPT.RaidLeader.Core.BulkAuctionList) do
        print(string.format("  [%d] %s x%d", i, item.itemLink, item.stackCount))
    end
end


-------------------------------------------------------------------
-- Start bulk auction (called when auctioning hearthstone)
-------------------------------------------------------------------


function GDKPT.RaidLeader.BulkAuction.StartBulkAuction()
    if #GDKPT.RaidLeader.Core.BulkAuctionList == 0 then
        print(GDKPT.RaidLeader.Core.errorPrintString .. "No items in bulk list!")
        return
    end
    
    if GDKPT.RaidLeader.Core.PotFinalized then
        print(GDKPT.RaidLeader.Core.errorPrintString .. "Cannot start auction - pot has been finalized!")
        return
    end
    
    local auctionId = GDKPT.RaidLeader.Core.nextAuctionId
    GDKPT.RaidLeader.Core.nextAuctionId = GDKPT.RaidLeader.Core.nextAuctionId + 1
    
    local duration = GDKPT.RaidLeader.Core.AuctionSettings.duration
    local serverTime = time()
    
    -- Build item list string - ONLY itemID:stackCount (no item links)
    local itemListStr = ""
    for i, item in ipairs(GDKPT.RaidLeader.Core.BulkAuctionList) do
        if i > 1 then itemListStr = itemListStr .. "," end
        itemListStr = itemListStr .. string.format("%d:%d", item.itemID, item.stackCount)
    end


    -- Make a copy of the bulk list before wiping it
    local bulkItemsCopy = {}
    for _, item in ipairs(GDKPT.RaidLeader.Core.BulkAuctionList) do
        table.insert(bulkItemsCopy, {
            itemID = item.itemID,
            itemLink = item.itemLink,
            stackCount = item.stackCount,
            itemInstanceHash = item.itemInstanceHash,
            bagID = item.bagID,
            slotID = item.slotID
        })
    end

    
    -- Store auction data with full item info
    GDKPT.RaidLeader.Core.ActiveAuctions[auctionId] = {
        id = auctionId,
        itemID = 6948,
        itemLink = "|cffffffff[Bulk Auction]|r",
        startTime = serverTime,
        endTime = serverTime + duration,
        duration = duration,
        startBid = GDKPT.RaidLeader.Core.AuctionSettings.startBid,
        currentBid = 0,
        topBidder = "",
        stackCount = 1,
        isBulkAuction = true,
        bulkItems = bulkItemsCopy
    }
    
    -- Send compact message to raid
    local msg = string.format(
        "BULK_AUCTION_START:%d:%d:%d:%d:%d:%s",
        auctionId,
        GDKPT.RaidLeader.Core.AuctionSettings.startBid,
        GDKPT.RaidLeader.Core.AuctionSettings.minIncrement,
        duration,
        #GDKPT.RaidLeader.Core.BulkAuctionList,
        itemListStr
    )
    
    C_Timer.After(0.5, function()
        SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, msg, "RAID")
    end)
    
    SendChatMessage("[GDKPT] Bidding starts on Bulk Auction! Starting at " 
        .. GDKPT.RaidLeader.Core.AuctionSettings.startBid .. " gold.", "RAID")
    
    wipe(GDKPT.RaidLeader.Core.BulkAuctionList)
    print(GDKPT.RaidLeader.Core.addonPrintString .. "Bulk auction started. Bulk list cleared.")
end