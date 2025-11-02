GDKPT.RaidLeader.TooltipAuction = {}

-- Create a unique hash for an item in a specific bag slot
local function CreateItemHash(bagID, slotID, itemLink)
    local texture, count = GetContainerItemInfo(bagID, slotID)
    local itemString = itemLink:match("item:([%-?%d:]+)")
    return itemString, texture, count
end

-- Check if an item in a bag slot was auctioned
local function WasItemAuctioned(bagID, slotID, itemLink)
    if not itemLink then return false, nil end
    
    local itemString, texture, count = CreateItemHash(bagID, slotID, itemLink)
    
    -- Check all tracked items to see if any match this item's properties
    for hash, data in pairs(GDKPT.RaidLeader.Core.AuctionedItems or {}) do
        -- Check if the hash starts with matching item properties
        if hash:find(itemString) and hash:find(tostring(texture)) then
            -- Additional validation: check if count matches for stackable items
            local _, itemCount = GetContainerItemInfo(bagID, slotID)
            if itemCount and data.stackCount and itemCount == data.stackCount then
                return true, data
            elseif not data.stackCount or data.stackCount == 1 then
                return true, data
            end
        end
    end
    
    return false, nil
end

local function OnTooltipSetItem(tooltip)
    if not tooltip or not tooltip.GetItem then return end
    
    local _, itemLink = tooltip:GetItem()
    if not itemLink then return end
    
    local itemID = tonumber(itemLink:match("item:(%d+)"))
    if not itemID then return end
    
    -- Check auction status
    local bagID, slotID = nil, nil
    local owner = tooltip:GetOwner()
    
    if owner and owner:GetName() then
        local name = owner:GetName()
        if name:match("^ContainerFrame%dItem%d+$") then
            local bagFrameID = tonumber(name:match("^ContainerFrame(%d+)Item%d+$"))
            local bagFrame = _G["ContainerFrame"..bagFrameID]
            if bagFrame then
                bagID = bagFrame:GetID()
                local slotNum = tonumber(name:match("Item(%d+)$"))
                if slotNum then
                    local numSlots = GetContainerNumSlots(bagID)
                    slotID = numSlots - slotNum + 1
                end
            end
        end
    end
    
    if not bagID or not slotID then return end
    
    local wasAuctioned, auctionData = WasItemAuctioned(bagID, slotID, itemLink)
    
    if wasAuctioned and auctionData then
        tooltip:AddLine(" ")
        tooltip:AddLine("|cff00ff00 This item has been auctioned|r", 1, 1, 1)
        
        if auctionData.auctionId then
            tooltip:AddLine("|cffaaaaaa  Auction ID: " .. auctionData.auctionId .. "|r", 0.7, 0.7, 0.7)
        end
        
        if auctionData.hasEnded and auctionData.winner then
            if auctionData.winner == "Bulk" then
                tooltip:AddLine("|cffffcc00  No winner - Added to Bulk|r", 1, 0.8, 0)
            else
                local winnerText = "|cff00ccff  Winner: " .. auctionData.winner .. "|r"
                tooltip:AddLine(winnerText, 0, 0.8, 1)
                
                if auctionData.winningBid and auctionData.winningBid > 0 then
                    local bidText = string.format("|cffffd700  Winning Bid: %d gold|r", auctionData.winningBid)
                    tooltip:AddLine(bidText, 1, 0.84, 0)
                end
            end
        elseif auctionData.hasEnded == false or not auctionData.winner then
            tooltip:AddLine("|cffffff00  Auction in progress...|r", 1, 1, 0)
        end
        
        tooltip:Show()
    end
end

-- Hook GameTooltip
GameTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)

-- Also hook ItemRefTooltip for shift-click links
if ItemRefTooltip then
    ItemRefTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
end

-- Clear tracking command
SLASH_GDKPTCLEARTRACKED1 = "/gdkptcleartracked"
SlashCmdList["GDKPTCLEARTRACKED"] = function()
    if GDKPT.RaidLeader.Core.AuctionedItems then
        wipe(GDKPT.RaidLeader.Core.AuctionedItems)
        print("|cff00ff00[GDKPT Leader]|r Cleared all auctioned item tracking")
    end
end

