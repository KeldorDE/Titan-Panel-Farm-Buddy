-- **************************************************************************
-- * Notification.lua
-- *
-- * By: Keldor
-- **************************************************************************

local L = LibStub('AceLocale-3.0'):GetLocale('Titan', true)
local FRAME_NAME = 'TitanFarmBuddyAlertFrameTemplate'
local FRAME = CreateFrame('Button', FRAME_NAME, UIParent, 'TitanFarmBuddyAlertFrameTemplate')
local ADDON_NAME = TitanFarmBuddy_GetAddOnName()
local FRAME_HIDDEN = true


---Shows a notification frame for the given item.
---@param name string The item name.
---@param icon number|string The item icon file data ID or path.
---@param goal number The reached goal quantity.
---@param sound number|string|nil The sound to play, or nil/empty for none.
---@param duration number The display duration in seconds.
---@param glow boolean Whether to show the glow effect.
---@param shine boolean Whether to show the shine effect.
function TitanFarmBuddyNotification_Show(name, icon, goal, sound, duration, glow, shine)

    TitanFarmBuddyNotification_HideNotification(false)

    TitanFarmBuddyNotification_SetTitle(ADDON_NAME)
    TitanFarmBuddyNotification_SetWidth(400)
    TitanFarmBuddyNotification_SetText(goal .. ' ' .. name)
    TitanFarmBuddyNotification_SetIcon(icon)

    if sound ~= nil and sound ~= '' then
        PlaySound(sound)
    end

    if glow then
        FRAME.glow:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Guild")
        FRAME.glow:SetTexCoord(0.00195313, 0.74804688, 0.19531250, 0.49609375)
        FRAME.glow:SetVertexColor(1,1,1)
        FRAME.glow:Show()
    else
        FRAME.glow:Hide()
    end

    if shine then
        FRAME.shine:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Guild")
        FRAME.shine:SetTexCoord(0.75195313, 0.91601563, 0.19531250, 0.35937500)
        FRAME.shine:SetPoint("BOTTOMLEFT", 0, 16)
        FRAME.shine:Show()
    else
        FRAME.shine:Hide()
    end

    FRAME_HIDDEN = false

    FRAME:Show()
    FRAME.animIn:Play()

    if glow then
        FRAME.glow.animIn:Play()
    end

    if shine then
        FRAME.shine.animIn:Play()
    end

    FRAME.waitAndAnimOut.animOut:SetStartDelay(duration)
    FRAME.waitAndAnimOut:Play()
end

---Resets the timer and hides the notification.
---@param click boolean If true, the notification was dismissed by a click.
function TitanFarmBuddyNotification_HideNotification(click)
    FRAME_HIDDEN = true
    FRAME.waitAndAnimOut:Stop()

    if click == true then
        FRAME.animOut:Play()
    end
end

---Sets the notification title.
---@param title string The title text.
function TitanFarmBuddyNotification_SetTitle(title)
    FRAME.unlocked:SetText(title)
end

---Sets the notification text.
---@param text string The notification text.
function TitanFarmBuddyNotification_SetText(text)
    FRAME.Name:SetText(text)
end

---Sets the notification icon.
---@param icon number|string The icon file data ID or path.
function TitanFarmBuddyNotification_SetIcon(icon)
    FRAME.Icon.Texture:SetTexture(icon)
end

---Sets the notification frame width.
---@param width number The frame width.
function TitanFarmBuddyNotification_SetWidth(width)
    FRAME:SetWidth(width)
end

---Handles the OnMouseDown event for the TitanFarmBuddyAnchor frame.
---@param frame table The anchor frame.
---@param button string The mouse button that was pressed.
function TitanFarmBuddyNotification_OnMouseDown(frame, button)

    if button == 'LeftButton' and not frame.isMoving then
        frame:StartMoving()
        frame.isMoving = true
    end

    if button == 'RightButton' and not frame.isMoving then
        frame:Hide()
        Settings.OpenToCategory(TitanFarmBuddy_GetAddOnSettingsPanel())
    end
end

---Handles the OnMouseUp event for the TitanFarmBuddyAnchor frame.
---@param frame table The anchor frame.
---@param button string The mouse button that was released.
function TitanFarmBuddyNotification_OnMouseUp(frame, button)

    if button == 'LeftButton' and frame.isMoving then
        frame:StopMovingOrSizing()
        frame.isMoving = false
    end
end

---Shows the notification anchor frame.
function TitanFarmBuddyNotification_ShowAnchor()

    -- Set Scale for Anchor frame
    TitanFarmBuddyAnchor:SetScale(FRAME:GetEffectiveScale())
    TitanFarmBuddyAnchor.Name:SetText(L['FARM_BUDDY_ANCHOR_HELP_TEXT'])

    TitanFarmBuddyAnchor:Show()
end

---Gets whether the notification is currently shown.
---@return boolean shown
function TitanFarmBuddyNotification_Shown()
    return not FRAME_HIDDEN
end
