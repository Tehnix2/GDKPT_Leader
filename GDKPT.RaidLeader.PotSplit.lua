GDKPT.RaidLeader.PotSplit = {}

-- Default to false - pot split only starts when all members paid
GDKPT.RaidLeader.PotSplit.StartPotSplitPhase = false

-------------------------------------------------------------------
-- DistributePot to add the cut to all players balance
-------------------------------------------------------------------

function GDKPT.RaidLeader.PotSplit.DistributePot()
    if not GDKPT.RaidLeader.PotSplit.StartPotSplitPhase then
        print("|cffff8800[GDKPT Leader]|r Cannot distribute pot - not all members have paid!")
        return
    end

    local totalPot = GDKPT.RaidLeader.Core.GDKP_Pot
    
    if totalPot <= 0 then
        print("|cffff8800[GDKPT Leader]|r Cannot distribute pot - pot is empty!")
        return
    end

    -- Get actual raid size automatically
    local raidMembers = {}
    local numRaid = GetNumRaidMembers()
    
    if numRaid == 0 then
        -- Solo testing - just use self
        local selfName = UnitName("player")
        if selfName then
            table.insert(raidMembers, selfName)
        end
    else
        -- Get all online raid members
        for i = 1, numRaid do
            local name, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
            if name and online then
                table.insert(raidMembers, name)
            end
        end
    end
    
    local numSplits = #raidMembers
    
    if numSplits == 0 then
        print("|cffff8800[GDKPT Leader]|r Error: No raid members found!")
        return
    end

    -- Convert to copper for precise calculation
    local totalPotCopper = totalPot * 10000
    
    -- Calculate per-player share in copper (with proper rounding)
    local playerShareCopper = math.floor((totalPotCopper / numSplits) + 0.5)
    
    -- Convert back to gold (this will have decimal precision)
    local playerShareGold = playerShareCopper / 10000

    -- Apply the cut to all raid member's balance
    local distributedTo = 0
    for _, name in ipairs(raidMembers) do
        GDKPT.RaidLeader.Core.PlayerBalances[name] = 
            (GDKPT.RaidLeader.Core.PlayerBalances[name] or 0) + playerShareGold
        distributedTo = distributedTo + 1
    end

    -- Update UI
    if GDKPT.RaidLeader.UI.UpdateRosterDisplay then
        GDKPT.RaidLeader.UI.UpdateRosterDisplay()
    end

    -- Format the share nicely for announcement
    local shareGold = math.floor(playerShareGold)
    local shareSilver = math.floor((playerShareGold - shareGold) * 100)
    local shareCopper = math.floor(((playerShareGold - shareGold) * 10000) - (shareSilver * 100))
    
    local shareText
    if shareSilver == 0 and shareCopper == 0 then
        shareText = string.format("%dg", shareGold)
    elseif shareCopper == 0 then
        shareText = string.format("%dg %ds", shareGold, shareSilver)
    else
        shareText = string.format("%dg %ds %dc", shareGold, shareSilver, shareCopper)
    end

    -- Announce in raid
    if IsInRaid() then
        SendChatMessage(
            string.format(
                "[GDKPT] Pot Split initialized! Total Pot: %d g - Split among %d online raiders - Each receives: %s - Trade the raid leader for your gold!",
                totalPot,
                numSplits,
                shareText
            ),
            "RAID"
        )
    end

    print(string.format("|cff00ff00[GDKPT Leader]|r Pot distributed! %d players will receive %s each.", 
        distributedTo, shareText))

    GDKPT.RaidLeader.MessageHandler.SafeSendAddonMessage(
        GDKPT.RaidLeader.Core.addonPrefix,"POT_SPLIT_START:0","RAID")
end





--[[



function GDKPT.RaidLeader.PotSplit.DistributePot()
    if not GDKPT.RaidLeader.PotSplit.StartPotSplitPhase then
        print("|cffff8800[GDKPT Leader]|r Cannot distribute pot - not all members have paid!")
        return
    end

    local totalPot = GDKPT.RaidLeader.Core.GDKP_Pot
    local numSplits = GDKPT.RaidLeader.Core.AuctionSettings.splitCount or 25

    if totalPot <= 0 then
        print("|cffff8800[GDKPT Leader]|r Cannot distribute pot - pot is empty!")
        return
    end

    -- Convert to copper for precise calculation
    local totalPotCopper = totalPot * 10000
    
    -- Calculate per-player share in copper (with proper rounding)
    local playerShareCopper = math.floor((totalPotCopper / numSplits) + 0.5) -- Round to nearest copper
    
    -- Convert back to gold (this will have decimal precision)
    local playerShareGold = playerShareCopper / 10000

    -- Get list of raid members
    local raidMembers = {}
    local numRaid = GetNumRaidMembers()
    for i = 1, numRaid do
        local name = GetRaidRosterInfo(i)
        if name then
            table.insert(raidMembers, name)
        end
    end

    -- Apply the cut to all raid member's balance
    -- Store as gold units with decimal precision
    local distributedTo = 0
    for _, name in ipairs(raidMembers) do
        GDKPT.RaidLeader.Core.PlayerBalances[name] = (GDKPT.RaidLeader.Core.PlayerBalances[name] or 0) + playerShareGold
        distributedTo = distributedTo + 1
    end

    -- Update UI
    if GDKPT.RaidLeader.UI.UpdateRosterDisplay then
        GDKPT.RaidLeader.UI.UpdateRosterDisplay()
    end

    -- Format the share nicely for announcement
    local shareGold = math.floor(playerShareGold)
    local shareSilver = math.floor((playerShareGold - shareGold) * 100)
    local shareCopper = math.floor(((playerShareGold - shareGold) * 10000) - (shareSilver * 100))
    
    local shareText
    if shareSilver == 0 and shareCopper == 0 then
        shareText = string.format("%dg", shareGold)
    elseif shareCopper == 0 then
        shareText = string.format("%dg %ds", shareGold, shareSilver)
    else
        shareText = string.format("%dg %ds %dc", shareGold, shareSilver, shareCopper)
    end

    -- Announce in raid
    if IsInRaid() then
        SendChatMessage(
            string.format(
                "[GDKPT] Pot Split initialized! Total Pot: %d g - Split by: %d - Each receives: %s - Trade the raid leader for your gold!",
                totalPot,
                numSplits,
                shareText
            ),
            "RAID"
        )
    end

    print(string.format("|cff00ff00[GDKPT Leader]|r Pot distributed! %d players will receive %s each.", 
        distributedTo, shareText))

    GDKPT.RaidLeader.MessageHandler.SafeSendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix,"POT_SPLIT_START:0","RAID")
end


]]


