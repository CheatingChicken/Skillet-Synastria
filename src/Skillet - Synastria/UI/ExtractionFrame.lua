--[[
Skillet: Extraction Frame
Shows prospecting and milling data organized by target items
]] --
---@class Frame
---@class ScrollFrame : Frame
---@class Button : Frame

---@class Skillet
---@field CONVERSION_GROUPS ConversionGroup[]

---@class ConversionButton : Button
---@field conversionData ConversionDefinition?

---@class MillingResult
---@field itemId number The common pigment ID
---@field name string The pigment name
---@field rarity string The rarity type ("common" or "uncommon")
---@field rarePigments number[] Array of rare pigment IDs

---@class MillingGroup
---@field type string Group type identifier
---@field result MillingResult The common pigment and associated rare pigments
---@field sources number[] Array of herb IDs that produce this pigment
---@field extended boolean? Special flag for extended layout
---@field title string? Display title for the group

---@class GemData
---@field id number The gem ID
---@field rarity string The gem rarity ("common" or "uncommon")

---@class ProspectingGroup
---@field type string Group type identifier
---@field tierName string Name of the ore tier
---@field expansion string Expansion identifier
---@field ores number[] Array of ore IDs in this tier
---@field gems GemData[] Array of gems that can be prospected
---@field extended boolean? Special flag for extended layout (Titanium)

---@class ConversionDefinition
---@field source number Source item ID
---@field target number Target item ID
---@field ratio number Conversion ratio (>1 for combine, <1 for split)
---@field type string Conversion type ("combine" or "split")
---@field name string Human-readable conversion name

---@class ConversionGroupItem
---@field title string Group title
---@field pattern string Pattern to match conversion names
---@field items ConversionDefinition[] Array of conversions in this group

---@class ConversionGroup
---@field bidirectional boolean
---@field conversions ConversionDefinition[]
---@field conversionPairs ConversionPair[] Array of conversion pairs for display
---@field extended boolean?
---@field hasWarnings boolean
---@field label string
---@field ratio number
---@field resultItems number[]
---@field sourceItems number[]
---@field title string
---@field type string
---@class ExtractionContainerFrame : Frame
---@field label FontString
---@field SetPoint fun(self: Frame, point: string, relativeTo: Frame, relativePoint: string, x: number, y: number)
---@field SetWidth fun(self: Frame, width: number)
---@field SetHeight fun(self: Frame, height: number)
---@field Hide fun(self: Frame)
---@field Show fun(self: Frame)
---@field SetBackdrop fun(self: Frame, backdrop: table)
---@field SetBackdropColor fun(self: Frame, r: number, g: number, b: number, a: number)
---@field SetBackdropBorderColor fun(self: Frame, r: number, g: number, b: number, a: number)

-- XML-defined frames (defined in ExtractionFrame.xml)
-- These are global frames - access via getglobal() for type safety
-- NOTE: All getglobal() calls must be validated for nil before use

---@type ExtractionPageData[] Global pages array for cross-function access
_G.scrollPages = {}

-- === BEGIN: Fix undefined globals and EmmyLua param doc issues ===
-- Fixed layout constants (must be above border creation functions)
local BORDER_EDGE_SIZE = 12
---@type FontString[]
local smallGroupLabels = {}
---@type FontString[]
local mediumGroupLabels = {}
---@type FontString|nil
local largeGroupLabel = nil
---@type function|nil
local setupSourceButtonClicks -- will be defined later
---
---@param i number
---@param container Frame
---@return Frame, FontString
local function createSmallGroupBorder(i, container)
	local borderName = "SkilletExtractionSmallGroupBorder" .. i
	---@type Frame
	local border = CreateFrame("Frame", borderName, container)
	border:SetFrameStrata("LOW")
	border:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = BORDER_EDGE_SIZE,
		insets = { left = 2, right = 2, top = 2, bottom = 2 }
	})
	border:SetBackdropColor(0.08, 0.08, 0.08, 0.9)
	border:SetBackdropBorderColor(0.6, 0.6, 0.6, 0.8)
	border:Hide()

	local labelName = "SkilletExtractionSmallGroupBorderLabel" .. i
	---@type FontString
	---@type FontString
	local label = container:CreateFontString(labelName, "OVERLAY", "GameFontNormalSmall")
	label:SetTextColor(1, 1, 0.4, 1)
	label:SetJustifyH("LEFT")
	label:SetDrawLayer("OVERLAY", 2)
	border.label = label
	return border, label
end

---@param i number
---@param container Frame
---@return Frame, FontString
local function createMediumGroupBorder(i, container)
	local borderName = "SkilletExtractionMediumGroupBorder" .. i
	---@type Frame
	local border = CreateFrame("Frame", borderName, container)
	border:SetFrameStrata("LOW")
	border:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = BORDER_EDGE_SIZE,
		insets = { left = 2, right = 2, top = 2, bottom = 2 }
	})
	border:SetBackdropColor(0.08, 0.08, 0.08, 0.9)
	border:SetBackdropBorderColor(0.6, 0.6, 0.6, 0.8)
	border:Hide()

	local labelName = "SkilletExtractionMediumGroupBorderLabel" .. i
	---@type FontString
	---@type FontString
	local label = container:CreateFontString(labelName, "OVERLAY", "GameFontNormalSmall")
	label:SetTextColor(1, 1, 0.4, 1)
	label:SetJustifyH("LEFT")
	label:SetDrawLayer("OVERLAY", 2)
	border.label = label
	return border, label
end

---@param container Frame
---@return Frame, FontString
local function createLargeGroupBorder(container)
	---@type Frame
	local border = CreateFrame("Frame", "SkilletExtractionLargeGroupBorder", container)
	border:SetFrameStrata("LOW")
	border:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = BORDER_EDGE_SIZE,
		insets = { left = 2, right = 2, top = 2, bottom = 2 }
	})
	border:SetBackdropColor(0.08, 0.08, 0.08, 0.9)
	border:SetBackdropBorderColor(0.6, 0.6, 0.6, 0.8)
	border:Hide()

	local label = container:CreateFontString("SkilletExtractionLargeGroupBorderLabel", "OVERLAY", "GameFontNormalSmall")
	label:SetTextColor(1, 1, 0.4, 1)
	label:SetJustifyH("LEFT")
	label:SetDrawLayer("OVERLAY", 2)
	border.label = label
	return border, label
end
-- === END: Fix undefined globals and EmmyLua param doc issues ===

---@type table<string, string>
local L = AceLibrary("AceLocale-2.2"):new("Skillet")

-- DEBUG: Check if CONVERSION_GROUPS exists at file load time
if Skillet and Skillet:IsDevMode() then
	if Skillet.CONVERSION_GROUPS then
		DEFAULT_CHAT_FRAME:AddMessage("[Skillet] ExtractionFrame.lua loaded - CONVERSION_GROUPS exists with " ..
			#Skillet.CONVERSION_GROUPS .. " groups")
	else
		DEFAULT_CHAT_FRAME:AddMessage("[Skillet] ExtractionFrame.lua loaded - CONVERSION_GROUPS NOT FOUND! Skillet=" ..
			tostring(Skillet))
	end
end

-- Stolen from the Waterfall Ace2 addon.
local ControlBackdrop  = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 16,
	edgeSize = 16,
	insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

---@type table<string, any>
local FrameBackdrop    = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 16,
	edgeSize = 16,
	insets = { left = 3, right = 3, top = 30, bottom = 3 }
}

-- Current tab: "MILLING" or "PROSPECTING"
---@type string
local currentTab       = "MILLING"

-- Track if frame has been initialized
---@type boolean
local frameInitialized = false

-- Bulk mode flag (default true)
---@type boolean
local bulkMode         = true

-- Current page index (1-based)
---@type number
local currentPageIndex = 1

-- Helper function to get item quality for sorting
local function getItemRarity(itemId)
	local _, _, quality = GetItemInfo(itemId)
	return quality or 1 -- Default to common if unknown
end

-- Helper function to get border color based on item quality (reused from existing code)
local function getQualityColor(itemId)
	local _, _, quality = GetItemInfo(itemId)

	if not quality then
		-- Default to black if quality unknown
		return { r = 0, g = 0, b = 0 }
	end

	-- WoW quality colors:
	-- 0 = Poor (gray), 1 = Common (white), 2 = Uncommon (green)
	-- 3 = Rare (blue), 4 = Epic (purple), 5 = Legendary (orange)
	if quality == 0 then
		-- Poor (gray)
		return { r = 0.62, g = 0.62, b = 0.62 }
	elseif quality == 1 then
		-- Common (white)
		return { r = 1.0, g = 1.0, b = 1.0 }
	elseif quality == 2 then
		-- Uncommon (green)
		return { r = 0.12, g = 1.0, b = 0.0 }
	elseif quality == 3 then
		-- Rare (blue)
		return { r = 0.0, g = 0.44, b = 0.87 }
	elseif quality == 4 then
		-- Epic (purple)
		return { r = 0.64, g = 0.21, b = 0.93 }
	else
		-- Legendary and above (orange)
		return { r = 1.0, g = 0.5, b = 0.0 }
	end
end

-- ========================================
-- LAYOUT CONSTANTS
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

