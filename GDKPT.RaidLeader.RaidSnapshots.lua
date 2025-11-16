GDKPT.RaidLeader.RaidSnapshots = {}

------------------------------------------------------------
-- Snapshot Management UI
------------------------------------------------------------

local SnapUI = {}
GDKPT.RaidLeader.RaidSnapshots.UI = SnapUI

local frameWidth, frameHeight = 600, 420


-------------------------------------------------------------------
-- Show Snapshot UI Button in GDKPLeaderFrame
-------------------------------------------------------------------

local SnapshotButton = CreateFrame("Button", nil, GDKPT.RaidLeader.UI.GDKPLeaderFrame, "GameMenuButtonTemplate")
SnapshotButton:SetPoint("CENTER", GDKPT.RaidLeader.UI.GDKPLeaderFrame, "CENTER", -100, -130)
SnapshotButton:SetSize(150, 30)
SnapshotButton:SetText("Raid Snapshots")
SnapshotButton:SetNormalFontObject("GameFontNormalLarge")
SnapshotButton:SetHighlightFontObject("GameFontHighlightLarge")

SnapshotButton:SetScript("OnClick", function()
    if GDKPT.RaidLeader.RaidSnapshots and GDKPT.RaidLeader.RaidSnapshots.ShowUI() then
        GDKPT.RaidLeader.RaidSnapshots.ShowUI()
    end
end)


-------------------------------------------------------------------
-- Unload Snapshot Button in GDKPLeaderFrame
-------------------------------------------------------------------

local UnloadSnapshotButton = CreateFrame("Button", nil, GDKPT.RaidLeader.UI.GDKPLeaderFrame, "GameMenuButtonTemplate")
UnloadSnapshotButton:SetPoint("CENTER", GDKPT.RaidLeader.UI.GDKPLeaderFrame, "CENTER", 100, -130)
UnloadSnapshotButton:SetSize(150, 30)
UnloadSnapshotButton:SetText("Unload Snapshot")
UnloadSnapshotButton:SetNormalFontObject("GameFontNormalLarge")
UnloadSnapshotButton:SetHighlightFontObject("GameFontHighlightLarge")

UnloadSnapshotButton:SetScript("OnClick", function()
    if GDKPT.RaidLeader.RaidSnapshots and GDKPT.RaidLeader.RaidSnapshots.UnloadSnapshot() then
        GDKPT.RaidLeader.RaidSnapshots.UnloadSnapshot()
    end
end)



------------------------------------------------------------
-- Main Snapshot Frame
------------------------------------------------------------
function SnapUI:CreateFrame()
    if self.frame then return end

    local f = CreateFrame("Frame", "GDKP_SnapshotFrame", UIParent)
    f:SetSize(frameWidth, frameHeight)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("DIALOG")

    f:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })

    f:Hide()
    self.frame = f

    ------------------------------------------------------------
    -- Title
    ------------------------------------------------------------
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", 0, -16)
    title:SetText("GDKPT Raid Snapshots")
    self.title = title

    ------------------------------------------------------------
    -- Scroll Frame for Snapshot List
    ------------------------------------------------------------
    local scroll = CreateFrame("ScrollFrame", "GDKP_SnapshotScroll", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 20, -60)
    scroll:SetPoint("BOTTOMRIGHT", -40, 100)

    local content = CreateFrame("Frame")
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)
    self.content = content

    ------------------------------------------------------------
    -- Save New Snapshot
    ------------------------------------------------------------
    local input = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    input:SetSize(200, 30)
    input:SetPoint("BOTTOMLEFT", 20, 50)
    input:SetAutoFocus(false)
    input:SetText("")
    self.input = input

    local saveBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    saveBtn:SetSize(120, 30)
    saveBtn:SetPoint("LEFT", input, "RIGHT", 10, 0)
    saveBtn:SetText("Save Snapshot")
    saveBtn:SetScript("OnClick", function()
        local name = input:GetText()
        GDKPT.RaidLeader.RaidSnapshots.SaveSnapshot(name)
        SnapUI:Refresh()
    end)

    ------------------------------------------------------------
    -- Close Button
    ------------------------------------------------------------
    local close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    close:SetSize(100, 26)
    close:SetPoint("BOTTOM", 0, 10)
    close:SetText("Close")
    close:SetScript("OnClick", function() f:Hide() end)

end

