GDKPT.RaidLeader.ItemTrading = {}


-------------------------------------------------------------------
-- Track current Item Trade session
-------------------------------------------------------------------

GDKPT.RaidLeader.ItemTrading.CurrentTrade = {
    partner = nil,          -- Trade partner name
    partnerBalance = 0,     -- Partner's balance at trade start
    partnerGold = 0,        -- Partner's gold in the trade window
    itemsOffered = {},      -- Table of items to give to the partner
    leaderGold = 0          -- in case there are mistrades happening in itemtrading phase and leader needs to give back gold
}





-------------------------------------------------------------------
-- When a trade is opened in Item Trading Phase then initialize the trade 
-- session and auto-place items if applicable
-------------------------------------------------------------------




local function OnTradeOpenedInItemTradingPhase()

     GDKPT.RaidLeader.ItemTrading.CurrentTrade = {
                partner = nil,
                partnerBalance = 0,
                partnerGold = 0,
                itemsOffered = {},
                leaderGold = 0
    }   

    local partnerName = UnitName("NPC")         -- Get trade partner name
    if not partnerName then return end          

    -- Get the balance of the current trade partner
    local balance = GDKPT.RaidLeader.Core.PlayerBalances[partnerName] or 0
    
    -- Print the current trade partner and their balance
    print(string.format(GDKPT.RaidLeader.Core.addonPrintString .. "%s Balance: %d G", partnerName, balance)) 

    -- Initialize trade session on trade open
    GDKPT.RaidLeader.ItemTrading.CurrentTrade = {
        partner = partnerName,
        partnerBalance = balance,
        partnerGold = 0,
        itemsOffered = {},
        leaderGold = 0
    }

    -- Check if partner has won any items
    local wonItems = GDKPT.RaidLeader.Core.PlayerWonItems[partnerName]
    if not wonItems or #wonItems == 0 then
        print(GDKPT.RaidLeader.Core.errorPrintString .. partnerName .. " did not win any items.")
        return
    end
    
    -- Auto-place tradeable items into trade window after short delay (BoE only currently)
    C_Timer.After(0.5, function()
        GDKPT.RaidLeader.Utils.AutoPlaceItemsInTrade(partnerName)
    end)
    
    -- Show trade helper frame after short delay
    if GDKPT.RaidLeader.TradeHelper then
        C_Timer.After(0.2, function()
            GDKPT.RaidLeader.TradeHelper.Show()
        end)
    end
end



-------------------------------------------------------------------
-- When the Gold offered by partner changes in Item Trading Phase
-- store the gold value within the current trade table
-------------------------------------------------------------------

local function OnMoneyChangedInItemTradingPhase()
    local goldFromPartner = GetTargetTradeMoney() / 10000                    -- Gold offered by partner in gold
    local goldFromSelf = GetPlayerTradeMoney() / 10000                       -- Gold offered by Leader in gold (in case of mistrades)

    GDKPT.RaidLeader.ItemTrading.CurrentTrade.partnerGold = goldFromPartner  -- Store in current trade session
    GDKPT.RaidLeader.ItemTrading.CurrentTrade.leaderGold = goldFromSelf
end


-------------------------------------------------------------------
-- When both players accept the Trade in Item Trading Phase then 
-- update the partner gold in the current trade session
-------------------------------------------------------------------


local function OnTradeAcceptUpdateInItemTradingPhase(playerAccepted, targetAccepted)
    
    if playerAccepted == 1 and targetAccepted == 1 then                             -- Both parties accepted the trade
        local goldFromPartner = GetTargetTradeMoney() / 10000 
        local goldFromSelf = GetPlayerTradeMoney() / 10000  
        GDKPT.RaidLeader.ItemTrading.CurrentTrade.partnerGold = goldFromPartner     -- Update partner gold in current trade session
        GDKPT.RaidLeader.ItemTrading.CurrentTrade.leaderGold = goldFromSelf         -- in case it changed from OnMoneyChangedInItemTradingPhase
                                                                                    
    end
end





