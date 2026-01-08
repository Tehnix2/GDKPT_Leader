GDKPT.RaidLeader.Reset = {}



local ResetAuctionsButton = CreateFrame("Button", nil, GDKPT.RaidLeader.UI.GDKPLeaderFrame, "GameMenuButtonTemplate")
ResetAuctionsButton:SetPoint("BOTTOM", GDKPT.RaidLeader.UI.GDKPLeaderFrame, "BOTTOM", 0, 100)
ResetAuctionsButton:SetSize(150, 20)
ResetAuctionsButton:SetText("Reset All Auctions")
ResetAuctionsButton:SetNormalFontObject("GameFontNormalLarge")
ResetAuctionsButton:SetHighlightFontObject("GameFontHighlightLarge")

ResetAuctionsButton:SetScript("OnClick", function()
    StaticPopupDialogs["GDKPT_CONFIRM_RESET"] = {
        text = "Are you sure you want to reset ALL auctions and player balances? This cannot be undone!",
        button1 = "Yes, Reset Everything",
        button2 = "Cancel",
        OnAccept = function()
            GDKPT.RaidLeader.Reset.ResetAllAuctions()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("GDKPT_CONFIRM_RESET")
end)



function GDKPT.RaidLeader.Reset.ResetAllAuctions()
    -- Send reset message first
    local msg = "AUCTION_RESET:"
    if IsInRaid() then
        SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, msg, "RAID")
        SendChatMessage("[GDKPT] All auctions and balances have been reset.", "RAID")
    end
    
    -- Clear everything
    wipe(GDKPT.RaidLeader.Core.ActiveAuctions)
    wipe(GDKPT_RaidLeader_Core_ActiveAuctions)
    wipe(GDKPT.RaidLeader.Core.PlayerBalances)
    wipe(GDKPT_RaidLeader_Core_PlayerBalances)
    wipe(GDKPT.RaidLeader.Core.PlayerWonItems)  
    wipe(GDKPT_RaidLeader_Core_PlayerWonItems)
    wipe(GDKPT.RaidLeader.Core.AuctionedItems)
    wipe(GDKPT_RaidLeader_Core_AuctionedItems)
    
    -- Reset flags
    GDKPT.RaidLeader.Core.nextAuctionId = 1
    GDKPT.RaidLeader.Core.GDKP_Pot = 0
    GDKPT.RaidLeader.Core.PotFinalized = false  

    if GDKPT.RaidLeader.PotSplit.CheckPotSplitButton then
        GDKPT.RaidLeader.PotSplit.CheckPotSplitButton:Show()
        GDKPT.RaidLeader.PotSplit.CheckPotSplitButton:Enable()
    end
    
    -- Hide and disable the actual pot split button
    if GDKPT.RaidLeader.PotSplit.PotSplitButton then
        GDKPT.RaidLeader.PotSplit.PotSplitButton:Hide()
        GDKPT.RaidLeader.PotSplit.PotSplitButton:Disable()
    end
    

    -- Hide the HandOutCut button from trade window
    if HandOutCutButton then
        HandOutCutButton:Hide()
    end

    
    -- Update UI
    if GDKPT.RaidLeader.PlayerBalance.UpdatePlayerBalance then
        GDKPT.RaidLeader.PlayerBalance.UpdatePlayerBalance()
    end

    GDKPT.RaidLeader.PotSplit.StartPotSplitPhase = false

    if GDKPT.RaidLeader.InventoryOverlay and GDKPT.RaidLeader.InventoryOverlay.UpdateAllBags then
        GDKPT.RaidLeader.InventoryOverlay.UpdateAllBags()
    end

    -- Register the item trade frame events and disable the pot split frame events after a reset
    GDKPT.RaidLeader.PotSplitTrading.UnregisterEvents()
    GDKPT.RaidLeader.ItemTrading.RegisterEvents()


    -- Wait a moment, then broadcast a confirmation sync
    C_Timer.After(2, function()
        if IsInRaid() then
            -- Send empty pot sync to confirm reset state
            local potMsg = string.format("SYNC_POT:%d:%d", 0, GDKPT.RaidLeader.Utils.GetCurrentSplitCount())
            SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, potMsg, "RAID")
        end
    end)
    
    print(GDKPT.RaidLeader.Core.addonPrintString .. "Full reset complete.")
end