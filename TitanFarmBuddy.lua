-- **************************************************************************
-- * TitanFarmBuddy.lua
-- *
-- * By: Keldor
-- **************************************************************************

local TITAN_FARM_BUDDY_ID = 'FarmBuddy'
local ADDON_NAME = 'Titan Farm Buddy'
local L = LibStub('AceLocale-3.0'):GetLocale('Titan', true)
local TitanFarmBuddy = LibStub('AceAddon-3.0'):NewAddon(TITAN_FARM_BUDDY_ID, 'AceConsole-3.0', 'AceHook-3.0', 'AceTimer-3.0', 'AceEvent-3.0')
local ADDON_VERSION = C_AddOns.GetAddOnMetadata('TitanFarmBuddy', 'Version')
local OPTION_ORDER = {}
local ITEMS_AVAILABLE = 16
local ITEM_DISPLAY_STYLES = {}
local NOTIFICATION_QUEUE = {}
local NOTIFICATION_TRIGGERED = {}
local ADDON_SETTING_PANEL
local ITEM_DATA_INIT_COMPLETE = false
local PLAYER_IN_COMBAT = false
local POPUP_KEY_RESET_ALL_CONFIRM = ADDON_NAME .. 'ResetAllConfirm'
local POPUP_KEY_RESET_ALL_ITEMS_CONFIRM = ADDON_NAME .. 'ResetAllItemsConfirm'
local POPUP_KEY_SET_ITEM_INDEX = ADDON_NAME .. 'SetItemIndex'
local CHAT_COMMAND = 'fb'
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
}
local NOTIFICATION_SOUNDS = {
    [SOUNDKIT.ALARM_CLOCK_WARNING_1]        = L['FARM_BUDDY_SOUND_ALARM_1'],
    [SOUNDKIT.ALARM_CLOCK_WARNING_2]        = L['FARM_BUDDY_SOUND_ALARM_2'],
    [SOUNDKIT.ALARM_CLOCK_WARNING_3]        = L['FARM_BUDDY_SOUND_ALARM_3'],
    [SOUNDKIT.READY_CHECK]                  = L['FARM_BUDDY_SOUND_READY_CHECK'],
    [SOUNDKIT.RAID_WARNING]                 = L['FARM_BUDDY_SOUND_RAID_WARNING'],
    [SOUNDKIT.AUCTION_WINDOW_OPEN]          = L['FARM_BUDDY_SOUND_AUCTION'],
    [SOUNDKIT.IG_QUEST_LIST_COMPLETE]       = L['FARM_BUDDY_SOUND_QUEST_COMPLETE'],
    [SOUNDKIT.LFG_REWARDS]                  = L['FARM_BUDDY_SOUND_DUNGEON_REWARD'],
    [SOUNDKIT.UI_EPICLOOT_TOAST]            = L['FARM_BUDDY_SOUND_EPIC_LOOT'],
    [SOUNDKIT.UI_LEGENDARY_LOOT_TOAST]      = L['FARM_BUDDY_SOUND_LEGENDARY_LOOT'],
}

-- **************************************************************************
-- NAME : TitanFarmBuddy_GetAddOnName()
-- DESC : Gets the Titan Plugin AdOn name.
-- **************************************************************************
function TitanFarmBuddy_GetAddOnName()
    return ADDON_NAME
end


-- **************************************************************************
-- NAME : TitanFarmBuddy_GetAddOnSettingsPanel()
-- DESC : Gets the Titan Plugin AdOn settings panel.
-- **************************************************************************
function TitanFarmBuddy_GetAddOnSettingsPanel()
    return ADDON_SETTING_PANEL
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:OnInitialize()
-- DESC : Is called by AceAddon when the addon is first loaded.
-- **************************************************************************
function TitanFarmBuddy:OnInitialize()
    LibStub('AceConfig-3.0'):RegisterOptionsTable(ADDON_NAME, self:GetConfigOption())
    local _, category = LibStub('AceConfigDialog-3.0'):AddToBlizOptions(ADDON_NAME)
    ADDON_SETTING_PANEL = category

    self:RegisterDialogs()

    ITEM_DISPLAY_STYLES[1] = L['FARM_BUDDY_ITEM_DISPLAY_STYLE_1']
    ITEM_DISPLAY_STYLES[2] = L['FARM_BUDDY_ITEM_DISPLAY_STYLE_2']

    -- Register chat command
    self:RegisterChatCommand(CHAT_COMMAND, 'ChatCommand')

    -- Register events
    self:RegisterEvent('PLAYER_ENTERING_WORLD', 'PlayerEnteringWorld')
    self:RegisterEvent('BAG_UPDATE_DELAYED', 'BagUpdateDelayed')
    self:RegisterEvent('PLAYER_REGEN_DISABLED', 'PlayerRegenDisabled')
    self:RegisterEvent('PLAYER_REGEN_ENABLED', 'PlayerRegenEnabled')
    self:RegisterEvent('PET_BATTLE_OPENING_START', 'PlayerRegenDisabled')
    self:RegisterEvent('PET_BATTLE_CLOSE', 'PlayerRegenEnabled')
end

-- **************************************************************************
-- NAME : TitanFarmBuddy_OnLoad()
-- DESC : Registers the plugin upon it loading.
-- **************************************************************************
function TitanFarmBuddy_OnLoad(button)
    button.registry = {
        id = TITAN_FARM_BUDDY_ID,
        category = 'Information',
        version = TITAN_VERSION,
        menuText = ADDON_NAME,
        buttonTextFunction = function() return TitanFarmBuddy:GetButtonText() end,
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
            ItemShowInBarIndex = 1,
            ItemDisplayStyle = 2,
            GoalNotification = true,
            IncludeBank = false,
            ShowQuantity = true,
            GoalNotificationSound = SOUNDKIT.ALARM_CLOCK_WARNING_3,
            PlayNotificationSound = true,
            NotificationDisplayDuration = 5,
            NotificationGlow = true,
            NotificationShine = true,
            HideNotificationInCombat = false,
            FastTrackingMouseButton = 'RightButton',
            FastTrackingKeys = {
                ctrl = false,
                shift = false,
                alt = true,
            },
        }
    }

    for i = 1, ITEMS_AVAILABLE do
        button.registry.savedVariables['Item' .. i] = ''
        button.registry.savedVariables['ItemQuantity' .. i] = 0
    end
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:OnEnable()
-- DESC : Is called when the Plugin gets enabled.
-- **************************************************************************
function TitanFarmBuddy:OnEnable()
    self:SecureHook('HandleModifiedItemClick', 'ModifiedClick')
    self:ScheduleRepeatingTimer('NotificationTask', 1)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:OnDisable()
-- DESC : Is called when the Plugin gets disabled.
-- **************************************************************************
function TitanFarmBuddy:OnDisable()
    ITEM_DATA_INIT_COMPLETE = false
    self:CancelAllTimers()
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:PlayerEnteringWorld()
-- DESC : Is called when the player enters the world.
-- **************************************************************************
function TitanFarmBuddy:PlayerEnteringWorld()
    self:UnregisterEvent('PLAYER_ENTERING_WORLD')

    -- Delayed data fetching to prevent login timing issues
    C_Timer.After(4, function()
        for i = 1, ITEMS_AVAILABLE do
            local item = TitanGetVar(TITAN_FARM_BUDDY_ID, 'Item' .. i)
            local quantity = tonumber(TitanGetVar(TITAN_FARM_BUDDY_ID, 'ItemQuantity' .. i)) or 0
            local itemInfo = (item and item ~= '') and TitanFarmBuddy_GetItemInfo(item) or nil

            NOTIFICATION_TRIGGERED[i] = itemInfo and quantity > 0 and TitanFarmBuddy_GetCount(itemInfo) >= quantity
        end

        TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
        ITEM_DATA_INIT_COMPLETE = true
    end)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:RegisterDialogs()
