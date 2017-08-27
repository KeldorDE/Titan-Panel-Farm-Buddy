-- **************************************************************************
-- * TitanFarmBuddy.lua
-- *
-- * By: Keldor
-- **************************************************************************

local TITAN_FARM_BUDDY_ID = 'FarmBuddy';
local ADDON_NAME = 'Titan Farm Buddy';
local L = LibStub('AceLocale-3.0'):GetLocale('Titan', true);
local TitanFarmBuddy = LibStub('AceAddon-3.0'):NewAddon(TITAN_FARM_BUDDY_ID, 'AceConsole-3.0', 'AceHook-3.0', 'AceTimer-3.0');
local ADDON_VERSION = GetAddOnMetadata('TitanFarmBuddy', 'Version');
local OPTION_ORDER = {};
local ITEMS_AVAILABLE = 4;
local NOTIFICATION_COUNT = 0;
local NOTIFICATION_QUEUE = {};
local NOTIFICATION_TRIGGERED = {};
local CHAT_COMMAND = 'fb';
local CHAT_COMMANDS = {
  track = {
    Args = '<' .. L['FARM_BUDDY_COMMAND_PRIMARY_ARGS']:gsub('!max!', ITEMS_AVAILABLE) .. '> <' .. L['FARM_BUDDY_COMMAND_TRACK_ARGS'] .. '>',
    Description = L['FARM_BUDDY_COMMAND_TRACK_DESC']
  },
  quantity = {
    Args = '<' .. L['FARM_BUDDY_COMMAND_PRIMARY_ARGS']:gsub('!max!', ITEMS_AVAILABLE) .. '> <' .. L['FARM_BUDDY_COMMAND_GOAL_ARGS'] .. '>',
    Description = L['FARM_BUDDY_COMMAND_GOAL_DESC']
  },
  primary = {
    Args = '<' .. L['FARM_BUDDY_COMMAND_PRIMARY_ARGS']:gsub('!max!', ITEMS_AVAILABLE) .. '>',
    Description = L['FARM_BUDDY_COMMAND_PRIMARY_DESC']
  },
  reset = {
    Args = '',
    Description = L['FARM_BUDDY_COMMAND_RESET_DESC']
  },
  version = {
    Args = '',
    Description = L['FARM_BUDDY_COMMAND_VERSION_DESC']
  },
  help = {
    Args = '',
    Description = L['FARM_BUDDY_COMMAND_HELP_DESC']
  }
};

-- **************************************************************************
-- NAME : TitanFarmBuddy:OnInitialize()
-- DESC : Is called by AceAddon when the addon is first loaded.
-- **************************************************************************
function TitanFarmBuddy:OnInitialize()
  LibStub('AceConfig-3.0'):RegisterOptionsTable(ADDON_NAME, TitanFarmBuddy:GetConfigOption());
  LibStub('AceConfigDialog-3.0'):AddToBlizOptions(ADDON_NAME);

  -- Register chat command
  TitanFarmBuddy:RegisterChatCommand(CHAT_COMMAND, 'ChatCommand');
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
			ShowIcon = true,
			ShowLabelText = true,
			ShowColoredText = true,
			DisplayOnRightSide = false,
			Item1 = '',
			Item2 = '',
			Item3 = '',
			Item4 = '',
			ItemQuantity1 = 0,
			ItemQuantity2 = 0,
			ItemQuantity3 = 0,
			ItemQuantity4 = 0,
      ItemShowInBarIndex = 1,
			GoalNotification = true,
			IncludeBank = false,
			ShowGoal = true,
			GoalNotificationSound = 'UI_WORLDQUEST_COMPLETE',
			PlayNotificationSound = true,
      NotificationDisplayDuration = 5,
      NotificationGlow = true,
      NotificationShine = true,
		}
	};

  TitanFarmBuddy:RegisterDialogs();

  for i = 1, ITEMS_AVAILABLE do
    NOTIFICATION_TRIGGERED[i] = false;
  end

	self:RegisterEvent('BAG_UPDATE');
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:OnEnable()
-- DESC : Is called when the Plugin gets enabled.
-- **************************************************************************
function TitanFarmBuddy:OnEnable()

  self:SecureHook('ContainerFrameItemButton_OnModifiedClick');
  self:ScheduleRepeatingTimer('NotificationTask', 1);
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:OnDisable()
-- DESC : Is called when the Plugin gets disabled.
-- **************************************************************************
function TitanFarmBuddy:OnDisable()
  self:CancelAllTimers();
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:RegisterDialogs()
-- DESC : Registers the addons dialog boxes.
-- **************************************************************************
function TitanFarmBuddy:RegisterDialogs()

  StaticPopupDialogs[ADDON_NAME .. 'ResetAllConfirm'] = {
    text = L['TITAN_FARM_BUDDY_CONFIRM_RESET'],
    button1 = L['TITAN_FARM_BUDDY_YES'],
    button2 = L['TITAN_FARM_BUDDY_NO'],
    OnAccept = function()
      TitanFarmBuddy:ResetConfig();
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
  };
  StaticPopupDialogs[ADDON_NAME .. 'SetItemIndex'] = {
    text = L['TITAN_FARM_BUDDY_CHOOSE_ITEM_INDEX'],
    button1 = L['TITAN_FARM_BUDDY_OK'],
    button2 = L['TITAN_FARM_BUDDY_CANCEL'],
    hasEditBox = true,
    OnShow = TitanFamrBuddyButton_SetItemIndexOnShow,
    OnAccept = TitanFamrBuddyButton_SetItemIndexOnAccept,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
  };
end

-- **************************************************************************
-- NAME : TitanFamrBuddyButton_SetItemIndexOnShow()
-- DESC : Callback function for the SetItemIndex OnShow event.
-- **************************************************************************
function TitanFamrBuddyButton_SetItemIndexOnShow(self)

  -- Get first position without an item as preferred default value
  local defaultIndex = 1;
  for i = 1, ITEMS_AVAILABLE do
    if TitanGetVar(TITAN_FARM_BUDDY_ID, 'Item' .. tostring(i)) == '' then
      defaultIndex = i;
      break;
    end
  end

  -- Set default value for dialog editbox
  getglobal(self:GetName() .. 'EditBox'):SetText(tostring(defaultIndex));
end

