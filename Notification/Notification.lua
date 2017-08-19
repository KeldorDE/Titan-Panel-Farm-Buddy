-- **************************************************************************
-- * Notification.lua
-- *
-- * By: Keldor
-- **************************************************************************

local L = LibStub('AceLocale-3.0'):GetLocale('Titan', true);
local FarmBuddyNotification = LibStub('AceAddon-3.0'):NewAddon('FarmBuddyNotification', 'AceTimer-3.0');
local FRAME_NAME = 'TitanFarmBuddyAlertFrameTemplate';
local FRAME = CreateFrame('Button', FRAME_NAME, UIParent, 'TitanFarmBuddyAlertFrameTemplate');


-- **************************************************************************
-- NAME : TitanFarmBuddyNotification_Show()
-- DESC : Shows a notification frame for the given item link.
-- **************************************************************************
function TitanFarmBuddyNotification_Show(itemName, goal, sound)

  TitanFarmBuddyNotification_HideNotification();

  local itemInfo = TitanPanelFarmBuddyButton_GetItemInfo(itemName)
  if itemInfo ~= nil then

    TitanFarmBuddy_SetTitle(TitanFamrBuddyButton_GetAddOnName())
    TitanFarmBuddy_SetWidth(400);
    TitanFarmBuddy_SetText(goal .. ' ' .. itemInfo.Name);
    TitanFarmBuddy_SetIcon(itemInfo.IconFileDataID);

    if sound ~= nil and sound ~= '' then
      PlaySound(sound);
    end

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

-- **************************************************************************
-- NAME : TitanFarmBuddyAnchor_OnMouseDown()
-- DESC : Handles the OnMouseDown event for the TitanFarmBuddyAnchor frame.
-- **************************************************************************
function TitanFarmBuddyAnchor_OnMouseDown(self, button)

  if button == 'LeftButton' and not self.isMoving then
    self:StartMoving();
    self.isMoving = true;
  end

  if button == 'RightButton' and not self.isMoving then
    self:Hide();
  end
end

-- **************************************************************************
-- NAME : TitanFarmBuddyAnchor_OnMouseUp()
-- DESC : Handles the OnMouseUp event for the TitanFarmBuddyAnchor frame.
-- **************************************************************************
function TitanFarmBuddyAnchor_OnMouseUp(self, button)

  if button == 'LeftButton' and self.isMoving then
    self:StopMovingOrSizing();
    self.isMoving = false;
  end
end

-- **************************************************************************
-- NAME : TitanFarmBuddyAnchor_Show()
-- DESC : Shows the Notification Anchor frame.
-- **************************************************************************
function TitanFarmBuddyAnchor_Show()

  -- TODO: Hide BLizzard Option Frame and show again when anchor is hidden

  -- Set Scale for Anchor frame
  TitanFarmBuddyAnchor:SetScale(FRAME:GetEffectiveScale());
  _G['TitanFarmBuddyAnchorName']:SetText(L['FARM_BUDDY_ANCHOR_HELP_TEXT']);

  TitanFarmBuddyAnchor:Show();
end