-- Helper function to setup extraction buttons with direct row/column positioning
---@class ExtractionConversionButton : ConversionButton
---@field itemId number
---@field conversionPair { resultItem: number, sourceItem: number, bidirectional: boolean, ratio?: number }
---@class FrameWithLabel : Frame
---@field label any
---Set up an extraction button with all required fields and positioning
---@param button ExtractionConversionButton
---@param buttonPrefix string
---@param index number
---@param itemId number
---@param row number
---@param col number
---@param border FrameWithLabel
---@param clickHandler fun(button: ExtractionConversionButton, itemId: number, data: any)|nil
---@param clickHandlerData any
local function setupExtractionButton(button, buttonPrefix, index, itemId, row, col, border, clickHandler,
									 clickHandlerData)
	if not button then return end
	if not border then return end    -- Border required for positioning
	if not buttonPrefix then return end -- Prefix required for child lookups
	if not itemId then return end    -- ItemId required for data

	button:Show()
	local countBg = getglobal(buttonPrefix .. index .. "CountBackground")
	if countBg then
		countBg:Show()
	end

	-- Position button using direct row/column
	button:ClearAllPoints()
	local totalInset = BORDER_EDGE_SIZE / 2 + GROUP_PADDING

	if col == 1 then
		-- First column - anchor to border with row offset
		local yOffset = -totalInset - (row * (ITEM_HEIGHT + ROW_SPACING))
		button:SetPoint("TOPLEFT", border, "TOPLEFT", totalInset, yOffset)
	else
		-- Other columns - anchor to previous button
		local prevButton = getglobal(buttonPrefix .. (index - 1))
		if prevButton then
			button:SetPoint("LEFT", prevButton, "RIGHT", ITEM_SPACING, 0)
		end
	end

	-- Setup icon, label, counts, and border using quality detection
	local icon = getglobal(buttonPrefix .. index .. "Icon")
	local label = getglobal(buttonPrefix .. index .. "Label")
	local countOwned = getglobal(buttonPrefix .. index .. "CountOwned")
	local countBank = getglobal(buttonPrefix .. index .. "CountBank")
	local buttonBorder = getglobal(buttonPrefix .. index .. "Border")

	if icon then
		local itemTexture = GetItemIcon(itemId)
		if itemTexture then icon:SetTexture(itemTexture) end
	end

	if label then
		local itemName = GetItemInfo(itemId) or ("Item " .. itemId)

		-- Customize labels for better UI clarity
		itemName = string.gsub(itemName, "Crystallized ", "Cryst. ") -- Shorten Crystallized to Cryst.
		itemName = string.gsub(itemName, " Essence$", "")      -- Remove " Essence" suffix

		label:SetText(itemName)
	end

	-- Get quantities from bags and resource banks
	local bagCount = GetItemCount(itemId, false) or 0
	local bankCount = 0

	-- Use Synastria's custom API to get Resource Bank count
	-- GetCustomGameData(13, itemId) where 13 is RESOURCE_BANK data type
	if GetCustomGameData then
		bankCount = GetCustomGameData(13, itemId) or 0
	end

	if countOwned then
		-- Always show bag count, even if 0
		countOwned:SetText(tostring(bagCount))
		if bagCount > 0 then
			countOwned:SetTextColor(1, 1, 1) -- White
		else
			countOwned:SetTextColor(0.5, 0.5, 0.5) -- Gray for 0
		end
		countOwned:Show()
	end

	if countBank then
		-- Always show resource bank count, even if 0
		countBank:SetText(tostring(bankCount))
		if bankCount > 0 then
			countBank:SetTextColor(0.8, 0.8, 1) -- Light blue
		else
			countBank:SetTextColor(0.4, 0.4, 0.5) -- Darker gray for 0
		end
		countBank:Show()
	end

	-- Set border color based on item quality
	if buttonBorder then
		local qualityColor = getQualityColor(itemId)
		if qualityColor then
			buttonBorder:SetVertexColor(qualityColor.r, qualityColor.g, qualityColor.b)
			buttonBorder:Show()
		end
	end

	-- Store item data
	button.itemId = itemId
	button.itemId = itemId -- EmmyLua: ExtractionConversionButton allows this

	-- Apply custom click handler if provided
	if clickHandler and clickHandlerData then
		clickHandler(button, itemId, clickHandlerData)
	end

	-- Default tooltip handling
	button:SetScript("OnEnter", function(self)
		---@type ExtractionConversionButton
		self = self
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if self.itemId then
			local itemLink = select(2, GetItemInfo(self.itemId))
			if itemLink then
				GameTooltip:SetHyperlink(itemLink)
			end
		end
		GameTooltip:Show()
	end)

	button:SetScript("OnLeave", function(self)
		---@type ExtractionConversionButton
		self = self
		GameTooltip:Hide()
	end)
end

-- Helper function to get border color based on item quality (reused from existing code)
local function getQualityColor(itemId)
	local _, _, quality = GetItemInfo(itemId)

	if not quality then
		-- Default to green if quality unknown
		return { r = 0.25, g = 0.75, b = 0.25 }
	end

	-- WoW quality colors:
	-- 0 = Poor (gray), 1 = Common (white), 2 = Uncommon (green)
	-- 3 = Rare (blue), 4 = Epic (purple), 5 = Legendary (orange)
	if quality == 0 then
		-- Poor (gray)
		return { r = 0.62, g = 0.62, b = 0.62 }
	elseif quality == 1 then
		-- Common (white)
		return { r = 1.0, g = 1.0, b = 1.0 }
	elseif quality == 2 then
		-- Uncommon (green)
		return { r = 0.12, g = 1.0, b = 0.0 }
	elseif quality == 3 then
		-- Rare (blue)
		return { r = 0.0, g = 0.44, b = 0.87 }
	elseif quality == 4 then
		-- Epic (purple)
		return { r = 0.64, g = 0.21, b = 0.93 }
	else
		-- Legendary and above (orange)
		return { r = 1.0, g = 0.5, b = 0.0 }
	end
end

-- ========================================
-- BUILD REVERSE MAPS
-- ========================================

-- Build map of pigment -> herbs
local function buildMillingMap()
	---@type table<number, {type: string, herbs: number[], rarePigments: number[]}>
	local pigmentToHerbs = {}

	-- CRITICAL: Check if database is loaded
	if not Skillet.MILLING_DATA then
		DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Skillet] ERROR: MILLING_DATA not loaded!|r")
		return pigmentToHerbs -- Return empty table
	end

	for herbId, data in pairs(Skillet.MILLING_DATA) do
		-- Only process common pigments (rare pigments are attached to them)
		if data.commonPigments then
			---@type number
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

-- Additional layout constants
local RESULT_BUTTONS_PER_GROUP = 6
local SOURCE_BUTTONS_PER_ROW = 6

---@type ConversionGroup[]|MillingGroup[]|ProspectingGroup[]
local scrollData = {}
---@type Frame[]
local mediumGroupBorders = {}
---@type Frame|nil
local largeGroupBorder = nil
---@type Frame[]
local smallGroupBorders = {}

-- Conversion-specific click processor for setupExtractionButton
-- Helper function to find empty slot or existing stack for target item
local function findEmptySlotOrStack(itemId)
	-- First try to find existing stack with space
	for bag = 0, 4 do
		local numSlots = GetContainerNumSlots(bag)
		if numSlots and numSlots > 0 then
			for slot = 1, numSlots do
				local _, count, _, _, _, _, link = GetContainerItemInfo(bag, slot)
				if link then
					local foundItemId = Skillet:GetItemIDFromLink(link)
					if foundItemId and foundItemId == itemId then
						-- Found existing stack - check if it has space
						local _, _, _, _, _, _, _, maxStack = GetItemInfo(itemId)
						if maxStack and count < maxStack then
							return bag, slot
						end
					end
				end
			end
		end
	end

	-- Then find empty slot
	for bag = 0, 4 do
		local numSlots = GetContainerNumSlots(bag)
		if numSlots and numSlots > 0 then
			for slot = 1, numSlots do
				local link = GetContainerItemLink(bag, slot)
				if not link then
					return bag, slot
				end
			end
		end
	end

	return nil, nil
end

-- Perform the actual item conversion by USING the items
-- Conversions work by right-clicking items in your inventory
local function performActualConversion(sourceItemId, targetItemId, inputAmount, sourceItemName, targetItemName, isReverse)
	-- Find the first stack of source items
	local sourceBag, sourceSlot = nil, nil

	for bag = 0, 4 do
		local numSlots = GetContainerNumSlots(bag)
		if numSlots and numSlots > 0 then
			for slot = 1, numSlots do
				local link = GetContainerItemLink(bag, slot)
				if link then
					local foundItemId = Skillet:GetItemIDFromLink(link)
					if foundItemId and foundItemId == sourceItemId then
						local _, count = GetContainerItemInfo(bag, slot)
						if count and count >= inputAmount then
							sourceBag = bag
							sourceSlot = slot
							break
						end
					end
				end
			end
			if sourceBag then break end
		end
	end

	if not sourceBag or not sourceSlot then
		Skillet:Print("|cFFFF6666Could not find " .. inputAmount .. "x " .. sourceItemName .. " in a single stack|r")
		return
	end

	-- Use the item to perform conversion (right-click)
	-- For essences/eternals/primals, right-clicking them performs the conversion
	UseContainerItem(sourceBag, sourceSlot)

	local outputAmount = 1 -- Default output is 1 item
	Skillet:Print("|cFF66FF66Converting " ..
		inputAmount .. "x " .. sourceItemName .. " -> " .. outputAmount .. "x " .. targetItemName .. "|r")
end

-- Perform conversion between items
---
---@param clickedItemId number The item ID that was clicked
---@param conversionPair { resultItem: number, sourceItem: number, bidirectional: boolean, inputAmount?: number, outputAmount?: number } The conversion definition for this pair
---@param itemName string The name of the clicked item
local function performConversion(clickedItemId, conversionPair, itemName)
	if not conversionPair then return end

	---@type number|nil
	local sourceItemId
	---@type number|nil
	local targetItemId
	---@type boolean|nil
	local isReverse
	---@type number
	local inputAmount = conversionPair.inputAmount or 10
	local outputAmount = conversionPair.outputAmount or 1

	-- Determine conversion direction based on clicked item
	if clickedItemId == conversionPair.resultItem then
		-- Clicked result item - check if bidirectional for reverse conversion
		if conversionPair.bidirectional then
			---@type number
			sourceItemId = conversionPair.resultItem
			---@type number
			targetItemId = conversionPair.sourceItem
			---@type boolean
			isReverse = true
		else
			-- Can't reverse convert, treat as deposit request
			if Skillet and Skillet.DepositToResourceBank then
				Skillet:Print("|cFFFFAA00Cannot reverse convert " .. itemName .. " - depositing instead|r")
				Skillet:DepositToResourceBank(clickedItemId, true)
			end
			return
		end
	elseif clickedItemId == conversionPair.sourceItem then
		-- Clicked source item - normal conversion
		---@type number
		sourceItemId = conversionPair.sourceItem
		---@type number
		targetItemId = conversionPair.resultItem
		---@type boolean
		isReverse = false
	else
		DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000Error: Item not part of conversion pair|r")
		return
	end

	-- Check if we have source items in inventory first
	---@type number
	local bagsCount = GetItemCount(sourceItemId, false) or 0
	---@type number
	local bankCount = 0

	-- Get resource bank count if available
	if GetCustomGameData then
		bankCount = GetCustomGameData(13, sourceItemId) or 0
	end

	---@type number
	local totalAvailable = bagsCount + bankCount
	---@type string
	local sourceItemName = GetItemInfo(sourceItemId) or ("Item " .. tostring(sourceItemId))
	---@type string
	local targetItemName = GetItemInfo(targetItemId) or ("Item " .. tostring(targetItemId))

	-- Check if we have enough resources for at least one conversion
	if totalAvailable < inputAmount then
		Skillet:Print("|cFFFF6666Not enough " ..
			sourceItemName .. " (" .. totalAvailable .. "/" .. inputAmount .. " needed)|r")
		return
	end

	-- If we have enough in bags, convert immediately
	if bagsCount >= inputAmount then
		-- Check if we have inventory space for the result
		---@type number|nil
		local targetBag, targetSlot = findEmptySlotOrStack(targetItemId)
		if not targetBag then
			Skillet:Print("|cFFFF6666No inventory space for " .. targetItemName .. "|r")
			return
		end

		performActualConversion(sourceItemId, targetItemId, inputAmount, sourceItemName, targetItemName, isReverse)
		return
	end

	-- Not enough in bags - withdraw from resource bank (no conversion yet)
	---@type number
	local neededFromBank = inputAmount - bagsCount
	if bankCount >= neededFromBank then
		if Skillet and Skillet.WithdrawFromResourceBank then
			Skillet:Print("|cFF66AAFF Withdrawing " ..
				neededFromBank .. "x " .. sourceItemName .. " from Resource Bank. Click again to convert.|r")
			Skillet:WithdrawFromResourceBank(sourceItemId, true)
		else
			Skillet:Print("|cFFFF6666Cannot withdraw from Resource Bank - functionality not available|r")
		end
	else
		Skillet:Print("|cFFFF6666Not enough " ..
			sourceItemName .. " in Resource Bank (" .. bankCount .. "/" .. neededFromBank .. " needed)|r")
	end
