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
local ITEM_INFO_CACHE = {}
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

---Gets the Titan Plugin AddOn name.
---@return string name
function TitanFarmBuddy_GetAddOnName()
    return ADDON_NAME
end


---Gets the Titan Plugin AddOn settings panel.
---@return table category
function TitanFarmBuddy_GetAddOnSettingsPanel()
    return ADDON_SETTING_PANEL
end

---Is called by AceAddon when the addon is first loaded.
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

---Registers the plugin upon it loading.
---@param button Button The Titan plugin button.
function TitanFarmBuddy_OnLoad(button)
    button.registry = {
        id = TITAN_FARM_BUDDY_ID,
        category = 'Information',
        version = TITAN_VERSION,
        menuText = ADDON_NAME,
        menuContextFunction = function(_, root) return TitanFarmBuddy:MenuGenerator(_, root) end,
        buttonTextFunction = function() return TitanFarmBuddy:GetButtonText() end,
        tooltipTitle = ADDON_NAME,
        tooltipTextFunction = function() return TitanFarmBuddy:GetTooltipText() end,
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

---Is called when the plugin gets enabled.
function TitanFarmBuddy:OnEnable()
    self:SecureHook('HandleModifiedItemClick', 'ModifiedClick')
    self:ScheduleRepeatingTimer('NotificationTask', 1)
end

---Is called when the plugin gets disabled.
function TitanFarmBuddy:OnDisable()
    ITEM_DATA_INIT_COMPLETE = false
    self:CancelAllTimers()
end

---Is called when the player enters the world.
function TitanFarmBuddy:PlayerEnteringWorld()
    self:UnregisterEvent('PLAYER_ENTERING_WORLD')

    -- Delayed data fetching to prevent login timing issues
    C_Timer.After(4, function()
        for i = 1, ITEMS_AVAILABLE do
            local item = TitanGetVar(TITAN_FARM_BUDDY_ID, 'Item' .. i)
            local quantity = tonumber(TitanGetVar(TITAN_FARM_BUDDY_ID, 'ItemQuantity' .. i)) or 0
            local itemInfo = (item and item ~= '') and self:GetItemInfo(item) or nil

            NOTIFICATION_TRIGGERED[i] = itemInfo and quantity > 0 and self:GetCount(itemInfo) >= quantity
        end

        TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
        ITEM_DATA_INIT_COMPLETE = true
    end)
end

---Registers the addon's dialog boxes.
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

---Callback function for the SetItemIndex OnShow event.
---@param frame table The static popup frame.
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

---Callback function for the SetItemIndex OnAccept event.
---@param frame table The static popup frame.
---@param data string The item link passed to the dialog.
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

---Gets the configuration table for the AceConfig lib.
---@return table options
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

---Dynamically builds the tracked item option fields based on ITEMS_AVAILABLE.
---@return table args
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

---A helper function to generate an item input field for the Blizzard option panel.
---@param index number The tracked item slot index.
---@return table field
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

---A helper function to generate an item count input field for the Blizzard option panel.
---@param index number The tracked item slot index.
---@return table field
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

---A helper function to generate an item "show in Titan bar" checkbox for the Blizzard option panel.
---@param index number The tracked item slot index.
---@return table field
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

---A helper function to generate a button for the Blizzard option panel to reset the tracked item.
---@param index number The tracked item slot index.
---@return table field
function TitanFarmBuddy:GetTrackedItemClearButton(index)
    return {
        type = 'execute',
        name = L['FARM_BUDDY_RESET'],
        desc = L['FARM_BUDDY_RESET_DESC'],
        func = function() self:ResetItem(index) end,
        order = self:GetOptionOrder('items'),
    }
end

---A helper function to order the option items in the order as listed in the array.
---@param category string The option category to order within.
---@return number order
function TitanFarmBuddy:GetOptionOrder(category)
    if not OPTION_ORDER[category] then
        OPTION_ORDER[category] = 0
    end

    OPTION_ORDER[category] = OPTION_ORDER[category] + 1

    return OPTION_ORDER[category]
end

---Calculates the item count of the tracked farm item and displays it.
---@return string text
function TitanFarmBuddy:GetButtonText()

    local str = ''
    local itemDisplayStyle = tonumber(TitanGetVar(TITAN_FARM_BUDDY_ID, 'ItemDisplayStyle'))
    local activeIndex = TitanGetVar(TITAN_FARM_BUDDY_ID, 'ItemShowInBarIndex')
    local showIcon = TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowIcon')
    local showQuantity = TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowQuantity')
    local showColoredText = TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowColoredText')
    local showLabelText = TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowLabelText')

    for i = 1, ITEMS_AVAILABLE do
        if (itemDisplayStyle == 1 and activeIndex == i) or itemDisplayStyle > 1 then
            local item = TitanGetVar(TITAN_FARM_BUDDY_ID, 'Item' .. i)
            if item and item ~= '' then
                local itemQuantity = tonumber(TitanGetVar(TITAN_FARM_BUDDY_ID, 'ItemQuantity' .. i))
                local itemStr = self:GetItemString(item, itemQuantity, showIcon, showQuantity, showColoredText, showLabelText)
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

---Gets the item link without the brackets.
---@param itemLink string The item link.
---@return string name
function TitanFarmBuddy:GetNameFromItemLink(itemLink)
    return (itemLink:gsub("%[(.-)%]", "%1"))
end

---Gets the item string to display on the Titan Panel button.
---@param item string The item link or name.
---@param itemQuantity number The goal quantity (0 means none).
---@param showIcon boolean Whether to prepend the item icon.
---@param showQuantity boolean Whether to append the goal quantity.
---@param showColoredText boolean Whether to color the text.
---@param showLabelText boolean Whether to append the item name.
---@return string text
function TitanFarmBuddy:GetItemString(item, itemQuantity, showIcon, showQuantity, showColoredText, showLabelText)

    local itemInfo = self:GetItemInfo(item)
    if not itemInfo then
        return ''
    end

    local str = ''

    if showIcon then
        str = str .. self:GetIconString(itemInfo.IconFileDataID, true)
    end

    str = str .. self:GetBarValue(self:GetCount(itemInfo), showColoredText)

    if showQuantity and itemQuantity > 0 then
        str = str .. ' / ' .. self:GetBarValue(itemQuantity, showColoredText)
    end

    if showLabelText then
        str = str .. ' ' .. (showColoredText and self:GetNameFromItemLink(item) or itemInfo.Name)
    end

    return str
end

---Gets an icon string.
---@param icon string|number The icon file path or file data ID.
---@param space boolean Whether to append a trailing space.
---@return string text
function TitanFarmBuddy:GetIconString(icon, space)
    local fontSize = TitanPanelGetVar('FontSize') + 6
    return string.format('|T%s:%d|t%s', icon, fontSize, space and ' ' or '')
end

---Gets a value with highlighted color for the Titan bar.
---@param value string|number The value to display.
---@param colored boolean Whether to apply the highlight color.
---@return string|number value
function TitanFarmBuddy:GetBarValue(value, colored)
    if colored then
        value = TitanUtils_GetHighlightText(value)
    end
    return value
end

---Handles click events on the Titan button.
---@param button string The mouse button that was clicked.
function TitanFarmBuddy_OnClick(_, button)
    if button == 'LeftButton' then
        Settings.OpenToCategory(ADDON_SETTING_PANEL)
    end
end

---Gets information for the given item name.
---@param item string The item link, name or id.
---@return table|nil itemInfo Item info table, or nil if the item could not be resolved.
function TitanFarmBuddy:GetItemInfo(item)
    if not item then
        return nil
    end

    local static = ITEM_INFO_CACHE[item]
    if not static then
        local itemName, itemLink = C_Item.GetItemInfo(item)
        if not itemLink then
            return nil
        end

        local itemID, _, _, _, itemIcon = C_Item.GetItemInfoInstant(item)
        static = {
            ItemID = itemID,
            Name = itemName,
            Link = itemLink,
            IconFileDataID = itemIcon,
        }
        ITEM_INFO_CACHE[item] = static
    end

    local countBags = C_Item.GetItemCount(static.ItemID)
    local countTotal = C_Item.GetItemCount(static.ItemID, true)

    return {
        ItemID = static.ItemID,
        Name = static.Name,
        Link = static.Link,
        IconFileDataID = static.IconFileDataID,
        CountBags = countBags,
        CountTotal = countTotal,
        CountBank = (countTotal - countBags),
    }
end

---Displays the tooltip text.
---@return string text
function TitanFarmBuddy:GetTooltipText()

    local str = TitanUtils_GetGreenText(L['FARM_BUDDY_TOOLTIP_DESC']) .. '\n' ..
        TitanUtils_GetGreenText(L['FARM_BUDDY_TOOLTIP_MODIFIER']) .. '\n\n'
    local strTmp = ''
    local hasItem = false

    for i = 1, ITEMS_AVAILABLE do
        local item = TitanGetVar(TITAN_FARM_BUDDY_ID, 'Item' .. i)

        -- No item set for this index
        if item and item ~= '' then
            local itemInfo = self:GetItemInfo(item)

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

---Builds the right click menu using the modern Titan_Menu (Blizzard_Menu) API.
---Titan automatically adds the title, the control variables and the hide
---command, so they are not added here.
---@param root table The Titan_Menu root node.
function TitanFarmBuddy:MenuGenerator(_, root)
    local id = TITAN_FARM_BUDDY_ID

    -- Options
    local options = Titan_Menu.AddButton(root, L['TITAN_PANEL_OPTIONS'])
    Titan_Menu.AddSelector(options, id, L['FARM_BUDDY_SHOW_GOAL'], 'ShowQuantity')
    Titan_Menu.AddSelector(options, id, L['FARM_BUDDY_INCLUDE_BANK'], 'IncludeBank')

    -- Notifications
    local notifications = Titan_Menu.AddButton(root, L['FARM_BUDDY_NOTIFICATIONS'])
    Titan_Menu.AddSelector(notifications, id, L['FARM_BUDDY_NOTIFICATION'], 'GoalNotification')
    Titan_Menu.AddDivider(notifications)
    Titan_Menu.AddSelector(notifications, id, L['FARM_BUDDY_NOTIFICATION_GLOW'], 'NotificationGlow')
    Titan_Menu.AddSelector(notifications, id, L['FARM_BUDDY_NOTIFICATION_SHINE'], 'NotificationShine')
    Titan_Menu.AddSelector(notifications, id, L['FARM_BUDDY_PLAY_NOTIFICATION_SOUND'], 'PlayNotificationSound')

    -- Actions
    local actions = Titan_Menu.AddButton(root, L['FARM_BUDDY_ACTIONS'])
    Titan_Menu.AddCommand(actions, id, L['FARM_BUDDY_TEST_NOTIFICATION'], function() self:TestNotification() end)
    Titan_Menu.AddDivider(actions)
    Titan_Menu.AddCommand(actions, id, L['FARM_BUDDY_RESET_ALL_ITEMS'], function() StaticPopup_Show(POPUP_KEY_RESET_ALL_ITEMS_CONFIRM) end)
    Titan_Menu.AddCommand(actions, id, L['FARM_BUDDY_RESET_ALL'], function() StaticPopup_Show(POPUP_KEY_RESET_ALL_CONFIRM) end)

    -- Reset all settings
    Titan_Menu.AddCommand(root, id, L['FARM_BUDDY_RESET'], function() self:ResetConfig() end)
end

---Checks if the item count has reached the goal and triggers a notification if it has.
function TitanFarmBuddy:BagUpdateDelayed()

    if not ITEM_DATA_INIT_COMPLETE then
        return
    end

    for i = 1, ITEMS_AVAILABLE do
        local trackedItem = TitanGetVar(TITAN_FARM_BUDDY_ID, 'Item' .. i)
        local quantity = tonumber(TitanGetVar(TITAN_FARM_BUDDY_ID, 'ItemQuantity' .. i))

        if trackedItem and trackedItem ~= '' and quantity and quantity > 0 then
            local itemInfo = self:GetItemInfo(trackedItem)
            if itemInfo then
                if self:GetCount(itemInfo) >= quantity then
                    self:QueueNotification(i, itemInfo.Name, itemInfo.IconFileDataID, quantity)
                else
                    NOTIFICATION_QUEUE[i] = nil
                end
            end
        end
    end

    TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
end

---Fires when the player enters combat.
function TitanFarmBuddy:PlayerRegenDisabled()
    PLAYER_IN_COMBAT = true
end

---Fires when the player leaves combat.
function TitanFarmBuddy:PlayerRegenEnabled()
    PLAYER_IN_COMBAT = false
end

---Gets the item count.
---@param itemInfo table The item info table.
---@return number count
function TitanFarmBuddy:GetCount(itemInfo)
    if TitanGetVar(TITAN_FARM_BUDDY_ID, 'IncludeBank') then
        return itemInfo.CountTotal
    end

    return itemInfo.CountBags
end

---Displays the button when the plugin is visible.
---@param self Button The Titan plugin button.
function TitanFarmBuddy_OnShow(self)
    local sound = TitanGetVar(TITAN_FARM_BUDDY_ID, 'GoalNotificationSound')
    if sound and not tonumber(sound) then
        TitanSetVar(TITAN_FARM_BUDDY_ID, 'GoalNotificationSound', SOUNDKIT.ALARM_CLOCK_WARNING_3)
    end

    TitanPanelButton_OnShow(self)
end

---Checks if the entered item name is valid.
---@param input string The item name or link to validate.
---@return boolean valid
function TitanFarmBuddy:ValidateItem(_, input)

    local _, itemLink = C_Item.GetItemInfo(input)

    if itemLink then
        return true
    end

    self:Print(L['FARM_BUDDY_ITEM_NOT_EXISTS'])
    return false
end

---Checks if the entered value is a valid and positive number.
---@param input string The value to validate.
---@return boolean valid
function TitanFarmBuddy:ValidateNumber(_, input)

    local number = tonumber(input)
    if not number or number < 0 then
        self:Print(L['FARM_BUDDY_INVALID_NUMBER'])
        return false
    end

    return true
end

---Gets the item.
---@param index number The tracked item slot index.
---@return string item
function TitanFarmBuddy:GetItem(index)
    return TitanGetVar(TITAN_FARM_BUDDY_ID, 'Item' .. index)
end

---Resolves the given input to an item link. If the input is already an item link
---it is returned unchanged, otherwise it is treated as an item id or item name
---and converted into an item link.
---@param input string The item link, id or name.
---@return string|nil itemLink
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

---Sets the item.
---@param index number The tracked item slot index.
---@param input string The item link, id or name.
function TitanFarmBuddy:SetItem(index, _, input)
    local itemLink = self:GetItemLink(input)

    TitanSetVar(TITAN_FARM_BUDDY_ID, 'Item' .. index, itemLink or input)
    TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
    NOTIFICATION_TRIGGERED[index] = false
    LibStub('AceConfigRegistry-3.0'):NotifyChange(ADDON_NAME)
end

---Resets the item with the given index.
---@param index number The tracked item slot index.
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

---Gets the item goal.
---@param index number The tracked item slot index.
---@return string quantity
function TitanFarmBuddy:GetItemQuantity(index)
    return tostring(TitanGetVar(TITAN_FARM_BUDDY_ID, 'ItemQuantity' .. index))
end

---Sets the item goal.
---@param index number The tracked item slot index.
---@param input string|number The goal quantity.
function TitanFarmBuddy:SetItemQuantity(index, _, input)
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'ItemQuantity' .. index, tonumber(input))
    TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
    NOTIFICATION_TRIGGERED[index] = false
