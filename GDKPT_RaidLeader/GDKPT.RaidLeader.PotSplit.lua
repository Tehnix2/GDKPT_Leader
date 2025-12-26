GDKPT.RaidLeader.PotSplit = {}

-------------------------------------------------------------------
-- Default to false - pot split phase not started
-- This is set to true when the raid leader clicks "Ready for Pot Split"
-------------------------------------------------------------------

GDKPT.RaidLeader.PotSplit.StartPotSplitPhase = false



-------------------------------------------------------------------
-- Button that checks if a pot split can be done
-------------------------------------------------------------------

local CheckPotSplitButton = CreateFrame("Button", nil, GDKPT.RaidLeader.UI.LeaderFrame, "UIPanelButtonTemplate")
CheckPotSplitButton:SetSize(140, 22)
CheckPotSplitButton:SetPoint("BOTTOM", GDKPT.RaidLeader.UI.LeaderFrame, "BOTTOM", 0, -100)
CheckPotSplitButton:SetText("Ready for Pot Split")
CheckPotSplitButton:Show()



-------------------------------------------------------------------
-- Button that finalizes pot split and distributes the pot AFTER 
-- the other button has been pressed
-------------------------------------------------------------------


local PotSplitButton = CreateFrame("Button", nil, GDKPT.RaidLeader.UI.LeaderFrame, "GameMenuButtonTemplate")
PotSplitButton:SetSize(120, 22)
PotSplitButton:SetPoint("BOTTOM", GDKPT.RaidLeader.UI.LeaderFrame, "BOTTOM", 0, 10)
PotSplitButton:SetText("Split Pot Now")
PotSplitButton:Hide()     -- Hidden until pot split phase starts 
PotSplitButton:Disable()  -- Disabled by default 








-------------------------------------------------------------------
-- Check if leader has enough gold collected from raidmembers to cover pot split
-- for all raid members (offline raid members included, so kick before pot split)
-------------------------------------------------------------------


function GDKPT.RaidLeader.PotSplit.EnoughGoldCollected()
    local totalPot = GDKPT.RaidLeader.Core.GDKP_Pot -- Total pot in gold

    if totalPot <= 0 then
        print(GDKPT.RaidLeader.Core.errorPrintString .. "No Auction has ended yet, there is no Pot yet!")
        return false
    end

    local playerGold = GetMoney() / 10000 -- Convert copper to gold
    local numRaid = GDKPT.RaidLeader.Utils.GetCurrentSplitCount()   -- Get number of raid members
    
    -- Calculate per-player share and total needed
    local totalPotCopper = totalPot * 10000
    local playerShareCopper = math.floor((totalPotCopper / numRaid) + 0.5)
    local totalNeededCopper = playerShareCopper * numRaid
    local totalNeededGold = totalNeededCopper / 10000
    
    -- Check if leader has enough gold
    if playerGold < totalNeededGold then
        print(string.format(GDKPT.RaidLeader.Core.errorPrintString .. "You need %.4fg more gold to complete pot split!", totalNeededGold - playerGold))
        return false
    end
    
    print(GDKPT.RaidLeader.Core.addonPrintString .. "All verifications passed - pot split is now available!")
    return true
end



-------------------------------------------------------------------
-- Add the cut to each player's balance and announce in raid chat
-- and send addon message to raidmembers
-------------------------------------------------------------------


