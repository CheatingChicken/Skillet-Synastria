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

SKILLET_NOTES_ITEM_DISPLAYED = 7
SKILLET_NOTES_ITEM_HEIGHT    = SKILLET_TRADE_SKILL_HEIGHT * 3

---@type AceLocale
local L                      = AceLibrary("AceLocale-2.2"):new("Skillet")

---@type string
local NO_NOTE                = GRAY_FONT_COLOR_CODE .. L["click here to add a note"] .. FONT_COLOR_CODE_CLOSE

---@type Frame|nil
local editbox

---@type BackdropTable
local ControlBackdrop        = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 16,
	edgeSize = 16,
	insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

-- Called when the list of skills is scrolled
---@return nil
function Skillet:NotesList_OnScroll()
	Skillet:UpdateNotesWindow()
end

-- Shows the recipe notes editor for the current window
---@return nil
function Skillet:ShowRecipeNotes()
	local s = self.stitch:GetItemDataByIndex(self.currentTrade, self.selectedSkill);
	if not s then
		return
	end

	local frame = SkilletRecipeNotesFrame
	if frame then
		self.recipeNotesFrame = SkilletRecipeNotesFrame
	else
		return
	end

	if frame:IsVisible() then
		-- make it a toggle? why not
		frame:Hide()
		return
	end

	self:UpdateNotesWindow()
	frame:Show()
end

---@return Frame
local function get_edit_box()
	---@type Frame
	local editbox = CreateFrame("EditBox", nil, nil)
	editbox:SetTextInsets(5, 5, 3, 3)
	editbox:SetMaxLetters(256)
	editbox:SetAutoFocus(true)
	editbox:SetMultiLine(false)
	editbox:SetFontObject(ChatFontNormal)
	editbox:SetBackdrop(ControlBackdrop)
	editbox:SetBackdropColor(0, 0, 0, 1)

	editbox:SetScript("OnEnterPressed", function()
		this:Hide()
		---@type Button
		local b = this:GetParent()
		---@type string
		local l = b:GetAttribute("recipe_link") or ""
		---@type FontString
		local n = getglobal(b:GetName() .. "Notes") or CreateFrame("FontString")

		---@type table
		local skillet = this.obj

		skillet:SetItemNote(l, this:GetText())
		n:Show();
		skillet:UpdateNotesWindow()
	end);
	editbox:SetScript("OnEscapePressed", function()
		this:Hide()

		---@type Button
		local b = this:GetParent()
		---@type FontString
		local n = getglobal(b:GetName() .. "Notes") or CreateFrame("FontString")
		n:Show()
	end);

	return editbox
end

---@param button Button The notes button frame
---@return nil
function Skillet:RecipeNote_OnClick(button)
	-- update the window so we know that we are starting from a known good location
	self:UpdateNotesWindow()

	---@type string
	local link = button:GetAttribute("recipe_link") or ""

	---@type FontString|nil
	local notesObject = getglobal(button:GetName() .. "Notes")
	if not notesObject then return end

	---@type string
	local notes = notesObject:GetText() or ""

	if not editbox then
		editbox = get_edit_box()
	end

	editbox:SetParent(button)
	editbox:SetAllPoints(notesObject);
	editbox:SetFrameStrata("HIGH")

	if notes ~= NO_NOTE then
		editbox:SetText(notes);
		editbox:HighlightText()
	else
		editbox:SetText("");
	end

	editbox.obj = self;

	notesObject:Hide();
	editbox:Show()
	editbox:SetFocus()
end

-- Updates the notes window with the current data.
-- This should display the notes for the recipe item itself and for
-- any reagents that are needed
---@return nil
function Skillet:UpdateNotesWindow()
	local s = self.stitch:GetItemDataByIndex(self.currentTrade, self.selectedSkill);
	if not s then
		return
	end

	if editbox then
		editbox:Hide()
	end

	SkilletRecipeNotesFrameLabel:SetText(L["Notes"]);

	local reagents = s.reagents or {}
	local numItems = 1 + #reagents

	-- Update the scroll frame
	---@type Frame
	local scrollFrame = SkilletNotesList or CreateFrame("Frame")
	FauxScrollFrame_Update(scrollFrame,               -- frame
		numItems,                                     -- num items
		SKILLET_NOTES_ITEM_DISPLAYED,                 -- num to display
		SKILLET_NOTES_ITEM_HEIGHT)                    -- value step (item height)

	-- Where in the list of skill to start counting.
	---@type integer
	local offset = FauxScrollFrame_GetOffset(SkilletNotesList) or 0

	-- now do all that nasty work to fill in the contents of the frame

	for i = 1, SKILLET_NOTES_ITEM_DISPLAYED, 1 do
		local index = i + offset

		---@type Button|nil
		local button = getglobal("SkilletNotesButton" .. i)
		if button then
			if index <= numItems then
				---@type FontString|nil
				local text  = getglobal(button:GetName() .. "Text")
				---@type Texture|nil
				local icon  = getglobal(button:GetName() .. "Icon")
				---@type FontString|nil
				local notes = getglobal(button:GetName() .. "Notes")

				if text and icon and notes then
					-- set the width based on whether or not the scroll bar is displayed
					if (scrollFrame:IsShown()) then
						button:SetWidth(170)
					else
						button:SetWidth(190)
					end

					---@type string
					local link = ""

					if index == 1 then
						-- notes for the recipe itself
						text:SetText(s.name)
						icon:SetNormalTexture(s.texture)
						link = s.link
					else
						-- notes for a reagent
						local reagents = s.reagents or {}
						text:SetText(reagents[index - 1].name)
						icon:SetNormalTexture(reagents[index - 1].texture)
						link = reagents[index - 1].link
					end

					button:SetAttribute("recipe_link", link)
					---@type string|nil
					local notes_text = self:GetItemNote(link)

					if notes_text then
						notes:SetText(notes_text)
					else
						notes:SetText(NO_NOTE)
					end

					text:Show()
					icon:Show()
					notes:Show()
					button:Show()
				end
			else
				button:Hide()
			end
		end
	end
end

--
-- Hide the Skillet notes window, it it was open
--
---@return boolean|nil closed Whether the window was closed
function Skillet:HideNotesWindow()
	---@type boolean|nil
	local closed

	if self.recipeNotesFrame and self.recipeNotesFrame:IsVisible() then
		HideUIPanel(self.recipeNotesFrame);
		closed = true
	end

	return closed
end