-- **************************************************************************
-- NAME : TitanFamrBuddyButton_SetItemIndexOnAccept()
-- DESC : Callback function for the SetItemIndex OnAccept event.
-- **************************************************************************
function TitanFamrBuddyButton_SetItemIndexOnAccept(self, data)
  local index = tonumber(getglobal(self:GetName() .. 'EditBox'):GetText());
  if TitanFarmBuddy:IsIndexValid(index) == true then
    local text = L['FARM_BUDDY_ITEM_SET_MSG']:gsub('!itemName!', data);
    TitanFarmBuddy:SetItem(index, nil, GetItemInfo(data));
    TitanFarmBuddy:Print(text);
  else
    local text = L['FARM_BUDDY_ITEM_SET_POSITION_MSG']:gsub('!max!', ITEMS_AVAILABLE);
    TitanFarmBuddy:Print(text);
  end
end

-- **************************************************************************
-- NAME : TitanFamrBuddyButton_GetID()
-- DESC : Gets the Titan Plugin ID.
-- **************************************************************************
function TitanFamrBuddyButton_GetID()
  return TITAN_FARM_BUDDY_ID;
end

-- **************************************************************************
-- NAME : TitanFamrBuddyButton_GetAddOnName()
-- DESC : Gets the Titan Plugin AdOn name.
-- **************************************************************************
function TitanFamrBuddyButton_GetAddOnName()
  return ADDON_NAME;
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetConfigOption()
-- DESC : Gets the configuration array for the AceConfig lib.
-- **************************************************************************
function TitanFarmBuddy:GetConfigOption()
	return {
		name = ADDON_NAME,
		handler = TitanFarmBuddy,
    childGroups = 'tab',
		type = 'group',
		args = {
      info_version = {
        type = 'description',
        name = L['FARM_BUDDY_VERSION'] .. ': ' .. ADDON_VERSION,
        order = TitanFarmBuddy:GetOptionOrder('main'),
      },
      info_author = {
        type = 'description',
        name = L['FARM_BUDDY_AUTHOR'] .. ': ' .. GetAddOnMetadata('TitanFarmBuddy', 'Author'),
        order = TitanFarmBuddy:GetOptionOrder('main'),
      },
      tab_general = {
        name = L['FARM_BUDDY_SETTINGS'],
        type = 'group',
        order = TitanFarmBuddy:GetOptionOrder('main'),
        args = {
          item_show_item_icon = {
            type = 'toggle',
            name = L['FARM_BUDDY_SHOW_ICON'],
            desc = L['FARM_BUDDY_SHOW_ICON_DESC'],
            get = 'GetShowItemIcon',
            set = 'SetShowItemIcon',
            width = 'full',
            order = TitanFarmBuddy:GetOptionOrder('general'),
          },
          space_general_1 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('general'),
          },
          item_show_item_name = {
            type = 'toggle',
            name = L['FARM_BUDDY_SHOW_NAME'],
            desc = L['FARM_BUDDY_SHOW_NAME_DESC'],
            get = 'GetShowItemName',
            set = 'SetShowItemName',
            width = 'full',
            order = TitanFarmBuddy:GetOptionOrder('general'),
          },
          space_general_2 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('general'),
          },
          item_show_colored_text = {
            type = 'toggle',
            name = L['FARM_BUDDY_SHOW_COLORED_TEXT'],
            desc = L['FARM_BUDDY_SHOW_COLORED_TEXT_DESC'],
            get = 'GetShowColoredText',
            set = 'SetShowColoredText',
            width = 'full',
            order = TitanFarmBuddy:GetOptionOrder('general'),
          },
          space_general_3 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('general'),
          },
          item_show_goal = {
            type = 'toggle',
            name = L['FARM_BUDDY_SHOW_GOAL'],
            desc = L['FARM_BUDDY_SHOW_GOAL_DESC'],
            get = 'GetShowGoal',
            set = 'SetShowGoal',
            width = 'full',
            order = TitanFarmBuddy:GetOptionOrder('general'),
          },
          space_general_4 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('general'),
          },
          item_track_bank = {
            type = 'toggle',
            name = L['FARM_BUDDY_INCLUDE_BANK'],
            desc = L['FARM_BUDDY_INCLUDE_BANK_DESC'],
            get = 'GetIncludeBank',
            set = 'SetIncludeBank',
            width = 'full',
            order = TitanFarmBuddy:GetOptionOrder('general'),
          },
			  },
			},
      tab_tracking = {
        name = L['FARM_BUDDY_ITEMS'],
        type = 'group',
        order = TitanFarmBuddy:GetOptionOrder('main'),
        args = {
          item_tracking_description = {
            type = 'description',
            name = L['FARM_BUDDY_TRACKING_DESC'],
            order = TitanFarmBuddy:GetOptionOrder('tracking'),
          },
          space_tracking_1 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('tracking'),
          },
          item_track_1 = TitanFarmBuddy:GetTrackedItemField(1),
          item_track_count_1 = TitanFarmBuddy:GetTrackedItemQuantityField(1),
          item_track_show_bar_1 = TitanFarmBuddy:GetTrackedItemShowBarField(1),
          item_clear_button_1 = TitanFarmBuddy:GetTrackedItemClearButton(1),
          space_tracking_2 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('tracking'),
          },
          item_track_2 = TitanFarmBuddy:GetTrackedItemField(2),
          item_track_count_2 = TitanFarmBuddy:GetTrackedItemQuantityField(2),
          item_track_show_bar_2 = TitanFarmBuddy:GetTrackedItemShowBarField(2),
          item_clear_button_2 = TitanFarmBuddy:GetTrackedItemClearButton(2),
          space_tracking_3 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('tracking'),
          },
          item_track_3 = TitanFarmBuddy:GetTrackedItemField(3),
          item_track_count_3 = TitanFarmBuddy:GetTrackedItemQuantityField(3),
          item_track_show_bar_3 = TitanFarmBuddy:GetTrackedItemShowBarField(3),
          item_clear_button_3 = TitanFarmBuddy:GetTrackedItemClearButton(3),
          space_tracking_4 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('tracking'),
          },
          item_track_4 = TitanFarmBuddy:GetTrackedItemField(4),
          item_track_count_4 = TitanFarmBuddy:GetTrackedItemQuantityField(4),
          item_track_show_bar_4 = TitanFarmBuddy:GetTrackedItemShowBarField(4),
          item_clear_button_4 = TitanFarmBuddy:GetTrackedItemClearButton(4),
        }
      },
      tab_notifications = {
        name = L['FARM_BUDDY_NOTIFICATIONS'],
        type = 'group',
        order = TitanFarmBuddy:GetOptionOrder('main'),
        args = {
          item_notification_status = {
            type = 'toggle',
            name = L['FARM_BUDDY_NOTIFICATION'],
            desc = L['FARM_BUDDY_NOTIFICATION_DESC'],
            get = 'GetNotificationStatus',
            set = 'SetNotificationStatus',
            width = 'full',
            order = TitanFarmBuddy:GetOptionOrder('notifications'),
          },
          space_notifications_1 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('notifications'),
          },
          item_notification_display_duration = {
            type = 'input',
            name = L['FARM_BUDDY_PLAY_NOTIFICATION_DISPLAY_DURATION'],
            desc = L['FARM_BUDDY_PLAY_NOTIFICATION_DISPLAY_DURATION_DESC'],
            get = 'GetNotificationDisplayDuration',
            set = 'SetNotificationDisplayDuration',
            validate = 'ValidateNumber',
            width = 'double',
            order = TitanFarmBuddy:GetOptionOrder('notifications'),
          },
          space_notifications_2 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('notifications'),
          },
          item_notification_glow = {
            type = 'toggle',
            name = L['FARM_BUDDY_NOTIFICATION_GLOW'],
            desc = L['FARM_BUDDY_NOTIFICATION_GLOW_DESC'],
            get = 'GetNotificationGlow',
            set = 'SetNotificationGlow',
            width = 'full',
            order = TitanFarmBuddy:GetOptionOrder('notifications'),
          },
          space_notifications_3 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('notifications'),
          },
          item_notification_shine = {
            type = 'toggle',
            name = L['FARM_BUDDY_NOTIFICATION_SHINE'],
            desc = L['FARM_BUDDY_NOTIFICATION_SHINE_DESC'],
            get = 'GetNotificationShine',
            set = 'SetNotificationShine',
            width = 'full',
            order = TitanFarmBuddy:GetOptionOrder('notifications'),
          },
          space_notifications_4 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('notifications'),
          },
          item_play_notification_sound = {
            type = 'toggle',
            name = L['FARM_BUDDY_PLAY_NOTIFICATION_SOUND'],
            desc = L['FARM_BUDDY_PLAY_NOTIFICATION_SOUND_DESC'],
            get = 'GetPlayNotificationSoundStatus',
            set = 'SetPlayNotificationSoundStatus',
            width = 'full',
            order = TitanFarmBuddy:GetOptionOrder('notifications'),
          },
          space_notifications_5 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('notifications'),
          },
          item_notification_sound = {
            type = 'select',
            name = L['TITAN_BUDDY_NOTIFICATION_SOUND'],
            style = 'dropdown',
            values = TitanFarmBuddy_GetSounds(),
            set = 'SetNotificationSound',
            get = 'GetNotificationSound',
            width = 'double',
            order = TitanFarmBuddy:GetOptionOrder('notifications'),
          },
          space_notifications_6 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('notifications'),
          },
          item_move_notification = {
            type = 'execute',
            name = L['FARM_BUDDY_MOVE_NOTIFICATION'],
            desc = L['FARM_BUDDY_MOVE_NOTIFICATION_DESC'],
            func = function() TitanFarmBuddyNotification_ShowAnchor() end,
            width = 'double',
            order = TitanFarmBuddy:GetOptionOrder('notifications'),
          },
        }
      },
      tab_actions = {
        name = L['FARM_BUDDY_ACTIONS'],
        type = 'group',
        order = TitanFarmBuddy:GetOptionOrder('main'),
        args = {
          space_actions_1 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('actions'),
          },
          space_actions_2 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('actions'),
            width = 'half',
          },
          item_test_alert = {
            type = 'execute',
            name = L['FARM_BUDDY_TEST_NOTIFICATION'],
            desc = L['FARM_BUDDY_TEST_NOTIFICATION_DESC'],
            func = 'TestNotification',
            width = 'double',
            order = TitanFarmBuddy:GetOptionOrder('actions'),
          },
          space_actions_3 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('actions'),
          },
          space_actions_4 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('actions'),
            width = 'half',
          },
          item_reset = {
            type = 'execute',
            name = L['FARM_BUDDY_RESET_ALL'],
            desc = L['FARM_BUDDY_RESET_ALL_DESC'],
            func = function() StaticPopup_Show(ADDON_NAME .. 'ResetAllConfirm'); end,
            width = 'double',
            order = TitanFarmBuddy:GetOptionOrder('actions'),
          },
        }
      },
		}
	};
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetTrackedItemField()
-- DESC : A helper function to generate a item input field for the blizzard option panel.
-- **************************************************************************
function TitanFarmBuddy:GetTrackedItemField(index)
  return {
    type = 'input',
    name = L['FARM_BUDDY_ITEM'],
    desc = L['FARM_BUDDY_ITEM_TO_TRACK_DESC'],
    get = function() return TitanFarmBuddy:GetItem(index) end,
    set = function(info, input) TitanFarmBuddy:SetItem(index, info, input) end,
    validate = 'ValidateItem',
    usage = L['FARM_BUDDY_ITEM_TO_TRACK_USAGE'],
    width = 'double',
    order = TitanFarmBuddy:GetOptionOrder('tracking'),
  };
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetTrackedItemQuantityField()
-- DESC : A helper function to generate a item count input field for the blizzard option panel.
-- **************************************************************************
function TitanFarmBuddy:GetTrackedItemQuantityField(index)
  return {
    type = 'input',
    name = L['FARM_BUDDY_QUANTITY'],
    desc = L['FARM_BUDDY_COMMAND_GOAL_DESC'],
    get = function() return TitanFarmBuddy:GetItemQuantity(index) end,
    set = function(info, input) TitanFarmBuddy:SetItemQuantity(index, info, input) end,
    validate = 'ValidateNumber',
    usage = L['FARM_BUDDY_ALERT_COUNT_USAGE'],
    width = 'half',
    order = TitanFarmBuddy:GetOptionOrder('tracking'),
  };
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetTrackedItemShowBarField()
-- DESC : A helper function to generate a item show in Titan bar checkbox for the blizzard option panel.
-- **************************************************************************
function TitanFarmBuddy:GetTrackedItemShowBarField(index)
  return {
    type = 'toggle',
    name = L['FARM_BUDDY_SHOW_IN_BAR'],
    desc = L['FARM_BUDDY_SHOW_IN_BAR_DESC'],
    get = function() return TitanFarmBuddy:GetItemShowInBar(index) end,
    set = function(info, input) TitanFarmBuddy:SetItemShowInBar(index, info, input) end,
    width = 'half',
    order = TitanFarmBuddy:GetOptionOrder('tracking'),
  };
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetTrackedItemClearButton()
-- DESC : A helper function to generate a button for the blizzard option panel to reset the tracked item.
-- **************************************************************************
function TitanFarmBuddy:GetTrackedItemClearButton(index)
  return {
    type = 'execute',
    name = L['FARM_BUDDY_RESET'],
    desc = L['FARM_BUDDY_RESET_DESC'],
    func = function() TitanFarmBuddy:ResetItem(index) end,
    order = TitanFarmBuddy:GetOptionOrder('tracking'),
  };
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetOptionOrder()
-- DESC : A helper function to order the option items in the order as listed in the array.
-- **************************************************************************
function TitanFarmBuddy:GetOptionOrder(category)

  if not OPTION_ORDER.category then
    OPTION_ORDER.category = 0
  end

	OPTION_ORDER.category = OPTION_ORDER.category + 1;
	return OPTION_ORDER.category;
