-- **************************************************************************
-- * TitanFarmBuddy.lua
-- *
-- * By: Keldor
-- **************************************************************************

local L = LibStub('AceLocale-3.0'):GetLocale('Titan', true)
local TitanFarmBuddy = LibStub('AceAddon-3.0'):NewAddon(TITAN_FARM_BUDDY_ID, 'AceConsole-3.0', 'AceHook-3.0', 'AceTimer-3.0', 'AceEvent-3.0')
local OPTION_ORDER = {}
local NOTIFICATION_QUEUE = {}
local NOTIFICATION_TRIGGERED = {}
local ITEM_INFO_CACHE = {}
local ITEM_LOADING = {}
local ITEM_DATA_INIT_COMPLETE = false
local PLAYER_IN_COMBAT = false

---Gets the Titan Plugin AddOn name.
---@return string name
function TitanFarmBuddy_GetAddOnName()
    return ADDON_NAME
end

---Is called by AceAddon when the addon is first loaded.
function TitanFarmBuddy:OnInitialize()
    self:RegisterDialogs()
    self:InitSettings()
    self:InitChatCommands()

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
        name = ADDON_NAME,
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
            ChatGoalNotification = false,
            IncludeBank = false,
            IncludeWarbandBank = false,
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

            self:SetNotificationTriggered(i, itemInfo and quantity > 0 and self:GetCount(itemInfo) >= quantity)
        end

        TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
        ITEM_DATA_INIT_COMPLETE = true
    end)
end