-- DESC : Registers the addons dialog boxes.
-- **************************************************************************
function TitanFarmBuddy:RegisterDialogs()

    StaticPopupDialogs[POPUP_KEY_RESET_ALL_CONFIRM] = {
        text = L['TITAN_FARM_BUDDY_CONFIRM_ALL_RESET'],
        button1 = L['TITAN_FARM_BUDDY_YES'],
        button2 = L['TITAN_FARM_BUDDY_NO'],
        OnAccept = function()
            self:ResetConfig(false)
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    StaticPopupDialogs[POPUP_KEY_RESET_ALL_ITEMS_CONFIRM] = {
        text = L['TITAN_FARM_BUDDY_CONFIRM_RESET'],
        button1 = L['TITAN_FARM_BUDDY_YES'],
        button2 = L['TITAN_FARM_BUDDY_NO'],
        OnAccept = function()
            self:ResetConfig(true)
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    StaticPopupDialogs[POPUP_KEY_SET_ITEM_INDEX] = {
        text = L['TITAN_FARM_BUDDY_CHOOSE_ITEM_INDEX'],
        button1 = L['TITAN_FARM_BUDDY_OK'],
        button2 = L['TITAN_FARM_BUDDY_CANCEL'],
        hasEditBox = true,
        OnShow = function(frame)
            self:SetItemIndexOnShow(frame)
        end,
        OnAccept = function(frame, data)
            self:SetItemIndexOnAccept(frame, data)
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetItemIndexOnShow()
-- DESC : Callback function for the SetItemIndex OnShow event.
-- **************************************************************************
function TitanFarmBuddy:SetItemIndexOnShow(frame)

    -- Get first position without an item as preferred default value
    local defaultIndex = 1
    for i = 1, ITEMS_AVAILABLE do
        if TitanGetVar(TITAN_FARM_BUDDY_ID, 'Item' .. i) == '' then
            defaultIndex = i
            break
        end
    end

    -- Set default value for dialog edit box
    _G[frame:GetName() .. 'EditBox']:SetText(defaultIndex)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetItemIndexOnAccept()
-- DESC : Callback function for the SetItemIndex OnAccept event.
-- **************************************************************************
function TitanFarmBuddy:SetItemIndexOnAccept(frame, data)
    local index = tonumber(_G[frame:GetName() .. 'EditBox']:GetText())
    if self:IsIndexValid(index) then
        local text = L['FARM_BUDDY_ITEM_SET_MSG']:gsub('!itemName!', data)
        self:SetItem(index, nil, data)
        self:Print(text)
        LibStub('AceConfigRegistry-3.0'):NotifyChange(ADDON_NAME)
    else
        local text = L['FARM_BUDDY_ITEM_SET_POSITION_MSG']:gsub('!max!', ITEMS_AVAILABLE)
        self:Print(text)
    end
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
                order = self:GetOptionOrder('main'),
            },
            info_author = {
                type = 'description',
                name = L['FARM_BUDDY_AUTHOR'] .. ': ' .. C_AddOns.GetAddOnMetadata('TitanFarmBuddy', 'Author'),
                order = self:GetOptionOrder('main'),
            },
            tab_general = {
                name = L['FARM_BUDDY_SETTINGS'],
                type = 'group',
                order = self:GetOptionOrder('main'),
                args = {
                    general_show_item_icon = {
                        type = 'toggle',
                        name = L['FARM_BUDDY_SHOW_ICON'],
                        desc = L['FARM_BUDDY_SHOW_ICON_DESC'],
                        get = 'GetShowItemIcon',
                        set = 'SetShowItemIcon',
                        width = 'full',
                        order = self:GetOptionOrder('general'),
                    },
                    general_space_1 = {
                        type = 'description',
                        name = '',
                        order = self:GetOptionOrder('general'),
                    },
                    general_show_item_name = {
                        type = 'toggle',
                        name = L['FARM_BUDDY_SHOW_NAME'],
                        desc = L['FARM_BUDDY_SHOW_NAME_DESC'],
                        get = 'GetShowItemName',
                        set = 'SetShowItemName',
                        width = 'full',
                        order = self:GetOptionOrder('general'),
                    },
                    general_space_2 = {
                        type = 'description',
                        name = '',
                        order = self:GetOptionOrder('general'),
                    },
                    general_show_colored_text = {
                        type = 'toggle',
                        name = L['FARM_BUDDY_SHOW_COLORED_TEXT'],
                        desc = L['FARM_BUDDY_SHOW_COLORED_TEXT_DESC'],
                        get = 'GetShowColoredText',
                        set = 'SetShowColoredText',
                        width = 'full',
                        order = self:GetOptionOrder('general'),
                    },
                    general_space_3 = {
                        type = 'description',
                        name = '',
                        order = self:GetOptionOrder('general'),
                    },
                    general_show_goal = {
                        type = 'toggle',
                        name = L['FARM_BUDDY_SHOW_GOAL'],
                        desc = L['FARM_BUDDY_SHOW_GOAL_DESC'],
                        get = 'GetShowQuantity',
                        set = 'SetShowQuantity',
                        width = 'full',
                        order = self:GetOptionOrder('general'),
                    },
                    general_space_s = {
                        type = 'description',
                        name = '',
                        order = self:GetOptionOrder('general'),
                    },
                    general_track_bank = {
                        type = 'toggle',
                        name = L['FARM_BUDDY_INCLUDE_BANK'],
                        desc = L['FARM_BUDDY_INCLUDE_BANK_DESC'],
                        get = 'GetIncludeBank',
                        set = 'SetIncludeBank',
                        width = 'full',
                        order = self:GetOptionOrder('general'),
                    },
                    general_space_5 = {
                        type = 'description',
                        name = '',
                        order = self:GetOptionOrder('general'),
                    },
                    general_space_6 = {
                        type = 'description',
                        name = '',
                        order = self:GetOptionOrder('general'),
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
                        order = self:GetOptionOrder('general'),
                    },
                    general_space_7 = {
                        type = 'description',
                        name = '',
                        order = self:GetOptionOrder('general'),
                    },
                    general_shortcuts_heading = {
                        type = 'header',
                        name = L['FARM_BUDDY_SHORTCUTS'],
                        order = self:GetOptionOrder('general'),
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
                        order = self:GetOptionOrder('general'),
                    },
                    general_space_8 = {
                        type = 'description',
                        name = '',
                        order = self:GetOptionOrder('general'),
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
                        order = self:GetOptionOrder('general'),
                    },
                },
            },
            tab_items = {
                name = L['FARM_BUDDY_ITEMS'],
                type = 'group',
                order = self:GetOptionOrder('main'),
                args = self:GetTrackedItemsArgs(),
            },
            tab_notifications = {
                name = L['FARM_BUDDY_NOTIFICATIONS'],
                type = 'group',
                order = self:GetOptionOrder('main'),
                args = {
                    notifications_notification_status = {
                        type = 'toggle',
                        name = L['FARM_BUDDY_NOTIFICATION'],
                        desc = L['FARM_BUDDY_NOTIFICATION_DESC'],
                        get = 'GetNotificationStatus',
                        set = 'SetNotificationStatus',
                        width = 'full',
                        order = self:GetOptionOrder('notifications'),
                    },
                    notifications_space_1 = {
                        type = 'description',
                        name = '',
                        order = self:GetOptionOrder('notifications'),
                    },
                    notifications_hide_in_combat = {
                        type = 'toggle',
                        name = L['FARM_BUDDY_HIDE_NOTIFICATIONS_IN_COMBAT'],
                        desc = L['FARM_BUDDY_HIDE_NOTIFICATIONS_IN_COMBAT_DESC'],
                        get = 'GetHideNotificationInCombat',
                        set = 'SetHideNotificationInCombat',
                        width = 'full',
                        order = self:GetOptionOrder('notifications'),
                    },
                    notifications_space_2 = {
                        type = 'description',
                        name = '',
                        order = self:GetOptionOrder('notifications'),
                    },
                    notifications_notification_display_duration = {
                        type = 'input',
                        name = L['FARM_BUDDY_PLAY_NOTIFICATION_DISPLAY_DURATION'],
                        desc = L['FARM_BUDDY_PLAY_NOTIFICATION_DISPLAY_DURATION_DESC'],
                        get = 'GetNotificationDisplayDuration',
                        set = 'SetNotificationDisplayDuration',
                        validate = 'ValidateNumber',
                        width = 'double',
                        order = self:GetOptionOrder('notifications'),
                    },
                    notifications_space_3 = {
                        type = 'description',
                        name = '',
                        order = self:GetOptionOrder('notifications'),
                    },
                    notifications_notification_glow = {
                        type = 'toggle',
                        name = L['FARM_BUDDY_NOTIFICATION_GLOW'],
                        desc = L['FARM_BUDDY_NOTIFICATION_GLOW_DESC'],
                        get = 'GetNotificationGlow',
                        set = 'SetNotificationGlow',
                        width = 'full',
                        order = self:GetOptionOrder('notifications'),
                    },
                    notifications_space_4 = {
                        type = 'description',
                        name = '',
                        order = self:GetOptionOrder('notifications'),
                    },
                    notifications_notification_shine = {
                        type = 'toggle',
                        name = L['FARM_BUDDY_NOTIFICATION_SHINE'],
                        desc = L['FARM_BUDDY_NOTIFICATION_SHINE_DESC'],
                        get = 'GetNotificationShine',
                        set = 'SetNotificationShine',
                        width = 'full',
                        order = self:GetOptionOrder('notifications'),
                    },
                    notifications_space_5 = {
                        type = 'description',
                        name = '',
                        order = self:GetOptionOrder('notifications'),
                    },
                    notifications_play_notification_sound = {
                        type = 'toggle',
                        name = L['FARM_BUDDY_PLAY_NOTIFICATION_SOUND'],
                        desc = L['FARM_BUDDY_PLAY_NOTIFICATION_SOUND_DESC'],
                        get = 'GetPlayNotificationSoundStatus',
                        set = 'SetPlayNotificationSoundStatus',
                        width = 'full',
                        order = self:GetOptionOrder('notifications'),
                    },
                    notifications_space_6 = {
                        type = 'description',
                        name = '',
                        order = self:GetOptionOrder('notifications'),
                    },
                    notifications_notification_sound = {
                        type = 'select',
                        name = L['TITAN_BUDDY_NOTIFICATION_SOUND'],
                        style = 'dropdown',
                        values = self:GetNotificationSounds(),
                        sorting = self:GetNotificationSoundsSorting(),
                        set = 'SetNotificationSound',
                        get = 'GetNotificationSound',
                        width = 'double',
                        order = self:GetOptionOrder('notifications'),
                    },
                    notifications_space_7 = {
                        type = 'description',
                        name = '',
                        order = self:GetOptionOrder('notifications'),
                    },
                    notifications_move_notification = {
                        type = 'execute',
                        name = L['FARM_BUDDY_MOVE_NOTIFICATION'],
                        desc = L['FARM_BUDDY_MOVE_NOTIFICATION_DESC'],
                        func = function() TitanFarmBuddyNotification_ShowAnchor() end,
                        width = 'double',
                        order = self:GetOptionOrder('notifications'),
                    },
                }
            },
            tab_actions = {
                name = L['FARM_BUDDY_ACTIONS'],
                type = 'group',
                order = self:GetOptionOrder('main'),
                args = {
                    actions_space_1 = {
                        type = 'description',
                        name = '',
                        order = self:GetOptionOrder('actions'),
                    },
                    actions_space_2 = {
                        type = 'description',
                        name = '',
                        order = self:GetOptionOrder('actions'),
                        width = 'half',
                    },
                    actions_test_alert = {
                        type = 'execute',
                        name = L['FARM_BUDDY_TEST_NOTIFICATION'],
                        desc = L['FARM_BUDDY_TEST_NOTIFICATION_DESC'],
                        func = 'TestNotification',
                        width = 'double',
                        order = self:GetOptionOrder('actions'),
                    },
                    actions_space_3 = {
                        type = 'description',
                        name = '',
                        order = self:GetOptionOrder('actions'),
                    },
                    actions_space_4 = {
                        type = 'description',
                        name = '',
                        order = self:GetOptionOrder('actions'),
                        width = 'half',
                    },
                    actions_reset_items = {
                        type = 'execute',
                        name = L['FARM_BUDDY_RESET_ALL_ITEMS'],
                        desc = L['FARM_BUDDY_RESET_ALL_ITEMS_DESC'],
                        func = function() StaticPopup_Show(POPUP_KEY_RESET_ALL_ITEMS_CONFIRM) end,
                        width = 'double',
                        order = self:GetOptionOrder('actions'),
                    },
                    actions_space_5 = {
                        type = 'description',
                        name = '',
                        order = self:GetOptionOrder('actions'),
                        width = 'full',
                    },
                    actions_space_6 = {
                        type = 'description',
                        name = '',
                        order = self:GetOptionOrder('actions'),
                        width = 'half',
                    },
                    actions_reset_all = {
                        type = 'execute',
                        name = L['FARM_BUDDY_RESET_ALL'],
                        desc = L['FARM_BUDDY_RESET_ALL_DESC'],
                        func = function() StaticPopup_Show(POPUP_KEY_RESET_ALL_CONFIRM) end,
                        width = 'double',
                        order = self:GetOptionOrder('actions'),
                    },
                }
            },
            tab_about = {
                name = L['FARM_BUDDY_ABOUT'],
                type = 'group',
                order = self:GetOptionOrder('main'),
                args = {
                    about_space_1 = {
                        type = 'description',
                        name = '',
                        order = self:GetOptionOrder('about'),
                    },
                    about_info_version_title = {
                        type = 'description',
                        name = L['FARM_BUDDY_VERSION'],
                        order = self:GetOptionOrder('about'),
                        width = 'half',
                    },
                    about_info_version = {
                        type = 'description',
                        name = ADDON_VERSION,
                        order = self:GetOptionOrder('about'),
                        width = 'double',
                    },
                    about_space_2 = {
                        type = 'description',
                        name = '',
                        order = self:GetOptionOrder('about'),
                    },
                    about_info_author_title = {
                        type = 'description',
                        name = L['FARM_BUDDY_AUTHOR'],
                        order = self:GetOptionOrder('about'),
                        width = 'half',
                    },
                    about_info_author = {
                        type = 'description',
                        name = C_AddOns.GetAddOnMetadata('TitanFarmBuddy', 'Author'),
                        order = self:GetOptionOrder('about'),
                        width = 'double',
                    },
                    about_space_3 = {
                        type = 'description',
                        name = '\n\n',
                        order = self:GetOptionOrder('about'),
                    },
                    about_info_localization_title = {
                        type = 'description',
                        fontSize = 'medium',
                        name = TitanUtils_GetGoldText(L['FARM_BUDDY_LOCALIZATION']) .. '\n',
                        order = self:GetOptionOrder('about'),
                        width = 'full',
                    },
                    about_info_localization_deDE = {
                        type = 'description',
                        fontSize = 'small',
                        name = TitanUtils_GetGreenText(L['FARM_BUDDY_GERMAN']) .. '\n',
                        order = self:GetOptionOrder('about'),
                        width = 'full',
                    },
                    about_info_localization_supporters_deDE = {
                        type = 'description',
                        name = '   • Keldor\n\n\n',
                        order = self:GetOptionOrder('about'),
                        width = 'full',
                    },
                    about_info_localization_enUS = {
                        type = 'description',
                        fontSize = 'small',
                        name = TitanUtils_GetGreenText(L['FARM_BUDDY_ENGLISH']) .. '\n',
                        order = self:GetOptionOrder('about'),
                        width = 'full',
                    },
                    about_info_localization_supporters_enUS = {
                        type = 'description',
                        name = '   • Keldor\n\n\n',
                        order = self:GetOptionOrder('about'),
                        width = 'full',
                    },
                    about_info_localization_ruRU = {
                        type = 'description',
                        fontSize = 'small',
                        name = TitanUtils_GetGreenText(L['FARM_BUDDY_RUSSIAN']) .. '\n',
                        order = self:GetOptionOrder('about'),
                        width = 'full',
                    },
                    about_info_localization_supporters_ruRU = {
                        type = 'description',
                        name = '   • ZamestoTV\n\n\n',
                        order = self:GetOptionOrder('about'),
                        width = 'full',
                    },
                    about_info_support_title = {
                        type = 'description',
                        fontSize = 'medium',
                        name = TitanUtils_GetGoldText(L['FARM_BUDDY_SUPPORT']) .. '\n',
                        order = self:GetOptionOrder('about'),
                        width = 'full',
                    },
                    about_info_support_text = {
                        type = 'description',
                        name = '   • ' .. L['FARM_BUDDY_SUPPORT_TEXT'] .. '\n\n\n',
                        order = self:GetOptionOrder('about'),
                        width = 'full',
                    },
                    about_info_chat_commands_title = {
                        type = 'description',
                        fontSize = 'medium',
                        name = TitanUtils_GetGoldText(L['FARM_BUDDY_CHAT_COMMANDS']) .. '\n',
                        order = self:GetOptionOrder('about'),
                        width = 'full',
                    },
                    about_info_chat_commands = {
                        type = 'description',
                        name = self:GetChatCommandsHelp(false),
                        order = self:GetOptionOrder('about'),
                        width = 'full',
                    },
                }
            },
        }
    }
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetTrackedItemsArgs()
-- DESC : Dynamically builds the tracked item option fields based on ITEMS_AVAILABLE.
-- **************************************************************************
function TitanFarmBuddy:GetTrackedItemsArgs()
    local args = {
        items_tracking_description = {
            type = 'description',
            name = L['FARM_BUDDY_TRACKING_DESC'],
            order = self:GetOptionOrder('items'),
        },
    }

    for i = 1, ITEMS_AVAILABLE do
        args['items_space_' .. i] = {
            type = 'description',
            name = '',
            order = self:GetOptionOrder('items'),
        }
        args['items_track_' .. i] = self:GetTrackedItemField(i)
        args['items_track_count_' .. i] = self:GetTrackedItemQuantityField(i)
        args['items_track_show_bar_' .. i] = self:GetTrackedItemShowBarField(i)
        args['items_clear_button_' .. i] = self:GetTrackedItemClearButton(i)
    end

    return args
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
        get = function() return self:GetItem(index) end,
        set = function(info, input) self:SetItem(index, info, input) end,
        validate = 'ValidateItem',
        usage = L['FARM_BUDDY_ITEM_TO_TRACK_USAGE'],
        width = 'double',
        order = self:GetOptionOrder('items'),
    }
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
        get = function() return self:GetItemQuantity(index) end,
        set = function(info, input) self:SetItemQuantity(index, info, input) end,
        validate = 'ValidateNumber',
        usage = L['FARM_BUDDY_ALERT_COUNT_USAGE'],
        width = 'half',
        order = self:GetOptionOrder('items'),
    }
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
        get = function() return self:GetItemShowInBar(index) end,
        set = function(info, input) self:SetItemShowInBar(index, info, input) end,
        width = 'half',
        order = self:GetOptionOrder('items'),
    }
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
        func = function() self:ResetItem(index) end,
        order = self:GetOptionOrder('items'),
    }
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetOptionOrder()
-- DESC : A helper function to order the option items in the order as listed in the array.
-- **************************************************************************
function TitanFarmBuddy:GetOptionOrder(category)
    if not OPTION_ORDER[category] then
        OPTION_ORDER[category] = 0
    end

    OPTION_ORDER[category] = OPTION_ORDER[category] + 1

    return OPTION_ORDER[category]
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetButtonText()
-- DESC : Calculate the item count of the tracked farm item and displays it.
-- **************************************************************************
function TitanFarmBuddy:GetButtonText()

    local str = ''
    local showIcon = TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowIcon')
    local itemDisplayStyle = tonumber(TitanGetVar(TITAN_FARM_BUDDY_ID, 'ItemDisplayStyle'))
    local activeIndex = TitanGetVar(TITAN_FARM_BUDDY_ID, 'ItemShowInBarIndex')

    for i = 1, ITEMS_AVAILABLE do
        if (itemDisplayStyle == 1 and activeIndex == i) or itemDisplayStyle > 1 then
            local item = TitanGetVar(TITAN_FARM_BUDDY_ID, 'Item' .. i)
            if item and item ~= '' then
                local itemStr = self:GetItemString(item, tonumber(TitanGetVar(TITAN_FARM_BUDDY_ID, 'ItemQuantity' .. i)), showIcon)
                if itemStr ~= nil and itemStr ~= '' then
                    if str ~= '' then
                        str = str .. '   '
                    end
                    str = str .. itemStr
                end
            end
        end
    end

    -- No item found
    if str == '' then
        if showIcon then
            str = str .. self:GetIconString('Interface\\AddOns\\TitanFarmBuddy\\TitanFarmBuddy', true)
        end

        str = str .. ADDON_NAME
    end

    return str
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetNameFromItemLink()
-- DESC : Gets the item link without the brackets.
-- **************************************************************************
function TitanFarmBuddy:GetNameFromItemLink(itemLink)
    return (itemLink:gsub("%[(.-)%]", "%1"))
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetItemString()
-- DESC : Gets the item string to display on the Titan Panel button.
-- **************************************************************************
function TitanFarmBuddy:GetItemString(itemName, itemQuantity, showIcon)

    local str = ''
    local itemInfo = TitanFarmBuddy_GetItemInfo(itemName)

    -- Invalid item or no item defined
    if itemInfo then

        local showColoredText = TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowColoredText')
        local itemCount = TitanFarmBuddy_GetCount(itemInfo)

        if showIcon then
            str = str .. self:GetIconString(itemInfo.IconFileDataID, true)
        end

        str = str .. self:GetBarValue(itemCount, showColoredText)

        if TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowQuantity') and itemQuantity > 0 then
            str = str .. ' / ' .. self:GetBarValue(itemQuantity, showColoredText)
        end

        if TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowLabelText') then
            local buttonItemName
            if showColoredText then
                buttonItemName = self:GetNameFromItemLink(itemName)
            else
                buttonItemName = itemInfo.Name
            end

            str = str .. ' ' .. buttonItemName
        end
    end

    return str
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetIconString()
-- DESC : Gets an icon string.
-- **************************************************************************
function TitanFarmBuddy:GetIconString(icon, space)
    local fontSize = TitanPanelGetVar('FontSize') + 6
    local str = '|T' .. icon .. ':' .. fontSize .. '|t'
    if space then
        str = str .. ' '
    end
    return str
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetBarValue()
-- DESC : Gets a value with highlighted color for the Titan Bar.
-- **************************************************************************
function TitanFarmBuddy:GetBarValue(value, colored)
    if colored then
        value = TitanUtils_GetHighlightText(value)
    end
    return value
