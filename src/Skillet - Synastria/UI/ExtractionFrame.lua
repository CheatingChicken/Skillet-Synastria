--[[
Skillet: Extraction Frame
Shows prospecting and milling data organized by target items
]]--

local L = AceLibrary("AceLocale-2.2"):new("Skillet")

-- Stolen from the Waterfall Ace2 addon.
local ControlBackdrop  = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

local FrameBackdrop = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 3, right = 3, top = 30, bottom = 3 }
}

-- Current tab: "MILLING" or "PROSPECTING"
local currentTab = "MILLING"

-- Track if frame has been initialized
local frameInitialized = false

-- Bulk mode flag (default true)
local bulkMode = true

-- ========================================
-- BUILD REVERSE MAPS
-- ========================================

-- Build map of pigment -> herbs
local function buildMillingMap()
	local pigmentToHerbs = {}
	
	for herbId, data in pairs(Skillet.MILLING_DATA) do
		-- Only process common pigments (rare pigments are attached to them)
		if data.commonPigments then
			for _, pigmentId in ipairs(data.commonPigments) do
				pigmentToHerbs[pigmentId] = pigmentToHerbs[pigmentId] or {
					type = "common",
					herbs = {},
					rarePigments = {}
				}
				table.insert(pigmentToHerbs[pigmentId].herbs, herbId)
				
				-- Track rare pigments that come from this herb
				if data.rarePigments and #data.rarePigments > 0 then
					for _, rareId in ipairs(data.rarePigments) do
						-- Add rare pigment if not already in the list
						local found = false
						for _, existingRare in ipairs(pigmentToHerbs[pigmentId].rarePigments) do
							if existingRare == rareId then
								found = true
								break
							end
						end
						if not found then
							table.insert(pigmentToHerbs[pigmentId].rarePigments, rareId)
						end
					end
				end
			end
		end
	end
	
	return pigmentToHerbs
end

-- Build map of gem -> ores
local function buildProspectingMap()
	local gemToOres = {}
	
	for oreId, data in pairs(Skillet.PROSPECTING_DATA) do
		-- Add to common gems map
		if data.commonGems then
			for _, gemId in ipairs(data.commonGems) do
				gemToOres[gemId] = gemToOres[gemId] or {
					type = "common",
					ores = {}
				}
				table.insert(gemToOres[gemId].ores, oreId)
			end
		end
		
		-- Add to uncommon gems map
		if data.uncommonGems then
			for _, gemId in ipairs(data.uncommonGems) do
				gemToOres[gemId] = gemToOres[gemId] or {
					type = "uncommon",
					ores = {}
				}
				table.insert(gemToOres[gemId].ores, oreId)
			end
		end
	end
	
	return gemToOres
end

-- ========================================
-- LAYOUT CONSTANTS AND INITIALIZATION
-- ========================================

-- Fixed layout constants
local ITEM_WIDTH = 52
local ITEM_HEIGHT = 68
local ITEM_SPACING = 10
local ROW_SPACING = 5
local BORDER_EDGE_SIZE = 12
local GROUP_PADDING = 8
local GROUP_SPACING = 20

-- Layout: 2 groups, each with 18 buttons (6 results + 12 sources)
-- Group 1: Buttons 1-18, Group 2: Buttons 19-36
local BUTTONS_PER_GROUP = 18
local RESULT_BUTTONS_PER_GROUP = 6
local SOURCE_BUTTONS_PER_ROW = 6

local scrollData = {}
local groupBorders = {}