end

-- **************************************************************************
-- NAME : TitanPanelFarmBuddyButton_GetButtonText()
-- DESC : Calculate the item count of the tracked farm item and displays it.
-- **************************************************************************
function TitanPanelFarmBuddyButton_GetButtonText(id)

	local str = '';
	local showIcon = TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowIcon');
  local activeIndex = TitanGetVar(TITAN_FARM_BUDDY_ID, 'ItemShowInBarIndex');
  local item = '';
  if activeIndex > 0 and activeIndex <= ITEMS_AVAILABLE then
    item = TitanGetVar(TITAN_FARM_BUDDY_ID, 'Item' .. tostring(activeIndex));
  end
  local itemInfo = TitanPanelFarmBuddyButton_GetItemInfo(item);

	-- Invalid item or no item defined
	if itemInfo ~= nil then

    local goalValue = tonumber(TitanGetVar(TITAN_FARM_BUDDY_ID, 'ItemQuantity' .. tostring(activeIndex)));
    local showColoredText = TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowColoredText');
    local itemCount = TitanPanelFarmBuddyButton_GetCount(itemInfo);

    if showIcon then
      str = str .. TitanFarmBuddy:GetIconString(itemInfo.IconFileDataID, true);
    end

    str = str .. TitanFarmBuddy:GetBarValue(itemCount, showColoredText);

    if TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowGoal') == true and goalValue > 0 then
      str = str .. ' / ' .. TitanFarmBuddy:GetBarValue(goalValue, showColoredText);
    end

    if TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowLabelText') then
      str = str .. ' ' .. itemInfo.Name;
    end
	else

    if showIcon then
			str = str .. TitanFarmBuddy:GetIconString('Interface\\AddOns\\TitanFarmBuddy\\TitanFarmBuddy', true);
		end

		str = str .. ADDON_NAME;
	end

	return str;
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetIconString()
-- DESC : Gets an icon string.
-- **************************************************************************
function TitanFarmBuddy:GetIconString(icon, space)

	local str = '|T' .. icon .. ':16:16:0:-2|t';

	if space == true then
		str = str .. ' ';
	end

	return str;
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetBarValue()
-- DESC : Gets a value with highlighted color for the Titan Bar.
-- **************************************************************************
function TitanFarmBuddy:GetBarValue(value, colored)
	if colored then
		value = TitanUtils_GetHighlightText(value);
	end
	return value;
