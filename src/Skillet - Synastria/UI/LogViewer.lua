-- LogViewer.lua: UI for displaying and copying SkilletLog entries
-- Provides a copyable dialog for diagnostic logs with group navigation

---Shows the log viewer frame and populates it with current logs
function Skillet:LogViewer_OnShow()
    self:LogViewer_RefreshDisplay()
end

---Refreshes the log display with current group's logs
function Skillet:LogViewer_RefreshDisplay()
    ---@type EditBox|nil
    local editBox = SkilletLogViewerEditBox
    ---@type FontString|nil
    local groupLabel = SkilletLogViewerGroupLabel

    if not editBox then
        self:Print("|cFFFF0000Error:|r LogViewer EditBox not found!")
        return
    end

    -- Get current group name and log text
    local groupName = SkilletLog:GetCurrentGroup() or "Main"
    local entryCount = SkilletLog:GetEntryCount()
    local logText = ""

    if SkilletLog and SkilletLog.groups then
        logText = SkilletLog:Export()
    else
        logText = "[No logs available - SkilletLog not initialized]"
    end

    -- Update group label
    if groupLabel then
        groupLabel:SetText(groupName .. " (" .. entryCount .. " entries)")
    end

    -- Set the text
    editBox:SetText(logText)
    editBox:HighlightText(0, 0) -- Clear any selection initially
    editBox:SetCursorPosition(0) -- Move cursor to start
end

---Navigates to previous log group
function Skillet:LogViewer_PrevGroup()
    if SkilletLog then
        SkilletLog:PreviousGroup()
        self:LogViewer_RefreshDisplay()
    end
end

---Navigates to next log group
function Skillet:LogViewer_NextGroup()
    if SkilletLog then
        SkilletLog:NextGroup()
        self:LogViewer_RefreshDisplay()
    end
end

---Selects all text in the log viewer for easy copying
function Skillet:LogViewer_CopyAll()
    ---@type EditBox|nil
    local editBox = SkilletLogViewerEditBox
    if not editBox then
        self:Print("|cFFFF0000Error:|r LogViewer EditBox not found!")
        return
    end

    -- Highlight all text and set focus so user can Ctrl+C
    editBox:SetFocus()
    editBox:HighlightText()

    -- Inform the user
    self:Print("|cFF00FF00Log text selected!|r Press Ctrl+C to copy.")
end

---Clears the log and refreshes the viewer
function Skillet:LogViewer_ClearLog()
    if SkilletLog then
        SkilletLog:Clear()
        self:Print("|cFF00FF00Log cleared.|r")
        self:LogViewer_RefreshDisplay()
    else
        self:Print("|cFFFF0000Error:|r SkilletLog not found!")
    end
end

---Opens the log viewer frame (called via slash command)
---@param groupName? string Optional group name to switch to
function Skillet:ShowLogViewer(groupName)
    -- Switch to specified group if provided
    if groupName and SkilletLog then
        SkilletLog:SetCurrentGroup(groupName)
    end

    if SkilletLogViewerFrame then
        SkilletLogViewerFrame:Show()
    else
        self:Print("|cFFFF0000Error:|r LogViewer frame not found!")
    end
end