------------------------------------------------------------
-- Create snapshot line in the UI
------------------------------------------------------------
function SnapUI:CreateSnapshotEntry(parent, index, snapshot)
    local line = CreateFrame("Frame", nil, parent)
    line:SetSize(350, 26)

    local loaded = (GDKPT.RaidLeader.Export.LoadedSnapshot == snapshot)

    local label = line:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", 0, 0)
    label:SetText(string.format("[%d] %s  |cffaaaaaa(%dg, %d players)|r",
        index, snapshot.name, snapshot.pot, snapshot.splitCount))

    if loaded then
        label:SetText(">>>" .. label:GetText() .. "<<<")
    end

    ------------------------------------------------------------
    -- Load Button
    ------------------------------------------------------------
    local loadBtn = CreateFrame("Button", nil, line, "UIPanelButtonTemplate")
    loadBtn:SetSize(50, 20)
    loadBtn:SetPoint("RIGHT",-25, 0)
    loadBtn:SetText("Load")
    loadBtn:SetScript("OnClick", function()
        GDKPT.RaidLeader.RaidSnapshots.LoadSnapshot(index)
        SnapUI:Refresh()
    end)

    ------------------------------------------------------------
    -- Export Button
    ------------------------------------------------------------
    local exportBtn = CreateFrame("Button", nil, line, "UIPanelButtonTemplate")
    exportBtn:SetSize(60, 20)
    exportBtn:SetPoint("LEFT",loadBtn,"RIGHT", 25, 0)
    exportBtn:SetText("Export")
    exportBtn:SetScript("OnClick", function()
        GDKPT.RaidLeader.Export.Show(snapshot)
    end)

    ------------------------------------------------------------
    -- Delete Button
    ------------------------------------------------------------
    local deleteBtn = CreateFrame("Button", nil, line, "UIPanelButtonTemplate")
    deleteBtn:SetSize(60, 20)
    deleteBtn:SetPoint("LEFT",exportBtn,"RIGHT", 25, 0)
    deleteBtn:SetText("Delete")
    deleteBtn:SetScript("OnClick", function()
        table.remove(GDKPT_RaidLeader_Core_SavedSnapshots, index)
        if GDKPT.RaidLeader.Export.LoadedSnapshot == snapshot then
            GDKPT.RaidLeader.Export.LoadedSnapshot = nil
        end
        SnapUI:Refresh()
    end)

    return line
end


------------------------------------------------------------
-- Refresh snapshot list UI
------------------------------------------------------------
function SnapUI:Refresh()
    self:CreateFrame()

    local content = self.content

    -- Clear previous children
    for _, child in ipairs({content:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    local snapshots = GDKPT_RaidLeader_Core_SavedSnapshots
    local y = -5

    for i, snap in ipairs(snapshots) do
        local entry = self:CreateSnapshotEntry(content, i, snap)
        entry:SetPoint("TOPLEFT", 0, y)
        y = y - 28
    end
end


------------------------------------------------------------
-- Public function to show UI
------------------------------------------------------------
function GDKPT.RaidLeader.RaidSnapshots.ShowUI()
    SnapUI:CreateFrame()
    SnapUI:Refresh()
    SnapUI.frame:Show()
end

------------------------------------------------------------
-- Unload snapshot
------------------------------------------------------------
function GDKPT.RaidLeader.RaidSnapshots.UnloadSnapshot()
    GDKPT.RaidLeader.Export.LoadedSnapshot = nil
    print(GDKPT.RaidLeader.Core.addonPrintString .. "Snapshot unloaded.")
    SnapUI:Refresh()
end












-------------------------------------------------------------------
-- Save current raid state as snapshot
-------------------------------------------------------------------


function GDKPT.RaidLeader.RaidSnapshots.SaveSnapshot(snapshotName)
    if not snapshotName or snapshotName == "" then
        snapshotName = date("%d-%m-%Y %H:%M")
    end
    
    local snapshot = {
        timestamp = time(),
        name = snapshotName,
        pot = GDKPT.RaidLeader.Core.GDKP_Pot,
        splitCount = GDKPT.RaidLeader.Core.ExportSplitCount,
        activeAuctions = {},
        playerBalances = {},
        playerWonItems = {},
        auctionedItems = {},
    }
    
    -- Deep copy active auctions
    for id, auction in pairs(GDKPT.RaidLeader.Core.ActiveAuctions) do
        snapshot.activeAuctions[id] = {
            id = auction.id,
            itemID = auction.itemID,
            itemLink = auction.itemLink,
            currentBid = auction.currentBid,
            topBidder = auction.topBidder,
            hasEnded = auction.hasEnded,
            stackCount = auction.stackCount,
        }
    end
    
    -- Deep copy balances
    for name, balance in pairs(GDKPT.RaidLeader.Core.PlayerBalances) do
        snapshot.playerBalances[name] = balance
    end
    
    -- Deep copy won items
    for name, items in pairs(GDKPT.RaidLeader.Core.PlayerWonItems) do
        snapshot.playerWonItems[name] = {}
        for _, item in ipairs(items) do
            table.insert(snapshot.playerWonItems[name], {
                auctionId = item.auctionId,
                itemID = item.itemID,
                itemLink = item.itemLink,
                price = item.price,
                fullyTraded = item.fullyTraded,
            })
        end
    end
    
    -- Save snapshot
    table.insert(GDKPT_RaidLeader_Core_SavedSnapshots, snapshot)
    
    print(string.format(GDKPT.RaidLeader.Core.addonPrintString .. "Raid Saved as %s .", snapshotName))
    return #GDKPT_RaidLeader_Core_SavedSnapshots
end

-------------------------------------------------------------------
-- Load snapshot by index
-------------------------------------------------------------------
function GDKPT.RaidLeader.RaidSnapshots.LoadSnapshot(index)
    local snapshot = GDKPT_RaidLeader_Core_SavedSnapshots[index]
    if not snapshot then
        print(GDKPT.RaidLeader.Core.errorPrintString .. "Raid not found.")
        return false
    end
    
    -- Restore data (without clearing current session)
    GDKPT.RaidLeader.Export.LoadedSnapshot = snapshot
    
    print(string.format(GDKPT.RaidLeader.Core.addonPrintString .. "Loaded Raid: %s", snapshot.name))
    return true
end