-- Debug command to see what's tracked
SLASH_GDKPTSHOWTRACKED1 = "/gdkptshowtracked"
SlashCmdList["GDKPTSHOWTRACKED"] = function()
    local count = 0
    print("|cff00ff00[GDKPT Debug]|r Currently tracked auctioned items:")
    
    if not GDKPT.RaidLeader.Core.AuctionedItems then
        print("|cff00ff00[GDKPT Debug]|r No items currently tracked")
        return
    end
    
    for hash, data in pairs(GDKPT.RaidLeader.Core.AuctionedItems) do
        count = count + 1
        print(string.format("  %d. %s (Auction #%d)", 
            count, data.itemLink, data.auctionId))
        print(string.format("     Hash: %s", hash))
    end
    
    if count == 0 then
        print("|cff00ff00[GDKPT Debug]|r No items currently tracked")
    end
end

-- Command to manually check if current mouseover item was auctioned
SLASH_GDKPTCHECKITEM1 = "/gdkptcheckitem"
SlashCmdList["GDKPTCHECKITEM"] = function()
    local bagID, slotID = GetMouseoverBagSlot()
    if not bagID or not slotID then
        print("|cffff0000Hover over an item in your bags first.|r")
        return
    end
    
    local itemLink = GetContainerItemLink(bagID, slotID)
    if not itemLink then
        print("|cffff0000No item in that slot.|r")
        return
    end
    
    local wasAuctioned, data = WasItemAuctioned(bagID, slotID, itemLink)
    if wasAuctioned then
        print("|cff00ff00This item WAS auctioned (Auction #" .. (data.auctionId or "?") .. ")|r")
    else
        print("|cffff0000This item was NOT auctioned.|r")
    end
end

