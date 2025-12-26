GDKPT.RaidLeader.VersionCheck = {}



-------------------------------------------------------------------
-- Versioncheck button in GDKPLeaderFrame
-------------------------------------------------------------------

local VersionCheckButton = CreateFrame("Button", nil, GDKPT.RaidLeader.UI.GDKPLeaderFrame, "GameMenuButtonTemplate")
VersionCheckButton:SetPoint("CENTER", GDKPT.RaidLeader.UI.GDKPLeaderFrame, "CENTER", 100, -80)
VersionCheckButton:SetSize(150, 20)
VersionCheckButton:SetText("Version Check")
VersionCheckButton:SetNormalFontObject("GameFontNormalLarge")
VersionCheckButton:SetHighlightFontObject("GameFontHighlightLarge")



-------------------------------------------------------------------
-- Version Check Function
-------------------------------------------------------------------

local function VersionCheck()
    if IsInRaid() then
        print(GDKPT.RaidLeader.Core.addonPrintString .. "Checking raid members GDKPT versions.")
        SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, "VERSION_CHECK:0", "RAID")
    else
        print(GDKPT.RaidLeader.Core.errorPrintString .." Must be in a raid to check for GDKPT versions.")
    end
end

-------------------------------------------------------------------
-- Hook up button to Version Check Function
-------------------------------------------------------------------

VersionCheckButton:SetScript(
    "OnClick",
    function()
        VersionCheck()
    end
)

