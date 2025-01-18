-- echo/init.lua
-- In-game notification system
-- Copyright (C) 2025  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

echo = {}

local MP = core.get_modpath("echo")

dofile(MP .. "/src/storage.lua")
dofile(MP .. "/src/api.lua")
dofile(MP .. "/src/utils.lua")
dofile(MP .. "/src/gui.lua")
dofile(MP .. "/src/callbacks.lua")
dofile(MP .. "/src/on_send.lua")
dofile(MP .. "/src/tests.lua")