-------------------------------------------------------------------
-- If a trade gets canceled or closed without completing in Item 
-- Trading Phase then reset the current trade session after a short delay
-------------------------------------------------------------------

local function OnTradeCancelledInItemTradingPhase()
    
    C_Timer.After(0.1, function()
        GDKPT.RaidLeader.ItemTrading.CurrentTrade = {
            partner = nil,
            partnerBalance = 0,
            partnerGold = 0,
            itemsOffered = {},
            leaderGold = 0
        }   
    end)

    -- Close trade helper frame when a trade gets cancelled
    if GDKPT.RaidLeader.TradeHelper then
        GDKPT.RaidLeader.TradeHelper.OnTradeClosed()
    end


end



-------------------------------------------------------------------
-- Process completed trade and update wonItem records
-------------------------------------------------------------------

local function ProcessTradeCompletionForItems()
    local partner = GDKPT.RaidLeader.ItemTrading.CurrentTrade.partner
    if not partner then return end

    local itemsOffered = GDKPT.RaidLeader.ItemTrading.CurrentTrade.itemsOffered
    if not itemsOffered or #itemsOffered == 0 then return end

    local wonItems = GDKPT.RaidLeader.Core.PlayerWonItems[partner]
    if not wonItems then return end

    -- Match offered items to wonItems and update their trade status
    for _, offeredItem in ipairs(itemsOffered) do
        for _, wonItem in ipairs(wonItems) do
            -- Match by itemInstanceHash (most reliable)
            if wonItem.itemInstanceHash == offeredItem.itemInstanceHash or
               wonItem.auctionHash == offeredItem.auctionHash then
                
                local stackTraded = offeredItem.stackSize or 1
                
                -- Update remaining quantity
                wonItem.remainingQuantity = (wonItem.remainingQuantity or wonItem.stackCount) - stackTraded
                
                -- Update amount paid
                if not wonItem.traded then
                    wonItem.amountPaid = (wonItem.amountPaid or 0) + wonItem.price
                    wonItem.traded = true
                end
                
                -- Mark as fully traded if all quantity delivered
                if wonItem.remainingQuantity <= 0 then
                    wonItem.fullyTraded = true
                    wonItem.remainingQuantity = 0
                end
                
                print(string.format(
                    GDKPT.RaidLeader.Core.addonPrintString .. "Traded %dx %s to %s (Auction #%d) - Remaining: %d",
                    stackTraded, wonItem.itemLink, partner, wonItem.auctionId, wonItem.remainingQuantity
                ))
                
                break
            end
        end
    end

    -- Remove fully traded items from the list
    for i = #wonItems, 1, -1 do
        if wonItems[i].fullyTraded then
            table.remove(wonItems, i)
        end
    end

    -- Clean up empty player entries
    if #wonItems == 0 then
        GDKPT.RaidLeader.Core.PlayerWonItems[partner] = nil
    end

    -- Close the trade helper window when a trade gets completed
    if GDKPT.RaidLeader.TradeHelper then
        GDKPT.RaidLeader.TradeHelper.OnTradeClosed()
    end
end





-------------------------------------------------------------------
-- On trade completion in Item Trading Phase update the partners'
-- balance based on the gold they gave
-------------------------------------------------------------------


local function OnTradeCompletedInItemTradingPhase()
    
    -- Use stored values from the trade session
    local partner = GDKPT.RaidLeader.ItemTrading.CurrentTrade.partner
    local goldReceived = GDKPT.RaidLeader.ItemTrading.CurrentTrade.partnerGold
    local goldGiven = GDKPT.RaidLeader.ItemTrading.CurrentTrade.leaderGold

    if not partner then
        print(GDKPT.RaidLeader.Core.errorPrintString .. "No partner name in trade table.")
        return
    end

    local moneyChange = goldReceived - goldGiven        -- Delta between received and given gold

    -- If there is a net difference between goldReceived and goldGiven then update the PlayerBalances table     
    if moneyChange ~= 0 then
        local currentBalance = GDKPT.RaidLeader.Core.PlayerBalances[partner] or 0
        local newBalance = currentBalance + moneyChange
        GDKPT.RaidLeader.Core.PlayerBalances[partner] = newBalance
    end
    -- Process item trades and update wonItem records
    ProcessTradeCompletionForItems()
    -- Visually Update the player balances inside the LeaderFrame
    GDKPT.RaidLeader.PlayerBalance.UpdatePlayerBalance()