end

-- **************************************************************************
-- NAME : TitanFarmBuddy_OnClick()
-- DESC : Handles click events to the Titan Button.
-- **************************************************************************
function TitanFarmBuddy_OnClick(_, button)
    if (button == 'LeftButton') then
        Settings.OpenToCategory(ADDON_SETTING_PANEL)
    end
end

-- **************************************************************************
-- NAME : TitanFarmBuddy_GetItemInfo()
-- DESC : Gets information for the given item name.
-- **************************************************************************
function TitanFarmBuddy_GetItemInfo(item)

    if item then
        local itemName, itemLink = C_Item.GetItemInfo(item)
        if itemLink then
            local itemID = C_Item.GetItemIDForItemInfo(item)
            local countBags = C_Item.GetItemCount(itemLink)
            local countTotal = C_Item.GetItemCount(itemLink, true)

            local info = {
                ItemID = itemID,
                Name = itemName,
                Link = itemLink,
                IconFileDataID = C_Item.GetItemIconByID(itemID),
                CountBags = countBags,
                CountTotal = countTotal,
                CountBank = (countTotal - countBags),
            }

            return info
        end
    end

    return nil
end

-- **************************************************************************
-- NAME : TitanFarmBuddy_GetTooltipText()
-- DESC : Display tooltip text.
-- **************************************************************************
function TitanFarmBuddy_GetTooltipText()

    local str = TitanUtils_GetGreenText(L['FARM_BUDDY_TOOLTIP_DESC']) .. '\n' ..
        TitanUtils_GetGreenText(L['FARM_BUDDY_TOOLTIP_MODIFIER']) .. '\n\n'
    local strTmp = ''
    local hasItem = false

    for i = 1, ITEMS_AVAILABLE do
        local item = TitanGetVar(TITAN_FARM_BUDDY_ID, 'Item' .. i)

        -- No item set for this index
        if item and item ~= '' then
            local itemInfo = TitanFarmBuddy_GetItemInfo(item)

            -- Invalid item or no item defined
            if itemInfo then
                local goalValue = L['FARM_BUDDY_NO_GOAL']
                local goal = tonumber(TitanGetVar(TITAN_FARM_BUDDY_ID, 'ItemQuantity' .. i))

                if goal > 0 then
                    goalValue = goal
                end

                strTmp = strTmp .. '\n'
                strTmp = strTmp .. L['FARM_BUDDY_ITEM'] .. ':\t' .. TitanFarmBuddy:GetIconString(itemInfo.IconFileDataID, true) .. TitanUtils_GetHighlightText(itemInfo.Name) .. '\n'
                strTmp = strTmp .. L['FARM_BUDDY_INVENTORY'] .. ':\t' .. TitanUtils_GetHighlightText(itemInfo.CountBags) .. '\n'
                strTmp = strTmp .. L['FARM_BUDDY_BANK'] .. ':\t' .. TitanUtils_GetHighlightText(itemInfo.CountBank) .. '\n'
                strTmp = strTmp .. L['FARM_BUDDY_TOTAL'] .. ':\t' .. TitanUtils_GetHighlightText(itemInfo.CountTotal) .. '\n'
                strTmp = strTmp .. L['FARM_BUDDY_ALERT_COUNT'] .. ':\t' .. TitanUtils_GetHighlightText(goalValue) .. '\n'
                hasItem = true
            end
        end
    end

    if hasItem then
        str = str .. TitanUtils_GetHighlightText(L['FARM_BUDDY_SUMMARY'])
        str = str .. '\n------------------------------------'
        str = str .. strTmp
    else
        str = str .. L['FARM_BUDDY_NO_ITEM_TRACKED']
    end

    return str
