GDKPT.RaidLeader.Trading = {}

-- Track current trade session
GDKPT.RaidLeader.Trading.CurrentTrade = {
    partner = nil,
    partnerBalance = 0,
    goldOffered = 0,
    goldGiven = 0,
    itemsOffered = {},
    isActive = false,
    isPotSplitPhase = false
}

-- Track current trade session in pot split phase
GDKPT.RaidLeader.Trading.CurrentPotSplitTrade = {
    partner = nil,
    partnerBalance = 0,
    goldGiven = 0,
    isActive = false
}

-- Track which players have had ANY bugged trade (not auto-attempted)
GDKPT.RaidLeader.Trading.ManualModeRequired = {}

-- Track inventory highlights
GDKPT.RaidLeader.Trading.InventoryHighlights = {}

-- Debug toggle
GDKPT.RaidLeader.Trading.DebugMode = true

local function DebugPrint(msg)
    if GDKPT.RaidLeader.Trading.DebugMode then
        print("|cff88ff88[GDKPT DEBUG]|r " .. msg)
    end
end

-------------------------------------------------------------------
-- INVENTORY HIGHLIGHTING SYSTEM
-------------------------------------------------------------------

-- Create highlight texture for a bag slot
local function CreateHighlightTexture(button)
    if not button then return nil end
    
    -- Remove any existing GDKPT highlight
    if button.GDKPTHighlight then
        button.GDKPTHighlight:Hide()
        button.GDKPTHighlight = nil
    end
    
    local highlight = button:CreateTexture(nil, "OVERLAY")
    highlight:SetAllPoints(button)
    highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    highlight:SetBlendMode("ADD")
    highlight:SetVertexColor(0, 1, 0, 0.8)  -- Bright green
    highlight:Show()
    
    button.GDKPTHighlight = highlight
    
    return highlight
end

-- Highlight specific bag slots containing won items for a player
local function HighlightWonItemsInBags(playerName)
    -- Clear previous highlights
    GDKPT.RaidLeader.Trading.ClearInventoryHighlights()
    
    local wonItems = GDKPT.RaidLeader.Core.PlayerWonItems[playerName]
    if not wonItems or #wonItems == 0 then
        return
    end
    
    -- Build list of item IDs to highlight
    local itemIDsToHighlight = {}
    for i, wonItem in ipairs(wonItems) do
        if not wonItem.fullyTraded and not wonItem.manuallyAdjusted then
            wonItem.remainingQuantity = wonItem.remainingQuantity or wonItem.stackCount
            if wonItem.remainingQuantity > 0 then
                itemIDsToHighlight[wonItem.itemID] = true
            end
        end
    end
    
    -- Scan bags and highlight matching items
    local highlightCount = 0
    for bagID = 0, 4 do
        local numSlots = GetContainerNumSlots(bagID)
        for slotID = 1, numSlots do
            local itemLink = GetContainerItemLink(bagID, slotID)
            if itemLink then
                local itemID = tonumber(itemLink:match("item:(%d+)"))
                if itemID and itemIDsToHighlight[itemID] then
                    -- Calculate the correct button name
                    -- Bag 0 = ContainerFrame1, Bag 1 = ContainerFrame5, Bag 2 = ContainerFrame4, etc.
                    local frameID
                    if bagID == 0 then
                        frameID = 1  -- Backpack
                    else
                        frameID = 6 - bagID  -- Bag 1->5, Bag 2->4, Bag 3->3, Bag 4->2
                    end
                    
                    -- Slot numbering is reversed (slot 1 is at bottom)
                    local buttonNum = numSlots - slotID + 1
                    
                    local buttonName = string.format("ContainerFrame%dItem%d", frameID, buttonNum)
                    local button = _G[buttonName]
                   
                    
                    if button then
                        local highlight = CreateHighlightTexture(button)
                        if highlight then
                            highlightCount = highlightCount + 1
                            table.insert(GDKPT.RaidLeader.Trading.InventoryHighlights, {
                                button = button,
                                texture = highlight,
                                bagID = bagID,
                                slotID = slotID,
                                itemID = itemID
                            })
                        end
                    end
                end
            end
        end
    end
end

-- Clear all inventory highlights
function GDKPT.RaidLeader.Trading.ClearInventoryHighlights()
    for _, data in ipairs(GDKPT.RaidLeader.Trading.InventoryHighlights) do
        if data.button and data.button.GDKPTHighlight then
            data.button.GDKPTHighlight:Hide()
            data.button.GDKPTHighlight = nil
        end
    end
    wipe(GDKPT.RaidLeader.Trading.InventoryHighlights)
end

