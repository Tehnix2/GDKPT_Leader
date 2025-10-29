GDKPT.RaidLeader = GDKPT.RaidLeader or {}

GDKPT.RaidLeader.Core = {}

GDKPT.RaidLeader.Core.version = 0.29

GDKPT.RaidLeader.Core.addonPrefix = "GDKP"  

GDKPT.RaidLeader.Core.PlayerWonItems = {}

GDKPT.RaidLeader.Core.PotFinalized = false


GDKPT.RaidLeader.Core.defaults = {
    duration = 20,         
    extraTime = 5,          
    startBid = 50,         
    minIncrement = 10,      
    splitCount = 25         
}

GDKPT.RaidLeader.Core.AuctionSettings = nil








GDKPT_RaidLeader_Core_PotHistory = GDKPT_RaidLeader_Core_PotHistory or {}
GDKPT.RaidLeader.Core.PotHistory = GDKPT_RaidLeader_Core_PotHistory

function GDKPT.RaidLeader.Core.InitPotHistory()
    local savedPotHistory = GDKPT_RaidLeader_Core_PotHistory or {}

    
    GDKPT.RaidLeader.Core.PotHistory = GDKPT_RaidLeader_Core_PotHistory
end





function GDKPT.RaidLeader.Core.InitSettings()
    local savedSettings = GDKPT_RaidLeader_Core_AuctionSettings or {}

    for k, v in pairs(GDKPT.RaidLeader.Core.defaults) do
        if savedSettings[k] == nil then
            savedSettings[k] = v
        end
    end

    GDKPT_RaidLeader_Core_AuctionSettings = savedSettings
    GDKPT.RaidLeader.Core.AuctionSettings = GDKPT_RaidLeader_Core_AuctionSettings
end

-------------------------------------------------------------------
-- Active Auctions
-------------------------------------------------------------------


GDKPT.RaidLeader.Core.nextAuctionId = 1  



GDKPT_RaidLeader_Core_ActiveAuctions = GDKPT_RaidLeader_Core_ActiveAuctions or {}
GDKPT.RaidLeader.Core.ActiveAuctions = GDKPT_RaidLeader_Core_ActiveAuctions

GDKPT_RaidLeader_Core_PlayerBalances = GDKPT_RaidLeader_Core_PlayerBalances or {}
GDKPT.RaidLeader.Core.PlayerBalances = GDKPT_RaidLeader_Core_PlayerBalances


function GDKPT.RaidLeader.Core.InitActiveAuctions()
    -- Load saved auctions
    GDKPT.RaidLeader.Core.ActiveAuctions = GDKPT_RaidLeader_Core_ActiveAuctions
    GDKPT.RaidLeader.Core.PlayerBalances = GDKPT_RaidLeader_Core_PlayerBalances
    
    -- Find the highest auction ID to continue from
    local maxId = 0
    for auctionId, _ in pairs(GDKPT.RaidLeader.Core.ActiveAuctions) do
        local numId = tonumber(auctionId)
        if numId and numId > maxId then
            maxId = numId
        end
    end
    GDKPT.RaidLeader.Core.nextAuctionId = maxId + 1
    
    print(string.format("|cff00ff00[GDKPT Leader]|r Loaded %d saved auctions. Next ID: %d", 
        maxId, GDKPT.RaidLeader.Core.nextAuctionId))
end





GDKPT_RaidLeader_Core_PlayerWonItems = GDKPT_RaidLeader_Core_PlayerWonItems or {}
GDKPT.RaidLeader.Core.PlayerWonItems = GDKPT_RaidLeader_Core_PlayerWonItems

function GDKPT.RaidLeader.Core.InitPlayerWonItems()
    GDKPT.RaidLeader.Core.PlayerWonItems = GDKPT_RaidLeader_Core_PlayerWonItems
end