end

-- **************************************************************************
-- NAME : TitanPanelRightClickMenu_PrepareFarmBuddyMenu()
-- DESC : Display right click menu options
-- **************************************************************************
function TitanPanelRightClickMenu_PrepareFarmBuddyMenu(_, level, menuList)

    if level == 1 then

        TitanPanelRightClickMenu_AddTitle(TitanPlugins[TITAN_FARM_BUDDY_ID].menuText, level)

        UIDropDownMenu_AddButton({
            text = L['TITAN_PANEL_OPTIONS'],
            menuList = 'Options',
            hasArrow = true,
            notCheckable = true,
        })

        UIDropDownMenu_AddButton({
            text = L['FARM_BUDDY_NOTIFICATIONS'],
            menuList = 'Notifications',
            hasArrow = true,
            notCheckable = true,
        })

        UIDropDownMenu_AddButton({
            text = L['FARM_BUDDY_ACTIONS'],
            menuList = 'Actions',
            hasArrow = true,
            notCheckable = true,
        })

        TitanPanelRightClickMenu_AddSpacer()
        TitanPanelRightClickMenu_AddToggleIcon(TITAN_FARM_BUDDY_ID)
        TitanPanelRightClickMenu_AddToggleLabelText(TITAN_FARM_BUDDY_ID)
        TitanPanelRightClickMenu_AddToggleColoredText(TITAN_FARM_BUDDY_ID)
        TitanPanelRightClickMenu_AddSpacer()
        TitanPanelRightClickMenu_AddCommand(L['FARM_BUDDY_RESET'], TITAN_FARM_BUDDY_ID, 'TitanFarmBuddy_ResetConfig')
        TitanPanelRightClickMenu_AddCommand(L['TITAN_PANEL_MENU_HIDE'], TITAN_FARM_BUDDY_ID, TITAN_PANEL_MENU_FUNC_HIDE)

    elseif level == 2 then

        if menuList == 'Options' then

            TitanPanelRightClickMenu_AddTitle(L['TITAN_PANEL_OPTIONS'], level)

            UIDropDownMenu_AddButton({
                text = L['FARM_BUDDY_SHOW_GOAL'],
                func = TitanFarmBuddy_ToggleShowQuantity,
                checked = TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowQuantity'),
            }, level)

            UIDropDownMenu_AddButton({
                text = L['FARM_BUDDY_INCLUDE_BANK'],
                func = TitanFarmBuddy_ToggleIncludeBank,
                checked = TitanGetVar(TITAN_FARM_BUDDY_ID, 'IncludeBank'),
            }, level)

        elseif menuList == 'Notifications' then

            UIDropDownMenu_AddButton({
                text = L['FARM_BUDDY_NOTIFICATION'],
                func = TitanFarmBuddy_ToggleGoalNotification,
                checked = TitanGetVar(TITAN_FARM_BUDDY_ID, 'GoalNotification'),
            }, level)

            UIDropDownMenu_AddSeparator(level)

            UIDropDownMenu_AddButton({
                text = L['FARM_BUDDY_NOTIFICATION_GLOW'],
                func = TitanFarmBuddy_ToggleNotificationGlow,
                checked = TitanGetVar(TITAN_FARM_BUDDY_ID, 'NotificationGlow'),
            }, level)

            UIDropDownMenu_AddButton({
                text = L['FARM_BUDDY_NOTIFICATION_SHINE'],
                func = TitanFarmBuddy_ToggleNotificationShine,
                checked = TitanGetVar(TITAN_FARM_BUDDY_ID, 'NotificationShine'),
            }, level)

            UIDropDownMenu_AddButton({
                text = L['FARM_BUDDY_PLAY_NOTIFICATION_SOUND'],
                func = TitanFarmBuddy_TogglePlayNotificationSound,
                checked = TitanGetVar(TITAN_FARM_BUDDY_ID, 'PlayNotificationSound'),
            }, level)

        elseif menuList == 'Actions' then

            UIDropDownMenu_AddButton({
                text = L['FARM_BUDDY_TEST_NOTIFICATION'],
                value = 'SettingsCustom',
                notCheckable = true,
                func = function() TitanFarmBuddy:TestNotification() end,
            }, level)

            UIDropDownMenu_AddSeparator(level)

            UIDropDownMenu_AddButton({
                text = L['FARM_BUDDY_RESET_ALL_ITEMS'],
                value = '',
                notCheckable = true,
                func = function() StaticPopup_Show(POPUP_KEY_RESET_ALL_ITEMS_CONFIRM) end,
            }, level)

            UIDropDownMenu_AddButton({
                text = L['FARM_BUDDY_RESET_ALL'],
                value = '',
                notCheckable = true,
                func = function() StaticPopup_Show(POPUP_KEY_RESET_ALL_CONFIRM) end,
            }, level)
        end
    end
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:BagUpdateDelayed()
-- DESC : Checks if the item count has reached the goal and triggers a notification if it has.
-- **************************************************************************
function TitanFarmBuddy:BagUpdateDelayed()

    if not ITEM_DATA_INIT_COMPLETE then
        return
    end

    for i = 1, ITEMS_AVAILABLE do
        local trackedItem = TitanGetVar(TITAN_FARM_BUDDY_ID, 'Item' .. i)
        local quantity = tonumber(TitanGetVar(TITAN_FARM_BUDDY_ID, 'ItemQuantity' .. i))

        if trackedItem and trackedItem ~= '' and quantity and quantity > 0 then
            local itemInfo = TitanFarmBuddy_GetItemInfo(trackedItem)
            if itemInfo then
                if TitanFarmBuddy_GetCount(itemInfo) >= quantity then
                    self:QueueNotification(i, itemInfo.Name, itemInfo.IconFileDataID, quantity)
                else
                    NOTIFICATION_QUEUE[i] = nil
                end
            end
        end
    end

    TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
