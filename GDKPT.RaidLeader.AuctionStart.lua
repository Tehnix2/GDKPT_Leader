GDKPT.RaidLeader.AuctionStart = {}

-- Helper function to get bag and slot from mouseover
function GetMouseoverBagSlot()
    local frame = GetMouseFocus()
    if not frame or not frame:GetParent() then return nil, nil end
    
    local name = frame:GetName()
    if name and name:match("^ContainerFrame%dItem%d+$") then
        local bagFrameID = tonumber(name:match("^ContainerFrame(%d+)Item%d+$"))
        local bagFrame = _G["ContainerFrame"..bagFrameID]
        if bagFrame then
            local bagID = bagFrame:GetID()
            local slotID = tonumber(name:match("Item(%d+)$"))
            if bagID and slotID then
                local numSlots = GetContainerNumSlots(bagID)
                slotID = numSlots - slotID + 1
                return bagID, slotID
            end
        end
    end
    return nil, nil
end

-- Create a unique hash for a specific item instance
-- Uses item properties that make it unique even among duplicates
local function CreateItemHash(bagID, slotID, itemLink)
    local texture, count, locked = GetContainerItemInfo(bagID, slotID)
    
    -- Parse itemLink to get all unique identifiers
    local itemString = itemLink:match("item:([%-?%d:]+)")
    
    -- Create hash from: itemString + current timestamp + bag + slot + texture
    -- This ensures each auction gets a unique hash even for identical items
    local hash = string.format("%s_%d_%d_%d_%s_%d", 
        itemString or "", 
        bagID, 
        slotID, 
        time(), 
        tostring(texture),
        count or 1
    )
    
    return hash
end

------------------------------------------------------------------------
-- StartAuction(itemLink, bagID, slotID)
------------------------------------------------------------------------
function GDKPT.RaidLeader.AuctionStart.StartAuction(itemLink, bagID, slotID)
    -- Validate bag/slot
    if not bagID or not slotID then
        print("|cffff0000Could not detect item bag/slot.|r")
        return
    end

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

    -- Verify the item is still in the specified slot
    local currentLink = GetContainerItemLink(bagID, slotID)
    if not currentLink or currentLink ~= itemLink then
        print("|cffff0000Item has moved or been removed from that slot.|r")
        return
    end

    local stackCount = 1
    local _, _, _, _, _, _, _, maxStack = GetItemInfo(itemID)
    if maxStack and maxStack > 1 then
        local _, count = GetContainerItemInfo(bagID, slotID)
        stackCount = count or 1
    end

    -- Generate unique hash for THIS specific item instance
    local itemHash = CreateItemHash(bagID, slotID, itemLink)

    local auctionId = GDKPT.RaidLeader.Core.nextAuctionId
    GDKPT.RaidLeader.Core.nextAuctionId = GDKPT.RaidLeader.Core.nextAuctionId + 1
     
    local duration = GDKPT.RaidLeader.Core.AuctionSettings.duration
    local serverTime = time()
    
    -- Store item information
    GDKPT.RaidLeader.Core.ActiveAuctions[auctionId] = {
        id = auctionId,
        itemID = itemID,
        itemLink = itemLink,
        startTime = serverTime,
        endTime = serverTime + duration,
        startBid = GDKPT.RaidLeader.Core.AuctionSettings.startBid,
        currentBid = 0,
        topBidder = "",
        stackCount = stackCount,
        history = {},
        itemHash = itemHash
    }
    
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
    
    -- Track this specific item instance by its hash
    GDKPT.RaidLeader.Core.AuctionedItems[itemHash] = {
        auctioned = true,
        auctionId = auctionId,
        timestamp = serverTime,
        itemLink = itemLink,
        stackCount = stackCount,
        itemHash = itemHash,
        winner = nil,  -- Will be set when auction ends
        winningBid = nil  -- Will be set when auction ends
    }
    
    print("|cff00ff00[GDKPT Leader]|r Item marked as auctioned. Will show in tooltip.")

    SendChatMessage(
        string.format("[GDKPT] Bidding starts on %s! Starting at %d gold.", itemLink, GDKPT.RaidLeader.Core.AuctionSettings.startBid),
        "RAID"
    )
    
    C_Timer.After(1, function()
        GDKPT.RaidLeader.MessageHandler.SafeSendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, msg, "RAID")
    end)
end

