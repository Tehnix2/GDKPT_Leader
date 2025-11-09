GDKPT.RaidLeader.PotSplitTrading = {}


-------------------------------------------------------------------
-- Track current PotSplit Trade session
-------------------------------------------------------------------

GDKPT.RaidLeader.PotSplitTrading.CurrentPotSplitTrade = {
    partner = nil,              -- Trade partner name
    partnerBalance = 0,         -- Partner's balance at trade start, should be positive as this is a PotSplit trade
    leaderGold = 0,             -- Gold offered by leader in trade
}


-------------------------------------------------------------------
-- On trade opened in Pot Split Phase Initialize the trade session
-- and show the HandOutCut button if applicable
-------------------------------------------------------------------

local function OnTradeOpenedInPotSplitPhase()

    local partnerName = UnitName("NPC")
    if not partnerName then return end

    -- Get the balance of the current trade partner
    local balance = GDKPT.RaidLeader.Core.PlayerBalances[partnerName] or 0


    -- Print the current trade partner and their balance
    print(string.format(GDKPT.RaidLeader.Core.addonPrintString .."%s Balance: %d G", partnerName, balance))


    -- Initialize trade session
    GDKPT.RaidLeader.PotSplitTrading.CurrentPotSplitTrade = {
        partner = partnerName,
        partnerBalance = balance,
        leaderGold = 0,
    }

    -- If balance is negative then the player should have already received their cut
    if balance <= 0 then
        print(string.format(GDKPT.RaidLeader.Core.errorPrintString .. "%s has no positive balance for Pot Split!", partnerName))
    end

    
    -- Verify if the leader has enough gold to hand out to the member
    local playerGold = GetMoney() / 10000
    if playerGold < balance then
       print(GDKPT.RaidLeader.Core.errorPrintString .."Not enough gold to hand out the cut")
    end

    -- Show HandOutCut button with delay if this is a valid trade
    C_Timer.After(0.1, function()
        GDKPT.RaidLeader.PotSplit.ShowHandOutCutButtonOnValidTrade(partnerName, balance)
    end)
end



-------------------------------------------------------------------
-- When the Gold offered by the leader changes in PotSplit Trading 
-- Phase we store the gold value within the current trade table
-------------------------------------------------------------------

local function OnMoneyChangedInPotSplitPhase()
    local goldFromSelf = GetPlayerTradeMoney() / 10000
    GDKPT.RaidLeader.PotSplitTrading.CurrentPotSplitTrade.leaderGold = goldFromSelf
end



-------------------------------------------------------------------
-- When both players accept the Trade in Pot Split Trading Phase then 
-- update the partner gold in the current trade session
-------------------------------------------------------------------


local function OnTradeAcceptUpdateInPotSplitPhase(playerAccepted, targetAccepted)
    
    if playerAccepted == 1 and targetAccepted == 1 then           -- both parties accepted the trade
        local goldFromSelf = GetPlayerTradeMoney() / 10000
        GDKPT.RaidLeader.PotSplitTrading.CurrentPotSplitTrade.leaderGold = goldFromSelf   -- Update leader gold
    end
end



-------------------------------------------------------------------
-- If a trade gets canceled or closed without completing in PotSplit 
-- Trading Phase then reset the current trade session after a short delay
-------------------------------------------------------------------


local function OnTradeClosedInPotSplitPhase()
    C_Timer.After(0.1, function()
        GDKPT.RaidLeader.PotSplitTrading.CurrentPotSplitTrade = {
            partner = nil,
            partnerBalance = 0,
            leaderGold = 0,
        }
    end)
end




-------------------------------------------------------------------
-- On trade completion in PotSplit Trading Phase update the partners'
-- balance based on the gold they received
-------------------------------------------------------------------


local function OnTradeCompletedInPotSplitPhase()

    -- Use stored values from the trade session
    local partner = GDKPT.RaidLeader.PotSplitTrading.CurrentPotSplitTrade.partner
    local goldGiven = GDKPT.RaidLeader.PotSplitTrading.CurrentPotSplitTrade.leaderGold
    
    if not partner or not goldGiven then
        print(GDKPT.RaidLeader.Core.errorPrintString .. "No stored pot split trade data!")
        return
    end

    if goldGiven > 0 then
        local currentBalance = GDKPT.RaidLeader.Core.PlayerBalances[partner] or 0
        local newBalance = currentBalance - goldGiven
        
        GDKPT.RaidLeader.Core.PlayerBalances[partner] = newBalance
        
        SendChatMessage(string.format("[GDKPT]: %s has received their cut (%d gold)!", 
        partner, goldGiven), "RAID")
    end
    -- Update the player balances inside the LeaderFrame
    GDKPT.RaidLeader.PlayerBalance.UpdatePlayerBalance()

end




-------------------------------------------------------------------
-- potSplitTradeFrame to react to PotSplit trade events
-------------------------------------------------------------------

local potSplitTradeFrame = CreateFrame("Frame")
potSplitTradeFrame:RegisterEvent("TRADE_SHOW")
potSplitTradeFrame:RegisterEvent("TRADE_CLOSED")
potSplitTradeFrame:RegisterEvent("TRADE_MONEY_CHANGED")
potSplitTradeFrame:RegisterEvent("TRADE_PLAYER_ITEM_CHANGED")
potSplitTradeFrame:RegisterEvent("TRADE_ACCEPT_UPDATE")
potSplitTradeFrame:RegisterEvent("UI_INFO_MESSAGE")
potSplitTradeFrame:RegisterEvent("PARTY_LOOT_METHOD_CHANGED")



-------------------------------------------------------------------
-- Function to check if the current trade is a valid PotSplit Trade 
-------------------------------------------------------------------

local function IsValidPotSplitTradeEvent()

    -- Must be in Pot Split phase
    if not GDKPT.RaidLeader.PotSplit.StartPotSplitPhase then
            return false
    end

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

    -- There must be at least one player with a positive balance, otherwise this is not an Pot Split trade event
    for _, balance in pairs(balances) do
        if balance > 0 then
            return true
        end
    end

    return false
end



-------------------------------------------------------------------
-- Event Handler
-------------------------------------------------------------------


potSplitTradeFrame:SetScript("OnEvent", function(self, event, ...)
    
    -- Check if this is a valid PotSplit trade event, if not then just return
    if not IsValidPotSplitTradeEvent() then 
        return
    end
    -- Event handling based on the current step within the item trading phase
    if event == "TRADE_SHOW" then
        OnTradeOpenedInPotSplitPhase()
    elseif event == "TRADE_MONEY_CHANGED" then
        OnMoneyChangedInPotSplitPhase()
    elseif event == "TRADE_ACCEPT_UPDATE" then
        local playerAccepted, targetAccepted = ...
        OnTradeAcceptUpdateInPotSplitPhase(playerAccepted, targetAccepted)
    elseif event == "TRADE_CLOSED" then
        OnTradeClosedInPotSplitPhase()
    elseif event == "UI_INFO_MESSAGE" then
        local msg = select(1, ...)
        if msg == ERR_TRADE_COMPLETE then
            OnTradeCompletedInPotSplitPhase()
        end
    end
end)