end

---@param button ExtractionConversionButton
---@param itemId number
---@param conversionPair { resultItem: number, sourceItem: number, bidirectional: boolean, ratio?: number }
local function setupConversionButtonClicks(button, itemId, conversionPair)
	if not button or not conversionPair then
		return
	end

	-- Store conversion data
	button.conversionPair = conversionPair

	-- Enable the button and register for clicks
	button:Enable()
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	-- Tooltip handling with conversion info
	button:SetScript("OnEnter", function(self)
		---@type ExtractionConversionButton
		self = self
		if GameTooltip and self.itemId then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetHyperlink("item:" .. self.itemId)

			-- Add conversion info to tooltip
			if self.conversionPair then
				local pair = self.conversionPair
				GameTooltip:AddLine(" ")                -- Blank line
				GameTooltip:AddLine("Conversion:", 1, 1, 0.4, true) -- Yellow header

				-- Show conversion ratio and direction
				if pair.bidirectional then
					GameTooltip:AddLine(
						"Bidirectional " .. (pair.inputAmount or 10) .. ":" .. (pair.outputAmount or 1) .. " conversion",
						0.8,
						0.8, 0.8, true)
				else
					GameTooltip:AddLine(
						"One-way " .. (pair.inputAmount or 10) .. ":" .. (pair.outputAmount or 1) .. " conversion", 1,
						0.6,
						0.6, true)
				end

				GameTooltip:AddLine("Left-click: Convert (or Withdraw if needed)", 0.6, 1, 0.6, true)
				GameTooltip:AddLine("Right-click: Deposit to Resource Bank", 0.6, 1, 0.6, true)
			end

			GameTooltip:Show()
		end
	end)

	button:SetScript("OnLeave", function(self)
		---@type ExtractionConversionButton
		self = self
		if GameTooltip then
			GameTooltip:Hide()
		end
	end)

	-- Synastria: Configure SecureActionButton for left-click item usage
	-- Determine which item to use when clicked (bidirectional conversions use the clicked item)
	local sourceItemId = conversionPair.sourceItem
	local sourceItemName = GetItemInfo(sourceItemId)

	if sourceItemName then
		-- Configure SecureActionButton to USE the source item on left-click
		button:SetAttribute("type1", "item")  -- Left-click = type1
		button:SetAttribute("item", sourceItemName) -- Item to use
	end

	-- PreClick: Check for withdraw needs before using item
	button:SetScript("PreClick", function(self, mouseButton)
		---@type ExtractionConversionButton
		self = self
		if not self.conversionPair then return end

		---@type { resultItem: number, sourceItem: number, bidirectional: boolean, inputAmount?: number, outputAmount?: number }
		local pair = self.conversionPair
		---@type string
		local itemName = GetItemInfo(itemId) or ("Item " .. tostring(itemId))

		-- Only handle left-click for conversions
		if mouseButton == "LeftButton" then
			-- Determine conversion direction based on clicked item
			---@type number|nil
			local sourceId
			---@type number|nil
			local targetId
			---@type boolean|nil
			local isReverse
			---@type number
			local inputAmount = pair.inputAmount or 10

			if itemId == pair.resultItem then
				-- Clicked result item - check if bidirectional for reverse conversion
				if pair.bidirectional then
					sourceId = pair.resultItem
					targetId = pair.sourceItem
					isReverse = true

					-- Update SecureActionButton to use result item
					local resultItemName = GetItemInfo(pair.resultItem)
					if resultItemName then
						self:SetAttribute("item", resultItemName)
					end
				else
					-- Can't reverse convert - prevent action
					Skillet:Print("|cFFFFAA00Cannot reverse convert " .. itemName .. " - right-click to deposit|r")
					return "block"
				end
			else
				-- Clicked source item - normal conversion
				sourceId = pair.sourceItem
				targetId = pair.resultItem
				isReverse = false

				-- Update SecureActionButton to use source item
				local sourceItemName = GetItemInfo(pair.sourceItem)
				if sourceItemName then
					self:SetAttribute("item", sourceItemName)
				end
			end

			-- Check if we have enough items in bags

			---@type number
			local bagsCount = GetItemCount(sourceId, false) or 0
			---@type number
			local bankCount = 0

			if GetCustomGameData then
				bankCount = GetCustomGameData(13, sourceId) or 0
			end

			---@type number
			local totalAvailable = bagsCount + bankCount
			---@type string
			local sourceItemName = GetItemInfo(sourceId) or ("Item " .. tostring(sourceId))

			-- Need at least inputAmount items for conversion
			if totalAvailable < inputAmount then
				Skillet:Print("|cFFFF6666Not enough " ..
					sourceItemName .. " (" .. totalAvailable .. "/" .. inputAmount .. " needed)|r")
				return "block" -- Prevent SecureActionButton from running
			end

			-- If not enough in bags, withdraw from bank first
			if bagsCount < inputAmount then
				---@type number
				local neededFromBank = inputAmount - bagsCount
				if bankCount >= neededFromBank and Skillet.WithdrawFromResourceBank then
					Skillet:Print("|cFF66AAFFWithdrawing " ..
						neededFromBank .. "x " .. sourceItemName .. " from Resource Bank. Click again to convert.|r")
					Skillet:WithdrawFromResourceBank(sourceId, true)
					return "block" -- Prevent conversion this click
				end
			end

			-- Have enough in bags - SecureActionButton will use the item
		end
	end)

	-- PostClick: Handle right-click deposits and conversion feedback
	button:SetScript("PostClick", function(self, mouseButton)
		---@type ExtractionConversionButton
		self = self
		if not self.conversionPair then return end

		---@type { resultItem: number, sourceItem: number, bidirectional: boolean, inputAmount?: number, outputAmount?: number }
		local pair = self.conversionPair
		---@type string
		local itemName = GetItemInfo(itemId) or ("Item " .. tostring(itemId))

		if mouseButton == "LeftButton" then
			-- Conversion was performed by SecureActionButton - provide feedback
			---@type number|nil
			local sourceId
			---@type number|nil
			local targetId
			---@type boolean|nil
			local isReverse
			---@type number
			local inputAmount = pair.inputAmount or 10
			---@type number
			local outputAmount = pair.outputAmount or 1

			if itemId == pair.resultItem then
				sourceId = pair.resultItem
				targetId = pair.sourceItem
				isReverse = true
			else
				sourceId = pair.sourceItem
				targetId = pair.resultItem
				isReverse = false
			end

			---@type string
			local sourceItemName = GetItemInfo(sourceId) or ("Item " .. tostring(sourceId))
			---@type string
			local targetItemName = GetItemInfo(targetId) or ("Item " .. tostring(targetId))
			---@type number
			local targetCount = isReverse and outputAmount or outputAmount

			Skillet:Print("|cFF66FF66Converting " ..
				inputAmount .. "x " .. sourceItemName .. " -> " .. targetCount .. "x " .. targetItemName .. "|r")
		elseif mouseButton == "RightButton" then
			-- Right click: Deposit all stacks to resource bank
			if Skillet and Skillet.Print and Skillet.DepositToResourceBank then
				Skillet:Print("|cFF00FF00Depositing " .. itemName .. " to Resource Bank...|r")
				Skillet:DepositToResourceBank(itemId, true)
			else
				DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000Error: Resource Bank functionality not available|r")
			end
		end
	end)
end

-- Helper function to get border color based on item quality
local function getQualityColor(itemId)
	local _, _, quality = GetItemInfo(itemId)

	if not quality then
		-- Default to green if quality unknown
		return { r = 0.25, g = 0.75, b = 0.25 }
	end

	-- WoW quality colors:
	-- 0 = Poor (gray), 1 = Common (white), 2 = Uncommon (green)
	-- 3 = Rare (blue), 4 = Epic (purple), 5 = Legendary (orange)
	if quality == 0 then
		-- Poor (gray)
		return { r = 0.62, g = 0.62, b = 0.62 }
	elseif quality == 1 then
		-- Common (white)
		return { r = 1.0, g = 1.0, b = 1.0 }
	elseif quality == 2 then
		-- Uncommon (green)
		return { r = 0.12, g = 1.0, b = 0.0 }
	elseif quality == 3 then
		-- Rare (blue)
		return { r = 0.0, g = 0.44, b = 0.87 }
	elseif quality == 4 then
		-- Epic (purple)
		return { r = 0.64, g = 0.21, b = 0.93 }
	elseif quality == 5 then
		-- Legendary (orange)
		return { r = 1.0, g = 0.5, b = 0.0 }
	else
		-- Default green for unknown
		return { r = 0.25, g = 0.75, b = 0.25 }
	end
end