function GDKPT.RaidLeader.Core.ResetAllAuctions()
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
    
    -- Reset flags
    GDKPT.RaidLeader.Core.nextAuctionId = 1
    GDKPT.RaidLeader.Core.GDKP_Pot = 0
    GDKPT.RaidLeader.Core.PotFinalized = false  
    --GDKPT.RaidLeader.PotSplit.PotDistributed = false
    
    -- Update UI
    if GDKPT.RaidLeader.UI.UpdateRosterDisplay then
        GDKPT.RaidLeader.UI.UpdateRosterDisplay()
    end

    GDKPT.RaidLeader.PotSplit.StartPotSplitPhase = false
    
    print("|cff00ff00[GDKPT Leader]|r Full reset complete.")
end





GDKPT.RaidLeader.Core.GDKP_Pot = 0        





-------------------------------------------------------------------
-- Items that will not get auto looted, based on item name
-------------------------------------------------------------------


GDKPT.RaidLeader.Core.AutoLootIgnoreList = {
    ["Nether Vortex"] = true,
    ["Ashes of Al'ar"] = true,
    ["Splinter of Atiesh"] = true,
    
}



GDKPT.RaidLeader.Core.TradeSession = {} -- To store active trade data



if GDKPT_RaidLeader_UpdateSettingsUI then
    GDKPT_RaidLeader_UpdateSettingsUI()
end



-------------------------------------------------------------------
-- Slash Commands
-------------------------------------------------------------------

SLASH_GDKPTLEADER1 = "/gdkpleader"
SlashCmdList["GDKPTLEADER"] = function(message)
    local cmd, param = message:match("^(%S+)%s*(.*)")
    cmd = cmd or ""

    if cmd == "" or cmd == "help" then
        print("|cff00ff00[GDKP Leader]|r Commands:")
        print("  /gdkpleader auction [itemlink] - starts auction for linked item ")
        print("  /gdkpleader hide - hides the leader frame")
        print("  /gdkpleader reset - reset the current session")
        print("  /gdkpleader show - shows the Leader frame ")
        print("  /gdkpleader syncdata - sends current auction data to raidmembers")
        print("  /gdkpleader syncsettings - sends global gdkp parameters to raidmembers")
        print("  /gdkpleader version - shows current leader addon version")
        print("  /gdkpleader versioncheck - causes everyone to post their GDKPT version in raid chat")
    elseif cmd == "auction" or cmd == "a" then
        GDKPT.RaidLeader.AuctionStart.StartAuction(param)
    elseif cmd == "hide" or cmd == "h" then
        --   GDKPLeaderFrame:Hide()
    elseif cmd == "reset" or cmd == "r" then
        GDKPT.RaidLeader.Core.ResetAllAuctions()
    elseif cmd == "show" or cmd == "s" then
        GDKPLeaderFrame:Show()
    elseif cmd == "syncdata" or cmd == "sendauctiondata" then
        --    SendAuctionData()
        print("Auction Data is sent to raidmembers.")
    elseif cmd == "syncsettings" or cmd == "sendsettings" then
        print("Sending global GDKP settings to raidmembers.") --TODO: Create SendSettings function to re-send the global settings to member addon
        SyncSettings()
    elseif cmd == "version" or cmd == "v" or cmd == "vers" then
        print("Current GDKPT Leader Addon Version: " .. version)
    elseif cmd == "versioncheck" then
        VersionCheck()
    elseif cmd == "leader" then
        LeaderFrame:Show()
    elseif cmd == "debug" or cmd == "d" then
        print("|cff00ff00[GDKPT Leader]|r Debug Info:")
        print("PlayerWonItems table:")
        for player, items in pairs(GDKPT.RaidLeader.Core.PlayerWonItems) do
            print(string.format("  %s has %d items:", player, #items))
            for i, item in ipairs(items) do
                print(string.format("    %d. ItemID=%d, Traded=%s, Link=%s", 
                    i, item.itemID, tostring(item.traded), item.itemLink or "nil"))
            end
        end
        if not next(GDKPT.RaidLeader.Core.PlayerWonItems) then
            print("  (empty)")
        end
    elseif cmd == "export" or cmd == "e" then
        if GDKPT.RaidLeader.Export then
            GDKPT.RaidLeader.Export.Show()
        end
    end

end