end

-- **************************************************************************
-- NAME : TitanPanelFarmBuddyButton_OnClick()
-- DESC : Handles click events to the Titan Button.
-- **************************************************************************
function TitanPanelFarmBuddyButton_OnClick(self, button)

	if (button == 'LeftButton') then
		-- Workarround for opening controls instead of AddOn options
		-- Call it two times to ensure the AddOn panel is opened
		InterfaceOptionsFrame_OpenToCategory(ADDON_NAME);
		InterfaceOptionsFrame_OpenToCategory(ADDON_NAME);
 	end
end

-- **************************************************************************
-- NAME : TitanPanelFarmBuddyButton_GetItemInfo()
-- DESC : Gets information for the given item name.
-- **************************************************************************
function TitanPanelFarmBuddyButton_GetItemInfo(name)

  if name then

    local itemName, itemLink = GetItemInfo(name);

    if itemLink == nil then
      return nil;
    else

      local countBags = GetItemCount(itemLink);
      local countTotal = GetItemCount(itemLink, true);
      local info = {
        Name = itemName,
        Link = itemLink,
        IconFileDataID = GetItemIcon(itemLink),
        CountBags = countBags,
        CountTotal = countTotal,
        CountBank = (countTotal - countBags),
      };

      return info;
    end
  end

  return nil;
end

-- **************************************************************************
-- NAME : TitanPanelFarmBuddyButton_GetTooltipText()
-- DESC : Display tooltip text.
-- **************************************************************************
function TitanPanelFarmBuddyButton_GetTooltipText()

	local str = TitanUtils_GetGreenText(L['FARM_BUDDY_TOOLTIP_DESC']) .. '\n' ..
              TitanUtils_GetGreenText(L['FARM_BUDDY_TOOLTIP_MODIFIER']) .. '\n\n';
  local strTmp = '';
  local itemInfo = TitanPanelFarmBuddyButton_GetItemInfo(TitanGetVar(TITAN_FARM_BUDDY_ID, 'Item'));
  local hasItem = false;

  for i = 1, ITEMS_AVAILABLE do
    local item = TitanGetVar(TITAN_FARM_BUDDY_ID, 'Item' .. tostring(i));

    -- No item set for this index
    if item ~= nil and item ~= '' then
      local itemInfo = TitanPanelFarmBuddyButton_GetItemInfo(item);

      -- Invalid item or no item defined
      if itemInfo ~= nil then
        local goalValue = L['FARM_BUDDY_NO_GOAL'];
    		local goal = tonumber(TitanGetVar(TITAN_FARM_BUDDY_ID, 'ItemQuantity' .. tostring(i)));

    		if goal > 0 then
    			goalValue = goal;
    		end

        strTmp = strTmp .. '\n';
    		strTmp = strTmp .. L['FARM_BUDDY_ITEM'] .. ':\t' .. TitanFarmBuddy:GetIconString(itemInfo.IconFileDataID, true) .. TitanUtils_GetHighlightText(itemInfo.Name) .. '\n';
    		strTmp = strTmp .. L['FARM_BUDDY_INVENTORY'] .. ':\t' .. TitanUtils_GetHighlightText(itemInfo.CountBags) .. '\n';
    		strTmp = strTmp .. L['FARM_BUDDY_BANK'] .. ':\t' .. TitanUtils_GetHighlightText(itemInfo.CountBank) .. '\n';
    		strTmp = strTmp .. L['FARM_BUDDY_TOTAL'] .. ':\t' .. TitanUtils_GetHighlightText(itemInfo.CountTotal) .. '\n';
    		strTmp = strTmp .. L['FARM_BUDDY_ALERT_COUNT'] .. ':\t' .. TitanUtils_GetHighlightText(goalValue) .. '\n';
        hasItem = true;
  		end
    end
  end

  if hasItem == true then
    str = str .. TitanUtils_GetHighlightText(L['FARM_BUDDY_SUMMARY']);
    str = str .. '\n------------------------------------';
    str = str .. strTmp;
  else
    str = str .. L['FARM_BUDDY_NO_ITEM_TRACKED'];
  end

	return str;
