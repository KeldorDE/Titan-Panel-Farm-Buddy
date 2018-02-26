local L = LibStub('AceLocale-3.0'):NewLocale('Titan', 'enUS', true)
if not L then return end

L = L or {}
L["FARM_BUDDY_ABOUT"] = "About"
L["FARM_BUDDY_ACTIONS"] = "Actions"
L["FARM_BUDDY_ALERT_COUNT"] = "Quantity for Alert"
L["FARM_BUDDY_ALERT_COUNT_USAGE"] = "An quantity for your farming goal."
L["FARM_BUDDY_ANCHOR_HELP_TEXT"] = "Hold left mouse button to move. Right click to close."
L["FARM_BUDDY_AUTHOR"] = "Author"
L["FARM_BUDDY_BANK"] = "Bank"
L["FARM_BUDDY_CHAT_COMMANDS"] = "Chat Commands"
L["FARM_BUDDY_COMMAND_GOAL_ARGS"] = "Quantity"
L["FARM_BUDDY_COMMAND_GOAL_DESC"] = "Sets the goal quantity."
L["FARM_BUDDY_COMMAND_GOAL_PARAM_MISSING"] = "You have to set a quantity as second parameter."
L["FARM_BUDDY_COMMAND_HELP_DESC"] = "Prints this information."
L["FARM_BUDDY_COMMAND_LIST"] = "List of Chat Commands"
L["FARM_BUDDY_COMMAND_PRIMARY_ARGS"] = "Position between 1 and !max!"
L["FARM_BUDDY_COMMAND_PRIMARY_DESC"] = "Sets the items position that would be shown in the Titan Panel bar."
L["FARM_BUDDY_COMMAND_RESET_ARGS"] = "all | items"
L["FARM_BUDDY_COMMAND_RESET_DESC"] = "Resets Farm Buddy to it's default settings."
L["FARM_BUDDY_COMMAND_SETTINGS_DESC"] = "Open up the AddOn settings page."
L["FARM_BUDDY_COMMAND_TRACK_ARGS"] = "Item Name|Item Link"
L["FARM_BUDDY_COMMAND_TRACK_DESC"] = "Sets the tracked item."
L["FARM_BUDDY_COMMAND_VERSION_DESC"] = "Show the current used Farm Buddy Version."
L["FARM_BUDDY_CONFIG_RESET_MSG"] = "The configuration has been set back to the defaults."
L["FARM_BUDDY_FAST_TRACKING_MOUSE_BUTTON"] = "Fast tracking mouse button"
L["FARM_BUDDY_FAST_TRACKING_SHORTCUTS"] = "Fast tracking shortcuts"
L["FARM_BUDDY_FAST_TRACKING_SHORTCUTS_DESC"] = "Combine your desired keys as a fast tracking shortcut. Fast tracking allows you to track an item from your inventory with these shortcut."
L["FARM_BUDDY_GERMAN"] = "German"
L["FARM_BUDDY_GOAL_SET"] = "The goal quantity has been set."
L["FARM_BUDDY_INCLUDE_BANK"] = "Include items in your bank"
L["FARM_BUDDY_INCLUDE_BANK_DESC"] = "If enabled items in your bank are included when counting the farmed item."
L["FARM_BUDDY_INVALID_NUMBER"] = "The entered number is not a valid number."
L["FARM_BUDDY_INVENTORY"] = "Inventory"
L["FARM_BUDDY_ITEM"] = "Item"
L["FARM_BUDDY_ITEM_DISPLAY_STYLE"] = "Item Display Style in Titan Bar"
L["FARM_BUDDY_ITEM_DISPLAY_STYLE_1"] = "Only the primary Item"
L["FARM_BUDDY_ITEM_DISPLAY_STYLE_2"] = "Show all Items"
L["FARM_BUDDY_ITEM_DISPLAY_STYLE_DESC"] = "The item display style in the Titan Panel Bar."
L["FARM_BUDDY_ITEM_NOT_EXISTS"] = "The item does not exists."
L["FARM_BUDDY_ITEM_PRIMARY_SET_MSG"] = "The item on position !position! is now the primary item to display."
L["FARM_BUDDY_ITEM_SET_MSG"] = "!itemName! is now your tracked item!"
L["FARM_BUDDY_ITEM_SET_POSITION_MSG"] = "The entered position is not valid. Pleaser enter a position between 1 and max!."
L["FARM_BUDDY_ITEM_TO_TRACK_DESC"] = "The name of the item to track"
L["FARM_BUDDY_ITEM_TO_TRACK_USAGE"] = "Enter the name of an item or CTRL + Click an item from your inventory. Please note: The item have to be in your World of Warcraft Data Cache otherwise the item is not known to the AddOn API functions."
L["FARM_BUDDY_ITEMS"] = "Items"
L["FARM_BUDDY_KEY_ALT"] = "Alt"
L["FARM_BUDDY_KEY_CTRL"] = "Ctrl"
L["FARM_BUDDY_KEY_LEFT_MOUSE_BUTTON"] = "Left mouse button"
L["FARM_BUDDY_KEY_RIGHT_MOUSE_BUTTON"] = "Right mouse button"
L["FARM_BUDDY_KEY_SHIFT"] = "Shift"
L["FARM_BUDDY_LOCALIZATION"] = "Localization"
L["FARM_BUDDY_MOVE_NOTIFICATION"] = "Change Notification Position"
L["FARM_BUDDY_MOVE_NOTIFICATION_DESC"] = "Change the Position of the Notification Frame."
L["FARM_BUDDY_NO_GOAL"] = "No goal defined"
L["FARM_BUDDY_NO_ITEM_TRACKED"] = "You have no item for tracking selected."
L["FARM_BUDDY_NOTIFICATION"] = "Enable Notifications"
L["FARM_BUDDY_NOTIFICATION_DEMO_ITEM_NAME"] = "Hearthstone"
L["FARM_BUDDY_NOTIFICATION_DESC"] = "Shows a notification if the item quantity has reached."
L["FARM_BUDDY_NOTIFICATION_GLOW"] = "Show Glow Effect"
L["FARM_BUDDY_NOTIFICATION_GLOW_DESC"] = "Shows a glow effect if a notification is shown."
L["FARM_BUDDY_NOTIFICATION_SHINE"] = "Show Shine Effect"
L["FARM_BUDDY_NOTIFICATION_SHINE_DESC"] = "Shows a shine effect if a notification is shown."
L["FARM_BUDDY_NOTIFICATIONS"] = "Notifications"
L["FARM_BUDDY_PLAY_NOTIFICATION_DISPLAY_DURATION"] = "Notification Display Duration"
L["FARM_BUDDY_PLAY_NOTIFICATION_DISPLAY_DURATION_DESC"] = "The Notification Display Duration in seconds."
L["FARM_BUDDY_PLAY_NOTIFICATION_SOUND"] = "Play Notification Sound"
L["FARM_BUDDY_PLAY_NOTIFICATION_SOUND_DESC"] = "Play a notification sound file if the farm goal has reached."
L["FARM_BUDDY_QUANTITY"] = "Quantity"
L["FARM_BUDDY_RESET"] = "Reset"
L["FARM_BUDDY_RESET_ALL"] = "Reset settings to default"
L["FARM_BUDDY_RESET_ALL_DESC"] = "Reset all settings to default values."
L["FARM_BUDDY_RESET_ALL_ITEMS"] = "Reset all tracked Items"
L["FARM_BUDDY_RESET_ALL_ITEMS_DESC"] = "Resets all tracked items."
L["FARM_BUDDY_RESET_DESC"] = "Resets the tracked item."
L["FARM_BUDDY_SETTINGS"] = "Common"
L["FARM_BUDDY_SHORTCUTS"] = "Shortcuts"
L["FARM_BUDDY_SHOW_COLORED_TEXT"] = "Show Colored Text"
L["FARM_BUDDY_SHOW_COLORED_TEXT_DESC"] = "Show the item count as colored text on the Titan Bar."
L["FARM_BUDDY_SHOW_GOAL"] = "Show Goal on Titan Bar"
L["FARM_BUDDY_SHOW_GOAL_DESC"] = "Show the goal quantity on the Titan Bar if a goal is defined."
L["FARM_BUDDY_SHOW_ICON"] = "Show icon"
L["FARM_BUDDY_SHOW_ICON_DESC"] = "Show the item icon on the Titan Bar."
L["FARM_BUDDY_SHOW_IN_BAR"] = "Primary"
L["FARM_BUDDY_SHOW_IN_BAR_DESC"] = "If this checkbox is enabled the items farm status will be shown on the Titan Panel bar."
L["FARM_BUDDY_SHOW_NAME"] = "Show item name"
L["FARM_BUDDY_SHOW_NAME_DESC"] = "Show the item name on the Titan Bar."
L["FARM_BUDDY_SUMMARY"] = "Summary"
L["FARM_BUDDY_TEST_NOTIFICATION"] = "Test Notification"
L["FARM_BUDDY_TEST_NOTIFICATION_DESC"] = "Triggers a test for the finish notification."
L["FARM_BUDDY_TOOLTIP_DESC"] = "Left click to open the Settings."
L["FARM_BUDDY_TOOLTIP_MODIFIER"] = "Alt + Right click on an item in your Bag to set item."
L["FARM_BUDDY_TOTAL"] = "Total"
L["FARM_BUDDY_TRACK_ITEM_PARAM_MISSING"] = "You have to set an Item Name or Item Link as second parameter."
L["FARM_BUDDY_TRACKING_DESC"] = "You can track up to 4 items at once and select one item that is shown in the titan bar the other items are shown in the tooltip of Farm Buddy."
L["FARM_BUDDY_VERSION"] = "Version"
L["TITAN_BUDDY_NOTIFICATION_SOUND"] = "Notification Sound"
L["TITAN_FARM_BUDDY_CANCEL"] = "Cancel"
L["TITAN_FARM_BUDDY_CHOOSE_ITEM_INDEX"] = "Please enter the Position where you want to place the clicked item. (1 - %s)"
L["TITAN_FARM_BUDDY_CONFIRM_ALL_RESET"] = "Are you sure you want to reset all settings to default values?"
L["TITAN_FARM_BUDDY_CONFIRM_RESET"] = "Are you sure you want to reset all items?"
L["TITAN_FARM_BUDDY_NO"] = "No"
L["TITAN_FARM_BUDDY_OK"] = "OK"
L["TITAN_FARM_BUDDY_YES"] = "Yes"
