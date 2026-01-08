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
    
    -- Make a copy of the bulk list
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
        itemLink = "Bulk Auction",
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
    
    -- Send initial bulk auction header
    local headerMsg = string.format(
        "BULK_AUCTION_START:%d:%d:%d:%d:%d",
        auctionId,
        GDKPT.RaidLeader.Core.AuctionSettings.startBid,
        GDKPT.RaidLeader.Core.AuctionSettings.minIncrement,
        duration,
        #bulkItemsCopy
    )
    
    SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, headerMsg, "RAID")
    
    -- Send item data in chunks (max 10 items per message to stay under 255 char limit)
    local chunkSize = 10
    for i = 1, #bulkItemsCopy, chunkSize do
        local itemChunk = {}
        for j = i, math.min(i + chunkSize - 1, #bulkItemsCopy) do
            table.insert(itemChunk, string.format("%d:%d", 
                bulkItemsCopy[j].itemID, 
                bulkItemsCopy[j].stackCount))
        end
        
        local chunkMsg = string.format("BULK_AUCTION_DATA:%d:%s",
            auctionId,
            table.concat(itemChunk, ",")
        )
        
        C_Timer.After(0.1 * ((i - 1) / chunkSize + 1), function()
            SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, chunkMsg, "RAID")
        end)
    end
    
    SendChatMessage("[GDKPT] Bidding starts on Bulk Auction! Starting at " 
        .. GDKPT.RaidLeader.Core.AuctionSettings.startBid .. " gold.", "RAID")
    
    wipe(GDKPT.RaidLeader.Core.BulkAuctionList)
    print(GDKPT.RaidLeader.Core.addonPrintString .. "Bulk auction started. Bulk list cleared.")
end


