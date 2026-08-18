---@meta
-- LuaLS type definitions for the Ace3 mixins used by this addon.
-- Not loaded by WoW (intentionally excluded from the .toc); only consumed by the Lua language server.

---@class AceConsole
local AceConsole = {}
---@param command string
---@param func string|function
function AceConsole:RegisterChatCommand(command, func) end
---@param ... any
function AceConsole:Print(...) end
---@param str string
---@param numargs? number
---@param startpos? number
---@return string, string, string
function AceConsole:GetArgs(str, numargs, startpos) end

---@class AceEvent
local AceEvent = {}
---@param event string
---@param callback? string|function
function AceEvent:RegisterEvent(event, callback) end
---@param event string
function AceEvent:UnregisterEvent(event) end

---@class AceHook
local AceHook = {}
---@param target any
---@param method? string
---@param hook? string|function
function AceHook:SecureHook(target, method, hook) end

---@class AceTimer
local AceTimer = {}
---@param callback string|function
---@param delay number
---@param ... any
---@return table timer
function AceTimer:ScheduleTimer(callback, delay, ...) end
---@param callback string|function
---@param delay number
---@param ... any
---@return table timer
function AceTimer:ScheduleRepeatingTimer(callback, delay, ...) end
---@param timer table
function AceTimer:CancelTimer(timer) end
function AceTimer:CancelAllTimers() end
