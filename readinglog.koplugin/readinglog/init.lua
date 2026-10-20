--[[
Reading Log for Simple UI: shared code behind every Reading Log module.

This is the Reading Log card kit (the alm_* Bookshelf micro-modules) ported to
Simple UI's home screen modules. The cards are drawn exactly as before; only
the host changed. Everything that used to come from Bookshelf (where settings
are stored, the card colour, fonts, book records, goals, covers, opening a
book) now goes through host.lua, which talks to Simple UI and KOReader.

Ring designs and the idea of a tabbed reading dashboard: u/fishnoogz on
Reddit. Built for KOReader and Simple UI.

Parts, each loaded once and attached to the same table:
  init.lua      this file: store, theme, drawing, text, the Canvas widget
  host.lua      Simple UI / KOReader adapter (settings file, fonts, books,
                goals, covers, repaints, the clock tick)
  data.lua      reading stats, book lists, covers
  panels.lua    one builder per card (banner, continue reading, rings, ...)
  settings.lua  each card's options, and the dialogs (page editor, picks)
  modules.lua   turns each panel into a Simple UI module; the dashboard
  menus.lua     the options as Simple UI settings menu items

Why modules paint their own card: each card has its own colour, so it fills
its box with a rounded panel and draws on that.
]]

local A = { VERSION = "1.1.0", NAME = "Reading Log" }
A.HOST = "Simple UI"

