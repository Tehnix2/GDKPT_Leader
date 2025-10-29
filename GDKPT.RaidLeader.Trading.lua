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
-- Auto-place items in trade window (handles stacks properly)
-------------------------------------------------------------------
local function AutoPlaceItemsInTrade(partner)
    local wonItems = GDKPT.RaidLeader.Core.PlayerWonItems[partner]
    if not wonItems then 
        print("|cffff0000[GDKPT]|r No won items found for " .. partner)
        return 0 
    end

    print("|cff00ff00[GDKPT]|r Found " .. #wonItems .. " items for " .. partner)

    local itemsPlaced = 0
    local maxSlots = 6
    local placedItems = {}

    -- Process each won item
    for i = 1, #wonItems do
        if itemsPlaced >= maxSlots then break end
        
        local wonItem = wonItems[i]
        
        -- Check if stackCount exists
        if not wonItem.stackCount then
            print("|cffff0000[GDKPT ERROR]|r Item " .. i .. " (" .. (wonItem.itemLink or "Unknown") .. ") has NO stackCount! Skipping.")
            print("|cffff0000[GDKPT ERROR]|r This means the AuctionEnd.lua file wasn't updated properly!")
        else
            -- Initialize remainingQuantity if not set
            if not wonItem.remainingQuantity then
                wonItem.remainingQuantity = wonItem.stackCount
            end
            
            -- Skip if already fully traded
            if not wonItem.fullyTraded and wonItem.remainingQuantity > 0 then
                local itemID = wonItem.itemID
                
                -- Search bags for this item and place stacks until we run out or fill trade window
                for bagID = 0, 4 do
                    if itemsPlaced >= maxSlots then break end
                    
                    for slotID = 1, GetContainerNumSlots(bagID) do
                        if itemsPlaced >= maxSlots then break end
                        if wonItem.remainingQuantity <= 0 then break end
                        
                        local itemLink = GetContainerItemLink(bagID, slotID)
                        if itemLink then
                            local linkItemID = tonumber(itemLink:match("item:(%d+)"))
                            if linkItemID == itemID then
                                local _, stackSize = GetContainerItemInfo(bagID, slotID)
                                stackSize = stackSize or 1
                                
                                -- Place this stack in trade window
                                PickupContainerItem(bagID, slotID)
                                ClickTradeButton(itemsPlaced + 1)
                                
                                -- Track what we placed
                                table.insert(placedItems, {
                                    wonItem = wonItem,
                                    stackSize = stackSize
                                })
                                
                                itemsPlaced = itemsPlaced + 1
                            end
                        end
                    end
                end
            end
        end
    end

    GDKPT.RaidLeader.Trading.CurrentTrade.itemsOffered = placedItems
    print("|cff00ff00[GDKPT]|r Placed " .. itemsPlaced .. " item stacks in trade")
    return itemsPlaced
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
            AutoPlaceItemsInTrade(partnerName)
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
        LeaderAutoFillButton:Hide()
        CloseTrade()
        return
    end

    C_Timer.After(0.2, function()
        local latestBalance = GDKPT.RaidLeader.Core.PlayerBalances[partnerName] or 0
        if latestBalance > 0 then
            GDKPT.RaidLeader.PotSplit.ShowAutoFillButtonOnValidTrade(partnerName, latestBalance)
        else
            LeaderAutoFillButton:Hide()
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
    end
    
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
-- Check if all members have paid up
-------------------------------------------------------------------
local function AllMembersPaidUp()
    local leaderName = UnitName("player")

    for player, balance in pairs(GDKPT.RaidLeader.Core.PlayerBalances) do
        if player ~= leaderName then
            if balance < 0 then
                return false
            end
        end
    end

    GDKPT.RaidLeader.Core.PlayerBalances[leaderName] = 0
    return true
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

    -- Check if ready for pot split
    -- Only proceed if there was actually a pot to collect from (auctions happened)
    if GDKPT.RaidLeader.Core.GDKP_Pot > 0 then
        local allItemsTraded = true
        local leaderName = UnitName("player")

        for playerName, items in pairs(GDKPT.RaidLeader.Core.PlayerWonItems) do
            if playerName ~= leaderName and #items > 0 then
                allItemsTraded = false
                break
            end
        end

        if allItemsTraded and AllMembersPaidUp() then
            print("|cff00ff00[GDKPT Leader]|r ========================================")
            print("|cff00ff00[GDKPT Leader]|r ALL MEMBERS PAID UP!")
            print("|cff00ff00[GDKPT Leader]|r Ready for pot split!")
            print("|cff00ff00[GDKPT Leader]|r ========================================")

            GDKPT.RaidLeader.PotSplit.StartPotSplitPhase = true
            SendChatMessage("[GDKPT]: Everyone has received their items.", "RAID")
            SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, "START_POT_SPLIT_PHASE:0", "RAID")
        end
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
local MASTER_LOOTER_WARNING_COOLDOWN = 600 -- seconds between warnings

local function CheckAndWarnMasterLooter()
    local now = GetTime()
    if now - lastMasterLooterWarning < MASTER_LOOTER_WARNING_COOLDOWN then
        return -- Don't spam warnings
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
            
            -- Play a warning sound
            PlaySound("RaidWarning")
        end
    end
end

-- Check master looter status when loot method changes
tradeEventFrame:RegisterEvent("PARTY_LOOT_METHOD_CHANGED")

-------------------------------------------------------------------
-- Helper function to check master looter in critical situations
-------------------------------------------------------------------
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

-------------------------------------------------------------------
-- Event Handler
-------------------------------------------------------------------
tradeEventFrame:SetScript("OnEvent", function(self, event, ...)
    local isInRaid = IsInRaid()
    local lootMethod = select(1, GetLootMethod())
    local isLootMaster = (lootMethod == "master")

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