end

-- **************************************************************************
-- NAME : TitanPanelRightClickMenu_PrepareFarmBuddyMenu()
-- DESC : Display rightclick menu options
-- **************************************************************************
function TitanPanelRightClickMenu_PrepareFarmBuddyMenu(frame, level, menuList)

	if level == 1 then

		TitanPanelRightClickMenu_AddTitle(TitanPlugins[TITAN_FARM_BUDDY_ID].menuText, level);

		info = {};
		info.notCheckable = true;
		info.text = L['TITAN_PANEL_OPTIONS'];
		info.menuList = 'Options';
		info.hasArrow = 1;
		L_UIDropDownMenu_AddButton(info);

		TitanPanelRightClickMenu_AddSpacer();
		TitanPanelRightClickMenu_AddToggleIcon(TITAN_FARM_BUDDY_ID);
		TitanPanelRightClickMenu_AddToggleLabelText(TITAN_FARM_BUDDY_ID);
		TitanPanelRightClickMenu_AddToggleColoredText(TITAN_FARM_BUDDY_ID);
		TitanPanelRightClickMenu_AddSpacer();
		TitanPanelRightClickMenu_AddCommand(L['FARM_BUDDY_RESET'], TITAN_FARM_BUDDY_ID, 'TitanPanelFarmBuddyButton_ResetConfig');
		TitanPanelRightClickMenu_AddCommand(L['TITAN_PANEL_MENU_HIDE'], TITAN_FARM_BUDDY_ID, TITAN_PANEL_MENU_FUNC_HIDE);

	elseif level == 2 and menuList == 'Options' then

		TitanPanelRightClickMenu_AddTitle(L['TITAN_PANEL_OPTIONS'], level);

		info = {};
		info.text = L['FARM_BUDDY_SHOW_GOAL'];
		info.func = TitanPanelFarmBuddyButton_ToggleShowGoal;
		info.checked = TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowGoal');
		L_UIDropDownMenu_AddButton(info, level);

		info = {};
		info.text = L['FARM_BUDDY_INCLUDE_BANK'];
		info.func = TitanPanelFarmBuddyButton_ToggleIncludeBank;
		info.checked = TitanGetVar(TITAN_FARM_BUDDY_ID, 'IncludeBank');
		L_UIDropDownMenu_AddButton(info, level);

		info = {};
		info.text = L['FARM_BUDDY_NOTIFICATION'];
		info.func = TitanPanelFarmBuddyButton_ToggleGoalNotification;
		info.checked = TitanGetVar(TITAN_FARM_BUDDY_ID, 'GoalNotification');
		L_UIDropDownMenu_AddButton(info, level);

    info = {};
		info.text = L['FARM_BUDDY_PLAY_NOTIFICATION_SOUND'];
		info.func = TitanPanelFarmBuddyButton_TogglePlayNotificationSound;
		info.checked = TitanGetVar(TITAN_FARM_BUDDY_ID, 'PlayNotificationSound');
		L_UIDropDownMenu_AddButton(info, level);
	end
end

-- **************************************************************************
-- NAME : TitanPanelFarmBuddyButton_OnEvent()
-- DESC : Parse events registered to plugin and act on them.
-- **************************************************************************
function TitanPanelFarmBuddyButton_OnEvent(self, event, ...)

  for i = 1, ITEMS_AVAILABLE do
    local item = TitanGetVar(TITAN_FARM_BUDDY_ID, 'Item' .. tostring(i));
    if item ~= nil and item ~= '' then
      local quantity = tonumber(TitanGetVar(TITAN_FARM_BUDDY_ID, 'ItemQuantity' .. tostring(i)));
      if quantity > 0 then
        local itemInfo = TitanPanelFarmBuddyButton_GetItemInfo(item);
        if itemInfo ~= nil then
          local count = TitanPanelFarmBuddyButton_GetCount(itemInfo);
          if count >= quantity then
            TitanFarmBuddy:QueueNotification(i, item, quantity);
          end
        end
      end
    end
  end

	TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID);
end

-- **************************************************************************
-- NAME : TitanPanelFarmBuddyButton_GetCount()
-- DESC : Gets the item count.
-- **************************************************************************
function TitanPanelFarmBuddyButton_GetCount(itemInfo)

  local includeBank = TitanGetVar(TITAN_FARM_BUDDY_ID, 'IncludeBank');
  local count = itemInfo.CountBags;

  if includeBank == 1 or includeBank == true then
    count = itemInfo.CountTotal;
  end

  return count;
end

