GDKPT.RaidLeader.TooltipAuction = {}


-- this function now exists twice, once here and once in raidleader utils, which one should we keep?

-- Create a unique hash for an item in a specific bag slot
local function CreateItemHash(bagID, slotID, itemLink)
    local texture, count = GetContainerItemInfo(bagID, slotID)
    local itemString = itemLink:match("item:([%-?%d:]+)")
    return itemString, texture, count
end


local function FindMatchingAuction(bagID, slotID, itemLink)
    if not itemLink then return nil end
    
    local itemString, texture, count = CreateItemHash(bagID, slotID, itemLink)
    local itemID = tonumber(itemLink:match("item:(%d+)"))
    
    if not itemID or not itemString or not texture then return nil end
    
    -- Find ALL matching auctions for this itemID
    local matches = {}
    for hash, data in pairs(GDKPT.RaidLeader.Core.AuctionedItems or {}) do
        if data.itemID == itemID then
            -- Check if properties match this specific instance
            if hash:find(itemString) and hash:find(tostring(texture)) then
                table.insert(matches, {hash = hash, data = data})
            end
        end
    end
    
    if #matches == 0 then return nil end
    
    -- If multiple matches (unlikely but possible), prefer exact stack count match
    if #matches == 1 then
        return matches[1].data
    end
    
    -- Multiple matches - try to find best match by stack count
    local _, bagCount = GetContainerItemInfo(bagID, slotID)
    for _, match in ipairs(matches) do
        if match.data.stackCount == bagCount then
            return match.data
        end
    end
    
    -- No perfect match, return most recent
    table.sort(matches, function(a, b) return a.data.timestamp > b.data.timestamp end)
    return matches[1].data
end

-- NEW: For tooltips NOT from bags (shift-click, trade window, etc)
local function FindAuctionByItemID(itemID)
    if not itemID or not GDKPT.RaidLeader.Core.AuctionedItems then return nil end
    
    -- Collect all auctions for this itemID
    local auctions = {}
    for hash, data in pairs(GDKPT.RaidLeader.Core.AuctionedItems) do
        if data.itemID == itemID and data.hasEnded then
            table.insert(auctions, data)
        end
    end
    
    if #auctions == 0 then return nil end
    
    -- Return most recent auction
    table.sort(auctions, function(a, b) return a.timestamp > b.timestamp end)
    return auctions[1]
end

local function OnTooltipSetItem(tooltip)
    if not tooltip or not tooltip.GetItem then return end
    
    local _, itemLink = tooltip:GetItem()
    if not itemLink then return end
    
    local itemID = tonumber(itemLink:match("item:(%d+)"))
    if not itemID then return end
    
    local auctionData = nil
    
    -- Try to determine source of tooltip
    local owner = tooltip:GetOwner()
    local bagID, slotID = nil, nil
    
    -- Check if tooltip is from a bag item
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
    
    -- Get auction data based on source
    if bagID and slotID then
        -- Specific bag item - find exact match
        auctionData = FindMatchingAuction(bagID, slotID, itemLink)
    else
        -- Generic tooltip (trade window, shift-click, etc) - find any match
        auctionData = FindAuctionByItemID(itemID)
    end
    
    -- Display auction info if found
    if auctionData then
        tooltip:AddLine(" ")
        tooltip:AddLine("|cff00ff00 This item has been auctioned|r", 1, 1, 1)
        
        if auctionData.auctionId then
            tooltip:AddLine("|cffaaaaaa  Auction ID: " .. auctionData.auctionId .. "|r", 0.7, 0.7, 0.7)
        end
        
        if auctionData.winner then
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
        elseif not auctionData.hasEnded then
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
    
    -- Group by itemID to show duplicates
    local byItemID = {}
    for hash, data in pairs(GDKPT.RaidLeader.Core.AuctionedItems) do
        local id = data.itemID
        if not byItemID[id] then
            byItemID[id] = {}
        end
        table.insert(byItemID[id], {hash = hash, data = data})
    end
    
    for itemID, instances in pairs(byItemID) do
        local itemName = GetItemInfo(itemID) or "Unknown"
        print(string.format("  Item: %s (ID: %d) - %d instance(s)", itemName, itemID, #instances))
        
        for i, instance in ipairs(instances) do
            print(string.format("    [%d] Auction #%d, Winner: %s, Bid: %dg", 
                i, 
                instance.data.auctionId or 0, 
                instance.data.winner or "?", 
                instance.data.winningBid or 0))
            print(string.format("        Hash: %s", instance.hash))
        end
        count = count + #instances
    end
    
    if count == 0 then
        print("|cff00ff00[GDKPT Debug]|r No items currently tracked")
    else
        print(string.format("|cff00ff00[GDKPT Debug]|r Total: %d item instances tracked", count))
    end
end

-- Command to manually check if current mouseover item was auctioned
SLASH_GDKPTCHECKITEM1 = "/gdkptcheckitem"
SlashCmdList["GDKPTCHECKITEM"] = function()
    -- Helper function from AuctionStart.lua
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
    
    local bagID, slotID = GDKPT.RaidLeader.Utils.GetMouseoverBagSlot()
    if not bagID or not slotID then
        print("|cffff0000Hover over an item in your bags first.|r")
        return
    end
    
    local itemLink = GetContainerItemLink(bagID, slotID)
    if not itemLink then
        print("|cffff0000No item in that slot.|r")
        return
    end
    
    local auctionData = FindMatchingAuction(bagID, slotID, itemLink)
    if auctionData then
        print("|cff00ff00This item WAS auctioned:|r")
        print(string.format("  Auction #%d", auctionData.auctionId or 0))
        print(string.format("  Winner: %s", auctionData.winner or "?"))
        print(string.format("  Winning Bid: %dg", auctionData.winningBid or 0))
    else
        print("|cffff0000This item was NOT auctioned.|r")
    end
end




