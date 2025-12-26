
-------------------------------------------------------------------
-- Function to expand the tooltip of auctioned items in inventory
-- with info on auction state, winner, winningBid
-------------------------------------------------------------------

local function ExpandAuctionedItemTooltip(tooltip)
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
        -- Find the specific item in the AuctionedItems table by comparing hashes
        auctionData = GDKPT.RaidLeader.Utils.FindMatchingAuction(bagID, slotID, itemLink)
    end
    
    -- Display auction info if found
    if auctionData then
        tooltip:AddLine(" ")
        tooltip:AddLine("|cff00ff00 This item has been auctioned|r", 1, 1, 1)
        
        -- Display Auction ID
        if auctionData.auctionId then
            tooltip:AddLine("|cffaaaaaa  Auction ID: " .. auctionData.auctionId .. "|r", 0.7, 0.7, 0.7)
        end
        
        -- Display Auction Winner
        if auctionData.winner then
            if auctionData.winner == "Bulk" then
                tooltip:AddLine("|cffffcc00  No winner - Added to Bulk|r", 1, 0.8, 0)
            else
                local winnerText = "|cff00ccff  Winner: " .. auctionData.winner .. "|r"
                tooltip:AddLine(winnerText, 0, 0.8, 1)
                
                -- Display Winning Bid
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


-------------------------------------------------------------------
-- Function to expand the tooltip of items in bulk auction list
-------------------------------------------------------------------

local function ExpandBulkListItemTooltip(tooltip)
    if not tooltip or not tooltip.GetItem then return end
    
    local _, itemLink = tooltip:GetItem()
    if not itemLink then return end
    
    local itemID = tonumber(itemLink:match("item:(%d+)"))
    if not itemID then return end
    
    -- Check if item is in bulk list
    local inBulkList = false
    local bulkStackCount = 0
    
    for _, bulkItem in ipairs(GDKPT.RaidLeader.Core.BulkAuctionList) do
        if bulkItem.itemID == itemID and bulkItem.itemLink == itemLink then
            inBulkList = true
            bulkStackCount = bulkItem.stackCount
            break
        end
    end
    
    if inBulkList then
        tooltip:AddLine(" ")
        tooltip:AddLine("|cffffaa00 In Bulk Auction List|r", 1, 1, 1)
        tooltip:AddLine(string.format("|cffaaaaaa  Stack: x%d|r", bulkStackCount), 0.7, 0.7, 0.7)
        tooltip:Show()
    end
end





-------------------------------------------------------------------
-- Hook Tooltips of auctioned items
-------------------------------------------------------------------

-- Hook GameTooltip
GameTooltip:HookScript("OnTooltipSetItem", ExpandAuctionedItemTooltip)

-- Also hook ItemRefTooltip for shift-click links
if ItemRefTooltip then
    ItemRefTooltip:HookScript("OnTooltipSetItem", ExpandAuctionedItemTooltip)
end


GameTooltip:HookScript("OnTooltipSetItem", ExpandBulkListItemTooltip)
if ItemRefTooltip then
    ItemRefTooltip:HookScript("OnTooltipSetItem", ExpandBulkListItemTooltip)
end




