-------------------------------------------------------------------
-- Button for actually distributing the pot
-------------------------------------------------------------------
local SplitPotNowButton = CreateFrame("Button", nil, LeaderFrame, "GameMenuButtonTemplate")
SplitPotNowButton:SetSize(120, 22)
SplitPotNowButton:SetPoint("BOTTOM", LeaderFrame, "BOTTOM", 0, 10)
SplitPotNowButton:SetText("Split Pot Now")
SplitPotNowButton:Hide() -- Hidden until ready phase is activated

SplitPotNowButton:SetScript("OnClick", function()
    StaticPopupDialogs["GDKPT_CONFIRM_FINALIZE"] = {
        text = "Split the pot now?\n\nThis will add each player's cut to their balance.\nYou will then need to trade each member to give them their gold.",
        button1 = "Yes, Split Pot",
        button2 = "Cancel",
        OnAccept = function()
            if IsInRaid() then
                GDKPT.RaidLeader.PotSplit.DistributePot()
            else
                print("|cffff8800[GDKPT Leader]|r You must be in a raid to split the pot!")
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("GDKPT_CONFIRM_FINALIZE")
end)



-------------------------------------------------------------------
-- "Ready for Pot Split" Button (Manual activation by leader)
-------------------------------------------------------------------
local ReadyForPotSplitButton = CreateFrame("Button", nil, LeaderFrame, "UIPanelButtonTemplate")
ReadyForPotSplitButton:SetSize(140, 22)
ReadyForPotSplitButton:SetPoint("BOTTOM", LeaderFrame, "BOTTOM", 0, -100)
ReadyForPotSplitButton:SetText("Ready for Pot Split")
ReadyForPotSplitButton:Disable() -- Disabled by default

GDKPT.RaidLeader.PotSplit.ReadyForPotSplitButton = ReadyForPotSplitButton

ReadyForPotSplitButton:SetScript("OnClick", function()
    StaticPopupDialogs["GDKPT_CONFIRM_READY"] = {
        text = "Declare that you're READY FOR POT SPLIT?\n\nThis means:\n- All current auctions are done\n- All winners have been traded\n- No more items to auction\n\nYou can still continue auctioning after this.",
        button1 = "Yes, Ready to Split",
        button2 = "Cancel",
        OnAccept = function()
            print("|cff00ff00[GDKPT Leader]|r ========================================")
            print("|cff00ff00[GDKPT Leader]|r ALL MEMBERS PAID UP!")
            print("|cff00ff00[GDKPT Leader]|r Ready for pot split!")
            print("|cff00ff00[GDKPT Leader]|r ========================================")
            
            GDKPT.RaidLeader.PotSplit.StartPotSplitPhase = true
            SendChatMessage("[GDKPT]: All items have been distributed. Pot split is now available!", "RAID")
            SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, "START_POT_SPLIT_PHASE:0", "RAID")
            
            -- Update button states
            ReadyForPotSplitButton:Hide()
            SplitPotNowButton:Show()
            SplitPotNowButton:Enable()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("GDKPT_CONFIRM_READY")
end)






-------------------------------------------------------------------
-- Trade Hand Out Cut Button to hand out the players cut
-------------------------------------------------------------------
local HandOutCutButton = CreateFrame("Button", "HandOutCutButton", TradeFrame, "UIPanelButtonTemplate")
HandOutCutButton:SetSize(100, 22)
HandOutCutButton:SetText("Autofill")
HandOutCutButton:SetPoint("TOP", TradeFrame, "TOP", -60, -45)
HandOutCutButton:SetNormalFontObject("GameFontNormal")
HandOutCutButton:SetHighlightFontObject("GameFontHighlight")
HandOutCutButton:Hide()

function GDKPT.RaidLeader.PotSplit.ShowAutoFillButtonOnValidTrade(partner, amountGold)
    HandOutCutButton:SetScript("OnClick", function()
        local copperAmount = amountGold * 10000
        MoneyInputFrame_SetCopper(TradePlayerInputMoneyFrame, copperAmount)
        
        AcceptTrade() 
    end)
    HandOutCutButton:SetText(string.format("Cut: %dg", amountGold))
    HandOutCutButton:Show()
end

function GDKPT.RaidLeader.PotSplit.HideAutoFillButton()
    HandOutCutButton:Hide()
end

-- Hide button when trade closes
local function OnTradeFrameHide()
    HandOutCutButton:Hide()
end

TradeFrame:HookScript("OnHide", OnTradeFrameHide)



