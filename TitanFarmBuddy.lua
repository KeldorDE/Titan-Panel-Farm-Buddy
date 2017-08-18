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
local OPTION_ORDER = 0


-- **************************************************************************
-- NAME : TitanFarmBuddy:OnInitialize()
-- DESC : Is called by AceAddon when the addon is first loaded.
-- **************************************************************************
function TitanFarmBuddy:OnInitialize()
    LibStub('AceConfig-3.0'):RegisterOptionsTable(ADDON_NAME, TitanFarmBuddy:GetConfigOption());
    LibStub('AceConfigDialog-3.0'):AddToBlizOptions(ADDON_NAME);
end

-- **************************************************************************
-- NAME : TitanPanelFarmBuddyButton_OnLoad()
-- DESC : Registers the plugin upon it loading.
-- **************************************************************************
function TitanPanelFarmBuddyButton_OnLoad(self)
	self.registry = {
		id = TITAN_FARM_BUDDY_ID,
		category = 'Information',
		version = TITAN_VERSION,
		menuText = ADDON_NAME,
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
			DisplayOnRightSide = true
		},
		savedVariables = {
			ShowIcon = 1,
			ShowLabelText = 1,
			ShowColoredText = 1,
			DisplayOnRightSide = false,
			Item = '',
			Goal = 0,
			GoalNotification = true,
			IncludeBank = false,
			ShowGoal = false,
			GoalNotificationSound = 'UI_FightClub_Victory'
		}
	}

	self:RegisterEvent('BAG_UPDATE')
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetConfigOption()
-- DESC : Gets the configuration array for the AceConfig lib.
-- **************************************************************************
function TitanFarmBuddy:GetConfigOption()
	return {
		name = ADDON_NAME,
		handler = TitanFarmBuddy,
		type = 'group',
		args = {
			info_version = {
				type = 'description',
				name = L['FARM_BUDDY_VERSION'] .. ': ' .. ADDON_VERSION,
				order = TitanFarmBuddy:GetOptionOrder(),
			},
			info_author = {
				type = 'description',
				name = L['FARM_BUDDY_AUTHOR'] .. ': ' .. GetAddOnMetadata('TitanFarmBuddy', 'Author'),
				order = TitanFarmBuddy:GetOptionOrder(),
			},
			header_general = {
				type = 'header',
				name = L['FARM_BUDDY_GENERAL_OPTIONS'],
				order = TitanFarmBuddy:GetOptionOrder(),
			},
			item_count = {
				type = 'input',
				name = L['FARM_BUDDY_ITEM_TO_TRACK'],
				desc = L['FARM_BUDDY_ITEM_TO_TRACK_DESC'],
				get = 'GetItem',
				set = 'SetItem',
				validate = 'ValidateItem',
				usage = L['FARM_BUDDY_ITEM_TO_TRACK_USAGE'],
				width = 'double',
				order = TitanFarmBuddy:GetOptionOrder(),
			},
			space_1 = {
				type = 'description',
				name = '',
				order = TitanFarmBuddy:GetOptionOrder(),
			},
			goal = {
				type = 'input',
				name = L['FARM_BUDDY_ALERT_COUNT'],
				desc = L['FARM_BUDDY_ALERT_COUNT_DESC'],
				get = 'GetGoal',
				set = 'SetGoal',
				usage = L['FARM_BUDDY_ALERT_COUNT_USAGE'],
				width = 'double',
				order = TitanFarmBuddy:GetOptionOrder(),
			},
			space_2 = {
				type = 'description',
				name = '',
				order = TitanFarmBuddy:GetOptionOrder(),
			},
			item_show_item_icon = {
				type = 'toggle',
				name = L['FARM_BUDDY_SHOW_ICON'],
				desc = L['FARM_BUDDY_SHOW_ICON_DESC'],
				get = 'GetShowItemIcon',
				set = 'SetShowItemIcon',
				width = 'full',
				order = TitanFarmBuddy:GetOptionOrder(),
			},
			space_3 = {
				type = 'description',
				name = '',
				order = TitanFarmBuddy:GetOptionOrder(),
			},
			item_show_item_name = {
				type = 'toggle',
				name = L['FARM_BUDDY_SHOW_NAME'],
				desc = L['FARM_BUDDY_SHOW_NAME_DESC'],
				get = 'GetShowItemName',
				set = 'SetShowItemName',
				width = 'full',
				order = TitanFarmBuddy:GetOptionOrder(),
			},
			space_4 = {
				type = 'description',
				name = '',
				order = TitanFarmBuddy:GetOptionOrder(),
			},
			item_show_colored_text = {
				type = 'toggle',
				name = L['FARM_BUDDY_SHOW_COLORED_TEXT'],
				desc = L['FARM_BUDDY_SHOW_COLORED_TEXT_DESC'],
				get = 'GetShowColoredText',
				set = 'SetShowColoredText',
				width = 'full',
				order = TitanFarmBuddy:GetOptionOrder(),
			},
			space_5 = {
				type = 'description',
				name = '',
				order = TitanFarmBuddy:GetOptionOrder(),
			},
			item_show_goal = {
				type = 'toggle',
				name = L['FARM_BUDDY_SHOW_GOAL'],
				desc = L['FARM_BUDDY_SHOW_GOAL_DESC'],
				get = 'GetShowGoal',
				set = 'SetShowGoal',
				width = 'full',
				order = TitanFarmBuddy:GetOptionOrder(),
			},
			space_6 = {
				type = 'description',
				name = '',
				order = TitanFarmBuddy:GetOptionOrder(),
			},
			item_track_bank = {
				type = 'toggle',
				name = L['FARM_BUDDY_INCLUDE_BANK'],
				desc = L['FARM_BUDDY_INCLUDE_BANK_DESC'],
				get = 'GetIncludeBank',
				set = 'SetIncludeBank',
				width = 'full',
				order = TitanFarmBuddy:GetOptionOrder(),
			},
			header_notification = {
				type = 'header',
				name = L['FARM_BUDDY_NOTIFICATION_OPTIONS'],
				order = TitanFarmBuddy:GetOptionOrder(),
			},
			item_notification_status = {
				type = 'toggle',
				name = L['FARM_BUDDY_NOTIFICATION'],
				desc = L['FARM_BUDDY_NOTIFICATION_DESC'],
				get = 'GetNotificationStatus',
				set = 'SetNotificationStatus',
				width = 'full',
				order = TitanFarmBuddy:GetOptionOrder(),
			},
      space_7 = {
				type = 'description',
				name = '',
				order = TitanFarmBuddy:GetOptionOrder(),
			},
			item_notification_sound = {
        type = 'select',
        name = L['TITAN_BUDDY_NOTIFICATION_SOUND'],
        style = 'dropdown',
        values = TitanFarmBuddy_GetSounds(),
        set = 'SetNotificationSound',
        get = 'GetNotificationSound',
        width = 'double',
        order = TitanFarmBuddy:GetOptionOrder(),
		  },
			header_actions = {
				type = 'header',
				name = L['FARM_BUDDY_ACTIONS'],
				order = TitanFarmBuddy:GetOptionOrder(),
			},
			item_reset = {
				type = 'execute',
				name = L['FARM_BUDDY_RESET'],
				desc = L['FARM_BUDDY_RESET_DESC'],
				func = 'ResetConfig',
				width = 'double',
				order = TitanFarmBuddy:GetOptionOrder(),
			},
			space_8 = {
				type = 'description',
				name = '',
				order = TitanFarmBuddy:GetOptionOrder(),
			},
			item_test_alert = {
				type = 'execute',
				name = L['FARM_BUDDY_TEST_NOTIFICATION'],
				desc = L['FARM_BUDDY_TEST_NOTIFICATION_DESC'],
				func = 'TestNotification',
				width = 'double',
				order = TitanFarmBuddy:GetOptionOrder(),
			}
		}
	}
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetOptionOrder()
-- DESC : A helper function to order the option items in the order as listed in the array.
-- **************************************************************************
function TitanFarmBuddy:GetOptionOrder()
	OPTION_ORDER = OPTION_ORDER + 1
	return OPTION_ORDER