-- **************************************************************************
-- NAME : TitanPanelFarmBuddyButton_OnShow()
-- DESC : Display button when plugin is visible.
-- **************************************************************************
function TitanPanelFarmBuddyButton_OnShow(self)
	TitanPanelButton_OnShow(self);
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:ValidateItem()
-- DESC : Checks if the entered item name is valid.
-- **************************************************************************
function TitanFarmBuddy:ValidateItem(info, input)

	local _, itemLink = GetItemInfo(input);

	if itemLink ~= nil then
		return true;
	end

	TitanFarmBuddy:Print(L['FARM_BUDDY_ITEM_NOT_EXISTS']);
	return false;
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:ValidateNumber()
-- DESC : Checks if the entered value a valid and positive number.
-- **************************************************************************
function TitanFarmBuddy:ValidateNumber(info, input)

  local number = tonumber(input);
  if not number or number < 0 then
    TitanFarmBuddy:Print(L['FARM_BUDDY_INVALID_NUMBER']);
    return false;
  end

  return true;
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetItem()
-- DESC : Gets the item.
-- **************************************************************************
function TitanFarmBuddy:GetItem(index)
  return TitanGetVar(TITAN_FARM_BUDDY_ID, 'Item' .. tostring(index));
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetItem()
-- DESC : Sets the item.
-- **************************************************************************
function TitanFarmBuddy:SetItem(index, info, input)
  TitanSetVar(TITAN_FARM_BUDDY_ID, 'Item' .. tostring(index), input);
  TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID);
  NOTIFICATION_TRIGGERED[index] = false;
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:ResetItem()
-- DESC : Resets the item with the given index.
-- **************************************************************************
function TitanFarmBuddy:ResetItem(index)
  TitanSetVar(TITAN_FARM_BUDDY_ID, 'Item' .. tostring(index), '');
  TitanSetVar(TITAN_FARM_BUDDY_ID, 'ItemQuantity' .. tostring(index), '0');

  if tostring(TitanGetVar(TITAN_FARM_BUDDY_ID, 'ItemShowInBarIndex')) == tostring(index) then
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'ItemShowInBarIndex', 1);
  end

  TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID);
  NOTIFICATION_TRIGGERED[index] = false;
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetItemQuantity()
-- DESC : Gets the item goal.
-- **************************************************************************
function TitanFarmBuddy:GetItemQuantity(index)
  return tostring(TitanGetVar(TITAN_FARM_BUDDY_ID, 'ItemQuantity' .. tostring(index)));
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetItemQuantity()
-- DESC : Sets the item goal.
-- **************************************************************************
function TitanFarmBuddy:SetItemQuantity(index, info, input)
  TitanSetVar(TITAN_FARM_BUDDY_ID, 'ItemQuantity' .. tostring(index), tonumber(input));
  TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID);
  NOTIFICATION_TRIGGERED[index] = false;
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetItemShowInBar()
-- DESC : Gets the item show in bar status.
-- **************************************************************************
function TitanFarmBuddy:GetItemShowInBar(index)
  if tostring(TitanGetVar(TITAN_FARM_BUDDY_ID, 'ItemShowInBarIndex')) == tostring(index) then
    return true;
  end
  return false;
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetItemShowInBar()
-- DESC : Sets the item show in bar status.
-- **************************************************************************
function TitanFarmBuddy:SetItemShowInBar(index, info, input)
  TitanSetVar(TITAN_FARM_BUDDY_ID, 'ItemShowInBarIndex', index);
  TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID);
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetNotificationStatus()
-- DESC : Sets the notification status.
-- **************************************************************************
function TitanFarmBuddy:SetNotificationStatus(info, input)
  TitanSetVar(TITAN_FARM_BUDDY_ID, 'GoalNotification', input);
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetNotificationStatus()
-- DESC : Gets the notification status.
-- **************************************************************************
function TitanFarmBuddy:GetNotificationStatus()
	return TitanGetVar(TITAN_FARM_BUDDY_ID, 'GoalNotification');
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetPlayNotificationSoundStatus()
-- DESC : Sets the play notification sound status.
-- **************************************************************************
function TitanFarmBuddy:SetPlayNotificationSoundStatus(info, input)
	TitanSetVar(TITAN_FARM_BUDDY_ID, 'PlayNotificationSound', input);
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetPlayNotificationSoundStatus()
-- DESC : Gets the play notification sound status.
-- **************************************************************************
function TitanFarmBuddy:GetPlayNotificationSoundStatus()
	return TitanGetVar(TITAN_FARM_BUDDY_ID, 'PlayNotificationSound');
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetNotificationDisplayDuration()
-- DESC : Sets the notification display duration.
-- **************************************************************************
function TitanFarmBuddy:SetNotificationDisplayDuration(info, input)
	TitanSetVar(TITAN_FARM_BUDDY_ID, 'NotificationDisplayDuration', input);
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetNotificationDisplayDuration()
-- DESC : Gets the notification display duration.
-- **************************************************************************
function TitanFarmBuddy:GetNotificationDisplayDuration()
	return tostring(TitanGetVar(TITAN_FARM_BUDDY_ID, 'NotificationDisplayDuration'));
end

-- **************************************************************************
-- NAME : TitanPanelFarmBuddyButton_TogglePlayNotificationSound()
-- DESC : Sets the play notification sound status.
-- **************************************************************************
function TitanPanelFarmBuddyButton_TogglePlayNotificationSound()
	TitanToggleVar(TITAN_FARM_BUDDY_ID, 'PlayNotificationSound');
	TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID);
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetNotificationSound()
-- DESC : Sets the notification sound.
-- **************************************************************************
function TitanFarmBuddy:SetNotificationSound(info, input)
	TitanSetVar(TITAN_FARM_BUDDY_ID, 'GoalNotificationSound', input);
	PlaySound(input, 'master');
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetNotificationSound()
-- DESC : Gets the notification sound.
-- **************************************************************************
function TitanFarmBuddy:GetNotificationSound()
	return TitanGetVar(TITAN_FARM_BUDDY_ID, 'GoalNotificationSound');
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetNotificationGlow()
-- DESC : Sets the notification glow effect status.
-- **************************************************************************
function TitanFarmBuddy:SetNotificationGlow(info, input)
  TitanSetVar(TITAN_FARM_BUDDY_ID, 'NotificationGlow', input);
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetNotificationGlow()
-- DESC : Gets the notification glow effect status.
-- **************************************************************************
function TitanFarmBuddy:GetNotificationGlow()
  return TitanGetVar(TITAN_FARM_BUDDY_ID, 'NotificationGlow');
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetNotificationShine()
-- DESC : Sets the notification shine effect status.
-- **************************************************************************
function TitanFarmBuddy:SetNotificationShine(info, input)
  TitanSetVar(TITAN_FARM_BUDDY_ID, 'NotificationShine', input);
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetNotificationShine()
-- DESC : Gets the notification shine effect status.
-- **************************************************************************
function TitanFarmBuddy:GetNotificationShine()
  return TitanGetVar(TITAN_FARM_BUDDY_ID, 'NotificationShine');