end

-- **************************************************************************
-- NAME : FarmBuddy:PlayerRegenDisabled()
-- DESC : Fires when the player enters combat.
-- **************************************************************************
function TitanFarmBuddy:PlayerRegenDisabled()
    PLAYER_IN_COMBAT = true
end

-- **************************************************************************
-- NAME : FarmBuddy:PlayerRegenDisabled()
-- DESC : Fires if the player leaves combat.
-- **************************************************************************
function TitanFarmBuddy:PlayerRegenEnabled()
    PLAYER_IN_COMBAT = false
end

-- **************************************************************************
-- NAME : TitanFarmBuddy_GetCount()
-- DESC : Gets the item count.
-- **************************************************************************
function TitanFarmBuddy_GetCount(itemInfo)

    local includeBank = TitanGetVar(TITAN_FARM_BUDDY_ID, 'IncludeBank')
    local count = itemInfo.CountBags

    if includeBank then
        count = itemInfo.CountTotal
    end

    return count
end

-- **************************************************************************
-- NAME : TitanFarmBuddy_OnShow()
-- DESC : Display button when plugin is visible.
-- **************************************************************************
function TitanFarmBuddy_OnShow(self)
    local sound = TitanGetVar(TITAN_FARM_BUDDY_ID, 'GoalNotificationSound')
    if sound then
        if not tonumber(sound) then
            TitanSetVar(TITAN_FARM_BUDDY_ID, 'GoalNotificationSound', SOUNDKIT.ALARM_CLOCK_WARNING_3)
        end
    end

    TitanPanelButton_OnShow(self)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:ValidateItem()