end

-- **************************************************************************
-- NAME : TitanPanelFarmBuddyButton_GetButtonText()
-- DESC : Calculate the item count of the tracked farm item and displays it.
-- **************************************************************************
function TitanPanelFarmBuddyButton_GetButtonText(id)

	local str = ''
	local showIcon = TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowIcon')
	local itemName, itemLink = GetItemInfo(TitanGetVar(TITAN_FARM_BUDDY_ID, 'Item'))

	-- Invalid item or no item defined
	if itemLink == nil then

		if showIcon == 1 then
			str = str .. TitanFarmBuddy:GetIconString('Interface\\AddOns\\TitanFarmBuddy\\TitanFarmBuddy', true)
		end

		str = str .. ADDON_NAME
	else

		local iconFileDataID = GetItemIcon(itemLink)
		local itemCount = GetItemCount(itemLink, TitanGetVar(TITAN_FARM_BUDDY_ID, 'IncludeBank'))
		local goalValue = TitanGetVar(TITAN_FARM_BUDDY_ID, 'Goal')
		local showColoredText = TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowColoredText')

		if showIcon == 1 then
			str = str .. TitanFarmBuddy:GetIconString(iconFileDataID, true)
		end

		str = str .. TitanFarmBuddy:GetBarValue(itemCount, showColoredText)

		if TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowGoal') == true and goalValue > 0 then
			str = str .. ' / ' .. TitanFarmBuddy:GetBarValue(goalValue, showColoredText)
		end

		if TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowLabelText') == 1 then
			str = str .. ' ' .. itemName
		end
	end

	return str
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetIconString()
-- DESC : Gets an icon string.
-- **************************************************************************
function TitanFarmBuddy:GetIconString(icon, space)

	local str = '|T' .. icon .. ':16:16:0:-2|t'

	if space == true then
		str = str .. ' '
	end

	return str
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetBarValue()
-- DESC : Gets a value with highlighted color for the Titan Bar.
-- **************************************************************************
function TitanFarmBuddy:GetBarValue(value, colored)

	if colored == 1 then
		value = TitanUtils_GetHighlightText(value)
	end

	return value
