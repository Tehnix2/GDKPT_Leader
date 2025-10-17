-- Create a dedicated, invisible frame just for handling events
local LoaderFrame = CreateFrame("Frame", "GDKPTLoaderFrame")

-- The UpdateSettingsUI function needs to be global or in the GDKPT table 
-- so the loader can call it, but the UpdateSettingsUI function itself relies 
-- on local variables (the EditBoxes) inside GDKPT.RaidLeader.UI.lua.

-- To fix the scoping issue, we will define a function stub here
-- and define the real function inside the UI file, then call the real function.
local function GDKPLeaderFrame_OnEvent(self, event, arg1)
    if event == "ADDON_LOADED" then
            if arg1 == "GDKPT_RaidLeader" then
                -- STEP 1: Initialize settings NOW that the saved variables are loaded
                if GDKPT.RaidLeader.Core and GDKPT.RaidLeader.Core.InitSettings then
                    GDKPT.RaidLeader.Core.InitSettings()
                end

                -- STEP 2: Update the UI with the now-loaded settings
                if GDKPT.RaidLeader.UI and GDKPT.RaidLeader.UI.UpdateSettingsUI then
                    GDKPT.RaidLeader.UI.UpdateSettingsUI()
                    self:UnregisterEvent("ADDON_LOADED")
                end
            end
    end
end

LoaderFrame:RegisterEvent("ADDON_LOADED")
LoaderFrame:RegisterEvent("PLAYER_LOGOUT") 
LoaderFrame:SetScript("OnEvent", GDKPLeaderFrame_OnEvent)

GDKPT.RaidLeader = GDKPT.RaidLeader or {}

GDKPT.RaidLeader.LoaderFrame = LoaderFrame