function GDKPT.RaidLeader.PotSplit.DistributePot()

    if not GDKPT.RaidLeader.PotSplit.StartPotSplitPhase then
        print(GDKPT.RaidLeader.Core.errorPrintString .."Cannot Pot Split yet - StartPotSplitPhase is still false!")
        return
    end

    if not GDKPT.RaidLeader.PotSplit.EnoughGoldCollected() then
        print(GDKPT.RaidLeader.Core.errorPrintString .. "Not enough gold collected to do a full pot split!")
        return
    end

    -- Get total pot
    local totalPot = GDKPT.RaidLeader.Core.GDKP_Pot -- totalPot is already validated in EnoughGoldCollected

    -- Every raidmember (online+offline) gets a share. Use the raid count at the point when the leader clicks the button
    local numSplits = GDKPT.RaidLeader.Core.ExportSplitCount -- GDKPT.RaidLeader.Utils.GetCurrentSplitCount()
    
    if numSplits <= 0 then
        print(GDKPT.RaidLeader.Core.errorPrintString .. "There are no raid members!")
        return
    end

    -- Calculate each player's share accurately by using copper internally and converting back to gold
    local totalPotCopper = totalPot * 10000
    local playerShareCopper = math.floor((totalPotCopper / numSplits) + 0.5)
    local playerShareGold = playerShareCopper / 10000

    
    -- Add the player share to each player's balance and count the amount of players distributed to
    local distributionCount = 0

    -- Get all raid member names
    local raidMembers = {}
    for i = 1, GetNumRaidMembers() do
        local name = GetRaidRosterInfo(i)
        if name then
            raidMembers[name] = true
        end
    end


    -- Distribute to ALL raid members (not just those with existing balances)
    for playerName, _ in pairs(raidMembers) do
        local currentBalance = GDKPT.RaidLeader.Core.PlayerBalances[playerName] or 0
        GDKPT.RaidLeader.Core.PlayerBalances[playerName] = currentBalance + playerShareGold
        distributionCount = distributionCount + 1
    end

    -- Update the shown player balances in the LeaderFrame
    GDKPT.RaidLeader.PlayerBalance.UpdatePlayerBalance()


    local shareText = GDKPT.RaidLeader.Utils.FormatGoldAmountForChatMessage(playerShareGold)

    -- Announce in raid
    if IsInRaid() then
        SendChatMessage(string.format("[GDKPT] Total Pot: %d G - Raid Members: %d - Everyone receives: %s - Trade the raid leader for your gold!",totalPot,numSplits,shareText), "RAID")
    end

    SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix,"POT_SPLIT_START:0","RAID")
end


-------------------------------------------------------------------
-- Helper: Check for offline players
-------------------------------------------------------------------
function GDKPT.RaidLeader.PotSplit.CheckOfflineMembers()
    local offlineNames = ""
    local foundOffline = false
    
    -- Iterate through raid members
    for i = 1, GetNumRaidMembers() do
        local name, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
        
        -- If name exists and online is false
        if name and not online then
            foundOffline = true
            if offlineNames ~= "" then
                offlineNames = offlineNames .. ", "
            end
            offlineNames = offlineNames .. name
        end
    end
    
    return foundOffline, offlineNames
end



-------------------------------------------------------------------
-- Offline Players in raid warning
-------------------------------------------------------------------


StaticPopupDialogs["GDKPT_OFFLINE_WARNING"] = {
    text = "WARNING: Offline Players Detected!\n\n%s\n\nConsider removing these players from the raid before starting the Pot Split.",
    button1 = "Okay",
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}





-------------------------------------------------------------------
-- StaticPopupDialogs for both buttons
-------------------------------------------------------------------


StaticPopupDialogs["GDKPT_CONFIRM_READY"] = {
    text = "Are you ready to do a pot split?\n\nThis means:\n- All current auctions are done\n- All winners have been traded\n- No more items left to auction",
    button1 = "Yes, Enable the Pot Split Button",
    button2 = "Cancel",
    OnAccept = function()
        GDKPT.RaidLeader.PotSplit.StartPotSplitPhase = true -- Enable the Pot Split Phase

        local currentRaidSize = IsInRaid() and GetNumRaidMembers() or 1
        GDKPT.RaidLeader.Core.ExportSplitCount = currentRaidSize
        -- Update button states
        PotSplitButton:Show()
        PotSplitButton:Enable()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}





StaticPopupDialogs["GDKPT_CONFIRM_FINALIZE"] = {
    text = "Split the pot now?\n\nThis will add each player's cut to their balance.\nYou will then need to trade each member to give them their gold.",
    button1 = "Yes, Split Pot",
    button2 = "Cancel",
    OnAccept = function()
        GDKPT.RaidLeader.PotSplit.DistributePot()

        -- Swap trade event handlers:
        -- Turn off item trading frame events
        if GDKPT.RaidLeader.ItemTrading and GDKPT.RaidLeader.ItemTrading.UnregisterEvents then
            GDKPT.RaidLeader.ItemTrading.UnregisterEvents()
        end

        -- Turn on pot split trade frame events
        if GDKPT.RaidLeader.PotSplitTrading and GDKPT.RaidLeader.PotSplitTrading.RegisterEvents then
            GDKPT.RaidLeader.PotSplitTrading.RegisterEvents()
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}




-------------------------------------------------------------------
-- OnClick handlers for the two buttons
-------------------------------------------------------------------


