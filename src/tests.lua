-- echo/src/tests.lua
-- Tests
-- Copyright (C) 2025  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

local echo = echo
local S = core.get_translator("echo")

echo.register_event_type("echo:test_simple", {
    title = S("Test event: Simple"),
    handle_event = function(event)
        return {
            title = S("Test event: Simple"),
            description = S("Description: @1", event.description),
            image = "air.png",
        }
    end,
})

echo.register_event_type("echo:test_more", {
    title = S("Test event: Show more"),
    handle_event = function(event)
        return {
            title = S("Test event: Show more"),
            description = S("Description: @1", event.description),
            more = S("This is the raw data of the event:") .. "\n\n" .. dump(event),
            onclick = echo.onclick.show_more,
            image = "air.png",
        }
    end,
})

core.register_chatcommand("echo_test", {
    description = S("Send testing notifications to yourself"),
    params = S("[<description>]"),
    privs = { server = true },
    func = function(name, param)
        echo.send_event_to(name, {
            type = "echo:test_simple",
            description = param,
        })

        echo.send_event_to(name, {
            type = "echo:test_more",
            description = param,
        })

        echo.send_event_to(name, {
            type = "echo:test_nonexist",
            description = param,
        })

        return true, S("Test notifications sent.")
    end,
})
