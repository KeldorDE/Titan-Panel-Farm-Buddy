-- **************************************************************************
-- * TitanFarmBuddyConst.lua
-- *
-- * By: Keldor
-- **************************************************************************

local L = LibStub('AceLocale-3.0'):GetLocale('Titan', true)

-- Addon information
TITAN_FARM_BUDDY_ID = 'FarmBuddy'
TITAN_FARM_BUDDY_ADDON_NAME = 'Titan Farm Buddy'

-- Settings
TITAN_FARM_BUDDY_ITEMS_AVAILABLE = 16
TITAN_FARM_BUDDY_NOTIFICATION_SOUNDS = {
    [SOUNDKIT.ALARM_CLOCK_WARNING_1]        = L['TITAN_FARM_BUDDY_SOUND_ALARM_1'],
    [SOUNDKIT.ALARM_CLOCK_WARNING_2]        = L['TITAN_FARM_BUDDY_SOUND_ALARM_2'],
    [SOUNDKIT.ALARM_CLOCK_WARNING_3]        = L['TITAN_FARM_BUDDY_SOUND_ALARM_3'],
    [SOUNDKIT.READY_CHECK]                  = L['TITAN_FARM_BUDDY_SOUND_READY_CHECK'],
    [SOUNDKIT.RAID_WARNING]                 = L['TITAN_FARM_BUDDY_SOUND_RAID_WARNING'],
    [SOUNDKIT.AUCTION_WINDOW_OPEN]          = L['TITAN_FARM_BUDDY_SOUND_AUCTION'],
    [SOUNDKIT.IG_QUEST_LIST_COMPLETE]       = L['TITAN_FARM_BUDDY_SOUND_QUEST_COMPLETE'],
    [SOUNDKIT.LFG_REWARDS]                  = L['TITAN_FARM_BUDDY_SOUND_DUNGEON_REWARD'],
    [SOUNDKIT.UI_EPICLOOT_TOAST]            = L['TITAN_FARM_BUDDY_SOUND_EPIC_LOOT'],
    [SOUNDKIT.UI_LEGENDARY_LOOT_TOAST]      = L['TITAN_FARM_BUDDY_SOUND_LEGENDARY_LOOT'],
}
TITAN_FARM_BUDDY_ITEM_DISPLAY_STYLES = {
    [1] = L['TITAN_FARM_BUDDY_ITEM_DISPLAY_STYLE_1'],
    [2] = L['TITAN_FARM_BUDDY_ITEM_DISPLAY_STYLE_2'],
}

-- Dialogs
TITAN_FARM_BUDDY_DIALOG_RESET_ALL_CONFIRM = 'TITAN_FARM_BUDDY_DIALOG_RESET_ALL_CONFIRM'
TITAN_FARM_BUDDY_DIALOG_RESET_ALL_ITEMS_CONFIRM = 'TITAN_FARM_BUDDY_DIALOG_RESET_ALL_ITEMS_CONFIRM'
TITAN_FARM_BUDDY_DIALOG_SET_ITEM_INDEX = 'TITAN_FARM_BUDDY_DIALOG_SET_ITEM_INDEX'

-- Chat commands
TITAN_FARM_BUDDY_CHAT_COMMAND = 'fb'
TITAN_FARM_BUDDY_CHAT_COMMANDS = {
    {
        Command = 'track',
        Args = '<' .. L['TITAN_FARM_BUDDY_COMMAND_PRIMARY_ARGS']:gsub('!max!', TITAN_FARM_BUDDY_ITEMS_AVAILABLE) .. '> <' .. L['TITAN_FARM_BUDDY_COMMAND_TRACK_ARGS'] .. '>',
        Description = L['TITAN_FARM_BUDDY_COMMAND_TRACK_DESC'],
        Handler = 'CmdTrackItem',
    },
    {
        Command = 'quantity',
        Args = '<' .. L['TITAN_FARM_BUDDY_COMMAND_PRIMARY_ARGS']:gsub('!max!', TITAN_FARM_BUDDY_ITEMS_AVAILABLE) .. '> <' .. L['TITAN_FARM_BUDDY_COMMAND_GOAL_ARGS'] .. '>',
        Description = L['TITAN_FARM_BUDDY_COMMAND_GOAL_DESC'],
        Handler = 'CmdSetQuantity',
    },
    {
        Command = 'primary',
        Args = '<' .. L['TITAN_FARM_BUDDY_COMMAND_PRIMARY_ARGS']:gsub('!max!', TITAN_FARM_BUDDY_ITEMS_AVAILABLE) .. '>',
        Description = L['TITAN_FARM_BUDDY_COMMAND_PRIMARY_DESC'],
        Handler = 'CmdSetPrimary',
    },
    {
        Command = 'settings',
        Args = '',
        Description = L['TITAN_FARM_BUDDY_COMMAND_SETTINGS_DESC'],
        Handler = 'CmdOpenSettings',
    },
    {
        Command = 'testNotification',
        Args = '',
        Description = L['TITAN_FARM_BUDDY_COMMAND_TEST_NOTIFICATION_DESC'],
        Handler = 'CmdTestNotification',
    },
    {
        Command = 'reset',
        Args = '<' .. L['TITAN_FARM_BUDDY_COMMAND_RESET_ARGS'] .. '>',
        Description = L['TITAN_FARM_BUDDY_COMMAND_RESET_DESC'],
        Handler = 'CmdReset',
    },
    {
        Command = 'version',
        Args = '',
        Description = L['TITAN_FARM_BUDDY_COMMAND_VERSION_DESC'],
        Handler = 'CmdVersion',
    },
    {
        Command = 'help',
        Args = '',
        Description = L['TITAN_FARM_BUDDY_COMMAND_HELP_DESC'],
        Handler = 'CmdHelp',
    }
}
