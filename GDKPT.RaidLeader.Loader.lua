GDKPT.RaidLeader = GDKPT.RaidLeader or {}


local LoaderFrame = CreateFrame("Frame", "GDKPTLoaderFrame")


local function GDKPT_Loader(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "GDKPT_RaidLeader" then
            -- Initialize auction settings
            if GDKPT.RaidLeader.Core and GDKPT.RaidLeader.Core.InitSettings then
                GDKPT.RaidLeader.Core.InitSettings()
            end
            -- Initialize active auctions from saved variables
            if GDKPT.RaidLeader.Core and GDKPT.RaidLeader.Core.InitActiveAuctions then
                GDKPT.RaidLeader.Core.InitActiveAuctions()
            end
            -- Update UI elements to reflect loaded settings and data
            if GDKPT.RaidLeader.UI and GDKPT.RaidLeader.UI.UpdateSettingsUI then
                GDKPT.RaidLeader.UI.UpdateSettingsUI() 
            end
            -- Initialize player balances
            if GDKPT.RaidLeader.Core and GDKPT.RaidLeader.Core.InitPlayerBalances then
                GDKPT.RaidLeader.Core.InitPlayerBalances()
            end
            -- Initialize player won items
            if GDKPT.RaidLeader.Core and GDKPT.RaidLeader.Core.InitPlayerWonItems then
                GDKPT.RaidLeader.Core.InitPlayerWonItems()
            end
            -- Initialize AuctionedItems table
            if GDKPT.RaidLeader.Core and GDKPT.RaidLeader.Core.InitAuctionedItems then
                GDKPT.RaidLeader.Core.InitAuctionedItems()
            end
            -- Initialize Saved Raid History Snapshots
            if GDKPT.RaidLeader.Core and GDKPT.RaidLeader.Core.InitSavedSnapshots then
                GDKPT.RaidLeader.Core.InitSavedSnapshots()
            end

            if GDKPT.RaidLeader.PlayerBalance and GDKPT.RaidLeader.PlayerBalance.UpdatePlayerBalance then
                GDKPT.RaidLeader.PlayerBalance.UpdatePlayerBalance()
            end
                --
            if GDKPT.RaidLeader.Core.ActiveAuctions then
                local recalculatedPot = 0
                for auctionId, auction in pairs(GDKPT.RaidLeader.Core.ActiveAuctions) do
                    if auction.currentBid and auction.currentBid > 0 and auction.hasEnded then
                        recalculatedPot = recalculatedPot + auction.currentBid
                    end
                end
                GDKPT.RaidLeader.Core.GDKP_Pot = recalculatedPot
            end
                
            if GDKPT.RaidLeader.AuctionStart and GDKPT.RaidLeader.AuctionStart.MouseoverAuction then
                GDKPT.RaidLeader.AuctionStart.MouseoverAuction()
            end

            GDKPT.RaidLeader.Sync.StartLeaderHeartbeat()

            self:UnregisterEvent("ADDON_LOADED")
        end
    end
end

LoaderFrame:RegisterEvent("ADDON_LOADED")
LoaderFrame:RegisterEvent("PLAYER_LOGOUT") 
LoaderFrame:SetScript("OnEvent", GDKPT_Loader) 