end

-- **************************************************************************
-- NAME : TitanPanelFarmBuddyButton_OnClick()
-- DESC : Handles click events to the Titan Button.
-- **************************************************************************
function TitanPanelFarmBuddyButton_OnClick(self, button)

	if (button == 'LeftButton') then
		-- Workarround for opening controls instead of AddOn options
		-- Call it two times to ensure the AddOn panel is opened
		InterfaceOptionsFrame_OpenToCategory(ADDON_NAME)
		InterfaceOptionsFrame_OpenToCategory(ADDON_NAME)
 	end
end

-- **************************************************************************
-- NAME : TitanPanelFarmBuddyButton_GetTooltipText()
-- DESC : Display tooltip text.
-- **************************************************************************
function TitanPanelFarmBuddyButton_GetTooltipText()

	local str = TitanUtils_GetGreenText(L['FARM_BUDDY_TOOLTIP_DESC']) .. '\n\n'
	local itemName, itemLink = GetItemInfo(TitanGetVar(TITAN_FARM_BUDDY_ID, 'Item'))

	-- Invalid item or no item defined
	if itemLink == nil then
		str = str .. L['FARM_BUDDY_NO_ITEM_TRACKED']
	else

		local iconFileDataID = GetItemIcon(itemLink)
		local countBags = GetItemCount(itemLink)
		local countTotal = GetItemCount(itemLink, true)
		local countBank = (countTotal - countBags)
		local goalValue = L['FARM_BUDDY_NO_GOAL']
		local goal = TitanGetVar(TITAN_FARM_BUDDY_ID, 'Goal')

		if goal > 0 then
			goalValue = goal
		end

		str = str .. L['FARM_BUDDY_SUMMARY'] .. '\n--------------------------------\n'
		str = str .. L['FARM_BUDDY_ITEM'] .. ':\t' .. TitanFarmBuddy:GetIconString(iconFileDataID, true) .. TitanUtils_GetHighlightText(itemName) .. '\n'
		str = str .. L['FARM_BUDDY_INVENTORY'] .. ':\t' .. TitanUtils_GetHighlightText(countBags) .. '\n'
		str = str .. L['FARM_BUDDY_BANK'] .. ':\t' .. TitanUtils_GetHighlightText(countBank) .. '\n'
		str = str .. L['FARM_BUDDY_TOTAL'] .. ':\t' .. TitanUtils_GetHighlightText(countTotal) .. '\n'
		str = str .. L['FARM_BUDDY_ALERT_COUNT'] .. ':\t' .. TitanUtils_GetHighlightText(goalValue) .. '\n'
	end

	return str
