local L = LibStub('AceLocale-3.0'):NewLocale('Titan', 'esMX', false)
if not L then return end

L = L or {}
--Translation missing 
L["FARM_BUDDY_ABOUT"] = "About"
--Translation missing 
L["FARM_BUDDY_ACTIONS"] = "Actions"
--Translation missing 
L["FARM_BUDDY_ALERT_COUNT"] = "Quantity for Alert"
--Translation missing 
L["FARM_BUDDY_ALERT_COUNT_USAGE"] = "An quantity for your farming goal."
--Translation missing 
L["FARM_BUDDY_ANCHOR_HELP_TEXT"] = "Hold left mouse button to move. Right click to close."
--Translation missing 
L["FARM_BUDDY_AUTHOR"] = "Author"
--Translation missing 
L["FARM_BUDDY_BANK"] = "Bank"
--Translation missing 
L["FARM_BUDDY_CHAT_COMMANDS"] = "Chat Commands"
--Translation missing 
L["FARM_BUDDY_COMMAND_GOAL_ARGS"] = "Quantity"
--Translation missing 
L["FARM_BUDDY_COMMAND_GOAL_DESC"] = "Sets the goal quantity."
--Translation missing 
L["FARM_BUDDY_COMMAND_GOAL_PARAM_MISSING"] = "You have to set a quantity as second parameter."
--Translation missing 
L["FARM_BUDDY_COMMAND_HELP_DESC"] = "Prints this information."
--Translation missing 
L["FARM_BUDDY_COMMAND_LIST"] = "List of Chat Commands"
--Translation missing 
L["FARM_BUDDY_COMMAND_PRIMARY_ARGS"] = "Position between 1 and !max!"
--Translation missing 
L["FARM_BUDDY_COMMAND_PRIMARY_DESC"] = "Sets the items position that would be shown in the Titan Panel bar."
--Translation missing 
L["FARM_BUDDY_COMMAND_RESET_ARGS"] = "all | items"
--Translation missing 
L["FARM_BUDDY_COMMAND_RESET_DESC"] = "Resets Farm Buddy to it's default settings."
--Translation missing 
L["FARM_BUDDY_COMMAND_TRACK_ARGS"] = "Item Name|Item Link"
--Translation missing 
L["FARM_BUDDY_COMMAND_TRACK_DESC"] = "Sets the tracked item."
--Translation missing 
L["FARM_BUDDY_COMMAND_VERSION_DESC"] = "Show the current used Farm Buddy Version."
--Translation missing 
L["FARM_BUDDY_CONFIG_RESET_MSG"] = "The configuration has been set back to the defaults."
--Translation missing 
L["FARM_BUDDY_GERMAN"] = "German"
--Translation missing 
L["FARM_BUDDY_GOAL_SET"] = "The goal quantity has been set."
--Translation missing 
L["FARM_BUDDY_INCLUDE_BANK"] = "Include items in your bank"
--Translation missing 
L["FARM_BUDDY_INCLUDE_BANK_DESC"] = "If enabled items in your bank are included when counting the farmed item."
--Translation missing 
L["FARM_BUDDY_INVALID_NUMBER"] = "The entered number is not a valid number."
--Translation missing 
L["FARM_BUDDY_INVENTORY"] = "Inventory"
--Translation missing 
L["FARM_BUDDY_ITEM"] = "Item"
--Translation missing 
L["FARM_BUDDY_ITEM_DISPLAY_STYLE"] = "Item Display Style in Titan Bar"
--Translation missing 
L["FARM_BUDDY_ITEM_DISPLAY_STYLE_1"] = "Only the primary Item"
--Translation missing 
L["FARM_BUDDY_ITEM_DISPLAY_STYLE_2"] = "Show all Items"
--Translation missing 
L["FARM_BUDDY_ITEM_DISPLAY_STYLE_DESC"] = "The item display style in the Titan Panel Bar."
--Translation missing 
L["FARM_BUDDY_ITEM_NOT_EXISTS"] = "The item does not exists."
--Translation missing 
L["FARM_BUDDY_ITEM_PRIMARY_SET_MSG"] = "The item on position !position! is now the primary item to display."
--Translation missing 
L["FARM_BUDDY_ITEM_SET_MSG"] = "!itemName! is now your tracked item!"
--Translation missing 
L["FARM_BUDDY_ITEM_SET_POSITION_MSG"] = "The entered position is not valid. Pleaser enter a position between 1 and max!."
--Translation missing 
L["FARM_BUDDY_ITEM_TO_TRACK_DESC"] = "The name of the item to track"
--Translation missing 
L["FARM_BUDDY_ITEM_TO_TRACK_USAGE"] = "Enter the name of an item or CTRL + Click an item from your inventory. Please note: The item have to be in your World of Warcraft Data Cache otherwise the item is not known to the AddOn API functions."
--Translation missing 
L["FARM_BUDDY_ITEMS"] = "Items"
--Translation missing 
L["FARM_BUDDY_LOCALIZATION"] = "Localization"
--Translation missing 
L["FARM_BUDDY_MOVE_NOTIFICATION"] = "Change Notification Position"
--Translation missing 
L["FARM_BUDDY_MOVE_NOTIFICATION_DESC"] = "Change the Position of the Notification Frame."
--Translation missing 
L["FARM_BUDDY_NO_GOAL"] = "No goal defined"
--Translation missing 
L["FARM_BUDDY_NO_ITEM_TRACKED"] = "You have no item for tracking selected."
--Translation missing 
L["FARM_BUDDY_NOTIFICATION"] = "Enable Notifications"
--Translation missing 
L["FARM_BUDDY_NOTIFICATION_DEMO_ITEM_NAME"] = "Hearthstone"
--Translation missing 
L["FARM_BUDDY_NOTIFICATION_DESC"] = "Shows a notification if the item quantity has reached."
--Translation missing 
L["FARM_BUDDY_NOTIFICATION_GLOW"] = "Show Glow Effect"
--Translation missing 
L["FARM_BUDDY_NOTIFICATION_GLOW_DESC"] = "Shows a glow effect if a notification is shown."
--Translation missing 
L["FARM_BUDDY_NOTIFICATION_SHINE"] = "Show Shine Effect"
--Translation missing 
L["FARM_BUDDY_NOTIFICATION_SHINE_DESC"] = "Shows a shine effect if a notification is shown."
--Translation missing 
L["FARM_BUDDY_NOTIFICATIONS"] = "Notifications"
--Translation missing 
L["FARM_BUDDY_PLAY_NOTIFICATION_DISPLAY_DURATION"] = "Notification Display Duration"
--Translation missing 
L["FARM_BUDDY_PLAY_NOTIFICATION_DISPLAY_DURATION_DESC"] = "The Notification Display Duration in seconds."
--Translation missing 
L["FARM_BUDDY_PLAY_NOTIFICATION_SOUND"] = "Play Notification Sound"
--Translation missing 
L["FARM_BUDDY_PLAY_NOTIFICATION_SOUND_DESC"] = "Play a notification sound file if the farm goal has reached."
--Translation missing 
L["FARM_BUDDY_QUANTITY"] = "Quantity"
--Translation missing 
L["FARM_BUDDY_RESET"] = "Reset"
--Translation missing 
L["FARM_BUDDY_RESET_ALL"] = "Reset settings to default"
--Translation missing 
L["FARM_BUDDY_RESET_ALL_DESC"] = "Reset all settings to their default values."
--Translation missing 
L["FARM_BUDDY_RESET_ALL_ITEMS"] = "Reset all tracked Items"
--Translation missing 
L["FARM_BUDDY_RESET_ALL_ITEMS_DESC"] = "Resets all tracked items."
--Translation missing 
L["FARM_BUDDY_RESET_DESC"] = "Resets the tracked item."
--Translation missing 
L["FARM_BUDDY_SETTINGS"] = "Common"
--Translation missing 
L["FARM_BUDDY_SHOW_COLORED_TEXT"] = "Show Colored Text"
--Translation missing 
L["FARM_BUDDY_SHOW_COLORED_TEXT_DESC"] = "Show the item count as colored text on the Titan Bar."
--Translation missing 
L["FARM_BUDDY_SHOW_GOAL"] = "Show Goal on Titan Bar"
--Translation missing 
L["FARM_BUDDY_SHOW_GOAL_DESC"] = "Show the goal quantity on the Titan Bar if a goal is defined."
--Translation missing 
L["FARM_BUDDY_SHOW_ICON"] = "Show icon"
--Translation missing 
L["FARM_BUDDY_SHOW_ICON_DESC"] = "Show the item icon on the Titan Bar."
--Translation missing 
L["FARM_BUDDY_SHOW_IN_BAR"] = "Primary"
--Translation missing 
L["FARM_BUDDY_SHOW_IN_BAR_DESC"] = "If this checkbox is enabled the items farm status will be shown on the Titan Panel bar."
--Translation missing 
L["FARM_BUDDY_SHOW_NAME"] = "Show item name"
--Translation missing 
L["FARM_BUDDY_SHOW_NAME_DESC"] = "Show the item name on the Titan Bar."
--Translation missing 
L["FARM_BUDDY_SUMMARY"] = "Summary"
--Translation missing 
L["FARM_BUDDY_TEST_NOTIFICATION"] = "Test Notification"
--Translation missing 
L["FARM_BUDDY_TEST_NOTIFICATION_DESC"] = "Triggers a test for the finish notification."
--Translation missing 
L["FARM_BUDDY_TOOLTIP_DESC"] = "Left click to open the Settings."
--Translation missing 
L["FARM_BUDDY_TOOLTIP_MODIFIER"] = "Alt + Right click on an item in your Bag to set item."
--Translation missing 
L["FARM_BUDDY_TOTAL"] = "Total"
--Translation missing 
L["FARM_BUDDY_TRACK_ITEM_PARAM_MISSING"] = "You have to set an Item Name or Item Link as second parameter."
--Translation missing 
L["FARM_BUDDY_TRACKING_DESC"] = "You can track up to 4 items at once and select one item that is shown in the titan bar the other items are shown in the tooltip of Farm Buddy."
--Translation missing 
L["FARM_BUDDY_VERSION"] = "Version"
--Translation missing 
L["TITAN_BUDDY_NOTIFICATION_SOUND"] = "Notification Sound"
--Translation missing 
L["TITAN_FARM_BUDDY_CANCEL"] = "Cancel"
--Translation missing 
L["TITAN_FARM_BUDDY_CHOOSE_ITEM_INDEX"] = "Please enter the Position where you want to place the clicked item. (1 - %s)"
--Translation missing 
L["TITAN_FARM_BUDDY_CONFIRM_ALL_RESET"] = "Are you sure you want to reset all settings to their default values?"
--Translation missing 
L["TITAN_FARM_BUDDY_CONFIRM_RESET"] = "Are you sure you want to reset all items?"
--Translation missing 
L["TITAN_FARM_BUDDY_NO"] = "No"
--Translation missing 
L["TITAN_FARM_BUDDY_OK"] = "OK"
--Translation missing 
L["TITAN_FARM_BUDDY_YES"] = "Yes"
