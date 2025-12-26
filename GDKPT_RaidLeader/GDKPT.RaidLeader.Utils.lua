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
-- Get current split count based on raid size
-------------------------------------------------------------------

function GDKPT.RaidLeader.Utils.GetCurrentSplitCount()
    return IsInRaid() and GetNumRaidMembers() or 1
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
-- Function to create two itemHash, one based on time so its 
-- completely unique, and one without the time for lookups
-------------------------------------------------------------------


function GDKPT.RaidLeader.Utils.CreateItemHash(bagID, slotID, itemLink)
    local texture, count, _ = GetContainerItemInfo(bagID, slotID)
    local itemString = itemLink:match("item:([%-?%d:]+)") or ""

    -- This one changes each auction, ensures uniqueness per event
    local auctionHash = string.format("%s_%d_%d_%d_%s_%d",
        itemString, bagID, slotID, time(), tostring(texture), count or 1
    )

    -- This one is reproducible for the same item in bags
    local itemInstanceHash = string.format("%s_%d_%d_%s_%d",
        itemString, bagID, slotID, tostring(texture), count or 1
    )

    return auctionHash, itemInstanceHash
end


-------------------------------------------------------------------
-- Function creates the itemInstanceHash of the current mouseovered
-- item for tooltip creation and then looks up the stored values for
-- this specific item in the AuctionedItems table.
-- Used by TooltipExtension code
-------------------------------------------------------------------

function GDKPT.RaidLeader.Utils.FindMatchingAuction(bagID, slotID, itemLink)
    local _, itemInstanceHash = GDKPT.RaidLeader.Utils.CreateItemHash(bagID, slotID, itemLink)

    for _, auctionData in pairs(GDKPT.RaidLeader.Core.AuctionedItems) do
        if auctionData.itemInstanceHash == itemInstanceHash then
            return auctionData
        end
    end

    return nil
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
    -- Keep track of slots we have already queued to prevent trying to pickup the same item twice
    local usedSlots = {}


    -- Collect up to 6 TRADEABLE items to place
    for i = 1, #wonItems do
        if #itemsToPlace >= maxSlots then break end

        local wonItem = wonItems[i]
        if wonItem.itemID and wonItem.stackCount then
            wonItem.remainingQuantity = wonItem.remainingQuantity or wonItem.stackCount 
            
            if not wonItem.fullyTraded and not wonItem.manuallyAdjusted and wonItem.remainingQuantity > 0 then
                local foundBag, foundSlot = GDKPT.RaidLeader.TradeHelper.FindItemInBagsByHash(wonItem)
                
                if foundBag and foundSlot then
                    -- Verify the item is tradeable
                    local scanTooltip = CreateFrame("GameTooltip", "GDKPTScanTooltip_AutoPlace", nil, "GameTooltipTemplate")
                    scanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
                    scanTooltip:SetBagItem(foundBag, foundSlot)
                    
                    local isTradeable = true
                    for i = 1, scanTooltip:NumLines() do
                        local line = _G["GDKPTScanTooltip_AutoPlaceTextLeft" .. i]
                        if line then
                            local text = line:GetText()
                            if text and (text:find("Soulbound") or text:find("Binds when picked up") or text:find("Quest Item")) then
                                isTradeable = false
                                break
                            end
                        end
                    end
                    scanTooltip:Hide()
                    
                    if isTradeable then
                        local _, stackSize = GetContainerItemInfo(foundBag, foundSlot)
                        stackSize = math.min(stackSize or 1, wonItem.remainingQuantity)

                        table.insert(itemsToPlace, {
                            wonItem = wonItem,
                            stackSize = stackSize,
                            itemID = wonItem.itemID,
                            itemLink = wonItem.itemLink,
                            bagID = foundBag,
                            slotID = foundSlot
                        })
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
            auctionHash = itemData.wonItem.auctionHash,
            itemInstanceHash = itemData.wonItem.itemInstanceHash
        })

        print(string.format(GDKPT.RaidLeader.Core.addonPrintString .. "Placed %s in trade slot %d (Auction #%d)", 
            itemData.itemLink, tradeSlot, itemData.wonItem.auctionId))
        
        if index < #itemsToPlace then
            C_Timer.After(PLACEMENT_DELAY, function()
                PlaceNextItem(index + 1)
            end)
        else
            -- Refresh the helper frame after all items placed
            C_Timer.After(0.1, function()
                if GDKPT.RaidLeader.TradeHelper and GDKPT.RaidLeader.TradeHelper.Update then
                    GDKPT.RaidLeader.TradeHelper.Update()
                end
            end)
        end
    end

    PlaceNextItem(1)
    return #itemsToPlace
end




-------------------------------------------------------------------
-- Find next empty trade slot
-------------------------------------------------------------------

function GDKPT.RaidLeader.Utils.GetNextEmptyTradeSlot()
    for i = 1, 6 do
        local itemLink = GetTradePlayerItemLink(i)
        if not itemLink then
            return i
        end
    end
    return nil -- All slots full
end