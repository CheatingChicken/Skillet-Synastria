--[[
SkilletCraftCalc.lua - SYNCHRONOUS Craftability Calculator
Handles INSTANTANEOUS calculation of craftable counts with Custom API optimization

Now runs synchronously since optimization reduced calculation time to ~10ms,
eliminating the need for coroutines and background processing.
]] --

if not Skillet then
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Skillet] Error: Skillet not loaded when CraftCalc initialized!|r")
    return
end

local SkilletCraftCalc = {}
Skillet.CraftCalc = SkilletCraftCalc

-- Localize globals for performance
local pairs = pairs
local ipairs = ipairs
local math = math
local type = type


---@class CalcUpdateFrame : Frame
---@field running boolean
---@field paused boolean
---@field profession string|nil
---@field OnUpdate fun(self: CalcUpdateFrame, elapsed: number)
local CalcUpdateFrame = CreateFrame("Frame")
---@type CalcUpdateFrame
CalcUpdateFrame = CalcUpdateFrame
CalcUpdateFrame.running = false
CalcUpdateFrame.paused = false
CalcUpdateFrame.profession = nil

-- Performance timing statistics (for benchmarking)
local TimingStats = {
    apiTime = 0,      -- Total time spent in Custom API calls (full calculation path)
    apiCallCount = 0, -- Number of times Custom API path was used
}

function SkilletCraftCalc:ResetTimingStats()
    TimingStats.apiTime = 0
    TimingStats.apiCallCount = 0
end

function SkilletCraftCalc:GetTimingStats()
    return 0, TimingStats.apiTime, TimingStats.apiCallCount -- Return 0 for checkTime (deprecated)
end

-- Cached results
---@type table<string, number>
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

-- Background calculation (now SYNCHRONOUS - no coroutine needed with 10ms runtime!)
function SkilletCraftCalc:CalculateCraftability(profession, yieldInterval)
    -- yieldInterval is now ignored since we run synchronously
    local lastProgressReport = 0

    Skillet:DebugLog("[Calc] Starting SYNCHRONOUS calculation for " .. (profession or "nil"), "|cFF00FFFF")

    ---@type SkilletStitch
    local lib = AceLibrary("SkilletStitch-1.1")
    if not lib or not lib.data or not lib.data[profession] then
        Skillet:DebugLog("[Calc] ERROR: No data for profession " .. (profession or "nil"), "|cFFFF0000")
        return
    end

    ---@type table<integer, RecipeData|string>
    local recipes = lib.data[profession]
    local count = 0
    local totalRecipes = 0

    -- Count total recipes first
    for index, recipeData in pairs(recipes) do
        if type(recipeData) == "table" then
            totalRecipes = totalRecipes + 1
        end
    end

    Skillet:DebugLog("[Calc] Found " .. totalRecipes .. " recipes to process", "|cFF00FFFF")

    -- Iterate through all recipes in the profession
    for index, recipeData in pairs(recipes) do
        if type(recipeData) == "table" then
            -- Use GetItemDataByIndex to get the cached recipe object
            -- This ensures we're using the SAME object the UI will use
            ---@type Recipe|nil
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
                        -- Performance is acceptable with synchronous calculation (10ms total!)
                        local numBagsResbank = self:CalculateRecipeCraftability(recipe, lib, false, false, 0, true)
                        local numBankResbank = self:CalculateRecipeCraftability(recipe, lib, true, false, 0, true)
                    end
                end

                count = count + 1

                -- Report progress every 25% (no yielding needed)
                local progressPercent = math.floor((count / totalRecipes) * 100)
                if progressPercent >= lastProgressReport + 25 then
                    lastProgressReport = progressPercent
                    Skillet:DebugLog(
                        "[Calc] Progress: " .. progressPercent .. "% (" .. count .. "/" .. totalRecipes .. ")",
                        "|cFF00FFFF")
                end
            end
        end
    end

    Skillet:DebugLog("[Calc] SYNCHRONOUS calculation complete! Processed " .. count .. " recipes", "|cFF00FF00")
    return count
end

