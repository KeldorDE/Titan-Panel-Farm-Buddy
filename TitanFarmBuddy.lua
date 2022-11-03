-- **************************************************************************
-- * TitanFarmBuddy.lua
-- *
-- * By: Keldor
-- **************************************************************************

local TITAN_FARM_BUDDY_ID = 'FarmBuddy';
local ADDON_NAME = 'Titan Farm Buddy';
local L = LibStub('AceLocale-3.0'):GetLocale('Titan', true);
local TitanFarmBuddy = LibStub('AceAddon-3.0'):NewAddon(TITAN_FARM_BUDDY_ID, 'AceConsole-3.0', 'AceHook-3.0', 'AceTimer-3.0', 'AceEvent-3.0');
local ADDON_VERSION = GetAddOnMetadata('TitanFarmBuddy', 'Version');
local OPTION_ORDER = {};
local ITEMS_AVAILABLE = 4;
local ITEM_DISPLAY_STYLES = {};
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
    Args = '<' .. L['FARM_BUDDY_COMMAND_RESET_ARGS'] .. '>',
    Description = L['FARM_BUDDY_COMMAND_RESET_DESC']
  },
  settings = {
    Args = '',
    Description = L['FARM_BUDDY_COMMAND_SETTINGS_DESC']
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

  self:RegisterDialogs();

  for i = 1, ITEMS_AVAILABLE do
    NOTIFICATION_TRIGGERED[i] = false;
  end

  ITEM_DISPLAY_STYLES[1] = L['FARM_BUDDY_ITEM_DISPLAY_STYLE_1'];
  ITEM_DISPLAY_STYLES[2] = L['FARM_BUDDY_ITEM_DISPLAY_STYLE_2'];

  -- Register chat command
  self:RegisterChatCommand(CHAT_COMMAND, 'ChatCommand');

  -- Register events
  self:RegisterEvent('BAG_UPDATE', 'BagUpdate');
end

-- **************************************************************************
-- NAME : TitanFarmBuddy_OnLoad()
-- DESC : Registers the plugin upon it loading.
-- **************************************************************************
function TitanFarmBuddy_OnLoad(self)
	self.registry = {
		id = TITAN_FARM_BUDDY_ID,
		category = 'Information',
		version = TITAN_VERSION,
		menuText = ADDON_NAME,
		buttonTextFunction = 'TitanFarmBuddy_GetButtonText',
		tooltipTitle = ADDON_NAME,
		tooltipTextFunction = 'TitanFarmBuddy_GetTooltipText',
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
      ItemDisplayStyle = 2,
			GoalNotification = true,
			IncludeBank = false,
			ShowQuantity = true,
			GoalNotificationSound = SOUNDKIT.UI_WORLDQUEST_COMPLETE,
			PlayNotificationSound = true,
      NotificationDisplayDuration = 5,
      NotificationGlow = true,
      NotificationShine = true,
      FastTrackingMouseButton = 'RightButton',
      FastTrackingKeys = {
        ctrl = false,
        shift = false,
        alt = true,
      },
		}
	};
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:OnEnable()
-- DESC : Is called when the Plugin gets enabled.
-- **************************************************************************
function TitanFarmBuddy:OnEnable()
  self:SecureHook('HandleModifiedItemClick', 'ModifiedClick');
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
    text = L['TITAN_FARM_BUDDY_CONFIRM_ALL_RESET'],
    button1 = L['TITAN_FARM_BUDDY_YES'],
    button2 = L['TITAN_FARM_BUDDY_NO'],
    OnAccept = function()
      TitanFarmBuddy:ResetConfig(false);
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
  };
  StaticPopupDialogs[ADDON_NAME .. 'ResetAllItemsConfirm'] = {
    text = L['TITAN_FARM_BUDDY_CONFIRM_RESET'],
    button1 = L['TITAN_FARM_BUDDY_YES'],
    button2 = L['TITAN_FARM_BUDDY_NO'],
    OnAccept = function()
      TitanFarmBuddy:ResetConfig(true);
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
    OnShow = TitanFarmBuddy_SetItemIndexOnShow,
    OnAccept = TitanFarmBuddy_SetItemIndexOnAccept,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
  };
end

-- **************************************************************************
-- NAME : TitanFarmBuddy_SetItemIndexOnShow()
-- DESC : Callback function for the SetItemIndex OnShow event.
-- **************************************************************************
function TitanFarmBuddy_SetItemIndexOnShow(self)

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
-- NAME : TitanFarmBuddy_SetItemIndexOnAccept()
-- DESC : Callback function for the SetItemIndex OnAccept event.
-- **************************************************************************
function TitanFarmBuddy_SetItemIndexOnAccept(self, data)
  local index = tonumber(getglobal(self:GetName() .. 'EditBox'):GetText());
  if TitanFarmBuddy:IsIndexValid(index) == true then
    local text = L['FARM_BUDDY_ITEM_SET_MSG']:gsub('!itemName!', data);
    TitanFarmBuddy:SetItem(index, nil, GetItemInfo(data));
    TitanFarmBuddy:Print(text);
    LibStub('AceConfigRegistry-3.0'):NotifyChange(ADDON_NAME);
  else
    local text = L['FARM_BUDDY_ITEM_SET_POSITION_MSG']:gsub('!max!', ITEMS_AVAILABLE);
    TitanFarmBuddy:Print(text);
  end
end