end


-------------------------------------------------------------------
-- itemTradeFrame to react to item trade events
-- initially events are registered, and when pot split starts these
-- get unregistered
-------------------------------------------------------------------

local itemTradeFrame = CreateFrame("Frame")


local function RegisterItemTradeEvents()
    if not itemTradeFrame.isRegistered then
        itemTradeFrame:RegisterEvent("TRADE_SHOW")
        itemTradeFrame:RegisterEvent("TRADE_MONEY_CHANGED")
        itemTradeFrame:RegisterEvent("TRADE_PLAYER_ITEM_CHANGED")
        itemTradeFrame:RegisterEvent("TRADE_ACCEPT_UPDATE")
        itemTradeFrame:RegisterEvent("UI_INFO_MESSAGE")
        itemTradeFrame.isRegistered = true
    end
end

-- Initially all item trade events are registered
RegisterItemTradeEvents()


-- item trade events get unregistered when the pot split trading phase begins
local function UnregisterItemTradeEvents()
    if itemTradeFrame.isRegistered then
        itemTradeFrame:UnregisterEvent("TRADE_SHOW")
        itemTradeFrame:UnregisterEvent("TRADE_MONEY_CHANGED")
        itemTradeFrame:UnregisterEvent("TRADE_PLAYER_ITEM_CHANGED")
        itemTradeFrame:UnregisterEvent("TRADE_ACCEPT_UPDATE")
        itemTradeFrame:UnregisterEvent("UI_INFO_MESSAGE")
        itemTradeFrame.isRegistered = false
    end
end




-------------------------------------------------------------------
-- Event Handler
-------------------------------------------------------------------


itemTradeFrame:SetScript("OnEvent", function(self, event, ...)
    
    -- Event handling based on the current step within the item trading phase
    if event == "TRADE_SHOW" then
        OnTradeOpenedInItemTradingPhase()
    elseif event == "TRADE_MONEY_CHANGED" then
        OnMoneyChangedInItemTradingPhase()
    elseif event == "TRADE_ACCEPT_UPDATE" then
        local playerAccepted, targetAccepted = ...
        OnTradeAcceptUpdateInItemTradingPhase(playerAccepted, targetAccepted)
    elseif event == "UI_INFO_MESSAGE" then
        local msg = select(1, ...)
        if msg == ERR_TRADE_COMPLETE then
            OnTradeCompletedInItemTradingPhase()
        elseif msg == ERR_TRADE_CANCELLED then 
            OnTradeCancelledInItemTradingPhase()
        end
    end
end)



-------------------------------------------------------------------
-- Raid Leader Addon Message Handler for balance requests from 
-- raidmembers
-------------------------------------------------------------------

local leaderEventFrame = CreateFrame("Frame")
leaderEventFrame:RegisterEvent("CHAT_MSG_ADDON")

leaderEventFrame:SetScript("OnEvent", function(self, event, prefix, msg, channel, sender)
    if prefix ~= GDKPT.RaidLeader.Core.addonPrefix then return end

    if msg == "REQUEST_MY_BALANCE" then
        local balance = GDKPT.RaidLeader.Core.PlayerBalances[sender] or 0
        SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, "SYNC_MY_BALANCE:" .. balance, "WHISPER", sender)
    end
end)








-------------------------------------------------------------------
-- Expose Register and Unregister functions so they can be used in other files
-------------------------------------------------------------------


GDKPT.RaidLeader.ItemTrading.RegisterEvents = RegisterItemTradeEvents
GDKPT.RaidLeader.ItemTrading.UnregisterEvents = UnregisterItemTradeEvents