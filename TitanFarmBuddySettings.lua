-- **************************************************************************
-- * TitanFarmBuddySettings.lua
-- *
-- * By: Keldor
-- **************************************************************************

local L = LibStub('AceLocale-3.0'):GetLocale('Titan', true)
local TitanFarmBuddy = LibStub('AceAddon-3.0'):GetAddon(TITAN_FARM_BUDDY_ID)
local CONFIG_REG = LibStub("AceConfigRegistry-3.0")
local ADDON_VERSION = C_AddOns.GetAddOnMetadata('TitanFarmBuddy', 'Version')
local ADDON_SETTING_PANEL
local ITEM_DISPLAY_STYLES = {
    [1] = L['FARM_BUDDY_ITEM_DISPLAY_STYLE_1'],
    [2] = L['FARM_BUDDY_ITEM_DISPLAY_STYLE_2'],
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

---Creates the chat commands.
function TitanFarmBuddy:InitSettings()
    LibStub('AceConfig-3.0'):RegisterOptionsTable(ADDON_NAME, self:GetConfigOption())
    local _, category = LibStub('AceConfigDialog-3.0'):AddToBlizOptions(ADDON_NAME)
    ADDON_SETTING_PANEL = category
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
                    general_space_4 = {
                        type = 'description',
                        name = '',
                        order = self:GetOptionOrder('general'),
                    },
                    general_display_group = {
                        type = 'group',
                        inline = true,
                        name = L['FARM_BUDDY_DISPLAY'],
                        order = self:GetOptionOrder('general'),
                        args = {
                            general_show_item_icon = {
                                arg = { key = 'ShowIcon' },
                                type = 'toggle',
                                name = L['FARM_BUDDY_SHOW_ICON'],
                                desc = L['FARM_BUDDY_SHOW_ICON_DESC'],
                                get = 'GetSettingsValue',
                                set = 'SetSettingsValue',
                                width = 'full',
                                order = self:GetOptionOrder('general'),
                            },
                            general_space_1 = {
                                type = 'description',
                                name = '',
                                order = self:GetOptionOrder('general'),
                            },
                            general_show_item_name = {
                                arg = { key = 'ShowLabelText' },
                                type = 'toggle',
                                name = L['FARM_BUDDY_SHOW_NAME'],
                                desc = L['FARM_BUDDY_SHOW_NAME_DESC'],
                                get = 'GetSettingsValue',
                                set = 'SetSettingsValue',
                                width = 'full',
                                order = self:GetOptionOrder('general'),
                            },
                            general_space_2 = {
                                type = 'description',
                                name = '',
                                order = self:GetOptionOrder('general'),
                            },
                            general_show_colored_text = {
                                arg = { key = 'ShowColoredText' },
                                type = 'toggle',
                                name = L['FARM_BUDDY_SHOW_COLORED_TEXT'],
                                desc = L['FARM_BUDDY_SHOW_COLORED_TEXT_DESC'],
                                get = 'GetSettingsValue',
                                set = 'SetSettingsValue',
                                width = 'full',
                                order = self:GetOptionOrder('general'),
                            },
                            general_space_3 = {
                                type = 'description',
                                name = '',
                                order = self:GetOptionOrder('general'),
                            },
                            general_show_goal = {
                                arg = { key = 'ShowQuantity' },
                                type = 'toggle',
                                name = L['FARM_BUDDY_SHOW_GOAL'],
                                desc = L['FARM_BUDDY_SHOW_GOAL_DESC'],
                                get = 'GetSettingsValue',
                                set = 'SetSettingsValue',
                                width = 'full',
                                order = self:GetOptionOrder('general'),
                            },
                        },
                    },
                    general_counting_group = {
                        type = 'group',
                        inline = true,
                        name = L['FARM_BUDDY_COUNTING'],
                        order = self:GetOptionOrder('general'),
                        args = {
                            general_track_bank = {
                                arg = { key = 'IncludeBank' },
                                type = 'toggle',
                                name = L['FARM_BUDDY_INCLUDE_BANK'],
                                desc = L['FARM_BUDDY_INCLUDE_BANK_DESC'],
                                get = 'GetSettingsValue',
                                set = 'SetSettingsValue',
                                width = 'full',
                                order = self:GetOptionOrder('general'),
                            },
                            general_track_warband_bank = {
                                arg = { key = 'IncludeWarbandBank' },
                                type = 'toggle',
                                name = L['FARM_BUDDY_INCLUDE_WARBAND_BANK'],
                                desc = L['FARM_BUDDY_INCLUDE_WARBAND_BANK_DESC'],
                                get = 'GetSettingsValue',
                                set = 'SetSettingsValue',
                                width = 'full',
                                order = self:GetOptionOrder('general'),
                            },
                        },
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
                        arg = { key = 'ItemDisplayStyle' },
                        type = 'select',
                        style = 'radio',
                        name = L['FARM_BUDDY_ITEM_DISPLAY_STYLE'],
                        desc = L['FARM_BUDDY_ITEM_DISPLAY_STYLE_DESC'],
                        get = 'GetSettingsValue',
                        set = 'SetSettingsValue',
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
                        arg = { key = 'FastTrackingMouseButton' },
                        type = 'select',
                        style = 'radio',
                        name = L['FARM_BUDDY_FAST_TRACKING_MOUSE_BUTTON'],
                        get = 'GetSettingsValue',
                        set = 'SetSettingsValue',
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
                        arg = { key = 'FastTrackingKeys' },
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
                        arg = { key = 'GoalNotification' },
                        type = 'toggle',
                        name = L['FARM_BUDDY_NOTIFICATION'],
                        desc = L['FARM_BUDDY_NOTIFICATION_DESC'],
                        get = 'GetSettingsValue',
                        set = 'SetSettingsValue',
                        width = 'full',
                        order = self:GetOptionOrder('notifications'),
                    },
                    notifications_space_1 = {
                        type = 'description',
                        name = '',
                        order = self:GetOptionOrder('notifications'),
                    },
                    notifications_chat_notification_status = {
                        arg = { key = 'ChatGoalNotification' },
                        type = 'toggle',
                        name = L['FARM_BUDDY_CHAT_NOTIFICATIONS'],
                        desc = L['FARM_BUDDY_CHAT_NOTIFICATIONS_DESC'],
                        get = 'GetSettingsValue',
                        set = 'SetSettingsValue',
                        width = 'full',
                        order = self:GetOptionOrder('notifications'),
                    },
                    notifications_space_2 = {
                        type = 'description',
                        name = '',
                        order = self:GetOptionOrder('notifications'),
                    },
                    notifications_hide_in_combat = {
                        arg = { key = 'HideNotificationInCombat' },
                        type = 'toggle',
                        name = L['FARM_BUDDY_HIDE_NOTIFICATIONS_IN_COMBAT'],
                        desc = L['FARM_BUDDY_HIDE_NOTIFICATIONS_IN_COMBAT_DESC'],
                        get = 'GetSettingsValue',
                        set = 'SetSettingsValue',
                        width = 'full',
                        order = self:GetOptionOrder('notifications'),
                    },
                    notifications_space_3 = {
                        type = 'description',
                        name = '',
                        order = self:GetOptionOrder('notifications'),
                    },
                    notifications_notification_display_duration = {
                        arg = { key = 'NotificationDisplayDuration', numeric = true },
                        type = 'input',
                        name = L['FARM_BUDDY_PLAY_NOTIFICATION_DISPLAY_DURATION'],
                        desc = L['FARM_BUDDY_PLAY_NOTIFICATION_DISPLAY_DURATION_DESC'],
                        get = 'GetSettingsValue',
                        set = 'SetSettingsValue',
                        validate = 'ValidateNumber',
                        width = 'double',
                        order = self:GetOptionOrder('notifications'),
                    },
                    notifications_space_4 = {
                        type = 'description',
                        name = '',
                        order = self:GetOptionOrder('notifications'),
                    },
                    notifications_notification_glow = {
                        arg = { key = 'NotificationGlow' },
                        type = 'toggle',
                        name = L['FARM_BUDDY_NOTIFICATION_GLOW'],
                        desc = L['FARM_BUDDY_NOTIFICATION_GLOW_DESC'],
                        get = 'GetSettingsValue',
                        set = 'SetSettingsValue',
                        width = 'full',
                        order = self:GetOptionOrder('notifications'),
                    },
                    notifications_space_5 = {
                        type = 'description',
                        name = '',
                        order = self:GetOptionOrder('notifications'),
                    },
                    notifications_notification_shine = {
                        arg = { key = 'NotificationShine' },
                        type = 'toggle',
                        name = L['FARM_BUDDY_NOTIFICATION_SHINE'],
                        desc = L['FARM_BUDDY_NOTIFICATION_SHINE_DESC'],
                        get = 'GetSettingsValue',
                        set = 'SetSettingsValue',
                        width = 'full',
                        order = self:GetOptionOrder('notifications'),
                    },
                    notifications_space_6 = {
                        type = 'description',
                        name = '',
                        order = self:GetOptionOrder('notifications'),
                    },
                    notifications_play_notification_sound = {
                        arg = { key = 'PlayNotificationSound' },
                        type = 'toggle',
                        name = L['FARM_BUDDY_PLAY_NOTIFICATION_SOUND'],
                        desc = L['FARM_BUDDY_PLAY_NOTIFICATION_SOUND_DESC'],
                        get = 'GetSettingsValue',
                        set = 'SetSettingsValue',
                        width = 'full',
                        order = self:GetOptionOrder('notifications'),
                    },
                    notifications_space_7 = {
                        type = 'description',
                        name = '',
                        order = self:GetOptionOrder('notifications'),
                    },
                    notifications_notification_sound = {
                        arg = { key = 'GoalNotificationSound' },
                        type = 'select',
                        name = L['TITAN_BUDDY_NOTIFICATION_SOUND'],
                        style = 'dropdown',
                        values = NOTIFICATION_SOUNDS,
                        sorting = self:GetNotificationSoundsSorting(),
                        set = 'SetNotificationSound',
                        get = 'GetNotificationSound',
                        width = 'double',
                        order = self:GetOptionOrder('notifications'),
                    },
                    notifications_space_8 = {
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
                    general_actions_group = {
                        type = 'group',
                        inline = true,
                        name = L['FARM_BUDDY_ACTIONS'],
                        order = self:GetOptionOrder('actions'),
                        args = {
                            actions_test_alert = {
                                type = 'execute',
                                name = L['FARM_BUDDY_TEST_NOTIFICATION'],
                                desc = L['FARM_BUDDY_TEST_NOTIFICATION_DESC'],
                                func = 'TestNotification',
                                width = 'full',
                                order = self:GetOptionOrder('actions'),
                            },
                        },
                    },
                    general_danger_zone_group = {
                        type = 'group',
                        inline = true,
                        name = L['FARM_BUDDY_DANGER_ZONE'],
                        order = self:GetOptionOrder('actions'),
                        args = {
                            actions_reset_items = {
                                type = 'execute',
                                name = L['FARM_BUDDY_RESET_ALL_ITEMS'],
                                desc = L['FARM_BUDDY_RESET_ALL_ITEMS_DESC'],
                                func = function() StaticPopup_Show(TITAN_FARM_BUDDY_DIALOG_RESET_ALL_ITEMS_CONFIRM) end,
                                width = 'full',
                                order = self:GetOptionOrder('actions'),
                            },
                            actions_space_3 = {
                                type = 'description',
                                name = '\n',
                                order = self:GetOptionOrder('actions'),
                            },
                            actions_reset_all = {
                                type = 'execute',
                                name = L['FARM_BUDDY_RESET_ALL'],
                                desc = L['FARM_BUDDY_RESET_ALL_DESC'],
                                func = function() StaticPopup_Show(TITAN_FARM_BUDDY_DIALOG_RESET_ALL_CONFIRM) end,
                                width = 'full',
                                order = self:GetOptionOrder('actions'),
                            },
                        },
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
                        fontSize = 'medium',
                        order = self:GetOptionOrder('about'),
                        width = 'half',
                    },
                    about_info_version = {
                        type = 'description',
                        name = ADDON_VERSION,
                        fontSize = 'medium',
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
                        fontSize = 'medium',
                        order = self:GetOptionOrder('about'),
                        width = 'half',
                    },
                    about_info_author = {
                        type = 'description',
                        name = C_AddOns.GetAddOnMetadata('TitanFarmBuddy', 'Author'),
                        fontSize = 'medium',
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
                        name = TitanUtils_GetGoldText(L['FARM_BUDDY_LOCALIZATION']),
                        fontSize = 'large',
                        order = self:GetOptionOrder('about'),
                        width = 'full',
                    },
                    about_space_4 = {
                        type = 'description',
                        name = '\n',
                        order = self:GetOptionOrder('about'),
                    },
                    about_info_localization_deDE = {
                        type = 'description',
                        name = TitanUtils_GetGreenText(L['FARM_BUDDY_GERMAN']),
                        fontSize = 'medium',
                        order = self:GetOptionOrder('about'),
                        width = 'full',
                    },
                    about_info_localization_supporters_deDE = {
                        type = 'description',
                        name = '   • Keldor',
                        fontSize = 'medium',
                        order = self:GetOptionOrder('about'),
                        width = 'full',
                    },
                    about_space_5 = {
                        type = 'description',
                        name = '\n',
                        order = self:GetOptionOrder('about'),
                    },
                    about_info_localization_enUS = {
                        type = 'description',
                        name = TitanUtils_GetGreenText(L['FARM_BUDDY_ENGLISH']),
                        fontSize = 'medium',
                        order = self:GetOptionOrder('about'),
                        width = 'full',
                    },
                    about_info_localization_supporters_enUS = {
                        type = 'description',
                        name = '   • Keldor',
                        fontSize = 'medium',
                        order = self:GetOptionOrder('about'),
                        width = 'full',
                    },
                    about_space_6 = {
                        type = 'description',
                        name = '\n',
                        order = self:GetOptionOrder('about'),
                    },
                    about_info_localization_ruRU = {
                        type = 'description',
                        name = TitanUtils_GetGreenText(L['FARM_BUDDY_RUSSIAN']),
                        fontSize = 'medium',
                        order = self:GetOptionOrder('about'),
                        width = 'full',
                    },
                    about_info_localization_supporters_ruRU = {
                        type = 'description',
                        name = '   • ZamestoTV',
                        fontSize = 'medium',
                        order = self:GetOptionOrder('about'),
                        width = 'full',
                    },
                    about_space_7 = {
                        type = 'description',
                        name = '\n',
                        order = self:GetOptionOrder('about'),
                    },
                    about_info_support_title = {
                        type = 'description',
                        name = TitanUtils_GetGoldText(L['FARM_BUDDY_SUPPORT']),
                        fontSize = 'large',
                        order = self:GetOptionOrder('about'),
                        width = 'full',
                    },
                    about_info_support_text = {
                        type = 'description',
                        name = '   • ' .. L['FARM_BUDDY_SUPPORT_TEXT'],
                        fontSize = 'medium',
                        order = self:GetOptionOrder('about'),
                        width = 'full',
                    },
                    about_space_8 = {
                        type = 'description',
                        name = '\n',
                        order = self:GetOptionOrder('about'),
                    },
                    about_info_chat_commands_title = {
                        type = 'description',
                        name = TitanUtils_GetGoldText(L['FARM_BUDDY_CHAT_COMMANDS']),
                        fontSize = 'large',
                        order = self:GetOptionOrder('about'),
                        width = 'full',
                    },
                    about_info_chat_commands = {
                        type = 'description',
                        name = self:GetChatCommandsHelp(false),
                        fontSize = 'medium',
                        order = self:GetOptionOrder('about'),
                        width = 'full',
                    },
                }
            },
        }
    }