end

-- **************************************************************************
-- NAME : TitanPanelFarmBuddyButton_ToggleGoalNotification()
-- DESC : Sets the notification status.
-- **************************************************************************
function TitanPanelFarmBuddyButton_ToggleGoalNotification()
	TitanToggleVar(TITAN_FARM_BUDDY_ID, 'GoalNotification');
	TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID);
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetShowItemIcon()
-- DESC : Sets the show item icon status.
-- **************************************************************************
function TitanFarmBuddy:SetShowItemIcon(info, input)
	TitanSetVar(TITAN_FARM_BUDDY_ID, 'ShowIcon', input);
	TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID);
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetShowItemIcon()
-- DESC : Gets the show item icon status.
-- **************************************************************************
function TitanFarmBuddy:GetShowItemIcon()
	return TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowIcon');
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetShowItemName()
-- DESC : Sets the show item name status.
-- **************************************************************************
function TitanFarmBuddy:SetShowItemName(info, input)
	TitanSetVar(TITAN_FARM_BUDDY_ID, 'ShowLabelText', input);
	TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID);
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetShowItemName()
-- DESC : Gets the show item name status.
-- **************************************************************************
function TitanFarmBuddy:GetShowItemName()
	return TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowLabelText');
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetShowColoredText()
-- DESC : Sets the show colored text status.
-- **************************************************************************
function TitanFarmBuddy:SetShowColoredText(info, input)
	TitanSetVar(TITAN_FARM_BUDDY_ID, 'ShowColoredText', input);
	TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID);
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetShowColoredText()
-- DESC : Gets the show colored text status.
-- **************************************************************************
function TitanFarmBuddy:GetShowColoredText()
	return TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowColoredText');
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetShowGoal()
-- DESC : Sets the show goal status.
-- **************************************************************************
function TitanFarmBuddy:SetShowGoal(info, input)
	TitanSetVar(TITAN_FARM_BUDDY_ID, 'ShowGoal', input);
	TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID);
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetShowGoal()
-- DESC : Gets the show goal status.
-- **************************************************************************
function TitanFarmBuddy:GetShowGoal()
	return TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowGoal');
end

-- **************************************************************************
-- NAME : TitanPanelFarmBuddyButton_ToggleShowGoal()
-- DESC : Sets the show goal status.
-- **************************************************************************
function TitanPanelFarmBuddyButton_ToggleShowGoal()
	TitanToggleVar(TITAN_FARM_BUDDY_ID, 'ShowGoal');
	TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID);
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetTrackBank()
-- DESC : Sets the track items in bank status.
-- **************************************************************************
function TitanFarmBuddy:SetIncludeBank(info, input)
	TitanSetVar(TITAN_FARM_BUDDY_ID, 'IncludeBank', input);
	TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID);
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetTrackBank()
-- DESC : Gets the track items in bank status.
-- **************************************************************************
function TitanFarmBuddy:GetIncludeBank()
	return TitanGetVar(TITAN_FARM_BUDDY_ID, 'IncludeBank');
end

-- **************************************************************************
-- NAME : TitanPanelFarmBuddyButton_ToggleIncludeBank()
-- DESC : Sets the track items in bank status.
-- **************************************************************************
function TitanPanelFarmBuddyButton_ToggleIncludeBank()
	TitanToggleVar(TITAN_FARM_BUDDY_ID, 'IncludeBank');
	TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID);
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:ResetConfig()
-- DESC : Resets the saved config to the default values.
-- **************************************************************************
function TitanFarmBuddy:ResetConfig()

	TitanSetVar(TITAN_FARM_BUDDY_ID, 'GoalNotification', true);
	TitanSetVar(TITAN_FARM_BUDDY_ID, 'ShowGoal', true);
	TitanSetVar(TITAN_FARM_BUDDY_ID, 'IncludeBank', false);
	TitanSetVar(TITAN_FARM_BUDDY_ID, 'ShowIcon', true);
	TitanSetVar(TITAN_FARM_BUDDY_ID, 'ShowLabelText', true);
	TitanSetVar(TITAN_FARM_BUDDY_ID, 'ShowColoredText', true);
	TitanSetVar(TITAN_FARM_BUDDY_ID, 'GoalNotificationSound', 'UI_WORLDQUEST_COMPLETE');
	TitanSetVar(TITAN_FARM_BUDDY_ID, 'PlayNotificationSound', true);
	TitanSetVar(TITAN_FARM_BUDDY_ID, 'NotificationDisplayDuration', 5);
	TitanSetVar(TITAN_FARM_BUDDY_ID, 'ItemShowInBarIndex', 1);
	TitanSetVar(TITAN_FARM_BUDDY_ID, 'NotificationGlow', true);
	TitanSetVar(TITAN_FARM_BUDDY_ID, 'NotificationShine', false);

  -- Reset items
  for i = 1, ITEMS_AVAILABLE do
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'Item' .. tostring(i), '');
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'ItemQuantity' .. tostring(i), 0);
    NOTIFICATION_TRIGGERED[i] = false;
  end

	TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID);
end

