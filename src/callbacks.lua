-- echo/src/callbacks.lua
-- callbacks
-- Copyright (C) 2025  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

local echo = echo
local S = core.get_translator("echo")

core.register_chatcommand("echo", {
    description = S("Show notifications"),
    func = function(name)
        local player = core.get_player_by_name(name)
        if not player then
            return false, S("You must be online to run this command.")
        end

        echo.echo_gui:show(player)
        return true
    end,
})
