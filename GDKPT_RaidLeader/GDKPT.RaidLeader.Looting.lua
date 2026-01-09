GDKPT.RaidLeader.Looting = {}


---------------------------------------------------------------------------------------
-- Buttons for auto masterlooting and auto announcement of dropped loot without looting
---------------------------------------------------------------------------------------


local AnnounceAndLootButton = CreateFrame("Button", "AutoMasterlootButton", GDKPT.RaidLeader.UI.LeaderFrame, "UIPanelButtonTemplate")
AnnounceAndLootButton:SetSize(160, 22)
AnnounceAndLootButton:SetPoint("TOP", GDKPT.RaidLeader.UI.LeaderFrame  , "BOTTOM", 0, -5)
AnnounceAndLootButton:SetText("Announce & Auto-Loot")


local AnnounceOnlyButton = CreateFrame("Button", nil, GDKPT.RaidLeader.UI.LeaderFrame, "UIPanelButtonTemplate")
AnnounceOnlyButton:SetSize(160, 22)
AnnounceOnlyButton:SetPoint("TOP", GDKPT.RaidLeader.UI.LeaderFrame, "BOTTOM", 0, -40)
AnnounceOnlyButton:SetText("Announce Only")


---------------------------------------------------------------------------------------
-- Function to update button visibility based on raid leader/officer status
---------------------------------------------------------------------------------------


local function UpdateLootingButtonsVisibility()
    if IsRaidLeader() or IsRaidOfficer() then
        AnnounceAndLootButton:Show()
        AnnounceOnlyButton:Show()
    else
        AnnounceAndLootButton:Hide()
        AnnounceOnlyButton:Hide()
    end
end




---------------------------------------------------------------------------------------
-- Function for AutoMasterlooting
---------------------------------------------------------------------------------------

-- Processes loot when the loot window is opened
function GDKPT.RaidLeader.Looting.ProcessLoot(shouldAutoLoot)

    local numItems = GetNumLootItems()

    if numItems <= 0 then return end

    local lootToAnnounce = {}
    local mlItemsToBroadcast = {}
    local minQuality = 2  -- 2 = green, 3 = blue, 4 = purple
    
    local mlPosition
    if shouldAutoLoot then
        local playerName = UnitName("player")
        local candidateIndex = 1
        local candidateName = GetMasterLootCandidate(candidateIndex)
        while candidateName do
            if candidateName == playerName then
                mlPosition = candidateIndex
                break
            end
            candidateIndex = candidateIndex + 1
            candidateName = GetMasterLootCandidate(candidateIndex)
        end
    end

    for numLoot = 1, numItems do
        if LootSlotIsItem(numLoot) then       -- only loot items, not gold
            local _, _, _, quality = GetLootSlotInfo(numLoot)
            local itemLink = GetLootSlotLink(numLoot)
            local itemName = GetItemInfo(itemLink)
            local isIgnored = GDKPT.RaidLeader.Core.AutoLootIgnoreList[itemName]
                       
            if quality >= minQuality and not isIgnored then
                table.insert(lootToAnnounce, itemLink)
                if mlPosition then
                    GiveMasterLoot(numLoot, mlPosition)
                    table.insert(mlItemsToBroadcast, itemLink)
                end
            end
        end
    end

    -- Announce the loot
    local lootString = "[GDKPT] Loot: "
    for i, link in ipairs(lootToAnnounce) do
        if #lootString + #link > 250 then 
            SendChatMessage(lootString, "RAID")
            lootString = link
        else
            lootString = (i == 1) and (lootString .. link) or (lootString .. ", " .. link)
        end
    end
    if #lootToAnnounce > 0 then
        SendChatMessage(lootString, "RAID") 

        for i, itemLink in ipairs(mlItemsToBroadcast) do
            C_Timer.After(i * 0.3, function()  -- 0.3 second delay between each message
                local msg = "MLOOT_ITEM:" .. itemLink
                SendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, msg, "RAID")
            end)
        end
    end
end



---------------------------------------------------------------------------------------
-- Button click handlers
---------------------------------------------------------------------------------------

AnnounceAndLootButton:SetScript("OnClick", function()
    GDKPT.RaidLeader.Looting.ProcessLoot(true) -- 'true' = auto-loot
end)

AnnounceOnlyButton:SetScript("OnClick", function()
    GDKPT.RaidLeader.Looting.ProcessLoot(false) -- 'false' = no auto-loot
end)


---------------------------------------------------------------------------------------
-- Only show the loot and announce buttons when the player is the raid leader, recheck
-- on roster change
---------------------------------------------------------------------------------------


-- Call on load and roster updates
local lootVisibilityFrame = CreateFrame("Frame")
lootVisibilityFrame:RegisterEvent("RAID_ROSTER_UPDATE")
lootVisibilityFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
lootVisibilityFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
lootVisibilityFrame:SetScript("OnEvent", UpdateLootingButtonsVisibility)

-- Initial call
UpdateLootingButtonsVisibility()