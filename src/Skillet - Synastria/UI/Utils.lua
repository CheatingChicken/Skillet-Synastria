--[[

Skillet: A tradeskill window replacement.
Copyright (c) 2007 Robert Clark <nogudnik@gmail.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

]] --

-- Handy utilities for Skillet UI methods.

---@type AceLocale
local L = AceLibrary("AceLocale-2.2"):new("Skillet")

---@type Frame|nil
local infoBox

---@type (fun(): nil)|nil
local createInfoBox

---@return nil
createInfoBox = function()
    infoBox = CreateFrame("Frame", "SkilletInfoBoxFrame", UIParent, "DialogBoxFrame")
    infoBox:SetWidth(500)
    infoBox:SetHeight(400)
    infoBox:SetPoint("CENTER")
    infoBox:SetBackdrop({
        bgFile = [[Interface\DialogFrame\UI-DialogBox-Background]],
        edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    infoBox:SetBackdropColor(0, 0, 0, 1)

    ---@type FontString
    local text = infoBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    infoBox.title = text
    text:SetPoint("TOP", 0, -5)

    ---@param text string The title text
    ---@return nil
    function infoBox:SetTitle(text)
        infoBox.title:SetText(text)
    end

    ---@type string[]
    infoBox.lefts = {}
    ---@type string[]
    infoBox.rights = {}
    ---@type FontString[]
    infoBox.textLefts = {}
    ---@type FontString[]
    infoBox.textRights = {}

    ---@return nil
    function infoBox:Clear()
        self.title:SetText("")
        for i = 1, #self.lefts do
            self.lefts[i] = nil
            self.rights[i] = nil
        end
    end

    ---@param left string Left column content
    ---@param right string Right column content
    ---@return nil
    function infoBox:AddLine(left, right)
        infoBox.lefts[#infoBox.lefts + 1] = left
        infoBox.rights[#infoBox.rights + 1] = right
    end

    ---@type fun(self: Frame)
    local infoBox_Show = infoBox.Show

    ---@return nil
    function infoBox:Show()
        ---@type number
        local maxLeftWidth = 0
        ---@type number
        local maxRightWidth = 0
        ---@type number
        local textHeight = 0

        -- Create all the font strings and find the longest text
        for i = 1, #self.lefts do
            if not self.textLefts[i] then
                ---@type FontString
                local left = infoBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                self.textLefts[i] = left
                ---@type FontString
                local right = infoBox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                self.textRights[i] = right

                -- Don't attach the first one until we know how big the rest of them are
                if i > 1 then
                    left:SetPoint("TOPRIGHT", self.textLefts[i - 1], "BOTTOMRIGHT", 0, -5)
                end
                right:SetPoint("LEFT", left, "RIGHT", 5, 0)
            end

            self.textLefts[i]:SetText(self.lefts[i] .. ":")
            self.textRights[i]:SetText(self.rights[i])
            ---@type number
            local leftWidth = self.textLefts[i]:GetWidth()
            ---@type number
            local rightWidth = self.textRights[i]:GetWidth()
            textHeight = self.textLefts[i]:GetHeight()
            if maxLeftWidth < leftWidth then
                maxLeftWidth = leftWidth
            end
            if maxRightWidth < rightWidth then
                maxRightWidth = rightWidth
            end
        end

        -- now attach buttons as needed
        self.textLefts[1]:SetPoint("TOPRIGHT", infoBox, "TOPLEFT", maxLeftWidth + 10, -35)

        for i = #self.lefts + 1, #self.textLefts do
            self.textLefts[i]:SetText('')
            self.textRights[i]:SetText('')
        end

        infoBox:SetWidth(maxLeftWidth + maxRightWidth + 30)
        infoBox:SetHeight(#self.lefts * (textHeight + 5) + 100)

        infoBox_Show(self)
    end

    infoBox:Hide()
    createInfoBox = nil
end

-- Adds resizing to a window. Resizing is both width and height from the lower right corner only
---@param frame Frame The frame to enable resizing for
---@param min_width number The minimum width of the frame
---@param min_height number The minimum height of the frame
---@param refresh_method fun(self: any): nil Callback function to refresh UI when resized
---@return nil
function Skillet:EnableResize(frame, min_width, min_height, refresh_method)
    -- lets play the resize me game!
    frame:SetMinResize(min_width, min_height) -- magic numbers
    local sizer_se = CreateFrame("Frame", frame:GetName() .. "_SizerSoutheast", frame)
    sizer_se:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    sizer_se:SetWidth(25)
    sizer_se:SetHeight(25)
    sizer_se:EnableMouse(true)
    sizer_se:SetScript("OnMouseDown", function(this)
        this:GetParent():StartSizing("BOTTOMRIGHT")
    end)
    sizer_se:SetScript("OnMouseUp", function(this)
        this:GetParent():StopMovingOrSizing()
        -- 'Skillet' is passed for the hidden 'self' variable
        pcall(refresh_method, Skillet)
    end)
    frame:SetScript("OnSizeChanged", function()
        -- 'Skillet' is passed for the hidden 'self' variable
        pcall(refresh_method, Skillet)
    end)

    -- Stole this from LibRockConfig (ya ckkinght!). Draws 3 diagonal lines in the
    -- lower right corner of the window
    local line1 = sizer_se:CreateTexture(sizer_se:GetName() .. "_Line1", "BACKGROUND")
    line1:SetWidth(14)
    line1:SetHeight(14)
    line1:SetPoint("BOTTOMRIGHT", -4, 4)
    line1:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    local x = 0.1 * 14 / 17
    line1:SetTexCoord(1 / 32 - x, 0.5, 1 / 32, 0.5 + x, 1 / 32, 0.5 - x, 1 / 32 + x, 0.5)

    local line2 = sizer_se:CreateTexture(sizer_se:GetName() .. "_Line2", "BACKGROUND")
    line2:SetWidth(11)
    line2:SetHeight(11)
    line2:SetPoint("BOTTOMRIGHT", -4, 4)
    line2:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    local x = 0.1 * 11 / 17
    line2:SetTexCoord(1 / 32 - x, 0.5, 1 / 32, 0.5 + x, 1 / 32, 0.5 - x, 1 / 32 + x, 0.5)

    local line3 = sizer_se:CreateTexture(sizer_se:GetName() .. "_Line3", "BACKGROUND")
    line3:SetWidth(8)
    line3:SetHeight(8)
    line3:SetPoint("BOTTOMRIGHT", -4, 4)
    line3:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    local x = 0.1 * 8 / 17
    line3:SetTexCoord(1 / 32 - x, 0.5, 1 / 32, 0.5 + x, 1 / 32, 0.5 - x, 1 / 32 + x, 0.5)
end

--
-- Shows a popup about the supported mods for inventory tracking
--
function Skillet:ShowInventoryInfoPopup()
    if createInfoBox then
        createInfoBox()
    end

    if infoBox then
        infoBox:Clear()
        infoBox:SetTitle(L["INVENTORYDESC"])

        if self.inventoryCheck then
            ---@type string
            local version = self.inventoryCheck:GetVersion()
            infoBox:AddLine(L["Library"], version)

            ---@type string[]
            local list = self.inventoryCheck:GetSupportedAddons()
            ---@type string
            local text = list[1]
            for i = 2, #list, 1 do
                text = text .. ", " .. list[i]
            end
            infoBox:AddLine(L["Supported Addons"], text)

            ---@type string
            local selectedAddon = self.inventoryCheck:GetSelectedAddon()
            infoBox:AddLine(L["Selected Addon"], selectedAddon)
        else
            infoBox:AddLine(L["Supported Addons"], "<none>")
        end

        infoBox:Show()
    end
end