CheckPotSplitButton:SetScript("OnClick", function()
    -- Check for offline players first
    local hasOffline, offlineNames = GDKPT.RaidLeader.PotSplit.CheckOfflineMembers()

    if hasOffline then
        -- If offline players exist, show the warning with their names
        StaticPopup_Show("GDKPT_OFFLINE_WARNING", offlineNames)
    end
    
    StaticPopup_Show("GDKPT_CONFIRM_READY")
end)

PotSplitButton:SetScript("OnClick",function()
    StaticPopup_Show("GDKPT_CONFIRM_FINALIZE")
end)








-------------------------------------------------------------------
-- Trade Hand Out Cut Button to automatically fill the player cut into
-- the trade window
-------------------------------------------------------------------

local HandOutCutButton = CreateFrame("Button", "HandOutCutButton", TradeFrame, "UIPanelButtonTemplate")
HandOutCutButton:SetSize(100, 22)
HandOutCutButton:SetText("")
HandOutCutButton:SetPoint("TOP", TradeFrame, "TOP", -60, -45)
HandOutCutButton:SetNormalFontObject("GameFontNormal")
HandOutCutButton:SetHighlightFontObject("GameFontHighlight")
HandOutCutButton:Hide()




-------------------------------------------------------------------
-- Only show the HandOutCutButton when trading with a valid partner
-- (valid partner = has positive balance and did not receive cut yet)
-------------------------------------------------------------------



function GDKPT.RaidLeader.PotSplit.ShowHandOutCutButtonOnValidTrade(partner, amountGold)

    -- Validate trade partner
    if UnitName("NPC") ~= partner then
        print(GDKPT.RaidLeader.Core.errorPrintString .. "No valid trade partner.")
        HandOutCutButton:Hide()
        return
    end
    
    -- Validate gold amount
    if amountGold <= 0 then
        print(GDKPT.RaidLeader.Core.errorPrintString .. "No valid gold amount.")
        HandOutCutButton:Hide()
        return
    end
    
    -- Check trade partners' current balance
    local currentBalance = GDKPT.RaidLeader.Core.PlayerBalances[partner] or 0
    
    if currentBalance <= 0 then
        print(GDKPT.RaidLeader.Core.errorPrintString .. "Trade partner has no positive balance.")
        HandOutCutButton:Hide()
        return
    end
    

    HandOutCutButton:SetText(string.format("Cut: %d G", currentBalance))
    HandOutCutButton:Show()
end


-------------------------------------------------------------------
-- OnClick behavior for HandOutCutButton
-------------------------------------------------------------------

local function OnClickHandOutCutButton()
    
    local partner = UnitName("NPC")
    
    if not partner then
        print(GDKPT.RaidLeader.Core.errorPrintString .. "No valid trade partner")
        HandOutCutButton:Hide()
        return
    end

    -- Check trade partners' current balance
    local currentBalance = GDKPT.RaidLeader.Core.PlayerBalances[partner] or 0
    
    if currentBalance <= 0 then
        print(string.format(GDKPT.RaidLeader.Core.errorPrintString .. "%s has no positive balance.", partner))
        HandOutCutButton:Hide()
        return
    end

    -- Check if leader has enough gold to hand out the cut
    local playerGold = GetMoney() / 10000 -- Convert copper to gold
    if playerGold < currentBalance then
        print(GDKPT.RaidLeader.Core.errorPrintString .. "You dont have enough gold left to pay this cut.")
        return
    end

    -- Convert gold to copper for the trade input
    local copperAmount = currentBalance * 10000

    -- Validate copper amount, must be positive and below gold cap
    if copperAmount <= 0 or copperAmount > 2147483647 then
        print(GDKPT.RaidLeader.Core.errorPrintString .. "Copper - converted gold amount is invalid.")
        return
    end

    -- Add the players cut to the trade window
    MoneyInputFrame_SetCopper(TradePlayerInputMoneyFrame, copperAmount)
    print(string.format(GDKPT.RaidLeader.Core.addonPrintString .. " Autofilled %d gold for %s", currentBalance, partner))

    AcceptTrade() -- Automatically accept the trade after filling in the amount, requires a second click on the button
end


-------------------------------------------------------------------
-- OnClick handler for HandOutCutButton
-------------------------------------------------------------------

HandOutCutButton:SetScript("OnClick", OnClickHandOutCutButton)



-------------------------------------------------------------------
-- Expose the CheckPotSplitButton for the trading file
-------------------------------------------------------------------

GDKPT.RaidLeader.PotSplit.CheckPotSplitButton = CheckPotSplitButton