-- Calculate craftability using ONLY Custom API functions (Synastria)
-- This completely bypasses traditional calculation and uses server-side data
---@param spellId number The recipe spell ID
---@param includeBank boolean Whether to include bank items (passed to API)
---@param verbose boolean Whether to print debug messages
---@param depth number Recursion depth for indentation
---@param cache table<string, number> Cache mapping spellId -> craftable count
---@return number|nil craftable How many times recipe can be crafted, or nil if API unavailable
function SkilletCraftCalc:CalculateRecipeCraftabilityCustomAPI(spellId, includeBank, verbose, depth, cache)
    if not spellId or not Custom_GetProfessionRecipeInfo then
        return nil -- API not available
    end

    depth = depth or 0
    ---@type table<string, number>
    cache = cache or {}
    local indent = string.rep("  ", depth)

    -- Maximum recursion depth safety check
    if depth > 50 then
        if verbose then
            DEFAULT_CHAT_FRAME:AddMessage(indent ..
                "|cFFFF0000[API] Max recursion depth reached for spell " .. spellId .. "|r")
        end
        return 0
    end

    -- Check cache first
    local cacheKey = spellId .. (includeBank and "_bank" or "")
    if cache[cacheKey] ~= nil then
        -- Special value -1 means "currently being calculated" (circular dependency detected)
        if cache[cacheKey] == -1 then
            if verbose then
                DEFAULT_CHAT_FRAME:AddMessage(indent ..
                    "|cFFFF8800[API] Circular dependency detected for spell " .. spellId .. "|r")
            end
            return 0
        end
        return cache[cacheKey]
    end

    -- Mark this recipe as "in progress" to detect circular dependencies
    cache[cacheKey] = -1

    -- Query Custom API for immediate craftability
    local skillId, name, itemId, craftCount, canCraft = Custom_GetProfessionRecipeInfo(spellId)

    if not canCraft then
        -- Recipe not found in API
        if verbose then
            DEFAULT_CHAT_FRAME:AddMessage(indent .. "|cFFFF0000[API] Spell " .. spellId .. " not found|r")
        end
        cache[cacheKey] = 0
        return 0
    end

    -- Calculate total items (API returns crafts, multiply by items-per-craft)
    local totalCraftable = canCraft * (craftCount or 1)

    if verbose then
        DEFAULT_CHAT_FRAME:AddMessage(
            indent .. "|cFF00FFFF[API] " .. (name or ("Recipe " .. spellId)) ..
            ": " .. canCraft .. " crafts * " .. (craftCount or 1) .. " = " .. totalCraftable .. "|r"
        )
    end

    -- If we can craft directly, return immediately
    if totalCraftable > 0 then
        cache[cacheKey] = totalCraftable
        return totalCraftable
    end

    -- We can't craft with current materials - need to check sub-recipes AND inventory
    -- Get the recipe object to access reagent inventory counts
    local recipeObj = Skillet.stitch:GetItemDataBySpellId(spellId)
    if not recipeObj or not recipeObj.reagents or #recipeObj.reagents == 0 then
        -- Can't find recipe or no reagents
        cache[cacheKey] = 0
        return 0
    end

    if verbose then
        DEFAULT_CHAT_FRAME:AddMessage(indent ..
            "|cFFFFAA00[API] Can't craft directly, checking inventory + sub-recipes...|r")
    end

    -- Track the limiting reagent - start with "infinite" and reduce to minimum
    local maxCraftable = math.huge

    -- Check each reagent: either have it in inventory OR can craft it
    for _, reagent in ipairs(recipeObj.reagents) do
        if reagent.vendor then
            -- Vendor items assumed unlimited, skip
            if verbose then
                DEFAULT_CHAT_FRAME:AddMessage(
                    indent .. "  |cFF88FF88" .. reagent.name ..
                    " (vendor item, unlimited)|r"
                )
            end
        else
            -- Check how many we have in inventory
            local available = includeBank and reagent.numwbank or reagent.num
            local needed = reagent.needed

            if available >= needed then
                -- We have enough of this reagent in inventory
                local timesFromInventory = math.floor(available / needed)
                maxCraftable = math.min(maxCraftable, timesFromInventory)

                if verbose then
                    DEFAULT_CHAT_FRAME:AddMessage(
                        indent .. "  |cFF88FF88" .. reagent.name .. ": have " ..
                        available .. ", need " .. needed .. " → " .. timesFromInventory .. " crafts|r"
                    )
                end
            else
                -- Don't have enough - check if it's craftable
                -- Get itemId from reagent link
                local reagentItemId = tonumber(reagent.link:match("|Hitem:(%d+)"))
                local reagentSpellId = reagentItemId and Custom_GetProfessionRecipeFromCraftedItem(reagentItemId)

                if reagentSpellId then
                    -- Craftable! Recurse to calculate how many we can make
                    if verbose then
                        DEFAULT_CHAT_FRAME:AddMessage(
                            indent .. "  |cFFFFAA00" .. reagent.name .. ": have " ..
                            available .. ", need " .. needed .. " → trying to craft (spell " .. reagentSpellId .. ")|r"
                        )
                    end

                    local craftableReagents = self:CalculateRecipeCraftabilityCustomAPI(
                        reagentSpellId, includeBank, verbose, depth + 1, cache
                    )

                    if craftableReagents and craftableReagents > 0 then
                        -- Include what we already have + what we can craft
                        local totalReagents = available + craftableReagents
                        local timesFromCrafting = math.floor(totalReagents / needed)
                        maxCraftable = math.min(maxCraftable, timesFromCrafting)

                        if verbose then
                            DEFAULT_CHAT_FRAME:AddMessage(
                                indent .. "    |cFF00FF00Can craft " .. craftableReagents ..
                                " + have " .. available .. " = " .. totalReagents ..
                                " → " .. timesFromCrafting .. " crafts|r"
                            )
                        end
                    else
                        -- Can't craft this reagent and don't have enough - recipe is blocked
                        maxCraftable = 0
                        if verbose then
                            DEFAULT_CHAT_FRAME:AddMessage(
                                indent .. "    |cFFFF0000Can't craft " .. reagent.name .. " - blocked!|r"
                            )
                        end
                        break
                    end
                else
                    -- Not craftable and don't have enough - recipe is blocked
                    maxCraftable = 0
                    if verbose then
                        DEFAULT_CHAT_FRAME:AddMessage(
                            indent .. "  |cFFFF0000" .. reagent.name .. ": have " ..
                            available .. ", need " .. needed .. " (not craftable) - blocked!|r"
                        )
                    end
                    break
                end
            end
        end
    end

    local finalCount = maxCraftable == math.huge and 0 or maxCraftable

    -- Multiply by nummade to get total items (Custom API gives us crafts, not items)
    if finalCount > 0 and recipeObj.nummade and recipeObj.nummade > 1 then
        finalCount = finalCount * recipeObj.nummade
        if verbose then
            DEFAULT_CHAT_FRAME:AddMessage(
                indent .. "|cFF00FF00[API] " .. (name or ("Recipe " .. spellId)) ..
                ": " .. math.floor(finalCount / recipeObj.nummade) .. " crafts * " ..
                recipeObj.nummade .. " = " .. finalCount .. "|r"
            )
        end
    end

    cache[cacheKey] = finalCount
    return finalCount
