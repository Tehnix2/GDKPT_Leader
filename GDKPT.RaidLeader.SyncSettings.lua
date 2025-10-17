GDKPT.RaidLeader.SyncSettings = {}

-------------------------------------------------------------------
-- Button to sync the current auction settings to raidmembers
-------------------------------------------------------------------

local function SyncSettings()
    local data =
        string.format(
        "%d,%d,%d,%d,%d",
        GDKPT.RaidLeader.Core.AuctionSettings.duration,
        GDKPT.RaidLeader.Core.AuctionSettings.extraTime,
        GDKPT.RaidLeader.Core.AuctionSettings.startBid,
        GDKPT.RaidLeader.Core.AuctionSettings.minIncrement,
        GDKPT.RaidLeader.Core.AuctionSettings.splitCount
    )

    if IsInRaid() then
        SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, "SETTINGS:" .. data, "RAID")
        print("|cff00ff00[GDKPT Leader]|r Sync current auction settings to raid members.")
    else
        print("|cffff8800[GDKPT Leader]|r Must be in a raid to sync settings.")
    end
end



local SyncSettingsButton = CreateFrame("Button", nil, GDKPLeaderFrame, "GameMenuButtonTemplate")
SyncSettingsButton:SetPoint("CENTER", GDKPLeaderFrame, "CENTER", 0, -100)
SyncSettingsButton:SetSize(150, 20)
SyncSettingsButton:SetText("Sync Settings")
SyncSettingsButton:SetNormalFontObject("GameFontNormalLarge")
SyncSettingsButton:SetHighlightFontObject("GameFontHighlightLarge")

SyncSettingsButton:SetScript(
    "OnClick",
    function()
        SyncSettings()
    end
)



-------------------------------------------------------------------
-- If a raid member requests a settings sync, then run 
-- SyncSettings() automatically
-------------------------------------------------------------------

GDKPLeaderFrame:SetScript(
    "OnEvent",
    function(self, event, ...)
        if event == "CHAT_MSG_ADDON" then
            local prefix, message, distribution, sender = ...

            if prefix == GDKPT.RaidLeader.Core.addonPrefix then
                -- Check for requested action
                -- Use strsplit to handle the action and then trim to guard against whitespace issues
                local action = select(1, strsplit(":", message, 2))
                action = GDKPT.RaidLeader.Utils.trim(action)

                if action == "REQUEST_SETTINGS_SYNC" then
                    print(
                        "GDKPT Leader: Received setting sync request from " ..
                            sender .. ". Automatically syncing settings."
                    )
                    SyncSettings()
                end
            end
        end
    end
)





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