-- DESC : Checks if the entered item name is valid.
-- **************************************************************************
function TitanFarmBuddy:ValidateItem(_, input)

    local _, itemLink = C_Item.GetItemInfo(input)

    if itemLink then
        return true
    end

    self:Print(L['FARM_BUDDY_ITEM_NOT_EXISTS'])
    return false
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:ValidateNumber()
-- DESC : Checks if the entered value a valid and positive number.
-- **************************************************************************
function TitanFarmBuddy:ValidateNumber(_, input)

    local number = tonumber(input)
    if not number or number < 0 then
        self:Print(L['FARM_BUDDY_INVALID_NUMBER'])
        return false
    end

    return true
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetItem()
-- DESC : Gets the item.
-- **************************************************************************
function TitanFarmBuddy:GetItem(index)
    return TitanGetVar(TITAN_FARM_BUDDY_ID, 'Item' .. index)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetItemLink()
-- DESC : Resolves the given input to an item link. If the input is already an
--        item link it is returned unchanged, otherwise it is treated as an
--        item id or item name and converted into an item link.
-- **************************************************************************
function TitanFarmBuddy:GetItemLink(input)
    if not input or input == '' then
        return nil
    end

    -- Input is already an item link
    if type(input) == 'string' and input:find('|Hitem:') then
        return input
    end

    -- Input is an item id or item name, resolve it to an item link
    local _, itemLink = C_Item.GetItemInfo(input)
    return itemLink
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetItem()
-- DESC : Sets the item.
-- **************************************************************************
function TitanFarmBuddy:SetItem(index, _, input)
    local itemLink = self:GetItemLink(input)

    TitanSetVar(TITAN_FARM_BUDDY_ID, 'Item' .. index, itemLink or input)
    TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
    NOTIFICATION_TRIGGERED[index] = false
    LibStub('AceConfigRegistry-3.0'):NotifyChange(ADDON_NAME)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:ResetItem()
-- DESC : Resets the item with the given index.
-- **************************************************************************
function TitanFarmBuddy:ResetItem(index)
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'Item' .. index, '')
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'ItemQuantity' .. index, '0')

    if TitanGetVar(TITAN_FARM_BUDDY_ID, 'ItemShowInBarIndex') == index then
        TitanSetVar(TITAN_FARM_BUDDY_ID, 'ItemShowInBarIndex', 1)
    end

    TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
    NOTIFICATION_TRIGGERED[index] = false
    LibStub('AceConfigRegistry-3.0'):NotifyChange(ADDON_NAME)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetItemQuantity()
-- DESC : Gets the item goal.
-- **************************************************************************
function TitanFarmBuddy:GetItemQuantity(index)
    return tostring(TitanGetVar(TITAN_FARM_BUDDY_ID, 'ItemQuantity' .. index))
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetItemQuantity()
-- DESC : Sets the item goal.
-- **************************************************************************
function TitanFarmBuddy:SetItemQuantity(index, _, input)
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'ItemQuantity' .. index, tonumber(input))
    TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
    NOTIFICATION_TRIGGERED[index] = false
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetItemShowInBar()
-- DESC : Gets the item show in bar status.
-- **************************************************************************
function TitanFarmBuddy:GetItemShowInBar(index)
    return TitanGetVar(TITAN_FARM_BUDDY_ID, 'ItemShowInBarIndex') == index
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetItemShowInBar()
-- DESC : Sets the item show in bar status.
-- **************************************************************************
function TitanFarmBuddy:SetItemShowInBar(index)
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'ItemShowInBarIndex', index)
    TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetNotificationStatus()
-- DESC : Sets the notification status.
-- **************************************************************************
function TitanFarmBuddy:SetNotificationStatus(_, input)
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
-- NAME : TitanFarmBuddy:SetItemDisplayStyle()
-- DESC : Sets the item display style.
-- **************************************************************************
function TitanFarmBuddy:SetItemDisplayStyle(_, input)
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'ItemDisplayStyle', input)
    TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetItemDisplayStyle()
-- DESC : Gets the item display style.
-- **************************************************************************
function TitanFarmBuddy:GetItemDisplayStyle()
    return TitanGetVar(TITAN_FARM_BUDDY_ID, 'ItemDisplayStyle')
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetFastTrackingMouseButton()
-- DESC : Sets the fast tracking mouse button.
-- **************************************************************************
function TitanFarmBuddy:SetFastTrackingMouseButton(_, input)
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'FastTrackingMouseButton', input)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetFastTrackingMouseButton()
-- DESC : Gets the fast tracking mouse button.
-- **************************************************************************
function TitanFarmBuddy:GetFastTrackingMouseButton()
    return TitanGetVar(TITAN_FARM_BUDDY_ID, 'FastTrackingMouseButton')
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetKeySetting()
-- DESC : Sets the fast tracking shortcut key.
-- **************************************************************************
function TitanFarmBuddy:SetKeySetting(_, key, state)

    local options = TitanGetVar(TITAN_FARM_BUDDY_ID, 'FastTrackingKeys')

    if (options[key]) then
        options[key] = state
    end

    TitanSetVar(TITAN_FARM_BUDDY_ID, 'FastTrackingKeys', options)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetKeySetting()
-- DESC : Gets the fast tracking shortcut key.
-- **************************************************************************
function TitanFarmBuddy:GetKeySetting(_, key)

    local options = TitanGetVar(TITAN_FARM_BUDDY_ID, 'FastTrackingKeys')

    if (options[key]) then
        return options[key]
    end

    return false
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetPlayNotificationSoundStatus()
-- DESC : Sets the play notification sound status.
-- **************************************************************************
function TitanFarmBuddy:SetPlayNotificationSoundStatus(_, input)
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'PlayNotificationSound', input)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetPlayNotificationSoundStatus()
-- DESC : Gets the play notification sound status.
-- **************************************************************************
function TitanFarmBuddy:GetPlayNotificationSoundStatus()
    return TitanGetVar(TITAN_FARM_BUDDY_ID, 'PlayNotificationSound')
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetNotificationDisplayDuration()
-- DESC : Sets the notification display duration.
-- **************************************************************************
function TitanFarmBuddy:SetNotificationDisplayDuration(_, input)
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'NotificationDisplayDuration', input)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetNotificationDisplayDuration()
-- DESC : Gets the notification display duration.
-- **************************************************************************
function TitanFarmBuddy:GetNotificationDisplayDuration()
    return tostring(TitanGetVar(TITAN_FARM_BUDDY_ID, 'NotificationDisplayDuration'))
end

-- **************************************************************************
-- NAME : TitanFarmBuddy_TogglePlayNotificationSound()
-- DESC : Sets the play notification sound status.
-- **************************************************************************
function TitanFarmBuddy_TogglePlayNotificationSound()
    TitanToggleVar(TITAN_FARM_BUDDY_ID, 'PlayNotificationSound')
    TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetNotificationSound()
