






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
    -- If pot has been distributed, we're in pot split phase
    if GDKPT.RaidLeader.PotSplit.StartPotSplitPhase then
        return "POT_SPLIT"
    end
    
    -- Otherwise, we're in debt collection phase
    return "DEBT_COLLECTION"
end





-------------------------------------------------------------------
-- Auto-place items in trade window
-------------------------------------------------------------------
local function AutoPlaceItemsInTrade(partner)
    local wonItems = GDKPT.RaidLeader.Core.PlayerWonItems[partner]
    if not wonItems then return 0 end

    local itemsPlaced = 0
    local maxSlots = 6
    local placedItems = {}

    -- Place items in trade window
    for i = #wonItems, 1, -1 do
        if itemsPlaced >= maxSlots then break end
        
        local wonItem = wonItems[i]
        if not wonItem.traded then
            local itemID = wonItem.itemID
            
            -- Search bags for this item
            for bagID = 0, 4 do
                if itemsPlaced >= maxSlots then break end
                
                for slotID = 1, GetContainerNumSlots(bagID) do
                    local itemLink = GetContainerItemLink(bagID, slotID)
                    if itemLink then
                        local linkItemID = tonumber(itemLink:match("item:(%d+)"))
                        if linkItemID == itemID then
                            -- Place in next available trade slot
                            PickupContainerItem(bagID, slotID)
                            ClickTradeButton(itemsPlaced + 1)
                            
                            table.insert(placedItems, wonItem)
                            itemsPlaced = itemsPlaced + 1
                            
                            --print(string.format("|cff00ff00[GDKPT]|r Placed %s in trade slot %d",
                            --    wonItem.itemLink or itemLink, itemsPlaced))
                            break
                        end
                    end
                end
            end
        end
    end

    GDKPT.RaidLeader.Trading.CurrentTrade.itemsOffered = placedItems
    return itemsPlaced
end




-------------------------------------------------------------------
-- Trade Opened in debt collection phase
-- initialize the CurrentTrade table and auto place won items into trade
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
            local placed = AutoPlaceItemsInTrade(partnerName)
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

    -- double check the balance table again after a small delay, to be absolutely sure this player shall be given a cut
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
-- used to stored gold from target during a trade in as goldOffered in trade table
-------------------------------------------------------------------


function GDKPT.RaidLeader.Trading.OnMoneyChangedInDebtCollectionPhase() 

    if not GDKPT.RaidLeader.Trading.CurrentTrade.isActive then return end

    local goldFromTarget = GetTargetTradeMoney() / 10000  -- receive gold from other player during debt collection

    GDKPT.RaidLeader.Trading.CurrentTrade.goldOffered = goldFromTarget -- store gold in current trade table
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
-- On trade accept update: Store gold from target in goldOffered at the time
-- when both players accept the trade
-------------------------------------------------------------------


function GDKPT.RaidLeader.Trading.OnTradeAcceptUpdateInDebtCollectionPhase(playerAccepted, targetAccepted)
    
    if not GDKPT.RaidLeader.Trading.CurrentTrade.isActive then return end
    
    -- When both players accept, capture the gold amount of target NOW before trade completes
    if playerAccepted == 1 and targetAccepted == 1 then
        local goldFromTarget = GetTargetTradeMoney() / 10000
        
        -- Store these for when UI_INFO_MESSAGE fires
        GDKPT.RaidLeader.Trading.CurrentTrade.goldOffered = goldFromTarget
    end
end




-------------------------------------------------------------------
-- on trade update during pot split phase
-------------------------------------------------------------------


function GDKPT.RaidLeader.Trading.OnTradeAcceptUpdateInPotSplitPhase(playerAccepted, targetAccepted)

    if not GDKPT.RaidLeader.Trading.CurrentPotSplitTrade.isActive then return end

    if playerAccepted == 1 and targetAccepted == 1 then
        local goldFromSelf = GetPlayerTradeMoney() / 10000
        GDKPT.RaidLeader.Trading.CurrentPotSplitTrade.goldGiven = goldFromSelf
    end
end








-------------------------------------------------------------------
-- on trade window closed (NOT COMPLETED) in debt collection phase
-- reset the trade table if either trade partner closes the trade
-------------------------------------------------------------------



