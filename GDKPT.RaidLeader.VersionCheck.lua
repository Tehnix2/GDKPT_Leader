GDKPT.RaidLeader.VersionCheck = {}



-------------------------------------------------------------------
-- Versioncheck button
-------------------------------------------------------------------

local function VersionCheck()
    if IsInRaid() then
        print("|cffff8800[GDKPT Leader]|r Checking raid members GDKPT versions.")
        SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, "VERSION_CHECK:0", "RAID")
    else
        print("|cffff8800[GDKPT Leader]|r Must be in a raid to check for GDKPT versions.")
    end
end

local VersionCheckButton = CreateFrame("Button", nil, GDKPLeaderFrame, "GameMenuButtonTemplate")
VersionCheckButton:SetPoint("CENTER", GDKPLeaderFrame, "CENTER", 0, -140)
VersionCheckButton:SetSize(150, 20)
VersionCheckButton:SetText("Version Check")
VersionCheckButton:SetNormalFontObject("GameFontNormalLarge")
VersionCheckButton:SetHighlightFontObject("GameFontHighlightLarge")

VersionCheckButton:SetScript(
    "OnClick",
    function()
        VersionCheck()
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