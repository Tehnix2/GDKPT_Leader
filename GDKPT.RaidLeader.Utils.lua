GDKPT.RaidLeader.Utils = {}

-------------------------------------------------------------------
-- Is message sender in my raid group
-------------------------------------------------------------------


function GDKPT.RaidLeader.Utils.IsSenderInMyRaid(sender)
    if IsInRaid() then
        for i = 1, GetNumRaidMembers() do
            local name = GetRaidRosterInfo(i)
            if name and name == sender then
                return true
            end
        end
        return false
    end
end


-- Helper function to trim whitespace from a string
function GDKPT.RaidLeader.Utils.trim(s)
    return s:match("^%s*(.-)%s*$") or s
end



-------------------------------------------------------------------
-- Function checks if player is masterlooter 
-------------------------------------------------------------------

function GDKPT.RaidLeader.Utils.IsMasterLooter()
    for raidID = 1, GetNumRaidMembers() do
        local name, _, _, _, _, _, _, _, _, _, isML = GetRaidRosterInfo(raidID)
        if name == UnitName("player") then
            return isML
        end
    end
    return false
end




-------------------------------------------------------------------
-- Function for returning the name of the raid leader
-------------------------------------------------------------------

function GDKPT.RaidLeader.Utils.GetRaidLeaderName()
    if not IsInRaid() then
        return nil 
    end

    for i = 1, GetNumRaidMembers() do
        local name, rank = GetRaidRosterInfo(i)
        if rank == 2 then
            return name
        end
    end

    return nil 
end


-------------------------------------------------------------------
-- Function to get the count of this item in inventory, needed when
-- syncing auctions cause we cannot provide bag/slot info on resync
-------------------------------------------------------------------


function GDKPT.RaidLeader.Utils.GetInventoryStackCount(itemLink)
    if not itemLink then
        return 0
    end

    local itemID = tonumber(itemLink:match("item:(%d+)"))
    if not itemID then return 0 end

    local totalCount = 0
    for bag = 0, 4 do
        local slots = GetContainerNumSlots(bag)
        for slot = 1, slots do
            local _, count = GetContainerItemInfo(bag, slot)
            local link = GetContainerItemLink(bag, slot)
            if link then
                local id = tonumber(link:match("item:(%d+)"))
                if id == itemID then
                    totalCount = totalCount + count
                end
            end
        end
    end

    return totalCount
end

-------------------------------------------------------------------
-- Function to get bag and slot from mouseover
-------------------------------------------------------------------

function GDKPT.RaidLeader.Utils.GetMouseoverBagSlot()
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





-------------------------------------------------------------------
-- Function to Create a unique hash for a specific item instance
-- based on bagID, slotID, itemLink, timestamp, texture, count
-------------------------------------------------------------------


-- Uses item properties that make it unique even among duplicates
function GDKPT.RaidLeader.Utils.CreateItemHash(bagID, slotID, itemLink)
    local texture, count, _ = GetContainerItemInfo(bagID, slotID)
    
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



-------------------------------------------------------------------
-- Function to get all finished auctions
-------------------------------------------------------------------


function GDKPT.RaidLeader.Utils.GetFinishedAuctions()
    local finishedAuctions = {}
    for id, auction in pairs(GDKPT.RaidLeader.Core.ActiveAuctions) do
        if not auction.hasEnded and time() >= auction.endTime then  --this is called before an auction ends, so auction.hasEnded is still false
            table.insert(finishedAuctions, id)
        end
    end
    return finishedAuctions
end


-------------------------------------------------------------------
-- Function to get all items won by a player
-------------------------------------------------------------------

-- Used by manual adjustments

function GDKPT.RaidLeader.Utils.GetPlayerWonItems(playerName)
    local wonItems = GDKPT.RaidLeader.Core.PlayerWonItems[playerName]
    if not wonItems or #wonItems == 0 then
        return nil
    end
    
    local items = {}
    for _, item in ipairs(wonItems) do
        table.insert(items, {
            auctionId = item.auctionId,
            itemLink = item.itemLink or ("Item #" .. tostring(item.itemID)),
            price = item.price or item.bid or 0,
            itemID = item.itemID,
        })
    end
    
    return items
end




-------------------------------------------------------------------
-- Format gold amount into "Xg Ys Zc" string for chat messages
-------------------------------------------------------------------


function GDKPT.RaidLeader.Utils.FormatGoldAmountForChatMessage(amount)
    local gold = math.floor(amount)
    local silver = math.floor((amount - gold) * 100)
    local copper = math.floor(((amount - gold) * 10000) - (silver * 100))

    if silver == 0 and copper == 0 then
        return string.format("%dg", gold)
    elseif copper == 0 then
        return string.format("%dg %ds", gold, silver)
    else
        return string.format("%dg %ds %dc", gold, silver, copper)
    end
end





-------------------------------------------------------------------
-- Function to find won item by its hash
-- Could be used by AutoPlaceItemsInTrade but its currently unused?
-------------------------------------------------------------------


local function FindWonItemByHash(wonItems, itemHash)
    if not wonItems or not itemHash then return nil end
    
    for _, item in ipairs(wonItems) do
        if item.itemHash == itemHash then
            return item
        end
    end
    return nil
end