--[[

GDKPT.RaidLeader.TooltipAuction = {}

-- Create a unique hash for an item in a specific bag slot
local function CreateItemHash(bagID, slotID, itemLink)
    local texture, count = GetContainerItemInfo(bagID, slotID)
    local itemString = itemLink:match("item:([%-?%d:]+)")
    
    -- For checking if item was auctioned, we create a hash that would match
    -- We need to check against all stored hashes since we don't have the original timestamp
    return itemString, texture, count
end

-- Check if an item in a bag slot was auctioned
local function WasItemAuctioned(bagID, slotID, itemLink)
    if not itemLink then return false, nil end
    
    local itemString, texture, count = CreateItemHash(bagID, slotID, itemLink)
    
    -- Check all tracked items to see if any match this item's properties
    for hash, data in pairs(GDKPT.RaidLeader.Core.AuctionedItems or {}) do
        -- Check if the hash starts with matching item properties
        if hash:find(itemString) and hash:find(tostring(texture)) then
            -- Additional validation: check if count matches for stackable items
            local _, itemCount = GetContainerItemInfo(bagID, slotID)
            if itemCount and data.stackCount and itemCount == data.stackCount then
                return true, data
            elseif not data.stackCount or data.stackCount == 1 then
                return true, data
            end
        end
    end
    
    return false, nil
end






local function OnTooltipSetItem(tooltip)
    if not tooltip or not tooltip.GetItem then return end
    
    local _, itemLink = tooltip:GetItem()
    if not itemLink then return end
    
    local itemID = tonumber(itemLink:match("item:(%d+)"))
    if not itemID then return end
    
    -- Check for bugged item status FIRST
    if GDKPT.RaidLeader.Core.BuggedItems[itemID] then
        local bugData = GDKPT.RaidLeader.Core.BuggedItems[itemID]
        tooltip:AddLine(" ")
        tooltip:AddLine("|cffff0000 BUGGED ITEM - CANNOT BE TRADED |r", 1, 1, 1)
        tooltip:AddLine("|cffff8800  Use manual adjustment to handle this item|r", 1, 0.5, 0)
        
        if bugData.detectedAt then
            tooltip:AddLine(string.format("|cff888888  Detected: %s|r", 
                date("%H:%M:%S", bugData.detectedAt)), 0.5, 0.5, 0.5)
        end
        tooltip:Show()
        return  -- Don't show auctioned status if bugged
    end
    
    -- Rest of the existing auction status code...
    local bagID, slotID = nil, nil
    local owner = tooltip:GetOwner()
    
    if owner and owner:GetName() then
        local name = owner:GetName()
        if name:match("^ContainerFrame%dItem%d+$") then
            local bagFrameID = tonumber(name:match("^ContainerFrame(%d+)Item%d+$"))
            local bagFrame = _G["ContainerFrame"..bagFrameID]
            if bagFrame then
                bagID = bagFrame:GetID()
                local slotNum = tonumber(name:match("Item(%d+)$"))
                if slotNum then
                    local numSlots = GetContainerNumSlots(bagID)
                    slotID = numSlots - slotNum + 1
                end
            end
        end
    end
    
    if not bagID or not slotID then return end
    
    local wasAuctioned, auctionData = WasItemAuctioned(bagID, slotID, itemLink)
    
    if wasAuctioned and auctionData then
        tooltip:AddLine(" ")
        tooltip:AddLine("|cff00ff00 This item has been auctioned|r", 1, 1, 1)
        
        if auctionData.auctionId then
            tooltip:AddLine("|cffaaaaaa  Auction ID: " .. auctionData.auctionId .. "|r", 0.7, 0.7, 0.7)
        end
        
        if auctionData.hasEnded and auctionData.winner then
            if auctionData.winner == "Bulk" then
                tooltip:AddLine("|cffffcc00  No winner - Added to Bulk|r", 1, 0.8, 0)
            else
                local winnerText = "|cff00ccff  Winner: " .. auctionData.winner .. "|r"
                tooltip:AddLine(winnerText, 0, 0.8, 1)
                
                if auctionData.winningBid and auctionData.winningBid > 0 then
                    local bidText = string.format("|cffffd700  Winning Bid: %d gold|r", auctionData.winningBid)
                    tooltip:AddLine(bidText, 1, 0.84, 0)
                end
            end
        elseif auctionData.hasEnded == false or not auctionData.winner then
            tooltip:AddLine("|cffffff00  Auction in progress...|r", 1, 1, 0)
        end
        
        tooltip:Show()
    end
end


-- Hook GameTooltip
GameTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)

-- Also hook ItemRefTooltip for shift-click links
if ItemRefTooltip then
    ItemRefTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
end

-- Clear tracking command
SLASH_GDKPTCLEARTRACKED1 = "/gdkptcleartracked"
SlashCmdList["GDKPTCLEARTRACKED"] = function()
    if GDKPT.RaidLeader.Core.AuctionedItems then
        wipe(GDKPT.RaidLeader.Core.AuctionedItems)
        print("|cff00ff00[GDKPT Leader]|r Cleared all auctioned item tracking")
    end
end

-- Debug command to see what's tracked
SLASH_GDKPTSHOWTRACKED1 = "/gdkptshowtracked"
SlashCmdList["GDKPTSHOWTRACKED"] = function()
    local count = 0
    print("|cff00ff00[GDKPT Debug]|r Currently tracked auctioned items:")
    
    if not GDKPT.RaidLeader.Core.AuctionedItems then
        print("|cff00ff00[GDKPT Debug]|r No items currently tracked")
        return
    end
    
    for hash, data in pairs(GDKPT.RaidLeader.Core.AuctionedItems) do
        count = count + 1
        print(string.format("  %d. %s (Auction #%d)", 
            count, data.itemLink, data.auctionId))
        print(string.format("     Hash: %s", hash))
    end
    
    if count == 0 then
        print("|cff00ff00[GDKPT Debug]|r No items currently tracked")
    end
end

-- Command to manually check if current mouseover item was auctioned
SLASH_GDKPTCHECKITEM1 = "/gdkptcheckitem"
SlashCmdList["GDKPTCHECKITEM"] = function()
    local bagID, slotID = GetMouseoverBagSlot()
    if not bagID or not slotID then
        print("|cffff0000Hover over an item in your bags first.|r")
        return
    end
    
    local itemLink = GetContainerItemLink(bagID, slotID)
    if not itemLink then
        print("|cffff0000No item in that slot.|r")
        return
    end
    
    local wasAuctioned, data = WasItemAuctioned(bagID, slotID, itemLink)
    if wasAuctioned then
        print("|cff00ff00This item WAS auctioned (Auction #" .. (data.auctionId or "?") .. ")|r")
    else
        print("|cffff0000This item was NOT auctioned.|r")
    end
end


]]