-- echo/src/gui.lua
-- Echo interface
-- Copyright (C) 2025  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

local echo = echo
local gui = flow.widgets
local S = core.get_translator("echo")

local function get_type_list(storage)
    local types_map = {}

    for _, event in ipairs(storage) do
        types_map[event.type] = true
    end

    local types, type_titles = {}, {}

    for etype in pairs(types_map) do
        types[#types + 1] = etype
    end

    table.sort(types)

    for i, etype in ipairs(types) do
        local def =
            echo.registered_notification_types[etype]
            or echo.registered_notification_types[echo.UNKNOWN_EVENT_HANDLER]
        type_titles[i] = def and def.title or etype
    end

    return types, type_titles
end

local function render_notif_row(event, notification)
    local style
    if not event.read then
        style = {
            bgcolor = "#C5FF7A00"
        }
    end
    return gui.HBox {
        gui.Stack {
            min_w = 9, min_h = 1, max_w = 9, max_h = 1,
            gui.Button {
                style = style,
                on_event = function(player, ctx)
                    event = echo.get_event(event)
                    if not event then return true end
                    if not event.read then
                        event.read = true
                        echo.log_notifications_modification(player:get_player_name())
                        for _, func in ipairs(echo.registered_on_read_message) do
                            func(event, notification)
                        end
                    end
                    if notification.onclick then
                        local rtn = notification.onclick(notification, player, ctx)
                        if type(rtn) == "function" then
                            ctx.curr_notification = notification
                            ctx.after_click_func = rtn
                        end
                    end
                    return true
                end,
            },
            gui.HBox {
                padding = 0.2,
                gui.Image {
                    w = 1, h = 1,
                    texture_name = notification.image or "blank.png",
                    align_v = "top", align_h = "left",
                },
                gui.VBox {
                    expand = true, align_h = "left", spacing = 0,
                    gui.Label {
                        w = 7.4, h = 0.5,
                        label = notification.title or S("Unknown notification"),
                        style = {
                            font_size = "*1.2",
                        }
                    },
                    gui.Label {
                        w = 7.4, h = 0.5,
                        label = notification.description or "",
                    },
                }
            }
        },
        gui.VBox {
            h = 1, spacing = 0,
            gui.Label {
                w = 2, h = 0.25,
                label = os.date("%Y/%m/%d", event.time)
            },
            gui.Label {
                w = 2, h = 0.25,
                label = os.date("%H:%M:%S", event.time)
            },
            gui.Button {
                w = 2, h = 0.5,
                label = S("Delete"),
                expand = true, align_v = "bottom",
                on_event = function(e_player)
                    local e_name = e_player:get_player_name()
                    local storage = echo.get_notifications_entry(e_name)
                    event = echo.get_event(event)

                    for i, s_event in ipairs(storage) do
                        if s_event == event then
                            table.remove(storage, i)
                            for _, func in ipairs(echo.registered_on_delete_message) do
                                func(event, echo.event_to_notification(event))
                            end
                            echo.log_notifications_modification(e_name)
                            return true
                        end
                    end
                end
            },
        }
    }
end

echo.echo_gui = flow.make_gui(function(player, ctx)
    if ctx.after_click_func and ctx.curr_notification then
        ctx.clear_confirm = nil
        local rtn = ctx.after_click_func(ctx.curr_notification, player, ctx)
        if rtn ~= nil then
            return rtn
        end
    end

    local name = player:get_player_name()
    local storage = echo.get_notifications_entry(name)

    local notifications = {}
    for _, event in ipairs(storage) do
        notifications[event] = ctx.notifications and ctx.notifications[event] or echo.event_to_notification(event)
    end
    ctx.notifications = notifications

    if not ctx.types_list then
        ctx.types_list, ctx.type_titles_list = get_type_list(storage)
    end


    local notifs_vbox = { w = 11.5, h = 9.5, name = "notifs_vbox" }

    local last_day
    for _, event in ipairs(storage) do
        local event_day = os.date("%Y/%m/%d", event.time)
        if event_day ~= last_day then
            last_day = event_day
            notifs_vbox[#notifs_vbox + 1] = gui.HBox {
                gui.Label {
                    h = 0.5,
                    label = event_day,
                    style = {
                        font_size = "*1.5",
                    },
                    expand = true, align_h = "left",
                },
                gui.Button {
                    w = 2, h = 0.5,
                    label = S("All read"),
                    on_event = function(e_player)
                        local e_name = e_player:get_player_name()
                        local e_storage = echo.get_notifications_entry(e_name)

                        for _, e_event in ipairs(e_storage) do
                            if os.date("%Y/%m/%d", e_event.time) == event_day then
                                e_event.read = true
                                for _, func in ipairs(echo.registered_on_read_message) do
                                    func(e_event, echo.event_to_notification(e_event))
                                end
                            end
                        end
                        echo.log_notifications_modification(e_name)
                        return true
                    end,
                },
                gui.Button {
                    w = 2, h = 0.5,
                    label = S("Delete all"),
                    on_event = function(e_player)
                        local e_name = e_player:get_player_name()
                        local e_storage = echo.get_notifications_entry(e_name)

                        for i=#e_storage, 1, -1 do
                            local e_event = e_storage[i]
                            for _, func in ipairs(echo.registered_on_delete_message) do
                                func(e_event, echo.event_to_notification(e_event))
                            end
                            if os.date("%Y/%m/%d", e_event.time) == event_day then
                                table.remove(e_storage, i)
                            end
                        end
                        echo.log_notifications_modification(e_name)
                        return true
                    end,
                },
            }
        end
        local notification = notifications[event]

        notifs_vbox[#notifs_vbox + 1] = render_notif_row(event, notification)
    end

    if #notifs_vbox == 0 then
        notifs_vbox[#notifs_vbox + 1] = gui.Label {
            label = S("No notifications."),
            style = {
                font_size = "*1.5",
            }
        }
    end

    local bottom_row
    if ctx.clear_confirm then
        bottom_row = gui.HBox {
            gui.Label {
                w = 2,
                label = S("Sure?"),
                expand = true, align_h = "right",
            },
            gui.Button {
                w = 2,
                label = S("Clear"),
                on_event = function(e_player, e_ctx)
                    e_ctx.clear_confirm = nil
                    local e_name = e_player:get_player_name()
                    echo.clear_notifications_entry(e_name)
                    return true
                end,
            },
            gui.Button {
                w = 2,
                label = S("Cancel"),
                on_event = function(_, e_ctx)
                    e_ctx.clear_confirm = nil
                    return true
                end,
            },
        }
    else
        bottom_row = gui.HBox {
            gui.Button {
                w = 2,
                label = S("All read"),
                expand = true, align_h = "right",
                on_event = function(e_player)
                    local e_name = e_player:get_player_name()
                    local e_storage = echo.get_notifications_entry(e_name)

                    for _, e_event in ipairs(e_storage) do
                        e_event.read = true
                        for _, func in ipairs(echo.registered_on_read_message) do
                            func(e_event, echo.event_to_notification(e_event))
                        end
                    end
                    echo.log_notifications_modification(e_name)
                    return true
                end,
            },
            gui.Button {
                w = 2,
                label = S("Delete all"),
                on_event = function(_, e_ctx)
                    e_ctx.clear_confirm = true
                    return true
                end,
            },
        }
    end

    return gui.VBox {
        gui.HBox {
            gui.Image {
                w = 0.4, h = 0.4, align_v = "center",
                texture_name = "echo_notification_icon.png",
            },
            gui.Label {
                h = 0.4,
                label = S("All notifications"),
                expand = true, align_h = "left",
                style = {
                    font_size = "*1.5",
                }
            },
            gui.ButtonExit {
                w = 0.7, h = 0.7,
                label = "x",
            },
        },
        gui.Box { w = 0.05, h = 0.05, color = "grey" },

        gui.ScrollableVBox(notifs_vbox),

        bottom_row,
    }
end)
