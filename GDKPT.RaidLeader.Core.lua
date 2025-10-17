GDKPT.RaidLeader = GDKPT.RaidLeader or {}

GDKPT.RaidLeader.Core = {}

GDKPT.RaidLeader.Core.version = 0.25

GDKPT.RaidLeader.Core.addonPrefix = "GDKP"  


GDKPT.RaidLeader.Core.defaults = {
    duration = 20,          -- Auction Duration
    extraTime = 5,          -- additional time per bid
    startBid = 50,          -- staring gold amound
    minIncrement = 10,      -- minimum increment from previous bid for bidding
    splitCount = 25         -- amount of players to split the gold by
}

-- Initialize the settings table to nil. It will be set in InitSettings.
GDKPT.RaidLeader.Core.AuctionSettings = nil


-- Define the function that merges defaults with loaded data.
function GDKPT.RaidLeader.Core.InitSettings()
    -- 1. Ensure the global saved variable table exists (loaded from disk or empty)
    local savedSettings = GDKPT_RaidLeader_Core_AuctionSettings or {}

    -- 2. Merge defaults only for missing keys.
    for k, v in pairs(GDKPT.RaidLeader.Core.defaults) do
        if savedSettings[k] == nil then
            savedSettings[k] = v
        end
    end

    -- 3. Point the global variable to the merged table (ensures saving works)
    GDKPT_RaidLeader_Core_AuctionSettings = savedSettings

    -- 4. Set the internal reference (used by UI)
    GDKPT.RaidLeader.Core.AuctionSettings = GDKPT_RaidLeader_Core_AuctionSettings
end



GDKPT.RaidLeader.Core.ActiveAuctions = {}  -- Table that tracks all active auctions
GDKPT.RaidLeader.Core.nextAuctionId = 1    -- Auction Index inside the table


GDKPT.RaidLeader.Core.GDKP_Pot = 0         








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
        --    ResetSession()
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
    end
end



-------------------------------------------------------------------
-- 
-------------------------------------------------------------------



-------------------------------------------------------------------
-- 
-------------------------------------------------------------------


-------------------------------------------------------------------
-- 
-------------------------------------------------------------------


-------------------------------------------------------------------
-- 
-------------------------------------------------------------------


-------------------------------------------------------------------
-- 
-------------------------------------------------------------------

if GDKPT_RaidLeader_UpdateSettingsUI then
    GDKPT_RaidLeader_UpdateSettingsUI()
end