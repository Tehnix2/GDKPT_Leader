local LoaderFrame = CreateFrame("Frame", "GDKPTLoaderFrame")


local function GDKPLeaderFrame_OnEvent(self, event, arg1)
    if event == "ADDON_LOADED" then
            if arg1 == "GDKPT_RaidLeader" then
                if GDKPT.RaidLeader.Core and GDKPT.RaidLeader.Core.InitSettings then
                    GDKPT.RaidLeader.Core.InitSettings()
                end

                if GDKPT.RaidLeader.Core and GDKPT.RaidLeader.Core.InitActiveAuctions then
                    GDKPT.RaidLeader.Core.InitActiveAuctions()
                end

                if GDKPT.RaidLeader.UI and GDKPT.RaidLeader.UI.UpdateSettingsUI then
                    GDKPT.RaidLeader.UI.UpdateSettingsUI()
                    
                end

                if GDKPT.RaidLeader.UI and GDKPT.RaidLeader.UI.UpdateRosterDisplay then
                    GDKPT.RaidLeader.UI.UpdateRosterDisplay()
                end

                if GDKPT.RaidLeader.Core.ActiveAuctions then
                    local recalculatedPot = 0
                    for auctionId, auction in pairs(GDKPT.RaidLeader.Core.ActiveAuctions) do
                        if auction.currentBid and auction.currentBid > 0 then
                            recalculatedPot = recalculatedPot + auction.currentBid
                        end
                    end
                    GDKPT.RaidLeader.Core.GDKP_Pot = recalculatedPot
                    print(string.format("|cff00ff00[GDKPT Leader]|r Recalculated pot: %d gold from %d auctions", 
                        recalculatedPot, GDKPT.RaidLeader.Core.nextAuctionId - 1))
                end

                if GDKPT.RaidLeader.Core.InitPotHistory then
                    GDKPT.RaidLeader.Core.InitPotHistory()
                end

                GDKPT.RaidLeader.Core.InitPlayerWonItems()

                self:UnregisterEvent("ADDON_LOADED")

            end
    end
end

LoaderFrame:RegisterEvent("ADDON_LOADED")
LoaderFrame:RegisterEvent("PLAYER_LOGOUT") 
LoaderFrame:SetScript("OnEvent", GDKPLeaderFrame_OnEvent)

GDKPT.RaidLeader = GDKPT.RaidLeader or {}

GDKPT.RaidLeader.LoaderFrame = LoaderFrame