-- echo/src/storage.lua
-- Store player notifications
-- Copyright (C) 2025  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

local echo = echo

local caches = {}
local modified = {}
local last_accessed = {}

local WP = core.get_worldpath()
local BASEPATH = WP .. DIR_DELIM .. "echo" .. DIR_DELIM
core.mkdir(BASEPATH)

local function get_entry_from_storage(name)
    local file = io.open(BASEPATH .. name, "r")
    if not file then
        return {}
    end
    local raw_data = file:read("*a")
    local data = core.deserialize(raw_data)
    return data
end

local function save_entry_to_storage(name)
    local data = caches[name]
    if #data == 0 then
        os.remove(BASEPATH .. name)
    else
        local raw_data = core.serialize(data)
        core.safe_file_write(BASEPATH .. name, raw_data)
    end
end

---Get storage entry of a player.
---This value is only safe to use within the same globalstep.
---@param name string The name of the player
---@return table
function echo.get_notifications_entry(name)
    if not caches[name] then
        caches[name] = get_entry_from_storage(name)
    end
    last_accessed[name] = os.time()
    return caches[name]
end

---Tell Echo you have modified a player's notifications.
---Call this every time you modified tables returned by echo.get_notifications_entry.
---@see echo.get_notifications_entry
---@param name string The name of the player
function echo.log_notifications_modification(name)
    if caches[name] then
        modified[name] = true
        last_accessed[name] = os.time()
    end
end

---Safely clear a player's notifications.
---@param name string The name of the player
function echo.clear_notifications_entry(name)
    local storage = echo.get_notifications_entry(name)
    for i in ipairs(storage) do
        storage[i] = nil
    end
    echo.log_notifications_modification(name)
end

local function saveloop()
    core.log("action", "Saving Echo data")
    local now = os.time()
    for name in pairs(caches) do
        if modified[name] then
            save_entry_to_storage(name)
            modified[name] = nil
        end

        if now - last_accessed[name] > 120 then
            last_accessed[name] = nil
            caches[name] = nil
        end
    end

    core.after(30, saveloop)
end

core.after(35, saveloop)

core.register_on_shutdown(function()
    core.log("action", "Saving Echo data")
    for name in pairs(caches) do
        if modified[name] then
            save_entry_to_storage(name)
        end
    end
end)