end

-- Calculate a single recipe's craftability with sub-reagent checking
---@param recipe Recipe The recipe to calculate
---@param lib SkilletStitch The Stitch library instance
---@param includeBank boolean Whether to include bank items
---@param verbose boolean Whether to print debug messages
---@param depth number|nil Current recursion depth
---@param forceRecalc boolean|nil Force recalculation bypassing cache
---@param skipCustomAPI boolean|nil Skip Custom API optimization (for benchmarking)
---@return number craftable How many times the recipe can be crafted
function SkilletCraftCalc:CalculateRecipeCraftability(recipe, lib, includeBank, verbose, depth, forceRecalc,
                                                      skipCustomAPI)
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

    -- Synastria: Try pure Custom API calculation path with sub-recipe support
    -- Uses server-side data + cached recipe lookups for speed
    if not skipCustomAPI and depth == 0 and recipe.spellId and Custom_GetProfessionRecipeInfo then
        local apiStartTime = debugprofilestop()

        -- Use dedicated Custom API calculation with full sub-recipe support
        local apiCache = {} -- Fresh cache for this calculation
        local customAPIResult = self:CalculateRecipeCraftabilityCustomAPI(
            recipe.spellId, includeBank, verbose, 0, apiCache
        )

        local apiElapsed = debugprofilestop() - apiStartTime

        if customAPIResult ~= nil then
            -- Custom API successfully calculated craftability
            TimingStats.apiTime = TimingStats.apiTime + apiElapsed
            TimingStats.apiCallCount = TimingStats.apiCallCount + 1

            -- Cache result
            local cacheKey = includeBank and "numcraftablewbank" or "numcraftable"
            lib:SetCachedCraftability(recipe, cacheKey, customAPIResult)

            if verbose then
                DEFAULT_CHAT_FRAME:AddMessage(
                    "|cFF00FFFF[CUSTOM API PATH] " .. recipe.name ..
                    ": " .. customAPIResult .. " (took " .. string.format("%.3f", apiElapsed) .. "ms)|r"
                )
            end

            return customAPIResult
        else
            -- Custom API unavailable or failed, fall back to traditional
            if verbose then
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[CUSTOM API UNAVAILABLE] " ..
                    recipe.name .. " - using traditional calculation|r")
            end
            -- Fall through to traditional calculation
        end
    end

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
    ---@type CacheStats|nil
    local stats = lib:GetCacheStats()
    if stats then
        stats.misses = stats.misses + 1
        stats.calculations = stats.calculations + 1
    end

    local num = -1 -- Use -1 as initial value to differentiate "not set" from "limited to 0"

    -- Synastria: Use modern reagents table format
    local reagents = recipe.reagents or {}

    if verbose then
        Skillet:DebugLog(indent .. "[CALC] Processing " .. recipe.name .. " (" .. #reagents .. " reagents)")
    end

    for _, reagent in ipairs(reagents) do
        -- Synastria: Vendor-buyable reagents are treated as always available (infinite)
        if reagent.vendor == true then
            if verbose then
                Skillet:DebugLog(indent .. "  [VENDOR] " .. reagent.name .. " - skipped (vendor item)")
            end
            -- Skip vendor items, they don't limit craftability
        else
            -- Non-vendor reagent - check availability and craftability
            local available = includeBank and reagent.numwbank or reagent.num

            if verbose then
                Skillet:DebugLog(indent .. "  [REAGENT] " .. reagent.name .. ": " .. available .. "/" .. reagent.needed)
            end

            -- Check if this reagent is craftable
            if available < reagent.needed then
                local reagentRecipe = lib:GetItemDataByName(reagent.name)
                if reagentRecipe then
                    if verbose then
                        Skillet:DebugLog(indent .. "    -> Craftable recipe found, recursing...")
                    end
                    -- Recursively calculate sub-reagent craftability
                    -- Pass forceRecalc and skipCustomAPI to sub-recipes
                    local subCraftable = self:CalculateRecipeCraftability(reagentRecipe, lib, includeBank, verbose,
                        depth + 1, forceRecalc, skipCustomAPI)
                    if subCraftable > 0 then
                        local addedAmount = subCraftable * (reagentRecipe.nummade or 1)
                        available = available + addedAmount
                        if verbose then
                            Skillet:DebugLog(indent ..
                                "    -> Can craft " ..
                                subCraftable .. ", adding " .. addedAmount .. " (total: " .. available .. ")")
                        end
                    else
                        if verbose then
                            Skillet:DebugLog(indent .. "    -> Cannot craft (0)")
                        end
                    end
                end
            end

            local max = math.floor(available / reagent.needed) * recipe.nummade

            if verbose then
                Skillet:DebugLog(indent .. "    -> Max from this reagent: " .. max .. " (num was: " .. num .. ")")
            end

            if num == -1 or max < num then
                num = max
                if verbose then
                    Skillet:DebugLog(indent .. "    -> Updated num to: " .. num)
                end

                -- Early exit: if num is 0, no need to check remaining reagents
                if num == 0 then
                    if verbose then
                        Skillet:DebugLog(indent .. "    -> Early exit: craftability is 0")
                    end
                    break
                end
            end
        end
    end

    -- If num is still -1, no reagents were processed (shouldn't happen, but safe default)
    if num == -1 then
        num = 0
    end

    if verbose then
        Skillet:DebugLog(indent .. "[CALC] " .. recipe.name .. " final result: " .. num)
    end

    -- Cache the result before returning
    -- Always cache, even when forcing recalc (we just bypassed reading, but still want to store)
    lib:SetCachedCraftability(recipe, cacheKey, num)

    return num
end

-- Legacy OnUpdate handler (no longer used with synchronous calculation)
-- Kept for compatibility but should never be called
function CalcUpdateFrame:OnUpdate(elapsed)
    -- This should not be called with synchronous calculation
    Skillet:DebugLog("[Calc] WARNING: OnUpdate called but using synchronous calculation!", "|cFFFFAA00")
    self:SetScript("OnUpdate", nil)
    self.running = false
end

-- Start calculation (now SYNCHRONOUS - completes immediately!)
function SkilletCraftCalc:StartBackgroundCalculation(profession, finishCallback, yieldInterval)
    Skillet:DebugLog("[Calc] StartSYNCHRONOUSCalculation called for " .. (profession or "nil"), "|cFF00FFFF")

    if CalcUpdateFrame.running then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[Skillet] Craftability calculation already in progress|r")
        return false
    end

    -- Mark as running to prevent overlapping calls
    CalcUpdateFrame.running = true
    CalcUpdateFrame.profession = profession

    -- Clear both caches for this profession
    self:ClearCache()

    -- Also clear the Stitch library's cache
    ---@type SkilletStitch|nil
    local lib = AceLibrary("SkilletStitch-1.1")
    if lib and lib.ClearCraftabilityCache then
        lib:ClearCraftabilityCache()
    end

    -- Run calculation synchronously (no coroutine needed - only 10ms!)
    local startTime = debugprofilestop()
    local count = self:CalculateCraftability(profession, yieldInterval)
    local elapsed = debugprofilestop() - startTime

    -- Mark as no longer running
    CalcUpdateFrame.running = false
    CalcUpdateFrame.profession = nil

    if count then
        Skillet:DebugLog("[Calc] SYNCHRONOUS calculation completed in " .. string.format("%.2f", elapsed) .. "ms",
            "|cFF00FF00")

        -- Call finish callback if provided
        if finishCallback then
            Skillet:DebugLog("[Calc] Executing finish callback", "|cFF00FF00")
            finishCallback(count)
        end

        return true
    else
        Skillet:DebugLog("[Calc] ERROR: Synchronous calculation failed", "|cFFFF0000")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Skillet] Error in craftability calculation|r")
        return false
    end
end

function SkilletCraftCalc:IsCalculationRunning()
    return CalcUpdateFrame.running, CalcUpdateFrame.profession
end

function SkilletCraftCalc:StopCalculation()
    -- With synchronous calculation, there's nothing to stop (completes immediately)
    -- Just reset state in case this is called
    CalcUpdateFrame.running = false
    CalcUpdateFrame.paused = false
    CalcUpdateFrame.profession = nil
end

function SkilletCraftCalc:PauseCalculation()
    -- Synchronous calculation can't be paused (completes in 10ms)
    -- Function kept for compatibility
end

function SkilletCraftCalc:ResumeCalculation()
    -- Synchronous calculation can't be paused/resumed
    -- Function kept for compatibility
    CalcUpdateFrame.paused = false
end

---
--- Benchmark craftability calculation performance
--- Compares old method (without Custom API) vs new method (with Custom API)
--- @param recipe table Recipe to benchmark
--- @param lib table SkilletData library
--- @param includeBank boolean Include bank materials
---
function SkilletCraftCalc:BenchmarkCraftability(recipe, lib, includeBank)
    if not recipe or not recipe.name then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Benchmark] Invalid recipe|r")
        return
    end

    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF========================================|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Benchmark] Testing: " .. recipe.name .. "|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF========================================|r")

    local includeBank = includeBank or false
    local verbose = false -- Disable verbose for cleaner benchmark

    -- Method 1: OLD (Traditional calculation, no Custom API)
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[1/2] Testing OLD method (without Custom API)...|r")
    lib:ClearCraftabilityCache() -- Clear all caches
    local startTime = debugprofilestop()
    local result1 = self:CalculateRecipeCraftability(recipe, lib, includeBank, verbose, 0, true, true)
    local elapsed1 = debugprofilestop() - startTime
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00  Result: " .. result1 .. " craftable|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00  Time: " .. string.format("%.3f", elapsed1) .. " ms|r")

    -- Method 2: NEW (With Custom API optimization)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[2/2] Testing NEW method (with Custom API)...|r")
    lib:ClearCraftabilityCache() -- Clear all caches again
    local startTime2 = debugprofilestop()
    local result2 = self:CalculateRecipeCraftability(recipe, lib, includeBank, verbose, 0, true, false)
    local elapsed2 = debugprofilestop() - startTime2
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00  Result: " .. result2 .. " craftable|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00  Time: " .. string.format("%.3f", elapsed2) .. " ms|r")

    -- Calculate speedup
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF========================================|r")
    if elapsed1 > 0 and elapsed2 > 0 then
        local speedup = elapsed1 / elapsed2
        local improvement = ((elapsed1 - elapsed2) / elapsed1) * 100
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[RESULTS] Speedup: " .. string.format("%.2fx", speedup) .. "|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[RESULTS] Improvement: " .. string.format("%.1f%%", improvement) .. "|r")
        if elapsed2 < elapsed1 then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[RESULTS] NEW method is FASTER! ⚡|r")
        elseif elapsed2 > elapsed1 then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[RESULTS] OLD method is faster (unexpected)|r")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFF[RESULTS] Same performance|r")
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[RESULTS] Times too small to measure accurately|r")
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF========================================|r")

    -- Clear cache one final time to not pollute normal usage
    lib:ClearCraftabilityCache()
