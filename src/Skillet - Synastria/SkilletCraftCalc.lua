--[[
SkilletCraftCalc.lua - Background Craftability Calculator
Handles background calculation of craftable counts to prevent UI freezing

Uses coroutines similar to Routes TSP solver to spread calculations across
multiple frames, preventing the game from freezing when opening professions
with many recipes.
]] --

if not Skillet then
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Skillet] Error: Skillet not loaded when CraftCalc initialized!|r")
    return
end

local SkilletCraftCalc = {}
Skillet.CraftCalc = SkilletCraftCalc

-- Localize globals for performance
local coroutine = coroutine
local pairs = pairs
local ipairs = ipairs
local math = math
local type = type

-- Update frame for background processing
local CalcUpdateFrame = CreateFrame("Frame")
CalcUpdateFrame.running = false
CalcUpdateFrame.yieldCounter = 0
CalcUpdateFrame.yieldInterval = 10 -- Yield every N recipe calculations (reduced from 50 to prevent freezing)

-- Cached results
local craftabilityCache = {}

function SkilletCraftCalc:ClearCache()
    craftabilityCache = {}
end

function SkilletCraftCalc:GetCachedCraftability(profession, recipeIndex, includeBank, includeResBank, includeAlts)
    local key = string.format("%s:%d:%s:%s:%s",
        profession or "nil",
        recipeIndex or 0,
        tostring(includeBank),
        tostring(includeResBank),
        tostring(includeAlts))
    return craftabilityCache[key]
end

function SkilletCraftCalc:SetCachedCraftability(profession, recipeIndex, includeBank, includeResBank, includeAlts, value)
    local key = string.format("%s:%d:%s:%s:%s",
        profession or "nil",
        recipeIndex or 0,
        tostring(includeBank),
        tostring(includeResBank),
        tostring(includeAlts))
    craftabilityCache[key] = value
end

-- Background calculation coroutine
function SkilletCraftCalc:CalculateCraftability(profession, yieldInterval)
    yieldInterval = yieldInterval or 10 -- Reduced from 50
    local yieldCounter = 0
    local lastProgressReport = 0

    -- Ensure at least one yield is called
    coroutine.yield()

    local lib = AceLibrary("SkilletStitch-1.1")
    if not lib or not lib.data or not lib.data[profession] then
        return
    end

    local recipes = lib.data[profession]
    local count = 0
    local totalRecipes = 0

    -- Count total recipes first
    for index, recipeData in pairs(recipes) do
        if type(recipeData) == "table" then
            totalRecipes = totalRecipes + 1
        end
    end

    -- Iterate through all recipes in the profession
    for index, recipeData in pairs(recipes) do
        if type(recipeData) == "table" then
            -- Use GetItemDataByIndex to get the cached recipe object
            -- This ensures we're using the SAME object the UI will use
            local recipe = lib:GetItemDataByIndex(profession, index)
            if recipe and recipe.name then
                -- Check if recipe needs rescanning (missing encoded data)
                if recipe.needsRescan then
                    -- Silent skip
                else
                    -- Check if recipe has reagents (decoded properly)
                    -- Synastria: Check modern reagents table format
                    local hasReagents = recipe.reagents and #recipe.reagents > 0

                    if not hasReagents then
                        -- Silent skip
                    else
                        -- Calculate craftability WITH sub-reagent checking
                        -- Each call will cache its result automatically

                        -- Calculate craftability (bags+resbank and bags+bank+resbank)
                        -- Note: bags now ALWAYS includes resource bank
                        -- Synastria: Force recalc enabled for now to ensure fresh calculations on every open
                        -- This bypasses cache reads but still writes results to cache
                        -- Performance is acceptable with coroutine-based background calculation
                        local numBagsResbank = self:CalculateRecipeCraftability(recipe, lib, false, false, 0, true)
                        local numBankResbank = self:CalculateRecipeCraftability(recipe, lib, true, false, 0, true)
                    end
                end

                count = count + 1
                yieldCounter = yieldCounter + 1

                -- Yield periodically to prevent freezing
                if yieldCounter >= yieldInterval then
                    yieldCounter = 0
                    coroutine.yield()
                end
            end
        end
    end

    return count
end