end

---Gets the item show in bar status.
---@param index number The tracked item slot index.
---@return boolean showInBar
function TitanFarmBuddy:GetItemShowInBar(index)
    return TitanGetVar(TITAN_FARM_BUDDY_ID, 'ItemShowInBarIndex') == index
end

---Sets the item show in bar status.
---@param index number The tracked item slot index.
function TitanFarmBuddy:SetItemShowInBar(index)
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'ItemShowInBarIndex', index)
    TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
end

---Sets the notification status.
---@param input boolean Whether goal notifications are enabled.
function TitanFarmBuddy:SetNotificationStatus(_, input)
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'GoalNotification', input)
end

---Gets the notification status.
---@return boolean enabled
function TitanFarmBuddy:GetNotificationStatus()
    return TitanGetVar(TITAN_FARM_BUDDY_ID, 'GoalNotification')
end

---Sets the item display style.
---@param input number The item display style.
function TitanFarmBuddy:SetItemDisplayStyle(_, input)
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'ItemDisplayStyle', input)
    TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
end

---Gets the item display style.
---@return number style
function TitanFarmBuddy:GetItemDisplayStyle()
    return TitanGetVar(TITAN_FARM_BUDDY_ID, 'ItemDisplayStyle')
end

---Sets the fast tracking mouse button.
---@param input string The mouse button.
function TitanFarmBuddy:SetFastTrackingMouseButton(_, input)
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'FastTrackingMouseButton', input)
end

