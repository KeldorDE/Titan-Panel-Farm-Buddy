-- **************************************************************************
-- * Notification.lua
-- *
-- * By: Keldor
-- **************************************************************************

local TITAN_FARM_BUDDY_ID = TitanFamrBuddyButton_GetID();
local FarmBuddyNotification = LibStub('AceAddon-3.0'):NewAddon('FarmBuddyNotification', 'AceTimer-3.0');
local FRAME_NAME = 'TitanFarmBuddyFrame';
local FRAME = CreateFrame('Button', FRAME_NAME, UIParent, 'TitanFarmBuddyAlertFrameTemplate');

-- TODO: There is a bug where the notification is immediately hidden when showing every second time.
-- TODO: There is a bug that changes the opacity of the notification icon.

-- **************************************************************************
-- NAME : TitanFarmBuddyNotification_Show()
-- DESC : Shows a notification frame for the given item link.
-- **************************************************************************
function TitanFarmBuddyNotification_Show(itemName, goal)

  TitanFarmBuddyNotification_HideNotification();

  local itemInfo = TitanPanelFarmBuddyButton_GetItemInfo(itemName)
  if itemInfo ~= nil then

    TitanFarmBuddy_SetTitle(TitanFamrBuddyButton_GetAddOnName())
    TitanFarmBuddy_SetWidth(400);
    TitanFarmBuddy_SetText(goal .. ' ' .. itemInfo.Name);
    TitanFarmBuddy_SetIcon(itemInfo.IconFileDataID);

    UIFrameFadeIn(FRAME, 1, 0, 1);
    FarmBuddyNotification:ScheduleTimer('HideNotification', 5);
  end
end

-- **************************************************************************
-- NAME : FarmBuddyNotification:HideNotification()
-- DESC : Hides the active notification frame.
-- **************************************************************************
function FarmBuddyNotification:HideNotification()

  if FRAME:IsShown() then
    UIFrameFadeOut(FRAME, 0.2, 1, 0);
    TitanFarmBuddyNotification_HideNotification();
  end
end

-- **************************************************************************
-- NAME : TitanFarmBuddyNotification_HideNotification()
-- DESC : Resets the timer and hides the notification.
-- **************************************************************************
function TitanFarmBuddyNotification_HideNotification()
  FarmBuddyNotification:CancelAllTimers();
  FRAME:Hide();
end

-- **************************************************************************
-- NAME : TitanFarmBuddyNotification_OnClick()
-- DESC : This function is fired when the user clicks on the notification.
-- **************************************************************************
function TitanFarmBuddyNotification_OnClick(self, button, down)
  FarmBuddyNotification:HideNotification();
end

-- **************************************************************************
-- NAME : TitanFarmBuddy_SetTitle()
-- DESC : Sets the notification title.
-- **************************************************************************
function TitanFarmBuddy_SetTitle(title)
  FRAME.unlocked:SetText(title);
end

-- **************************************************************************
-- NAME : TitanFarmBuddy_SetText()
-- DESC : Sets the notification text.
-- **************************************************************************
function TitanFarmBuddy_SetText(text)
   _G[FRAME_NAME .. 'Name']:SetText(text);
end

-- **************************************************************************
-- NAME : TitanFarmBuddy_SetIcon()
-- DESC : Sets the notification icon.
-- **************************************************************************
function TitanFarmBuddy_SetIcon(icon)
   _G[FRAME_NAME .. 'IconTexture']:SetTexture(icon);
end

-- **************************************************************************
-- NAME : TitanFarmBuddy_SetWidth()
-- DESC : Sets the notification frame width.
-- **************************************************************************
function TitanFarmBuddy_SetWidth(width)
   FRAME:SetWidth(400);
end
