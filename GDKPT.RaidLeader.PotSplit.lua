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
    local numSplits = GDKPT.RaidLeader.Core.AuctionSettings.splitCount or 25

    if totalPot <= 0 then
        print("|cffff8800[GDKPT Leader]|r Cannot distribute pot - pot is empty!")
        return
    end

    local playerShare = math.floor(totalPot / numSplits)

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
    local distributedTo = 0
    for _, name in ipairs(raidMembers) do
        GDKPT.RaidLeader.Core.PlayerBalances[name] = (GDKPT.RaidLeader.Core.PlayerBalances[name] or 0) + playerShare
        distributedTo = distributedTo + 1
    end

    -- Update UI
    if GDKPT.RaidLeader.UI.UpdateRosterDisplay then
        GDKPT.RaidLeader.UI.UpdateRosterDisplay()
    end


    -- Announce in raid
    if IsInRaid() then
        SendChatMessage(
            string.format(
                "[GDKPT] Pot Split initialized! Total Pot: %d g - Split by: %d - Each receives: %d g - Trade the raid leader for your gold!",
                totalPot,
                numSplits,
                playerShare
            ),
            "RAID"
        )
    end

    print(string.format("|cff00ff00[GDKPT Leader]|r Pot distributed! %d players will receive %dg each.", 
        distributedTo, playerShare))

    GDKPT.RaidLeader.MessageHandler.SafeSendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix,"POT_SPLIT_START:0","RAID")
end

-------------------------------------------------------------------
-- Button for initiating the pot split
-------------------------------------------------------------------
local SplitPotNowButton = CreateFrame("Button", nil, LeaderFrame, "GameMenuButtonTemplate")
SplitPotNowButton:SetSize(120, 22)
SplitPotNowButton:SetPoint("BOTTOM", LeaderFrame, "BOTTOM", 0, 10)
SplitPotNowButton:SetText("Split Pot Now")

SplitPotNowButton:SetScript("OnClick", function()
    -- Check if we can split
    if not GDKPT.RaidLeader.PotSplit.StartPotSplitPhase then
        StaticPopupDialogs["GDKPT_CANNOT_SPLIT"] = {
            text = "Cannot split pot yet!\n\nAll raid members must receive their items and pay their debts first.",
            button1 = "OK",
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("GDKPT_CANNOT_SPLIT")
        return
    end

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
-- Trade AutoFill Button
-------------------------------------------------------------------
local LeaderAutoFillButton = CreateFrame("Button", "LeaderAutoFillButton", TradeFrame, "UIPanelButtonTemplate")
LeaderAutoFillButton:SetSize(100, 22)
LeaderAutoFillButton:SetText("Autofill")
LeaderAutoFillButton:SetPoint("TOP", TradeFrame, "TOP", -60, -45)
LeaderAutoFillButton:SetNormalFontObject("GameFontNormal")
LeaderAutoFillButton:SetHighlightFontObject("GameFontHighlight")
LeaderAutoFillButton:Hide()

function GDKPT.RaidLeader.PotSplit.ShowAutoFillButtonOnValidTrade(partner, amountGold)
    LeaderAutoFillButton:SetScript("OnClick", function()
        local copperAmount = amountGold * 10000
        MoneyInputFrame_SetCopper(TradePlayerInputMoneyFrame, copperAmount)
        
        AcceptTrade() 
    end)
    LeaderAutoFillButton:SetText(string.format("Give %dg", amountGold))
    LeaderAutoFillButton:Show()
end

function GDKPT.RaidLeader.PotSplit.HideAutoFillButton()
    LeaderAutoFillButton:Hide()
end

-- Hide button when trade closes
local function OnTradeFrameHide()
    LeaderAutoFillButton:Hide()
end

TradeFrame:HookScript("OnHide", OnTradeFrameHide)



