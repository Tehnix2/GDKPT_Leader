GDKPT.RaidLeader.Utils = {}

-------------------------------------------------------------------
-- Is message sender in my raid group?
-------------------------------------------------------------------


function GDKPT.RaidLeader.Utils.IsSenderInMyRaid(sender)
    if IsInRaid() then
        for i = 1, GetNumRaidMembers() do
            local name = GetRaidRosterInfo(i)
            if name and name == sender then
                return true
            end
        end
        return false
    end
end


-- Helper function to trim whitespace from a string
function GDKPT.RaidLeader.Utils.trim(s)
    return s:match("^%s*(.-)%s*$") or s
end



-------------------------------------------------------------------
-- Function checks if player is masterlooter 
-------------------------------------------------------------------

function GDKPT.RaidLeader.Utils.IsMasterLooter()
    for raidID = 1, GetNumRaidMembers() do
        local name, _, _, _, _, _, _, _, _, _, isML = GetRaidRosterInfo(raidID)
        if name == UnitName("player") then
            return isML
        end
    end
    return false
end




-------------------------------------------------------------------
-- Function for returning the name of the raid leader
-------------------------------------------------------------------

function GDKPT.RaidLeader.Utils.GetRaidLeaderName()
    if not IsInRaid() then
        return nil 
    end

    for i = 1, GetNumRaidMembers() do
        local name, rank = GetRaidRosterInfo(i)
        if rank == 2 then
            return name
        end
    end

    return nil 
end


-------------------------------------------------------------------
-- Function to get the count of this item in inventory
-------------------------------------------------------------------


function GDKPT.RaidLeader.Utils.GetInventoryStackCount(itemLink)
    if not itemLink then
        return 0
    end

    local itemID = tonumber(itemLink:match("item:(%d+)"))
    if not itemID then return 0 end

    local totalCount = 0
    for bag = 0, 4 do
        local slots = GetContainerNumSlots(bag)
        for slot = 1, slots do
            local _, count = GetContainerItemInfo(bag, slot)
            local link = GetContainerItemLink(bag, slot)
            if link then
                local id = tonumber(link:match("item:(%d+)"))
                if id == itemID then
                    totalCount = totalCount + count
                end
            end
        end
    end

    return totalCount
end