function GDKPT.RaidLeader.Trading.OnTradeClosedInDebtCollectionPhase()
    
    if GDKPT.RaidLeader.Trading.CurrentTrade.isActive then
        local partner = GDKPT.RaidLeader.Trading.CurrentTrade.partner
    end
    
    C_Timer.After(1,function()
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


-------------------------------------------------------------------
-- on trade window closed (NOT COMPLETED) in pot split phase
-- reset the trade table if either trade partner closes the trade
-------------------------------------------------------------------

function GDKPT.RaidLeader.Trading.OnTradeClosedInPotSplitPhase()

    if GDKPT.RaidLeader.Trading.CurrentTrade.isActive then
        local partner = GDKPT.RaidLeader.Trading.CurrentPotSplitTrade.partner
    end
    
    C_Timer.After(1,function()
    GDKPT.RaidLeader.Trading.CurrentPotSplitTrade = {
        partner = nil,
        partnerBalance = 0,
        goldGiven = 0,
        isActive = false,
    }
    end)

end





-------------------------------------------------------------------
-- Check if all members have paid up (called from trade completion)
-------------------------------------------------------------------

local function AllMembersPaidUp()
    local leaderName = UnitName("player")

    for player, balance in pairs(GDKPT.RaidLeader.Core.PlayerBalances) do
        -- Only check non-leader players
        if player ~= leaderName then
            if balance < 0 then
                return false
            end
        end
    end

    -- Once all non-leaders are settled, ignore leader’s negative debt
    -- since that amount is effectively "paid" into the pot
    GDKPT.RaidLeader.Core.PlayerBalances[leaderName] = 0

    return true
end


--[[
local function AllMembersPaidUp()
    for player, balance in pairs(GDKPT.RaidLeader.Core.PlayerBalances) do
        -- Skip the leader themselves
        if player ~= UnitName("player") then
            if balance < 0 then
                return false
            end
        end
    end
    return true
end

]]





-------------------------------------------------------------------
-- On trade completion in debt collection phase
-------------------------------------------------------------------


function GDKPT.RaidLeader.Trading.OnTradeCompletedInDebtCollectionPhase()

    if not GDKPT.RaidLeader.Trading.CurrentTrade.isActive then return end

    local partner = GDKPT.RaidLeader.Trading.CurrentTrade.partner
    local goldReceived = GDKPT.RaidLeader.Trading.CurrentTrade.goldOffered
    local balance = GDKPT.RaidLeader.Trading.CurrentTrade.partnerBalance

    if not partner or not goldReceived or not balance then return end

    if goldReceived > 0 then
        local newBalance = balance + goldReceived
        GDKPT.RaidLeader.Core.PlayerBalances[partner] = newBalance


        -- Mark items as traded
        if GDKPT.RaidLeader.Trading.CurrentTrade.itemsOffered and #GDKPT.RaidLeader.Trading.CurrentTrade.itemsOffered > 0 then
            for _, item in ipairs(GDKPT.RaidLeader.Trading.CurrentTrade.itemsOffered) do
                item.traded = true
                print(string.format("|cff00ff00[GDKPT Leader]|r %s traded to %s", 
                    item.itemLink or "Item", partner))
            end
            
            -- Remove fully traded items from list
            local wonItems = GDKPT.RaidLeader.Core.PlayerWonItems[partner]
            if wonItems then
                for i = #wonItems, 1, -1 do
                    if wonItems[i].traded then
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

    end

    -- Clean up players with zero debt left
    if GDKPT.RaidLeader.Core.PlayerBalances[partner] and GDKPT.RaidLeader.Core.PlayerBalances[partner] == 0 then
        GDKPT.RaidLeader.Core.PlayerBalances[partner] = nil
    end

    -- Clean up UI
    if GDKPT.RaidLeader.UI.UpdateRosterDisplay then
        GDKPT.RaidLeader.UI.UpdateRosterDisplay()
    end

    -- Check if all items have been traded and all members paid up. If yes, start pot split phase
    local allItemsTraded = true
    local leaderName = UnitName("player")

    for playerName, items in pairs(GDKPT.RaidLeader.Core.PlayerWonItems) do
        -- Ignore the raid leader's own won items
        if playerName ~= leaderName and #items > 0 then
            allItemsTraded = false
            break
        end
    end

    --[[
    
    local allItemsTraded = true
    for _, items in pairs(GDKPT.RaidLeader.Core.PlayerWonItems) do
        if #items > 0 then
            allItemsTraded = false
            break
        end
    end
    ]]


    if allItemsTraded and AllMembersPaidUp() then
        print("|cff00ff00[GDKPT Leader]|r ========================================")
        print("|cff00ff00[GDKPT Leader]|r ALL MEMBERS PAID UP!")
        print("|cff00ff00[GDKPT Leader]|r Ready for pot split!.")
        print("|cff00ff00[GDKPT Leader]|r ========================================")

        GDKPT.RaidLeader.PotSplit.StartPotSplitPhase = true

        SendChatMessage("[GDKPT]: Everyone has received their items.", "RAID")

        SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, "START_POT_SPLIT_PHASE:0", "RAID")
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

    print(partner)
    print(goldGiven)
    print(balance)

    if not partner or not goldGiven or not balance then return end



    if goldGiven > 0 then
        local newBalance = balance - goldGiven
        GDKPT.RaidLeader.Core.PlayerBalances[partner] = newBalance
    end

    -- Clean up players with zero debt left
    if GDKPT.RaidLeader.Core.PlayerBalances[partner] and GDKPT.RaidLeader.Core.PlayerBalances[partner] == 0 then
        GDKPT.RaidLeader.Core.PlayerBalances[partner] = nil
    end

    -- Clean up UI
    if GDKPT.RaidLeader.UI.UpdateRosterDisplay then
        GDKPT.RaidLeader.UI.UpdateRosterDisplay()
    end

    SendChatMessage(string.format("[GDKPT]: %s has received their cut (%d gold) from this raid!",partner, balance), "RAID")
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
            if not isPotSplitPhase then  -- item trading & gold collecting phase
                --GDKPT.RaidLeader.PotSplit.HideTradeAutoFill()  -- no need for the auto fill button when we are collecting gold
                GDKPT.RaidLeader.Trading.OnTradeOpenedInDebtCollectionPhase()
            else                         -- pot split phase, just gold distribution phase
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

            if not isPotSplitPhase then  -- item trading & gold collecting phase
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
            local msg = select(1,...)
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