end

-- **************************************************************************
-- NAME : TitanPanelRightClickMenu_PrepareFarmBuddyMenu()
-- DESC : Display rightclick menu options
-- **************************************************************************
function TitanPanelRightClickMenu_PrepareFarmBuddyMenu(frame, level, menuList)

	if level == 1 then

		TitanPanelRightClickMenu_AddTitle(TitanPlugins[TITAN_FARM_BUDDY_ID].menuText, level)

		info = {}
		info.notCheckable = true
		info.text = L['TITAN_PANEL_OPTIONS']
		info.menuList = 'Options'
		info.hasArrow = 1
		L_UIDropDownMenu_AddButton(info)

		TitanPanelRightClickMenu_AddSpacer();
		TitanPanelRightClickMenu_AddToggleIcon(TITAN_FARM_BUDDY_ID)
		TitanPanelRightClickMenu_AddToggleLabelText(TITAN_FARM_BUDDY_ID)
		TitanPanelRightClickMenu_AddToggleColoredText(TITAN_FARM_BUDDY_ID)
		TitanPanelRightClickMenu_AddSpacer()
		TitanPanelRightClickMenu_AddCommand(L['FARM_BUDDY_RESET'], TITAN_FARM_BUDDY_ID, 'TitanPanelFarmBuddyButton_ResetConfig')
		TitanPanelRightClickMenu_AddCommand(L['TITAN_PANEL_MENU_HIDE'], TITAN_FARM_BUDDY_ID, TITAN_PANEL_MENU_FUNC_HIDE)

	elseif level == 2 and menuList == 'Options' then

		TitanPanelRightClickMenu_AddTitle(L['TITAN_PANEL_OPTIONS'], level)

		info = {}
		info.text = L['FARM_BUDDY_SHOW_GOAL']
		info.func = TitanPanelFarmBuddyButton_ToggleShowGoal
		info.checked = TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowGoal')
		L_UIDropDownMenu_AddButton(info, level)

		info = {}
		info.text = L['FARM_BUDDY_INCLUDE_BANK']
		info.func = TitanPanelFarmBuddyButton_ToggleIncludeBank
		info.checked = TitanGetVar(TITAN_FARM_BUDDY_ID, 'IncludeBank')
		L_UIDropDownMenu_AddButton(info, level)

		info = {}
		info.text = L['FARM_BUDDY_NOTIFICATION']
		info.func = TitanPanelFarmBuddyButton_ToggleGoalNotification
		info.checked = TitanGetVar(TITAN_FARM_BUDDY_ID, 'GoalNotification')
		L_UIDropDownMenu_AddButton(info, level)
	end
end

-- **************************************************************************
-- NAME : TitanPanelFarmBuddyButton_OnEvent()
-- DESC : Parse events registered to plugin and act on them.
-- **************************************************************************
function TitanPanelFarmBuddyButton_OnEvent(self, event, ...)
	TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
end

-- **************************************************************************
-- NAME : TitanPanelFarmBuddyButton_OnShow()
-- DESC : Display button when plugin is visible.
-- **************************************************************************
function TitanPanelFarmBuddyButton_OnShow(self)
	TitanPanelButton_OnShow(self);
