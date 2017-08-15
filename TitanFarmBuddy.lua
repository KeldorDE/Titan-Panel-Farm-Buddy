-- **************************************************************************
-- * TitanFarmBuddy.lua
-- *
-- * By: Keldor
-- **************************************************************************

local L = LibStub('AceLocale-3.0'):GetLocale('Titan', true)
local TitanFarmBuddy = LibStub('AceAddon-3.0'):NewAddon('TitanFarmBuddy')
local TITAN_FARM_BUDDY_ID = 'FarmBuddy'
local ADDON_NAME = 'Titan Farm Buddy'
local ADDON_VERSION = GetAddOnMetadata('TitanItemCount', 'Version')
local ADDON_AUTHOR = GetAddOnMetadata('TitanItemCount', 'Author')

local defaults = {
	char = {
		Item = '',
		Goal = 0
	}
};
local options = {
	name = ADDON_NAME,
	handler = TitanItemCount,
	type = 'group',
	args = {
		info_version = {
			type		= 'description',
			name		= L['Version'] .. ': ' .. ADDON_VERSION,
			order		= 0,
		},
		info_author = {
			type		= 'description',
			name		= L['Author'] . ': ' .. ADDON_AUTHOR,
			order		= 10,
		},
		header_general = {
			type		= 'header',
			name		= L['General Options'],
			order		= 20,
		},
		item_count = {
			type     = 'input',
			name     = L['Item to Count'],
			desc     = L['The name of the item to track'],
			get      = function() return TitanFarmBuddy.db.char.Item end,
			set      = 'SetItem',
		  usage    = L['Enter the name of an item or CTRL + Click an item from your inventory'],
			width    = full,
			order    = 30,
		},
		space_1 = {
		   type     = 'description',
		   name     = '',
		   order    = 40,
		},
		goal = {
		   type     = 'input',
		   name     = L['Goal Quantity'],
		   desc     = L['The goal quantity for the tracked item'],
		   get      = function() return tostring(TitanFarmBuddy.db.char.Goal) end,
		   set      = 'SetGoal',
		   usage    = L['0 to disable goal or an number for your goal'],
		   width    = full,
		   order    = 70,
		}
	}
}


-- **************************************************************************
-- NAME : TitanPanelFarmBuddyButton_OnLoad()
-- DESC : Registers the plugin upon it loading
-- **************************************************************************
function TitanPanelFarmBuddyButton_OnLoad(self)
	self.registry = {
		id = TITAN_FARM_BUDDY_ID,
		category = 'Information',
		version = TITAN_VERSION,
		menuText = ADDON_NAME .. ' (' .. ADDON_VERSION .. ')',
		buttonTextFunction = 'TitanPanelFamBuddyButton_GetButtonText',
		tooltipTitle = ADDON_NAME,
		tooltipTextFunction = 'TitanPanelFamBuddyButton_GetTooltipText',
		-- TODO: Default icon, possible to replace it with the tracked item icon?
		icon = 'Interface\\Icons\\INV_ENG_CRATE', -- self.registry.icon ?
		iconWidth = 16,
		controlVariables = {
			ShowIcon = true,
			ShowLabelText = true,
			ShowRegularText = false,
			ShowColoredText = true,
			DisplayOnRightSide = false
		},
		savedVariables = {
			ShowIcon = 1,
			ShowLabelText = false
		}
	}

	self.db = LibStub('AceDB-3.0'):New('TitanFarmBuddyDB', defaults, true)

	self:RegisterEvent('PLAYER_ENTERING_WORLD')
	self:RegisterEvent('PLAYER_LEAVING_WORLD')
end

-- **************************************************************************
-- NAME : TitanPanelFarmBuddyButton_GetButtonText(id)
-- DESC : Calculate the item count of the tracked farm item and displays it.
-- VARS : id = button ID
-- **************************************************************************
function TitanPanelFarmBuddyButton_GetButtonText(id)

	-- TODO: Get tracked item icon (http://wowprogramming.com/docs/api/GetItemIcon)

	return 'FarmBuddy'
end

-- **************************************************************************
-- NAME : TitanPanelFarmBuddyButton_GetTooltipText()
-- DESC : Display tooltip text
-- **************************************************************************
function TitanPanelFarmBuddyButton_GetTooltipText()

	return 'FarmBuddy'
end

-- **************************************************************************
-- NAME : TitanPanelFarmBuddyButton_OnEvent()
-- DESC : Parse events registered to plugin and act on them
-- **************************************************************************
function TitanPanelFarmBuddyButton_OnEvent(self, event, ...)
	-- TODO: Handle events
end

-- **************************************************************************
-- NAME : TitanPanelFarmBuddyButton_OnShow()
-- DESC : Display button when plugin is visible
-- **************************************************************************
function TitanPanelFarmBuddyButton_OnShow()
	-- TODO: Implement this function
end

-- **************************************************************************
-- NAME : TitanPanelLocationButton_OnHide()
-- DESC : Destroy vars on button remove
-- **************************************************************************
function TitanPanelLocationButton_OnHide()
	-- TODO: Implement this function
end


function TitanFarmBuddy:SetItem(info, input)
   TitanFarmBuddy.db.char.Item = input
   TitanPanelButton_UpdateButton(ID)
end

function TitanFarmBuddy:SetGoal(info, input)
   TitanFarmBuddy.db.char.Goal = tonumber(input)
   TitanPanelButton_UpdateButton(ID)
end
