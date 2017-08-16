-- **************************************************************************
-- * TitanFarmBuddy.lua
-- *
-- * By: Keldor
-- **************************************************************************

local TITAN_FARM_BUDDY_ID = 'FarmBuddy'
local ADDON_NAME = 'Titan Farm Buddy'
local L = LibStub('AceLocale-3.0'):GetLocale('Titan', true)
local TitanFarmBuddy = LibStub('AceAddon-3.0'):NewAddon(TITAN_FARM_BUDDY_ID, 'AceConsole-3.0')
local ADDON_VERSION = GetAddOnMetadata('TitanFarmBuddy', 'Version')
local DEFAULTS = {
	char = {
		Item = '',
		Goal = '',
		GoalNotification = 0,
		ShowItemName = 1
	}
};

-- **************************************************************************
-- NAME : TitanFarmBuddy:OnInitialize()
-- DESC : Is called by AceAddon when the addon is first loaded
-- **************************************************************************
function TitanFarmBuddy:OnInitialize()

	self.db = LibStub('AceDB-3.0'):New('TitanFarmBuddyDB', DEFAULTS, true)

    LibStub('AceConfig-3.0'):RegisterOptionsTable(ADDON_NAME, TitanFarmBuddy:GetConfigOption());
    LibStub('AceConfigDialog-3.0'):AddToBlizOptions(ADDON_NAME);
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetConfigOption()
-- DESC : Gets the configuration array for the AceConfig lib
-- **************************************************************************
function TitanFarmBuddy:GetConfigOption()
	return {
		name = ADDON_NAME,
		handler = TitanFarmBuddy,
		type = 'group',
		args = {
			info_version = {
				type		= 'description',
				name		= L['Version'] .. ': ' .. ADDON_VERSION,
				order		= 0,
			},
			info_author = {
				type		= 'description',
				name		= L['Author'] .. ': ' .. GetAddOnMetadata('TitanFarmBuddy', 'Author'),
				order		= 10,
			},
			header_general = {
				type		= 'header',
				name		= L['General Options'],
				order		= 20,
			},
			item_count = {
				type     = 'input',
				name     = L['Item to Track'],
				desc     = L['The name of the item to track'],
				get      = 'GetItem',
				set      = 'SetItem',
				validate = 'ValidateItem',
				usage    = L['Enter the name of an item or CTRL + Click an item from your inventory.'],
				width    = 'double',
				order    = 30,
			},
			space_1 = {
				type     = 'description',
				name     = '',
				order    = 40,
			},
			goal = {
				type     = 'input',
				name     = L['Quantity for Alert'],
				desc     = L['The goal quantity for the tracked item to show a finish notification.'],
				get      = 'GetGoal',
				set      = 'SetGoal',
				usage    = L['An number for your farming goal.'],
				width    = 'double',
				order    = 50,
			},
			space_2 = {
				type     = 'description',
				name     = '',
				order    = 60,
			},
			item_show_item_name = {
				type	   = 'toggle',
				name     = L['Show item name'],
				desc     = L['Show the item name on the Titan Bar.'],
				get	     = 'GetShowItemName',
				set	     = 'SetShowItemName',
				width	   = 'full',
				order	   = 70,
			},
			space_3 = {
				type     = 'description',
				name     = '',
				order    = 80,
			},
			item_notification_status = {
				type	   = 'toggle',
				name     = L['Notification if quantity has reached'],
				desc     = L['Shows a notification if the item quantity has reached.'],
				get	     = 'GetNotificationStatus',
				set	     = 'SetNotificationStatus',
				width	   = 'full',
				order	   = 90,
			},
			header_actions = {
				type	   = 'header',
				name	   = L['Actions'],
				order	   = 100,
			},
			item_reset = {
				type	   = 'execute',
				name     = L['Reset'],
				desc     = L['Resets the tracked item.'],
				func	   = 'ResetConfig',
				width    = 'double',
				order	   = 110,
			},
			space_3 = {
				type     = 'description',
				name     = '',
				order    = 120,
			},
			item_test_alert = {
				type	   = 'execute',
				name     = L['Test Notification'],
				desc     = L['Triggers a test for the finish notification.'],
				func	   = 'TestNotification',
				width    = 'double',
				order	   = 130,
			}

			-- TODO: Notification Sound select
		}
	}