-------------------------------------------------------------------
-- Check if item is soulbound/untradeable by bagID and slotID
-------------------------------------------------------------------
local scanTooltip = CreateFrame("GameTooltip", "GDKPTScanTooltip", nil, "GameTooltipTemplate")
scanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

local function IsItemTradeable(bagID, slotID)
    scanTooltip:ClearLines()
    scanTooltip:SetBagItem(bagID, slotID)
    
    -- Check tooltip lines for soulbound text
    for i = 1, scanTooltip:NumLines() do
        local line = _G["GDKPTScanTooltipTextLeft" .. i]
        if line then
            local text = line:GetText()
            if text and (text:find("Soulbound") or text:find("Binds when picked up") or text:find("Quest Item")) then
                return false
            end
        end
    end
    
    return true
end




-------------------------------------------------------------------
-- Function to auto-place won items into trade window when trading 
-- with a partner
-------------------------------------------------------------------



function GDKPT.RaidLeader.Utils.AutoPlaceItemsInTrade(partner)
    local wonItems = GDKPT.RaidLeader.Core.PlayerWonItems[partner]
    if not wonItems then
        return 0
    end

    local maxSlots = 6
    local itemsToPlace = {}

    -- Collect up to 6 TRADEABLE items to place
    for i = 1, #wonItems do
        if #itemsToPlace >= maxSlots then break end

        local wonItem = wonItems[i]
        if not wonItem.itemID or not wonItem.stackCount then
        else
            wonItem.remainingQuantity = wonItem.remainingQuantity or wonItem.stackCount 
            
            if not wonItem.fullyTraded and not wonItem.manuallyAdjusted and wonItem.remainingQuantity > 0 then
                local itemID = wonItem.itemID
                local foundTradeable = false
                
                -- Try to find by hash first if available
                if wonItem.itemHash then
                    for bagID = 0, 4 do
                        for slotID = 1, GetContainerNumSlots(bagID) do
                            if foundTradeable then break end
                            
                            local itemLink = GetContainerItemLink(bagID, slotID)
                            if itemLink then
                                local bagItemID = tonumber(itemLink:match("item:(%d+)"))
                                if bagItemID == itemID then
                                    -- Check if this matches the specific hash
                                    local texture, count = GetContainerItemInfo(bagID, slotID)
                                    local itemString = itemLink:match("item:([%-?%d:]+)")
                                    
                                    -- Check itemString match AND quantity match
                                    if wonItem.itemHash:find(itemString) and 
                                       wonItem.itemHash:find(tostring(texture)) and
                                       count >= wonItem.remainingQuantity and  -- Must have at least the remaining quantity
                                       IsItemTradeable(bagID, slotID) then
                        
                                        local _, stackSize = GetContainerItemInfo(bagID, slotID)
                                        stackSize = math.min(stackSize or 1, wonItem.remainingQuantity) -- Take only what's needed

                                        table.insert(itemsToPlace, {
                                            wonItem = wonItem,
                                            stackSize = stackSize,
                                            itemID = itemID,
                                            itemLink = itemLink,
                                            bagID = bagID,
                                            slotID = slotID
                                        })
                                        foundTradeable = true
                                        break
                                    end
                                end
                            end
                        end
                        if foundTradeable then break end
                    end
                end
                
                -- Fallback: Find by itemID only
                if not foundTradeable then
                    for bagID = 0, 4 do
                        for slotID = 1, GetContainerNumSlots(bagID) do
                            if foundTradeable then break end
                            
                            local itemLink = GetContainerItemLink(bagID, slotID)
                            if itemLink and tonumber(itemLink:match("item:(%d+)")) == itemID then
                                if IsItemTradeable(bagID, slotID) then
                                    local _, stackSize = GetContainerItemInfo(bagID, slotID)
                                    stackSize = stackSize or 1

                                    table.insert(itemsToPlace, {
                                        wonItem = wonItem,
                                        stackSize = stackSize,
                                        itemID = itemID,
                                        itemLink = itemLink,
                                        bagID = bagID,
                                        slotID = slotID
                                    })
                                    foundTradeable = true
                                    break
                                end
                            end
                        end
                        if foundTradeable then break end
                    end
                end
            end
        end
    end

    GDKPT.RaidLeader.ItemTrading.CurrentTrade.itemsOffered = {}

    if #itemsToPlace == 0 then
        return 0
    end

    local PLACEMENT_DELAY = 0.4
    
    local function PlaceNextItem(index)
        if index > #itemsToPlace then
            return
        end

        local itemData = itemsToPlace[index]
        local tradeSlot = index

        PickupContainerItem(itemData.bagID, itemData.slotID)
        ClickTradeButton(tradeSlot)

        table.insert(GDKPT.RaidLeader.ItemTrading.CurrentTrade.itemsOffered, {
            wonItem = itemData.wonItem,
            stackSize = itemData.stackSize,
            itemID = itemData.itemID,
            itemLink = itemData.itemLink,
            placementOrder = tradeSlot,
            itemHash = itemData.wonItem.itemHash  -- Track hash
        })

        if index < #itemsToPlace then
            C_Timer.After(PLACEMENT_DELAY, function()
                PlaceNextItem(index + 1)
            end)
        end
    end

    PlaceNextItem(1)
    return #itemsToPlace
end