end

---Sets the notification sound.
---@param input number The sound kit id.
function TitanFarmBuddy:SetNotificationSound(info, input)
    self:SetSettingsValue(info, input)
    PlaySound(input, 'master')
end

---Gets the notification sound.
---@param info table The info table containing the key to get.
---@return number sound
function TitanFarmBuddy:GetNotificationSound(info)
    local sound = TitanGetVar(TITAN_FARM_BUDDY_ID, info.arg.key)
    if not sound or not NOTIFICATION_SOUNDS[sound] then
        return SOUNDKIT.ALARM_CLOCK_WARNING_3
    end

    return sound
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

---Sets the fast tracking shortcut key.
---@param info table The info table containing the key to set.
---@param key string The modifier key.
---@param state boolean Whether the modifier key is required.
function TitanFarmBuddy:SetKeySetting(info, key, state)
    local options = TitanGetVar(TITAN_FARM_BUDDY_ID, info.arg.key)

    if options[key] ~= nil then
        options[key] = state
    end

    TitanSetVar(TITAN_FARM_BUDDY_ID, info.arg.key, options)
end

---Gets the fast tracking shortcut key.
---@param info table The info table containing the key to get.
---@param key string The modifier key.
---@return boolean state
function TitanFarmBuddy:GetKeySetting(info, key)
    local options = TitanGetVar(TITAN_FARM_BUDDY_ID, info.arg.key)
    return options[key] or false
