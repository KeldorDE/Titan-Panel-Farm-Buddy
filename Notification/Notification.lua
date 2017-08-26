-- **************************************************************************
-- * Notification.lua
-- *
-- * By: Keldor
-- **************************************************************************

local L = LibStub('AceLocale-3.0'):GetLocale('Titan', true);
local FarmBuddyNotification = LibStub('AceAddon-3.0'):NewAddon('FarmBuddyNotification', 'AceTimer-3.0');
local FRAME_NAME = 'TitanFarmBuddyAlertFrameTemplate';
local FRAME = CreateFrame('Button', FRAME_NAME, UIParent, 'TitanFarmBuddyAlertFrameTemplate');
local ADDON_NAME = TitanFamrBuddyButton_GetAddOnName();
local FRAME_HIDDEN = true;


-- **************************************************************************
-- NAME : TitanFarmBuddyNotification_Show()
-- DESC : Shows a notification frame for the given item link.
-- **************************************************************************
function TitanFarmBuddyNotification_Show(itemName, goal, sound, duration)

  TitanFarmBuddyNotification_HideNotification();

  local itemInfo = TitanPanelFarmBuddyButton_GetItemInfo(itemName);
  if itemInfo ~= nil then

    TitanFarmBuddyNotification_SetTitle(ADDON_NAME);
    TitanFarmBuddyNotification_SetWidth(400);
    TitanFarmBuddyNotification_SetText(goal .. ' ' .. itemInfo.Name);
    TitanFarmBuddyNotification_SetIcon(itemInfo.IconFileDataID);

    if sound ~= nil and sound ~= '' then
      PlaySound(sound);
    end

    UIFrameFadeIn(FRAME, 0.5, 0, 1);
    FarmBuddyNotification:ScheduleTimer('HideNotification', duration);
    FRAME_HIDDEN = false;
  end
end

-- **************************************************************************
-- NAME : FarmBuddyNotification:HideNotification()
-- DESC : Hides the active notification frame.
-- **************************************************************************
function FarmBuddyNotification:HideNotification()

  if FRAME:IsShown() and FRAME_HIDDEN == false then

    FRAME_HIDDEN = true;

    local fadeInfo = {};
    fadeInfo.mode = 'OUT';
    fadeInfo.timeToFade = 1;
    fadeInfo.startAlpha = 1;
    fadeInfo.endAlpha = 0;
    fadeInfo.finishedFunc = TitanFarmBuddyNotification_HideNotification;

    UIFrameFade(FRAME, fadeInfo);
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
-- NAME : TitanFarmBuddyNotification_SetTitle()
-- DESC : Sets the notification title.
-- **************************************************************************
function TitanFarmBuddyNotification_SetTitle(title)
  FRAME.unlocked:SetText(title);
end

-- **************************************************************************
-- NAME : TitanFarmBuddyNotification_SetText()
-- DESC : Sets the notification text.
-- **************************************************************************
function TitanFarmBuddyNotification_SetText(text)
  _G[FRAME_NAME .. 'Name']:SetText(text);
end

-- **************************************************************************
-- NAME : TitanFarmBuddyNotification_SetIcon()
-- DESC : Sets the notification icon.
-- **************************************************************************
function TitanFarmBuddyNotification_SetIcon(icon)
  _G[FRAME_NAME .. 'IconTexture']:SetTexture(icon);
end

-- **************************************************************************
-- NAME : TitanFarmBuddyNotification_SetWidth()
-- DESC : Sets the notification frame width.
-- **************************************************************************
function TitanFarmBuddyNotification_SetWidth(width)
  FRAME:SetWidth(400);
end

-- **************************************************************************
-- NAME : TitanFarmBuddyNotification_OnMouseDown()
-- DESC : Handles the OnMouseDown event for the TitanFarmBuddyAnchor frame.
-- **************************************************************************
function TitanFarmBuddyNotification_OnMouseDown(self, button)

  if button == 'LeftButton' and not self.isMoving then
    self:StartMoving();
    self.isMoving = true;
  end

  if button == 'RightButton' and not self.isMoving then
    self:Hide();
    InterfaceOptionsFrame_OpenToCategory(ADDON_NAME);
  end
end

-- **************************************************************************
-- NAME : TitanFarmBuddyNotification_OnMouseUp()
-- DESC : Handles the OnMouseUp event for the TitanFarmBuddyAnchor frame.
-- **************************************************************************
function TitanFarmBuddyNotification_OnMouseUp(self, button)

  if button == 'LeftButton' and self.isMoving then
    self:StopMovingOrSizing();
    self.isMoving = false;
  end
end

-- **************************************************************************
-- NAME : TitanFarmBuddyNotification_ShowAnchor()
-- DESC : Shows the Notification Anchor frame.
-- **************************************************************************
function TitanFarmBuddyNotification_ShowAnchor()

  -- Set Scale for Anchor frame
  TitanFarmBuddyAnchor:SetScale(FRAME:GetEffectiveScale());
  _G['TitanFarmBuddyAnchorName']:SetText(L['FARM_BUDDY_ANCHOR_HELP_TEXT']);

  InterfaceOptionsFrame:Hide();
  TitanFarmBuddyAnchor:Show();
end

-- **************************************************************************
-- NAME : TitanFarmBuddyNotification_Shown()
-- DESC : Gets the notification is currently shown status.
-- **************************************************************************
function TitanFarmBuddyNotification_Shown()
  if FRAME_HIDDEN == false then
    return true;
  end
  return false;
end