-- **************************************************************************
-- NAME : TitanFarmBuddy_GetID()
-- DESC : Gets the Titan Plugin ID.
-- **************************************************************************
function TitanFarmBuddy_GetID()
  return TITAN_FARM_BUDDY_ID;
end

-- **************************************************************************
-- NAME : TitanFarmBuddy_GetAddOnName()
-- DESC : Gets the Titan Plugin AdOn name.
-- **************************************************************************
function TitanFarmBuddy_GetAddOnName()
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
          general_show_item_icon = {
            type = 'toggle',
            name = L['FARM_BUDDY_SHOW_ICON'],
            desc = L['FARM_BUDDY_SHOW_ICON_DESC'],
            get = 'GetShowItemIcon',
            set = 'SetShowItemIcon',
            width = 'full',
            order = TitanFarmBuddy:GetOptionOrder('general'),
          },
          general_space_1 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('general'),
          },
          general_show_item_name = {
            type = 'toggle',
            name = L['FARM_BUDDY_SHOW_NAME'],
            desc = L['FARM_BUDDY_SHOW_NAME_DESC'],
            get = 'GetShowItemName',
            set = 'SetShowItemName',
            width = 'full',
            order = TitanFarmBuddy:GetOptionOrder('general'),
          },
          general_space_2 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('general'),
          },
          general_show_colored_text = {
            type = 'toggle',
            name = L['FARM_BUDDY_SHOW_COLORED_TEXT'],
            desc = L['FARM_BUDDY_SHOW_COLORED_TEXT_DESC'],
            get = 'GetShowColoredText',
            set = 'SetShowColoredText',
            width = 'full',
            order = TitanFarmBuddy:GetOptionOrder('general'),
          },
          general_space_3 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('general'),
          },
          general_show_goal = {
            type = 'toggle',
            name = L['FARM_BUDDY_SHOW_GOAL'],
            desc = L['FARM_BUDDY_SHOW_GOAL_DESC'],
            get = 'GetShowQuantity',
            set = 'SetShowQuantity',
            width = 'full',
            order = TitanFarmBuddy:GetOptionOrder('general'),
          },
          general_space_4 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('general'),
          },
          general_track_bank = {
            type = 'toggle',
            name = L['FARM_BUDDY_INCLUDE_BANK'],
            desc = L['FARM_BUDDY_INCLUDE_BANK_DESC'],
            get = 'GetIncludeBank',
            set = 'SetIncludeBank',
            width = 'full',
            order = TitanFarmBuddy:GetOptionOrder('general'),
          },
          general_space_5 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('general'),
          },
          general_space_6 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('general'),
          },
          general_display_style = {
            type = 'select',
            style = 'radio',
            name = L['FARM_BUDDY_ITEM_DISPLAY_STYLE'],
            desc = L['FARM_BUDDY_ITEM_DISPLAY_STYLE_DESC'],
            get = 'GetItemDisplayStyle',
            set = 'SetItemDisplayStyle',
            width = 'full',
            values = ITEM_DISPLAY_STYLES,
            order = TitanFarmBuddy:GetOptionOrder('general'),
          },
          general_space_7 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('general'),
          },
          general_shortcuts_heading = {
            type = 'header',
            name = L['FARM_BUDDY_SHORTCUTS'],
            order = TitanFarmBuddy:GetOptionOrder('general'),
          },
          general_fast_tracking_shortcut_mouse_button = {
            type = 'select',
            style = 'radio',
            name = L['FARM_BUDDY_FAST_TRACKING_MOUSE_BUTTON'],
            get = 'GetFastTrackingMouseButton',
            set = 'SetFastTrackingMouseButton',
            width = 'full',
            values = {
              LeftButton = L['FARM_BUDDY_KEY_LEFT_MOUSE_BUTTON'],
              RightButton = L['FARM_BUDDY_KEY_RIGHT_MOUSE_BUTTON'],
            },
            order = TitanFarmBuddy:GetOptionOrder('general'),
          },
          general_space_8 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('general'),
          },
          general_fast_tracking_shortcut_keys = {
            type = 'multiselect',
            name = L['FARM_BUDDY_FAST_TRACKING_SHORTCUTS'],
            desc = L['FARM_BUDDY_FAST_TRACKING_SHORTCUTS_DESC'],
            set = 'SetKeySetting',
            get = 'GetKeySetting',
            values = {
              alt = L['FARM_BUDDY_KEY_ALT'],
              ctrl = L['FARM_BUDDY_KEY_CTRL'],
              shift = L['FARM_BUDDY_KEY_SHIFT'],
            },
            width = 'full',
            order = TitanFarmBuddy:GetOptionOrder('general'),
          },
			  },
			},
      tab_items = {
        name = L['FARM_BUDDY_ITEMS'],
        type = 'group',
        order = TitanFarmBuddy:GetOptionOrder('main'),
        args = {
          items_tracking_description = {
            type = 'description',
            name = L['FARM_BUDDY_TRACKING_DESC'],
            order = TitanFarmBuddy:GetOptionOrder('items'),
          },
          items_space_1 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('items'),
          },
          items_track_1 = TitanFarmBuddy:GetTrackedItemField(1),
          items_track_count_1 = TitanFarmBuddy:GetTrackedItemQuantityField(1),
          items_track_show_bar_1 = TitanFarmBuddy:GetTrackedItemShowBarField(1),
          items_clear_button_1 = TitanFarmBuddy:GetTrackedItemClearButton(1),
          items_space_2 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('items'),
          },
          items_track_2 = TitanFarmBuddy:GetTrackedItemField(2),
          items_track_count_2 = TitanFarmBuddy:GetTrackedItemQuantityField(2),
          items_track_show_bar_2 = TitanFarmBuddy:GetTrackedItemShowBarField(2),
          items_clear_button_2 = TitanFarmBuddy:GetTrackedItemClearButton(2),
          items_space_3 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('items'),
          },
          items_track_3 = TitanFarmBuddy:GetTrackedItemField(3),
          items_track_count_3 = TitanFarmBuddy:GetTrackedItemQuantityField(3),
          items_track_show_bar_3 = TitanFarmBuddy:GetTrackedItemShowBarField(3),
          items_clear_button_3 = TitanFarmBuddy:GetTrackedItemClearButton(3),
          items_space_4 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('items'),
          },
          items_track_4 = TitanFarmBuddy:GetTrackedItemField(4),
          items_track_count_4 = TitanFarmBuddy:GetTrackedItemQuantityField(4),
          items_track_show_bar_4 = TitanFarmBuddy:GetTrackedItemShowBarField(4),
          items_clear_button_4 = TitanFarmBuddy:GetTrackedItemClearButton(4),
        },
      },
      tab_notifications = {
        name = L['FARM_BUDDY_NOTIFICATIONS'],
        type = 'group',
        order = TitanFarmBuddy:GetOptionOrder('main'),
        args = {
          notifications_notification_status = {
            type = 'toggle',
            name = L['FARM_BUDDY_NOTIFICATION'],
            desc = L['FARM_BUDDY_NOTIFICATION_DESC'],
            get = 'GetNotificationStatus',
            set = 'SetNotificationStatus',
            width = 'full',
            order = TitanFarmBuddy:GetOptionOrder('notifications'),
          },
          notifications_space_1 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('notifications'),
          },
          notifications_notification_display_duration = {
            type = 'input',
            name = L['FARM_BUDDY_PLAY_NOTIFICATION_DISPLAY_DURATION'],
            desc = L['FARM_BUDDY_PLAY_NOTIFICATION_DISPLAY_DURATION_DESC'],
            get = 'GetNotificationDisplayDuration',
            set = 'SetNotificationDisplayDuration',
            validate = 'ValidateNumber',
            width = 'double',
            order = TitanFarmBuddy:GetOptionOrder('notifications'),
          },
          notifications_space_2 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('notifications'),
          },
          notifications_notification_glow = {
            type = 'toggle',
            name = L['FARM_BUDDY_NOTIFICATION_GLOW'],
            desc = L['FARM_BUDDY_NOTIFICATION_GLOW_DESC'],
            get = 'GetNotificationGlow',
            set = 'SetNotificationGlow',
            width = 'full',
            order = TitanFarmBuddy:GetOptionOrder('notifications'),
          },
          notifications_space_3 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('notifications'),
          },
          notifications_notification_shine = {
            type = 'toggle',
            name = L['FARM_BUDDY_NOTIFICATION_SHINE'],
            desc = L['FARM_BUDDY_NOTIFICATION_SHINE_DESC'],
            get = 'GetNotificationShine',
            set = 'SetNotificationShine',
            width = 'full',
            order = TitanFarmBuddy:GetOptionOrder('notifications'),
          },
          notifications_space_4 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('notifications'),
          },
          notifications_play_notification_sound = {
            type = 'toggle',
            name = L['FARM_BUDDY_PLAY_NOTIFICATION_SOUND'],
            desc = L['FARM_BUDDY_PLAY_NOTIFICATION_SOUND_DESC'],
            get = 'GetPlayNotificationSoundStatus',
            set = 'SetPlayNotificationSoundStatus',
            width = 'full',
            order = TitanFarmBuddy:GetOptionOrder('notifications'),
          },
          notifications_space_5 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('notifications'),
          },
          notifications_notification_sound = {
            type = 'select',
            name = L['TITAN_BUDDY_NOTIFICATION_SOUND'],
            style = 'dropdown',
            values = TitanFarmBuddy:GetSounds(),
            set = 'SetNotificationSound',
            get = 'GetNotificationSound',
            width = 'double',
            order = TitanFarmBuddy:GetOptionOrder('notifications'),
          },
          notifications_space_6 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('notifications'),
          },
          notifications_move_notification = {
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
          actions_space_1 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('actions'),
          },
          actions_space_2 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('actions'),
            width = 'half',
          },
          actions_test_alert = {
            type = 'execute',
            name = L['FARM_BUDDY_TEST_NOTIFICATION'],
            desc = L['FARM_BUDDY_TEST_NOTIFICATION_DESC'],
            func = 'TestNotification',
            width = 'double',
            order = TitanFarmBuddy:GetOptionOrder('actions'),
          },
          actions_space_3 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('actions'),
          },
          actions_space_4 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('actions'),
            width = 'half',
          },
          actions_reset_items = {
            type = 'execute',
            name = L['FARM_BUDDY_RESET_ALL_ITEMS'],
            desc = L['FARM_BUDDY_RESET_ALL_ITEMS_DESC'],
            func = function() StaticPopup_Show(ADDON_NAME .. 'ResetAllItemsConfirm'); end,
            width = 'double',
            order = TitanFarmBuddy:GetOptionOrder('actions'),
          },
          actions_space_5 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('actions'),
            width = 'full',
          },
          actions_space_6 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('actions'),
            width = 'half',
          },
          actions_reset_all = {
            type = 'execute',
            name = L['FARM_BUDDY_RESET_ALL'],
            desc = L['FARM_BUDDY_RESET_ALL_DESC'],
            func = function() StaticPopup_Show(ADDON_NAME .. 'ResetAllConfirm'); end,
            width = 'double',
            order = TitanFarmBuddy:GetOptionOrder('actions'),
          },
        }
      },
      tab_about = {
        name = L['FARM_BUDDY_ABOUT'],
        type = 'group',
        order = TitanFarmBuddy:GetOptionOrder('about'),
        args = {
          about_space_1 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('about'),
          },
          about_info_version_title = {
            type = 'description',
            name = L['FARM_BUDDY_VERSION'],
            order = TitanFarmBuddy:GetOptionOrder('about'),
            width = 'half',
          },
          about_info_version = {
            type = 'description',
            name = ADDON_VERSION,
            order = TitanFarmBuddy:GetOptionOrder('about'),
            width = 'double',
          },
          about_space_2 = {
            type = 'description',
            name = '',
            order = TitanFarmBuddy:GetOptionOrder('about'),
          },
          about_info_author_title = {
            type = 'description',
            name = L['FARM_BUDDY_AUTHOR'],
            order = TitanFarmBuddy:GetOptionOrder('about'),
            width = 'half',
          },
          about_info_author = {
            type = 'description',
            name = GetAddOnMetadata('TitanFarmBuddy', 'Author'),
            order = TitanFarmBuddy:GetOptionOrder('about'),
            width = 'double',
          },
          about_space_3 = {
            type = 'description',
            name = '\n\n',
            order = TitanFarmBuddy:GetOptionOrder('about'),
          },
          about_info_localization_title = {
            type = 'description',
            fontSize = 'medium',
            name = TitanUtils_GetGoldText(L['FARM_BUDDY_LOCALIZATION']) .. '\n',
            order = TitanFarmBuddy:GetOptionOrder('about'),
            width = 'full',
          },
          about_info_localization_deDE = {
            type = 'description',
            fontSize = 'small',
            name = TitanUtils_GetGreenText(L['FARM_BUDDY_GERMAN']) .. '\n',
            order = TitanFarmBuddy:GetOptionOrder('about'),
            width = 'full',
          },
          about_info_localization_supporters = {
            type = 'description',
            name = '   • Keldor\n\n\n',
            order = TitanFarmBuddy:GetOptionOrder('about'),
            width = 'full',
          },
          about_info_chat_commands_title = {
            type = 'description',
            fontSize = 'medium',
            name = TitanUtils_GetGoldText(L['FARM_BUDDY_CHAT_COMMANDS']) .. '\n',
            order = TitanFarmBuddy:GetOptionOrder('about'),
            width = 'full',
          },
          about_info_chat_commands = {
            type = 'description',
            name = TitanFarmBuddy:GetChatCommandsHelp(false),
            order = TitanFarmBuddy:GetOptionOrder('about'),
            width = 'full',
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
    order = TitanFarmBuddy:GetOptionOrder('items'),
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
    order = TitanFarmBuddy:GetOptionOrder('items'),
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
    order = TitanFarmBuddy:GetOptionOrder('items'),
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
    order = TitanFarmBuddy:GetOptionOrder('items'),
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
-- NAME : TitanFarmBuddy_GetButtonText()
-- DESC : Calculate the item count of the tracked farm item and displays it.
-- **************************************************************************
function TitanFarmBuddy_GetButtonText(id)

	local str = '';
  local items = {};
  local showIcon = TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowIcon');
  local itemDisplayStyle = tonumber(TitanGetVar(TITAN_FARM_BUDDY_ID, 'ItemDisplayStyle'));
  local activeIndex = TitanGetVar(TITAN_FARM_BUDDY_ID, 'ItemShowInBarIndex');

  -- Create item table
  for i = 1, ITEMS_AVAILABLE do
    if (itemDisplayStyle == 1 and activeIndex == i) or (itemDisplayStyle == 2 or itemDisplayStyle == 3) then
      local item = TitanGetVar(TITAN_FARM_BUDDY_ID, 'Item' .. tostring(i));
      if item ~= nil and item ~= '' then
        items[i] = {
          Name = TitanGetVar(TITAN_FARM_BUDDY_ID, 'Item' .. tostring(i)),
          Quantity = tonumber(TitanGetVar(TITAN_FARM_BUDDY_ID, 'ItemQuantity' .. tostring(i))),
        };
      end
    end
  end

  for i, item in pairs(items) do
  	local itemStr = TitanFarmBuddy:GetItemString(item, showIcon);
  	if itemStr ~= nil and itemStr ~= '' then
  		if i > 1 then
  		  str = str .. '   ';
  		end
  		str = str .. itemStr;
  	end
  end

  -- No item found
  if str == '' then
    if showIcon then
			str = str .. TitanFarmBuddy:GetIconString('Interface\\AddOns\\TitanFarmBuddy\\TitanFarmBuddy', true);
		end

		str = str .. ADDON_NAME;
  end

	return str;
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetItemString()
-- DESC : Gets the item strinf to diplay on the Titan Panel button.
-- **************************************************************************
function TitanFarmBuddy:GetItemString(item, showIcon)

  local str = '';
  local itemInfo = TitanFarmBuddy_GetItemInfo(item.Name);

  -- Invalid item or no item defined
  if itemInfo ~= nil then

    local showColoredText = TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowColoredText');
    local itemCount = TitanFarmBuddy_GetCount(itemInfo);

    if showIcon then
      str = str .. TitanFarmBuddy:GetIconString(itemInfo.IconFileDataID, true);
    end

    str = str .. TitanFarmBuddy:GetBarValue(itemCount, showColoredText);

    if TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowQuantity') and item.Quantity > 0 then
      str = str .. ' / ' .. TitanFarmBuddy:GetBarValue(item.Quantity, showColoredText);
    end

    if TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowLabelText') then
      str = str .. ' ' .. itemInfo.Name;
    end
  end

  return str;
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetIconString()
-- DESC : Gets an icon string.
-- **************************************************************************
function TitanFarmBuddy:GetIconString(icon, space)
  local fontSize = TitanPanelGetVar('FontSize') + 6;
	local str = '|T' .. icon .. ':' .. fontSize .. '|t';
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
-- NAME : TitanFarmBuddy_OnClick()
-- DESC : Handles click events to the Titan Button.
-- **************************************************************************
function TitanFarmBuddy_OnClick(self, button)
	if (button == 'LeftButton') then
		-- Workarround for opening controls instead of AddOn options
		-- Call it two times to ensure the AddOn panel is opened
		InterfaceOptionsFrame_OpenToCategory(ADDON_NAME);
		InterfaceOptionsFrame_OpenToCategory(ADDON_NAME);
 	end
end

-- **************************************************************************
-- NAME : TitanFarmBuddy_GetItemInfo()
-- DESC : Gets information for the given item name.
-- **************************************************************************
function TitanFarmBuddy_GetItemInfo(name)

  if name then

    local itemName, itemLink = GetItemInfo(name);

    if itemLink == nil then
      return nil;
    else

      local countBags = GetItemCount(itemLink);
      local countTotal = GetItemCount(itemLink, true);
      local _, itemID = strsplit(':', itemLink);
      local info = {
        ItemID = itemID,
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
-- NAME : TitanFarmBuddy_GetTooltipText()
-- DESC : Display tooltip text.
-- **************************************************************************
function TitanFarmBuddy_GetTooltipText()

	local str = TitanUtils_GetGreenText(L['FARM_BUDDY_TOOLTIP_DESC']) .. '\n' ..
              TitanUtils_GetGreenText(L['FARM_BUDDY_TOOLTIP_MODIFIER']) .. '\n\n';
  local strTmp = '';
  local itemInfo = TitanFarmBuddy_GetItemInfo(TitanGetVar(TITAN_FARM_BUDDY_ID, 'Item'));
  local hasItem = false;

  for i = 1, ITEMS_AVAILABLE do
    local item = TitanGetVar(TITAN_FARM_BUDDY_ID, 'Item' .. tostring(i));

    -- No item set for this index
    if item ~= nil and item ~= '' then
      local itemInfo = TitanFarmBuddy_GetItemInfo(item);

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
    UIDropDownMenu_AddButton(info);

    info = {};
		info.notCheckable = true;
		info.text = L['FARM_BUDDY_NOTIFICATIONS'];
		info.menuList = 'Notifications';
		info.hasArrow = 1;
    UIDropDownMenu_AddButton(info);

    info = {};
		info.notCheckable = true;
		info.text = L['FARM_BUDDY_ACTIONS'];
		info.menuList = 'Actions';
		info.hasArrow = 1;
    UIDropDownMenu_AddButton(info);

		TitanPanelRightClickMenu_AddSpacer();
		TitanPanelRightClickMenu_AddToggleIcon(TITAN_FARM_BUDDY_ID);
		TitanPanelRightClickMenu_AddToggleLabelText(TITAN_FARM_BUDDY_ID);
		TitanPanelRightClickMenu_AddToggleColoredText(TITAN_FARM_BUDDY_ID);
		TitanPanelRightClickMenu_AddSpacer();
		TitanPanelRightClickMenu_AddCommand(L['FARM_BUDDY_RESET'], TITAN_FARM_BUDDY_ID, 'TitanFarmBuddy_ResetConfig');
		TitanPanelRightClickMenu_AddCommand(L['TITAN_PANEL_MENU_HIDE'], TITAN_FARM_BUDDY_ID, TITAN_PANEL_MENU_FUNC_HIDE);

	elseif level == 2 then

    if menuList == 'Options' then

      TitanPanelRightClickMenu_AddTitle(L['TITAN_PANEL_OPTIONS'], level);

  		info = {};
  		info.text = L['FARM_BUDDY_SHOW_GOAL'];
  		info.func = TitanFarmBuddy_ToggleShowQuantity;
  		info.checked = TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowQuantity');
      UIDropDownMenu_AddButton(info, level);

  		info = {};
  		info.text = L['FARM_BUDDY_INCLUDE_BANK'];
  		info.func = TitanFarmBuddy_ToggleIncludeBank;
  		info.checked = TitanGetVar(TITAN_FARM_BUDDY_ID, 'IncludeBank');
      UIDropDownMenu_AddButton(info, level);

    elseif menuList == 'Notifications' then

      info = {};
  		info.text = L['FARM_BUDDY_NOTIFICATION'];
  		info.func = TitanFarmBuddy_ToggleGoalNotification;
  		info.checked = TitanGetVar(TITAN_FARM_BUDDY_ID, 'GoalNotification');
      UIDropDownMenu_AddButton(info, level);

      UIDropDownMenu_AddSeparator(level);

      info = {};
  		info.text = L['FARM_BUDDY_NOTIFICATION_GLOW'];
  		info.func = TitanFarmBuddy_ToggleNotificationGlow;
  		info.checked = TitanGetVar(TITAN_FARM_BUDDY_ID, 'NotificationGlow');
  		UIDropDownMenu_AddButton(info, level);

      info = {};
  		info.text = L['FARM_BUDDY_NOTIFICATION_SHINE'];
  		info.func = TitanFarmBuddy_ToggleNotificationShine;
  		info.checked = TitanGetVar(TITAN_FARM_BUDDY_ID, 'NotificationShine');
  		UIDropDownMenu_AddButton(info, level);

      info = {};
  		info.text = L['FARM_BUDDY_PLAY_NOTIFICATION_SOUND'];
  		info.func = TitanFarmBuddy_TogglePlayNotificationSound;
  		info.checked = TitanGetVar(TITAN_FARM_BUDDY_ID, 'PlayNotificationSound');
  		UIDropDownMenu_AddButton(info, level);

    elseif menuList == 'Actions' then

      info = {};
    	info.notCheckable = true;
    	info.text = L['FARM_BUDDY_TEST_NOTIFICATION'];
    	info.value = 'SettingsCustom';
    	info.func = function() TitanFarmBuddy:TestNotification(); end;
      UIDropDownMenu_AddButton(info, level);

      UIDropDownMenu_AddSeparator(level);

      info = {};
    	info.notCheckable = true;
    	info.text = L['FARM_BUDDY_RESET_ALL_ITEMS'];
    	info.value = '';
    	info.func = function() StaticPopup_Show(ADDON_NAME .. 'ResetAllItemsConfirm'); end;
      UIDropDownMenu_AddButton(info, level);

      info = {};
    	info.notCheckable = true;
    	info.text = L['FARM_BUDDY_RESET_ALL'];
    	info.value = '';
    	info.func = function() StaticPopup_Show(ADDON_NAME .. 'ResetAllConfirm'); end;
      UIDropDownMenu_AddButton(info, level);
    end
	end
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:BagUpdate()
-- DESC : Parse events registered to plugin and act on them.
-- **************************************************************************
function TitanFarmBuddy:BagUpdate()
  for i = 1, ITEMS_AVAILABLE do
    local item = TitanGetVar(TITAN_FARM_BUDDY_ID, 'Item' .. tostring(i));
    if item ~= nil and item ~= '' then
      local quantity = tonumber(TitanGetVar(TITAN_FARM_BUDDY_ID, 'ItemQuantity' .. tostring(i)));
      if quantity > 0 then
        local itemInfo = TitanFarmBuddy_GetItemInfo(item);
        if itemInfo ~= nil then
          local count = TitanFarmBuddy_GetCount(itemInfo);
          if count >= quantity then
            self:QueueNotification(itemInfo.ItemID, item, quantity);
          else
            NOTIFICATION_QUEUE[itemInfo.ItemID] = nil;
            NOTIFICATION_TRIGGERED[itemInfo.ItemID] = false;
          end
        end
      end
    end
  end

	TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID);
end

-- **************************************************************************
-- NAME : TitanFarmBuddy_GetCount()
-- DESC : Gets the item count.
-- **************************************************************************
function TitanFarmBuddy_GetCount(itemInfo)

  local includeBank = TitanGetVar(TITAN_FARM_BUDDY_ID, 'IncludeBank');
  local count = itemInfo.CountBags;

  if includeBank == 1 or includeBank == true then
    count = itemInfo.CountTotal;
  end

  return count;
end

-- **************************************************************************
-- NAME : TitanFarmBuddy_OnShow()
-- DESC : Display button when plugin is visible.
-- **************************************************************************
function TitanFarmBuddy_OnShow(self)

  -- SOUNDKIT Fux for Patch 7.3
  -- Since 7.3 the sound is a number so check if we have a string
  -- from AddON version <= 1.1.6
  local sound = TitanGetVar(TITAN_FARM_BUDDY_ID, 'GoalNotificationSound');
  if sound ~= nil then
    if not tonumber(sound) then
      TitanSetVar(TITAN_FARM_BUDDY_ID, 'GoalNotificationSound', SOUNDKIT.UI_WORLDQUEST_COMPLETE);
    end
  end

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
  LibStub('AceConfigRegistry-3.0'):NotifyChange(ADDON_NAME);
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
  LibStub('AceConfigRegistry-3.0'):NotifyChange(ADDON_NAME);
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
-- NAME : TitanFarmBuddy:SetItemDisplayStyle()
-- DESC : Sets the item display style.
-- **************************************************************************
function TitanFarmBuddy:SetItemDisplayStyle(info, input)
  TitanSetVar(TITAN_FARM_BUDDY_ID, 'ItemDisplayStyle', input);
  TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID);
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetItemDisplayStyle()
-- DESC : Gets the item display style.
-- **************************************************************************
function TitanFarmBuddy:GetItemDisplayStyle()
  return TitanGetVar(TITAN_FARM_BUDDY_ID, 'ItemDisplayStyle');
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetFastTrackingMouseButton()
-- DESC : Sets the fast tracking mouse button.
-- **************************************************************************
function TitanFarmBuddy:SetFastTrackingMouseButton(info, input)
  TitanSetVar(TITAN_FARM_BUDDY_ID, 'FastTrackingMouseButton', input);
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetFastTrackingMouseButton()
-- DESC : Gets the fast tracking mouse button.
-- **************************************************************************
function TitanFarmBuddy:GetFastTrackingMouseButton()
  return TitanGetVar(TITAN_FARM_BUDDY_ID, 'FastTrackingMouseButton');
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetKeySetting()
-- DESC : Sets the fast tracking shortcut key.
-- **************************************************************************
function TitanFarmBuddy:SetKeySetting(info, key, state)

  local options = TitanGetVar(TITAN_FARM_BUDDY_ID, 'FastTrackingKeys');

  if (options[key] ~= nil) then
    options[key] = state;
  end

  TitanSetVar(TITAN_FARM_BUDDY_ID, 'FastTrackingKeys', options);
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetKeySetting()
-- DESC : Gets the fast tracking shortcut key.
-- **************************************************************************
function TitanFarmBuddy:GetKeySetting(info, key)

  local options = TitanGetVar(TITAN_FARM_BUDDY_ID, 'FastTrackingKeys');

  if (options[key] ~= nil) then
    return options[key];
  end

  return false;
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
-- NAME : TitanFarmBuddy_TogglePlayNotificationSound()
-- DESC : Sets the play notification sound status.
-- **************************************************************************
function TitanFarmBuddy_TogglePlayNotificationSound()
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
-- NAME : TitanFarmBuddy_ToggleGoalNotification()
-- DESC : Sets the notification status.
-- **************************************************************************
function TitanFarmBuddy_ToggleGoalNotification()
	TitanToggleVar(TITAN_FARM_BUDDY_ID, 'GoalNotification');
	TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID);