end

-- Slash command to benchmark the currently selected recipe
SLASH_SKILLETBENCH1 = "/skilletbench"
SLASH_SKILLETBENCH2 = "/sbench"
SlashCmdList["SKILLETBENCH"] = function(msg)
    if not Skillet then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Benchmark] Skillet not loaded|r")
        return
    end
    if not Skillet.stitch then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Benchmark] Skillet.stitch not initialized|r")
        return
    end

    local recipe = Skillet.currentRecipe
    if not recipe then
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cFFFF0000[Benchmark] No recipe selected. Please select a recipe in the Skillet window first.|r")
        return
    end

    -- Run the benchmark
    SkilletCraftCalc:BenchmarkCraftability(recipe, Skillet.stitch, false)
end

---
--- Benchmark all recipes in the currently open profession
--- Provides aggregate statistics comparing old vs new methods
--- @param includeBank boolean Include bank materials
---
function SkilletCraftCalc:BenchmarkAllRecipes(includeBank)
    if not Skillet or not Skillet.stitch or not Skillet.currentTrade then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Benchmark] No profession window open|r")
        return
    end

    ---@type string
    local profession = Skillet.currentTrade
    local numRecipes = GetNumTradeSkills()

    if not numRecipes or numRecipes == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Benchmark] No recipes found in " .. profession .. "|r")
        return
    end

    includeBank = includeBank or false
    local verbose = false

    -- Check Custom API availability
    local customAPIAvailable = Custom_GetProfessionRecipeInfo ~= nil

    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF========================================|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Benchmark] Testing ALL recipes in: " .. profession .. "|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Benchmark] Total recipes: " .. numRecipes .. "|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Benchmark] Custom API: " ..
        (customAPIAvailable and "AVAILABLE" or "NOT AVAILABLE") .. "|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF========================================|r")

    -- Build list of actual recipes (skip headers)
    ---@type Recipe[]
    local recipes = {}
    local recipesSkipped = 0
    for i = 1, numRecipes do
        local recipe = Skillet.stitch:GetItemDataByIndex(profession, i)
        if recipe and recipe.name and not recipe.header then
            table.insert(recipes, recipe)
        else
            recipesSkipped = recipesSkipped + 1
        end
    end

    local recipesProcessed = #recipes
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFF  Valid recipes: " ..
        recipesProcessed .. ", Headers/Skipped: " .. recipesSkipped .. "|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF========================================|r")

    -- PASS 1: Test ALL recipes with OLD method (no Custom API)
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[PASS 1/2] Testing OLD method (all recipes)...|r")
    local totalTimeOld = 0
    ---@type number[]
    local resultsOld = {} -- Store results for comparison
    for idx, recipe in ipairs(recipes) do
        ---@type Recipe
        local r = recipe
        Skillet.stitch:ClearCraftabilityCache()
        local startTime = debugprofilestop()
        local result = self:CalculateRecipeCraftability(r, Skillet.stitch, includeBank, verbose, 0, true, true)
        totalTimeOld = totalTimeOld + (debugprofilestop() - startTime)
        resultsOld[idx] = result -- Store result

        if idx % 50 == 0 then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00  Progress: " .. idx .. "/" .. recipesProcessed .. "|r")
        end
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00  OLD method complete: " .. string.format("%.2f", totalTimeOld) .. " ms|r")

    -- PASS 2: Test ALL recipes with NEW method (with Custom API)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[PASS 2/2] Testing NEW method (all recipes)...|r")

    -- Reset timing statistics before PASS 2
    self:ResetTimingStats()

    local totalTimeNew = 0
    local recipesWithCustomAPI = 0
    local recipesWithSpellId = 0
    ---@type number[]
    local resultsNew = {} -- Store results for comparison
    local mismatchCount = 0
    ---@type {recipe: Recipe, name: string, old: number, new: number}[]
    local mismatchExamples = {}
    for idx, recipe in ipairs(recipes) do
        Skillet.stitch:ClearCraftabilityCache()

        -- Track spellId availability
        if recipe.spellId then
            recipesWithSpellId = recipesWithSpellId + 1
        end

        local startTime = debugprofilestop()
        local result = self:CalculateRecipeCraftability(recipe, Skillet.stitch, includeBank, verbose, 0, true, false)
        local elapsed = debugprofilestop() - startTime
        totalTimeNew = totalTimeNew + elapsed
        resultsNew[idx] = result -- Store result

        -- Compare results
        if resultsOld[idx] ~= resultsNew[idx] then
            mismatchCount = mismatchCount + 1
            if #mismatchExamples < 5 then -- Store first 5 mismatches
                table.insert(mismatchExamples, {
                    recipe = recipe,      -- Store recipe reference for verbose re-run
                    name = recipe.name,
                    old = resultsOld[idx],
                    new = resultsNew[idx]
                })
            end
        end

        -- Detect Custom API usage (much faster than traditional calculation)
        -- Traditional calc averages 2-3ms, Custom API should be <1ms
        if recipe.spellId and customAPIAvailable and elapsed < 1.0 then
            recipesWithCustomAPI = recipesWithCustomAPI + 1
        end

        if idx % 50 == 0 then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00  Progress: " .. idx .. "/" .. recipesProcessed .. "|r")
        end
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00  NEW method complete: " .. string.format("%.2f", totalTimeNew) .. " ms|r")

    -- Get timing statistics from PASS 2
    local checkTime, apiTime, apiCallCount = self:GetTimingStats()

    -- Display aggregate results
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF========================================|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[DIAGNOSTIC INFO]|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFF  Recipes Processed: " .. recipesProcessed .. "|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFF  Recipes with spellId: " .. recipesWithSpellId .. "|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFF  Recipes using Custom API: " .. recipesWithCustomAPI .. "|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFF  Custom API Usage: " ..
        string.format("%.1f%%", (recipesWithCustomAPI / math.max(recipesProcessed, 1)) * 100) .. "|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[TIMING BREAKDOWN (NEW method)]|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFF  Total Custom API time: " ..
        string.format("%.2f", apiTime) ..
        " ms (" .. string.format("%.1f%%", (apiTime / totalTimeNew) * 100) .. " of NEW)|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFF  Custom API calls: " .. apiCallCount .. "|r")
    if apiCallCount > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFF  Avg API call time: " ..
            string.format("%.3f", apiTime / apiCallCount) .. " ms|r")
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFF  Traditional calculation time: " ..
        string.format("%.2f", totalTimeNew - apiTime) ..
        " ms (" .. string.format("%.1f%%", ((totalTimeNew - apiTime) / totalTimeNew) * 100) .. " of NEW)|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF----------------------------------------|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00  OLD Method Total Time: " .. string.format("%.2f", totalTimeOld) .. " ms|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00  NEW Method Total Time: " .. string.format("%.2f", totalTimeNew) .. " ms|r")

    if recipesProcessed > 0 then
        ---@type number
        local avgOld = totalTimeOld / recipesProcessed
        ---@type number
        local avgNew = totalTimeNew / recipesProcessed
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00  OLD Method Avg/Recipe: " .. string.format("%.3f", avgOld) .. " ms|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00  NEW Method Avg/Recipe: " .. string.format("%.3f", avgNew) .. " ms|r")
    end

    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF========================================|r")

    -- Result accuracy comparison
    if mismatchCount == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[ACCURACY] Perfect Match! All " ..
            recipesProcessed .. " results identical ✓|r")
    else
        local matchPercent = ((recipesProcessed - mismatchCount) / recipesProcessed) * 100
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8800[ACCURACY] " ..
            mismatchCount .. " mismatches found (" .. string.format("%.1f%%", matchPercent) .. " match)|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8800[EXAMPLES] First " .. math.min(5, #mismatchExamples) .. " mismatches:|r")
        for _, mismatch in ipairs(mismatchExamples) do
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8800  " ..
                mismatch.name .. ": OLD=" .. mismatch.old .. " vs NEW=" .. mismatch.new .. "|r")
        end

        -- PASS 3: Re-run mismatched recipes with verbose output for debugging
        if #mismatchExamples > 0 then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF========================================|r")
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FF[DEBUG] Detailed calculation trees for mismatches:|r")
            DEFAULT_CHAT_FRAME:AddMessage(
                "|cFFFFFF00  NOTE: Enable dev mode (/skillet dev) to see full calculation details|r")
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF========================================|r")

            for i, mismatch in ipairs(mismatchExamples) do
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFF |r")
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[MISMATCH " ..
                    i .. "/" .. #mismatchExamples .. "] " .. mismatch.name .. "|r")
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00  Expected (OLD): " ..
                    mismatch.old .. " | Got (NEW): " .. mismatch.new .. "|r")
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8800----------------------------------------|r")

                -- Run OLD method with verbose
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[OLD METHOD - Traditional Calculation]|r")
                Skillet.stitch:ClearCraftabilityCache()
                local resultOld = self:CalculateRecipeCraftability(mismatch.recipe, Skillet.stitch, includeBank, true, 0,
                    true, true)
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00  → Result: " .. resultOld .. "|r")

                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8800----------------------------------------|r")

                -- Run NEW method with verbose
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[NEW METHOD - With Custom API]|r")
                Skillet.stitch:ClearCraftabilityCache()
                local resultNew = self:CalculateRecipeCraftability(mismatch.recipe, Skillet.stitch, includeBank, true, 0,
                    true, false)
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00  → Result: " .. resultNew .. "|r")

                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF========================================|r")
            end
        end
    end

    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF========================================|r")

    if totalTimeOld > 0 and totalTimeNew > 0 then
        ---@type number
        local speedup = totalTimeOld / totalTimeNew
        ---@type number
        local improvement = ((totalTimeOld - totalTimeNew) / totalTimeOld) * 100
        ---@type number
        local timeSaved = totalTimeOld - totalTimeNew

        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[OVERALL PERFORMANCE]|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00  Speedup: " .. string.format("%.2fx", speedup) .. "|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00  Improvement: " .. string.format("%.1f%%", improvement) .. "|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00  Time Saved: " .. string.format("%.2f", timeSaved) .. " ms|r")

        if totalTimeNew < totalTimeOld then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00  NEW method is FASTER! ⚡|r")
        elseif totalTimeNew > totalTimeOld then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000  OLD method is faster (unexpected)|r")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFF  Same performance|r")
        end

        -- Warnings
        if mismatchCount > 0 then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000  ⚠ CRITICAL: Results don't match! Custom API may be incorrect!|r")
        end
        if not customAPIAvailable then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000  ⚠ WARNING: Custom API not available!|r")
        elseif recipesWithCustomAPI == 0 and recipesWithSpellId > 0 then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000  ⚠ WARNING: Custom API available but not being used!|r")
        elseif recipesWithSpellId == 0 then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000  ⚠ WARNING: No recipes have spellId!|r")
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000  Unable to calculate performance metrics|r")
    end

    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF========================================|r")

    -- Clear cache for normal usage
    Skillet.stitch:ClearCraftabilityCache()
end

-- Slash command to benchmark all recipes in open profession
SLASH_SKILLETBENCHALL1 = "/skilletbenchall"
SLASH_SKILLETBENCHALL2 = "/sbenchall"
SlashCmdList["SKILLETBENCHALL"] = function(msg)
    if not Skillet then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Benchmark] Skillet not loaded|r")
        return
    end
    if not Skillet.stitch then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Benchmark] Skillet.stitch not initialized|r")
        return
    end
    if not Skillet.currentTrade then
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cFFFF0000[Benchmark] No profession window open. Please open a profession first.|r")
        return
    end

    -- Run the benchmark for all recipes
    SkilletCraftCalc:BenchmarkAllRecipes(false)
end
