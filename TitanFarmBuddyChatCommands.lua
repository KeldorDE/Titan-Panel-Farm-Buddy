-- **************************************************************************
-- * TitanFarmBuddy.lua
-- *
-- * By: Keldor
-- **************************************************************************


---@class TitanFarmBuddy : AceConsole, AceEvent, AceHook, AceTimer
local TitanFarmBuddy = LibStub('AceAddon-3.0'):GetAddon(TITAN_FARM_BUDDY_ID)
local L = LibStub('AceLocale-3.0'):GetLocale('Titan', true)
local CHAT_COMMAND = 'fb'
local CHAT_COMMANDS = {
    {
        Command = 'track',
        Args = '<' .. L['FARM_BUDDY_COMMAND_PRIMARY_ARGS']:gsub('!max!', ITEMS_AVAILABLE) .. '> <' .. L['FARM_BUDDY_COMMAND_TRACK_ARGS'] .. '>',
        Description = L['FARM_BUDDY_COMMAND_TRACK_DESC'],
        Handler = 'CmdTrackItem',
    },
    {
        Command = 'quantity',
        Args = '<' .. L['FARM_BUDDY_COMMAND_PRIMARY_ARGS']:gsub('!max!', ITEMS_AVAILABLE) .. '> <' .. L['FARM_BUDDY_COMMAND_GOAL_ARGS'] .. '>',
        Description = L['FARM_BUDDY_COMMAND_GOAL_DESC'],
        Handler = 'CmdSetQuantity',
    },
    {
        Command = 'primary',
        Args = '<' .. L['FARM_BUDDY_COMMAND_PRIMARY_ARGS']:gsub('!max!', ITEMS_AVAILABLE) .. '>',
        Description = L['FARM_BUDDY_COMMAND_PRIMARY_DESC'],
        Handler = 'CmdSetPrimary',
    },
    {
        Command = 'settings',
        Args = '',
        Description = L['FARM_BUDDY_COMMAND_SETTINGS_DESC'],
        Handler = 'CmdOpenSettings',
    },
    {
        Command = 'testNotification',
        Args = '',
        Description = L['FARM_BUDDY_COMMAND_TEST_NOTIFICATION_DESC'],
        Handler = 'CmdTestNotification',
    },
    {
        Command = 'reset',
        Args = '<' .. L['FARM_BUDDY_COMMAND_RESET_ARGS'] .. '>',
        Description = L['FARM_BUDDY_COMMAND_RESET_DESC'],
        Handler = 'CmdReset',
    },
    {
        Command = 'version',
        Args = '',
        Description = L['FARM_BUDDY_COMMAND_VERSION_DESC'],
        Handler = 'CmdVersion',
    },
    {
        Command = 'help',
        Args = '',
        Description = L['FARM_BUDDY_COMMAND_HELP_DESC'],
        Handler = 'CmdHelp',
    }
}

-- Maps command names to their entry for quick lookup, derived from the ordered CHAT_COMMANDS list.
local CHAT_COMMANDS_BY_NAME = {}
for _, entry in ipairs(CHAT_COMMANDS) do
    CHAT_COMMANDS_BY_NAME[entry.Command] = entry
end

---Creates the chat commands.
function TitanFarmBuddy:InitChatCommands()
    self:RegisterChatCommand(CHAT_COMMAND, 'ChatCommand')
end

---Handles AddOn commands.
---@param input string The raw chat command input.
function TitanFarmBuddy:ChatCommand(input)
    local cmd, value, arg1 = self:GetArgs(input, 3)
    local entry = CHAT_COMMANDS_BY_NAME[cmd] or CHAT_COMMANDS_BY_NAME.help
    self[entry.Handler](self, value, arg1)
end