-------------------------------------------------------------------
-- Check if item is soulbound/untradeable
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
-- Auto-place items in trade window with delays
-------------------------------------------------------------------
local function AutoPlaceItemsInTrade(partner)
    
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
                
                -- Find the item in bags
                for bagID = 0, 4 do
                    local numSlots = GetContainerNumSlots(bagID)
                    for slotID = 1, numSlots do
                        if wonItem.remainingQuantity <= 0 then break end
                        if foundTradeable then break end

                        local itemLink = GetContainerItemLink(bagID, slotID)
                        if itemLink and tonumber(itemLink:match("item:(%d+)")) == itemID then
                            -- Check if tradeable
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

    GDKPT.RaidLeader.Trading.CurrentTrade.itemsOffered = {}

    if #itemsToPlace == 0 then
        return 0
    end

    local PLACEMENT_DELAY = 0.4
    
    local function PlaceNextItem(index)
        if index > #itemsToPlace then
            return
        end

        local itemData = itemsToPlace[index]
        local tradeSlot = index  -- Trade slots are 1-6, matching our array index

        PickupContainerItem(itemData.bagID, itemData.slotID)
        ClickTradeButton(tradeSlot)

        table.insert(GDKPT.RaidLeader.Trading.CurrentTrade.itemsOffered, {
            wonItem = itemData.wonItem,
            stackSize = itemData.stackSize,
            itemID = itemData.itemID,
            itemLink = itemData.itemLink,
            placementOrder = tradeSlot
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

-------------------------------------------------------------------
-- Check if player has more TRADEABLE items to trade
-------------------------------------------------------------------
local function PlayerHasMoreTradeableItems(playerName)
    local wonItems = GDKPT.RaidLeader.Core.PlayerWonItems[playerName]
    if not wonItems then return false end
    
    for _, wonItem in ipairs(wonItems) do
        wonItem.remainingQuantity = wonItem.remainingQuantity or wonItem.stackCount
        if not wonItem.fullyTraded and not wonItem.manuallyAdjusted and wonItem.remainingQuantity > 0 then
            -- Check if this item exists and is tradeable
            local itemID = wonItem.itemID
            for bagID = 0, 4 do
                for slotID = 1, GetContainerNumSlots(bagID) do
                    local itemLink = GetContainerItemLink(bagID, slotID)
                    if itemLink and tonumber(itemLink:match("item:(%d+)")) == itemID then
                        if IsItemTradeable(bagID, slotID) then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

-------------------------------------------------------------------
-- Determine current trade phase (debt collection or pot split)
-------------------------------------------------------------------
local function DetermineTradePhase()
    if GDKPT.RaidLeader.PotSplit.StartPotSplitPhase then
        return "POT_SPLIT"
    end
    return "DEBT_COLLECTION"
end

-- Track last trade close time to detect bugs
local lastTradeCloseTime = 0
local lastTradeOpenTime = 0

-------------------------------------------------------------------
-- Trade Opened in debt collection phase
-------------------------------------------------------------------
function GDKPT.RaidLeader.Trading.OnTradeOpenedInDebtCollectionPhase()
    local partnerName = UnitName("NPC")
    if not partnerName then return end

    lastTradeOpenTime = GetTime()
    
    local balance = GDKPT.RaidLeader.Core.PlayerBalances[partnerName] or 0

    print(string.format("|cff00ff00[GDKPT Leader]|r Trading with %s. Balance: %dg", 
        partnerName, balance)) 

    -- Initialize trade session
    GDKPT.RaidLeader.Trading.CurrentTrade = {
        partner = partnerName,
        partnerBalance = balance,
        goldOffered = 0,
        goldGiven = 0,
        itemsOffered = {},
        isActive = true,
    }

    -- Check if we should use manual mode
    local requiresManual = GDKPT.RaidLeader.Trading.ManualModeRequired[partnerName]
    
    if requiresManual then
        -- Manual trading mode - highlight items
        
        C_Timer.After(0.1, function()
            HighlightWonItemsInBags(partnerName)
        end)
    else
        -- Auto-trade mode
        
        C_Timer.After(0.5, function()
            if GDKPT.RaidLeader.Trading.CurrentTrade.isActive and 
                GDKPT.RaidLeader.Trading.CurrentTrade.partner == partnerName then
                AutoPlaceItemsInTrade(partnerName)
            end
        end)
    end
    
    -- Show trade helper frame
    if GDKPT.RaidLeader.TradeHelper and GDKPT.RaidLeader.TradeHelper.Show then
        C_Timer.After(0.3, function()
            GDKPT.RaidLeader.TradeHelper.Show()
        end)
    end
end

-------------------------------------------------------------------
-- Trade Opened in pot split phase
-------------------------------------------------------------------
function GDKPT.RaidLeader.Trading.OnTradeOpenedInPotSplitPhase()
    local partnerName = UnitName("NPC")
    if not partnerName then return end

    local balance = GDKPT.RaidLeader.Core.PlayerBalances[partnerName] or 0

    -- Initialize trade session
    GDKPT.RaidLeader.Trading.CurrentPotSplitTrade = {
        partner = partnerName,
        partnerBalance = balance,
        goldGiven = 0,
        isActive = true
    }

    if balance <= 0 then
        SendChatMessage(string.format("[GDKPT]: You have already received your cut, %s !",partnerName), "RAID")
        if HandOutCutButton then HandOutCutButton:Hide() end
        CloseTrade()
        return
    end

    C_Timer.After(0.2, function()
        local latestBalance = GDKPT.RaidLeader.Core.PlayerBalances[partnerName] or 0
        if latestBalance > 0 then
            GDKPT.RaidLeader.PotSplit.ShowAutoFillButtonOnValidTrade(partnerName, latestBalance)
        else
            if HandOutCutButton then HandOutCutButton:Hide() end
            CloseTrade()
            SendChatMessage(string.format("[GDKPT]: Please don't double trade for your cut %s! (Or Addon is bugged)",partnerName), "RAID")
        end
    end)
end

-------------------------------------------------------------------
-- Gold values changed during a trade in Debt Collection Phase 
-------------------------------------------------------------------
function GDKPT.RaidLeader.Trading.OnMoneyChangedInDebtCollectionPhase() 
    if not GDKPT.RaidLeader.Trading.CurrentTrade.isActive then return end
    local goldFromTarget = GetTargetTradeMoney() / 10000
    GDKPT.RaidLeader.Trading.CurrentTrade.goldOffered = goldFromTarget
end

-------------------------------------------------------------------
-- Gold values changed during a trade in Pot Split Phase
-------------------------------------------------------------------
function GDKPT.RaidLeader.Trading.OnMoneyChangedInPotSplitPhase() 
    if not GDKPT.RaidLeader.Trading.CurrentPotSplitTrade.isActive then return end
    local goldFromSelf = GetPlayerTradeMoney() / 10000
    GDKPT.RaidLeader.Trading.CurrentPotSplitTrade.goldGiven = goldFromSelf
end

-------------------------------------------------------------------
-- On trade accept update
-------------------------------------------------------------------
function GDKPT.RaidLeader.Trading.OnTradeAcceptUpdateInDebtCollectionPhase(playerAccepted, targetAccepted)
    if not GDKPT.RaidLeader.Trading.CurrentTrade.isActive then return end
    
    if playerAccepted == 1 and targetAccepted == 1 then
        local goldFromTarget = GetTargetTradeMoney() / 10000
        GDKPT.RaidLeader.Trading.CurrentTrade.goldOffered = goldFromTarget
    end
end

function GDKPT.RaidLeader.Trading.OnTradeAcceptUpdateInPotSplitPhase(playerAccepted, targetAccepted)
    if not GDKPT.RaidLeader.Trading.CurrentPotSplitTrade.isActive then return end
    
    if playerAccepted == 1 and targetAccepted == 1 then
        local goldFromSelf = GetPlayerTradeMoney() / 10000
        GDKPT.RaidLeader.Trading.CurrentPotSplitTrade.goldGiven = goldFromSelf
    end
end

-------------------------------------------------------------------
-- on trade window closed (NOT COMPLETED)
-------------------------------------------------------------------
function GDKPT.RaidLeader.Trading.OnTradeClosedInDebtCollectionPhase()
    lastTradeCloseTime = GetTime()
    local timeSinceOpen = lastTradeCloseTime - lastTradeOpenTime
    
    -- If trade closed very quickly (< 1 second) after opening, it's likely a bug
    if timeSinceOpen < 1.0 and GDKPT.RaidLeader.Trading.CurrentTrade.isActive then
        local partner = GDKPT.RaidLeader.Trading.CurrentTrade.partner
        if partner then
            GDKPT.RaidLeader.Trading.ManualModeRequired[partner] = true
        end
    end
    
    -- Clear highlights when trade closes
    GDKPT.RaidLeader.Trading.ClearInventoryHighlights()
    
    C_Timer.After(1, function()
        GDKPT.RaidLeader.Trading.CurrentTrade = {
            partner = nil,
            partnerBalance = 0,
            goldOffered = 0,
            goldGiven = 0,
            itemsOffered = {},
            isActive = false,
        }   
    end)
end

function GDKPT.RaidLeader.Trading.OnTradeClosedInPotSplitPhase()
    C_Timer.After(1, function()
        GDKPT.RaidLeader.Trading.CurrentPotSplitTrade = {
            partner = nil,
            partnerBalance = 0,
            goldGiven = 0,
            isActive = false,
        }
    end)
end

-------------------------------------------------------------------
-- Check if all current winners have paid up
-------------------------------------------------------------------
local function AllCurrentWinnersPaidUp()
    local leaderName = UnitName("player")
    
    -- Check if there are any pending items
    for playerName, items in pairs(GDKPT.RaidLeader.Core.PlayerWonItems) do
        if playerName ~= leaderName and #items > 0 then
            return false -- Still items pending
        end
    end
    
    -- Check if there are any negative balances
    for player, balance in pairs(GDKPT.RaidLeader.Core.PlayerBalances) do
        if player ~= leaderName and balance < 0 then
            return false -- Still debts unpaid
        end
    end
    
    return true
end

-------------------------------------------------------------------
-- Update the "Ready for Pot Split" button state
-------------------------------------------------------------------
function GDKPT.RaidLeader.Trading.UpdateReadyForPotSplitButton()
    if GDKPT.RaidLeader.PotSplit.ReadyForPotSplitButton then
        local canBeReady = AllCurrentWinnersPaidUp() and GDKPT.RaidLeader.Core.GDKP_Pot > 0
        
        if canBeReady then
            GDKPT.RaidLeader.PotSplit.ReadyForPotSplitButton:Enable()
            GDKPT.RaidLeader.PotSplit.ReadyForPotSplitButton:SetText("Ready for Pot Split")
            GDKPT.RaidLeader.PotSplit.ReadyForPotSplitButton:Show()
        else
            GDKPT.RaidLeader.PotSplit.ReadyForPotSplitButton:Disable()
            GDKPT.RaidLeader.PotSplit.ReadyForPotSplitButton:SetText("Ready for Pot Split")
            GDKPT.RaidLeader.PotSplit.ReadyForPotSplitButton:Hide()
        end
    end
end

-------------------------------------------------------------------
-- On trade completion in debt collection phase
-------------------------------------------------------------------
function GDKPT.RaidLeader.Trading.OnTradeCompletedInDebtCollectionPhase()
    if not GDKPT.RaidLeader.Trading.CurrentTrade.isActive then return end
    
    local partner = GDKPT.RaidLeader.Trading.CurrentTrade.partner
    local goldReceived = GDKPT.RaidLeader.Trading.CurrentTrade.goldOffered
    local balance = GDKPT.RaidLeader.Trading.CurrentTrade.partnerBalance

    if not partner or not goldReceived or not balance then return end

    -- Update balance
    if goldReceived > 0 then
        local newBalance = balance + goldReceived
        GDKPT.RaidLeader.Core.PlayerBalances[partner] = newBalance
        DebugPrint(string.format("Updated balance: %d + %d = %d", balance, goldReceived, newBalance))
    end

    -- Process traded items with quantity tracking
    if GDKPT.RaidLeader.Trading.CurrentTrade.itemsOffered and 
       #GDKPT.RaidLeader.Trading.CurrentTrade.itemsOffered > 0 then
        
        for _, placedItem in ipairs(GDKPT.RaidLeader.Trading.CurrentTrade.itemsOffered) do
            local wonItem = placedItem.wonItem
            local quantityTraded = placedItem.stackSize
            
            -- Initialize remainingQuantity if not set
            if not wonItem.remainingQuantity then
                wonItem.remainingQuantity = wonItem.stackCount
            end
            
            -- Subtract what was traded
            wonItem.remainingQuantity = wonItem.remainingQuantity - quantityTraded
           
            
            -- Mark as fully traded if all quantity delivered
            if wonItem.remainingQuantity <= 0 then
                wonItem.fullyTraded = true
            end
        end
        
        -- Remove fully traded items from list
        local wonItems = GDKPT.RaidLeader.Core.PlayerWonItems[partner]
        if wonItems then
            for i = #wonItems, 1, -1 do
                if wonItems[i].fullyTraded then
                    table.remove(wonItems, i)
                end
            end
            
            -- Remove player if no items left
            if #wonItems == 0 then
                GDKPT.RaidLeader.Core.PlayerWonItems[partner] = nil
            end
        end
    end

    -- Check if we need to open another trade window for more items
    local hasMore = PlayerHasMoreTradeableItems(partner)
    
    if hasMore and not GDKPT.RaidLeader.Trading.ManualModeRequired[partner] then
        C_Timer.After(2.0, function()
            InitiateTrade(partner)
        end)
    elseif hasMore and GDKPT.RaidLeader.Trading.ManualModeRequired[partner] then
    end

    -- Clean up players with zero debt
    if GDKPT.RaidLeader.Core.PlayerBalances[partner] and 
       GDKPT.RaidLeader.Core.PlayerBalances[partner] == 0 then
        GDKPT.RaidLeader.Core.PlayerBalances[partner] = nil
    end

    -- Update UI
    if GDKPT.RaidLeader.UI.UpdateRosterDisplay then
        GDKPT.RaidLeader.UI.UpdateRosterDisplay()
    end
    
    -- Update the Ready for Pot Split button state
    GDKPT.RaidLeader.Trading.UpdateReadyForPotSplitButton()
    
    -- Update trade helper frame
    if GDKPT.RaidLeader.TradeHelper and GDKPT.RaidLeader.TradeHelper.Update then
        GDKPT.RaidLeader.TradeHelper.Update()
    end
end

-------------------------------------------------------------------
-- On trade completion in pot split phase
-------------------------------------------------------------------
function GDKPT.RaidLeader.Trading.OnTradeCompletedInPotSplitPhase()
    if not GDKPT.RaidLeader.Trading.CurrentPotSplitTrade.isActive then return end

    local partner = GDKPT.RaidLeader.Trading.CurrentPotSplitTrade.partner
    local goldGiven = GDKPT.RaidLeader.Trading.CurrentPotSplitTrade.goldGiven
    local balance = GDKPT.RaidLeader.Trading.CurrentPotSplitTrade.partnerBalance

    if not partner or not goldGiven or not balance then return end

    if goldGiven > 0 then
        local newBalance = balance - goldGiven
        GDKPT.RaidLeader.Core.PlayerBalances[partner] = newBalance
    end

    -- Clean up players with zero balance
    if GDKPT.RaidLeader.Core.PlayerBalances[partner] and 
       GDKPT.RaidLeader.Core.PlayerBalances[partner] == 0 then
        GDKPT.RaidLeader.Core.PlayerBalances[partner] = nil
    end

    -- Update UI
    if GDKPT.RaidLeader.UI.UpdateRosterDisplay then
        GDKPT.RaidLeader.UI.UpdateRosterDisplay()
    end

    SendChatMessage(string.format("[GDKPT]: %s has received their cut (%d gold) from this raid!", partner, balance), "RAID")
end

-------------------------------------------------------------------
-- Master Looter Reminder System
-------------------------------------------------------------------
local lastMasterLooterWarning = 0
local MASTER_LOOTER_WARNING_COOLDOWN = 600

local function CheckAndWarnMasterLooter()
    local now = GetTime()
    if now - lastMasterLooterWarning < MASTER_LOOTER_WARNING_COOLDOWN then
        return
    end
    
    if IsInRaid() then
        local lootMethod = select(1, GetLootMethod())
        local isLootMaster = (lootMethod == "master")
        
        if not isLootMaster and (IsRaidLeader() or IsRaidOfficer()) then
            lastMasterLooterWarning = now
            print("|cffff0000========================================|r")
            print("|cffff0000[GDKPT WARNING]|r YOU ARE NOT MASTER LOOTER!")
            print("|cffff0000[GDKPT WARNING]|r Auto-trading will NOT work!")
            print("|cffff0000[GDKPT WARNING]|r Change loot to Master Looter now!")
            print("|cffff0000========================================|r")
            PlaySound("RaidWarning")
        end
    end
end

function GDKPT.RaidLeader.Trading.CheckMasterLooterStatus()
    CheckAndWarnMasterLooter()
end

-------------------------------------------------------------------
-- COMMANDS
-------------------------------------------------------------------

-- Toggle debug mode
SLASH_GDKPTDEBUG1 = "/gdkptdebug"
SlashCmdList["GDKPTDEBUG"] = function(msg)
    if msg == "on" then
        GDKPT.RaidLeader.Trading.DebugMode = true
        print("|cff00ff00[GDKPT]|r Debug mode ENABLED")
    elseif msg == "off" then
        GDKPT.RaidLeader.Trading.DebugMode = false
        print("|cff00ff00[GDKPT]|r Debug mode DISABLED")
    else
        GDKPT.RaidLeader.Trading.DebugMode = not GDKPT.RaidLeader.Trading.DebugMode
        print("|cff00ff00[GDKPT]|r Debug mode " .. (GDKPT.RaidLeader.Trading.DebugMode and "ENABLED" or "DISABLED"))
    end
end

-- Reset manual mode flag for a player
SLASH_GDKPTRESETMANUAL1 = "/gdkptresetmanual"
SlashCmdList["GDKPTRESETMANUAL"] = function(playerName)
    if playerName and playerName ~= "" then
        GDKPT.RaidLeader.Trading.ManualModeRequired[playerName] = nil
        print(string.format("|cff00ff00[GDKPT Leader]|r Reset manual mode flag for %s - auto-trade will be attempted", playerName))
    else
        wipe(GDKPT.RaidLeader.Trading.ManualModeRequired)
        print("|cff00ff00[GDKPT Leader]|r Reset manual mode flags for all players")
    end
end

-- Check items pending for a player
SLASH_GDKPTCHECKPLAYER1 = "/gdkptcheck"
SlashCmdList["GDKPTCHECKPLAYER"] = function(playerName)
    if not playerName or playerName == "" then
        print("|cffff8800[GDKPT Debug]|r Usage: /gdkptcheck PlayerName")
        return
    end
    
    local wonItems = GDKPT.RaidLeader.Core.PlayerWonItems[playerName]
    if not wonItems or #wonItems == 0 then
        print("|cffff8800[GDKPT Debug]|r No pending items for " .. playerName)
        return
    end
    
    print("|cff00ff00[GDKPT Debug]|r Pending items for " .. playerName .. ":")
    for i, item in ipairs(wonItems) do
        local stackCount = item.stackCount or 0
        local remaining = item.remainingQuantity or stackCount
        local itemID = item.itemID or "nil"
        print(string.format("  %d. %s - ItemID: %s, Quantity: %d, Remaining: %d, FullyTraded: %s", 
            i, 
            item.itemLink or "Unknown", 
            tostring(itemID),
            stackCount, 
            remaining, 
            tostring(item.fullyTraded or false)))
    end
    
    -- Check manual mode status
    if GDKPT.RaidLeader.Trading.ManualModeRequired[playerName] then
        print("|cffff8800  Manual mode REQUIRED - auto-trade disabled|r")
    else
        print("|cff00ff00  Auto-trade mode ACTIVE|r")
    end
end

-- List all players with pending items
SLASH_GDKPTLISTPENDING1 = "/gdkptlistpending"
SlashCmdList["GDKPTLISTPENDING"] = function()
    local hasPending = false
    print("|cff00ff00[GDKPT Debug]|r Players with pending items:")
    for playerName, items in pairs(GDKPT.RaidLeader.Core.PlayerWonItems) do
        if #items > 0 then
            hasPending = true
            local modeStatus = GDKPT.RaidLeader.Trading.ManualModeRequired[playerName] and "[Manual Mode]" or "[Auto Mode]"
            print(string.format("  %s: %d item(s) pending %s", playerName, #items, modeStatus))
        end
    end
    if not hasPending then
        print("|cffff8800[GDKPT Debug]|r No players have pending items")
    end
end

-- Force split command
SLASH_GDKPTFORCESPLIT1 = "/gdkptforcesplit"
SlashCmdList["GDKPTFORCESPLIT"] = function(msg)
    if not IsRaidLeader() and not IsRaidOfficer() then
        print("|cffff0000[GDKPT Leader]|r Only the Raid Leader or Officer can force split the pot.")
        return
    end
    
    StaticPopupDialogs["GDKPT_FORCE_SPLIT_CONFIRM"] = {
        text = "FORCE SPLIT THE POT?\n\nThis bypasses all safety checks.\nUse this if there's a bug preventing normal pot split.\n\nAre you sure?",
        button1 = "Yes, Force Split",
        button2 = "Cancel",
        OnAccept = function()
            GDKPT.RaidLeader.PotSplit.StartPotSplitPhase = true
            GDKPT.RaidLeader.Core.PlayerWonItems = {}
            
            for player, balance in pairs(GDKPT.RaidLeader.Core.PlayerBalances) do
                if balance < 0 then
                    GDKPT.RaidLeader.Core.PlayerBalances[player] = 0
                end
            end
            
            GDKPT.RaidLeader.Core.PlayerBalances[UnitName("player")] = 0
            
            GDKPT.RaidLeader.PotSplit.DistributePot()
            print("|cffff8800[GDKPT Leader]|r POT FORCE SPLIT - All checks bypassed!")
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("GDKPT_FORCE_SPLIT_CONFIRM")
end

-- Manual highlight test
SLASH_GDKPTHIGHLIGHT1 = "/gdkpthighlight"
SlashCmdList["GDKPTHIGHLIGHT"] = function(playerName)
    if not playerName or playerName == "" then
        print("|cffff8800[GDKPT]|r Usage: /gdkpthighlight PlayerName")
        return
    end
    HighlightWonItemsInBags(playerName)
end

-- Clear highlights manually
SLASH_GDKPTCLEARHIGHLIGHT1 = "/gdkptclearhighlight"
SlashCmdList["GDKPTCLEARHIGHLIGHT"] = function()
    GDKPT.RaidLeader.Trading.ClearInventoryHighlights()
    print("|cff00ff00[GDKPT]|r Cleared all highlights")
end

-------------------------------------------------------------------
-- Event Frame
-------------------------------------------------------------------
local tradeEventFrame = CreateFrame("Frame")
tradeEventFrame:RegisterEvent("TRADE_SHOW")
tradeEventFrame:RegisterEvent("TRADE_CLOSED")
tradeEventFrame:RegisterEvent("TRADE_MONEY_CHANGED")
tradeEventFrame:RegisterEvent("TRADE_PLAYER_ITEM_CHANGED")
tradeEventFrame:RegisterEvent("TRADE_ACCEPT_UPDATE")
tradeEventFrame:RegisterEvent("UI_INFO_MESSAGE")
tradeEventFrame:RegisterEvent("PARTY_LOOT_METHOD_CHANGED")

-------------------------------------------------------------------
-- Event Handler
-------------------------------------------------------------------
tradeEventFrame:SetScript("OnEvent", function(self, event, ...)
    local isInRaid = IsInRaid()
    local lootMethod = select(1, GetLootMethod())
    local isLootMaster = (lootMethod == "master")

    if event == "PARTY_LOOT_METHOD_CHANGED" then
        CheckAndWarnMasterLooter()
        return
    end
    
    if event == "TRADE_SHOW" then
        CheckAndWarnMasterLooter()
    end

    if isInRaid and isLootMaster then
        local phase = DetermineTradePhase()
        local isPotSplitPhase = (phase == "POT_SPLIT")

        if event == "TRADE_SHOW" then
            if not isPotSplitPhase then
                GDKPT.RaidLeader.Trading.OnTradeOpenedInDebtCollectionPhase()
            else
                GDKPT.RaidLeader.Trading.OnTradeOpenedInPotSplitPhase()
            end

        elseif event == "TRADE_MONEY_CHANGED" then
            if not isPotSplitPhase then
                GDKPT.RaidLeader.Trading.OnMoneyChangedInDebtCollectionPhase()            
            else
                GDKPT.RaidLeader.Trading.OnMoneyChangedInPotSplitPhase()
            end

        elseif event == "TRADE_ACCEPT_UPDATE" then
            local playerAccepted, targetAccepted = ...
            if not isPotSplitPhase then
                GDKPT.RaidLeader.Trading.OnTradeAcceptUpdateInDebtCollectionPhase(playerAccepted, targetAccepted)
            else
                GDKPT.RaidLeader.Trading.OnTradeAcceptUpdateInPotSplitPhase(playerAccepted, targetAccepted)
            end
      
        elseif event == "TRADE_CLOSED" then
            if not isPotSplitPhase then
                GDKPT.RaidLeader.Trading.OnTradeClosedInDebtCollectionPhase()    
            else
                GDKPT.RaidLeader.Trading.OnTradeClosedInPotSplitPhase()
            end

        elseif event == "UI_INFO_MESSAGE" then
            local msg = select(1, ...)
            if msg == ERR_TRADE_COMPLETE then
                if not isPotSplitPhase then
                    GDKPT.RaidLeader.Trading.OnTradeCompletedInDebtCollectionPhase()
                else
                    GDKPT.RaidLeader.Trading.OnTradeCompletedInPotSplitPhase()
                end
            end
        end
    end
end)


--[[



GDKPT.RaidLeader.Trading = {}

-- Track current trade session
GDKPT.RaidLeader.Trading.CurrentTrade = {
    partner = nil,
    partnerBalance = 0,
    goldOffered = 0,
    goldGiven = 0,
    itemsOffered = {},
    isActive = false,
    isPotSplitPhase = false
}

-- Track current trade session in pot split phase
GDKPT.RaidLeader.Trading.CurrentPotSplitTrade = {
    partner = nil,
    partnerBalance = 0,
    goldGiven = 0,
    isActive = false
}



-- Track if we're in a bugged item detection cycle
GDKPT.RaidLeader.Trading.DetectionCycle = {
    isActive = false,
    partner = nil,
    attemptCount = 0,
    maxAttempts = 3
}

-------------------------------------------------------------------
-- Determine current trade phase (debt collection or pot split)
-------------------------------------------------------------------
local function DetermineTradePhase()
    if GDKPT.RaidLeader.PotSplit.StartPotSplitPhase then
        return "POT_SPLIT"
    end
    return "DEBT_COLLECTION"
end







-------------------------------------------------------------------
-- Auto-place items in trade window with delays (handles bugged items)
-------------------------------------------------------------------



local function AutoPlaceItemsInTrade(partner)
    local wonItems = GDKPT.RaidLeader.Core.PlayerWonItems[partner]
    if not wonItems then return 0 end

    local maxSlots = 6
    local skippedBuggedItems = {}
    local itemsToPlace = {}

    for i = 1, #wonItems do
        if #itemsToPlace >= maxSlots then break end

        local wonItem = wonItems[i]
        if not wonItem.itemID or not wonItem.stackCount then
            print("|cffff0000[GDKPT ERROR]|r Missing itemID or stackCount.")
        else
            wonItem.remainingQuantity = wonItem.remainingQuantity or wonItem.stackCount
            if not wonItem.fullyTraded and not wonItem.manuallyAdjusted and wonItem.remainingQuantity > 0 then
                local itemID = wonItem.itemID
                
                if GDKPT.RaidLeader.Core.BuggedItems[itemID] then
                    table.insert(skippedBuggedItems, { itemLink = wonItem.itemLink, wonItem = wonItem, itemID = itemID })
                else
                    for bagID = 0, 4 do
                        for slotID = 1, GetContainerNumSlots(bagID) do
                            if wonItem.remainingQuantity <= 0 then break end

                            local itemLink = GetContainerItemLink(bagID, slotID)
                            if itemLink and tonumber(itemLink:match("item:(%d+)")) == itemID then
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
                                break
                            end
                        end
                        if #itemsToPlace >= maxSlots then break end
                    end
                end
            end
        end
    end

    GDKPT.RaidLeader.Trading.CurrentTrade.skippedItems = skippedBuggedItems
    GDKPT.RaidLeader.Trading.CurrentTrade.itemsOffered = {}

    GDKPT.RaidLeader.Trading.DetectionCycle.isActive = true
    GDKPT.RaidLeader.Trading.DetectionCycle.partner = partner

    if #itemsToPlace == 0 then
        print("|cffff8800[GDKPT Leader]|r No items to place for " .. partner)
        return 0
    end

    
    local PLACEMENT_DELAY = 0.5
    
    local function PlaceNextItem(index)
        if index > #itemsToPlace then
            print("|cff00ff00[GDKPT Leader]|r Finished placing items")
            return
        end

        local itemData = itemsToPlace[index]
        local placementTime = GetTime()

        PickupContainerItem(itemData.bagID, itemData.slotID)
        ClickTradeButton(index)

        table.insert(GDKPT.RaidLeader.Trading.CurrentTrade.itemsOffered, {
            wonItem = itemData.wonItem,
            stackSize = itemData.stackSize,
            itemID = itemData.itemID,
            itemLink = itemData.itemLink,
            placementOrder = index,
            placedAt = placementTime
        })

        print(string.format("|cff00ff00[GDKPT]|r [%d/%d] Placed %s at %.3f", 
            index, #itemsToPlace, itemData.itemLink, placementTime))

        if index < #itemsToPlace then
            C_Timer.After(PLACEMENT_DELAY, function()
                PlaceNextItem(index + 1)
            end)
        end
    end

    PlaceNextItem(1)
    return #itemsToPlace
end




-------------------------------------------------------------------
-- Detect if trade closed unexpectedly (bugged item detection)
-------------------------------------------------------------------
local lastTradeOpenTime = 0
local TRADE_CLOSE_DETECTION_WINDOW = 0.5
local tradeWasAccepted = false


local function DetectBuggedItemClose()
    local tradeCloseTime = GetTime()
    local timeSinceOpen = tradeCloseTime - lastTradeOpenTime
    local currentTrade = GDKPT.RaidLeader.Trading.CurrentTrade
    
    if tradeWasAccepted then
        print("|cff00ff00[GDKPT]|r Trade completed successfully - not marking as bugged")
        tradeWasAccepted = false
        GDKPT.RaidLeader.Trading.DetectionCycle.isActive = false
        GDKPT.RaidLeader.Trading.DetectionCycle.attemptCount = 0
        return
    end
    
    local itemsOffered = currentTrade.itemsOffered
    
	if timeSinceOpen < TRADE_CLOSE_DETECTION_WINDOW and itemsOffered and #itemsOffered > 0 then
		
		print(string.format("|cffff8800[GDKPT DEBUG]|r Trade closed at %.3f (%.3fs after open)", 
			tradeCloseTime, timeSinceOpen))
		print(string.format("|cffff8800[GDKPT DEBUG]|r %d items were placed before closure", #itemsOffered))
		
		-- Find the LAST item that was placed (the one that caused instant closure)
		local buggedItem = itemsOffered[#itemsOffered]  -- Simply get the last item in the array
		
		if not buggedItem or not buggedItem.itemID then
			print("|cffff8800[GDKPT]|r Trade closed quickly but no items to check")
			return
		end
		
		-- Check if already marked to avoid duplicates
		if GDKPT.RaidLeader.Core.BuggedItems[buggedItem.itemID] then
			print("|cffff8800[GDKPT]|r Last placed item already marked as bugged, skipping duplicate detection")
			return
		end
		
		local timeBetweenPlacementAndClose = tradeCloseTime - buggedItem.placedAt
		
		print("|cffff0000========================================|r")
		print("|cffff0000[GDKPT BUGGED ITEM DETECTED]|r")
		print(string.format("|cffff0000Item:|r %s", buggedItem.itemLink))
		print(string.format("|cffff0000Placement Order:|r %d out of %d (LAST item placed)", buggedItem.placementOrder, #itemsOffered))
		print(string.format("|cffff0000Time between placement and close:|r %.3fs", timeBetweenPlacementAndClose))
		print("|cffff0000This item caused the trade window to close!|r")
		print("|cffff0000It will be skipped in future trades.|r")
		print("|cffff0000========================================|r")
		
		GDKPT.RaidLeader.Core.BuggedItems[buggedItem.itemID] = {
			itemID = buggedItem.itemID,
			itemLink = buggedItem.itemLink,
			detectedAt = time(),
			playerAttempted = currentTrade.partner,
			stackSize = buggedItem.stackSize,
			placementOrder = buggedItem.placementOrder,
			placedAt = buggedItem.placedAt,
			closeDelay = timeBetweenPlacementAndClose
		}
		
		PlaySound("RaidWarning")

        GDKPT.RaidLeader.Trading.DetectionCycle.attemptCount = 
            (GDKPT.RaidLeader.Trading.DetectionCycle.attemptCount or 0) + 1

        if GDKPT.RaidLeader.Trading.DetectionCycle.attemptCount < 
           GDKPT.RaidLeader.Trading.DetectionCycle.maxAttempts then
            
            C_Timer.After(1.5, function()
                if GDKPT.RaidLeader.Trading.DetectionCycle.partner then
                    print(string.format("|cffff8800[GDKPT]|r Retrying trade with %s (attempt %d/%d)...", 
                        GDKPT.RaidLeader.Trading.DetectionCycle.partner,
                        GDKPT.RaidLeader.Trading.DetectionCycle.attemptCount + 1,
                        GDKPT.RaidLeader.Trading.DetectionCycle.maxAttempts))
                    
                    InitiateTrade(GDKPT.RaidLeader.Trading.DetectionCycle.partner)
                end
            end)
        else
            print("|cffff0000[GDKPT]|r Max retry attempts reached. Use manual adjustment for remaining items.|r")
            GDKPT.RaidLeader.Trading.DetectionCycle.isActive = false
            GDKPT.RaidLeader.Trading.DetectionCycle.attemptCount = 0
        end
    else
        if timeSinceOpen >= TRADE_CLOSE_DETECTION_WINDOW then
            print(string.format("|cff00ff00[GDKPT]|r Trade lasted %.2f seconds - normal closure", timeSinceOpen))
        end
        GDKPT.RaidLeader.Trading.DetectionCycle.isActive = false
        GDKPT.RaidLeader.Trading.DetectionCycle.attemptCount = 0
    end
end





-------------------------------------------------------------------
-- Trade Opened in debt collection phase
-------------------------------------------------------------------
function GDKPT.RaidLeader.Trading.OnTradeOpenedInDebtCollectionPhase()
    local partnerName = UnitName("NPC")
    if not partnerName then return end

    local balance = GDKPT.RaidLeader.Core.PlayerBalances[partnerName] or 0

    print(string.format("|cff00ff00[GDKPT Leader]|r Trading with %s. Balance: %dg", 
        partnerName, balance))

    -- Track when trade opened for bugged item detection
    lastTradeOpenTime = GetTime()

    -- Initialize trade session
    GDKPT.RaidLeader.Trading.CurrentTrade = {
        partner = partnerName,
        partnerBalance = balance,
        goldOffered = 0,
        goldGiven = 0,
        itemsOffered = {},
        isActive = true,
    }

    C_Timer.After(0.3, function()
        if GDKPT.RaidLeader.Trading.CurrentTrade.isActive and 
            GDKPT.RaidLeader.Trading.CurrentTrade.partner == partnerName then
            --AutoPlaceItemsInTrade(partnerName)
        end
    end)
end

-------------------------------------------------------------------
-- Trade Opened in pot split phase
-------------------------------------------------------------------
function GDKPT.RaidLeader.Trading.OnTradeOpenedInPotSplitPhase()
    local partnerName = UnitName("NPC")
    if not partnerName then return end

    local balance = GDKPT.RaidLeader.Core.PlayerBalances[partnerName] or 0

    -- Initialize trade session
    GDKPT.RaidLeader.Trading.CurrentPotSplitTrade = {
        partner = partnerName,
        partnerBalance = balance,
        goldGiven = 0,
        isActive = true
    }

    if balance <= 0 then
        SendChatMessage(string.format("[GDKPT]: You have already received your cut, %s !",partnerName), "RAID")
        HandOutCutButton:Hide()
        CloseTrade()
        return
    end

    C_Timer.After(0.2, function()
        local latestBalance = GDKPT.RaidLeader.Core.PlayerBalances[partnerName] or 0
        if latestBalance > 0 then
            GDKPT.RaidLeader.PotSplit.ShowAutoFillButtonOnValidTrade(partnerName, latestBalance)
        else
            HandOutCutButton:Hide()
            CloseTrade()
            SendChatMessage(string.format("[GDKPT]: Please don't double trade for your cut %s! (Or Addon is bugged)",partnerName), "RAID")
        end
    end)
end

-------------------------------------------------------------------
-- Gold values changed during a trade in Debt Collection Phase 
-------------------------------------------------------------------
function GDKPT.RaidLeader.Trading.OnMoneyChangedInDebtCollectionPhase() 
    if not GDKPT.RaidLeader.Trading.CurrentTrade.isActive then return end
    local goldFromTarget = GetTargetTradeMoney() / 10000
    GDKPT.RaidLeader.Trading.CurrentTrade.goldOffered = goldFromTarget
end

-------------------------------------------------------------------
-- Gold values changed during a trade in Pot Split Phase
-------------------------------------------------------------------
function GDKPT.RaidLeader.Trading.OnMoneyChangedInPotSplitPhase() 
    if not GDKPT.RaidLeader.Trading.CurrentPotSplitTrade.isActive then return end
    local goldFromSelf = GetPlayerTradeMoney() / 10000
    GDKPT.RaidLeader.Trading.CurrentPotSplitTrade.goldGiven = goldFromSelf
end

-------------------------------------------------------------------
-- On trade accept update
-------------------------------------------------------------------
function GDKPT.RaidLeader.Trading.OnTradeAcceptUpdateInDebtCollectionPhase(playerAccepted, targetAccepted)
    if not GDKPT.RaidLeader.Trading.CurrentTrade.isActive then return end
    
    if playerAccepted == 1 and targetAccepted == 1 then
        local goldFromTarget = GetTargetTradeMoney() / 10000
        GDKPT.RaidLeader.Trading.CurrentTrade.goldOffered = goldFromTarget
    end
end

function GDKPT.RaidLeader.Trading.OnTradeAcceptUpdateInPotSplitPhase(playerAccepted, targetAccepted)
    if not GDKPT.RaidLeader.Trading.CurrentPotSplitTrade.isActive then return end
    
    if playerAccepted == 1 and targetAccepted == 1 then
        local goldFromSelf = GetPlayerTradeMoney() / 10000
        GDKPT.RaidLeader.Trading.CurrentPotSplitTrade.goldGiven = goldFromSelf
    end
end


-------------------------------------------------------------------
-- on trade window closed (NOT COMPLETED)
-------------------------------------------------------------------
function GDKPT.RaidLeader.Trading.OnTradeClosedInDebtCollectionPhase()
    if GDKPT.RaidLeader.Trading.CurrentTrade.isActive then
        local partner = GDKPT.RaidLeader.Trading.CurrentTrade.partner

        -- Detect if this was a bugged item closure
        DetectBuggedItemClose()
    end
    
    -- Reset flag after detection completes
    C_Timer.After(0.1, function()
        tradeWasAccepted = false
    end)
    
    C_Timer.After(1, function()
        GDKPT.RaidLeader.Trading.CurrentTrade = {
            partner = nil,
            partnerBalance = 0,
            goldOffered = 0,
            goldGiven = 0,
            itemsOffered = {},
            isActive = false,
        }   
    end)
end



function GDKPT.RaidLeader.Trading.OnTradeClosedInPotSplitPhase()
    if GDKPT.RaidLeader.Trading.CurrentTrade.isActive then
        local partner = GDKPT.RaidLeader.Trading.CurrentPotSplitTrade.partner
    end
    
    C_Timer.After(1, function()
        GDKPT.RaidLeader.Trading.CurrentPotSplitTrade = {
            partner = nil,
            partnerBalance = 0,
            goldGiven = 0,
            isActive = false,
        }
    end)
end

-------------------------------------------------------------------
-- Check if all current winners have paid up
-------------------------------------------------------------------
local function AllCurrentWinnersPaidUp()
    local leaderName = UnitName("player")
    
    -- Check if there are any pending items
    for playerName, items in pairs(GDKPT.RaidLeader.Core.PlayerWonItems) do
        if playerName ~= leaderName and #items > 0 then
            return false -- Still items pending
        end
    end
    
    -- Check if there are any negative balances
    for player, balance in pairs(GDKPT.RaidLeader.Core.PlayerBalances) do
        if player ~= leaderName and balance < 0 then
            return false -- Still debts unpaid
        end
    end
    
    return true
end

-------------------------------------------------------------------
-- Update the "Ready for Pot Split" button state
-------------------------------------------------------------------
function GDKPT.RaidLeader.Trading.UpdateReadyForPotSplitButton()
    if GDKPT.RaidLeader.PotSplit.ReadyForPotSplitButton then
        local canBeReady = AllCurrentWinnersPaidUp() and GDKPT.RaidLeader.Core.GDKP_Pot > 0
        
        if canBeReady then
            GDKPT.RaidLeader.PotSplit.ReadyForPotSplitButton:Enable()
            GDKPT.RaidLeader.PotSplit.ReadyForPotSplitButton:SetText("Ready for Pot Split")
            GDKPT.RaidLeader.PotSplit.ReadyForPotSplitButton:Show()
        else
            GDKPT.RaidLeader.PotSplit.ReadyForPotSplitButton:Disable()
            GDKPT.RaidLeader.PotSplit.ReadyForPotSplitButton:SetText("Ready for Pot Split")
            GDKPT.RaidLeader.PotSplit.ReadyForPotSplitButton:Hide()
        end
    end
end






-------------------------------------------------------------------
-- On trade completion in debt collection phase
-------------------------------------------------------------------
function GDKPT.RaidLeader.Trading.OnTradeCompletedInDebtCollectionPhase()
    if not GDKPT.RaidLeader.Trading.CurrentTrade.isActive then return end

    -- Mark that trade was successfully completed (not bugged)
    tradeWasAccepted = true
    
    local partner = GDKPT.RaidLeader.Trading.CurrentTrade.partner
    local goldReceived = GDKPT.RaidLeader.Trading.CurrentTrade.goldOffered
    local balance = GDKPT.RaidLeader.Trading.CurrentTrade.partnerBalance

    if not partner or not goldReceived or not balance then return end

    print("|cff00ff00[GDKPT Leader]|r Trade completed successfully with " .. partner)

    -- Update balance
    if goldReceived > 0 then
        local newBalance = balance + goldReceived
        GDKPT.RaidLeader.Core.PlayerBalances[partner] = newBalance
    end

    -- Process traded items with quantity tracking
    if GDKPT.RaidLeader.Trading.CurrentTrade.itemsOffered and 
       #GDKPT.RaidLeader.Trading.CurrentTrade.itemsOffered > 0 then
        
        for _, placedItem in ipairs(GDKPT.RaidLeader.Trading.CurrentTrade.itemsOffered) do
            local wonItem = placedItem.wonItem
            local quantityTraded = placedItem.stackSize
            
            -- Initialize remainingQuantity if not set
            if not wonItem.remainingQuantity then
                wonItem.remainingQuantity = wonItem.stackCount
            end
            
            -- Subtract what was traded
            wonItem.remainingQuantity = wonItem.remainingQuantity - quantityTraded
            
            -- Mark as fully traded if all quantity delivered
            if wonItem.remainingQuantity <= 0 then
                wonItem.fullyTraded = true
                print(string.format("|cff00ff00[GDKPT Leader]|r %s (x%d) fully traded to %s", 
                    wonItem.itemLink or "Item", wonItem.stackCount, partner))
            else
                print(string.format("|cff00ff00[GDKPT Leader]|r %s: %d/%d traded to %s (more trades needed)", 
                    wonItem.itemLink or "Item", 
                    wonItem.stackCount - wonItem.remainingQuantity,
                    wonItem.stackCount,
                    partner))
            end
        end
        
        -- Remove fully traded items from list
        local wonItems = GDKPT.RaidLeader.Core.PlayerWonItems[partner]
        if wonItems then
            for i = #wonItems, 1, -1 do
                if wonItems[i].fullyTraded then
                    table.remove(wonItems, i)
                end
            end
            
            -- Remove player if no items left
            if #wonItems == 0 then
                GDKPT.RaidLeader.Core.PlayerWonItems[partner] = nil
                print(string.format("|cff00ff00[GDKPT Leader]|r %s has received all items.", partner))
            end
        end
    end

    -- Clean up players with zero debt
    if GDKPT.RaidLeader.Core.PlayerBalances[partner] and 
       GDKPT.RaidLeader.Core.PlayerBalances[partner] == 0 then
        GDKPT.RaidLeader.Core.PlayerBalances[partner] = nil
    end

    -- Update UI
    if GDKPT.RaidLeader.UI.UpdateRosterDisplay then
        GDKPT.RaidLeader.UI.UpdateRosterDisplay()
    end
    
    -- Update the Ready for Pot Split button state
    GDKPT.RaidLeader.Trading.UpdateReadyForPotSplitButton()
    
    -- Reset detection cycle on successful trade
    GDKPT.RaidLeader.Trading.DetectionCycle.isActive = false
    GDKPT.RaidLeader.Trading.DetectionCycle.attemptCount = 0
end



-------------------------------------------------------------------
-- On trade completion in pot split phase
-------------------------------------------------------------------
function GDKPT.RaidLeader.Trading.OnTradeCompletedInPotSplitPhase()
    if not GDKPT.RaidLeader.Trading.CurrentPotSplitTrade.isActive then return end

    local partner = GDKPT.RaidLeader.Trading.CurrentPotSplitTrade.partner
    local goldGiven = GDKPT.RaidLeader.Trading.CurrentPotSplitTrade.goldGiven
    local balance = GDKPT.RaidLeader.Trading.CurrentPotSplitTrade.partnerBalance

    if not partner or not goldGiven or not balance then return end

    if goldGiven > 0 then
        local newBalance = balance - goldGiven
        GDKPT.RaidLeader.Core.PlayerBalances[partner] = newBalance
    end

    -- Clean up players with zero balance
    if GDKPT.RaidLeader.Core.PlayerBalances[partner] and 
       GDKPT.RaidLeader.Core.PlayerBalances[partner] == 0 then
        GDKPT.RaidLeader.Core.PlayerBalances[partner] = nil
    end

    -- Update UI
    if GDKPT.RaidLeader.UI.UpdateRosterDisplay then
        GDKPT.RaidLeader.UI.UpdateRosterDisplay()
    end

    SendChatMessage(string.format("[GDKPT]: %s has received their cut (%d gold) from this raid!", partner, balance), "RAID")
end

-------------------------------------------------------------------
-- Master Looter Reminder System
-------------------------------------------------------------------
local lastMasterLooterWarning = 0
local MASTER_LOOTER_WARNING_COOLDOWN = 600

local function CheckAndWarnMasterLooter()
    local now = GetTime()
    if now - lastMasterLooterWarning < MASTER_LOOTER_WARNING_COOLDOWN then
        return
    end
    
    if IsInRaid() then
        local lootMethod = select(1, GetLootMethod())
        local isLootMaster = (lootMethod == "master")
        
        if not isLootMaster and (IsRaidLeader() or IsRaidOfficer()) then
            lastMasterLooterWarning = now
            print("|cffff0000========================================|r")
            print("|cffff0000[GDKPT WARNING]|r YOU ARE NOT MASTER LOOTER!")
            print("|cffff0000[GDKPT WARNING]|r Auto-trading will NOT work!")
            print("|cffff0000[GDKPT WARNING]|r Change loot to Master Looter now!")
            print("|cffff0000========================================|r")
            PlaySound("RaidWarning")
        end
    end
end

function GDKPT.RaidLeader.Trading.CheckMasterLooterStatus()
    CheckAndWarnMasterLooter()
end

-------------------------------------------------------------------
-- FORCE SPLIT COMMAND - Bypass all checks
-------------------------------------------------------------------
SLASH_GDKPTFORCESPLIT1 = "/gdkptforcesplit"
SlashCmdList["GDKPTFORCESPLIT"] = function(msg)
    if not IsRaidLeader() and not IsRaidOfficer() then
        print("|cffff0000[GDKPT Leader]|r Only the Raid Leader or Officer can force split the pot.")
        return
    end
    
    StaticPopupDialogs["GDKPT_FORCE_SPLIT_CONFIRM"] = {
        text = "FORCE SPLIT THE POT?\n\nThis bypasses all safety checks.\nUse this if there's a bug preventing normal pot split.\n\nAre you sure?",
        button1 = "Yes, Force Split",
        button2 = "Cancel",
        OnAccept = function()
            GDKPT.RaidLeader.PotSplit.StartPotSplitPhase = true
            GDKPT.RaidLeader.Core.PlayerWonItems = {}
            
            for player, balance in pairs(GDKPT.RaidLeader.Core.PlayerBalances) do
                if balance < 0 then
                    GDKPT.RaidLeader.Core.PlayerBalances[player] = 0
                end
            end
            
            -- Clear leader balance
            GDKPT.RaidLeader.Core.PlayerBalances[UnitName("player")] = 0
            
            GDKPT.RaidLeader.PotSplit.DistributePot()
            print("|cffff8800[GDKPT Leader]|r POT FORCE SPLIT - All checks bypassed!")
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("GDKPT_FORCE_SPLIT_CONFIRM")
end

-------------------------------------------------------------------
-- DEBUG COMMAND - Check what items are pending for a player
-------------------------------------------------------------------
SLASH_GDKPTDEBUGITEMS1 = "/gdkptdebug"
SlashCmdList["GDKPTDEBUGITEMS"] = function(playerName)
    if not playerName or playerName == "" then
        print("|cffff8800[GDKPT Debug]|r Usage: /gdkptdebug PlayerName")
        return
    end
    
    local wonItems = GDKPT.RaidLeader.Core.PlayerWonItems[playerName]
    if not wonItems or #wonItems == 0 then
        print("|cffff8800[GDKPT Debug]|r No pending items for " .. playerName)
        return
    end
    
    print("|cff00ff00[GDKPT Debug]|r Pending items for " .. playerName .. ":")
    for i, item in ipairs(wonItems) do
        local stackCount = item.stackCount or 0
        local remaining = item.remainingQuantity or stackCount
        local itemID = item.itemID or "nil"
        print(string.format("  %d. %s - ItemID: %s, Quantity: %d, Remaining: %d, FullyTraded: %s", 
            i, 
            item.itemLink or "Unknown", 
            tostring(itemID),
            stackCount, 
            remaining, 
            tostring(item.fullyTraded or false)))
    end
end

-------------------------------------------------------------------
-- UTILITY COMMAND - List all players with pending items
-------------------------------------------------------------------
SLASH_GDKPTLISTPENDING1 = "/gdkptlistpending"
SlashCmdList["GDKPTLISTPENDING"] = function()
    local hasPending = false
    print("|cff00ff00[GDKPT Debug]|r Players with pending items:")
    for playerName, items in pairs(GDKPT.RaidLeader.Core.PlayerWonItems) do
        if #items > 0 then
            hasPending = true
            print(string.format("  %s: %d item(s) pending", playerName, #items))
        end
    end
    if not hasPending then
        print("|cffff8800[GDKPT Debug]|r No players have pending items")
    end
end

-------------------------------------------------------------------
-- Event Frame
-------------------------------------------------------------------
local tradeEventFrame = CreateFrame("Frame")
tradeEventFrame:RegisterEvent("TRADE_SHOW")
tradeEventFrame:RegisterEvent("TRADE_CLOSED")
tradeEventFrame:RegisterEvent("TRADE_MONEY_CHANGED")
tradeEventFrame:RegisterEvent("TRADE_PLAYER_ITEM_CHANGED")
tradeEventFrame:RegisterEvent("TRADE_ACCEPT_UPDATE")
tradeEventFrame:RegisterEvent("UI_INFO_MESSAGE")
tradeEventFrame:RegisterEvent("PARTY_LOOT_METHOD_CHANGED")

-------------------------------------------------------------------
-- Event Handler
-------------------------------------------------------------------
tradeEventFrame:SetScript("OnEvent", function(self, event, ...)
    local isInRaid = IsInRaid()
    local lootMethod = select(1, GetLootMethod())
    local isLootMaster = (lootMethod == "master")

    if event == "PARTY_LOOT_METHOD_CHANGED" then
        CheckAndWarnMasterLooter()
        return
    end
    
    if event == "TRADE_SHOW" then
        CheckAndWarnMasterLooter()
    end

    if isInRaid and isLootMaster then
        local phase = DetermineTradePhase()
        local isPotSplitPhase = (phase == "POT_SPLIT")

        if event == "TRADE_SHOW" then
            if not isPotSplitPhase then
                GDKPT.RaidLeader.Trading.OnTradeOpenedInDebtCollectionPhase()
            else
                GDKPT.RaidLeader.Trading.OnTradeOpenedInPotSplitPhase()
            end

        elseif event == "TRADE_MONEY_CHANGED" then
            if not isPotSplitPhase then
                GDKPT.RaidLeader.Trading.OnMoneyChangedInDebtCollectionPhase()            
            else
                GDKPT.RaidLeader.Trading.OnMoneyChangedInPotSplitPhase()
            end

        elseif event == "TRADE_ACCEPT_UPDATE" then
            local playerAccepted, targetAccepted = ...
            if not isPotSplitPhase then
                GDKPT.RaidLeader.Trading.OnTradeAcceptUpdateInDebtCollectionPhase(playerAccepted, targetAccepted)
            else
                GDKPT.RaidLeader.Trading.OnTradeAcceptUpdateInPotSplitPhase(playerAccepted, targetAccepted)
            end
      
        elseif event == "TRADE_CLOSED" then
            if not isPotSplitPhase then
                GDKPT.RaidLeader.Trading.OnTradeClosedInDebtCollectionPhase()    
            else
                GDKPT.RaidLeader.Trading.OnTradeClosedInPotSplitPhase()
            end

        elseif event == "UI_INFO_MESSAGE" then
            local msg = select(1, ...)
            if msg == ERR_TRADE_COMPLETE then
                if not isPotSplitPhase then
                    GDKPT.RaidLeader.Trading.OnTradeCompletedInDebtCollectionPhase()
                else
                    GDKPT.RaidLeader.Trading.OnTradeCompletedInPotSplitPhase()
                end
            end
        end
    end
end)



-------------------------------------------------------------------
-- BUGGED ITEM MANAGEMENT COMMANDS
-------------------------------------------------------------------

-- List all known bugged items
SLASH_GDKPTLISTBUGGED1 = "/gdkptlistbugged"
SlashCmdList["GDKPTLISTBUGGED"] = function()
    local count = 0
    print("|cff00ff00[GDKPT Debug]|r Known bugged items:")
    for itemID, data in pairs(GDKPT.RaidLeader.Core.BuggedItems) do
        count = count + 1
        print(string.format("  %d. %s (ID: %d) - Detected: %s", 
            count, 
            data.itemLink or "Unknown", 
            itemID,
            date("%Y-%m-%d %H:%M", data.detectedAt or 0)))
    end
    if count == 0 then
        print("|cff00ff00[GDKPT Debug]|r No bugged items detected yet")
    end
end

-- Clear bugged items list
SLASH_GDKPTCLEARBUGGED1 = "/gdkptclearbugged"
SlashCmdList["GDKPTCLEARBUGGED"] = function()
    wipe(GDKPT.RaidLeader.Core.BuggedItems)
    wipe(GDKPT_RaidLeader_BuggedItems)
    print("|cff00ff00[GDKPT Leader]|r Cleared all bugged items from tracking")
end

-- Manually mark an item as bugged
SLASH_GDKPTMARKBUGGED1 = "/gdkptmarkbugged"
SlashCmdList["GDKPTMARKBUGGED"] = function(msg)
    local itemLink = msg:match("|c%x+|Hitem:.-|h%[.-%]|h|r")
    if not itemLink then
        print("|cffff8800[GDKPT]|r Usage: /gdkptmarkbugged [Shift-click item link]")
        return
    end
    
    local itemID = tonumber(itemLink:match("item:(%d+)"))
    if itemID then
        GDKPT.RaidLeader.Core.BuggedItems[itemID] = {
            itemID = itemID,
            itemLink = itemLink,
            detectedAt = time(),
            manuallyMarked = true
        }
        print(string.format("|cff00ff00[GDKPT Leader]|r Marked %s as bugged (will be skipped in trades)", itemLink))
    end
end

-- Remove specific item from bugged list
SLASH_GDKPTUNMARKBUGGED1 = "/gdkptunmarkbugged"
SlashCmdList["GDKPTUNMARKBUGGED"] = function(msg)
    local itemLink = msg:match("|c%x+|Hitem:.-|h%[.-%]|h|r")
    if not itemLink then
        print("|cffff8800[GDKPT]|r Usage: /gdkptunmarkbugged [Shift-click item link]")
        return
    end
    
    local itemID = tonumber(itemLink:match("item:(%d+)"))
    if itemID and GDKPT.RaidLeader.Core.BuggedItems[itemID] then
        GDKPT.RaidLeader.Core.BuggedItems[itemID] = nil
        print(string.format("|cff00ff00[GDKPT Leader]|r Removed %s from bugged items list", itemLink))
    else
        print("|cffff8800[GDKPT]|r Item not found in bugged list")
    end
end



-------------------------------------------------------------------
-- DEBUG COMMAND - Enhanced to show item details
-------------------------------------------------------------------
SLASH_GDKPTDEBUGITEMS1 = "/gdkptdebug"
SlashCmdList["GDKPTDEBUGITEMS"] = function(playerName)
    if not playerName or playerName == "" then
        print("|cffff8800[GDKPT Debug]|r Usage: /gdkptdebug PlayerName")
        return
    end
    
    local wonItems = GDKPT.RaidLeader.Core.PlayerWonItems[playerName]
    if not wonItems or #wonItems == 0 then
        print("|cffff8800[GDKPT Debug]|r No pending items for " .. playerName)
        return
    end
    
    print("|cff00ff00[GDKPT Debug]|r Pending items for " .. playerName .. ":")
    for i, item in ipairs(wonItems) do
        local stackCount = item.stackCount or 0
        local remaining = item.remainingQuantity or stackCount
        local itemID = item.itemID or "nil"
        local isBugged = GDKPT.RaidLeader.Core.BuggedItems[tonumber(itemID)] ~= nil
        
        print(string.format("  %d. %s", i, item.itemLink or "Unknown"))
        print(string.format("     ItemID: %s %s", tostring(itemID), isBugged and "|cffff0000[BUGGED]|r" or ""))
        print(string.format("     Quantity: %d, Remaining: %d", stackCount, remaining))
        print(string.format("     FullyTraded: %s, ManuallyAdjusted: %s", 
            tostring(item.fullyTraded or false),
            tostring(item.manuallyAdjusted or false)))
        print(string.format("     AuctionID: %s", tostring(item.auctionId or "N/A")))
    end
end



]]