-- Initialize fixed button positions (called once on frame creation)
-- Initialize button positions for both Medium and Large layouts
local function initializeButtonPositions()
	---@type ExtractionContainerFrame
	local container = getglobal("SkilletExtractionContainer")
	if not container then
		return
	end

	local totalInset = BORDER_EDGE_SIZE / 2 + GROUP_PADDING

	-- ===== MEDIUM LAYOUT (2 groups) =====
	-- Create borders only - buttons will be positioned dynamically
	for groupNum = 0, 1 do
		local groupY = -5 - (groupNum * (totalInset * 2 + ITEM_HEIGHT + 2 * (ITEM_HEIGHT + ROW_SPACING) + GROUP_SPACING))

		-- Create border for this group
		if not mediumGroupBorders[groupNum + 1] then
			local borderName = "SkilletExtractionMediumGroupBorder" .. (groupNum + 1)
			local border = CreateFrame("Frame", borderName, container)
			border:SetFrameStrata("LOW")
			border:SetBackdrop({
				bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = true,
				tileSize = 16,
				edgeSize = BORDER_EDGE_SIZE,
				insets = { left = 2, right = 2, top = 2, bottom = 2 }
			})
			border:SetBackdropColor(0.08, 0.08, 0.08, 0.9)
			border:SetBackdropBorderColor(0.6, 0.6, 0.6, 0.8)
			border:SetPoint("TOPLEFT", container, "TOPLEFT", 6, groupY)

			-- Size border for normal layout (6 results + 2 source rows)
			local borderWidth = (totalInset * 2) + (SOURCE_BUTTONS_PER_ROW * ITEM_WIDTH) +
				((SOURCE_BUTTONS_PER_ROW - 1) * ITEM_SPACING)
			local borderHeight = (totalInset * 2) + ITEM_HEIGHT + (2 * (ITEM_HEIGHT + ROW_SPACING))
			border:SetWidth(borderWidth)
			border:SetHeight(borderHeight)
			border:Hide()

			---@cast border Frame
			mediumGroupBorders[groupNum + 1] = border
		end
	end

	-- ===== LARGE LAYOUT (1 extended group) =====
	-- Create single border for large layout
	if not largeGroupBorder then
		local border = CreateFrame("Frame", "SkilletExtractionLargeGroupBorder", container)
		border:SetFrameStrata("LOW")
		border:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileSize = 16,
			edgeSize = BORDER_EDGE_SIZE,
			insets = { left = 2, right = 2, top = 2, bottom = 2 }
		})
		border:SetBackdropColor(0.08, 0.08, 0.08, 0.9)
		border:SetBackdropBorderColor(0.6, 0.6, 0.6, 0.8)
		border:SetPoint("TOPLEFT", container, "TOPLEFT", 6, -5)

		-- Size border for extended layout (6 results + 5 source rows)
		local borderWidth = (totalInset * 2) + (SOURCE_BUTTONS_PER_ROW * ITEM_WIDTH) +
			((SOURCE_BUTTONS_PER_ROW - 1) * ITEM_SPACING)
		local borderHeight = (totalInset * 2) + ITEM_HEIGHT + (5 * (ITEM_HEIGHT + ROW_SPACING))
		border:SetWidth(borderWidth)
		border:SetHeight(borderHeight)
		border:Hide()

		-- Create group label text as child of container (not border) to avoid transparency issues
		local labelName = "SkilletExtractionLargeGroupBorderLabel"
		---@type FontString
		local label = container:CreateFontString(labelName, "OVERLAY", "GameFontNormalSmall")
		label:SetPoint("TOPLEFT", border, "TOPLEFT", 8, 2) -- Position relative to border but as container child
		label:SetTextColor(1, 1, 0.4, 1)             -- Bright yellow-gold text for better visibility
		label:SetText("Group 1")                     -- Default text, will be updated dynamically
		label:SetJustifyH("LEFT")
		label:SetDrawLayer("OVERLAY", 2)             -- Higher layer than border elements
		---@diagnostic disable-next-line: undefined-field
		border.label = label                         -- Store reference for easy access
		-- (removed duplicate class/field annotation for FrameWithLabel)

		largeGroupBorder = border
		largeGroupLabel = label
	end

	-- Position result row buttons (6 buttons)
	for i = 1, RESULT_BUTTONS_PER_GROUP do
		local button = getglobal("SkilletExtractionLargeButton" .. i)
		if button then
			button:ClearAllPoints()
			if i == 1 then
				button:SetPoint("TOPLEFT", largeGroupBorder, "TOPLEFT", totalInset, -totalInset)
			else
				button:SetPoint("LEFT", getglobal("SkilletExtractionLargeButton" .. (i - 1)), "RIGHT", ITEM_SPACING, 0)
			end
		end
	end

	-- Position source row buttons (30 buttons = 5 rows of 6)
	for row = 0, 4 do
		for col = 1, SOURCE_BUTTONS_PER_ROW do
			local sourceIndex = RESULT_BUTTONS_PER_GROUP + (row * SOURCE_BUTTONS_PER_ROW) + col
			local button = getglobal("SkilletExtractionLargeButton" .. sourceIndex)
			if button then
				button:ClearAllPoints()
				if col == 1 then
					-- First in row - anchor to border
					local yOffset = -totalInset - (ITEM_HEIGHT + ROW_SPACING) - (row * (ITEM_HEIGHT + ROW_SPACING))
					button:SetPoint("TOPLEFT", largeGroupBorder, "TOPLEFT", totalInset, yOffset)
				else
					-- Subsequent in row - anchor to previous
					button:SetPoint("LEFT", getglobal("SkilletExtractionLargeButton" .. (sourceIndex - 1)), "RIGHT",
						ITEM_SPACING, 0)
				end
			end
		end
	end

	-- ===== SMALL LAYOUT (for conversions) =====
	-- Create borders for small layout groups (3 groups with minimal spacing)
	local SMALL_GROUP_SPACING = GROUP_SPACING / 4 -- 25% of normal spacing
	for groupNum = 0, 2 do
		local groupY = -5 - (groupNum * (totalInset * 2 + 2 * (ITEM_HEIGHT + ROW_SPACING) + SMALL_GROUP_SPACING))

		-- Create border for this group
		if not smallGroupBorders then
			smallGroupBorders = {}
		end

		if not smallGroupBorders[groupNum + 1] then
			local borderName = "SkilletExtractionSmallGroupBorder" .. (groupNum + 1)
			local border = CreateFrame("Frame", borderName, container)
			border:SetFrameStrata("LOW")
			border:SetBackdrop({
				bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = true,
				tileSize = 16,
				edgeSize = BORDER_EDGE_SIZE,
				insets = { left = 2, right = 2, top = 2, bottom = 2 }
			})
			border:SetBackdropColor(0.08, 0.08, 0.08, 0.9)
			border:SetBackdropBorderColor(0.6, 0.6, 0.6, 0.8)
			border:SetPoint("TOPLEFT", container, "TOPLEFT", 6, groupY)

			-- Size border for small layout (6 columns, 2 rows)
			local borderWidth = (totalInset * 2) + (6 * ITEM_WIDTH) + (5 * ITEM_SPACING)
			local borderHeight = (totalInset * 2) + (2 * ITEM_HEIGHT) + ROW_SPACING
			border:SetWidth(borderWidth)
			border:SetHeight(borderHeight)
			border:Hide()

			-- Create group label text as child of container (not border) to avoid transparency issues
			local labelName = borderName .. "Label"
			local label = container:CreateFontString(labelName, "OVERLAY", "GameFontNormalSmall")
			label:SetPoint("TOPLEFT", border, "TOPLEFT", 8, 2) -- Position relative to border but as container child
			label:SetTextColor(1, 1, 0.4, 1)          -- Bright yellow-gold text for better visibility
			label:SetText("Group " .. (groupNum + 1)) -- Default text, will be updated dynamically
			label:SetJustifyH("LEFT")
			label:SetDrawLayer("OVERLAY", 2)          -- Higher layer than border elements
			---@diagnostic disable-next-line: undefined-field
			border.label = label                      -- Store reference for easy access
			---@diagnostic disable-next-line: assign-type-mismatch
			---@diagnostic disable-next-line: undefined-field
			border.label = label -- Store reference for easy access

			---@cast border Frame
			smallGroupBorders[groupNum + 1] = border
		end
	end

	-- Position small buttons in a 6x6 grid (36 buttons total for 3 groups)
	for i = 1, 36 do
		local button = getglobal("SkilletExtractionSmallButton" .. i)
		if button then
			button:ClearAllPoints()

			-- Calculate row and column (0-based for math, then adjust)
			local row = math.floor((i - 1) / 6)
			local col = (i - 1) % 6

			-- Position relative to container
			local xOffset = 20 + (col * (ITEM_WIDTH + ITEM_SPACING))
			local yOffset = -20 - (row * (ITEM_HEIGHT + ROW_SPACING))

			button:SetPoint("TOPLEFT", container, "TOPLEFT", xOffset, yOffset)
		end
	end
end

-- ========================================
-- UI CREATION
-- ========================================

local function createExtractionFrame(self)
	local frame = SkilletExtractionFrame
	if not frame then
		-- Critical error - silent
		return nil
	end

	frame:SetBackdrop(FrameBackdrop)
	frame:SetBackdropColor(0.1, 0.1, 0.1)

	-- Title bar
	local r, g, b = 0, 0.7, 0
	local titlebar = frame:CreateTexture("SkilletExtractionTitleBarTop", "BACKGROUND")
	local titlebar2 = frame:CreateTexture("SkilletExtractionTitleBarBottom", "BACKGROUND")

	titlebar:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -4)
	titlebar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -4)
	titlebar:SetHeight(13)

	titlebar2:SetPoint("TOPLEFT", titlebar, "BOTTOMLEFT", 0, 0)
	titlebar2:SetPoint("TOPRIGHT", titlebar, "BOTTOMRIGHT", 0, 0)
	titlebar2:SetHeight(13)

	titlebar:SetGradientAlpha("VERTICAL", r * 0.6, g * 0.6, b * 0.6, 1, r, g, b, 1)
	titlebar:SetTexture(r, g, b, 1)
	titlebar2:SetGradientAlpha("VERTICAL", r * 0.9, g * 0.9, b * 0.9, 1, r * 0.6, g * 0.6, b * 0.6, 1)
	titlebar2:SetTexture(r, g, b, 1)

	local title = CreateFrame("Frame", "SkilletExtractionTitleFrame", frame)
	title:SetPoint("TOPLEFT", titlebar, "TOPLEFT", 0, 0)
	title:SetPoint("BOTTOMRIGHT", titlebar2, "BOTTOMRIGHT", 0, 0)

	local titletext = title:CreateFontString("SkilletExtractionTitleText", "OVERLAY", "GameFontNormalLarge")
	titletext:SetPoint("TOPLEFT", title, "TOPLEFT", 0, 0)
	titletext:SetPoint("TOPRIGHT", title, "TOPRIGHT", 0, 0)
	titletext:SetHeight(26)
	titletext:SetShadowColor(0, 0, 0)
	titletext:SetShadowOffset(1, -1)
	titletext:SetTextColor(1, 1, 1)
	titletext:SetText("Skillet: Extraction")

	-- Set backdrop on container
	local container = SkilletExtractionContainer
	if container then
		-- Removed: SetBackdrop creates unnamed texture tables in BACKGROUND layer
		-- which can cause black box rendering artifacts
		-- container:SetBackdrop(ControlBackdrop)
		-- container:SetBackdropBorderColor(0.6, 0.6, 0.6)
		-- container:SetBackdropColor(0.05, 0.05, 0.05)
		container:Show()
	end

	-- Show scroll frame
	if SkilletExtractionScrollFrame then
		SkilletExtractionScrollFrame:Show()
	end

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

		-- Add instructions text to the right of bulk mode label
		local instructionsText = SkilletExtractionFrame:CreateFontString("SkilletExtractionInstructionsText", "OVERLAY",
			"GameFontNormalSmall")
		instructionsText:SetPoint("LEFT", label, "RIGHT", 15, 0)
		instructionsText:SetTextColor(0.7, 0.7, 0.7)
		instructionsText:SetText("Left Click: Withdraw/Process  |  Right Click: Deposit")
		instructionsText:SetJustifyH("LEFT")
	end

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

	-- Sort pigments by ID for consistent display
	---@type number[]
	local pigmentIds = {}
	---@type number
	for pigmentId in pairs(pigmentMap) do
		table.insert(pigmentIds, pigmentId)
	end
	table.sort(pigmentIds)

	---@type number
	for _, pigmentId in ipairs(pigmentIds) do
		---@type {type: string, herbs: table, rarePigments: table}
		local info = pigmentMap[pigmentId]
		local pigmentName = GetItemInfo(pigmentId) or ("Pigment " .. pigmentId)

		-- Sort herbs by rarity (higher quality first), then by ID
		local herbsList = info.herbs ---@type number[]
		---@cast herbsList number[]
		local sortedHerbs = {} ---@type number[]
		for _, herbId in ipairs(herbsList) do
			table.insert(sortedHerbs, herbId)
		end
		---@param a number
		---@param b number
		table.sort(sortedHerbs, function(a, b)
			local qualityA = getItemRarity(a)
			local qualityB = getItemRarity(b)
			if qualityA ~= qualityB then
				return qualityA > qualityB -- Higher quality first
			else
				return a < b   -- Then by ID for consistency
			end
		end)

		-- Create group entry with result and sources
		table.insert(data, {
			type = "group",
			result = {
				---@type number
				itemId = pigmentId,
				name = pigmentName,
				---@type string
				rarity = info.type,
				---@type table
				rarePigments = info.rarePigments
			},
			---@type number[]
			sources = sortedHerbs -- Use sorted herbs
		})
	end

	return data
