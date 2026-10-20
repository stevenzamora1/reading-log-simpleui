--[[
Reading Log for Simple UI.

This file only puts the cards into Simple UI. When KOReader starts the
plugin, every Reading Log card (and the Dashboard) is registered with Simple
UI's module registry, the documented way for another plugin to add modules.
From then on they are Simple UI modules like its own: placed with its layout
editor, configured with a long-press, drawn when its screens are drawn.

The cards themselves live in the readinglog/ folder (see readinglog/init.lua).
]]

local WidgetContainer = require("ui/widget/container/widgetcontainer")
local UIManager = require("ui/uimanager")
local logger = require("logger")
local _ = require("gettext")

local DIR = (debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")) or "."

-- The card kit, loaded once per KOReader session.
local function kit()
    local A = package.loaded["readinglog_kit"]
    if A then return A end
    local ok, r = pcall(dofile, DIR .. "/readinglog/init.lua")
    if not ok or type(r) ~= "table" then
        logger.err("[readinglog] could not load the cards:", r)
        return nil
    end
    package.loaded["readinglog_kit"] = r
    return r
end

-- Register every module with Simple UI. Safe to call again: done once per
-- registry (a Simple UI reloaded in place gets a new one, and is told again).
local function register()
    local ok, Registry = pcall(require, "modules/moduleregistry")
    if not (ok and type(Registry) == "table" and Registry.register) then return false end
    local A = kit()
    if not A then return false end
    if A._registered_with == Registry then return true end
    for _, m in ipairs(A.simpleUIModules()) do
        local ok2, err = pcall(Registry.register, m)
        if not ok2 then logger.warn("[readinglog] could not register", m.id, err) end
    end
    A._registered_with = Registry
    logger.info("[readinglog] registered", #A.simpleUIModules(), "modules with Simple UI")
    -- a screen already on display gets the modules placed on it drawn now
    local SE = package.loaded["engines/sui_screen_engine"]
    if SE and SE.liveScreenIds and SE.refreshAllLiveImmediate then
        local ok3, ids = pcall(SE.liveScreenIds)
        if ok3 and type(ids) == "table" and #ids > 0 then pcall(SE.refreshAllLiveImmediate, false) end
    end
    return true
end

local warned = false

local ReadingLog = WidgetContainer:extend{
    name = "readinglog",
    is_doc_only = false,
}

function ReadingLog:init()
    if not register() then
        -- Simple UI may not be ready yet: try again once everything has started.
        UIManager:nextTick(function()
            if not register() and not warned and not (self.ui and self.ui.document) then
                warned = true
                logger.warn("[readinglog] Simple UI not found")
                local Notification = require("ui/widget/notification")
                UIManager:show(Notification:new{
                    text = _("Reading Log needs the Simple UI plugin."),
                })
            end
        end)
    end
    if self.ui and self.ui.menu then
        self.ui.menu:registerToMainMenu(self)
    end
end

function ReadingLog:addToMainMenu(menu_items)
    menu_items.readinglog = {
        text = _("Reading Log"),
        sorting_hint = "tools",
        sub_item_table = {
            {
                text = _("Look and colours…"),
                enabled_func = function() return kit() ~= nil end,
                callback = function()
                    local A = kit()
                    if A then A.S.look(nil) end
                end,
            },
            {
                text = _("Copy settings from the Bookshelf version"),
                enabled_func = function() return kit() ~= nil end,
                callback = function()
                    local A = kit()
                    if not A then return end
                    local n = A.host.importBookshelf()
                    local InfoMessage = require("ui/widget/infomessage")
                    UIManager:show(InfoMessage:new{
                        text = n and n > 0
                            and string.format(_("Copied %d settings from Reading Log for Bookshelf."), n)
                            or _("No Reading Log for Bookshelf settings were found."),
                    })
                    if n and n > 0 then
                        A.D.invalidate()
                        A.host.redrawAll()
                    end
                end,
            },
            {
                text = _("About"),
                keep_menu_open = true,
                callback = function()
                    local A = kit()
                    local InfoMessage = require("ui/widget/infomessage")
                    local found = pcall(require, "modules/moduleregistry")
                    UIManager:show(InfoMessage:new{
                        text = string.format(_([[Reading Log %s for Simple UI

Simple UI: %s

To add a card: Simple UI Settings > Home Screen > Layout Editor (or Extra Custom Screens), open a page, tap Add Module and pick any "Reading Log · …" module. Long-press a card for its settings.

For the Dashboard, give "Reading Log · Dashboard" a page (or a custom screen) of its own, and set its Top Margin to 0.

Ring designs and the dashboard idea: u/fishnoogz on Reddit.]]),
                            A and A.VERSION or "?",
                            found and (A and A.host.version() or _("found")) or _("not found")),
                    })
                end,
            },
        },
    }
end

return ReadingLog