---Gets the fast tracking mouse button.
---@return string button
function TitanFarmBuddy:GetFastTrackingMouseButton()
    return TitanGetVar(TITAN_FARM_BUDDY_ID, 'FastTrackingMouseButton')
end

---Sets the fast tracking shortcut key.
---@param key string The modifier key.
---@param state boolean Whether the modifier key is required.
function TitanFarmBuddy:SetKeySetting(_, key, state)

    local options = TitanGetVar(TITAN_FARM_BUDDY_ID, 'FastTrackingKeys')

    if options[key] then
        options[key] = state
    end

    TitanSetVar(TITAN_FARM_BUDDY_ID, 'FastTrackingKeys', options)
end

---Gets the fast tracking shortcut key.
---@param key string The modifier key.
---@return boolean state
function TitanFarmBuddy:GetKeySetting(_, key)

    local options = TitanGetVar(TITAN_FARM_BUDDY_ID, 'FastTrackingKeys')

    if options[key] then
        return options[key]
    end

    return false
end

---Sets the play notification sound status.
---@param input boolean Whether the notification sound is played.
function TitanFarmBuddy:SetPlayNotificationSoundStatus(_, input)
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'PlayNotificationSound', input)
end

---Gets the play notification sound status.
---@return boolean enabled
function TitanFarmBuddy:GetPlayNotificationSoundStatus()
    return TitanGetVar(TITAN_FARM_BUDDY_ID, 'PlayNotificationSound')