end

local function createProspectingScrollData()
	local data = {}

	-- CRITICAL: Check if database is loaded
	if not Skillet.PROSPECTING_DATA then
		DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Skillet] ERROR: PROSPECTING_DATA not loaded!|r")
		return data -- Return empty table
	end

	-- Define ore tier groups
	-- IMPORTANT: Only group ores that share ALL their output gems (even if drop rates differ)
	-- IMPORTANT: Titanium separate because it has 18 possible gems (needs special layout)
	local oreTiers = {
		{
			name = "Copper Ore",
			ores = { 2770 }, -- Copper Ore
			expansion = "vanilla"
		},
		{
			name = "Tin Ore",
			ores = { 2771 }, -- Tin Ore
			expansion = "vanilla"
		},
		{
			name = "Iron Ore",
			ores = { 2772 }, -- Iron Ore
			expansion = "vanilla"
		},
		{
			name = "Mithril Ore",
			ores = { 3858 }, -- Mithril Ore
			expansion = "vanilla"
		},
		{
			name = "Thorium Ore",
			ores = { 10620 }, -- Thorium Ore
			expansion = "vanilla"
		},
		{
			name = "Fel Iron/Adamantite",
			ores = { 23424, 23425 }, -- Fel Iron Ore, Adamantite Ore (share same gems)
			expansion = "tbc"
		},
		{
			name = "Cobalt Ore",
			ores = { 36909 }, -- Cobalt Ore (6 common + 6 uncommon = 12 gems)
			expansion = "wrath"
		},
		{
			name = "Saronite Ore",
			ores = { 36912 }, -- Saronite Ore (6 common + 6 uncommon = 12 gems)
			expansion = "wrath"
		},
		{
			name = "Titanium Ore",
			ores = { 36910 }, -- Titanium Ore (18 total gems! - needs extended layout)
			expansion = "wrath",
			extended = true -- Flag for special layout
		}
	}

	-- Build groups based on ore tiers
	for _, tier in ipairs(oreTiers) do
		-- Collect all unique gems that can come from ANY ore in this tier
		---@type table<number, string>
		local gemSet = {}

		for _, oreId in ipairs(tier.ores) do
			local oreData = Skillet.PROSPECTING_DATA[oreId]
			if oreData then
				-- Add common gems
				if oreData.commonGems then
					for _, gemId in ipairs(oreData.commonGems) do
						---@type string
						gemSet[gemId] = "common"
					end
				end
				-- Add uncommon gems (overwrite rarity if already exists)
				if oreData.uncommonGems then
					for _, gemId in ipairs(oreData.uncommonGems) do
						---@type string
						gemSet[gemId] = "uncommon"
					end
				end
				-- Add rare gems (for Titanium ore)
				if oreData.rareGems then
					for _, gemId in ipairs(oreData.rareGems) do
						---@type string
						gemSet[gemId] = "rare"
					end
				end
			end
		end

		-- Convert gem set to sorted list
		---@type {id: number, rarity: string}[]
		local gems = {}
		for gemId, rarity in pairs(gemSet) do
			---@cast gemId number
			---@cast rarity string
			table.insert(gems, { ---@type number
				id = gemId, ---@type string
				rarity = rarity
			})
		end

		-- Sort gems by rarity (higher quality first), then by ID
		---@param a {id: number, rarity: string}
		---@param b {id: number, rarity: string}
		table.sort(gems, function(a, b)
			local qualityA = getItemRarity(a.id)
			local qualityB = getItemRarity(b.id)
			if qualityA ~= qualityB then
				return qualityA > qualityB -- Higher quality first
			else
				return a.id < b.id -- Then by ID for consistency
			end
		end)

		if #gems > 0 then
			-- Create group entry:
			-- Result row = the ores in this tier
			-- Source rows = all gems these ores can produce
			table.insert(data, {
				type = "group",
				tierName = tier.name,
				expansion = tier.expansion,
				ores = tier.ores, -- The ores shown in result row
				gems = gems, -- The gems shown in source rows
				---@type boolean|nil
				extended = tier.extended -- Special flag for Titanium
			})
		end
	end

	return data
end