end

-- **************************************************************************
-- NAME : TitanFarmBuddy_ToggleNotificationGlow()
-- DESC : Sets the notification glow effect status.
-- **************************************************************************
function TitanFarmBuddy_ToggleNotificationGlow()
	TitanToggleVar(TITAN_FARM_BUDDY_ID, 'NotificationGlow');
	TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID);
end

-- **************************************************************************
-- NAME : TitanFarmBuddy_ToggleNotificationShine()
-- DESC : Sets the notification shine effect status.
-- **************************************************************************
function TitanFarmBuddy_ToggleNotificationShine()
	TitanToggleVar(TITAN_FARM_BUDDY_ID, 'NotificationShine');
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
-- NAME : TitanFarmBuddy:SetShowQuantity()
-- DESC : Sets the show goal status.
-- **************************************************************************
function TitanFarmBuddy:SetShowQuantity(info, input)
	TitanSetVar(TITAN_FARM_BUDDY_ID, 'ShowQuantity', input);
	TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID);
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetShowQuantity()
-- DESC : Gets the show goal status.
-- **************************************************************************
function TitanFarmBuddy:GetShowQuantity()
	return TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowQuantity');
end

-- **************************************************************************
-- NAME : TitanFarmBuddy_ToggleShowQuantity()
-- DESC : Sets the show goal status.
-- **************************************************************************
function TitanFarmBuddy_ToggleShowQuantity()
	TitanToggleVar(TITAN_FARM_BUDDY_ID, 'ShowQuantity');
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
-- NAME : TitanFarmBuddy_ToggleIncludeBank()
-- DESC : Sets the track items in bank status.
-- **************************************************************************
function TitanFarmBuddy_ToggleIncludeBank()
	TitanToggleVar(TITAN_FARM_BUDDY_ID, 'IncludeBank');
	TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID);
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:ResetConfig()
-- DESC : Resets the saved config to the default values.
-- **************************************************************************
function TitanFarmBuddy:ResetConfig(itemsOnly)

  if itemsOnly == false then
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'GoalNotification', true);
  	TitanSetVar(TITAN_FARM_BUDDY_ID, 'ShowQuantity', true);
  	TitanSetVar(TITAN_FARM_BUDDY_ID, 'IncludeBank', false);
  	TitanSetVar(TITAN_FARM_BUDDY_ID, 'ShowIcon', true);
  	TitanSetVar(TITAN_FARM_BUDDY_ID, 'ShowLabelText', true);
  	TitanSetVar(TITAN_FARM_BUDDY_ID, 'ShowColoredText', true);
  	TitanSetVar(TITAN_FARM_BUDDY_ID, 'GoalNotificationSound', 'UI_WORLDQUEST_COMPLETE');
  	TitanSetVar(TITAN_FARM_BUDDY_ID, 'PlayNotificationSound', true);
  	TitanSetVar(TITAN_FARM_BUDDY_ID, 'NotificationDisplayDuration', 5);
  	TitanSetVar(TITAN_FARM_BUDDY_ID, 'ItemShowInBarIndex', 1);
  	TitanSetVar(TITAN_FARM_BUDDY_ID, 'ItemDisplayStyle', 2);
  	TitanSetVar(TITAN_FARM_BUDDY_ID, 'NotificationGlow', true);
  	TitanSetVar(TITAN_FARM_BUDDY_ID, 'NotificationShine', true);
  	TitanSetVar(TITAN_FARM_BUDDY_ID, 'FastTrackingMouseButton', 'RightButton');
  	TitanSetVar(TITAN_FARM_BUDDY_ID, 'FastTrackingKeys', {
      ctrl = false,
      shift = false,
      alt = true,
    });
  end

  -- Reset items
  for i = 1, ITEMS_AVAILABLE do
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'Item' .. tostring(i), '');
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'ItemQuantity' .. tostring(i), 0);
    NOTIFICATION_TRIGGERED[i] = false;
  end

	TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID);
  LibStub('AceConfigRegistry-3.0'):NotifyChange(ADDON_NAME);