end

-- **************************************************************************
-- NAME : TitanPanelFarmBuddyButton_OnHide()
-- DESC : Destroy vars on button remove.
-- **************************************************************************
function TitanPanelFarmBuddyButton_OnHide()
	-- TODO: Implement this function
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetOptionChoiceVal()
-- DESC : Returns the formated input value for an AceOption input.
-- **************************************************************************
function TitanFarmBuddy:GetOptionChoiceVal(input)

	local val = false
	if input == true then
		val = 1
	end

	return val
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:ValidateItem()
-- DESC : Checks if the entered item name is valid.
-- **************************************************************************
function TitanFarmBuddy:ValidateItem(info, input)

	local _, itemLink = GetItemInfo(input)

	if itemLink ~= nil then
		return true
	end

	TitanFarmBuddy:Print(L['FARM_BUDDY_ITEM_NOT_EXISTS']);
	return false
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetItem()
-- DESC : Sets the item.
-- **************************************************************************
function TitanFarmBuddy:SetItem(info, input)
   TitanSetVar(TITAN_FARM_BUDDY_ID, 'Item', input)
   TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetItem()
-- DESC : Gets the item.
-- **************************************************************************
function TitanFarmBuddy:GetItem()
   return TitanGetVar(TITAN_FARM_BUDDY_ID, 'Item')
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetGoal()
-- DESC : Sets the item goal.
-- **************************************************************************
function TitanFarmBuddy:SetGoal(info, input)
   TitanSetVar(TITAN_FARM_BUDDY_ID, 'Goal', tonumber(input))
   TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetGoal()
-- DESC : Gets the item goal.
-- **************************************************************************
function TitanFarmBuddy:GetGoal()
   return tostring(TitanGetVar(TITAN_FARM_BUDDY_ID, 'Goal'))
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetNotificationStatus()
-- DESC : Sets the notification status.
-- **************************************************************************
function TitanFarmBuddy:SetNotificationStatus(info, input)
	TitanSetVar(TITAN_FARM_BUDDY_ID, 'GoalNotification', input)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetNotificationStatus()
-- DESC : Gets the notification status.
-- **************************************************************************
function TitanFarmBuddy:GetNotificationStatus()
	return TitanGetVar(TITAN_FARM_BUDDY_ID, 'GoalNotification')
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetNotificationSound()
-- DESC : Sets the notification sound.
-- **************************************************************************
function TitanFarmBuddy:SetNotificationSound(info, input)
	TitanSetVar(TITAN_FARM_BUDDY_ID, 'GoalNotificationSound', input)
	PlaySound(input, 'master');
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetNotificationSound()
-- DESC : Gets the notification sound.
-- **************************************************************************
function TitanFarmBuddy:GetNotificationSound()
	return TitanGetVar(TITAN_FARM_BUDDY_ID, 'GoalNotificationSound')
end

-- **************************************************************************
-- NAME : TitanPanelFarmBuddyButton_ToggleGoalNotification()
-- DESC : Sets the notification status.
-- **************************************************************************
function TitanPanelFarmBuddyButton_ToggleGoalNotification()
	TitanToggleVar(TITAN_FARM_BUDDY_ID, 'GoalNotification');
	TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetShowItemIcon()
-- DESC : Sets the show item icon status.
-- **************************************************************************
function TitanFarmBuddy:SetShowItemIcon(info, input)
	local val = TitanFarmBuddy:GetOptionChoiceVal(input)
	TitanSetVar(TITAN_FARM_BUDDY_ID, 'ShowIcon', val)
	TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetShowItemIcon()
-- DESC : Gets the show item icon status.
-- **************************************************************************
function TitanFarmBuddy:GetShowItemIcon()
	return TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowIcon')
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetShowItemName()
-- DESC : Sets the show item name status.
-- **************************************************************************
function TitanFarmBuddy:SetShowItemName(info, input)
	local val = TitanFarmBuddy:GetOptionChoiceVal(input)
	TitanSetVar(TITAN_FARM_BUDDY_ID, 'ShowLabelText', val)
	TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetShowItemName()
