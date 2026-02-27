-- SkilletLog.lua: Persistent logging system that doesn't depend on chat frames
-- This logs to a table that can be dumped via /skillet log
-- Supports multiple log groups for different categories of diagnostic output

-- Create global log table immediately
---@class SkilletLogEntry
---@field time string Timestamp
---@field level string Log level (INFO, WARN, ERROR, SUCCESS)
---@field message string Log message

---@class SkilletLogClass
---@field groups table<string, SkilletLogEntry[]> Log groups (by category name)
---@field currentGroup string Currently selected group name
---@field groupOrder string[] Order of groups for navigation
---@field maxEntriesPerGroup number Maximum entries per group
---@field initialized boolean Whether the log system is initialized

---@type SkilletLogClass
SkilletLog = SkilletLog or {
    groups = { ["Main"] = {} }, -- Default group
    currentGroup = "Main",
    groupOrder = { "Main" },
    maxEntriesPerGroup = 500,
    initialized = false
}

-- Add log entry to specified group (safe to call before Skillet addon loads)
---@param message string The log message
---@param level? string The log level (INFO, WARN, ERROR, SUCCESS)
---@param group? string The log group/category (default: "Main")
function SkilletLog:Add(message, level, group)
    level = level or "INFO"
    group = group or "Main"

    -- Use GetTime() which returns seconds since client start
    ---@type string
    local timestamp = string.format("%.3fs", GetTime())

    ---@type SkilletLogEntry
    local entry = {
        time = timestamp,
        level = level,
        message = message
    }

    -- Create group if it doesn't exist
    if not self.groups[group] then
        self.groups[group] = {}
        table.insert(self.groupOrder, group)
    end

    table.insert(self.groups[group], entry)

    -- Trim old entries if we exceed max for this group
    while #self.groups[group] > self.maxEntriesPerGroup do
        table.remove(self.groups[group], 1)
    end

    -- Also try to print to chat if available (only for Main group to avoid spam)
    if DEFAULT_CHAT_FRAME and group == "Main" then
        local color = "|cFFFFFFFF"
        if level == "ERROR" then
            color = "|cFFFF0000"
        elseif level == "WARN" then
            color = "|cFFFFAA00"
        elseif level == "SUCCESS" then
            color = "|cFF00FF00"
        elseif level == "INFO" then
            color = "|cFF00FFFF"
        end
        DEFAULT_CHAT_FRAME:AddMessage(color .. "[" .. timestamp .. "] " .. message .. "|r")
    end
end

-- Dump all logs from current group to chat
function SkilletLog:Dump()
    if not DEFAULT_CHAT_FRAME then
        return
    end

    local group = self.currentGroup
    local entries = self.groups[group] or {}

    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF========== Skillet Log Dump [" .. group .. "] ==========|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFF" .. #entries .. " log entries in group '" .. group .. "':|r")

    ---@type SkilletLogEntry
    for i, entry in ipairs(entries) do
        local color = "|cFFFFFFFF"
        if entry.level == "ERROR" then
            color = "|cFFFF0000"
        elseif entry.level == "WARN" then
            color = "|cFFFFAA00"
        elseif entry.level == "SUCCESS" then
            color = "|cFF00FF00"
        end

        DEFAULT_CHAT_FRAME:AddMessage(color .. "[" .. entry.time .. "] " .. entry.level .. ": " .. entry.message .. "|r")
    end

    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF" .. string.rep("=", 50) .. "|r")
end

-- Clear logs from current group
function SkilletLog:Clear()
    local group = self.currentGroup
    if self.groups[group] then
        self.groups[group] = {}
    end
end

-- Clear all logs from all groups
function SkilletLog:ClearAll()
    for groupName, _ in pairs(self.groups) do
        self.groups[groupName] = {}
    end
end

-- Export current group to string for copy/paste
---@return string logText The formatted log text
function SkilletLog:Export()
    local group = self.currentGroup
    local entries = self.groups[group] or {}

    ---@type string
    local output = "========== Skillet Log Export [" .. group .. "] ==========\n"
    output = output .. "Group: " .. group .. "\n"
    output = output .. "Entries: " .. #entries .. "\n"
    output = output .. string.rep("=", 50) .. "\n\n"

    for i, entry in ipairs(entries) do
        output = output .. "[" .. entry.time .. "] [" .. entry.level .. "] " .. entry.message .. "\n"
    end

    output = output .. "\n" .. string.rep("=", 50) .. "\n"
    output = output .. "End of log export\n"

    return output
end

-- Get list of all group names
---@return string[] groupNames Array of group names
function SkilletLog:GetGroupNames()
    return self.groupOrder
end

-- Get current group name
---@return string groupName Current group name
function SkilletLog:GetCurrentGroup()
    return self.currentGroup
end

-- Set current group
---@param groupName string The group name to switch to
function SkilletLog:SetCurrentGroup(groupName)
    if self.groups[groupName] then
        self.currentGroup = groupName
    end
end

-- Navigate to next group
function SkilletLog:NextGroup()
    local currentIndex = 1
    for i, name in ipairs(self.groupOrder) do
        if name == self.currentGroup then
            currentIndex = i
            break
        end
    end

    local nextIndex = currentIndex + 1
    if nextIndex > #self.groupOrder then
        nextIndex = 1 -- Wrap around
    end

    self.currentGroup = self.groupOrder[nextIndex]
end

-- Navigate to previous group
function SkilletLog:PreviousGroup()
    local currentIndex = 1
    for i, name in ipairs(self.groupOrder) do
        if name == self.currentGroup then
            currentIndex = i
            break
        end
    end

    local prevIndex = currentIndex - 1
    if prevIndex < 1 then
        prevIndex = #self.groupOrder -- Wrap around
    end

    self.currentGroup = self.groupOrder[prevIndex]
end

-- Get entry count for current group
---@return number count Number of entries in current group
function SkilletLog:GetEntryCount()
    local group = self.currentGroup
    return #(self.groups[group] or {})
end

-- Initialize
SkilletLog:Add("SkilletLog.lua loaded", "INFO", "Debug")
