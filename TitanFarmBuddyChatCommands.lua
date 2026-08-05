-- **************************************************************************
-- * TitanFarmBuddy.lua
-- *
-- * By: Keldor
-- **************************************************************************


local L = LibStub('AceLocale-3.0'):GetLocale('Titan', true)
local TitanFarmBuddy = LibStub('AceAddon-3.0'):GetAddon(TITAN_FARM_BUDDY_ID)
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

---Creates the chat commands.
function TitanFarmBuddy:InitChatCommands()
    self:RegisterChatCommand(CHAT_COMMAND, 'ChatCommand')
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
            self:NotifySettingsChanged()
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
                    self:NotifySettingsChanged()
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
                    local existingIndex = self:GetTrackedItemIndex(itemInfo.ItemID, index)
                    if existingIndex then
                        local text = L['FARM_BUDDY_ITEM_ALREADY_TRACKED']
                            :gsub('!itemName!', itemInfo.Link)
                            :gsub('!position!', existingIndex)
                        self:Print(text)
                    else
                        self:SetItem(index, nil, itemInfo.Name)
                        local text = L['FARM_BUDDY_ITEM_SET_MSG']:gsub('!itemName!', itemInfo.Link)
                        self:Print(text)
                    end
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

        if not printOut then
            helpStr = helpStr .. '   '
        end

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