-- DESC : Gets the show item name status.
-- **************************************************************************
function TitanFarmBuddy:GetShowItemName()
	return TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowLabelText')
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetShowColoredText()
-- DESC : Sets the show colored text status.
-- **************************************************************************
function TitanFarmBuddy:SetShowColoredText(info, input)
	local val = TitanFarmBuddy:GetOptionChoiceVal(input)
	TitanSetVar(TITAN_FARM_BUDDY_ID, 'ShowColoredText', val)
	TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetShowColoredText()
-- DESC : Gets the show colored text status.
-- **************************************************************************
function TitanFarmBuddy:GetShowColoredText()
	return TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowColoredText')
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetShowGoal()
-- DESC : Sets the show goal status.
-- **************************************************************************
function TitanFarmBuddy:SetShowGoal(info, input)
	TitanSetVar(TITAN_FARM_BUDDY_ID, 'ShowGoal', input)
	TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetShowGoal()
-- DESC : Gets the show goal status.
-- **************************************************************************
function TitanFarmBuddy:GetShowGoal()
	return TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowGoal')
end

-- **************************************************************************
-- NAME : TitanPanelFarmBuddyButton_ToggleShowGoal()
-- DESC : Sets the show goal status.
-- **************************************************************************
function TitanPanelFarmBuddyButton_ToggleShowGoal()
	TitanToggleVar(TITAN_FARM_BUDDY_ID, 'ShowGoal');
	TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetTrackBank()
-- DESC : Sets the track items in bank status.
-- **************************************************************************
function TitanFarmBuddy:SetIncludeBank(info, input)
	TitanSetVar(TITAN_FARM_BUDDY_ID, 'IncludeBank', input)
	TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetTrackBank()
-- DESC : Gets the track items in bank status.
-- **************************************************************************
function TitanFarmBuddy:GetIncludeBank()
	return TitanGetVar(TITAN_FARM_BUDDY_ID, 'IncludeBank')
end

-- **************************************************************************
-- NAME : TitanPanelFarmBuddyButton_ToggleIncludeBank()
-- DESC : Sets the track items in bank status.
-- **************************************************************************
function TitanPanelFarmBuddyButton_ToggleIncludeBank()
	TitanToggleVar(TITAN_FARM_BUDDY_ID, 'IncludeBank');
	TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:ResetConfig()
-- DESC : Resets the saved config to the default values.
-- **************************************************************************
function TitanFarmBuddy:ResetConfig()

	TitanSetVar(TITAN_FARM_BUDDY_ID, 'Item', '')
	TitanSetVar(TITAN_FARM_BUDDY_ID, 'Goal', 0)
	TitanSetVar(TITAN_FARM_BUDDY_ID, 'GoalNotification', true)
	TitanSetVar(TITAN_FARM_BUDDY_ID, 'ShowGoal', false)
	TitanSetVar(TITAN_FARM_BUDDY_ID, 'IncludeBank', false)
	TitanSetVar(TITAN_FARM_BUDDY_ID, 'ShowIcon', 1)
	TitanSetVar(TITAN_FARM_BUDDY_ID, 'ShowLabelText', 1)
	TitanSetVar(TITAN_FARM_BUDDY_ID, 'ShowColoredText', 1)
	TitanSetVar(TITAN_FARM_BUDDY_ID, 'GoalNotificationSound', 'UI_FightClub_Victory')

	TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
end

-- **************************************************************************
-- NAME : TitanPanelFarmBuddyButton_ResetConfig()
-- DESC : Resets the saved config to the default values.
-- **************************************************************************
function TitanPanelFarmBuddyButton_ResetConfig()
	TitanFarmBuddy:ResetConfig()
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:TestNotification()
-- DESC : Raises a test notification.
-- **************************************************************************
function TitanFarmBuddy:TestNotification()
	-- TODO: Call notification function
	TitanFarmBuddy:Print('The notifications are not implemented yet!')
end
