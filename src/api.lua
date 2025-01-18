-- echo/src/api.lua
-- APIs
-- Copyright (C) 2025  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

local echo = echo

echo.registered_notification_types = {}
function echo.register_event_type(name, def)
    assert(type(name) == "string", string.format(
        "Invalid type fo argument name (string expected, got %s)", type(name)))
    assert(type(def) == "table", string.format(
        "Invalid type fo argument def (table expected, got %s)", type(def)))
    assert(type(def.handle_event) == "function", string.format(
        "Invalid type fo field def.handle_event (function expected, got %s)", type(def.handle_event)))

    echo.registered_notification_types[name] = def
end

echo.UNKNOWN_EVENT_HANDLER = "echo:unknown"

function echo.event_to_notification(event)
    assert(type(event) == "table", string.format(
        "Invalid type fo argument event (table expected, got %s)", type(event)))
    assert(type(event.type) == "string", string.format(
        "Invalid type fo field event.type (string expected, got %s)", type(event.type)))

    local event_handler = echo.registered_notification_types[event.type]
    if not event_handler then
        core.log("warning", string.format("Unknown event type %s found in event: %s", event.type, dump(event)))
        event_handler = echo.registered_notification_types[echo.UNKNOWN_EVENT_HANDLER]
    end

    return event_handler.handle_event(event)
end

echo.registered_on_send_event = {}
function echo.register_on_send_event(func)
    assert(type(func) == "function", string.format(
        "Invalid type fo argument func (function expected, got %s)", type(func)))

    echo.registered_on_send_event[#echo.registered_on_send_event + 1] = func
end

echo.registered_on_read_message = {}
function echo.register_on_read_message(func)
    assert(type(func) == "function", string.format(
        "Invalid type fo argument func (function expected, got %s)", type(func)))

    echo.registered_on_read_message[#echo.registered_on_read_message + 1] = func
end

-- source: https://gist.github.com/jrus/3197011
local random = math.random
local function new_uuid()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

function echo.send_event_to(name, event)
    assert(type(event) == "table", string.format(
        "Invalid type fo argument event (table expected, got %s)", type(event)))
    assert(type(event.type) == "string", string.format(
        "Invalid type fo field event.type (string expected, got %s)", type(event.type)))

    event = table.copy(event)

    event.time = event.time or os.time()
    event.to = name
    event.uuid = new_uuid()

    local storage = echo.get_notifications_entry(name)
    table.insert(storage, 1, event)
    echo.log_notifications_modification(name)

    local notification = echo.event_to_notification(event)
    for _, func in ipairs(echo.registered_on_send_event) do
        func(event, notification)
    end
end

function echo.get_event(name, uuid)
    if type(name) == "table" then
        -- Seems like we got an event, renew it.
        assert(type(name) == "table", string.format(
            "Invalid type fo argument event (table expected, got %s)", type(name)))
        assert(type(name.type) == "string", string.format(
            "Invalid type fo field event.type (string expected, got %s)", type(name.type)))
        assert(type(name.uuid) == "string", string.format(
            "Invalid type fo field event.uuid (string expected, got %s)", type(name.uuid)))
        return echo.get_event(name.to, name.uuid)
    end

    local storage = echo.get_notifications_entry(name)
    for _, s_event in ipairs(storage) do
        if uuid == s_event.uuid then
            return s_event
        end
    end
end
