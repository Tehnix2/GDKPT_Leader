GDKPT.RaidLeader.Looting = {}


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

        if #mlItemsToBroadcast > 0 and mlPosition then
            local msg = "MLOOT_ITEM:" .. table.concat(mlItemsToBroadcast, "|")
            GDKPT.RaidLeader.MessageHandler.SafeSendAddonMessage(GDKPT.RaidLeader.Core.addonPrefix, msg, "RAID")
        end
    end
end