-- DESC : Sets the notification sound.
-- **************************************************************************
function TitanFarmBuddy:SetNotificationSound(_, input)
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'GoalNotificationSound', input)
    PlaySound(input, 'master')
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetNotificationSound()
-- DESC : Gets the notification sound.
-- **************************************************************************
function TitanFarmBuddy:GetNotificationSound()
    local sound = TitanGetVar(TITAN_FARM_BUDDY_ID, 'GoalNotificationSound')
    if not sound or NOTIFICATION_SOUNDS[sound] == nil then
        return SOUNDKIT.ALARM_CLOCK_WARNING_3
    end

    return sound
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetNotificationGlow()
-- DESC : Sets the notification glow effect status.
-- **************************************************************************
function TitanFarmBuddy:SetNotificationGlow(_, input)
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'NotificationGlow', input)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetNotificationGlow()
-- DESC : Gets the notification glow effect status.
-- **************************************************************************
function TitanFarmBuddy:GetNotificationGlow()
    return TitanGetVar(TITAN_FARM_BUDDY_ID, 'NotificationGlow')
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetNotificationShine()
-- DESC : Sets the notification shine effect status.
-- **************************************************************************
function TitanFarmBuddy:SetNotificationShine(_, input)
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'NotificationShine', input)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetNotificationShine()
-- DESC : Gets the notification shine effect status.
-- **************************************************************************
function TitanFarmBuddy:GetNotificationShine()
    return TitanGetVar(TITAN_FARM_BUDDY_ID, 'NotificationShine')
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetHideNotificationInCombat()
-- DESC : Sets the hide notification in combat status.
-- **************************************************************************
function TitanFarmBuddy:SetHideNotificationInCombat(_, input)
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'HideNotificationInCombat', input)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetHideNotificationInCombat()
-- DESC : Gets the hide notification in combat status.
-- **************************************************************************
function TitanFarmBuddy:GetHideNotificationInCombat()
    return TitanGetVar(TITAN_FARM_BUDDY_ID, 'HideNotificationInCombat')
end

-- **************************************************************************
-- NAME : TitanFarmBuddy_ToggleGoalNotification()
-- DESC : Sets the notification status.
-- **************************************************************************
function TitanFarmBuddy_ToggleGoalNotification()
    TitanToggleVar(TITAN_FARM_BUDDY_ID, 'GoalNotification')
    TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy_ToggleNotificationGlow()
-- DESC : Sets the notification glow effect status.
-- **************************************************************************
function TitanFarmBuddy_ToggleNotificationGlow()
    TitanToggleVar(TITAN_FARM_BUDDY_ID, 'NotificationGlow')
    TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy_ToggleNotificationShine()
-- DESC : Sets the notification shine effect status.
-- **************************************************************************
function TitanFarmBuddy_ToggleNotificationShine()
    TitanToggleVar(TITAN_FARM_BUDDY_ID, 'NotificationShine')
    TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetShowItemIcon()
-- DESC : Sets the show item icon status.
-- **************************************************************************
function TitanFarmBuddy:SetShowItemIcon(_, input)
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'ShowIcon', input)
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
function TitanFarmBuddy:SetShowItemName(_, input)
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'ShowLabelText', input)
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
function TitanFarmBuddy:SetShowColoredText(_, input)
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'ShowColoredText', input)
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
-- NAME : TitanFarmBuddy:SetShowQuantity()
-- DESC : Sets the show goal status.
-- **************************************************************************
function TitanFarmBuddy:SetShowQuantity(_, input)
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'ShowQuantity', input)
    TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetShowQuantity()
-- DESC : Gets the show goal status.
-- **************************************************************************
function TitanFarmBuddy:GetShowQuantity()
    return TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowQuantity')
end

-- **************************************************************************
-- NAME : TitanFarmBuddy_ToggleShowQuantity()
-- DESC : Sets the show goal status.
-- **************************************************************************
function TitanFarmBuddy_ToggleShowQuantity()
    TitanToggleVar(TITAN_FARM_BUDDY_ID, 'ShowQuantity')
    TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:SetTrackBank()
-- DESC : Sets the track items in bank status.
-- **************************************************************************
function TitanFarmBuddy:SetIncludeBank(_, input)
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
-- NAME : TitanFarmBuddy_ToggleIncludeBank()
-- DESC : Sets the track items in bank status.
-- **************************************************************************
function TitanFarmBuddy_ToggleIncludeBank()
    TitanToggleVar(TITAN_FARM_BUDDY_ID, 'IncludeBank')
    TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:ResetConfig()
-- DESC : Resets the saved config to the default values.
-- **************************************************************************
function TitanFarmBuddy:ResetConfig(itemsOnly)

    if not itemsOnly then
        TitanSetVar(TITAN_FARM_BUDDY_ID, 'GoalNotification', true)
        TitanSetVar(TITAN_FARM_BUDDY_ID, 'ShowQuantity', true)
        TitanSetVar(TITAN_FARM_BUDDY_ID, 'IncludeBank', false)
        TitanSetVar(TITAN_FARM_BUDDY_ID, 'ShowIcon', true)
        TitanSetVar(TITAN_FARM_BUDDY_ID, 'ShowLabelText', true)
        TitanSetVar(TITAN_FARM_BUDDY_ID, 'ShowColoredText', true)
        TitanSetVar(TITAN_FARM_BUDDY_ID, 'GoalNotificationSound', 'ALARM_CLOCK_WARNING_3')
        TitanSetVar(TITAN_FARM_BUDDY_ID, 'PlayNotificationSound', true)
        TitanSetVar(TITAN_FARM_BUDDY_ID, 'NotificationDisplayDuration', 5)
        TitanSetVar(TITAN_FARM_BUDDY_ID, 'ItemShowInBarIndex', 1)
        TitanSetVar(TITAN_FARM_BUDDY_ID, 'ItemDisplayStyle', 2)
        TitanSetVar(TITAN_FARM_BUDDY_ID, 'NotificationGlow', true)
        TitanSetVar(TITAN_FARM_BUDDY_ID, 'NotificationShine', true)
        TitanSetVar(TITAN_FARM_BUDDY_ID, 'HideNotificationInCombat', false)
        TitanSetVar(TITAN_FARM_BUDDY_ID, 'FastTrackingMouseButton', 'RightButton')
        TitanSetVar(TITAN_FARM_BUDDY_ID, 'FastTrackingKeys', {
            ctrl = false,
            shift = false,
            alt = true,
        })
    end

    -- Reset items
    for i = 1, ITEMS_AVAILABLE do
        TitanSetVar(TITAN_FARM_BUDDY_ID, 'Item' .. i, '')
        TitanSetVar(TITAN_FARM_BUDDY_ID, 'ItemQuantity' .. i, 0)
        NOTIFICATION_TRIGGERED[i] = false
    end

    TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
    LibStub('AceConfigRegistry-3.0'):NotifyChange(ADDON_NAME)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy_ResetConfig()
-- DESC : Resets the saved config to the default values.
-- **************************************************************************
function TitanFarmBuddy_ResetConfig()
    TitanFarmBuddy:ResetConfig(false)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:TestNotification()
