-- echo/src/on_send.lua
-- HUD and chatroom indications on receiving notification
-- Copyright (C) 2025  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

local echo = echo
local S = core.get_translator("echo")

local huds = {}
local hud_type_name = core.features.hud_def_type_field and "type" or "hud_elem_type"

local function update_hud(player)
    local counter = 0
    local name = player:get_player_name()
    local storage = echo.get_notifications_entry(name)
    for _, event in ipairs(storage) do
        if not event.read then
            counter = counter + 1
        end
    end

    if counter == 0 then
        player:hud_change(huds[name], "text", "")
    else
        player:hud_change(huds[name], "text", S("@1 unread notifications", counter))
    end
end

core.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    huds[name] = player:hud_add({
        [hud_type_name] = "text",
        position = { x = 1, y = 0.2 },
        alignment = { x = -1, y = 2.5 },
        offset = { x = -6, y = 0 },
        text = "",
        number = 0xffffff,
    })
    update_hud(player)
end)

core.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    huds[name] = nil
end)

echo.register_on_send_event(function(event, notification)
    local name = event.to
    local player = core.get_player_by_name(name)
    if player then
        core.chat_send_player(name, core.colorize("#C5FF7A",
            S("New notification: @1.", notification.title or event.type) .. "\n" ..
            S("Type /echo in the chatroom to check it out.")))

        if huds[name] then
            update_hud(player)
        end
    end
end)

echo.register_on_read_message(function(event)
    local name = event.to
    local player = core.get_player_by_name(name)
    if player and huds[name] then
        update_hud(player)
    end
end)