A.dir = (debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")) or "."

local floor, ceil, max, min, sqrt = math.floor, math.ceil, math.max, math.min, math.sqrt

-- ─── small utilities ─────────────────────────────────────────────────────────

function A.log(...)
    local ok, logger = pcall(require, "logger")
    if ok and logger then logger.warn("[almanac]", ...) end
end

-- A line in KOReader's own log (crash.log on a Kobo), for the few events
-- worth being able to look up afterwards.
function A.note(...)
    local ok, logger = pcall(require, "logger")
    if ok and logger then logger.info("[almanac]", ...) end
end

-- Counters shown in Look and colours > Diagnostics. Since this session started.
A.counts = { views = 0, flashes = 0, reinks = 0, narrowed = 0, clipped = 0, cleans = 0 }
function A.count(name) A.counts[name] = (A.counts[name] or 0) + 1 end

function A.round(n) return floor(n + 0.5) end
function A.clamp(v, lo, hi) if v < lo then return lo elseif v > hi then return hi end return v end

-- Text from book metadata or typed by the reader can carry bytes the text
-- shaper chokes on (a C-level crash no pcall catches); see host.lua.
function A.safe(s)
    if type(s) ~= "string" then s = s == nil and "" or tostring(s) end
    return A.host.safeText(s)
end

function A.upper(s)
    s = A.safe(s)
    local ok, U = pcall(require, "ffi/utf8proc")
    if ok and U and U.uppercase_dumb then
        local ok2, r = pcall(U.uppercase_dumb, s)
        if ok2 and type(r) == "string" then return r end
    end
    return s:upper()
end

function A.screen() return require("device").screen end

-- ─── settings store ──────────────────────────────────────────────────────────
-- Reading Log keeps its settings in a file of its own,
-- settings/readinglog.lua (see host.lua). On the first run, settings saved by
-- the Bookshelf version are copied in.

function A.get(key, default)
    local ok, v = pcall(A.host.get, key)
    if ok and v ~= nil then return v end
    return default
end

function A.set(key, value)
    pcall(A.host.set, key, value)
    A.epoch = (A.epoch or 0) + 1
end

A.epoch = 0

-- ─── theme ───────────────────────────────────────────────────────────────────
-- Colour e-ink (Kaleido) shows about a third of the saturation of a phone
-- screen, sixteen levels per channel, and it is dark: a deep tinted fill
-- comes out as a muddy grey, and anything flat that is not one of those
-- sixteen levels is dithered into grain. Big dark areas are also where
-- ghosting shows most. So a theme is one surface colour (white, cream or
-- true black), colour is kept for accents, and every flat colour here is a
-- multiple of 17 per channel (an exact panel level, so no grain).
--
-- A theme: surface (the card), tint (a second, slightly different card),
-- fg (ink), border, page / page_fg (what the Dashboard paints behind its
-- cards), accent (the accent it starts with).
-- The two accents are the reader's: any two of A.ACCENTS. Each has a `deep`
-- form for light surfaces and a `bright` one for dark, and names the partner
-- that is used when no second accent has been chosen.

A.ACCENTS = {
    red     = { label = "Red",     deep = { 204, 34, 51 },  bright = { 255, 102, 102 }, pair = "blue" },
    orange  = { label = "Orange",  deep = { 221, 102, 0 },  bright = { 255, 170, 51 },  pair = "teal" },
    gold    = { label = "Gold",    deep = { 170, 119, 0 },  bright = { 255, 204, 51 },  pair = "red" },
    lime    = { label = "Lime",    deep = { 102, 153, 0 },  bright = { 187, 238, 68 },  pair = "purple" },
    green   = { label = "Green",   deep = { 17, 136, 68 },  bright = { 102, 221, 119 }, pair = "orange" },
    teal    = { label = "Teal",    deep = { 0, 136, 136 },  bright = { 85, 221, 221 },  pair = "orange" },
    sky     = { label = "Sky",     deep = { 0, 136, 204 },  bright = { 102, 204, 255 }, pair = "pink" },
    blue    = { label = "Blue",    deep = { 34, 102, 204 }, bright = { 102, 170, 255 }, pair = "red" },
    purple  = { label = "Purple",  deep = { 119, 68, 187 }, bright = { 187, 153, 255 }, pair = "gold" },
    magenta = { label = "Magenta", deep = { 187, 34, 153 }, bright = { 255, 119, 221 }, pair = "teal" },
    pink    = { label = "Pink",    deep = { 204, 51, 119 }, bright = { 255, 136, 187 }, pair = "sky" },
    brown   = { label = "Brown",   deep = { 136, 85, 34 },  bright = { 221, 170, 119 }, pair = "teal" },
}
A.ACCENT_ORDER = { "red", "orange", "gold", "lime", "green", "teal", "sky", "blue", "purple", "magenta", "pink", "brown" }

local WHITE, BLACK = { 255, 255, 255 }, { 0, 0, 0 }

A.THEMES = {
    white = { label = "White", accent = "red",
              surface = WHITE, tint = { 238, 238, 238 }, fg = BLACK, border = BLACK,
              page = WHITE, page_fg = BLACK },
    dark  = { label = "Dark", accent = "gold",
              surface = BLACK, tint = { 34, 34, 34 }, fg = WHITE, border = { 119, 119, 119 }, thin = true,
              page = BLACK, page_fg = WHITE },
    paper = { label = "Paper", accent = "orange",
              surface = { 255, 238, 204 }, tint = { 238, 221, 170 }, fg = { 34, 17, 0 }, border = { 68, 51, 34 },
              page = { 255, 238, 204 }, page_fg = { 34, 17, 0 } },
}
A.THEME_ORDER = { "white", "dark", "paper" }
A.DEFAULT_THEME = "white"
-- names from earlier versions
local THEME_ALIAS = { noir = "dark" }

-- The four card styles of every theme. Earlier versions stored "plum" and
-- "wine"; those now mean the two plain styles.
A.TONES = { "ink", "paper", "tint", "tint2" }
local TONE_LABELS = { ink = "Plain", paper = "Plain, accents swapped", tint = "Tinted", tint2 = "Tinted, accents swapped" }
local TONE_ALIAS = { plum = "ink", wine = "paper" }

function A.toneKey(name)
    name = TONE_ALIAS[name] or name
    if not TONE_LABELS[name] then name = "ink" end
    return name
end

function A.toneLabel(key) return TONE_LABELS[A.toneKey(key)] end

function A.themeId()
    local id = A.get("theme", A.DEFAULT_THEME)
    id = THEME_ALIAS[id] or id
    if not A.THEMES[id] then id = A.DEFAULT_THEME end
    return id
end

-- The two accent families in use: the reader's picks, else the theme's own
-- first accent and that accent's partner.
function A.accentIds()
    local th = A.THEMES[A.themeId()]
    local a = A.get("accent", nil)
    if not A.ACCENTS[a] then a = th.accent end
    local b = A.get("accent2", nil)
    if not A.ACCENTS[b] then b = A.ACCENTS[a].pair end
    return a, b
end

-- The current theme, with the handful of colours the Dashboard's own
-- furniture uses: gold (accent on a dark page), wine (accent on a light
-- page), ink and paper.
function A.theme()
    local th = A.THEMES[A.themeId()]
    local fam = A.ACCENTS[(A.accentIds())]
    return { label = th.label, page = th.page, page_fg = th.page_fg,
             gold = fam.bright, wine = fam.deep, ink = BLACK, paper = WHITE }
end

function A.mix(a, b, t)
    return { a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t, a[3] + (b[3] - a[3]) * t }
end

function A.luma(c) return 0.299 * c[1] + 0.587 * c[2] + 0.114 * c[3] end

function A.night()
    local Screen = A.screen()
    return Screen.night_mode and true or false
end

function A.inverted(c) return { 255 - c[1], 255 - c[2], 255 - c[3] } end

-- How the page will LOOK: dark when the page colour is dark, and dark when
-- night mode turns a light page over.
function A.pageLooksDark()
    local bg = A.pageColors()
    return (A.luma(bg) < 128) ~= A.night()
end

-- Colour to paint so that it LOOKS like `rgb` on a canvas that is not
-- pre-inverted (the dashboard's own tab bar and headings).
function A.shown(rgb)
    if A.night() then return A.inverted(rgb) end
    return rgb
end

-- One card style: colours worked out from a surface, its ink and the two
-- accents. `fixed` = looks the same day and night (see Canvas).
local function buildTone(name, bg, fg, border, thin)
    local dark = A.luma(bg) < 128
    local id1, id2 = A.accentIds()
    local a1 = dark and A.ACCENTS[id1].bright or A.ACCENTS[id1].deep
    local a2 = dark and A.ACCENTS[id2].bright or A.ACCENTS[id2].deep
    if name == "paper" or name == "tint2" then a1, a2 = a2, a1 end
    return {
        name = name, dark = dark, fixed = true,
        bg = bg, fg = fg, muted = A.mix(bg, fg, dark and 0.8 or 0.72),
        -- chart and calendar labels (months, days, axis figures): darker
        -- than muted, so small bold letters stay crisp on e-ink
        label = A.mix(bg, fg, dark and 0.88 or 0.82),
        accent = a1, accent2 = a2,
        track = A.mix(bg, fg, dark and 0.24 or 0.15),
        border = border, border_thin = thin,
        btn = a1, btn_fg = (A.luma(a1) > 140) and BLACK or WHITE,
        soft = A.mix(bg, fg, 0.12),
        series = { a1, a2, fg },
    }
end

-- A card style in the theme's own colours: what the Dashboard's cards use.
function A.tone(name)
    name = A.toneKey(name)
    local th = A.THEMES[A.themeId()]
    local tinted = (name == "tint" or name == "tint2")
    return buildTone(name, tinted and th.tint or th.surface, th.fg, th.border, th.thin)
end

-- A card style for a card on its own on a Simple UI screen: it takes Simple
-- UI's own background and ink and draws no frame of its own, so the card sits
-- on the page like Simple UI's own modules (its Frame and Background options
-- still apply around it). Only the accents come from the theme. Tinted styles
-- keep a soft, frameless panel. Colours are kept as they should LOOK; the
-- canvas pre-inverts them at night like every other card.
function A.nativeTone(name)
    name = A.toneKey(name)
    local bg, fg = A.pageColors()
    if A.night() then bg, fg = A.inverted(bg), A.inverted(fg) end
    local tinted = (name == "tint" or name == "tint2")
    if tinted then bg = A.mix(bg, fg, A.luma(bg) < 128 and 0.12 or 0.07) end
    local t = buildTone(name, bg, fg, nil, nil)
    t.native, t.panel = true, tinted
    return t
end

-- Whether cards on their own take Simple UI's look (the default) or the
-- theme's framed cards.
function A.standaloneNative()
    return A.get("standalone", "native") ~= "framed"
end

-- The colour of the page the panel sits on (Simple UI's background), the ink
-- Simple UI draws on it, and its muted ink. Read at render time.
function A.pageColors()
    local ok, bg, fg, muted = pcall(A.host.pageColors)
    if ok and bg then return bg, fg, muted end
    return { 0xFF, 0xFF, 0xFF }, { 0, 0, 0 }, { 0x77, 0x77, 0x77 }
end

-- What the Dashboard paints behind and between its cards, as colours to
-- PAINT (night mode already allowed for): bg, fg, whether it will look dark,
-- an accent for headings, and `look` = the page colour as it should look when
-- the theme sets one (nil when the page is Simple UI's own background).
function A.dashPage()
    local th = A.theme()
    if th.page then
        local dark = A.luma(th.page) < 128
        return A.shown(th.page), A.shown(th.page_fg), dark, A.shown(dark and th.gold or th.wine), th.page
    end
    local bg, fg = A.pageColors()
    local dark = A.pageLooksDark()
    return bg, fg, dark, A.shown(dark and th.gold or A.mix(th.gold, { 0, 0, 0 }, 0.42)), nil
end

-- ─── colours → Blitbuffer ────────────────────────────────────────────────────
-- Colours live as {r,g,b}. They become Blitbuffer colours at the last moment:
-- real colour on a colour screen, Rec.601 grey otherwise.

local _colcache, _colmode, _colcount = {}, nil, 0

function A.color(rgb, inv)
    local Blitbuffer = require("ffi/blitbuffer")
    local Screen = A.screen()
    local is_color = Screen.isColorEnabled and Screen:isColorEnabled() or false
    -- Edge blending makes many one-off shades; start over now and then.
    if _colmode ~= is_color or _colcount > 8192 then _colcache, _colmode, _colcount = {}, is_color, 0 end
    local r = A.clamp(floor(rgb[1] + 0.5), 0, 255)
    local g = A.clamp(floor(rgb[2] + 0.5), 0, 255)
    local b = A.clamp(floor(rgb[3] + 0.5), 0, 255)
    if inv then r, g, b = 255 - r, 255 - g, 255 - b end
    local key = r * 65536 + g * 256 + b
    local c = _colcache[key]
    if c then return c end
    if is_color and Blitbuffer.ColorRGB32 then
        c = Blitbuffer.ColorRGB32(r, g, b, 0xFF)
    else
        c = Blitbuffer.Color8(floor(0.299 * r + 0.587 * g + 0.114 * b + 0.5))
    end
    _colcache[key] = c
    _colcount = _colcount + 1
    return c
end

-- paintRect flattens a colour to grey; paintRectRGB32 keeps it. Same choice
-- KOReader's own FrameContainer makes.
local function fillRect(bb, x, y, w, h, c)
    if w <= 0 or h <= 0 then return end
    local Blitbuffer = require("ffi/blitbuffer")
    if bb.paintRectRGB32 and Blitbuffer.isColor8 and not Blitbuffer.isColor8(c) then
        bb:paintRectRGB32(x, y, w, h, c)
    else
        bb:paintRect(x, y, w, h, c)
    end
end
A.fillRect = fillRect

-- One pixel, only if it is inside the bitmap. Blitbuffer's own setPixel does
-- no bounds check (rect fills and blits do), so a shape that hangs over the
-- edge of what it is painted into would otherwise write into whatever memory
-- sits beside the bitmap. bw, bh = the bitmap's size, read once per shape.
local function plot(bb, bw, bh, x, y, c)
    if x >= 0 and y >= 0 and x < bw and y < bh then
        bb:setPixel(x, y, c)
    else
        A.counts.clipped = A.counts.clipped + 1
        if A._oob then A._oob(x, y, bw, bh) end
    end
end

-- ─── drawing primitives ──────────────────────────────────────────────────────
-- All take {r,g,b} colours plus `inv` (see Canvas: night-mode compensation).
-- Edges are anti-aliased by mixing with the colour known to be underneath
-- (`under`), never by reading pixels back, so they behave the same whichever
-- way the device implements night mode.

local G = {}
A.G = G

function G.rect(bb, x, y, w, h, rgb, inv)
    fillRect(bb, floor(x), floor(y), floor(w), floor(h), A.color(rgb, inv))
end

-- Filled rounded rectangle. `under` = colour behind it, for the corner edges.
function G.rrect(bb, x, y, w, h, r, rgb, under, inv)
    x, y, w, h = floor(x), floor(y), floor(w), floor(h)
    if w <= 0 or h <= 0 then return end
    r = floor(min(r or 0, w / 2, h / 2))
    local c = A.color(rgb, inv)
    if r < 1 then fillRect(bb, x, y, w, h, c) return end
    local bw, bh = bb:getWidth(), bb:getHeight()
    fillRect(bb, x, y + r, w, h - 2 * r, c)
    for i = 0, r - 1 do
        local dy = r - i - 0.5
        local inset = r - sqrt(max(0, r * r - dy * dy))
        local full = ceil(inset)
        local cov = full - inset
        local yt, yb = y + i, y + h - 1 - i
        local span = w - 2 * full
        if span > 0 then
            fillRect(bb, x + full, yt, span, 1, c)
            fillRect(bb, x + full, yb, span, 1, c)
        end
        if under and cov > 0.02 and full >= 1 then
            local e = A.color(A.mix(under, rgb, cov), inv)
            plot(bb, bw, bh, x + full - 1, yt, e)
            plot(bb, bw, bh, x + w - full, yt, e)
            plot(bb, bw, bh, x + full - 1, yb, e)
            plot(bb, bw, bh, x + w - full, yb, e)
        end
    end
end

-- Outlined rounded rectangle: border colour outside, fill inside.
function G.frame(bb, x, y, w, h, r, bw, border, fill, under, inv)
    G.rrect(bb, x, y, w, h, r, border, under, inv)
    G.rrect(bb, x + bw, y + bw, w - 2 * bw, h - 2 * bw, max(0, r - bw), fill, border, inv)
end

function G.disc(bb, cx, cy, r, rgb, under, inv)
    if not (r > 0 and r < 4096 and cx == cx and cy == cy) then return end
    local c = A.color(rgb, inv)
    local bw, bh = bb:getWidth(), bb:getHeight()
    local x0, x1 = floor(cx - r - 1), ceil(cx + r + 1)
    for py = floor(cy - r - 1), ceil(cy + r + 1) do
        local dy = py + 0.5 - cy
        for px = x0, x1 do
            local dx = px + 0.5 - cx
            local cov = r + 0.5 - sqrt(dx * dx + dy * dy)
            if cov >= 1 then
                plot(bb, bw, bh, px, py, c)
            elseif cov > 0 and under then
                plot(bb, bw, bh, px, py, A.color(A.mix(under, rgb, cov), inv))
            end
        end
    end
end

-- Progress ring: a full track with an arc of `frac` drawn clockwise from
-- 12 o'clock, round caps at both ends. R = outer radius, t = thickness.
-- A thick line through points { x1, y1, x2, y2, ... } (a curve is just many
-- short segments). Each pixel's coverage is its distance from the nearest
-- segment, kept in a scratch buffer as the largest over all segments, so
-- joints and overlaps come out smooth instead of doubling up at the edges.
-- Everything is clipped to the bitmap first.
function G.polyline(bb, pts, lw, rgb, under, inv)
    local n = floor(#pts / 2)
    if n < 2 or not (lw > 0 and lw < 200) then return end
    local bw, bh = bb:getWidth(), bb:getHeight()
    local r = lw / 2
    local minx, miny, maxx, maxy = math.huge, math.huge, -math.huge, -math.huge
    for i = 1, 2 * n, 2 do
        local x, y = pts[i], pts[i + 1]
        if x ~= x or y ~= y then return end -- NaN: nothing sensible to draw
        if x < minx then minx = x end
        if x > maxx then maxx = x end
        if y < miny then miny = y end
        if y > maxy then maxy = y end
    end
    local x0, x1 = max(0, floor(minx - r - 1)), min(bw - 1, ceil(maxx + r + 1))
    local y0, y1 = max(0, floor(miny - r - 1)), min(bh - 1, ceil(maxy + r + 1))
    if x1 < x0 or y1 < y0 then return end
    local W, H = x1 - x0 + 1, y1 - y0 + 1
    if W * H > 8000000 then return end
    local ffi = require("ffi")
    local cov = ffi.new("uint8_t[?]", W * H)
    local touched, nt = {}, 0 -- every pixel given any coverage, to compose only those
    for i = 1, 2 * n - 2, 2 do
        local ax, ay, bx2, by2 = pts[i], pts[i + 1], pts[i + 2], pts[i + 3]
        local dx, dy = bx2 - ax, by2 - ay
        local len2 = dx * dx + dy * dy
        local sx0 = max(x0, floor(min(ax, bx2) - r - 1))
        local sx1 = min(x1, ceil(max(ax, bx2) + r + 1))
        local sy0 = max(y0, floor(min(ay, by2) - r - 1))
        local sy1 = min(y1, ceil(max(ay, by2) + r + 1))
        for py = sy0, sy1 do
            local cy = py + 0.5
            local row = (py - y0) * W - x0
            for px = sx0, sx1 do
                local cx = px + 0.5
                local t = 0
                if len2 > 0 then
                    t = ((cx - ax) * dx + (cy - ay) * dy) / len2
                    if t < 0 then t = 0 elseif t > 1 then t = 1 end
                end
                local ex, ey = ax + t * dx - cx, ay + t * dy - cy
                local c = r + 0.5 - sqrt(ex * ex + ey * ey)
                if c > 0 then
                    local v = (c >= 1) and 255 or floor(c * 255)
                    local idx = row + px
                    local old = cov[idx]
                    if v > old then
                        if old == 0 then nt = nt + 1; touched[nt] = idx end
                        cov[idx] = v
                    end
                end
            end
        end
    end
    local solid = A.color(rgb, inv)
    for i = 1, nt do
        local idx = touched[i]
        local v = cov[idx]
        local py = y0 + floor(idx / W)
        local px = x0 + idx % W
        if v == 255 then
            plot(bb, bw, bh, px, py, solid)
        elseif under then
            plot(bb, bw, bh, px, py, A.color(A.mix(under, rgb, v / 255), inv))
        elseif v >= 128 then
            plot(bb, bw, bh, px, py, solid)
        end
    end
end

function G.ring(bb, cx, cy, R, t, frac, track, fill, under, inv)
    if not (R > 0 and R < 4096 and t > 0 and cx == cx and cy == cy) then return end
    frac = tonumber(frac) or 0
    if frac ~= frac then frac = 0 end
    frac = A.clamp(frac, 0, 1)
    local pi2 = 2 * math.pi
    local theta = frac * pi2
    local rm, cap = R - t / 2, t / 2
    local ex, ey = cx + rm * math.sin(theta), cy - rm * math.cos(theta)
    local sx, sy = cx, cy - rm
    local c_track, c_fill = A.color(track, inv), A.color(fill, inv)
    local bw, bh = bb:getWidth(), bb:getHeight()
    local atan2 = math.atan2
    local full = frac >= 0.999
    for py = floor(cy - R - 1), ceil(cy + R + 1) do
        local dy = py + 0.5 - cy
        local ro = (R + 1) * (R + 1) - dy * dy
        if ro > 0 then
            local half = sqrt(ro)
            local ri = (R - t - 1)
            local hole = (ri > 0 and ri * ri - dy * dy > 0) and sqrt(ri * ri - dy * dy) or 0
            for px = floor(cx - half), ceil(cx + half) do
                local dx = px + 0.5 - cx
                if dx > hole or dx < -hole or hole == 0 then
                    local d = sqrt(dx * dx + dy * dy)
                    local cov = min(R + 0.5 - d, d - (R - t) + 0.5)
                    if cov > 0 then
                        if cov > 1 then cov = 1 end
                        -- how much of this pixel belongs to the filled arc
                        local f
                        if full then
                            f = 1
                        else
                            local a = atan2(dx, -dy)
                            if a < 0 then a = a + pi2 end
                            if a <= theta then
                                f = 1
                            else
                                local d1 = cap + 0.5 - sqrt((px + 0.5 - sx) ^ 2 + (py + 0.5 - sy) ^ 2)
                                local d2 = cap + 0.5 - sqrt((px + 0.5 - ex) ^ 2 + (py + 0.5 - ey) ^ 2)
                                f = max(0, min(1, max(d1, d2)))
                            end
                        end
                        if cov >= 1 and f >= 1 then
                            plot(bb, bw, bh, px, py, c_fill)
                        elseif cov >= 1 and f <= 0 then
                            plot(bb, bw, bh, px, py, c_track)
                        else
                            local base = A.mix(track, fill, f)
                            if under and cov < 1 then base = A.mix(under, base, cov) end
                            plot(bb, bw, bh, px, py, A.color(base, inv))
                        end
                    end
                end
            end
        end
    end
end

-- ─── fonts and text ──────────────────────────────────────────────────────────
-- Everything here is sized in real pixels, derived from the panel's size.
-- KOReader's Font:getFace takes a size that it scales for the screen itself
-- (ceil(size * scale)), so convert back before asking.

local function dp(px)
    local Screen = A.screen()
    local scale = Screen:scaleBySize(1000000) / 1000000
    return max(1, (px - 0.5) / scale)
end

function A.face(px, o)
    o = o or {}
    px = max(8, floor(px + 0.5))
    -- (asked of Font:getFace as KOReader has it, before Simple UI's Global
    -- Text Size scales it: the cards are drawn to fit their box)
    if o.symbol then
        -- icon glyphs: KOReader's bundled Nerd Font symbols
        local Font = require("ui/font")
        local getFace = A.host.nativeGetFace() or Font.getFace
        local ok, face = pcall(getFace, Font, "symbols", dp(px))
        if ok and face then return face, false end
    end
    if o.serif then
        local Font = require("ui/font")
        local name = o.bold and "NotoSerif-Bold.ttf" or (o.italic and "NotoSerif-Italic.ttf" or "NotoSerif-Regular.ttf")
        local getFace = A.host.nativeGetFace() or Font.getFace
        local ok, face = pcall(getFace, Font, name, dp(px))
        if ok and face then return face, false end
    end
    local ok, face, bold = pcall(A.host.face, dp(px), o)
    if ok and face then return face, bold end
    local Font = require("ui/font")
    return Font:getFace(o.bold and "tfont" or "cfont", dp(px)), false
end

-- Single-line text that keeps a colour ink a colour (see colourtext.lua).
local function textClass()
    return A.host.textClass()
end

-- Wrapped text that composites over whatever is behind it. KOReader's
-- TextBoxWidget paints an opaque box in a flattened grey, which shows as a
-- slab on a coloured card; this renders black-on-white once and uses that
-- bitmap as the coverage mask for the ink (the approach Bookshelf's own
-- TransparentTextBox takes, extended to keep a colour ink a colour).
local _MText
local function mtextClass()
    if _MText then return _MText end
    local TextBoxWidget = require("ui/widget/textboxwidget")
    local Blitbuffer = require("ffi/blitbuffer")
    _MText = TextBoxWidget:extend{ ink = nil }
    function _MText:init()
        self.ink = self.fgcolor or Blitbuffer.COLOR_BLACK
        self.fgcolor = Blitbuffer.COLOR_BLACK
        self.bgcolor = Blitbuffer.COLOR_WHITE
        TextBoxWidget.init(self)
    end
    function _MText:paintTo(bb, x, y)
        local m = self._bb
        if not m then return TextBoxWidget.paintTo(self, bb, x, y) end
        if self.dimen then self.dimen.x, self.dimen.y = x, y end
        local w, h = m:getWidth(), m:getHeight()
        m:invertRect(0, 0, w, h)
        local ok
        if bb.colorblitFromRGB32 and Blitbuffer.isColor8 and not Blitbuffer.isColor8(self.ink) then
            ok = pcall(bb.colorblitFromRGB32, bb, m, x, y, 0, 0, w, h, self.ink)
        else
            ok = pcall(bb.colorblitFrom, bb, m, x, y, 0, 0, w, h, self.ink)
        end
        m:invertRect(0, 0, w, h)
        if not ok then TextBoxWidget.paintTo(self, bb, x, y) end
    end
    return _MText
end

-- ─── Canvas ──────────────────────────────────────────────────────────────────
-- One card. Things are placed at absolute pixel positions inside it, which
-- keeps layout and tap regions in the same coordinates.
--
-- Night mode: KOReader inverts the whole screen. A dark card would come out
-- pale, so a dark-toned canvas paints every colour pre-inverted and ends up
-- looking the same as by day. (The light "paper" card switches to a dark
-- variant at night for the same reason; see A.tone.) Covers are inverted
-- once more after they are drawn, so they keep their real colours.

local _Canvas
local function canvasClass()
    if _Canvas then return _Canvas end
    local Widget = require("ui/widget/widget")
    local Geom = require("ui/geometry")
    local C = Widget:extend{ w = 0, h = 0 }

    function C:init()
        self.ops = {}
        self.regions = {}
        self.owned = {}
        self.dimen = Geom:new{ w = self.w, h = self.h }
        local Screen = A.screen()
        -- Night mode inverts the screen. Cards meant to look the same day and
        -- night (every dark card, and every card of the newer themes) are
        -- painted pre-inverted.
        local tone = self.tone
        self.inv = (Screen.night_mode and tone and (tone.dark or tone.fixed)) and true or false
        -- Colour that sits under this canvas, in the canvas's own colour
        -- space. `page` = the Dashboard's page colour as it should LOOK, when
        -- this card is on one; otherwise Simple UI's background.
        if self.page then
            self.under = self.inv and self.page or A.shown(self.page)
        else
            local page_bg = A.pageColors()
            self.under = self.inv and { 255 - page_bg[1], 255 - page_bg[2], 255 - page_bg[3] } or page_bg
        end
    end

    function C:getSize() return Geom:new{ w = self.w, h = self.h } end

    function C:col(rgb) return A.color(rgb, self.inv) end

    function C:op(fn) self.ops[#self.ops + 1] = fn end

    function C:rect(x, y, w, h, rgb)
        local inv = self.inv
        self:op(function(bb, ox, oy) G.rect(bb, ox + x, oy + y, w, h, rgb, inv) end)
    end

    function C:rrect(x, y, w, h, r, rgb, under)
        local inv = self.inv
        under = under or (self.tone and self.tone.bg) or self.under
        self:op(function(bb, ox, oy) G.rrect(bb, ox + x, oy + y, w, h, r, rgb, under, inv) end)
    end

    function C:frame(x, y, w, h, r, bw, border, fill, under)
        local inv = self.inv
        under = under or (self.tone and self.tone.bg) or self.under
        self:op(function(bb, ox, oy) G.frame(bb, ox + x, oy + y, w, h, r, bw, border, fill, under, inv) end)
    end

    function C:disc(cx, cy, r, rgb, under)
        local inv = self.inv
        under = under or (self.tone and self.tone.bg) or self.under
        self:op(function(bb, ox, oy) G.disc(bb, ox + cx, oy + cy, r, rgb, under, inv) end)
    end

    function C:ring(cx, cy, R, t, frac, track, fill)
        local inv = self.inv
        local under = (self.tone and self.tone.bg) or self.under
        self:op(function(bb, ox, oy) G.ring(bb, ox + cx, oy + cy, R, t, frac, track, fill, under, inv) end)
    end

    -- A line through points { x1, y1, x2, y2, ... } in canvas coordinates.
    function C:polyline(pts, lw, rgb, under)
        local inv = self.inv
        under = under or (self.tone and self.tone.bg) or self.under
        self:op(function(bb, ox, oy)
            local moved = {}
            for i = 1, #pts, 2 do moved[i], moved[i + 1] = pts[i] + ox, pts[i + 1] + oy end
            G.polyline(bb, moved, lw, rgb, under, inv)
        end)
    end

    -- A single line of text. Returns { widget, w, h, base } without placing it.
    function C:text(str, px, o)
        o = o or {}
        local face, bold = A.face(px, o)
        local rgb = o.color or (self.tone and self.tone.fg) or { 0, 0, 0 }
        local txt = o.caps and A.upper(str) or A.safe(str)
        local tw = textClass():new{
            text = txt, face = face, bold = bold and true or false,
            fgcolor = self:col(rgb),
            max_width = o.max_w and max(8, floor(o.max_w)) or nil,
        }
        local sz = tw:getSize()
        self.owned[#self.owned + 1] = tw
        return { widget = tw, w = sz.w, h = sz.h, base = tw:getBaseline() or sz.h, px = px }
    end

    -- Wrapped text, at most `lines` lines (ellipsis after that).
    function C:textbox(str, px, width, lines, o)
        o = o or {}
        local face, bold = A.face(px, o)
        local rgb = o.color or (self.tone and self.tone.fg) or { 0, 0, 0 }
        local lh = o.line_height or 0.18
        local line_px = floor((1 + lh) * face.size + 0.5)
        local tb = mtextClass():new{
            text = o.caps and A.upper(str) or A.safe(str),
            face = face, bold = bold and true or false,
            width = max(20, floor(width)),
            height = lines and (line_px * lines) or nil,
            height_adjust = lines and true or nil,
            height_overflow_show_ellipsis = lines and true or nil,
            line_height = lh,
            alignment = o.align or "left",
            fgcolor = self:col(rgb),
        }
        local sz = tb:getSize()
        self.owned[#self.owned + 1] = tb
        return { widget = tb, w = sz.w, h = sz.h, base = sz.h, px = px, box = true }
    end

    -- Place a text. anchor: "l" (default), "c", "r" relative to x.
    -- valign: "top" (default), "base" (y is the baseline), "mid" (y is the centre).
    function C:put(t, x, y, anchor, valign)
        if anchor == "r" then x = x - t.w elseif anchor == "c" then x = x - t.w / 2 end
        if valign == "base" then y = y - t.base elseif valign == "mid" then y = y - t.h / 2 end
        x, y = floor(x + 0.5), floor(y + 0.5)
        local w = t.widget
        self:op(function(bb, ox, oy) w:paintTo(bb, ox + x, oy + y) end)
        return x, y
    end

    -- Create and place in one go. Returns the text record.
    function C:label(str, px, x, y, o)
        o = o or {}
        local t = self:text(str, px, o)
        self:put(t, x, y, o.anchor, o.valign)
        return t
    end

    -- A book cover, cropped to fill w x h. `fp` may be nil (placeholder).
    -- o = { title = (shown when there is no cover), edge = border colour,
    --       border = width or false, top = crop from the top, not the middle }
    function C:cover(fp, x, y, w, h, o)
        o = o or {}
        x, y, w, h = floor(x), floor(y), floor(w), floor(h)
        if w < 4 or h < 2 then return end
        local tone = self.tone or A.tone("ink")
        local src = fp and A.D and A.D.cover(fp, w, h, o.top and "top" or nil) or nil
        local inv = self.inv
        local bw = o.border == false and 0 or max(1, floor((o.border or 1)))
        local edge = o.edge or tone.muted
        local title
        if not src and o.title and w >= 40 then
            title = self:textbox(o.title, max(9, floor(w / 8)), w - floor(w / 6), 4,
                { bold = true, color = tone.fg, align = "center" })
        end
        self:op(function(bb, ox, oy)
            local X, Y = ox + x, oy + y
            if src then
                local sw, sh = src:getWidth(), src:getHeight()
                local sx = max(0, floor((sw - w) / 2))
                local sy = o.top and 0 or max(0, floor((sh - h) / 2))
                local Screen = A.screen()
                if Screen.sw_dithering and bb.ditherblitFrom then
                    bb:ditherblitFrom(src, X, Y, sx, sy, min(w, sw), min(h, sh))
                else
                    bb:blitFrom(src, X, Y, sx, sy, min(w, sw), min(h, sh))
                end
                -- keep the cover's real colours when the screen is inverted
                if Screen.night_mode then bb:invertRect(X, Y, min(w, sw), min(h, sh)) end
            else
                G.rect(bb, X, Y, w, h, tone.track, inv)
                if title then
                    title.widget:paintTo(bb, X + floor((w - title.w) / 2), Y + floor((h - title.h) / 2))
                end
            end
            if bw > 0 then
                local c = A.color(edge, inv)
                fillRect(bb, X, Y, w, bw, c)
                fillRect(bb, X, Y + h - bw, w, bw, c)
                fillRect(bb, X, Y, bw, h, c)
                fillRect(bb, X + w - bw, Y, bw, h, c)
            end
        end)
    end

    function C:region(id, x, y, w, h, pad)
        pad = pad or 0
        self.regions[#self.regions + 1] = {
            id = id, x = floor(x - pad), y = floor(y - pad), w = floor(w + 2 * pad), h = floor(h + 2 * pad),
        }
    end

    -- Nest another canvas at (x, y). Its tap regions come along, prefixed.
    function C:sub(child, x, y, prefix)
        x, y = floor(x), floor(y)
        self.owned[#self.owned + 1] = child
        self:op(function(bb, ox, oy) child:paintTo(bb, ox + x, oy + y, true) end)
        for _, r in ipairs(child.regions) do
            self.regions[#self.regions + 1] = {
                id = (prefix or "") .. r.id, x = r.x + x, y = r.y + y, w = r.w, h = r.h,
            }
        end
    end

    function C:paintTo(bb, x, y, nested)
        local w, h = self.w, self.h
        self.dimen = Geom:new{ x = x, y = y, w = w, h = h }
        local px, py, pw, ph = x, y, w, h
        -- `bleed`: let the panel run to the edges of an offscreen buffer it is
        -- centred in with a small inset (a host that paints modules that way).
        -- Simple UI does not, so this stays off; kept for the shared layout code.
        if self.bleed and not nested then
            local Screen = A.screen()
            local bw, bh = bb:getWidth(), bb:getHeight()
            local slack = Screen:scaleBySize(48)
            if (bw < Screen:getWidth() or bh < Screen:getHeight())
                    and bw - w >= 0 and bh - h >= 0 and bw - w <= slack and bh - h <= slack
                    and x == floor((bw - w) / 2) and y == floor((bh - h) / 2) then
                px, py, pw, ph = 0, 0, bw, bh
            end
        end
        if self.fill then G.rect(bb, px, py, pw, ph, self.fill, false) end
        local tone = self.tone
        if tone and not self.plain then
            local r = self.radius or 0
            if tone.border and (self.border_w or 0) > 0 then
                G.frame(bb, px, py, pw, ph, r, self.border_w, tone.border, tone.bg, self.under, self.inv)
            else
                G.rrect(bb, px, py, pw, ph, r, tone.bg, self.under, self.inv)
            end
        end
        for i = 1, #self.ops do self.ops[i](bb, x, y) end
    end

    function C:free()
        for _, wdg in ipairs(self.owned) do
            if wdg.free then pcall(wdg.free, wdg) end
        end
        self.owned, self.ops = {}, {}
    end

    _Canvas = C
    return C
end

--- A.canvas{ w=, h=, tone="ink"|table|nil, radius=, border_w=, bleed=bool, plain=bool }
function A.canvas(o)
    local tone = o.tone
    if type(tone) == "string" then tone = A.tone(tone) end
    return canvasClass():new{
        w = max(1, floor(o.w)), h = max(1, floor(o.h)), tone = tone,
        radius = o.radius, border_w = o.border_w, bleed = o.bleed, plain = o.plain, page = o.page,
        fill = o.fill,
    }
end

-- ─── formatting helpers ──────────────────────────────────────────────────────

function A.fmtMinutes(mins)
    mins = max(0, floor((tonumber(mins) or 0) + 0.5))
    local h, m = floor(mins / 60), mins % 60
    if h > 0 and m > 0 then return string.format("%d h %d m", h, m) end
    if h > 0 then return string.format("%d h", h) end
    return string.format("%d m", m)
end

-- 14894 -> "14,894"
function A.thousands(n)
    local str = tostring(floor((tonumber(n) or 0) + 0.5))
    local sign, digits = str:match("^(-?)(%d+)$")
    if not digits then return str end
    digits = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return sign .. digits
end

function A.plural(n, one, many)
    if n == 1 then return string.format("%d %s", n, one) end
    return string.format("%d %s", n, many)
end

-- Day/month names in the interface language (os.date gives English).
function A.date(fmt, t)
    local s = os.date(fmt, t)
    local ok, r = pcall(A.host.localizeDate, s)
    if ok and type(r) == "string" then return r end
    return s
end

-- Days since the epoch for a local calendar date, anchored at noon so a DST
-- shift cannot move the boundary.
function A.dayNumber(y, m, d)
    return floor(os.time{ year = y, month = m, day = d, hour = 12 } / 86400)
end

function A.parseYmd(s)
    if type(s) ~= "string" then return nil end
    local y, m, d = s:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)")
    if not y then return nil end
    return tonumber(y), tonumber(m), tonumber(d)
end

function A.todayYmd()
    local t = os.date("*t")
    return string.format("%04d-%02d-%02d", t.year, t.month, t.day), t
end

-- ─── load the other parts ────────────────────────────────────────────────────

local function part(name)
    local chunk, err = loadfile(A.dir .. "/" .. name .. ".lua")
    if not chunk then error("almanac: cannot load " .. name .. ".lua: " .. tostring(err)) end
    return chunk(A)
end

part("host")
part("data")
part("panels")
part("settings")
part("modules")
part("menus")

A.note(A.NAME .. " for " .. A.HOST, A.VERSION, "loaded from", A.dir)

return A