-- Initialize fixed button positions (called once on frame creation)
local function initializeButtonPositions()
	local totalInset = BORDER_EDGE_SIZE / 2 + GROUP_PADDING
	
	for groupNum = 0, 1 do -- Two groups
		local buttonOffset = groupNum * BUTTONS_PER_GROUP
		local groupY = -5 - (groupNum * (totalInset * 2 + ITEM_HEIGHT + 2 * (ITEM_HEIGHT + ROW_SPACING) + GROUP_SPACING))
		
		-- Create border for this group
		if not groupBorders[groupNum + 1] then
			local border = CreateFrame("Frame", nil, SkilletExtractionListParent)
			border:SetBackdrop({
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				edgeSize = BORDER_EDGE_SIZE,
				insets = { left = 2, right = 2, top = 2, bottom = 2 }
			})
			border:SetBackdropBorderColor(0.6, 0.6, 0.6, 0.8)
			border:SetPoint("TOPLEFT", SkilletExtractionListScrollFrame, "TOPLEFT", 2, groupY)
			
			-- Size border for content:
			-- Group 0: 6 results + 5 source rows (extended layout for Titanium)
			-- Group 1: 6 results + 2 source rows (normal layout)
			local borderWidth = (totalInset * 2) + (SOURCE_BUTTONS_PER_ROW * ITEM_WIDTH) + ((SOURCE_BUTTONS_PER_ROW - 1) * ITEM_SPACING)
			local sourceRows = (groupNum == 0) and 5 or 2
			local borderHeight = (totalInset * 2) + ITEM_HEIGHT + (sourceRows * (ITEM_HEIGHT + ROW_SPACING))
			border:SetWidth(borderWidth)
			border:SetHeight(borderHeight)
			
			groupBorders[groupNum + 1] = border
		end
		
		local border = groupBorders[groupNum + 1]
		
		-- Position result row buttons (6 buttons)
		for i = 1, RESULT_BUTTONS_PER_GROUP do
			local buttonIndex = buttonOffset + i
			local button = getglobal("SkilletExtractionListButton" .. buttonIndex)
			if button then
				button:ClearAllPoints()
				if i == 1 then
					button:SetPoint("TOPLEFT", border, "TOPLEFT", totalInset, -totalInset)
				else
					button:SetPoint("LEFT", getglobal("SkilletExtractionListButton" .. (buttonIndex - 1)), "RIGHT", ITEM_SPACING, 0)
				end
			end
		end
		
		-- Position source row buttons
		-- Group 0: 30 buttons (5 rows of 6) for extended layout (Titanium Ore)
		-- Group 1: 12 buttons (2 rows of 6) for normal layout
		local maxRows = (groupNum == 0) and 4 or 1 -- Group 0 gets 5 rows (0-4), Group 1 gets 2 rows (0-1)
		for row = 0, maxRows do
			for col = 1, SOURCE_BUTTONS_PER_ROW do
				local sourceIndex = RESULT_BUTTONS_PER_GROUP + (row * SOURCE_BUTTONS_PER_ROW) + col
				local buttonIndex = buttonOffset + sourceIndex
				local button = getglobal("SkilletExtractionListButton" .. buttonIndex)
				if button then
					button:ClearAllPoints()
					if col == 1 then
						-- First in row - anchor to border
						local yOffset = -totalInset - (ITEM_HEIGHT + ROW_SPACING) - (row * (ITEM_HEIGHT + ROW_SPACING))
						button:SetPoint("TOPLEFT", border, "TOPLEFT", totalInset, yOffset)
					else
						-- Subsequent in row - anchor to previous
						button:SetPoint("LEFT", getglobal("SkilletExtractionListButton" .. (buttonIndex - 1)), "RIGHT", ITEM_SPACING, 0)
					end
				end
			end
		end
	end
end

-- ========================================
-- UI CREATION
-- ========================================

local function createExtractionFrame(self)
	local frame = SkilletExtractionFrame
	if not frame then
		DEFAULT_CHAT_FRAME:AddMessage("ERROR: SkilletExtractionFrame not found!")
		return nil
	end
	
	DEFAULT_CHAT_FRAME:AddMessage("Initializing Extraction Frame...")
	
	frame:SetBackdrop(FrameBackdrop)
	frame:SetBackdropColor(0.1, 0.1, 0.1)
	
	-- Title bar
	local r,g,b = 0, 0.7, 0
	local titlebar = frame:CreateTexture(nil,"BACKGROUND")
	local titlebar2 = frame:CreateTexture(nil,"BACKGROUND")
	
	titlebar:SetPoint("TOPLEFT",frame,"TOPLEFT",3,-4)
	titlebar:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-3,-4)
	titlebar:SetHeight(13)
	
	titlebar2:SetPoint("TOPLEFT",titlebar,"BOTTOMLEFT",0,0)
	titlebar2:SetPoint("TOPRIGHT",titlebar,"BOTTOMRIGHT",0,0)
	titlebar2:SetHeight(13)
	
	titlebar:SetGradientAlpha("VERTICAL",r*0.6,g*0.6,b*0.6,1,r,g,b,1)
	titlebar:SetTexture(r,g,b,1)
	titlebar2:SetGradientAlpha("VERTICAL",r*0.9,g*0.9,b*0.9,1,r*0.6,g*0.6,b*0.6,1)
	titlebar2:SetTexture(r,g,b,1)
	
	local title = CreateFrame("Frame",nil,frame)
	title:SetPoint("TOPLEFT",titlebar,"TOPLEFT",0,0)
	title:SetPoint("BOTTOMRIGHT",titlebar2,"BOTTOMRIGHT",0,0)
	
	local titletext = title:CreateFontString("SkilletExtractionTitleText", "OVERLAY", "GameFontNormalLarge")
	titletext:SetPoint("TOPLEFT",title,"TOPLEFT",0,0)
	titletext:SetPoint("TOPRIGHT",title,"TOPRIGHT",0,0)
	titletext:SetHeight(26)
	titletext:SetShadowColor(0,0,0)
	titletext:SetShadowOffset(1,-1)
	titletext:SetTextColor(1,1,1)
	titletext:SetText("Skillet: Extraction")
	
	-- Add instructions text in top right
	local instructionsText = title:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	instructionsText:SetPoint("TOPRIGHT", title, "TOPRIGHT", -5, -6)
	instructionsText:SetTextColor(0.7, 0.7, 0.7)
	instructionsText:SetText("Left Click: Withdraw/Process  |  Right Click: Deposit")
	instructionsText:SetJustifyH("RIGHT")
	
	-- Scroll frame backdrop
	local backdrop = SkilletExtractionListParent
	if backdrop then
		DEFAULT_CHAT_FRAME:AddMessage("Setting backdrop on SkilletExtractionListParent...")
		backdrop:SetBackdrop(ControlBackdrop)
		backdrop:SetBackdropBorderColor(0.6, 0.6, 0.6)
		backdrop:SetBackdropColor(0.05, 0.05, 0.05)
		backdrop:Show() -- Ensure parent is shown
	else
		DEFAULT_CHAT_FRAME:AddMessage("ERROR: SkilletExtractionListParent not found!")
	end
	
	-- Ensure scroll frame is shown
	local scrollFrame = SkilletExtractionListScrollFrame
	if scrollFrame then
		DEFAULT_CHAT_FRAME:AddMessage("Showing SkilletExtractionListScrollFrame...")
		scrollFrame:Show()
	else
		DEFAULT_CHAT_FRAME:AddMessage("ERROR: SkilletExtractionListScrollFrame not found!")
	end
	
	DEFAULT_CHAT_FRAME:AddMessage("Extraction Frame initialized.")
	
	-- Initialize bulk mode checkbox to checked state
	if SkilletExtractionBulkModeCheckbox then
		SkilletExtractionBulkModeCheckbox:SetChecked(true)
		
		-- Check if label exists, if not create it
		local label = getglobal("SkilletExtractionBulkModeLabel")
		if not label then
			label = SkilletExtractionFrame:CreateFontString("SkilletExtractionBulkModeLabel", "OVERLAY", "GameFontNormal")
			label:SetPoint("LEFT", SkilletExtractionBulkModeCheckbox, "RIGHT", 4, 0)
			label:SetText("Bulk Mode")
		end
	end
	
	-- Initialize button positions (only needs to be done once)
	initializeButtonPositions()
	
	-- Register frame to close on escape key
	table.insert(UISpecialFrames, "SkilletExtractionFrame")
	
	return frame