end

---Sets the notification display duration.
---@param input string|number The display duration in seconds.
function TitanFarmBuddy:SetNotificationDisplayDuration(_, input)
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'NotificationDisplayDuration', input)
end

---Gets the notification display duration.
---@return string duration
function TitanFarmBuddy:GetNotificationDisplayDuration()
    return tostring(TitanGetVar(TITAN_FARM_BUDDY_ID, 'NotificationDisplayDuration'))
end

---Sets the notification sound.
---@param input number The sound kit id.
function TitanFarmBuddy:SetNotificationSound(_, input)
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'GoalNotificationSound', input)
    PlaySound(input, 'master')
end

---Gets the notification sound.
---@return number sound
function TitanFarmBuddy:GetNotificationSound()
    local sound = TitanGetVar(TITAN_FARM_BUDDY_ID, 'GoalNotificationSound')
    if not sound or not NOTIFICATION_SOUNDS[sound] then
        return SOUNDKIT.ALARM_CLOCK_WARNING_3
    end

    return sound
end

---Sets the notification glow effect status.
---@param input boolean Whether the glow effect is enabled.
function TitanFarmBuddy:SetNotificationGlow(_, input)
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'NotificationGlow', input)
end

---Gets the notification glow effect status.
---@return boolean enabled
function TitanFarmBuddy:GetNotificationGlow()
    return TitanGetVar(TITAN_FARM_BUDDY_ID, 'NotificationGlow')