local function createConversionsScrollData()
	local data = {} ---@type ConversionGroup[]

	-- Check if conversion groups are loaded
	if not Skillet or not Skillet.CONVERSION_GROUPS then
		DEFAULT_CHAT_FRAME:AddMessage("[Skillet] CONVERSION_GROUPS not loaded!")
		return data
	end

	if Skillet:IsDevMode() then
		DEFAULT_CHAT_FRAME:AddMessage("[Skillet] Creating conversion scroll data, found " ..
			#Skillet.CONVERSION_GROUPS .. " groups")
	end

	-- Use hardcoded conversion groups directly
	---@type ConversionGroup[]
	Skillet.CONVERSION_GROUPS = Skillet.CONVERSION_GROUPS
	for _, group in ipairs(Skillet.CONVERSION_GROUPS) do
		-- Create conversion pairs from the hardcoded structure
		local conversionPairs = {}

		-- Each result item pairs with corresponding source item (1:1 mapping)
		local maxItems = math.min(#group.resultItems, #group.sourceItems)

		for i = 1, maxItems do
			---@type number
			local resultItem = group.resultItems[i]
			---@type number
			local sourceItem = group.sourceItems[i]

			-- Create the pair entry (compatible with existing display logic)
			table.insert(conversionPairs, {
				resultItem = resultItem,
				sourceItem = sourceItem, -- Single source item for compatibility
				bidirectional = group.bidirectional,
				inputAmount = (group.inputAmount or 10) --[[@as number]],
				outputAmount = (group.outputAmount or 1) --[[@as number]],
				type = "hardcoded" -- Mark as using new system
			})
		end

		-- Add group to scroll data
		table.insert(data, {
			type = "conversion_group",
			title = group.label, -- Use the group label
			conversionPairs = conversionPairs,
			extended = group.extended -- Pass through extended flag for large layout
		})
	end

	if Skillet:IsDevMode() then
		DEFAULT_CHAT_FRAME:AddMessage("[Skillet] Created " .. #data .. " conversion groups for display")
	end

	return data
end


-- Generate pages from scroll data - each page contains layout info and group indices
---@param scrollData ConversionGroup[]|MillingGroup[]|ProspectingGroup[]
---@param currentTab string
---@return ExtractionPageData[]
local function generatePages(scrollData, currentTab)
	local pages = {} ---@type ExtractionPageData[]

	if not scrollData or #scrollData == 0 then
		return pages
	end

	if currentTab == "CONVERSIONS" then
		-- Conversions: check each group for extended layout
		---@cast scrollData ConversionGroup[]
		local i = 1
		while i <= #scrollData do
			local currentGroup = scrollData[i] ---@type ConversionGroup
			local page = {
				groupIndices = {}
			}

			-- Check if current group needs extended layout
			if currentGroup and currentGroup.extended then
				-- Extended layout: single group per page
				page.layout = "large"
				page.groupsPerPage = 1
				table.insert(page.groupIndices, i)
				i = i + 1
			else
				-- Small layout: try to fit 3 groups
				page.layout = "small"
				page.groupsPerPage = 3

				-- Add up to 3 non-extended groups
				for j = 1, 3 do
					if i <= #scrollData then
						local group = scrollData[i] ---@type ConversionGroup
						if not (group and group.extended) then
							table.insert(page.groupIndices, i)
							i = i + 1
						else
							break -- Stop if we hit an extended group
						end
					end
				end
			end

			table.insert(pages, page)
		end
	else
		-- For milling/prospecting, check each group individually for extended layout
		---@cast scrollData MillingGroup[]|ProspectingGroup[]
		local i = 1
		while i <= #scrollData do
			local currentGroup = scrollData[i] ---@type MillingGroup|ProspectingGroup
			local page = {
				groupIndices = {}
			}

			-- Check if current group needs extended layout
			if currentGroup and currentGroup.extended then
				-- Extended layout: single group per page
				page.layout = "large"
				page.groupsPerPage = 1
				table.insert(page.groupIndices, i)
				i = i + 1
			else
				-- Medium layout: try to fit 2 groups
				page.layout = "medium"
				page.groupsPerPage = 2

				-- Add current group
				table.insert(page.groupIndices, i)
				i = i + 1

				-- Try to add second group if it's not extended
				if i <= #scrollData then
					local nextGroup = scrollData[i] ---@type MillingGroup|ProspectingGroup
					if not (nextGroup and nextGroup.extended) then
						table.insert(page.groupIndices, i)
						i = i + 1
					end
				end
			end

			table.insert(pages, page)
		end
	end

	return pages
end

function Skillet:UpdateExtractionList()
	if Skillet:IsDevMode() then
		DEFAULT_CHAT_FRAME:AddMessage("[Skillet] UpdateExtractionList called for tab: " .. tostring(currentTab))
	end

	if currentTab == "MILLING" then
		scrollData = createMillingScrollData()
	elseif currentTab == "PROSPECTING" then
		scrollData = createProspectingScrollData()
	elseif currentTab == "CONVERSIONS" then
		scrollData = createConversionsScrollData()
	else
		-- Default fallback
		scrollData = createMillingScrollData()
	end

	if Skillet:IsDevMode() then
		DEFAULT_CHAT_FRAME:AddMessage("[Skillet] ScrollData has " .. #scrollData .. " entries")
	end

	-- Use the single scroll frame for all layouts
	local scrollFrame = getglobal("SkilletExtractionScrollFrame")
	if scrollFrame then
		-- Generate page-based data structure
		local pages = generatePages(scrollData, currentTab)

		if Skillet:IsDevMode() then
			DEFAULT_CHAT_FRAME:AddMessage("[Skillet] Generated " .. #pages .. " pages")
		end

		-- Store pages for display function (declare as local to avoid global warning)
		-- EmmyLua: pages is local, _G.scrollPages is global for cross-function access, intentional design
		_G.scrollPages = pages -- Explicitly global for cross-function access

		-- Configure scroll frame with exact number of pages
		local totalInset = (BORDER_EDGE_SIZE / 2 + GROUP_PADDING)
		local maxGroupHeight = (totalInset * 2) + ITEM_HEIGHT + (2 * (ITEM_HEIGHT + ROW_SPACING))

		-- Reset to page 1
		currentPageIndex = 1

		if #pages <= 1 then
			-- No scrolling needed
			if scrollFrame then scrollFrame:Hide() end
		else
			-- Multiple pages - set up simple mouse wheel navigation

			if scrollFrame then
				scrollFrame:Show()

				-- Configure scrollbar range based on number of pages
				local scrollBar = getglobal(scrollFrame:GetName() .. "ScrollBar")
				if scrollBar then
					-- Set scroll range: 0 to (numPages - 1) * some step value
					-- We'll use a step of 100 for smooth scrollbar movement
					local maxScroll = (#pages - 1) * 100
					scrollBar:SetMinMaxValues(0, maxScroll)
					scrollBar:SetValueStep(100)
					scrollBar:SetValue(0) -- Start at page 1

					-- Bidirectional sync: when scrollbar is manually moved, update page
					scrollBar:SetScript("OnValueChanged", function(self, value)
						local newPageIndex = math.floor(value / 100) + 1
						newPageIndex = math.max(1, math.min(newPageIndex, #_G.scrollPages))

						if newPageIndex ~= currentPageIndex then
							currentPageIndex = newPageIndex
							Skillet:UpdateExtractionListDisplay()
						end
					end)
				end

				-- Attach handler directly to scroll frame since it intercepts mouse events
				scrollFrame:EnableMouseWheel(true)
				scrollFrame:SetScript("OnMouseWheel", function(self, delta)
					if delta > 0 then
						-- Scroll up - previous page
						currentPageIndex = math.max(1, currentPageIndex - 1)
					else
						-- Scroll down - next page
						currentPageIndex = math.min(#_G.scrollPages, currentPageIndex + 1)
					end

					-- Update scrollbar visual position
					if scrollBar then
						scrollBar:SetValue((currentPageIndex - 1) * 100)
					end

					Skillet:UpdateExtractionListDisplay()
				end)
			end
		end

		self:UpdateExtractionListDisplay()
	end
end

---@param layout string The layout type ("small", "medium", or "large")
---@param groupsToShow number The number of groups to display
---@param groupIndices table Array of group indices to display (0-based)
---@param offset number The scroll offset (always 0 for page-based system)
local function updateGroupBorders(layout, groupsToShow, groupIndices, offset)
	local container = getglobal("SkilletExtractionContainer")
	if not container then return end

	for i = 1, groupsToShow do
		---@type integer|nil
		---@type integer|nil
		local groupIndex = groupIndices[i]
		if groupIndex and scrollData[groupIndex + 1] then -- Convert to 1-based index
			---@type table
			local group = scrollData[groupIndex + 1]
			---@type Frame|nil
			local border
			---@type FontString|nil
			local label
			---@type number
			local baseY

			if layout == "small" then
				-- Small layout: 3 groups, positions at -35, -135, -235
				baseY = -35 + ((i - 1) * -100)
				if not smallGroupBorders[i] then
					border, label = createSmallGroupBorder(i, container)
					smallGroupBorders[i] = border
					smallGroupLabels[i] = label
				end
				border = smallGroupBorders[i]
				label = smallGroupLabels[i]
			elseif layout == "large" then
				-- Large layout: 1 group, position at -35
				baseY = -35
				if not largeGroupBorder then
					border, label = createLargeGroupBorder(container)
					largeGroupBorder = border
					largeGroupLabel = label
				end
				border = largeGroupBorder
				label = largeGroupLabel
			else -- medium layout
				-- Medium layout: 2 groups, positions at -35, -170
				baseY = -35 + ((i - 1) * -135)
				if not mediumGroupBorders[i] then
					border, label = createMediumGroupBorder(i, container)
					mediumGroupBorders[i] = border
					mediumGroupLabels[i] = label
				end
				border = mediumGroupBorders[i]
				label = mediumGroupLabels[i]
			end

			-- Position and show border
			assert(border, "Border frame is nil")
			assert(label, "Label is nil")
			border:SetPoint("TOPLEFT", container, "TOPLEFT", 5, baseY)
			border:Show()

			-- Position and configure label
			label:SetPoint("TOPLEFT", container, "TOPLEFT", 15, baseY - 8)
			label:SetText(group.label or "Unknown Group")

			-- Add one-way warning if needed
			if group.bidirectional == false then
				label:SetText((group.label or "Unknown Group") .. " |cFFFF6666[One-Way]|r")
			end
			label:Show()
		end
	end
end

---@param layout string The layout type ("small", "medium", or "large")
---@param groupsToShow number The number of groups being shown
local function clearUnusedBorders(layout, groupsToShow)
	-- Clear unused small group borders
	if layout ~= "small" then
		for i = 1, 3 do
			if smallGroupBorders[i] then smallGroupBorders[i]:Hide() end
			if smallGroupLabels[i] then smallGroupLabels[i]:Hide() end
		end
	else
		-- In small layout, hide borders beyond groupsToShow
		for i = groupsToShow + 1, 3 do
			if smallGroupBorders[i] then smallGroupBorders[i]:Hide() end
			if smallGroupLabels[i] then smallGroupLabels[i]:Hide() end
		end
	end

	-- Clear unused medium group borders
	if layout ~= "medium" then
		for i = 1, 2 do
			if mediumGroupBorders[i] then mediumGroupBorders[i]:Hide() end
			if mediumGroupLabels[i] then mediumGroupLabels[i]:Hide() end
		end
	else
		-- In medium layout, hide borders beyond groupsToShow
		for i = groupsToShow + 1, 2 do
			if mediumGroupBorders[i] then mediumGroupBorders[i]:Hide() end
			if mediumGroupLabels[i] then mediumGroupLabels[i]:Hide() end
		end
	end

	-- Clear unused large group border
	if layout ~= "large" then
		if largeGroupBorder then largeGroupBorder:Hide() end
		if largeGroupLabel then largeGroupLabel:Hide() end
	end
end

---@param buttonName string The button name (e.g. "SkilletExtractionSmallButton1")
---@param group ConversionGroup|MillingGroup|ProspectingGroup The group data to display in this button
local function updateButtonForGroup(buttonName, group)
	local button = getglobal(buttonName)
	if not button or not group then return end

	-- Determine button positioning based on tab type and group structure
	if currentTab == "CONVERSIONS" and group.conversionPairs then
		-- Handle conversions: display conversion pairs in result/source layout
		---@cast group ConversionGroup
		local buttonsPerGroup = 12 -- 6 result + 6 source
		local buttonIndex = tonumber(string.match(buttonName, "%d+"))
		local groupSlot = math.floor((buttonIndex - 1) / buttonsPerGroup) + 1
		local positionInGroup = ((buttonIndex - 1) % buttonsPerGroup) + 1

		if positionInGroup <= 6 then
			-- Result buttons (1-6): show result items
			local pair = group.conversionPairs[positionInGroup] ---@type ConversionPair
			if pair and pair.resultItem then
				local border = smallGroupBorders and smallGroupBorders[groupSlot]
				setupExtractionButton(button, "SkilletExtractionSmallButton", buttonIndex,
					pair.resultItem, 0, positionInGroup, border,
					setupConversionButtonClicks, pair)
			else
				button:Hide()
			end
		else
			-- Source buttons (7-12): show source items
			local pairIndex = positionInGroup - 6
			local pair = group.conversionPairs[pairIndex] ---@type ConversionPair
			if pair and pair.sourceItem then
				local border = smallGroupBorders and smallGroupBorders[groupSlot]
				setupExtractionButton(button, "SkilletExtractionSmallButton", buttonIndex,
					pair.sourceItem, 1, pairIndex, border,
					setupConversionButtonClicks, pair)
			else
				button:Hide()
			end
		end
	elseif currentTab == "MILLING" and group.result then
		-- Handle milling: main pigment + rare pigments in result row, herbs in source rows
		---@cast group MillingGroup
		local buttonIndex = tonumber(string.match(buttonName, "%d+"))
		local buttonPrefix = string.match(buttonName, "(.+)%d+")
		local groupSlot = math.floor((buttonIndex - 1) / BUTTONS_PER_GROUP) + 1
		local positionInGroup = ((buttonIndex - 1) % BUTTONS_PER_GROUP) + 1
		local border = largeGroupBorder or (mediumGroupBorders and mediumGroupBorders[groupSlot])

		if positionInGroup == 1 then
			-- Main pigment result
			setupExtractionButton(button, buttonPrefix, buttonIndex, group.result.itemId,
				0, 1, border, nil, nil)
		elseif positionInGroup <= 6 then
			-- Rare pigments (positions 2-6)
			local rareIndex = positionInGroup - 1
			if group.result.rarePigments and group.result.rarePigments[rareIndex] then
				setupExtractionButton(button, buttonPrefix, buttonIndex,
					group.result.rarePigments[rareIndex], 0, positionInGroup, border, nil, nil)
			else
				button:Hide()
			end
		else
			-- Source herbs (positions 7-18)
			local sourceIndex = positionInGroup - 6
			if group.sources and group.sources[sourceIndex] then
				local row = math.floor((sourceIndex - 1) / 6) + 1 -- Row 1-2 for herbs (after row 0 pigments)
				local col = ((sourceIndex - 1) % 6) + 1
				setupExtractionButton(button, buttonPrefix, buttonIndex, group.sources[sourceIndex],
					row, col, border, setupSourceButtonClicks, group.sources[sourceIndex])
			else
				button:Hide()
			end
		end
	elseif currentTab == "PROSPECTING" and group.ores then
		-- Handle prospecting: ores in result row, gems in source rows
		---@cast group ProspectingGroup
		local buttonIndex = tonumber(string.match(buttonName, "%d+"))
		local buttonPrefix = string.match(buttonName, "(.+)%d+")
		local groupSlot = math.floor((buttonIndex - 1) / BUTTONS_PER_GROUP) + 1
		local positionInGroup = ((buttonIndex - 1) % BUTTONS_PER_GROUP) + 1
		local border = largeGroupBorder or (mediumGroupBorders and mediumGroupBorders[groupSlot])

		if positionInGroup <= 6 then
			-- Ore buttons (positions 1-6)
			if group.ores[positionInGroup] then
				setupExtractionButton(button, buttonPrefix, buttonIndex, group.ores[positionInGroup],
					0, positionInGroup, border, setupSourceButtonClicks, group.ores[positionInGroup])
			else
				button:Hide()
			end
		else
			-- Gem buttons (positions 7+)
			local gemIndex = positionInGroup - 6
			local maxGems = group.extended and 30 or 12
			if gemIndex <= maxGems and group.gems and group.gems[gemIndex] then
				local gemData = group.gems[gemIndex] ---@type GemData
				if gemData and gemData.id then
					local row = math.floor((gemIndex - 1) / 6) + 1 -- Row 1+ for gems (after row 0 ores)
					local col = ((gemIndex - 1) % 6) + 1
					setupExtractionButton(button, buttonPrefix, buttonIndex, gemData.id,
						row, col, border, nil, nil)
				else
					button:Hide()
				end
			else
				button:Hide()
			end
		end
	else
		-- Unknown group type or tab - hide button
		button:Hide()
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
	if not itemId or type(itemId) ~= "number" then
		return nil, nil
	end

	for bag = 0, 4 do
		local numSlots = GetContainerNumSlots(bag)
		if numSlots and numSlots > 0 then
			for slot = 1, numSlots do
				local _, count, _, _, _, _, link = GetContainerItemInfo(bag, slot)
				if link then
					local foundItemId = Skillet:GetItemIDFromLink(link)
					if foundItemId and foundItemId == itemId then
						return bag, slot
					end
				end
			end
		end
	end
	return nil, nil
end

-- Setup click handler for a source button
---@param button ExtractionConversionButton
---@param sourceId number
local function setupSourceButtonClicks(button, sourceId)
	if not button then return end
	if not sourceId or type(sourceId) ~= "number" then return end

	-- Enable the button
	button:Enable()

	-- Register for left and right clicks
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	-- Set up SecureActionButton attributes for left-click spell casting
	-- Check if we have >= 5 items to determine whether to cast or withdraw
	local bagsCount = GetItemCount(sourceId, false) or 0
	---@cast bagsCount number

	if bagsCount >= 5 then
		-- Enough items: set up spell casting
		-- Use spell IDs for reliability (names can vary with localization)
		-- Milling: 51005 (regular), 80348 (Mass Milling)
		-- Prospecting: 31252 (regular), 80347 (Mass Prospecting)
		---@type number
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
					---@type number
					local targetBag = self:GetAttribute("target-bag")
					---@type number
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
			---@cast currentBagsCount number
			if currentBagsCount < 5 then
				-- Not enough items, withdraw from resource bank
				local itemName = GetItemInfo(sourceId)
				if not itemName then itemName = "item " .. tostring(sourceId) end
				if Skillet and Skillet.Print and Skillet.WithdrawFromResourceBank then
					Skillet:Print("|cFF00FF00Withdrawing " .. itemName .. " from Resource Bank...|r")
					Skillet:WithdrawFromResourceBank(sourceId, true)
				end
			else
				-- We had >= 5 items but spell didn't cast - provide feedback
				local itemName = GetItemInfo(sourceId)
				if not itemName then itemName = "item " .. tostring(sourceId) end
				local spellId = currentTab == "MILLING" and (bulkMode and 80348 or 51005) or
					(bulkMode and 80347 or 31252)
				local spellName = GetSpellInfo(spellId)
				if not spellName then spellName = "Spell " .. tostring(spellId) end
				if Skillet and Skillet.Print then
					Skillet:Print("|cFFFF0000Attempted to cast " ..
						spellName .. " (ID:" .. tostring(spellId) .. ") on " .. itemName .. "|r")
				end
			end
		elseif mouseButton == "RightButton" then
			-- Right click: Deposit this specific item to resource bank
			local itemName = GetItemInfo(sourceId)
			if not itemName then itemName = "item " .. tostring(sourceId) end
			if Skillet and Skillet.Print and Skillet.DepositToResourceBank then
				Skillet:Print("|cFF00FF00Depositing " .. itemName .. " to Resource Bank...|r")
				Skillet:DepositToResourceBank(sourceId, true)
			end
		end
	end)
end

function Skillet:UpdateExtractionListDisplay()
	-- Create borders lazily on first display (Container must exist)
	local needsRecreation = not mediumGroupBorders[1]
	local container = getglobal("SkilletExtractionContainer")
	if mediumGroupBorders[1] and not mediumGroupBorders[1]:GetParent() then
		mediumGroupBorders = {}
		largeGroupBorder = nil
		smallGroupBorders = {}
		needsRecreation = true
	end

	if container and needsRecreation then
		initializeButtonPositions()
	end

	-- Use our own page tracking
	if not _G.scrollPages or #_G.scrollPages == 0 then return end

	-- Clamp page index to valid range
	if currentPageIndex < 1 then currentPageIndex = 1 end
	if currentPageIndex > #_G.scrollPages then currentPageIndex = #_G.scrollPages end

	local currentPage = _G.scrollPages[currentPageIndex] ---@type ExtractionPageData
	if not currentPage then return end

	-- Hide all buttons first
	for i = 1, 36 do
		local smallButton = getglobal("SkilletExtractionSmallButton" .. i)
		local mediumButton = getglobal("SkilletExtractionMediumButton" .. i)
		local largeButton = getglobal("SkilletExtractionLargeButton" .. i)
		if smallButton then smallButton:Hide() end
		if mediumButton then mediumButton:Hide() end
		if largeButton then largeButton:Hide() end
	end

	-- Hide all borders initially
	for i = 1, 3 do
		if smallGroupBorders and smallGroupBorders[i] then
			smallGroupBorders[i]:Hide()
			if smallGroupBorders[i].label then
				smallGroupBorders[i].label:Hide()
			end
		end
	end
	for i = 1, 2 do
		if mediumGroupBorders[i] then mediumGroupBorders[i]:Hide() end
	end
	if largeGroupBorder then
		largeGroupBorder:Hide()
		if largeGroupBorder.label then
			largeGroupBorder.label:Hide()
		end
	end

	-- Display groups for current page
	for displaySlot, groupIndex in ipairs(currentPage.groupIndices) do
		local group = scrollData[groupIndex] ---@type ConversionGroup|MillingGroup|ProspectingGroup
		if group then
			-- Show appropriate border and populate data
			if currentPage.layout == "small" then
				-- Show small border and update label
				if smallGroupBorders and smallGroupBorders[displaySlot] then
					smallGroupBorders[displaySlot]:Show()
					if smallGroupBorders[displaySlot].label and group.title then
						smallGroupBorders[displaySlot].label:SetText(group.title)
						smallGroupBorders[displaySlot].label:Show()
					end
				end

				-- Populate conversion buttons for this group
				if currentTab == "CONVERSIONS" and group.conversionPairs then
					local buttonsPerGroup = 12 -- 6 result + 6 source
					local startButton = (displaySlot - 1) * buttonsPerGroup + 1

					for i = 1, 12 do
						local buttonIndex = startButton + i - 1
						local button = getglobal("SkilletExtractionSmallButton" .. buttonIndex)
						if button then
							if i <= 6 then
								-- Result buttons (1-6): show result items
								local pair = group.conversionPairs[i]
								if pair and pair.resultItem then
									local border = smallGroupBorders and smallGroupBorders[displaySlot]
									setupExtractionButton(button, "SkilletExtractionSmallButton", buttonIndex,
										pair.resultItem, 0, i, border,
										setupConversionButtonClicks, pair)
									button:Show()
								else
									button:Hide()
								end
							else
								-- Source buttons (7-12): show source items
								local pairIndex = i - 6
								local pair = group.conversionPairs[pairIndex]
								if pair and pair.sourceItem then
									local border = smallGroupBorders and smallGroupBorders[displaySlot]
									setupExtractionButton(button, "SkilletExtractionSmallButton", buttonIndex,
										pair.sourceItem, 1, pairIndex, border,
										setupConversionButtonClicks, pair)
									button:Show()
								else
									button:Hide()
								end
							end
						end
					end
				end
			elseif currentPage.layout == "medium" then
				-- Show medium border
				if mediumGroupBorders[displaySlot] then
					mediumGroupBorders[displaySlot]:Show()
				end

				-- Populate milling/prospecting buttons for this group
				if currentTab == "MILLING" and group.result then
					-- MILLING: 6 result slots (common pigment + rare pigments), 12 source slots (herbs)
					local startButton = (displaySlot - 1) * 18 + 1 -- 18 buttons per group in medium
					local border = mediumGroupBorders[displaySlot]

					-- First result button: main common pigment
					local button = getglobal("SkilletExtractionMediumButton" .. startButton)
					if button then
						setupExtractionButton(button, "SkilletExtractionMediumButton", startButton,
							group.result.itemId, 0, 1, border, nil, nil)
						button:Show()
					end

					-- Remaining result buttons: rare pigments (up to 5 more)
					if group.result.rarePigments then
						for rareIndex = 1, math.min(5, #group.result.rarePigments) do
							local buttonIndex = startButton + rareIndex
							local rareButton = getglobal("SkilletExtractionMediumButton" .. buttonIndex)
							if rareButton then
								setupExtractionButton(rareButton, "SkilletExtractionMediumButton", buttonIndex,
									group.result.rarePigments[rareIndex], 0, rareIndex + 1, border, nil, nil)
								rareButton:Show()
							end
						end
					end

					-- Source buttons: herb sources (up to 12 herbs in 2 rows of 6)
					for sourceIndex = 1, math.min(12, #group.sources) do
						local buttonIndex = startButton + 6 + sourceIndex - 1 -- Start after 6 result buttons
						local sourceButton = getglobal("SkilletExtractionMediumButton" .. buttonIndex)
						if sourceButton then
							local row = math.floor((sourceIndex - 1) / 6) + 1 -- Row 1-2 for herbs (after row 0 pigments)
							local col = ((sourceIndex - 1) % 6) + 1 -- Column 1-6
							setupExtractionButton(sourceButton, "SkilletExtractionMediumButton", buttonIndex,
								group.sources[sourceIndex], row, col, border, setupSourceButtonClicks,
								group.sources[sourceIndex])
							sourceButton:Show()
						end
					end
				elseif currentTab == "PROSPECTING" and group.ores then
					-- PROSPECTING: 6 result slots (ores), 12 source slots (gems in 2 rows of 6)
					local startButton = (displaySlot - 1) * 18 + 1 -- 18 buttons per group in medium
					local border = mediumGroupBorders[displaySlot]

					-- Result buttons: ores (up to 6)
					for oreIndex = 1, math.min(6, #group.ores) do
						local buttonIndex = startButton + oreIndex - 1
						local oreButton = getglobal("SkilletExtractionMediumButton" .. buttonIndex)
						if oreButton then
							setupExtractionButton(oreButton, "SkilletExtractionMediumButton", buttonIndex,
								group.ores[oreIndex], 0, oreIndex, border, setupSourceButtonClicks, group.ores[oreIndex])
							oreButton:Show()
						end
					end

					-- Source buttons: gems (up to 12 gems in 2 rows of 6)
					for gemIndex = 1, math.min(12, #group.gems) do
						local buttonIndex = startButton + 6 + gemIndex - 1 -- Start after 6 result buttons
						local gemButton = getglobal("SkilletExtractionMediumButton" .. buttonIndex)
						if gemButton and group.gems[gemIndex] then
							local row = math.floor((gemIndex - 1) / 6) + 1 -- Row 1-2 for gems (after row 0 ores)
							local col = ((gemIndex - 1) % 6) + 1 -- Column 1-6
							setupExtractionButton(gemButton, "SkilletExtractionMediumButton", buttonIndex,
								group.gems[gemIndex].id, row, col, border, nil, nil)
							gemButton:Show()
						end
					end
				end
			else -- large layout
				-- Show large border and label
				if largeGroupBorder then
					largeGroupBorder:Show()
					if largeGroupLabel and group.title then
						largeGroupLabel:SetText(group.title)
						largeGroupLabel:Show()
					end
				end

				-- Populate extended layout for this group (single group spans all 25 buttons)
				if currentTab == "CONVERSIONS" and group.conversionPairs then
					-- CONVERSIONS LARGE LAYOUT: 7 conversion pairs in 4 rows (alternating Greater/Lesser)
					-- Row 0: Greater essences #1-4 (Cosmic, Planar, Eternal, Nether)
					-- Row 1: Lesser essences #1-4 (Cosmic, Planar, Eternal, Nether)
					-- Row 2: Greater essences #5-7 (Mystic, Astral, Magic)
					-- Row 3: Lesser essences #5-7 (Mystic, Astral, Magic)

					-- ROW 0: Greater essences #1-4
					for pairIndex = 1, math.min(4, #group.conversionPairs) do
						local pair = group.conversionPairs[pairIndex]
						if pair and pair.resultItem then
							local buttonIndex = pairIndex
							local button = getglobal("SkilletExtractionLargeButton" .. buttonIndex)
							if button then
								setupExtractionButton(button, "SkilletExtractionLargeButton", buttonIndex,
									pair.resultItem, 0, pairIndex, largeGroupBorder,
									setupConversionButtonClicks, pair)
								button:Show()
							end
						end
					end

					-- ROW 1: Lesser essences #1-4
					for pairIndex = 1, math.min(4, #group.conversionPairs) do
						local pair = group.conversionPairs[pairIndex]
						if pair and pair.sourceItem then
							local buttonIndex = 7 + (pairIndex - 1)
							local button = getglobal("SkilletExtractionLargeButton" .. buttonIndex)
							if button then
								setupExtractionButton(button, "SkilletExtractionLargeButton", buttonIndex,
									pair.sourceItem, 1, pairIndex, largeGroupBorder,
									setupConversionButtonClicks, pair)
								button:Show()
							end
						end
					end

					-- ROW 2: Greater essences #5-7
					for pairIndex = 5, math.min(7, #group.conversionPairs) do
						local pair = group.conversionPairs[pairIndex]
						if pair and pair.resultItem then
							local buttonIndex = 13 + (pairIndex - 5)
							local button = getglobal("SkilletExtractionLargeButton" .. buttonIndex)
							if button then
								setupExtractionButton(button, "SkilletExtractionLargeButton", buttonIndex,
									pair.resultItem, 2, (pairIndex - 4), largeGroupBorder,
									setupConversionButtonClicks, pair)
								button:Show()
							end
						end
					end

					-- ROW 3: Lesser essences #5-7
					for pairIndex = 5, math.min(7, #group.conversionPairs) do
						local pair = group.conversionPairs[pairIndex]
						if pair and pair.sourceItem then
							local buttonIndex = 19 + (pairIndex - 5)
							local button = getglobal("SkilletExtractionLargeButton" .. buttonIndex)
							if button then
								setupExtractionButton(button, "SkilletExtractionLargeButton", buttonIndex,
									pair.sourceItem, 3, (pairIndex - 4), largeGroupBorder,
									setupConversionButtonClicks, pair)
								button:Show()
							end
						end
					end
				elseif currentTab == "PROSPECTING" and group.ores and group.extended then
					-- EXTENDED PROSPECTING (like Titanium): show ore(s) in first row, gems in 6-column grid
					local startButton = 1

					-- Show ore(s) in result row (up to 6 ores)
					for oreIndex = 1, math.min(6, #group.ores) do
						local oreButton = getglobal("SkilletExtractionLargeButton" .. (startButton + oreIndex - 1))
						if oreButton then
							setupExtractionButton(oreButton, "SkilletExtractionLargeButton", startButton + oreIndex - 1,
								group.ores[oreIndex], 0, oreIndex, largeGroupBorder, setupSourceButtonClicks,
								group.ores[oreIndex])
							oreButton:Show()
						end
					end

					-- Show gems in 6-column grid (up to 18 gems in 3 rows)
					for gemIndex = 1, math.min(18, #group.gems) do
						local buttonIndex = startButton + 6 + gemIndex - 1 -- Start after 6 result buttons
						local gemButton = getglobal("SkilletExtractionLargeButton" .. buttonIndex)
						if gemButton and group.gems[gemIndex] then
							local row = math.floor((gemIndex - 1) / 6) + 1 -- Row 1-3 for gems (after row 0 ores)
							local col = ((gemIndex - 1) % 6) + 1 -- Column 1-6
							setupExtractionButton(gemButton, "SkilletExtractionLargeButton", buttonIndex,
								group.gems[gemIndex].id, row, col, largeGroupBorder, nil, nil)
							gemButton:Show()
						end
					end
				elseif group.result then
					-- Standard large layout for other content
					-- First button: main result
					local button = getglobal("SkilletExtractionLargeButton1")
					if button then
						setupExtractionButton(button, "SkilletExtractionLargeButton", 1,
							group.result.itemId, 0, 1, largeGroupBorder, nil, nil)
						button:Show()
					end

					-- Remaining 24 buttons: source items
					for sourceIndex = 1, math.min(24, #group.sources) do
						local buttonIndex = sourceIndex + 1
						local sourceButton = getglobal("SkilletExtractionLargeButton" .. buttonIndex)
						if sourceButton then
							local row = math.floor((sourceIndex - 1) / 6) + 1 -- Row 1+ (after row 0 result)
							local col = ((sourceIndex - 1) % 6) + 1 -- Column 1-6
							setupExtractionButton(sourceButton, "SkilletExtractionLargeButton", buttonIndex,
								group.sources[sourceIndex], row, col, largeGroupBorder, nil, nil)
							sourceButton:Show()
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
		local conversionsButton = getglobal("SkilletExtractionConversionsButton")
		if conversionsButton then
			conversionsButton:UnlockHighlight()
		end
	elseif tab == "PROSPECTING" then
		-- Highlight prospecting button
		if SkilletExtractionMillingButton then
			SkilletExtractionMillingButton:UnlockHighlight()
		end
		if SkilletExtractionProspectingButton then
			SkilletExtractionProspectingButton:LockHighlight()
		end
		local conversionsButton = getglobal("SkilletExtractionConversionsButton")
		if conversionsButton then
			conversionsButton:UnlockHighlight()
		end
	elseif tab == "CONVERSIONS" then
		-- Highlight conversions button
		if SkilletExtractionMillingButton then
			SkilletExtractionMillingButton:UnlockHighlight()
		end
		if SkilletExtractionProspectingButton then
			SkilletExtractionProspectingButton:UnlockHighlight()
		end
		local conversionsButton = getglobal("SkilletExtractionConversionsButton")
		if conversionsButton then
			conversionsButton:LockHighlight()
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

		-- Debug helper: Dump all pigment tooltips to chat
		-- (disabled by default - uncomment to debug tooltip data)
		--[[
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
			---@type Tooltip
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
		]]
	end

	-- Clear any orphaned borders from previous sessions
	if mediumGroupBorders[1] or mediumGroupBorders[2] or largeGroupBorder or (smallGroupBorders and (smallGroupBorders[1] or smallGroupBorders[2] or smallGroupBorders[3])) then
		mediumGroupBorders = {}
		largeGroupBorder = nil
		smallGroupBorders = {}
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
	-- Bulk mode toggled (silent)

	-- Update all active button click handlers with new bulk mode state
	-- Need to update buttons in BOTH layouts (Medium and Big)
	for i = 1, 36 do
		local mediumButton = getglobal("SkilletExtractionMediumButton" .. i)
		local bigButton = getglobal("SkilletExtractionBigButton" .. i)

		if mediumButton and mediumButton:IsVisible() and mediumButton.itemId then
			setupSourceButtonClicks(mediumButton, mediumButton.itemId)
		end
		if bigButton and bigButton:IsVisible() and bigButton.itemId then
			setupSourceButtonClicks(bigButton, bigButton.itemId)
		end
	end
end

function Skillet:IsExtractionBulkMode()
	return bulkMode
end