end

-- ========================================
-- SCROLL DATA CREATION
-- ========================================

local function createMillingScrollData()
	local data = {}
	local pigmentMap = buildMillingMap()
	
	DEFAULT_CHAT_FRAME:AddMessage("Building milling data...")
	
	-- Sort pigments by ID for consistent display
	local pigmentIds = {}
	for pigmentId in pairs(pigmentMap) do
		table.insert(pigmentIds, pigmentId)
	end
	table.sort(pigmentIds)
	
	DEFAULT_CHAT_FRAME:AddMessage("Found " .. #pigmentIds .. " pigments")
	
	for _, pigmentId in ipairs(pigmentIds) do
		local info = pigmentMap[pigmentId]
		local pigmentName = GetItemInfo(pigmentId) or ("Pigment "..pigmentId)
		
		DEFAULT_CHAT_FRAME:AddMessage("  Pigment: " .. pigmentName .. " with " .. #info.herbs .. " herbs")
		
		-- Create group entry with result and sources
		table.insert(data, {
			type = "group",
			result = {
				itemId = pigmentId,
				name = pigmentName,
				rarity = info.type,
				rarePigments = info.rarePigments
			},
			sources = info.herbs
		})
	end
	
	DEFAULT_CHAT_FRAME:AddMessage("Created " .. #data .. " milling groups")
	return data
end

local function createProspectingScrollData()
	local data = {}
	
	DEFAULT_CHAT_FRAME:AddMessage("Building prospecting data by ore tiers...")
	
	-- Define ore tier groups
	-- IMPORTANT: Only group ores that share ALL their output gems (even if drop rates differ)
	-- IMPORTANT: Titanium separate because it has 18 possible gems (needs special layout)
	local oreTiers = {
		{
			name = "Copper Ore",
			ores = {2770}, -- Copper Ore
			expansion = "vanilla"
		},
		{
			name = "Tin Ore",
			ores = {2771}, -- Tin Ore
			expansion = "vanilla"
		},
		{
			name = "Iron Ore",
			ores = {2772}, -- Iron Ore
			expansion = "vanilla"
		},
		{
			name = "Mithril Ore",
			ores = {3858}, -- Mithril Ore
			expansion = "vanilla"
		},
		{
			name = "Thorium Ore",
			ores = {10620}, -- Thorium Ore
			expansion = "vanilla"
		},
		{
			name = "Fel Iron/Adamantite",
			ores = {23424, 23425}, -- Fel Iron Ore, Adamantite Ore (share same gems)
			expansion = "tbc"
		},
		{
			name = "Cobalt Ore",
			ores = {36909}, -- Cobalt Ore (23% common, 1.3% uncommon)
			expansion = "wrath"
		},
		{
			name = "Saronite Ore",
			ores = {36912}, -- Saronite Ore (18% common, 4% uncommon)
			expansion = "wrath"
		},
		{
			name = "Titanium Ore",
			ores = {36910}, -- Titanium Ore (18 total gems! - needs extended layout)
			expansion = "wrath",
			extended = true -- Flag for special layout
		}
	}
	
	-- Build groups based on ore tiers
	for _, tier in ipairs(oreTiers) do
		-- Collect all unique gems that can come from ANY ore in this tier
		local gemSet = {}
		
		for _, oreId in ipairs(tier.ores) do
			local oreData = Skillet.PROSPECTING_DATA[oreId]
			if oreData then
				-- Add common gems
				if oreData.commonGems then
					for _, gemId in ipairs(oreData.commonGems) do
						gemSet[gemId] = "common"
					end
				end
				-- Add uncommon gems (overwrite rarity if already exists)
				if oreData.uncommonGems then
					for _, gemId in ipairs(oreData.uncommonGems) do
						gemSet[gemId] = "uncommon"
					end
				end
			end
		end
		
		-- Convert gem set to sorted list
		local gems = {}
		for gemId, rarity in pairs(gemSet) do
			table.insert(gems, {id = gemId, rarity = rarity})
		end
		
		-- Sort gems by ID for consistent display
		table.sort(gems, function(a, b) return a.id < b.id end)
		
		if #gems > 0 then
			DEFAULT_CHAT_FRAME:AddMessage("  Tier: " .. tier.name .. " (" .. tier.expansion .. ") with " .. #gems .. " gems" .. (tier.extended and " [EXTENDED]" or ""))
			
			-- Create group entry:
			-- Result row = the ores in this tier
			-- Source rows = all gems these ores can produce
			table.insert(data, {
				type = "group",
				tierName = tier.name,
				expansion = tier.expansion,
				ores = tier.ores, -- The ores shown in result row
				gems = gems,      -- The gems shown in source rows
				extended = tier.extended -- Special flag for Titanium
			})
		end
	end
	
	DEFAULT_CHAT_FRAME:AddMessage("Created " .. #data .. " ore tier groups")
	return data
end

function Skillet:UpdateExtractionList()
	if currentTab == "MILLING" then
		scrollData = createMillingScrollData()
	else
		scrollData = createProspectingScrollData()
	end
	
	DEFAULT_CHAT_FRAME:AddMessage("Extraction list updated: " .. #scrollData .. " items for " .. currentTab)
	
	-- Update scroll frame
	local scrollFrame = SkilletExtractionListScrollFrame
	if scrollFrame then
		local totalGroups = #scrollData
		local groupsToShow = math.min(2, totalGroups) -- Show up to 2 groups, but not more than available
		
		-- Use a fixed average height estimate (max case: 2 rows of 6 items)
		-- Border inset + result row + 2 source rows with spacing
		local totalInset = (BORDER_EDGE_SIZE / 2 + GROUP_PADDING)
		local maxGroupHeight = (totalInset * 2) + ITEM_HEIGHT + (2 * (ITEM_HEIGHT + ROW_SPACING))
		
		-- If we have 2 or fewer groups, disable scrolling by showing all items
		-- If we have more than 2, enable scrolling
		if totalGroups <= groupsToShow then
			-- No scrolling needed - show all groups
			FauxScrollFrame_Update(scrollFrame, totalGroups, totalGroups, maxGroupHeight)
		else
			-- Scrolling needed - show 2 at a time, scroll range is 0 to (totalGroups - 2)
			FauxScrollFrame_Update(scrollFrame, totalGroups, groupsToShow, maxGroupHeight)
		end
		
		self:UpdateExtractionListDisplay()
	end
end

-- ========================================
-- EVENT HANDLERS
-- ========================================

-- Handle bag updates to refresh item counts
local function onBagUpdate()
	if SkilletExtractionFrame and SkilletExtractionFrame:IsVisible() then
		Skillet:UpdateExtractionListDisplay()
	end
end

-- ========================================
-- CLICK HANDLERS FOR SOURCE ITEMS
-- ========================================

-- Helper: Find first stack of an item in bags
-- Returns bag, slot or nil if not found
local function GetItemContainerAndSlot(itemId)
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local _, count, _, _, _, _, link = GetContainerItemInfo(bag, slot)
			if link then
				local foundItemId = Skillet:GetItemIDFromLink(link)
				if foundItemId == itemId then
					return bag, slot
				end
			end
		end
	end
	return nil, nil
end

-- Setup click handler for a source button
local function setupSourceButtonClicks(button, sourceId)
	if not button then return end
	
	-- Enable the button
	button:Enable()
	
	-- Register for left and right clicks
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	
	-- Set up SecureActionButton attributes for left-click spell casting
	-- Check if we have >= 5 items to determine whether to cast or withdraw
	local bagsCount = GetItemCount(sourceId, false) or 0
	
	if bagsCount >= 5 then
		-- Enough items: set up spell casting
		-- Use spell IDs for reliability (names can vary with localization)
		-- Milling: 51005 (regular), 80348 (Mass Milling)
		-- Prospecting: 31252 (regular), 80347 (Mass Prospecting)
		local spellId
		if currentTab == "MILLING" then
			spellId = bulkMode and 80348 or 51005
		else -- PROSPECTING
			spellId = bulkMode and 80347 or 31252
		end
		
		-- Get the item's bag and slot
		local bag, slot = GetItemContainerAndSlot(sourceId)
		
		if bag and slot then
			-- Configure SecureActionButton to cast spell on the item
			button:SetAttribute("type1", "spell")
			button:SetAttribute("spell", spellId)
			button:SetAttribute("target-bag", bag)
			button:SetAttribute("target-slot", slot)
			
			-- Use PreClick to schedule the item click after spell cast
			button:SetScript("PreClick", function(self, mouseButton)
				if mouseButton == "LeftButton" then
					local targetBag = self:GetAttribute("target-bag")
					local targetSlot = self:GetAttribute("target-slot")
					if targetBag and targetSlot then
						-- Schedule the item click after spell is cast (0.05s delay)
						Skillet:ScheduleEvent("Skillet_UseItem_" .. sourceId, function()
							-- Check if we have a spell cursor active
							local cursorType = GetCursorInfo()
							if cursorType == "spell" then
								UseContainerItem(targetBag, targetSlot)
							end
						end, 0.05)
					end
				end
			end)
		else
			-- Couldn't find item in bags, clear spell casting
			button:SetAttribute("type1", nil)
			button:SetAttribute("spell", nil)
			button:SetScript("PreClick", nil)
		end
	else
		-- Not enough items: clear spell attributes and use regular handler
		button:SetAttribute("type1", nil)
		button:SetAttribute("spell", nil)
		button:SetScript("PreClick", nil)
	end
	
	-- Right-click and left-click fallback (when not enough items) use PostClick
	button:SetScript("PostClick", function(self, mouseButton)
		if mouseButton == "LeftButton" then
			local currentBagsCount = GetItemCount(sourceId, false) or 0
			if currentBagsCount < 5 then
				-- Not enough items, withdraw from resource bank
				local itemName = GetItemInfo(sourceId) or "item"
				Skillet:Print("|cFF00FF00Withdrawing " .. itemName .. " from Resource Bank...|r")
				Skillet:WithdrawFromResourceBank(sourceId, true)
			else
				-- We had >= 5 items but spell didn't cast - provide feedback
				local itemName = GetItemInfo(sourceId) or "item"
				local spellId = currentTab == "MILLING" and (bulkMode and 80348 or 51005) or (bulkMode and 80347 or 31252)
				local spellName = GetSpellInfo(spellId) or ("Spell " .. spellId)
				Skillet:Print("|cFFFF0000Attempted to cast " .. spellName .. " (ID:" .. spellId .. ") on " .. itemName .. "|r")
			end
		elseif mouseButton == "RightButton" then
			-- Right click: Deposit this specific item to resource bank
			local itemName = GetItemInfo(sourceId) or "item"
			Skillet:Print("|cFF00FF00Depositing " .. itemName .. " to Resource Bank...|r")
			Skillet:DepositToResourceBank(sourceId, true)
		end
	end)
end

function Skillet:UpdateExtractionListDisplay()
	local offset = FauxScrollFrame_GetOffset(SkilletExtractionListScrollFrame)
	
	-- Hide all buttons first
	for i = 1, 36 do
		local button = getglobal("SkilletExtractionListButton" .. i)
		if button then
			button:Hide()
		end
	end
	
	-- Show/hide borders
	for i = 1, 2 do
		if groupBorders[i] then
			groupBorders[i]:Hide()
		end
	end
	
	-- Check if first group at offset is extended (Titanium Ore)
	-- Extended groups take up entire display (all 36 buttons)
	local firstGroup = scrollData[offset + 1]
	local isExtendedDisplay = firstGroup and firstGroup.extended
	
	-- Populate groups: 1 extended group OR 2 normal groups
	local displaySlots = isExtendedDisplay and 0 or 1 -- 0-0 for extended, 0-1 for normal
	
	for displaySlot = 0, displaySlots do
		local groupIndex = offset + displaySlot + 1
		local group = scrollData[groupIndex]
		
		-- Handle both old milling format (group.result) and new prospecting format (group.ores/gems)
		if group and (group.result or group.ores) then
			-- Show border for this group
			if groupBorders[displaySlot + 1] then
				groupBorders[displaySlot + 1]:Show()
			end
			
			local buttonOffset = displaySlot * BUTTONS_PER_GROUP
			
			-- MILLING: group.result exists (single pigment + rare pigments)
			-- PROSPECTING: group.ores exists (ores in result row, gems in source rows)
			if currentTab == "MILLING" and group.result then
				-- Populate main result button (button 1 or 19)
				local resultButton = getglobal("SkilletExtractionListButton" .. (buttonOffset + 1))
				if resultButton then
					resultButton:Show()
					
					local icon = getglobal("SkilletExtractionListButton" .. (buttonOffset + 1) .. "Icon")
					local label = getglobal("SkilletExtractionListButton" .. (buttonOffset + 1) .. "Label")
					local countOwned = getglobal("SkilletExtractionListButton" .. (buttonOffset + 1) .. "CountOwned")
					local countBank = getglobal("SkilletExtractionListButton" .. (buttonOffset + 1) .. "CountBank")
					
					if icon then
						local itemTexture = GetItemIcon(group.result.itemId)
						if itemTexture then icon:SetTexture(itemTexture) end
					end
					if label then
						local itemName = GetItemInfo(group.result.itemId)
						label:SetText(itemName or "")
					end
					
					-- Bags count (bottom right, green)
					local owned = GetItemCount(group.result.itemId, false)
					if countOwned then
						countOwned:SetText(owned or 0)
						countOwned:SetTextColor(0.25, 0.75, 0.25)
					end
					
					-- Synastria Resource Bank count (bottom left, yellow)
					local rbank = 0
					if GetCustomGameData then
						rbank = GetCustomGameData(13, group.result.itemId) or 0
					end
					if countBank then
						countBank:SetText(rbank or 0)
						countBank:SetTextColor(1, 0.82, 0)
					end
					
					resultButton.itemId = group.result.itemId
				end
				
				-- Populate rare pigment buttons (buttons 2-6 or 20-24)
				if group.result.rarePigments then
					for i, rareId in ipairs(group.result.rarePigments) do
						if i <= 5 then -- Max 5 rare pigments (6 result slots total - 1 for main)
							local rareButton = getglobal("SkilletExtractionListButton" .. (buttonOffset + 1 + i))
							if rareButton then
								rareButton:Show()
								
								local icon = getglobal("SkilletExtractionListButton" .. (buttonOffset + 1 + i) .. "Icon")
								local label = getglobal("SkilletExtractionListButton" .. (buttonOffset + 1 + i) .. "Label")
								local countOwned = getglobal("SkilletExtractionListButton" .. (buttonOffset + 1 + i) .. "CountOwned")
								local countBank = getglobal("SkilletExtractionListButton" .. (buttonOffset + 1 + i) .. "CountBank")
								
								if icon then
									local itemTexture = GetItemIcon(rareId)
									if itemTexture then icon:SetTexture(itemTexture) end
								end
								if label then
									local itemName = GetItemInfo(rareId)
									label:SetText(itemName or "")
								end
								
								-- Bags count (bottom right, cyan for rare)
								local owned = GetItemCount(rareId, false)
								if countOwned then
									countOwned:SetText(owned or 0)
									countOwned:SetTextColor(0.12, 0.8, 1)
								end
								
								-- Synastria Resource Bank count (bottom left, yellow)
								local rbank = 0
								if GetCustomGameData then
									rbank = GetCustomGameData(13, rareId) or 0
								end
								if countBank then
									countBank:SetText(rbank or 0)
									countBank:SetTextColor(1, 0.82, 0)
								end
								
								rareButton.itemId = rareId
							end
						end
					end
				end
				
				-- Populate source buttons (herbs that give this pigment)
				for i, sourceId in ipairs(group.sources) do
					if i <= 12 then -- Max 12 sources (2 rows of 6)
						local sourceButton = getglobal("SkilletExtractionListButton" .. (buttonOffset + RESULT_BUTTONS_PER_GROUP + i))
						if sourceButton then
							sourceButton:Show()
							
							local icon = getglobal("SkilletExtractionListButton" .. (buttonOffset + RESULT_BUTTONS_PER_GROUP + i) .. "Icon")
							local label = getglobal("SkilletExtractionListButton" .. (buttonOffset + RESULT_BUTTONS_PER_GROUP + i) .. "Label")
							local countOwned = getglobal("SkilletExtractionListButton" .. (buttonOffset + RESULT_BUTTONS_PER_GROUP + i) .. "CountOwned")
							local countBank = getglobal("SkilletExtractionListButton" .. (buttonOffset + RESULT_BUTTONS_PER_GROUP + i) .. "CountBank")
							
							if icon then
								local itemTexture = GetItemIcon(sourceId)
								if itemTexture then icon:SetTexture(itemTexture) end
							end
							if label then
								local itemName = GetItemInfo(sourceId)
								label:SetText(itemName or "")
							end
							
							-- Bags count (bottom right, green)
							local owned = GetItemCount(sourceId, false)
							if countOwned then
								countOwned:SetText(owned or 0)
								countOwned:SetTextColor(0.25, 0.75, 0.25)
							end
							
							-- Synastria Resource Bank count (bottom left, yellow)
							local rbank = 0
							if GetCustomGameData then
								rbank = GetCustomGameData(13, sourceId) or 0
							end
							if countBank then
								countBank:SetText(rbank or 0)
								countBank:SetTextColor(1, 0.82, 0)
							end
							
							sourceButton.itemId = sourceId
							
							-- Setup click handlers for withdraw/deposit
							setupSourceButtonClicks(sourceButton, sourceId)
						end
					end
				end
				
			elseif currentTab == "PROSPECTING" and group.ores then
				-- PROSPECTING: Show ores in result row, gems in source rows
				
				-- Populate ore buttons in result row (buttons 1-6 or 19-24)
				for i, oreId in ipairs(group.ores) do
					if i <= RESULT_BUTTONS_PER_GROUP then
						local oreButton = getglobal("SkilletExtractionListButton" .. (buttonOffset + i))
						if oreButton then
							oreButton:Show()
							
							local icon = getglobal("SkilletExtractionListButton" .. (buttonOffset + i) .. "Icon")
							local label = getglobal("SkilletExtractionListButton" .. (buttonOffset + i) .. "Label")
							local countOwned = getglobal("SkilletExtractionListButton" .. (buttonOffset + i) .. "CountOwned")
							local countBank = getglobal("SkilletExtractionListButton" .. (buttonOffset + i) .. "CountBank")
							
							if icon then
								local itemTexture = GetItemIcon(oreId)
								if itemTexture then icon:SetTexture(itemTexture) end
							end
							if label then
								local itemName = GetItemInfo(oreId)
								label:SetText(itemName or "")
							end
							
							-- Bags count (bottom right, green)
							local owned = GetItemCount(oreId, false)
							if countOwned then
								countOwned:SetText(owned or 0)
								countOwned:SetTextColor(0.25, 0.75, 0.25)
							end
							
							-- Synastria Resource Bank count (bottom left, yellow)
							local rbank = 0
							if GetCustomGameData then
								rbank = GetCustomGameData(13, oreId) or 0
							end
							if countBank then
								countBank:SetText(rbank or 0)
								countBank:SetTextColor(1, 0.82, 0)
							end
							
							oreButton.itemId = oreId
						end
					end
				end
				
				-- Populate gem buttons in source rows
				-- Standard layout: 12 gems max (2 rows of 6) - buttons 7-18 or 25-36
				-- Extended layout (Titanium): 30 gems max (5 rows of 6) - uses ALL remaining buttons
				local maxGems = group.extended and 30 or 12
				
				for i, gemData in ipairs(group.gems) do
					if i <= maxGems then
						local gemId = gemData.id
						local gemRarity = gemData.rarity
						local gemButton = getglobal("SkilletExtractionListButton" .. (buttonOffset + RESULT_BUTTONS_PER_GROUP + i))
						if gemButton then
							gemButton:Show()
							
							local icon = getglobal("SkilletExtractionListButton" .. (buttonOffset + RESULT_BUTTONS_PER_GROUP + i) .. "Icon")
							local label = getglobal("SkilletExtractionListButton" .. (buttonOffset + RESULT_BUTTONS_PER_GROUP + i) .. "Label")
							local countOwned = getglobal("SkilletExtractionListButton" .. (buttonOffset + RESULT_BUTTONS_PER_GROUP + i) .. "CountOwned")
							local countBank = getglobal("SkilletExtractionListButton" .. (buttonOffset + RESULT_BUTTONS_PER_GROUP + i) .. "CountBank")
							local border = getglobal("SkilletExtractionListButton" .. (buttonOffset + RESULT_BUTTONS_PER_GROUP + i) .. "Border")
							
							if icon then
								local itemTexture = GetItemIcon(gemId)
								if itemTexture then icon:SetTexture(itemTexture) end
							end
							if label then
								local itemName = GetItemInfo(gemId)
								label:SetText(itemName or "")
							end
							
							-- Set border color by rarity
							if border then
								if gemRarity == "uncommon" then
									-- Epic quality gems (from Titanium only)
									-- Check if it's actually epic by looking at the item
									local _, _, quality = GetItemInfo(gemId)
									if quality and quality == 4 then
										-- Epic (purple border)
										border:SetVertexColor(0.64, 0.21, 0.93, 1)
									else
										-- Uncommon (blue border)
										border:SetVertexColor(0.12, 0.7, 1, 1)
									end
								else
									-- Common (green border)
									border:SetVertexColor(0.25, 0.75, 0.25, 1)
								end
							end
							
							-- Bags count (bottom right, color by rarity)
							local owned = GetItemCount(gemId, false)
							if countOwned then
								countOwned:SetText(owned or 0)
								-- Match border color
								if gemRarity == "uncommon" then
									local _, _, quality = GetItemInfo(gemId)
									if quality and quality == 4 then
										countOwned:SetTextColor(0.64, 0.21, 0.93) -- Purple for epic
									else
										countOwned:SetTextColor(0.12, 0.7, 1) -- Blue for uncommon
									end
								else
									countOwned:SetTextColor(0.25, 0.75, 0.25) -- Green for common
								end
							end
							
							-- Synastria Resource Bank count (bottom left, yellow)
							local rbank = 0
							if GetCustomGameData then
								rbank = GetCustomGameData(13, gemId) or 0
							end
							if countBank then
								countBank:SetText(rbank or 0)
								countBank:SetTextColor(1, 0.82, 0)
							end
							
							gemButton.itemId = gemId
							
							-- Setup click handlers for withdraw/deposit
							setupSourceButtonClicks(gemButton, gemId)
						end
					end
				end
			end
		end
	end
end

-- ========================================
-- TAB SWITCHING
-- ========================================

function Skillet:SetExtractionTab(tab)
	currentTab = tab
	
	-- Update mode buttons with visual highlighting
	if tab == "MILLING" then
		-- Highlight milling button
		if SkilletExtractionMillingButton then
			SkilletExtractionMillingButton:LockHighlight()
		end
		if SkilletExtractionProspectingButton then
			SkilletExtractionProspectingButton:UnlockHighlight()
		end
	else
		-- Highlight prospecting button
		if SkilletExtractionMillingButton then
			SkilletExtractionMillingButton:UnlockHighlight()
		end
		if SkilletExtractionProspectingButton then
			SkilletExtractionProspectingButton:LockHighlight()
		end
	end
	
	-- Refresh display
	self:UpdateExtractionList()
end

-- ========================================
-- SHOW/HIDE
-- ========================================

function Skillet:ShowExtractionFrame()
	if not frameInitialized then
		createExtractionFrame(self)
		frameInitialized = true
		
		-- Print all pigment tooltips to help verify herb mappings
		DEFAULT_CHAT_FRAME:AddMessage("=== PIGMENT TOOLTIPS ===")
		
		-- Collect all unique pigments from MILLING_DATA
		local pigments = {}
		for herbId, data in pairs(self.MILLING_DATA) do
			for _, pigmentId in ipairs(data.commonPigments or {}) do
				pigments[pigmentId] = true
			end
			for _, pigmentId in ipairs(data.rarePigments or {}) do
				pigments[pigmentId] = true
			end
		end
		
		-- Sort pigments by ID for consistent output
		local pigmentIds = {}
		for pigmentId in pairs(pigments) do
			table.insert(pigmentIds, pigmentId)
		end
		table.sort(pigmentIds)
		
		-- Print tooltip for each pigment
		for _, pigmentId in ipairs(pigmentIds) do
			local itemName = GetItemInfo(pigmentId)
			DEFAULT_CHAT_FRAME:AddMessage("--- Pigment: " .. (itemName or "Unknown") .. " (" .. pigmentId .. ") ---")
			
			-- Create temporary tooltip to extract text
			local tooltip = CreateFrame("GameTooltip", "SkilletPigmentScanTooltip", nil, "GameTooltipTemplate")
			tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
			tooltip:SetHyperlink("item:" .. pigmentId)
			
			-- Read all tooltip lines
			for i = 1, tooltip:NumLines() do
				local leftText = getglobal("SkilletPigmentScanTooltipTextLeft" .. i)
				if leftText then
					local text = leftText:GetText()
					if text then
						DEFAULT_CHAT_FRAME:AddMessage("  " .. text)
					end
				end
			end
			
			tooltip:Hide()
		end
		
		DEFAULT_CHAT_FRAME:AddMessage("=== END PIGMENT TOOLTIPS ===")
	end
	
	SkilletExtractionFrame:Show()
	self:SetExtractionTab(currentTab)
	
	-- Register BAG_UPDATE event to refresh counts
	if not SkilletExtractionFrame.bagUpdateRegistered then
		self:RegisterEvent("BAG_UPDATE", onBagUpdate)
		SkilletExtractionFrame.bagUpdateRegistered = true
	end
end

function Skillet:HideExtractionFrame()
	if SkilletExtractionFrame then
		SkilletExtractionFrame:Hide()
		
		-- Unregister BAG_UPDATE event
		if SkilletExtractionFrame.bagUpdateRegistered then
			self:UnregisterEvent("BAG_UPDATE", onBagUpdate)
			SkilletExtractionFrame.bagUpdateRegistered = false
		end
	end
end

function Skillet:ToggleExtractionFrame()
	if SkilletExtractionFrame and SkilletExtractionFrame:IsVisible() then
		self:HideExtractionFrame()
	else
		self:ShowExtractionFrame()
	end
end

function Skillet:ToggleExtractionBulkMode()
	bulkMode = not bulkMode
	SkilletExtractionBulkModeCheckbox:SetChecked(bulkMode)
	DEFAULT_CHAT_FRAME:AddMessage("Extraction Bulk Mode: " .. (bulkMode and "ON" or "OFF"))
	
	-- Update all active source button click handlers with new bulk mode state
	-- Source buttons are at indices 7-18 (group 1) and 25-36 (group 2)
	for i = 1, 36 do
		-- Skip result buttons (1-6 and 19-24), only update source buttons
		if (i >= 7 and i <= 18) or (i >= 25 and i <= 36) then
			local button = getglobal("SkilletExtractionListButton" .. i)
			if button and button:IsVisible() and button.itemId then
				setupSourceButtonClicks(button, button.itemId)
			end
		end
	end
end

function Skillet:IsExtractionBulkMode()
	return bulkMode
end