end

---Sets the notification shine effect status.
---@param input boolean Whether the shine effect is enabled.
function TitanFarmBuddy:SetNotificationShine(_, input)
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'NotificationShine', input)
end

---Gets the notification shine effect status.
---@return boolean enabled
function TitanFarmBuddy:GetNotificationShine()
    return TitanGetVar(TITAN_FARM_BUDDY_ID, 'NotificationShine')
end

---Sets the hide notification in combat status.
---@param input boolean Whether notifications are hidden in combat.
function TitanFarmBuddy:SetHideNotificationInCombat(_, input)
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'HideNotificationInCombat', input)
end

---Gets the hide notification in combat status.
---@return boolean enabled
function TitanFarmBuddy:GetHideNotificationInCombat()
    return TitanGetVar(TITAN_FARM_BUDDY_ID, 'HideNotificationInCombat')
end

---Sets the show item icon status.
---@param input boolean Whether the item icon is shown.
function TitanFarmBuddy:SetShowItemIcon(_, input)
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'ShowIcon', input)
    TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
end

---Gets the show item icon status.
---@return boolean enabled
function TitanFarmBuddy:GetShowItemIcon()
    return TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowIcon')
end

---Sets the show item name status.
---@param input boolean Whether the item name is shown.
function TitanFarmBuddy:SetShowItemName(_, input)
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'ShowLabelText', input)
    TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
end

---Gets the show item name status.
---@return boolean enabled
function TitanFarmBuddy:GetShowItemName()
    return TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowLabelText')
end

---Sets the show colored text status.
---@param input boolean Whether the text is colored.
function TitanFarmBuddy:SetShowColoredText(_, input)
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'ShowColoredText', input)
    TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
end