--- Sets the tracked item for a specific position.
---@param positionIndex string The position of the item to set as tracked.
---@param item string The item to track (can be an item ID, name, or link).
function TitanFarmBuddy:CmdTrackItem(positionIndex, item)
    local index = tonumber(positionIndex) or 0
    if not self:IsIndexValid(index) then
        local text = L['FARM_BUDDY_ITEM_SET_POSITION_MSG']:gsub('!max!', ITEMS_AVAILABLE)
        self:Print(text)
        return
    end

    local itemInfo = self:GetItemInfo(item)
    if not itemInfo then
        self:Print(L['FARM_BUDDY_ITEM_NOT_EXISTS'])
        return
    end

    local existingIndex = self:GetTrackedItemIndex(itemInfo.ItemID, index)
    if existingIndex then
        local text = L['FARM_BUDDY_ITEM_ALREADY_TRACKED']
            :gsub('!itemName!', itemInfo.Link)
            :gsub('!position!', existingIndex)
        self:Print(text)
    else
        self:SetItem(index, itemInfo.Name)
        local text = L['FARM_BUDDY_ITEM_SET_MSG']:gsub('!itemName!', itemInfo.Link)
        self:Print(text)
    end
end

--- Sets the goal quantity for a specific item.
---@param positionIndex string The position of the item to set the goal quantity for.
---@param quantity string The goal quantity to set.
function TitanFarmBuddy:CmdSetQuantity(positionIndex, quantity)
    local index = tonumber(positionIndex) or 0
    local goalQuantity = tonumber(quantity) or 0

    if self:IsIndexValid(index) then
        if goalQuantity > 0 then
            self:SetItemQuantity(index, goalQuantity)
            TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
            self:NotifySettingsChanged()
            self:Print(L['FARM_BUDDY_GOAL_SET'])
        else
            self:Print(L['FARM_BUDDY_COMMAND_GOAL_PARAM_MISSING'])
        end
    else
        local text = L['FARM_BUDDY_ITEM_SET_POSITION_MSG']:gsub('!max!', ITEMS_AVAILABLE)
        self:Print(text)
    end
end

--- Sets the primary item to display in the Titan Panel bar.
---@param positionIndex string The position of the item to set as primary.
function TitanFarmBuddy:CmdSetPrimary(positionIndex)
    local index = tonumber(positionIndex) or 0

    if self:IsIndexValid(index) then
        local text = L['FARM_BUDDY_ITEM_PRIMARY_SET_MSG']:gsub('!position!', index)
        TitanSetVar(TITAN_FARM_BUDDY_ID, 'ItemShowInBarIndex', index)
        self:Print(text)
        TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
        self:NotifySettingsChanged()
    else
        local text = L['FARM_BUDDY_ITEM_SET_POSITION_MSG']:gsub('!max!', ITEMS_AVAILABLE)
        self:Print(text)
    end
end

--- Opens the AddOn settings.
function TitanFarmBuddy:CmdOpenSettings()
    Settings.OpenToCategory(TitanFarmBuddy_GetAddOnSettingsPanel())
end

--- Prints a test notification.
function TitanFarmBuddy:CmdTestNotification()
    self:TestNotification()
end

---Resets the AddOn settings.
---@param resetType string The reset type. Can be 'all' or 'items'.
function TitanFarmBuddy:CmdReset(resetType)
    if resetType == 'all' then
        self:ResetConfig(false)
    else
        self:ResetConfig(true)
    end

    self:Print(L['FARM_BUDDY_CONFIG_RESET_MSG'])
end

--- Prints the AddOn version information.
function TitanFarmBuddy:CmdVersion()
    self:Print(C_AddOns.GetAddOnMetadata('TitanFarmBuddy', 'Version'))
end

--- Prints the AddOn helptext.
function TitanFarmBuddy:CmdHelp()
    self:Print(L['FARM_BUDDY_COMMAND_LIST'] .. '\n')
    self:GetChatCommandsHelp(true)
end

---Returns the help text of the chat commands.
---@param printOut boolean If true, each line is printed to the chat frame.
---@return string helpText
function TitanFarmBuddy:GetChatCommandsHelp(printOut)
    local helpStr = ''

    for _, info in ipairs(CHAT_COMMANDS) do

        if not printOut then
            helpStr = helpStr .. '   '
        end

        helpStr = helpStr .. TitanUtils_GetGreenText('/' .. CHAT_COMMAND) .. ' ' .. TitanUtils_GetHexText(info.Command, '4fbcd5')
        if info.Args ~= '' then
            helpStr = helpStr .. ' ' .. TitanUtils_GetGoldText(info.Args)
        end
        helpStr = helpStr .. ' - ' .. info.Description
        if printOut then
            DEFAULT_CHAT_FRAME:AddMessage(helpStr)
            helpStr = ''
        else
            helpStr = helpStr .. '\n'
        end
    end

    return helpStr
end
