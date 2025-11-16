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

    -- Assign a new auction ID

    local auctionId = GDKPT.RaidLeader.Core.nextAuctionId
    GDKPT.RaidLeader.Core.nextAuctionId = GDKPT.RaidLeader.Core.nextAuctionId + 1

    -- Assign auction duration and endTime based on serverTime + duration setting
     
    local duration = GDKPT.RaidLeader.Core.AuctionSettings.duration
    local serverTime = time()


    -- Generate two item hashes for THIS specific item 
    -- auctionHash is unique cause it includes a timestamp
    -- itemInstanceHash does NOT include a timestamp
    local auctionHash, itemInstanceHash = GDKPT.RaidLeader.Utils.CreateItemHash(bagID, slotID, itemLink)
    
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
        auctionHash = auctionHash,
        itemInstanceHash = itemInstanceHash
    }
    
    -- Track this specific item instance by its hash
    GDKPT.RaidLeader.Core.AuctionedItems[auctionHash] = {
        auctioned = true,
        auctionId = auctionId,
        timestamp = serverTime,
        itemLink = itemLink,
        stackCount = stackCount,
        auctionHash = auctionHash,
        itemInstanceHash = itemInstanceHash,
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








-------------------------------------------------------------------
-- Start auction from loot window / from creature corpse
-------------------------------------------------------------------

function GDKPT.RaidLeader.AuctionStart.StartAuctionFromLootWindow(lootSlot)
    if not IsRaidLeader() and not IsRaidOfficer() then
        print(GDKPT.RaidLeader.Core.errorPrintString .. "Only the Raid Leader or an Officer can start auctions.")
        return
    end
    
    if not LootSlotIsItem(lootSlot) then
        print(GDKPT.RaidLeader.Core.errorPrintString .. "This item cannot be auctioned.")
        return
    end
    
    local itemLink = GetLootSlotLink(lootSlot)
    if not itemLink then
        print(GDKPT.RaidLeader.Core.errorPrintString .. "Could not get item link from loot slot.")
        return
    end
    
    local itemID = tonumber(itemLink:match("item:(%d+)"))
    if not itemID then
        print(GDKPT.RaidLeader.Core.errorPrintString .. "Invalid item link.")
        return
    end
    
    -- Check if pot is finalized
    if GDKPT.RaidLeader.Core.PotFinalized then
        print(GDKPT.RaidLeader.Core.errorPrintString .. "Cannot start auction - pot has been finalized!")
        return
    end
    
    -- Get stack count from loot slot
    local _, _, stackCount = GetLootSlotInfo(lootSlot)
    stackCount = stackCount or 1
    
    -- Assign auction ID
    local auctionId = GDKPT.RaidLeader.Core.nextAuctionId
    GDKPT.RaidLeader.Core.nextAuctionId = GDKPT.RaidLeader.Core.nextAuctionId + 1
    
    local duration = GDKPT.RaidLeader.Core.AuctionSettings.duration
    local serverTime = time()
    
    -- Create special hash for loot window items (no bag/slot)
    local auctionHash = string.format("LOOT_%d_%d_%s", 
        auctionId, serverTime, itemLink:match("item:([%-?%d:]+)") or "")
    local itemInstanceHash = string.format("LOOT_%s", 
        itemLink:match("item:([%-?%d:]+)") or "")
    
    -- Store auction data
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
        auctionHash = auctionHash,
        itemInstanceHash = itemInstanceHash,
        isLootWindowItem = true  -- FLAG for special handling
    }
    
    -- Track in AuctionedItems
    GDKPT.RaidLeader.Core.AuctionedItems[auctionHash] = {
        auctioned = true,
        auctionId = auctionId,
        timestamp = serverTime,
        itemLink = itemLink,
        stackCount = stackCount,
        auctionHash = auctionHash,
        itemInstanceHash = itemInstanceHash,
        winner = nil,
        winningBid = nil,
        itemID = itemID,
        isLootWindowItem = true
    }
    
    -- Send to raid
    local msg = string.format(
        "AUCTION_START:%d:%d:%d:%d:%d:%d:%s",
        auctionId, itemID,
        GDKPT.RaidLeader.Core.AuctionSettings.startBid,
        GDKPT.RaidLeader.Core.AuctionSettings.minIncrement,
        duration, stackCount, itemLink
    )
    
    C_Timer.After(0.5, function()
        SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, msg, "RAID")
    end)
    
    SendChatMessage(string.format("[GDKPT] Bidding starts on %s! Starting at %d gold.", 
        itemLink, GDKPT.RaidLeader.Core.AuctionSettings.startBid), "RAID")
end


------------------------------------------------------------------------
-- Function to start auction for loot window auctions from slash command 
-- /gdkpleader corpseauction
------------------------------------------------------------------------

function GDKPT.RaidLeader.AuctionStart.PrintLootSlotsForCorpseAuction()
    -- Show loot slots
    print(GDKPT.RaidLeader.Core.addonPrintString .. "Available loot slots:")
    for i = 1, GetNumLootItems() do
        if LootSlotIsItem(i) then
            local link = GetLootSlotLink(i)
            local _, _, count = GetLootSlotInfo(i)
            print(string.format("  [%d] %s x%d", i, link or "Unknown", count or 1))
        end
    end
    print("Use: /gdkpleader loot <slot> to auction that item")

end


function GDKPT.RaidLeader.AuctionStart.StartAuctionForCorpseLootFromSlashCommand(slot)

    if GetNumLootItems() == 0 then
        print(GDKPT.RaidLeader.Core.errorPrintString .. "No loot window open.")
        return
    end

    if slot and slot > 0 and slot <= GetNumLootItems() then
        GDKPT.RaidLeader.AuctionStart.StartAuctionFromLootWindow(slot)
    else
        print(GDKPT.RaidLeader.Core.errorPrintString .. "Invalid loot slot.")
    end

end 