-- Calculate a single recipe's craftability with sub-reagent checking
---@param recipe Recipe The recipe to calculate
---@param lib table The Stitch library instance
---@param includeBank boolean Whether to include bank items
---@param verbose boolean Whether to print debug messages
---@param depth number|nil Current recursion depth
---@param forceRecalc boolean|nil Force recalculation bypassing cache
---@return number craftable How many times the recipe can be crafted
function SkilletCraftCalc:CalculateRecipeCraftability(recipe, lib, includeBank, verbose, depth, forceRecalc)
    if not recipe or not recipe.name then
        return 0
    end

    -- Check if recipe needs rescanning
    if recipe.needsRescan then
        if verbose then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[SKIPPED] " .. recipe.name .. " - needs rescan|r")
        end
        return 0
    end

    -- Safety check: ensure recipe has reagents array (modern format)
    if type(recipe) ~= "table" or not recipe.reagents or #recipe.reagents == 0 then
        return 0
    end

    depth = depth or 0
    forceRecalc = forceRecalc or false
    includeBank = includeBank or false
    local indent = string.rep("  ", depth)

    -- Check cache first - UNLESS we're forcing recalculation
    -- Note: "num" now includes resource bank automatically
    local cacheKey = includeBank and "numcraftablewbank" or "numcraftable"
    local sourceText = includeBank and "bags+bank+resbank" or "bags+resbank"

    if not forceRecalc then
        local cached = lib:GetCachedCraftability(recipe, cacheKey)
        if cached ~= nil then
            return cached
        end
    end

    -- Special detailed logging for Titansteel - DISABLED
    local isTitansteel = false -- Disabled debug logging

    -- Cache miss - track it
    local stats = lib:GetCacheStats()
    if stats then
        stats.misses = stats.misses + 1
        stats.calculations = stats.calculations + 1
    end

    local num = 0

    -- Synastria: Use modern reagents table format
    local reagents = recipe.reagents or {}

    -- Total reagents debug removed

    for _, reagent in ipairs(reagents) do
        -- Synastria: Vendor-buyable reagents are treated as always available (infinite)
        if reagent.vendor == true then
            -- Skip vendor items, they don't limit craftability
        else
            -- Non-vendor reagent - check availability and craftability
            local available = includeBank and reagent.numwbank or reagent.num

            -- Titansteel reagent debug removed

            -- Check if this reagent is craftable

            if available < reagent.needed then
                -- Shortage debug removed

                local reagentRecipe = lib:GetItemDataByName(reagent.name)
                if reagentRecipe then
                    -- Recursively calculate sub-reagent craftability
                    -- Pass forceRecalc to sub-recipes so they also bypass cache
                    local subCraftable = self:CalculateRecipeCraftability(reagentRecipe, lib, includeBank, verbose,
                        depth + 1, forceRecalc)
                    if subCraftable > 0 then
                        local addedAmount = subCraftable * (reagentRecipe.nummade or 1)
                        available = available + addedAmount
                        -- New total available debug removed
                    end
                end
            end

            local max = math.floor(available / reagent.needed) * recipe.nummade

            if num == 0 or max < num then
                num = max
            end
        end
    end

    if num == 0 then
        for _, reagent in ipairs(reagents) do
            -- Note: reagent.num now ALWAYS includes resource bank
            local available = includeBank and reagent.numwbank or reagent.num

            local max = math.floor(available / reagent.needed) * recipe.nummade
            if max < num then
                num = max
            end
        end
    end

    -- Cache the result before returning
    -- Always cache, even when forcing recalc (we just bypassed reading, but still want to store)
    lib:SetCachedCraftability(recipe, cacheKey, num)

    return num
end

-- OnUpdate handler for the calculation frame
function CalcUpdateFrame:OnUpdate(elapsed)
    local status, count = coroutine.resume(self.co)
    if status then
        if coroutine.status(self.co) == "dead" then
            -- Calculation finished
            self:SetScript("OnUpdate", nil)
            self.running = false

            if self.finishFunc then
                self.finishFunc(count)
                self.finishFunc = nil
            end

            self.co = nil
            self.profession = nil
        end
    else
        -- Error occurred
        self:SetScript("OnUpdate", nil)
        self.running = false
        self.co = nil
        self.finishFunc = nil
        self.profession = nil
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Skillet] Error in craftability calculation: " ..
            tostring(count) .. "|r")
    end
end

-- Start background calculation
function SkilletCraftCalc:StartBackgroundCalculation(profession, finishCallback, yieldInterval)
    if CalcUpdateFrame.running then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[Skillet] Craftability calculation already in progress|r")
        return false
    end

    -- Clear both caches for this profession
    self:ClearCache()

    -- Also clear the Stitch library's cache
    local lib = AceLibrary("SkilletStitch-1.1")
    if lib and lib.ClearCraftabilityCache then
        lib:ClearCraftabilityCache()
    end

    CalcUpdateFrame.co = coroutine.create(function()
        return self:CalculateCraftability(profession, yieldInterval)
    end)

    CalcUpdateFrame:SetScript("OnUpdate", CalcUpdateFrame.OnUpdate)
    CalcUpdateFrame.running = true
    CalcUpdateFrame.profession = profession
    CalcUpdateFrame.finishFunc = finishCallback

    local status = coroutine.resume(CalcUpdateFrame.co)
    if not status then
        CalcUpdateFrame.running = false
        CalcUpdateFrame:SetScript("OnUpdate", nil)
        CalcUpdateFrame.co = nil
        return false
    end

    return true
end

function SkilletCraftCalc:IsCalculationRunning()
    return CalcUpdateFrame.running, CalcUpdateFrame.profession
end

function SkilletCraftCalc:StopCalculation()
    if CalcUpdateFrame.running then
        CalcUpdateFrame:SetScript("OnUpdate", nil)
        CalcUpdateFrame.running = false
        CalcUpdateFrame.co = nil
        CalcUpdateFrame.finishFunc = nil
        CalcUpdateFrame.profession = nil
    end
end