end

-- **************************************************************************
-- NAME : TitanFarmBuddy_ResetConfig()
-- DESC : Resets the saved config to the default values.
-- **************************************************************************
function TitanFarmBuddy_ResetConfig()
	TitanFarmBuddy:ResetConfig(false);
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:TestNotification()
-- DESC : Raises a test notification.
-- **************************************************************************
function TitanFarmBuddy:TestNotification()
  TitanFarmBuddy:ShowNotification(0, L['FARM_BUDDY_NOTIFICATION_DEMO_ITEM_NAME'], 200, true);
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:ModifiedClick()
-- DESC : Is called when an item is clicked with modifier key.
-- **************************************************************************
function TitanFarmBuddy:ModifiedClick(itemLink, itemLocation)

  -- item location is only not nil for bag item clicks
  if itemLocation == nil then
    return;
  end

  local fastTrackingMouseButton = TitanGetVar(TITAN_FARM_BUDDY_ID, 'FastTrackingMouseButton');
  local fastTrackingKeys = TitanGetVar(TITAN_FARM_BUDDY_ID, 'FastTrackingKeys');
  local conditions = false;

  -- Check modifier keys
  for key, state in pairs(fastTrackingKeys) do
    if (key == 'alt') then
      if (state == true) then
        conditions = IsAltKeyDown();
      else
        conditions = not IsAltKeyDown();
      end;

      if (conditions == false) then
        break;
      end;

    elseif (key == 'ctrl') then
      if (state == true) then
        conditions = IsControlKeyDown();
      else
        conditions = not IsControlKeyDown();
      end;

      if (conditions == false) then
        break;
      end

    elseif (key == 'shift') then
      if (state == true) then
        conditions = IsShiftKeyDown();
      else
        conditions = not IsShiftKeyDown();
      end;

      if (conditions == false) then
        break;
      end
    end
  end

  if GetMouseButtonClicked() == fastTrackingMouseButton and not CursorHasItem() and conditions == true then
    if itemLink ~= nil then

      local dialog = StaticPopup_Show(ADDON_NAME .. 'SetItemIndex', tostring(ITEMS_AVAILABLE));
      if dialog then
        dialog.data = itemLink;
      end
    end
  end
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:QueueNotification()
-- DESC : Queues a notification.
-- **************************************************************************
function TitanFarmBuddy:QueueNotification(index, item, quantity)
  NOTIFICATION_QUEUE[index] = {
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

  local triggerStatus = true;
  if (NOTIFICATION_TRIGGERED[index] == nil or NOTIFICATION_TRIGGERED[index] == false) then
    triggerStatus = false;
  end

  local notificationEnabled = TitanGetVar(TITAN_FARM_BUDDY_ID, 'GoalNotification');
  if (notificationEnabled == true and triggerStatus == false) or demo == true then

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
    TitanFarmBuddy:GetChatCommandsHelp(true);

  -- Prints version information
  elseif cmd == 'version' then
    TitanFarmBuddy:Print(ADDON_VERSION);

  -- Reset AddOn settings
  elseif cmd == 'reset' then

    if value == 'all' then
      TitanFarmBuddy:ResetConfig(false);
    else
      TitanFarmBuddy:ResetConfig(true);
    end

    TitanFarmBuddy:Print(L['FARM_BUDDY_CONFIG_RESET_MSG']);

  elseif cmd == 'primary' then

    local index = tonumber(value);

    if TitanFarmBuddy:IsIndexValid(index) == true then
      local text = L['FARM_BUDDY_ITEM_PRIMARY_SET_MSG']:gsub('!position!', tostring(index));
      TitanSetVar(TITAN_FARM_BUDDY_ID, 'ItemShowInBarIndex', index);
      TitanFarmBuddy:Print(text);
      TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID);
      LibStub('AceConfigRegistry-3.0'):NotifyChange(ADDON_NAME);
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
          LibStub('AceConfigRegistry-3.0'):NotifyChange(ADDON_NAME);
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
      local itemInfo = TitanFarmBuddy_GetItemInfo(arg1);
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
  elseif cmd == 'settings' then
    -- Workarround for opening controls instead of AddOn options
		-- Call it two times to ensure the AddOn panel is opened
		InterfaceOptionsFrame_OpenToCategory(ADDON_NAME);
		InterfaceOptionsFrame_OpenToCategory(ADDON_NAME);
  end
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetChatCommandsHelp()
-- DESC : Returns the help text of the chat commands.
-- **************************************************************************
function TitanFarmBuddy:GetChatCommandsHelp(printOut)

  local helpStr = '';

  for command, info in pairs(CHAT_COMMANDS) do
    helpStr = helpStr .. TitanUtils_GetGreenText('/' .. CHAT_COMMAND) .. ' ' .. TitanUtils_GetRedText(command);
    if info.Args ~= '' then
      helpStr = helpStr .. ' ' .. TitanUtils_GetGoldText(info.Args);
    end
    helpStr = helpStr .. ' - ' .. info.Description;
    if printOut then
      print(helpStr);
      helpStr = '';
    else
      helpStr = helpStr .. '\n';
    end
  end

  return helpStr;
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

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetSounds()
-- DESC : Get a list of available sounds.
-- **************************************************************************
function TitanFarmBuddy:GetSounds()

	local sounds = {};

	for k, v in pairs(SOUNDKIT) do
		sounds[v] = k;
	end

	return sounds;
end
