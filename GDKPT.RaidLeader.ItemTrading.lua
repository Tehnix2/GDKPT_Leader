GDKPT.RaidLeader.ItemTrading = {}


-------------------------------------------------------------------
-- Track current Item Trade session
-------------------------------------------------------------------

GDKPT.RaidLeader.ItemTrading.CurrentTrade = {
    partner = nil,          -- Trade partner name
    partnerBalance = 0,     -- Partner's balance at trade start
    partnerGold = 0,        -- Partner's gold in the trade window
    itemsOffered = {},      -- Table of items to give to the partner
}





-------------------------------------------------------------------
-- When a trade is opened in Item Trading Phase then initialize the trade 
-- session and auto-place items if applicable
-------------------------------------------------------------------




local function OnTradeOpenedInItemTradingPhase()
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
        C_Timer.After(0.5, function()
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
    GDKPT.RaidLeader.ItemTrading.CurrentTrade.partnerGold = goldFromPartner  -- Store in current trade session
end


-------------------------------------------------------------------
-- When both players accept the Trade in Item Trading Phase then 
-- update the partner gold in the current trade session
-------------------------------------------------------------------


local function OnTradeAcceptUpdateInItemTradingPhase(playerAccepted, targetAccepted)
    
    if playerAccepted == 1 and targetAccepted == 1 then                             -- Both parties accepted the trade
        local goldFromPartner = GetTargetTradeMoney() / 10000  
        GDKPT.RaidLeader.ItemTrading.CurrentTrade.partnerGold = goldFromPartner 	-- Update partner gold in current trade session
                                                                                    -- in case it changed from OnMoneyChangedInItemTradingPhase
    end
end





-------------------------------------------------------------------
-- If a trade gets canceled or closed without completing in Item 
-- Trading Phase then reset the current trade session after a short delay
-------------------------------------------------------------------

local function OnTradeClosedInItemTradingPhase()
    
    C_Timer.After(0.1, function()
        GDKPT.RaidLeader.ItemTrading.CurrentTrade = {
            partner = nil,
            partnerBalance = 0,
            partnerGold = 0,
            itemsOffered = {},
        }   
    end)
end




-------------------------------------------------------------------
-- On trade completion in Item Trading Phase update the partners'
-- balance based on the gold they gave
-------------------------------------------------------------------


local function OnTradeCompletedInItemTradingPhase()
    
    -- Use stored values from the trade session
    local partner = GDKPT.RaidLeader.ItemTrading.CurrentTrade.partner
    local goldReceived = GDKPT.RaidLeader.ItemTrading.CurrentTrade.partnerGold


    if not partner or not goldReceived then
        print(GDKPT.RaidLeader.Core.errorPrintString .. "No stored item trade data!")
        return
    end

    -- Add the received gold to the partner's balance
    if goldReceived > 0 then
        local currentBalance = GDKPT.RaidLeader.Core.PlayerBalances[partner] or 0
        local newBalance = currentBalance + goldReceived
        GDKPT.RaidLeader.Core.PlayerBalances[partner] = newBalance
    end
    -- Update the player balances inside the LeaderFrame
    GDKPT.RaidLeader.PlayerBalance.UpdatePlayerBalance()
end


-------------------------------------------------------------------
-- itemTradeFrame to react to item trade events
-------------------------------------------------------------------



local itemTradeFrame = CreateFrame("Frame")
itemTradeFrame:RegisterEvent("TRADE_SHOW")
itemTradeFrame:RegisterEvent("TRADE_CLOSED")
itemTradeFrame:RegisterEvent("TRADE_MONEY_CHANGED")
itemTradeFrame:RegisterEvent("TRADE_PLAYER_ITEM_CHANGED")
itemTradeFrame:RegisterEvent("TRADE_ACCEPT_UPDATE")
itemTradeFrame:RegisterEvent("UI_INFO_MESSAGE")
itemTradeFrame:RegisterEvent("PARTY_LOOT_METHOD_CHANGED")




-------------------------------------------------------------------
-- Function to check if the current trade is a valid ItemTrade 
-------------------------------------------------------------------

local function IsValidItemTradeEvent()

    -- Must be in a raid
    if not IsInRaid() then return false end

    local balances = GDKPT.RaidLeader.Core.PlayerBalances

    -- Must have at least one player with a balance
    local hasAnyBalance = false
    for _, balance in pairs(balances) do
        hasAnyBalance = true
        break
    end
    if not hasAnyBalance then return false end

    -- There must be at least one player with a negative balance, otherwise this is not an item trade event
    for _, balance in pairs(balances) do
        if balance < 0 then
            return true
        end
    end

    return false
end


-------------------------------------------------------------------
-- Event Handler
-------------------------------------------------------------------


itemTradeFrame:SetScript("OnEvent", function(self, event, ...)
    
    -- Check if this is a valid item trade event, if not then just return
    if not IsValidItemTradeEvent() then 
        return
    end
    -- Event handling based on the current step within the item trading phase
    if event == "TRADE_SHOW" then
        OnTradeOpenedInItemTradingPhase()
    elseif event == "TRADE_MONEY_CHANGED" then
        OnMoneyChangedInItemTradingPhase()
    elseif event == "TRADE_ACCEPT_UPDATE" then
        local playerAccepted, targetAccepted = ...
        OnTradeAcceptUpdateInItemTradingPhase(playerAccepted, targetAccepted)
    elseif event == "TRADE_CLOSED" then
        OnTradeClosedInItemTradingPhase()
    elseif event == "UI_INFO_MESSAGE" then
        local msg = select(1, ...)
        if msg == ERR_TRADE_COMPLETE then
            OnTradeCompletedInItemTradingPhase()
        end
    end
end)
