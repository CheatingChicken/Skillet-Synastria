-- SkilletExtraction.lua: Extraction System for Prospecting and Milling
-- This module handles ore->gem (Prospecting) and herb->pigment (Milling) extractions
-- Unlike conversions (1:1 deterministic), extractions are probabilistic (1:many random)
--
-- NOTE: Data tables have been moved to Databases/ folder:
--   - ProspectingData.lua: PROSPECTING_DATA table
--   - MillingData.lua: MILLING_DATA table
--   - ConversionData.lua: CONVERSION_DEFINITIONS and CONVERSION_GROUPS tables

-- Namespace
Skillet = Skillet or {}

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

-- Get prospecting information for an ore
function Skillet:GetProspectingInfo(oreId)
	return self.PROSPECTING_DATA[oreId]
end

-- Get milling information for a herb
function Skillet:GetMillingInfo(herbId)
	return self.MILLING_DATA[herbId]
end

-- Check if item can be prospected
function Skillet:CanProspect(itemId)
	return self.PROSPECTING_DATA[itemId] ~= nil
end

-- Check if item can be milled
function Skillet:CanMill(itemId)
	return self.MILLING_DATA[itemId] ~= nil
end

-- Get all possible results from prospecting an ore
function Skillet:GetProspectingResults(oreId)
	local data = self.PROSPECTING_DATA[oreId]
	if not data then return nil end

	local results = {}

	-- Add common gems
	if data.commonGems then
		for _, gemId in ipairs(data.commonGems) do
			table.insert(results, { itemId = gemId, rarity = "common" })
		end
	end

	-- Add uncommon gems
	if data.uncommonGems then
		for _, gemId in ipairs(data.uncommonGems) do
			table.insert(results, { itemId = gemId, rarity = "uncommon" })
		end
	end

	return results
end

-- Get all possible results from milling a herb
function Skillet:GetMillingResults(herbId)
	local data = self.MILLING_DATA[herbId]
	if not data then return nil end

	local results = {}

	-- Add common pigments
	if data.commonPigments then
		for _, pigmentId in ipairs(data.commonPigments) do
			table.insert(results, { itemId = pigmentId, rarity = "common" })
		end
	end

	-- Add rare pigments
	if data.rarePigments then
		for _, pigmentId in ipairs(data.rarePigments) do
			table.insert(results, { itemId = pigmentId, rarity = "rare" })
		end
	end

	return results
end

Skillet:Print("SkilletExtraction module loaded")