---Registers the addon's dialog boxes.
function TitanFarmBuddy:RegisterDialogs()
    StaticPopupDialogs[TITAN_FARM_BUDDY_DIALOG_RESET_ALL_CONFIRM] = {
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

    StaticPopupDialogs[TITAN_FARM_BUDDY_DIALOG_RESET_ALL_ITEMS_CONFIRM] = {
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

    StaticPopupDialogs[TITAN_FARM_BUDDY_DIALOG_SET_ITEM_INDEX] = {
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
        EditBoxOnEnterPressed = function(editBox)
            local dialog = editBox:GetParent()

            self:SetItemIndexOnAccept(dialog, dialog.data)
            dialog:Hide()
        end,
        EditBoxOnEscapePressed = function(editBox)
            editBox:GetParent():Hide()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

--- Prints a message to the default chat frame with the addon's prefix.
--- @param msg string The message to print.
function TitanFarmBuddy:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cffFFD100" .. ADDON_NAME .. ":|r " .. tostring(msg))
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
        local existingIndex = self:GetTrackedItemIndex(data, index)
        if existingIndex then
            local text = L['FARM_BUDDY_ITEM_ALREADY_TRACKED']
                :gsub('!itemName!', data)
                :gsub('!position!', existingIndex)
            self:Print(text)
        else
            local text = L['FARM_BUDDY_ITEM_SET_MSG']:gsub('!itemName!', data)
            self:SetItem(index, nil, data)
            self:Print(text)
            self:NotifySettingsChanged()
        end
    else
        local text = L['FARM_BUDDY_ITEM_SET_POSITION_MSG']:gsub('!max!', ITEMS_AVAILABLE)
        self:Print(text)
    end
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
        str = str .. ' ' .. (showColoredText and self:GetNameFromItemLink(itemInfo.Link) or itemInfo.Name)
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
        Settings.OpenToCategory(TitanFarmBuddy_GetAddOnSettingsPanel())
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

    local countWarbandBank = 0
    local countBags = C_Item.GetItemCount(static.ItemID)
    local countBank = C_Item.GetItemCount(static.ItemID, true)

    countBank = (countBank - countBags)

    if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
        countWarbandBank = C_Item.GetItemCount(static.ItemID, false, false, false, true)
        countWarbandBank = (countWarbandBank - countBags)
    end

    local countTotal = (countBags + countBank + countWarbandBank)

    return {
        ItemID = static.ItemID,
        Name = static.Name,
        Link = static.Link,
        IconFileDataID = static.IconFileDataID,
        CountBags = countBags,
        CountWarbandBank = countWarbandBank,
        CountBank = countBank,
        CountTotal = countTotal,
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
                local itemName = self:GetNameFromItemLink(itemInfo.Link) or itemInfo.Name

                if goal > 0 then
                    goalValue = goal
                end

                strTmp = strTmp .. '\n'
                strTmp = strTmp .. L['FARM_BUDDY_ITEM'] .. ':\t' .. TitanFarmBuddy:GetIconString(itemInfo.IconFileDataID, true) .. itemName .. '\n'
                strTmp = strTmp .. L['FARM_BUDDY_INVENTORY'] .. ':\t' .. TitanUtils_GetHighlightText(itemInfo.CountBags) .. '\n'
                strTmp = strTmp .. L['FARM_BUDDY_BANK'] .. ':\t' .. TitanUtils_GetHighlightText(itemInfo.CountBank) .. '\n'

                if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
                    strTmp = strTmp .. L['FARM_BUDDY_WARBAND_BANK'] .. ':\t' .. TitanUtils_GetHighlightText(itemInfo.CountWarbandBank) .. '\n'
                end

                strTmp = strTmp .. L['FARM_BUDDY_TOTAL'] .. ':\t' .. TitanUtils_GetHighlightText(itemInfo.CountTotal) .. '\n'
                strTmp = strTmp .. L['FARM_BUDDY_ALERT_COUNT'] .. ':\t' .. TitanUtils_GetHighlightText(goalValue) .. '\n'
                hasItem = true
            end
        end
    end

    if hasItem then
        str = str .. TitanUtils_GetHighlightText(L['FARM_BUDDY_SUMMARY'])
        str = str .. '\n'
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
    Titan_Menu.AddSelector(options, id, L['FARM_BUDDY_INCLUDE_WARBAND_BANK'], 'IncludeWarbandBank')

    -- Notifications
    local notifications = Titan_Menu.AddButton(root, L['FARM_BUDDY_NOTIFICATIONS'])
    Titan_Menu.AddSelector(notifications, id, L['FARM_BUDDY_NOTIFICATION'], 'GoalNotification')
    Titan_Menu.AddSelector(notifications, id, L['FARM_BUDDY_CHAT_NOTIFICATIONS'], 'ChatGoalNotification')
    Titan_Menu.AddDivider(notifications)
    Titan_Menu.AddSelector(notifications, id, L['FARM_BUDDY_NOTIFICATION_GLOW'], 'NotificationGlow')
    Titan_Menu.AddSelector(notifications, id, L['FARM_BUDDY_NOTIFICATION_SHINE'], 'NotificationShine')
    Titan_Menu.AddSelector(notifications, id, L['FARM_BUDDY_PLAY_NOTIFICATION_SOUND'], 'PlayNotificationSound')

    -- Actions
    local actions = Titan_Menu.AddButton(root, L['FARM_BUDDY_ACTIONS'])
    Titan_Menu.AddCommand(actions, id, L['FARM_BUDDY_TEST_NOTIFICATION'], function() self:TestNotification() end)
    Titan_Menu.AddDivider(actions)
    Titan_Menu.AddCommand(actions, id, L['FARM_BUDDY_RESET_ALL_ITEMS'], function() StaticPopup_Show(TITAN_FARM_BUDDY_DIALOG_RESET_ALL_ITEMS_CONFIRM) end)
    Titan_Menu.AddCommand(actions, id, L['FARM_BUDDY_RESET_ALL'], function() StaticPopup_Show(TITAN_FARM_BUDDY_DIALOG_RESET_ALL_CONFIRM) end)

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
                    self:QueueNotification(i, itemInfo, quantity)
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

    local count = itemInfo.CountBags

    if TitanGetVar(TITAN_FARM_BUDDY_ID, 'IncludeWarbandBank') then
        count = count + itemInfo.CountWarbandBank
    end

    if TitanGetVar(TITAN_FARM_BUDDY_ID, 'IncludeBank') then
        count = count + itemInfo.CountBank
    end

    return count
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

---Checks if the entered item is valid.
---@param input string The item id, name or link to validate.
---@return boolean valid
function TitanFarmBuddy:ValidateItem(_, input)
    -- Item ids do not need to be cached: validate them instantly here and load
    -- the full item data asynchronously in SetItem.
    local itemID = self:GetInputItemID(input)
    if itemID then
        if C_Item.GetItemInfoInstant(itemID) then
            return true
        end

        self:Print(L['FARM_BUDDY_ITEM_NOT_EXISTS'])
        return false
    end

    -- Item names and links have to be known already (unchanged behavior).
    local _, itemLink = C_Item.GetItemInfo(input)
    if itemLink then
        return true
    end

    self:Print(L['FARM_BUDDY_ITEM_NOT_EXISTS'])
    return false
end

---Gets the item.
---@param index number The tracked item slot index.
---@return string item
function TitanFarmBuddy:GetItem(index)
    return TitanGetVar(TITAN_FARM_BUDDY_ID, 'Item' .. index)
end

---Checks if the item in the given slot is currently being loaded from the server.
---@param index number The tracked item slot index.
---@return boolean loading
function TitanFarmBuddy:IsItemLoading(index)
    return ITEM_LOADING[index] ~= nil
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

---Returns the numeric item id if the given input is a bare item id (not a name or link).
---@param input string The item link, id or name.
---@return number|nil itemID
function TitanFarmBuddy:GetInputItemID(input)
    if type(input) == 'string' and input:find('|Hitem:') then
        return nil
    end

    return tonumber(input)
end

---Sets the item.
---@param index number The tracked item slot index.
---@param input string The item link, id or name.
function TitanFarmBuddy:SetItem(index, _, input)
    local itemID = self:GetInputItemID(input)

    -- Item ids might not be cached yet. If the data is already available apply
    -- it directly, otherwise fetch it asynchronously while showing a loading state.
    if itemID then
        local _, itemLink = C_Item.GetItemInfo(itemID)
        if itemLink then
            self:ApplyItem(index, itemLink)
        else
            self:LoadItemAsync(index, itemID)
        end

        return
    end

    -- Item links and names keep their previous behavior.
    self:ApplyItem(index, self:GetItemLink(input) or input)
end

---Applies the resolved item to the given slot and refreshes the UI.
---@param index number The tracked item slot index.
---@param value string The resolved item link or the raw input.
function TitanFarmBuddy:ApplyItem(index, value)
    ITEM_LOADING[index] = nil

    TitanSetVar(TITAN_FARM_BUDDY_ID, 'Item' .. index, value)
    TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
    self:SetNotificationTriggered(index, false)
    self:NotifySettingsChanged()
end

---Asynchronously loads the item data for the given item id and applies it once
---it is available. While loading, a placeholder is shown in the settings GUI.
---@param index number The tracked item slot index.
---@param itemID number The item id to load.
function TitanFarmBuddy:LoadItemAsync(index, itemID)
    ITEM_LOADING[index] = itemID
    self:NotifySettingsChanged()

    local item = Item:CreateFromItemID(itemID)
    item:ContinueOnItemLoad(function()
        -- Ignore outdated callbacks if the slot was changed or reset meanwhile.
        if ITEM_LOADING[index] ~= itemID then
            return
        end

        self:ApplyItem(index, item:GetItemLink() or tostring(itemID))
    end)
end

---Resets the item with the given index.
---@param index number The tracked item slot index.
function TitanFarmBuddy:ResetItem(index)
    ITEM_LOADING[index] = nil
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'Item' .. index, '')
    TitanSetVar(TITAN_FARM_BUDDY_ID, 'ItemQuantity' .. index, '0')

    if TitanGetVar(TITAN_FARM_BUDDY_ID, 'ItemShowInBarIndex') == index then
        TitanSetVar(TITAN_FARM_BUDDY_ID, 'ItemShowInBarIndex', 1)
    end

    TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
    self:SetNotificationTriggered(index, false)
    self:NotifySettingsChanged()
end

---Resets the saved config to the default values.
---@param itemsOnly boolean If true, only the tracked items are reset.
function TitanFarmBuddy:ResetConfig(itemsOnly)
    if not itemsOnly then
        TitanSetVar(TITAN_FARM_BUDDY_ID, 'GoalNotification', true)
        TitanSetVar(TITAN_FARM_BUDDY_ID, 'ChatGoalNotification', false)
        TitanSetVar(TITAN_FARM_BUDDY_ID, 'ShowQuantity', true)
        TitanSetVar(TITAN_FARM_BUDDY_ID, 'IncludeBank', false)
        TitanSetVar(TITAN_FARM_BUDDY_ID, 'IncludeWarbandBank', false)
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
        ITEM_LOADING[i] = nil
        TitanSetVar(TITAN_FARM_BUDDY_ID, 'Item' .. i, '')
        TitanSetVar(TITAN_FARM_BUDDY_ID, 'ItemQuantity' .. i, 0)
        self:SetNotificationTriggered(i, false)
    end

    TitanPanelButton_UpdateButton(TITAN_FARM_BUDDY_ID)
    self:NotifySettingsChanged()
end

---Sets the notification triggered status for the given index.
---@param index number The tracked item slot index.
---@param status boolean The notification triggered status.
function TitanFarmBuddy:SetNotificationTriggered(index, status)
    NOTIFICATION_TRIGGERED[index] = status
end

---Raises a test notification.
function TitanFarmBuddy:TestNotification()
    local itemInfo = self:GetItemInfo(L['FARM_BUDDY_NOTIFICATION_DEMO_ITEM_NAME'])
    self:ShowNotification(0, itemInfo, 200, true)
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
            local dialog = StaticPopup_Show(TITAN_FARM_BUDDY_DIALOG_SET_ITEM_INDEX, ITEMS_AVAILABLE)
            if dialog then
                dialog.data = itemLink
            end
        end
    end
end

---Queues a notification.
---@param index number The tracked item slot index.
---@param itemInfo string|number The item name or icon file data ID.
---@param quantity number The reached goal quantity.
function TitanFarmBuddy:QueueNotification(index, itemInfo, quantity)
    NOTIFICATION_QUEUE[index] = {
        Index = index,
        ItemInfo = itemInfo,
        Quantity = quantity,
    }
end

---Raises a notification.
---@param index number The tracked item slot index.
---@param itemInfo string|number The item name or icon file data ID.
---@param quantity number The reached goal quantity.
---@param demo boolean Whether this is a demo/test notification.
function TitanFarmBuddy:ShowNotification(index, itemInfo, quantity, demo)
    local notificationEnabled = TitanGetVar(TITAN_FARM_BUDDY_ID, 'GoalNotification')
    if (notificationEnabled and not NOTIFICATION_TRIGGERED[index]) or demo then

        local playSound = TitanGetVar(TITAN_FARM_BUDDY_ID, 'PlayNotificationSound')
        local notificationDisplayDuration = tonumber(TitanGetVar(TITAN_FARM_BUDDY_ID, 'NotificationDisplayDuration'))
        local notificationGlow = TitanGetVar(TITAN_FARM_BUDDY_ID, 'NotificationGlow')
        local notificationShine = TitanGetVar(TITAN_FARM_BUDDY_ID, 'NotificationShine')
        local chatNotification = TitanGetVar(TITAN_FARM_BUDDY_ID, 'ChatGoalNotification')
        local sound

        if playSound then
            sound = TitanGetVar(TITAN_FARM_BUDDY_ID, 'GoalNotificationSound')
        end

        if not demo then
            self:SetNotificationTriggered(index, true)
        end

        if chatNotification then
            local message = L["FARM_BUDDY_CHAT_NOTIFICATION_TEXT"]:gsub('!quantity!', quantity):gsub('!itemLink!', itemInfo.Link)
            self:Print(message)
        end

        TitanFarmBuddyNotification_Show(itemInfo.Name, itemInfo.IconFileDataID, quantity, sound, notificationDisplayDuration, notificationGlow, notificationShine)
    end
end

---Is called by the timer to handle the next notification.
function TitanFarmBuddy:NotificationTask()
    if not TitanFarmBuddyNotification_Shown() then
        for index, notification in pairs(NOTIFICATION_QUEUE) do
            if not TitanGetVar(TITAN_FARM_BUDDY_ID, 'HideNotificationInCombat') or not PLAYER_IN_COMBAT then
                self:ShowNotification(notification.Index, notification.ItemInfo, notification.Quantity, false)
            end
            NOTIFICATION_QUEUE[index] = nil
            break
        end
    end
end

---Returns the index status.
---@param index number The tracked item slot index.
---@return boolean valid
function TitanFarmBuddy:IsIndexValid(index)
    return index and index > 0 and index <= ITEMS_AVAILABLE
end

---Checks whether the given item is already tracked in one of the slots.
---@param item string|number The item link, id or name.
---@param ignoreIndex number|nil An optional slot index to skip during the check.
---@return number|nil index The slot index if already tracked, otherwise nil.
function TitanFarmBuddy:GetTrackedItemIndex(item, ignoreIndex)
    local itemInfo = self:GetItemInfo(item)
    if not itemInfo then
        return nil
    end

    for i = 1, ITEMS_AVAILABLE do
        if i ~= ignoreIndex then
            local trackedInfo = self:GetItemInfo(self:GetItem(i))
            if trackedInfo and trackedInfo.ItemID == itemInfo.ItemID then
                return i
            end
        end
    end

    return nil
end