end

---Dynamically builds the tracked item option fields based on ITEMS_AVAILABLE.
---@return table args
function TitanFarmBuddy:GetTrackedItemsArgs()
    local args = {
        items_tracking_description = {
            type = 'description',
            name = string.gsub(L['FARM_BUDDY_TRACKING_DESC'], '!amount!', ITEMS_AVAILABLE),
            fontSize = 'medium',
            order = self:GetOptionOrder('items'),
        },
        items_tracking_space_1 = {
            type = 'description',
            name = '\n',
            order = self:GetOptionOrder('items'),
        },
        tracking_cache_warning = {
            type = 'description',
            name = '|cffffd100' .. L['FARM_BUDDY_TRACKING_CACHE_WARNING'] .. '|r',
            fontSize = 'medium',
            image = 'Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew',
            imageWidth = 20,
            imageHeight = 20,
            order = self:GetOptionOrder('items'),
        },
        items_tracking_space_2 = {
            type = 'description',
            name = '\n',
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
        get = function()
            if self:IsItemLoading(index) then
                return L['FARM_BUDDY_ITEM_LOADING']
            end

            return self:GetItem(index)
        end,
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
    local quantity = tonumber(input)
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'ItemQuantity' .. index, quantity)
    TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)

    local item = self:GetItem(index)
    local itemInfo = (item and item ~= '') and self:GetItemInfo(item) or nil

    self:SetNotificationTriggered(index, itemInfo and quantity and quantity > 0 and self:GetCount(itemInfo) >= quantity)
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

---Sets a value for a given key.
---@param info table The info table containing the key to set.
---@param value any The value to set.
function TitanFarmBuddy:SetSettingsValue(info, value)
    if info.arg.numeric then
        value = tonumber(value)
    end

    TitanSetVar(TITAN_FARM_BUDDY_ID, info.arg.key, value)
    TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
end

---Gets a value for a given key.
---@param info table The info table containing the key to get.
---@return any value
function TitanFarmBuddy:GetSettingsValue(info)
    local value = TitanGetVar(TITAN_FARM_BUDDY_ID, info.arg.key)

    if info.type == 'input' then
        return tostring(value)
    end

    return value
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

---Notifies the settings GUI that a change has been made.
function TitanFarmBuddy:NotifySettingsChanged()
    CONFIG_REG:NotifyChange(ADDON_NAME)
end

---Gets the Titan Plugin AddOn settings panel.
---@return table category
function TitanFarmBuddy_GetAddOnSettingsPanel()
    return ADDON_SETTING_PANEL
end