-- **************************************************************************
-- NAME : TitanPanelFarmBuddyButton_ResetConfig()
-- DESC : Resets the saved config to the default values.
-- **************************************************************************
function TitanPanelFarmBuddyButton_ResetConfig()
	TitanFarmBuddy:ResetConfig();
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:TestNotification()
-- DESC : Raises a test notification.
-- **************************************************************************
function TitanFarmBuddy:TestNotification()
  TitanFarmBuddy:ShowNotification(0, L['FARM_BUDDY_NOTIFICATION_DEMO_ITEM_NAME'], 200, true);
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:ContainerFrameItemButton_OnModifiedClick()
-- DESC : Is called when an item is clicked with modifier key.
-- **************************************************************************
function TitanFarmBuddy:ContainerFrameItemButton_OnModifiedClick(self, button, ...)

  if button == 'RightButton' and IsAltKeyDown() then
    if not CursorHasItem() and not IsControlKeyDown() and not IsShiftKeyDown() then

      local bagID = self:GetParent():GetID();
      local bagSlot = self:GetID();
      local itemLink = GetContainerItemLink(bagID, bagSlot);

      if itemLink ~= nil then

        local dialog = StaticPopup_Show(ADDON_NAME .. 'SetItemIndex', tostring(ITEMS_AVAILABLE));
        if dialog then
          dialog.data = itemLink;
        end
      end
    end
  end
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:QueueNotification()
-- DESC : Queues a notification.
-- **************************************************************************
function TitanFarmBuddy:QueueNotification(index, item, quantity)
  NOTIFICATION_COUNT = NOTIFICATION_COUNT + 1;
  NOTIFICATION_QUEUE[NOTIFICATION_COUNT] = {
    Index = index,
    Item = item,
    Quantity = quantity,
  };
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:ShowNotification()
-- DESC : Raises a notification.
-- **************************************************************************
function TitanFarmBuddy:ShowNotification(index, item, quantity, demo)

  local notificationEnabled = TitanGetVar(TITAN_FARM_BUDDY_ID, 'GoalNotification');
  if (notificationEnabled == true and NOTIFICATION_TRIGGERED[index] == false) or demo == true then

    local playSound = TitanGetVar(TITAN_FARM_BUDDY_ID, 'PlayNotificationSound');
    local notificationDisplayDuration = tonumber(TitanGetVar(TITAN_FARM_BUDDY_ID, 'NotificationDisplayDuration'));
    local notificationGlow = TitanGetVar(TITAN_FARM_BUDDY_ID, 'NotificationGlow');
    local notificationShine = TitanGetVar(TITAN_FARM_BUDDY_ID, 'NotificationShine');
    local sound = nil;

    if demo == true then
      item = L['FARM_BUDDY_NOTIFICATION_DEMO_ITEM_NAME'];
    end

    if playSound == true then
      sound = TitanGetVar(TITAN_FARM_BUDDY_ID, 'GoalNotificationSound');
    end

    if demo == false then
      NOTIFICATION_TRIGGERED[index] = true;
    end

    TitanFarmBuddyNotification_Show(item, quantity, sound, notificationDisplayDuration, notificationGlow, notificationShine);
  end
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:NotificationTask()
-- DESC : Is called by the timer to handle the next notification.
-- **************************************************************************
function TitanFarmBuddy:NotificationTask()
  if TitanFarmBuddyNotification_Shown() == false then
    for index, notification in pairs(NOTIFICATION_QUEUE) do
      TitanFarmBuddy:ShowNotification(notification.Index, notification.Item, notification.Quantity, false);
      NOTIFICATION_QUEUE[index] = nil;
      break;
    end
  end
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:ChatCommand()
-- DESC : Handles AddOn commands.
-- **************************************************************************
function TitanFarmBuddy:ChatCommand(input)

  local cmd, value, arg1 = TitanFarmBuddy:GetArgs(input, 3);

  -- Show help
  if not cmd or cmd == 'help' then

    TitanFarmBuddy:Print(L['FARM_BUDDY_COMMAND_LIST'] .. '\n');
    for command, info in pairs(CHAT_COMMANDS) do
      local helpStr = TitanUtils_GetGreenText('/' .. CHAT_COMMAND) .. ' ' .. TitanUtils_GetRedText(command);
      if info.Args ~= '' then
        helpStr = helpStr .. ' ' .. TitanUtils_GetGoldText(info.Args);
      end
      helpStr = helpStr .. ' - ' .. info.Description;
      print(helpStr);
    end

  -- Prints version information
  elseif cmd == 'version' then
    TitanFarmBuddy:Print(ADDON_VERSION);

  -- Reset AddOn settings
  elseif cmd == 'reset' then
    TitanFarmBuddy:ResetConfig();
    TitanFarmBuddy:Print(L['FARM_BUDDY_CONFIG_RESET_MSG']);

  elseif cmd == 'primary' then

    local index = tonumber(value);

    if TitanFarmBuddy:IsIndexValid(index) == true then
      local text = L['FARM_BUDDY_ITEM_PRIMARY_SET_MSG']:gsub('!position!', tostring(index));
      TitanSetVar(TITAN_FARM_BUDDY_ID, 'ItemShowInBarIndex', index);
      TitanFarmBuddy:Print(text);
      TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID);
    else
      local text = L['FARM_BUDDY_ITEM_SET_POSITION_MSG']:gsub('!max!', ITEMS_AVAILABLE);
      TitanFarmBuddy:Print(text);
    end

  -- Set goal quantity
  elseif cmd == 'quantity' then

    if value ~= nil then
      local status = TitanFarmBuddy:ValidateNumber(nil, arg1);
      if status == true then
        local index = tonumber(value);
        if TitanFarmBuddy:IsIndexValid(index) == true then
          TitanFarmBuddy:SetItemQuantity(index, nil, arg1);
          TitanFarmBuddy:Print(L['FARM_BUDDY_GOAL_SET']);
          TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID);
        else
          local text = L['FARM_BUDDY_ITEM_SET_POSITION_MSG']:gsub('!max!', ITEMS_AVAILABLE);
          TitanFarmBuddy:Print(text);
        end
      end
    else
      TitanFarmBuddy:Print(L['FARM_BUDDY_COMMAND_GOAL_PARAM_MISSING']);
    end

  -- Set tracked item
  elseif cmd == 'track' then

    if value ~= nil then
      local itemInfo = TitanPanelFarmBuddyButton_GetItemInfo(arg1);
      if itemInfo ~= nil then
        local index = tonumber(value);
        if TitanFarmBuddy:IsIndexValid(index) == true then
          TitanFarmBuddy:SetItem(index, nil, itemInfo.Name);
          local text = L['FARM_BUDDY_ITEM_SET_MSG']:gsub('!itemName!', itemInfo.Link);
          TitanFarmBuddy:Print(text);
        else
          local text = L['FARM_BUDDY_ITEM_SET_POSITION_MSG']:gsub('!max!', ITEMS_AVAILABLE);
          TitanFarmBuddy:Print(text);
        end
      else
        TitanFarmBuddy:Print(L['FARM_BUDDY_ITEM_NOT_EXISTS']);
      end
    else
      TitanFarmBuddy:Print(L['FARM_BUDDY_TRACK_ITEM_PARAM_MISSING']);
    end
  end
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:IsIndexValid()
-- DESC : Returns the index status.
-- **************************************************************************
function TitanFarmBuddy:IsIndexValid(index)
  if index ~= nil and index > 0 and index <= ITEMS_AVAILABLE then
    return true;
  end
  return false;
end