-- Slash command handler
SLASH_GDKPLEADERAUCTION1 = "/gdkpleader"
SlashCmdList["GDKPLEADERAUCTION"] = function(msg)
    local command, rest = msg:match("^(%S*)%s*(.-)$")
    
    if command == "auction" then
        -- Get mouseover bag and slot
        local bagID, slotID = GetMouseoverBagSlot()
        
        if not bagID or not slotID then
            print("|cffff0000Could not detect bag/slot. Make sure you're hovering over an item.|r")
            return
        end
        
        local itemLink = GetContainerItemLink(bagID, slotID)
        if not itemLink then
            print("|cffff0000No item found in that slot.|r")
            return
        end
        
        GDKPT.RaidLeader.AuctionStart.StartAuction(itemLink, bagID, slotID)
    end
end





--[[


GDKPT.RaidLeader.AuctionStart = {}





-- Helper function to get bag and slot from mouseover
local function GetMouseoverBagSlot()
    local frame = GetMouseFocus()
    if not frame or not frame:GetParent() then return nil, nil end
    
    local name = frame:GetName()
    if name and name:match("^ContainerFrame%dItem%d+$") then
        local bagFrameID = tonumber(name:match("^ContainerFrame(%d+)Item%d+$"))
        local bagFrame = _G["ContainerFrame"..bagFrameID]
        if bagFrame then
            local bagID = bagFrame:GetID()
            local slotID = tonumber(name:match("Item(%d+)$"))
            if bagID and slotID then
                local numSlots = GetContainerNumSlots(bagID)
                slotID = numSlots - slotID + 1
                return bagID, slotID
            end
        end
    end
    return nil, nil
end



-- Get unique identifier for an item in a specific slot
local function GetItemGUID(bagID, slotID)
    -- In 3.3.5, we need to use tooltip scanning to get unique item info
    local scanTooltip = CreateFrame("GameTooltip", "GDKPTScanTooltip", nil, "GameTooltipTemplate")
    scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    scanTooltip:SetBagItem(bagID, slotID)
    
    -- Get texture, count, and locked status as additional identifiers
    local texture, count, locked = GetContainerItemInfo(bagID, slotID)
    
    -- Create a semi-unique identifier (not perfect, but best we can do in 3.3.5)
    -- This combines bag, slot, texture, and count
    local identifier = string.format("%d:%d:%s:%d:%d", bagID, slotID, tostring(texture), count or 1, time())
    
    scanTooltip:Hide()
    return identifier
end







------------------------------------------------------------------------
-- StartAuction(itemLink)
-- Function that handles starting a new auction on the member frame
-- called through ingame mouseover /gdkpleader auction [itemlink] macro
------------------------------------------------------------------------



function GDKPT.RaidLeader.AuctionStart.StartAuction(itemLink, bagID, slotID)

    -- Validate bag/slot
    if not bagID or not slotID then
        print("|cffff0000Could not detect item bag/slot.|r")
        return
    end

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

    local stackCount = 1

    -- Only use inventory count if item is actually stackable
    local _, _, _, _, _, _, _, maxStack = GetItemInfo(itemID)
    if maxStack and maxStack > 1 then
        stackCount = GDKPT.RaidLeader.Utils.GetInventoryStackCount(itemLink)
    end




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



    
    -- Create unique identifier for this specific item stack
    if foundBag and foundSlot then
        local uniqueKey = string.format("%d-%d-%s", foundBag, foundSlot, itemLink)
        GDKPT.RaidLeader.Core.AuctionedItemInstances[uniqueKey] = {
            auctioned = true,
            auctionId = auctionId,
            timestamp = time(),
            bagID = foundBag,
            slotID = foundSlot,
            itemLink = itemLink,
            stackCount = stackCount
        }
        
        -- Update inventory overlays
        if GDKPT.RaidLeader.InventoryOverlay and GDKPT.RaidLeader.InventoryOverlay.UpdateSpecificSlot then
            GDKPT.RaidLeader.InventoryOverlay.UpdateSpecificSlot(foundBag, foundSlot)
        end
    end

   
    SendChatMessage(
        string.format("[GDKPT] Bidding starts on %s! Starting at %d gold.", itemLink, GDKPT.RaidLeader.Core.AuctionSettings.startBid),
        "RAID"
    )
    
    C_Timer.After(1, function()
        GDKPT.RaidLeader.MessageHandler.SafeSendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, msg, "RAID")
    end)
end



function GDKPT.RaidLeader.AuctionStart.MouseoverAuction()
    local focus = GetMouseFocus()
    if not focus or not focus:GetParent() then return end

    local bag = focus:GetParent():GetID()
    local slot = tonumber(focus:GetName():match("Item(%d+)"))
    local itemLink = select(2, GameTooltip:GetItem())
    if not itemLink then return end

    DEFAULT_CHAT_FRAME.editBox:SetText("/gdkpleader auction "..itemLink.." "..bag.." "..slot)
    ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
end


]]