---Gets the show colored text status.
---@return boolean enabled
function TitanFarmBuddy:GetShowColoredText()
    return TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowColoredText')
end

---Sets the show goal status.
---@param input boolean Whether the goal quantity is shown.
function TitanFarmBuddy:SetShowQuantity(_, input)
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'ShowQuantity', input)
    TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
end

---Gets the show goal status.
---@return boolean enabled
function TitanFarmBuddy:GetShowQuantity()
    return TitanGetVar(TITAN_FARM_BUDDY_ID, 'ShowQuantity')
end

---Sets the include items in bank status.
---@param input boolean Whether bank items are included in the count.
function TitanFarmBuddy:SetIncludeBank(_, input)
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'IncludeBank', input)
    TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
end

---Gets the include items in bank status.
---@return boolean enabled
function TitanFarmBuddy:GetIncludeBank()
    return TitanGetVar(TITAN_FARM_BUDDY_ID, 'IncludeBank')
end

---Resets the saved config to the default values.
---@param itemsOnly boolean If true, only the tracked items are reset.
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

---Raises a test notification.
function TitanFarmBuddy:TestNotification()
    local itemInfo = self:GetItemInfo(L['FARM_BUDDY_NOTIFICATION_DEMO_ITEM_NAME'])
    self:ShowNotification(0, itemInfo.Name, itemInfo.IconFileDataID, 200, true)
end

---Is called when an item is clicked with a modifier key.
---@param itemLink string The clicked item link.
---@param itemLocation table|nil The item location, or nil for bags/bank/mail.
function TitanFarmBuddy:ModifiedClick(itemLink, itemLocation)

    -- item location can be nil for bags/bank/mail and is not nil for inventory slots, make an explicit check
    if itemLocation and itemLocation.IsBagAndSlot and (not itemLocation:IsBagAndSlot()) then
        return
    end

    local fastTrackingMouseButton = TitanGetVar(TITAN_FARM_BUDDY_ID, 'FastTrackingMouseButton')
    local fastTrackingKeys = TitanGetVar(TITAN_FARM_BUDDY_ID, 'FastTrackingKeys')
    local modifierChecks = {
        alt = IsAltKeyDown,
        ctrl = IsControlKeyDown,
        shift = IsShiftKeyDown,
    }
    local conditions = false

    -- Check modifier keys
    for key, state in pairs(fastTrackingKeys) do
        local isKeyDown = modifierChecks[key]
        if isKeyDown then
            conditions = isKeyDown() == (state == true)
            if not conditions then
                break
            end
        end
    end

    if GetMouseButtonClicked() == fastTrackingMouseButton and not CursorHasItem() and conditions then
        if itemLink then
            local dialog = StaticPopup_Show(POPUP_KEY_SET_ITEM_INDEX, ITEMS_AVAILABLE)
            if dialog then
                dialog.data = itemLink
            end
        end
    end
end

---Queues a notification.
---@param index number The tracked item slot index.
---@param itemName string The item name.
---@param itemIconFileDataID number The item icon file data ID.
---@param quantity number The reached goal quantity.
function TitanFarmBuddy:QueueNotification(index, itemName, itemIconFileDataID, quantity)
    NOTIFICATION_QUEUE[index] = {
        Index = index,
        Name = itemName,
        Icon = itemIconFileDataID,
        Quantity = quantity,
    }
end

---Raises a notification.
---@param index number The tracked item slot index.
---@param name string The item name.
---@param icon number The item icon file data ID.
---@param quantity number The reached goal quantity.
---@param demo boolean Whether this is a demo/test notification.
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

---Is called by the timer to handle the next notification.
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

---Handles AddOn commands.
---@param input string The raw chat command input.
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
            local itemInfo = self:GetItemInfo(arg1)
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

---Returns the help text of the chat commands.
---@param printOut boolean If true, each line is printed to the chat frame.
---@return string helpText
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

---Returns the index status.
---@param index number The tracked item slot index.
---@return boolean valid
function TitanFarmBuddy:IsIndexValid(index)
    return index and index > 0 and index <= ITEMS_AVAILABLE
end

---Gets a list of available sounds.
---@return table sounds
function TitanFarmBuddy:GetNotificationSounds()

    local sounds = {}

    for k, v in pairs(NOTIFICATION_SOUNDS) do
        sounds[k] = v
    end

    return sounds
end

---Gets the sound keys sorted by their label ascending.
---@return table sorting
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