-- DESC : Raises a test notification.
-- **************************************************************************
function TitanFarmBuddy:TestNotification()
    local itemInfo = TitanFarmBuddy_GetItemInfo(L['FARM_BUDDY_NOTIFICATION_DEMO_ITEM_NAME'])
    self:ShowNotification(0, itemInfo.Name, itemInfo.IconFileDataID, 200, true)
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:ModifiedClick()
-- DESC : Is called when an item is clicked with modifier key.
-- **************************************************************************
function TitanFarmBuddy:ModifiedClick(itemLink, itemLocation)

    -- item location can be nil for bags/bank/mail and is not nil for inventory slots, make an explicit check
    if itemLocation and itemLocation.IsBagAndSlot and (not itemLocation:IsBagAndSlot()) then
        return
    end

    local fastTrackingMouseButton = TitanGetVar(TITAN_FARM_BUDDY_ID, 'FastTrackingMouseButton')
    local fastTrackingKeys = TitanGetVar(TITAN_FARM_BUDDY_ID, 'FastTrackingKeys')
    local conditions = false

    -- Check modifier keys
    for key, state in pairs(fastTrackingKeys) do
        if (key == 'alt') then
            if (state == true) then
                conditions = IsAltKeyDown()
            else
                conditions = not IsAltKeyDown()
            end

            if (not conditions) then
                break
            end

        elseif (key == 'ctrl') then
            if (state == true) then
                conditions = IsControlKeyDown()
            else
                conditions = not IsControlKeyDown()
            end

            if (not conditions) then
                break
            end

        elseif (key == 'shift') then
            if (state == true) then
                conditions = IsShiftKeyDown()
            else
                conditions = not IsShiftKeyDown()
            end

            if (not conditions) then
                break
            end
        end
    end

    if GetMouseButtonClicked() == fastTrackingMouseButton and not CursorHasItem() and conditions == true then
        if itemLink then
            local dialog = StaticPopup_Show(POPUP_KEY_SET_ITEM_INDEX, ITEMS_AVAILABLE)
            if dialog then
                dialog.data = itemLink
            end
        end
    end
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:QueueNotification()
-- DESC : Queues a notification.
-- **************************************************************************
function TitanFarmBuddy:QueueNotification(index, itemName, itemIconFileDataID, quantity)
    NOTIFICATION_QUEUE[index] = {
        Index = index,
        Name = itemName,
        Icon = itemIconFileDataID,
        Quantity = quantity,
    }
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:ShowNotification()
-- DESC : Raises a notification.
-- **************************************************************************
function TitanFarmBuddy:ShowNotification(index, name, icon, quantity, demo)
    local notificationEnabled = TitanGetVar(TITAN_FARM_BUDDY_ID, 'GoalNotification')
    if (notificationEnabled and not NOTIFICATION_TRIGGERED[index]) or demo then

        local playSound = TitanGetVar(TITAN_FARM_BUDDY_ID, 'PlayNotificationSound')
        local notificationDisplayDuration = tonumber(TitanGetVar(TITAN_FARM_BUDDY_ID, 'NotificationDisplayDuration'))
        local notificationGlow = TitanGetVar(TITAN_FARM_BUDDY_ID, 'NotificationGlow')
        local notificationShine = TitanGetVar(TITAN_FARM_BUDDY_ID, 'NotificationShine')
        local sound

        if playSound then
            sound = TitanGetVar(TITAN_FARM_BUDDY_ID, 'GoalNotificationSound')
        end

        if not demo then
            NOTIFICATION_TRIGGERED[index] = true
        end

        TitanFarmBuddyNotification_Show(name, icon, quantity, sound, notificationDisplayDuration, notificationGlow, notificationShine)
    end
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:NotificationTask()
-- DESC : Is called by the timer to handle the next notification.
-- **************************************************************************
function TitanFarmBuddy:NotificationTask()
    if not TitanFarmBuddyNotification_Shown() then
        for index, notification in pairs(NOTIFICATION_QUEUE) do
            if not TitanGetVar(TITAN_FARM_BUDDY_ID, 'HideNotificationInCombat') or not PLAYER_IN_COMBAT then
                self:ShowNotification(notification.Index, notification.Name, notification.Icon, notification.Quantity, false)
            end
            NOTIFICATION_QUEUE[index] = nil
            break
        end
    end
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:ChatCommand()
-- DESC : Handles AddOn commands.
-- **************************************************************************
function TitanFarmBuddy:ChatCommand(input)

    local cmd, value, arg1 = self:GetArgs(input, 3)

    -- Show help
    if not cmd or cmd == 'help' then

        self:Print(L['FARM_BUDDY_COMMAND_LIST'] .. '\n')
        self:GetChatCommandsHelp(true)

        -- Prints version information
    elseif cmd == 'version' then
        self:Print(ADDON_VERSION)

    -- Reset AddOn settings
    elseif cmd == 'reset' then

        if value == 'all' then
            self:ResetConfig(false)
        else
            self:ResetConfig(true)
        end

        self:Print(L['FARM_BUDDY_CONFIG_RESET_MSG'])

    elseif cmd == 'primary' then

        local index = tonumber(value)

        if self:IsIndexValid(index) then
            local text = L['FARM_BUDDY_ITEM_PRIMARY_SET_MSG']:gsub('!position!', index)
            TitanSetVar(TITAN_FARM_BUDDY_ID, 'ItemShowInBarIndex', index)
            self:Print(text)
            TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
            LibStub('AceConfigRegistry-3.0'):NotifyChange(ADDON_NAME)
        else
            local text = L['FARM_BUDDY_ITEM_SET_POSITION_MSG']:gsub('!max!', ITEMS_AVAILABLE)
            self:Print(text)
        end

    -- Set goal quantity
    elseif cmd == 'quantity' then

        if value then
            local status = self:ValidateNumber(nil, arg1)
            if status then
                local index = tonumber(value)
                if self:IsIndexValid(index) then
                    self:SetItemQuantity(index, nil, arg1)
                    self:Print(L['FARM_BUDDY_GOAL_SET'])
                    TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
                    LibStub('AceConfigRegistry-3.0'):NotifyChange(ADDON_NAME)
                else
                    local text = L['FARM_BUDDY_ITEM_SET_POSITION_MSG']:gsub('!max!', ITEMS_AVAILABLE)
                    self:Print(text)
                end
            end
        else
            self:Print(L['FARM_BUDDY_COMMAND_GOAL_PARAM_MISSING'])
        end

    -- Set tracked item
    elseif cmd == 'track' then

        if value then
            local itemInfo = TitanFarmBuddy_GetItemInfo(arg1)
            if itemInfo then
                local index = tonumber(value)
                if self:IsIndexValid(index) then
                    self:SetItem(index, nil, itemInfo.Name)
                    local text = L['FARM_BUDDY_ITEM_SET_MSG']:gsub('!itemName!', itemInfo.Link)
                    self:Print(text)
                else
                    local text = L['FARM_BUDDY_ITEM_SET_POSITION_MSG']:gsub('!max!', ITEMS_AVAILABLE)
                    self:Print(text)
                end
            else
                self:Print(L['FARM_BUDDY_ITEM_NOT_EXISTS'])
            end
        else
            self:Print(L['FARM_BUDDY_TRACK_ITEM_PARAM_MISSING'])
        end
    elseif cmd == 'settings' then
        Settings.OpenToCategory(ADDON_SETTING_PANEL)
    end
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetChatCommandsHelp()
-- DESC : Returns the help text of the chat commands.
-- **************************************************************************
function TitanFarmBuddy:GetChatCommandsHelp(printOut)

    local helpStr = ''

    for command, info in pairs(CHAT_COMMANDS) do
        helpStr = helpStr .. TitanUtils_GetGreenText('/' .. CHAT_COMMAND) .. ' ' .. TitanUtils_GetRedText(command)
        if info.Args ~= '' then
            helpStr = helpStr .. ' ' .. TitanUtils_GetGoldText(info.Args)
        end
        helpStr = helpStr .. ' - ' .. info.Description
        if printOut then
            print(helpStr)
            helpStr = ''
        else
            helpStr = helpStr .. '\n'
        end
    end

    return helpStr
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:IsIndexValid()
-- DESC : Returns the index status.
-- **************************************************************************
function TitanFarmBuddy:IsIndexValid(index)
    return index and index > 0 and index <= ITEMS_AVAILABLE
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetNotificationSounds()
-- DESC : Get a list of available sounds.
-- **************************************************************************
function TitanFarmBuddy:GetNotificationSounds()

    local sounds = {}

    for k, v in pairs(NOTIFICATION_SOUNDS) do
        sounds[k] = v
    end

    return sounds
end

-- **************************************************************************
-- NAME : TitanFarmBuddy:GetNotificationSoundsSorting()
-- DESC : Get the sound keys sorted by their label ascending.
-- **************************************************************************
function TitanFarmBuddy:GetNotificationSoundsSorting()

    local sorting = {}

    for k in pairs(NOTIFICATION_SOUNDS) do
        table.insert(sorting, k)
    end

    table.sort(sorting, function(a, b)
        return NOTIFICATION_SOUNDS[a] < NOTIFICATION_SOUNDS[b]
    end)

    return sorting
end
