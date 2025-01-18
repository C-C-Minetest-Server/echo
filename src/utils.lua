-- echo/src/utils.lua
-- Utilities and unknown event handler
-- Copyright (C) 2025  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

local echo = echo
local gui = flow.widgets
local S = core.get_translator("echo")

function echo.on_event_reset_after_click(_, ctx)
    ctx.curr_notification = nil
    ctx.after_click_func = nil
    return true
end

echo.after_click = {} -- run in main function fun(notifictaion, player, ctx)
echo.onclick = {}     -- run in on_event fun(notifictaion, player, ctx)

-- Show more

function echo.after_click.show_more(notification)
    return gui.VBox {
        gui.HBox {
            gui.Button {
                w = 0.7, h = 0.7,
                label = "<",
                on_event = echo.on_event_reset_after_click,
            },
            gui.Label {
                label = S("More about: @1", notification.title),
                expand = true, align_h = "left",
            },
        },
        gui.Box { w = 0.05, h = 0.05, color = "grey" },

        gui.Textarea {
            w = 9, h = 7,
            default = notification.more,
        },
    }
end

function echo.onclick.show_more()
    return echo.after_click.show_more
end

-- Unknown event handler

echo.register_event_type("echo:unknown", {
    title = S("Unknown events"),
    handle_event = function(event)
        return {
            title = S("Unknown event: @1", event.type),
            description = S("You got a notification that the system cannot identify."),
            more =
                S("You got a notification that the system cannot identify. " ..
                    "An uninstalled mod might cause this.") .. "\n" ..
                S("This is the raw data of the event:") .. "\n\n" .. dump(event),
            onclick = echo.onclick.show_more,
            image = "unknown_item.png",
        }
    end,
})
