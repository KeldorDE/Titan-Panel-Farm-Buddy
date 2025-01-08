-- **************************************************************************
-- * Notification.lua
-- *
-- * By: Keldor
-- **************************************************************************

local L = LibStub('AceLocale-3.0'):GetLocale('Titan', true);
local FarmBuddyNotification = LibStub('AceAddon-3.0'):NewAddon('FarmBuddyNotification');
local FRAME_NAME = 'TitanFarmBuddyAlertFrameTemplate';
local FRAME = CreateFrame('Button', FRAME_NAME, UIParent, 'TitanFarmBuddyAlertFrameTemplate');
local ADDON_NAME = TitanFarmBuddy_GetAddOnName();
local FRAME_HIDDEN = true;


-- **************************************************************************
-- NAME : TitanFarmBuddyNotification_Show()
-- DESC : Shows a notification frame for the given item link.
-- **************************************************************************
function TitanFarmBuddyNotification_Show(itemName, goal, sound, duration, glow, shine)

  TitanFarmBuddyNotification_HideNotification(false);

  local itemInfo = TitanFarmBuddy_GetItemInfo(itemName);
  if itemInfo ~= nil then

    TitanFarmBuddyNotification_SetTitle(ADDON_NAME);
    TitanFarmBuddyNotification_SetWidth(400);
    TitanFarmBuddyNotification_SetText(goal .. ' ' .. itemInfo.Name);
    TitanFarmBuddyNotification_SetIcon(itemInfo.IconFileDataID);

    if sound ~= nil and sound ~= '' then
      PlaySound(sound);
    end

    if glow then
      FRAME.glow:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Guild");
      FRAME.glow:SetTexCoord(0.00195313, 0.74804688, 0.19531250, 0.49609375);
      FRAME.glow:SetVertexColor(1,1,1);
      FRAME.glow:Show();
    else
      FRAME.glow:Hide();
    end

    if shine then
      FRAME.shine:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Guild");
      FRAME.shine:SetTexCoord(0.75195313, 0.91601563, 0.19531250, 0.35937500);
      FRAME.shine:SetPoint("BOTTOMLEFT", 0, 16);
      FRAME.shine:Show();
    else
      FRAME.shine:Hide();
    end

    FRAME_HIDDEN = false;

    FRAME:Show();
    FRAME.animIn:Play();

    if glow then
      FRAME.glow.animIn:Play();
    end
    if shine then
      FRAME.shine.animIn:Play();
    end

    FRAME.waitAndAnimOut:Play();
  end
end

-- **************************************************************************
-- NAME : TitanFarmBuddyNotification_HideNotification()
-- DESC : Resets the timer and hides the notification.
-- **************************************************************************
function TitanFarmBuddyNotification_HideNotification(click)
  FRAME_HIDDEN = true;
  FRAME.waitAndAnimOut:Stop();
  if click == true then
    FRAME.animOut:Play();
  end
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
  FRAME.Name:SetText(text);
end

-- **************************************************************************
-- NAME : TitanFarmBuddyNotification_SetIcon()
-- DESC : Sets the notification icon.
-- **************************************************************************
function TitanFarmBuddyNotification_SetIcon(icon)
  FRAME.Icon.Texture:SetTexture(icon);
end

-- **************************************************************************
-- NAME : TitanFarmBuddyNotification_SetWidth()
-- DESC : Sets the notification frame width.
-- **************************************************************************
function TitanFarmBuddyNotification_SetWidth(width)
  FRAME:SetWidth(width);
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
    Settings.OpenToCategory(ADDON_NAME);
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
  TitanFarmBuddyAnchor.Name:SetText(L['FARM_BUDDY_ANCHOR_HELP_TEXT']);

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