end

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
		buttonTextFunction = 'TitanPanelFarmBuddyButton_GetButtonText',
		tooltipTitle = ADDON_NAME,
		tooltipTextFunction = 'TitanPanelFarmBuddyButton_GetTooltipText',
		icon = 'Interface\\AddOns\\TitanFarmBuddy\\TitanFarmBuddy',
		iconWidth = 0,
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

	self:RegisterEvent('PLAYER_ENTERING_WORLD')
	self:RegisterEvent('PLAYER_LEAVING_WORLD')
end

-- **************************************************************************
-- NAME : TitanPanelFarmBuddyButton_GetButtonText(id)
-- DESC : Calculate the item count of the tracked farm item and displays it.
-- **************************************************************************
function TitanPanelFarmBuddyButton_GetButtonText(id)

	-- TODO: Get show icon status from Titan Panel
	-- self.registry['controlVariables'].ShowIcon

	-- TODO: Refactor and handle options
	-- TODO: Color item count

	local itemName, itemLink = GetItemInfo(TitanFarmBuddy.db.char.Item)
	local iconFileDataID = GetItemIcon(itemLink)
	local itemCount = GetItemCount(itemLink)
	local label = '|T' .. iconFileDataID .. ':16:16:0:-2|t'

	return label .. ' ' .. itemCount .. ' ' .. itemName
end

function TitanPanelFarmBuddyButton_OnClick(self, button)

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
function TitanPanelFarmBuddyButton_OnShow(self)
	TitanPanelButton_OnShow(self);
end

-- **************************************************************************
-- NAME : TitanPanelFarmBuddyButton_OnHide()
-- DESC : Destroy vars on button remove
-- **************************************************************************
function TitanPanelFarmBuddyButton_OnHide()
	-- TODO: Implement this function
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:ValidateItem()
-- DESC : Checks if the entered item name is valid
-- **************************************************************************
function TitanFarmBuddy:ValidateItem(info, input)

	local _, itemLink = GetItemInfo(input)

	if itemLink ~= nil then
		return true
	end

	TitanFarmBuddy:Print(L['The item does not exists.']);
	return false
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetItem()
-- DESC : Sets the item
-- **************************************************************************
function TitanFarmBuddy:SetItem(info, input)
   self.db.char.Item = input
   TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetItem()
-- DESC : Gets the item
-- **************************************************************************
function TitanFarmBuddy:GetItem()
   return self.db.char.Item
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetGoal()
-- DESC : Sets the item goal
-- **************************************************************************
function TitanFarmBuddy:SetGoal(info, input)
   self.db.char.Goal = tonumber(input)
   TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetGoal()
-- DESC : Gets the item goal
-- **************************************************************************
function TitanFarmBuddy:GetGoal()
   return tostring(self.db.char.Goal)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetNotificationStatus()
-- DESC : Sets the notification status
-- **************************************************************************
function TitanFarmBuddy:SetNotificationStatus(info, input)
	self.db.char.GoalNotification = input
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetNotificationStatus()
-- DESC : Gets the notification status
-- **************************************************************************
function TitanFarmBuddy:GetNotificationStatus()
	return self.db.char.GoalNotification
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetShowItemName()
-- DESC : Sets the show item name status
-- **************************************************************************
function TitanFarmBuddy:SetShowItemName(info, input)
	self.db.char.ShowItemName = input
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetShowItemName()
-- DESC : Gets the show item name status
-- **************************************************************************
function TitanFarmBuddy:GetShowItemName()
	return self.db.char.ShowItemName
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:ResetConfig()
-- DESC : Resets the saved config to the default values
-- **************************************************************************
function TitanFarmBuddy:ResetConfig()
	self.db.char.Item = DEFAULTS.char.Item
	self.db.char.Goal = DEFAULTS.char.Goal
	self.db.char.GoalNotification = DEFAULTS.char.GoalNotification
	self.db.char.ShowItemName = DEFAULTS.char.ShowItemName
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:TestNotification()
-- DESC : Raises a test notification
-- **************************************************************************
function TitanFarmBuddy:TestNotification()
	-- TODO: Call notification function
	TitanFarmBuddy:Print('Hello, World!')
end
