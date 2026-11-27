-- FieldGuide - main window (ElvUI-like flat style)
local _, ns = ...
local L, FG = ns.L, ns.FG

local Window = {}
ns.Window = Window

local WHITE = "Interface\\Buttons\\WHITE8X8"
local BD = { bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 }
local TEMPLATE = BackdropTemplateMixin and "BackdropTemplate" or nil
local W, H = 1000, 660
local MIN_W, MIN_H, MAX_W, MAX_H = 620, 600, 2400, 1600
local GAP, BAR_PAD, CARD_H, CARD_MIN = 10, 8, 88, 200
local LIST_W, ROW_H = 270, 26
local FONT
local A, AD = ns.ACCENT, ns.ACCENT_DARK
local MUTED = { 0.64, 0.64, 0.64 }

local state = { faction = "all", tab = "all", cont = "all", harv = false, grey = false, myZone = false, q = "", sel = nil, status = nil }

---------------------------------------------------------------------------
-- Widget helpers
---------------------------------------------------------------------------
local function Box(parent, r, g, b, a, kind)
    local f = CreateFrame(kind or "Frame", nil, parent, TEMPLATE)
    f:SetBackdrop(BD)
    f:SetBackdropColor(r, g, b, a or 1)
    f:SetBackdropBorderColor(0, 0, 0, 1)
    return f
end

-- Number of columns that fit in a width, and the width of each column
local function Grid(width, count, minCell, gap)
    gap = gap or 8
    local cols = math.max(1, math.min(count, math.floor((width + gap) / (minCell + gap))))
    return cols, (width - (cols - 1) * gap) / cols
end

local function Text(parent, size, color, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(FONT, size, "")
    local c = color or { 0.95, 0.95, 0.95 }
    fs:SetTextColor(c[1], c[2], c[3])
    fs:SetJustifyH(justify or "LEFT")
    fs:SetWordWrap(false)
    return fs
end

local function Tip(frame, text)
    frame:SetScript("OnEnter", function(self)
        -- Anchored on the left edge and kept on screen (a centred tooltip was cut off at the screen edge)
        GameTooltip:SetOwner(self, "ANCHOR_NONE")
        GameTooltip:ClearAllPoints()
        GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -4)
        GameTooltip:SetClampedToScreen(true)
        GameTooltip:SetText(type(text) == "function" and text() or text, 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", GameTooltip_Hide)
end

local function HoverBorder(btn)
    btn:HookScript("OnEnter", function(self) self:SetBackdropBorderColor(A[1], A[2], A[3], 1) end)
    btn:HookScript("OnLeave", function(self) self:SetBackdropBorderColor(0, 0, 0, 1) end)
end

local MEDIA = ns.MEDIA

-- Small tinted icon from the addon's own textures
local function Icon(parent, name, size, color)
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetSize(size, size)
    t:SetTexture(MEDIA .. name)
    local c = color or MUTED
    t:SetVertexColor(c[1], c[2], c[3], 1)
    return t
end

-- Segmented button group (same height as the search box)
local function SegGroup(parent, items, onClick, isToggle)
    local g = Box(parent, 0.05, 0.05, 0.05, 1)
    g:SetHeight(32)
    g.buttons = {}
    local x = 2
    for _, it in ipairs(items) do
        local b = CreateFrame("Button", nil, g, TEMPLATE)
        b:SetBackdrop({ bgFile = WHITE })
        b:SetHeight(26)
        b.text = Text(b, 13, MUTED, "CENTER")
        b.text:SetText(it.label)
        local tw = math.ceil(b.text:GetStringWidth())
        local w = tw + 24
        b.text:SetPoint("CENTER")
        b:SetWidth(w)
        b:SetPoint("LEFT", g, "LEFT", x, 0)
        x = x + w + 2
        b.key, b.label = it.key, it.label
        b:SetScript("OnClick", function() onClick(it.key) end)
        if it.tip then Tip(b, it.tip) end
        g.buttons[#g.buttons + 1] = b
    end
    g:SetWidth(x)
    function g:Update(isOn)
        for _, b in ipairs(self.buttons) do
            local on = isOn(b.key)
            if on then
                b:SetBackdropColor(AD[1], AD[2], AD[3], 1)
                b.text:SetTextColor(1, 1, 1)
            else
                b:SetBackdropColor(0, 0, 0, 0)
                b.text:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
            end
        end
    end
    return g
end

-- Simple vertical scroll area with mouse wheel and a thin thumb
local function ScrollArea(parent)
    local sf = CreateFrame("ScrollFrame", nil, parent)
    local child = CreateFrame("Frame", nil, sf)
    child:SetSize(1, 1)
    sf:SetScrollChild(child)
    sf.child = child
    local thumb = sf:CreateTexture(nil, "OVERLAY")
    thumb:SetColorTexture(0.23, 0.23, 0.23, 1)
    thumb:SetWidth(4)
    sf.thumb = thumb
    function sf:UpdateThumb()
        local viewH, contentH = self:GetHeight(), self.child:GetHeight()
        if contentH <= viewH + 1 then thumb:Hide() return end
        thumb:Show()
        local h = math.max(20, viewH * viewH / contentH)
        local pos = self:GetVerticalScroll() / (contentH - viewH)
        thumb:SetHeight(h)
        thumb:ClearAllPoints()
        thumb:SetPoint("TOPRIGHT", self, "TOPRIGHT", -1, -(viewH - h) * pos)
    end
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(self, delta)
        local max = math.max(0, self.child:GetHeight() - self:GetHeight())
        local v = math.min(max, math.max(0, self:GetVerticalScroll() - delta * 52))
        self:SetVerticalScroll(v)
        self:UpdateThumb()
    end)
    sf:SetScript("OnSizeChanged", function(self, w) self.child:SetWidth(w) self:UpdateThumb() end)
    return sf
end

-- Pools for dynamic detail widgets
local pools = {}
local function Acquire(kind, factory)
    pools[kind] = pools[kind] or { free = {}, used = {} }
    local p = pools[kind]
    local w = table.remove(p.free) or factory()
    p.used[#p.used + 1] = w
    w:Show()
    return w
end
local function ReleaseAll()
    for _, p in pairs(pools) do
        for _, w in ipairs(p.used) do
            w:Hide()
            w:ClearAllPoints()
            p.free[#p.free + 1] = w
        end
        wipe(p.used)
    end
end

---------------------------------------------------------------------------
-- Entries
---------------------------------------------------------------------------
local function MobEntries()
    local out = {}
    for _, prof in ipairs({ "ore", "herb" }) do
        local mobs = ns.db.global.learnedMobs[prof]
        if mobs and next(mobs) then
            out[#out + 1] = { key = "mobs_" .. prof, type = prof, mobs = mobs, req = 0,
                name = prof == "ore" and L["Creatures (mining)"] or L["Creatures (herbalism)"] }
        end
    end
    return out
end

local function EntryName(r)
    return r.name or ns.Data:Name(r)
end

-- Lower-case name without accents or colour codes, for alphabetical sorting
local ACCENTS = {
    ["à"] = "a", ["â"] = "a", ["ä"] = "a", ["á"] = "a", ["ã"] = "a", ["ç"] = "c", ["é"] = "e", ["è"] = "e", ["ê"] = "e", ["ë"] = "e",
    ["î"] = "i", ["ï"] = "i", ["í"] = "i", ["ô"] = "o", ["ö"] = "o", ["ó"] = "o", ["õ"] = "o", ["ù"] = "u", ["û"] = "u", ["ü"] = "u",
    ["ú"] = "u", ["ñ"] = "n", ["ß"] = "ss", ["œ"] = "oe", ["É"] = "e", ["È"] = "e", ["Ê"] = "e", ["À"] = "a", ["Â"] = "a", ["Ç"] = "c",
    ["Î"] = "i", ["Ô"] = "o", ["Ö"] = "o", ["Ü"] = "u", ["Ä"] = "a",
}
local GROUP_ORDER = { special = 1, quest = 2, raidloot = 3, vendor = 4 }
local GROUP_LABEL = { special = "Special leathers and scales", quest = "Nat Pagle quest", raidloot = "Raid loot", vendor = "Sold by vendors" }

local function SortKey(name)
    name = tostring(name or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    for k, v in pairs(ACCENTS) do name = name:gsub(k, v) end
    return name:lower()
end

local function Matches(r, q, here)
    if state.tab ~= "all" and r.type ~= state.tab then return false end
    if r.mobs then return q == "" or EntryName(r):lower():find(q, 1, true) end
    local rank = FG:EffSkill(r.type)
    local band = r.loot and "none" or ns.Band(r.req, rank, ns.Data:Thresholds(r))
    if state.harv and band == "red" then return false end
    if state.grey and band == "grey" then return false end
    local zones = ns.Data:Zones(r)
    if state.cont ~= "all" then
        local ok = false
        for _, id in ipairs(zones) do if ns.Data.Continent(id) == state.cont then ok = true break end end
        if not ok then return false end
    end
    if state.myZone then
        local ok = false
        for _, id in ipairs(zones) do if id == here then ok = true break end end
        if not ok then return false end
    end
    if q ~= "" then
        if EntryName(r):lower():find(q, 1, true) then return true end
        for _, id in ipairs(zones) do
            if ns.ZoneName(id):lower():find(q, 1, true) then return true end
        end
        return false
    end
    return true
end

function Window:BuildList()
    local q = (state.q or ""):lower()
    local here = ns.CurrentZone()
    local list = {}
    for _, r in ipairs(ns.Data.Resources) do
        if Matches(r, q, here) then list[#list + 1] = r end
    end
    for _, r in ipairs(MobEntries()) do
        if Matches(r, q, here) then list[#list + 1] = r end
    end
    -- Profession order, then required level, then name (alphabetical, accents ignored)
    local rank, names = {}, {}
    for i, p in ipairs(ns.PROFS) do rank[p] = i end
    for _, r in ipairs(list) do names[r] = SortKey(EntryName(r)) end
    table.sort(list, function(a, b)
        if a.type ~= b.type then return (rank[a.type] or 99) < (rank[b.type] or 99) end
        local ga, gb = GROUP_ORDER[a.group or ""] or 0, GROUP_ORDER[b.group or ""] or 0
        if ga ~= gb then return ga < gb end -- grouped entries (special skins, quest fish) after the others
        if a.req ~= b.req then return a.req < b.req end
        return names[a] < names[b]
    end)
    return list
end

---------------------------------------------------------------------------
-- Construction
---------------------------------------------------------------------------
function Window:Create()
    FONT = ns.Font()
    local f = Box(UIParent, 0.1, 0.1, 0.1, ns.db.profile.window.alpha)
    _G.FieldGuideFrame = f
    self.frame = f
    f:SetSize(W, H)
    f:SetFrameStrata("MEDIUM")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        Window:PinTopLeft()
    end)
    tinsert(UISpecialFrames, "FieldGuideFrame")
    f.bg = f:CreateTexture(nil, "BACKGROUND", nil, 1)
    f.bg:SetPoint("TOPLEFT", 1, -1)
    f.bg:SetPoint("BOTTOMRIGHT", -1, 1)
    f.bg:SetColorTexture(0.1, 0.1, 0.1, 1)

    -- Header
    local header = Box(f, 0.07, 0.07, 0.07, 1)
    header:SetPoint("TOPLEFT")
    header:SetPoint("TOPRIGHT")
    header:SetHeight(36)
    local icon = header:CreateTexture(nil, "ARTWORK")
    icon:SetSize(22, 22)
    icon:SetPoint("LEFT", 8, 0)
    icon:SetTexture(MEDIA .. "Logo")
    local title = Text(header, 18)
    self.title = title
    title:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    title:SetText("Field|cff3aa0e8Guide|r |cffa3a3a3- " .. L["Field guide"] .. "|r")
    -- Version in a smaller font, on the title baseline
    local version = Text(header, 11, { 0.48, 0.48, 0.48 })
    self.version = version
    version:SetPoint("BOTTOMLEFT", title, "BOTTOMRIGHT", 6, 1)
    version:SetText("v" .. ns.VERSION)

    local close = Box(header, 0.1, 0.1, 0.1, 1, "Button")
    close:SetSize(26, 26)
    close:SetPoint("RIGHT", -6, 0)
    local x = Icon(close, "Close", 12)
    x:SetPoint("CENTER")
    close:HookScript("OnEnter", function() x:SetVertexColor(1, 0.42, 0.42, 1) end)
    close:HookScript("OnLeave", function() x:SetVertexColor(MUTED[1], MUTED[2], MUTED[3], 1) end)
    close:SetScript("OnClick", function() f:Hide() end)
    HoverBorder(close)

    local opt = Box(header, 0.1, 0.1, 0.1, 1, "Button")
    opt:SetSize(26, 26)
    opt:SetPoint("RIGHT", close, "LEFT", -4, 0)
    local gear = Icon(opt, "Gear", 14)
    gear:SetPoint("CENTER")
    opt:HookScript("OnEnter", function() gear:SetVertexColor(A[1], A[2], A[3], 1) end)
    opt:HookScript("OnLeave", function() gear:SetVertexColor(MUTED[1], MUTED[2], MUTED[3], 1) end)
    opt:SetScript("OnClick", function() ns.Options:Open() end)
    Tip(opt, L["Options"])
    HoverBorder(opt)

    local session = Box(header, 0.05, 0.05, 0.05, 1)
    session:SetHeight(26)
    session:SetPoint("RIGHT", opt, "LEFT", -8, 0)
    session.text = Text(session, 13, MUTED)
    session.text:SetPoint("LEFT", 10, 0)
    self.session = session

    -- Toolbar
    local bar = CreateFrame("Frame", nil, f)
    bar:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 0)
    bar:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, 0)
    bar:SetHeight(48)
    self.bar = bar
    local line = bar:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(0, 0, 0, 1)
    line:SetPoint("BOTTOMLEFT")
    line:SetPoint("BOTTOMRIGHT")
    line:SetHeight(1)

    local search = Box(bar, 0.05, 0.05, 0.05, 1, "EditBox")
    self.searchBox = search
    search:SetSize(200, 32)
    search:SetFont(FONT, 14, "")
    search:SetTextColor(0.95, 0.95, 0.95)
    search:SetAutoFocus(false)
    search:SetTextInsets(26, 8, 0, 0)
    local mag = Icon(search, "Search", 13)
    mag:SetPoint("LEFT", 9, 0)
    local ph = Text(search, 14, MUTED)
    ph:SetPoint("LEFT", 26, 0)
    ph:SetText(L["Search..."])
    search:SetTextInsets(26, 26, 0, 0)
    -- Clear button, shown only when there is text
    local clear = CreateFrame("Button", nil, search)
    clear:SetSize(18, 18)
    clear:SetPoint("RIGHT", -6, 0)
    clear.icon = Icon(clear, "Close", 10)
    clear.icon:SetPoint("CENTER")
    clear:Hide()
    clear:SetScript("OnEnter", function(self) self.icon:SetVertexColor(A[1], A[2], A[3], 1) end)
    clear:SetScript("OnLeave", function(self) self.icon:SetVertexColor(MUTED[1], MUTED[2], MUTED[3], 1) end)
    clear:SetScript("OnClick", function()
        search:SetText("")
        search:ClearFocus()
    end)
    search:SetScript("OnEscapePressed", search.ClearFocus)
    search:SetScript("OnEnterPressed", search.ClearFocus)
    search:SetScript("OnTextChanged", function(self)
        local t = self:GetText() or ""
        ph:SetShown(t == "")
        clear:SetShown(t ~= "")
        state.q = t
        Window:Refresh()
    end)
    HoverBorder(search)

    self.tabs = SegGroup(bar, {
        { key = "all", label = L["All"] }, { key = "herb", label = L["Herbs"] }, { key = "ore", label = L["Ores"] },
        { key = "skin", label = L["Skinning"] }, { key = "fish", label = L["Fishing"] },
    }, function(k) state.tab = k Window:Refresh() end)

    self.conts = SegGroup(bar, {
        { key = "all", label = L["All"], tip = L["All continents"] },
        { key = "EK", label = L["East"], tip = ns.ZoneName(ns.Data.EASTERN_ID) },
        { key = "KA", label = ns.ZoneName(ns.Data.KALIMDOR_ID) },
    }, function(k) state.cont = k Window:Refresh() end)

    self.chips = SegGroup(bar, {
        { key = "harv", label = L["Harvestable"], tip = L["Harvestable_tip"] },
        { key = "grey", label = L["No grey"], tip = L["No grey_tip"] },
        { key = "myZone", label = L["My zone"], tip = function()
            local z = ns.CurrentZone()
            return L["My zone_tip"]:format(z and ns.ZoneName(z) or "?")
        end },
    }, function(k) state[k] = not state[k] Window:Refresh() end, true)

    -- Filters saved per character (faction defaults to the player's own)
    local saved = ns.db.char.filters
    if type(saved) ~= "table" then saved = {} ns.db.char.filters = saved end
    state.faction = saved.faction or UnitFactionGroup("player") or "all"
    state.tab, state.cont = saved.tab or "all", saved.cont or "all"
    state.harv, state.grey, state.myZone = saved.harv or false, saved.grey or false, saved.myZone or false
    state.sel = saved.sel
    self.facs = SegGroup(bar, {
        { key = "all", label = L["All"], tip = L["All factions"] },
        { key = "Alliance", label = FACTION_ALLIANCE or "Alliance" },
        { key = "Horde", label = FACTION_HORDE or "Horde" },
    }, function(k) state.faction = k Window:Refresh(true) end)
    self.barItems = { search, self.tabs, self.conts, self.chips, self.facs }

    -- Default width: whole toolbar on one line (long labels in some languages)
    local full = GAP
    for _, item in ipairs(self.barItems) do full = full + item:GetWidth() + GAP end
    W = math.max(W, math.ceil(full))
    self.minW = W
    -- Narrowest width: list + a usable detail panel, or the widest toolbar element
    local minW = MIN_W
    for _, item in ipairs(self.barItems) do minW = math.max(minW, math.ceil(item:GetWidth() + 2 * GAP)) end
    local saved = ns.db.profile.window
    f:SetSize(math.max(minW, saved.w or W), math.max(MIN_H, saved.h or H))
    f:SetResizable(true)
    self.minResizeW = minW
    if f.SetResizeBounds then
        f:SetResizeBounds(minW, MIN_H, MAX_W, MAX_H)
    else
        f:SetMinResize(minW, MIN_H)
        f:SetMaxResize(MAX_W, MAX_H)
    end

    -- Progression strip
    local prog = Box(f, 0.08, 0.08, 0.08, 1)
    prog:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, 0)
    prog:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT", 0, 0)
    prog:SetHeight(104)
    self.prog = prog
    self.cards = {}
    for i, prof in ipairs(ns.PROFS) do
        local c = Box(prog, 0.12, 0.12, 0.12, 1)
        c:SetHeight(CARD_H)
        c.name = Text(c, 14)
        c.name:SetPoint("TOPLEFT", 10, -8)
        c.name:SetText(L["PROF_" .. prof])
        c.level = Text(c, 13, MUTED, "RIGHT")
        c.level:SetPoint("TOPRIGHT", -10, -9)
        c.barBg = Box(c, 0.05, 0.05, 0.05, 1)
        c.barBg:SetPoint("TOPLEFT", 10, -28)
        c.barBg:SetPoint("TOPRIGHT", -10, -28)
        c.barBg:SetHeight(6)
        c.bar = c.barBg:CreateTexture(nil, "ARTWORK")
        c.bar:SetPoint("TOPLEFT", 1, -1)
        c.bar:SetHeight(4)
        -- Next target: name on one line, zone (clickable) on the next
        c.target = Text(c, 13)
        c.target:SetPoint("TOPLEFT", 10, -40)
        c.target:SetPoint("RIGHT", -10, 0)
        c.zone = CreateFrame("Button", nil, c)
        c.zone:SetPoint("TOPLEFT", 10, -56)
        c.zone:SetPoint("RIGHT", -10, 0)
        c.zone:SetHeight(14)
        c.zone.icon = Icon(c.zone, "Map", 11, A)
        c.zone.icon:SetPoint("LEFT")
        c.zone.text = Text(c.zone, 12, MUTED)
        c.zone.text:SetPoint("LEFT", 15, 0)
        c.zone.text:SetPoint("RIGHT")
        c.zone:EnableMouse(false)
        -- Next target + zone: click opens its sheet (and shows its spawn points on the map)
        c.targetBtn = CreateFrame("Button", nil, c)
        c.targetBtn:SetPoint("TOPLEFT", 6, -38)
        c.targetBtn:SetPoint("RIGHT", -6, 0)
        c.targetBtn:SetHeight(30)
        c.targetBtn:SetScript("OnClick", function(self)
            if not self.res then return end
            Window:Select(self.res)
            if self.mapID then Window:ShowZonePoints(self.res, self.mapID) end
        end)
        c.targetBtn:SetScript("OnEnter", function(self)
            if not self.res then return end
            c.zone.text:SetTextColor(A[1], A[2], A[3])
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(ns.Data:Name(self.res), 1, 1, 1)
            GameTooltip:AddLine(L["Click to open its sheet and show its spawn points on the map."], 0.64, 0.64, 0.64, true)
            GameTooltip:Show()
        end)
        c.targetBtn:SetScript("OnLeave", function()
            c.zone.text:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
            GameTooltip:Hide()
        end)
        -- One alert line (all alerts are listed in the card tooltip)
        c.alertBtn = CreateFrame("Button", nil, c)
        c.alertBtn:SetPoint("TOPLEFT", 10, -70)
        c.alertBtn:SetPoint("RIGHT", -10, 0)
        c.alertBtn:SetHeight(16)
        c.alert = Text(c.alertBtn, 12)
        c.alert:SetPoint("LEFT")
        c.alert:SetPoint("RIGHT")
        c.alertBtn:SetScript("OnClick", function(self)
            local loc = self.loc
            if loc then Window:PinStatus(loc[2], loc[3], loc[4], ns.PlacePin(loc[2], loc[3], loc[4], loc[1], self.purpose)) end
        end)
        -- Clickable reminder: "Artisan :" stays blue, the rest looks like the zone line (grey, accent on hover)
        function c.alertBtn:Render(hover)
            if not self.loc then return end
            local rest = hover and ("|cff%02x%02x%02x"):format(A[1] * 255, A[2] * 255, A[3] * 255) or "|cffa3a3a3"
            c.alert:SetText("|cff7dc4f5" .. self.prefix .. "|r" .. rest .. self.rest .. "|r")
        end
        c.alertBtn:SetScript("OnEnter", function(self)
            self:Render(true)
            local h = c:GetScript("OnEnter")
            if h then h(c) end
        end)
        c.alertBtn:SetScript("OnLeave", function(self)
            self:Render(false)
            GameTooltip_Hide()
        end)
        c:EnableMouse(true)
        c:SetScript("OnEnter", function(self)
            if not self.tipLines or #self.tipLines == 0 then return end
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:AddLine(L["PROF_" .. prof], 1, 1, 1)
            for _, l in ipairs(self.tipLines) do GameTooltip:AddLine(l[1], l[2], l[3], l[4], true) end
            GameTooltip:Show()
        end)
        c:SetScript("OnLeave", GameTooltip_Hide)
        self.cards[prof] = c
    end

    -- Footer
    local footer = Box(f, 0.07, 0.07, 0.07, 1)
    footer:SetPoint("BOTTOMLEFT")
    footer:SetPoint("BOTTOMRIGHT")
    footer:SetHeight(24)
    self.count = Text(footer, 12, MUTED)
    self.count:SetPoint("LEFT", 10, 0)
    -- Hide or show the spawn points on the world map (visible while a herb or ore has points)
    local sb = CreateFrame("Button", nil, footer)
    self.spawnBtn = sb
    sb:SetHeight(20)
    sb:SetPoint("LEFT", self.count, "RIGHT", 16, 0)
    sb.icon = Icon(sb, "Map", 12, A)
    sb.icon:SetPoint("LEFT")
    sb.text = Text(sb, 12)
    sb.text:SetPoint("LEFT", 16, 0)
    sb:SetScript("OnClick", function() ns.SpawnMap:Toggle() end)
    sb:SetScript("OnEnter", function(self) self.text:SetTextColor(A[1], A[2], A[3]) end)
    sb:SetScript("OnLeave", function(self) self.text:SetTextColor(0.95, 0.95, 0.95) end)
    sb:Hide()
    self.statusText = Text(footer, 12, A, "RIGHT")
    self.statusText:SetPoint("RIGHT", -24, 0) -- clear of the resize grip

    -- List
    local listBg = CreateFrame("Frame", nil, f)
    listBg:SetPoint("TOPLEFT", prog, "BOTTOMLEFT", 0, 0)
    listBg:SetPoint("BOTTOMLEFT", footer, "TOPLEFT", 0, 0)
    listBg:SetWidth(ns.db.profile.window.listW or LIST_W)
    self.listBg = listBg
    local sep = listBg:CreateTexture(nil, "ARTWORK")
    sep:SetColorTexture(0, 0, 0, 1)
    sep:SetPoint("TOPRIGHT")
    sep:SetPoint("BOTTOMRIGHT")
    sep:SetWidth(1)
    self.list = ScrollArea(listBg)
    self.list:SetPoint("TOPLEFT", 1, -1)
    self.list:SetPoint("BOTTOMRIGHT", -2, 1)
    self.rows = {}
    self.empty = Text(listBg, 13, MUTED)
    self.empty:SetPoint("TOPLEFT", 12, -14)
    self.empty:SetText(L["No results with these filters."])

    -- Splitter: drag the list's right border to change its width
    local split = CreateFrame("Button", nil, f)
    split:SetPoint("TOPLEFT", listBg, "TOPRIGHT", -3, 0)
    split:SetPoint("BOTTOMLEFT", listBg, "BOTTOMRIGHT", -3, 0)
    split:SetWidth(7)
    split:SetFrameLevel(listBg:GetFrameLevel() + 10)
    split.line = split:CreateTexture(nil, "OVERLAY")
    split.line:SetPoint("TOP")
    split.line:SetPoint("BOTTOM")
    split.line:SetWidth(2)
    split.line:SetColorTexture(A[1], A[2], A[3], 1)
    split.line:Hide()
    split:SetScript("OnEnter", function(self)
        self.line:Show()
        if SetCursor then SetCursor("UI_RESIZE_CURSOR") end
    end)
    split:SetScript("OnLeave", function(self)
        if not self:GetScript("OnUpdate") then self.line:Hide() end
        if ResetCursor then ResetCursor() end
    end)
    local function StopSplit()
        if not split:GetScript("OnUpdate") then return end
        split:SetScript("OnUpdate", nil)
        if not split:IsMouseOver() then split.line:Hide() end
        ns.db.profile.window.listW = listBg:GetWidth()
        Window:Refresh(true)
    end
    split:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" then return end
        local scale = f:GetEffectiveScale()
        local startX, startW = GetCursorPosition() / scale, listBg:GetWidth()
        self:SetScript("OnUpdate", function()
            if not IsMouseButtonDown("LeftButton") then StopSplit() return end
            local x = GetCursorPosition() / scale
            listBg:SetWidth(Window:ClampListWidth(startW + (x - startX)))
        end)
    end)
    split:SetScript("OnMouseUp", StopSplit)

    -- Detail
    self.detail = ScrollArea(f)
    self.detail:SetPoint("TOPLEFT", listBg, "TOPRIGHT", 0, -1)
    self.detail:SetPoint("BOTTOMRIGHT", footer, "TOPRIGHT", -2, 1)

    -- Resize grip (bottom-right corner)
    local grip = CreateFrame("Button", nil, f)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -2, 2)
    grip:SetFrameLevel(footer:GetFrameLevel() + 5)
    local gt = Icon(grip, "Resize", 14)
    gt:SetPoint("CENTER")
    grip:SetScript("OnEnter", function() gt:SetVertexColor(A[1], A[2], A[3], 1) end)
    grip:SetScript("OnLeave", function() gt:SetVertexColor(MUTED[1], MUTED[2], MUTED[3], 1) end)
    -- Manual sizing from the top-left anchor (StartSizing can make the window jump bigger),
    -- always kept inside the screen so the corner stays reachable
    local function StopSizing()
        if not grip:GetScript("OnUpdate") then return end
        grip:SetScript("OnUpdate", nil)
        ns.db.profile.window.w, ns.db.profile.window.h = f:GetWidth(), f:GetHeight()
        Window:PinTopLeft()
        Window:Refresh(true)
    end
    grip:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" then return end
        Window:PinTopLeft()
        local scale = f:GetEffectiveScale()
        local cx, cy = GetCursorPosition()
        local sx, sy, sw, sh = cx / scale, cy / scale, f:GetWidth(), f:GetHeight()
        grip:SetScript("OnUpdate", function()
            if not IsMouseButtonDown("LeftButton") then StopSizing() return end
            local x, y = GetCursorPosition()
            x, y = x / scale, y / scale
            local left, top = f:GetLeft() or 0, f:GetTop() or MIN_H
            local screenW = UIParent:GetWidth() * UIParent:GetEffectiveScale() / scale
            local w = math.max(Window.minResizeW, math.min(sw + (x - sx), MAX_W, screenW - left))
            local h = math.max(MIN_H, math.min(sh - (y - sy), MAX_H, top))
            f:SetSize(w, h)
        end)
    end)
    grip:SetScript("OnMouseUp", StopSizing)
    f:SetScript("OnSizeChanged", function()
        Window:Layout()
        if Window.resizePending then return end
        Window.resizePending = true
        C_Timer.After(0.1, function()
            Window.resizePending = nil
            if f:IsShown() then Window:Refresh(true) end
        end)
    end)
    self:Layout()

    if ns.db.profile.window.point then
        local p = ns.db.profile.window.point
        f:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    else
        f:SetPoint("CENTER")
    end
    f:SetScript("OnShow", function() Window:PinTopLeft() Window:Refresh(true) end)
    f:Hide()
    FG:RegisterEvent("ZONE_CHANGED_NEW_AREA", function() if f:IsShown() then Window:Refresh() end end)
end

---------------------------------------------------------------------------
-- Rows
---------------------------------------------------------------------------
local function CreateRow(parent)
    local b = CreateFrame("Button", nil, parent, TEMPLATE)
    b:SetBackdrop({ bgFile = WHITE })
    b:SetHeight(ROW_H)
    b.dot = b:CreateTexture(nil, "ARTWORK")
    b.dot:SetSize(8, 8)
    b.dot:SetPoint("LEFT", 12, 0)
    b.dot:SetTexture(MEDIA .. "Dot")
    b.name = Text(b, 14)
    b.name:SetPoint("LEFT", 28, 0)
    b.name:SetPoint("RIGHT", -44, 0)
    b.req = Text(b, 13, MUTED, "RIGHT")
    b.req:SetPoint("RIGHT", -12, 0)
    local line = b:CreateTexture(nil, "BORDER")
    line:SetColorTexture(0, 0, 0, 1)
    line:SetPoint("BOTTOMLEFT")
    line:SetPoint("BOTTOMRIGHT")
    line:SetHeight(1)
    b:SetScript("OnEnter", function(self) if not self.selected then self:SetBackdropColor(0.15, 0.15, 0.15, 1) end end)
    b:SetScript("OnLeave", function(self) if not self.selected then self:SetBackdropColor(0, 0, 0, 0) end end)
    return b
end

local DOT = { herb = { 0.25, 0.75, 0.25 }, ore = { 0.79, 0.64, 0.29 }, skin = { 0.75, 0.48, 0.29 }, fish = { 0.23, 0.63, 0.91 } }

---------------------------------------------------------------------------
-- Detail
---------------------------------------------------------------------------
local function SectionTitle(parent, y, text)
    local fs = Acquire("title", function() return Text(parent, 12, MUTED) end)
    fs:SetPoint("TOPLEFT", 16, -y)
    fs:SetText(text:upper())
    return y + 20
end

local function NewChip(parent)
    local b = Box(parent, 0.13, 0.13, 0.13, 1, "Button")
    b:SetHeight(24)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetSize(16, 16)
    b.icon:SetPoint("LEFT", 4, 0)
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    b.text = Text(b, 13)
    b.text:SetPoint("LEFT", b.icon, "RIGHT", 6, 0)
    b:SetScript("OnEnter", function(self)
        if not self.itemID then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(self.itemID)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    return b
end

local function NewInfoRow(parent)
    local b = Box(parent, 0.13, 0.13, 0.13, 1)
    b:SetHeight(26)
    b.left = Text(b, 13)
    b.left:SetPoint("LEFT", 10, 0)
    b.right = Text(b, 13, { 0.82, 0.82, 0.82 }, "RIGHT")
    b.right:SetPoint("RIGHT", -10, 0)
    b.right:SetPoint("LEFT", b.left, "RIGHT", 12, 0)
    return b
end

local function NewRecipeRow(parent)
    local b = Box(parent, 0.13, 0.13, 0.13, 1, "Button")
    b:SetHeight(28)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetSize(20, 20)
    b.icon:SetPoint("LEFT", 6, 0)
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    b.name = Text(b, 14)
    b.name:SetPoint("LEFT", 32, 0)
    b.name:SetPoint("RIGHT", -8, 0)
    b:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(A[1], A[2], A[3], 1)
        if self.itemID then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(self.itemID)
            GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0, 0, 0, 1)
        GameTooltip:Hide()
    end)
    return b
end

-- One vendor (or drop zone): click places a map pin when its position is known
local function NewVendorRow(parent)
    local b = CreateFrame("Button", nil, parent, TEMPLATE)
    b:SetBackdrop({ bgFile = WHITE })
    b:SetBackdropColor(0, 0, 0, 0)
    b:SetHeight(22)
    b.map = Icon(b, "Map", 13, A)
    b.map:SetPoint("LEFT", 2, 0)
    b.text = Text(b, 13)
    b.text:SetPoint("LEFT", 22, 0)
    b.text:SetPoint("RIGHT", -6, 0)
    b:SetScript("OnClick", function(self)
        if self.mapID and self.x then
            Window:PinStatus(self.mapID, self.x, self.y, ns.PlacePin(self.mapID, self.x, self.y, self.label, self.purpose))
        end
    end)
    b:SetScript("OnEnter", function(self) self:SetBackdropColor(0.15, 0.15, 0.15, 1) end)
    b:SetScript("OnLeave", function(self) self:SetBackdropColor(0, 0, 0, 0) end)
    return b
end

local function NewStat(parent)
    local b = Box(parent, 0.13, 0.13, 0.13, 1)
    b:SetHeight(50)
    b.label = Text(b, 12, MUTED)
    b.label:SetPoint("TOPLEFT", 10, -7)
    b.value = Text(b, 18)
    b.value:SetPoint("TOPLEFT", 10, -24)
    b.value:SetPoint("RIGHT", -8, 0)
    return b
end

local function NewZone(parent)
    local b = Box(parent, 0.13, 0.13, 0.13, 1, "Button")
    b:SetHeight(38)
    b.name = Text(b, 14)
    b.name:SetPoint("TOPLEFT", 10, -5)
    b.name:SetPoint("RIGHT", -30, 0)
    b.info = Text(b, 12, MUTED)
    b.info:SetPoint("TOPLEFT", 10, -21)
    b.info:SetPoint("RIGHT", -30, 0)
    b.map = Icon(b, "Map", 16, A)
    b.map:SetPoint("RIGHT", -10, 0)
    b:SetScript("OnClick", function(self)
        if not self.clickable then return end
        if self.active then Window:HideZonePoints(self.res) else Window:ShowZonePoints(self.res, self.mapID) end
    end)
    b:SetScript("OnEnter", function(self)
        if not self.clickable then return end
        self:SetBackdropBorderColor(A[1], A[2], A[3], 1)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(ns.ZoneName(self.mapID), 1, 1, 1)
        GameTooltip:AddLine(self.active and L["Click to hide these points from the world map."]
            or L["Click to show these points on the world map."], 0.64, 0.64, 0.64, true)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function(self)
        if not self.active then self:SetBackdropBorderColor(0, 0, 0, 1) end
        GameTooltip:Hide()
    end)
    return b
end

local function TimeOfDayText(r)
    if r.time == "night" then return L["Mostly at night"] end
    if r.time == "day" then return L["Not between 00:00 and 06:00"] end
    if r.season == "summer" then return L["Spring to autumn (seasonal)"] end
    if r.season == "winter" then return L["Autumn to spring (seasonal)"] end
    return L["Day and night"]
end

local function LureText(r, rank)
    local diff = r.req - (rank or 0)
    if diff <= 0 then return L["None needed"] end
    for _, lure in ipairs(ns.Data.Lures) do
        if lure[2] >= diff then
            return (ns.GetItemInfo(lure[1]) or "?") .. " (+" .. lure[2] .. ")"
        end
    end
    local last = ns.Data.Lures[#ns.Data.Lures]
    return (ns.GetItemInfo(last[1]) or "?") .. " (+" .. last[2] .. ")"
end

function Window:BuildDetail(r)
    ReleaseAll()
    local content = self.detail.child
    if not r then content:SetHeight(1) self.detail:UpdateThumb() return end
    local cw = self.detail:GetWidth() - 32
    local y = 14

    -- Points on the world map are shown per zone: counts for the zone boxes
    local SM = ns.SpawnMap
    local byMap = SM:Count(r)
    local anyPoint = byMap and next(byMap) ~= nil

    local rank, max, mod = FG:Skill(r.type)
    local eff = FG:EffSkill(r.type)
    local band = r.mobs and "orange" or (r.loot and "grey") or ns.Band(r.req, eff, ns.Data:Thresholds(r))
    local col = r.loot and { 0.95, 0.95, 0.95 } or ns.BAND[band]

    local typeFs = Acquire("title", function() return Text(content, 12, MUTED) end)
    typeFs:SetPoint("TOPLEFT", 16, -y)
    typeFs:SetText(L["PROF_" .. r.type]:upper())
    local nameFs = Acquire("bigname", function() return Text(content, 22) end)
    nameFs:SetPoint("TOPLEFT", 16, -(y + 16))
    nameFs:SetText(EntryName(r))
    nameFs:SetTextColor(col[1], col[2], col[3])
    y = y + 52

    -- Points on the world map: what is shown (with a link to hide it), or how to show it
    if byMap then
        local showing = SM:IsShowing(r)
        local line = Acquire("spawnline", function()
            local f = CreateFrame("Frame", nil, content)
            f:SetHeight(16)
            f.icon = Icon(f, "Map", 13, A)
            f.icon:SetPoint("TOPLEFT", 0, -1)
            f.btn = CreateFrame("Button", nil, f)
            f.btn:SetHeight(16)
            f.btn:SetPoint("TOPRIGHT")
            f.btn.text = Text(f.btn, 12)
            f.btn.text:SetPoint("RIGHT")
            f.btn:SetScript("OnEnter", function(b) b.text:SetTextColor(A[1], A[2], A[3]) end)
            f.btn:SetScript("OnLeave", function(b) b.text:SetTextColor(0.95, 0.95, 0.95) end)
            f.btn:SetScript("OnClick", function(b)
                if b.mapID then Window:ShowZonePoints(b.res, b.mapID) else Window:HideZonePoints(b.res) end
            end)
            f.text = Text(f, 12, A)
            f.text:SetWordWrap(true)
            f.text:SetPoint("TOPLEFT", 18, 0)
            f.text:SetPoint("RIGHT", f.btn, "LEFT", -10, 0)
            return f
        end)
        line:SetPoint("TOPLEFT", 16, -y)
        line:SetWidth(cw)
        line.btn.res, line.btn.mapID = r, nil
        if showing then
            line.text:SetText(L["SPAWN_SHOWN_ZONE"]:format(SM.counts.total, ns.ZoneName(SM.currentMap)))
            line.text:SetTextColor(A[1], A[2], A[3])
            line.btn.text:SetText(L["Hide from the map"])
            line.btn:Show()
        elseif not anyPoint then
            line.text:SetText(L[r.type == "skin" and "SPAWN_NONE_SKIN" or "SPAWN_NONE"])
            line.text:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
            line.btn:Hide()
        elseif r.quest and r.spot and byMap[r.spot.map] then
            -- Quest fish: no zone list, the link shows its fishing zone
            line.text:SetText(L["SPAWN_CLICK_ZONE"])
            line.text:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
            line.btn.mapID = r.spot.map
            line.btn.text:SetText(L["Show on the map"])
            line.btn:Show()
        else
            line.text:SetText(L["SPAWN_CLICK_ZONE"])
            line.text:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
            line.btn:Hide()
        end
        line.btn.text:SetTextColor(0.95, 0.95, 0.95)
        line.btn:SetWidth(line.btn:IsShown() and ((line.btn.text:GetStringWidth() or 60) + 4) or 1)
        line.icon:SetAlpha(showing and 1 or 0.5)
        local h = math.max(16, math.ceil(line.text:GetStringHeight() or 14))
        line:SetHeight(h)
        y = y + h + 10
    end

    if r.quest then
        y = self:BuildQuestDetail(r, content, cw, y, rank, max)
        content:SetHeight(y + 10)
        self.detail:SetVerticalScroll(0)
        self.detail:UpdateThumb()
        return
    end

    if r.mobs then
        y = SectionTitle(content, y, L["Also on creatures"])
        local hint = Acquire("hint", function() local t = Text(content, 12, MUTED) t:SetWordWrap(true) return t end)
        hint:SetPoint("TOPLEFT", 16, -y)
        hint:SetWidth(cw)
        hint:SetText(L["Creatures you have seen that can be gathered."])
        y = y + 22
        local names = {}
        for n in pairs(r.mobs) do names[#names + 1] = n end
        table.sort(names)
        for _, n in ipairs(names) do
            local row = Acquire("info", function() return NewInfoRow(content) end)
            row:SetPoint("TOPLEFT", 16, -y)
            row:SetWidth(cw)
            row.left:SetText(n)
            local zs = {}
            for id in pairs(r.mobs[n]) do zs[#zs + 1] = ns.ZoneName(id) end
            row.right:SetText(table.concat(zs, ", "))
            y = y + 30
        end
        content:SetHeight(y + 10)
        self.detail:UpdateThumb()
        return
    end

    -- Stats
    local stats = {
        { L["Required skill"], r.loot and L["None needed"] or tostring(r.req), r.loot and MUTED or col },
        { L["Your level"], rank and (rank .. "/" .. max .. ((mod and mod > 0) and (" |cff40c040+" .. mod .. "|r") or "")) or L["Not learned"], { 0.95, 0.95, 0.95 } },
        { L["Skill points"], L["GAIN_" .. band], col },
    }
    local cols, sw = Grid(cw, #stats, 130)
    for i, s in ipairs(stats) do
        local b = Acquire("stat", function() return NewStat(content) end)
        local col, row = (i - 1) % cols, math.floor((i - 1) / cols)
        b:SetPoint("TOPLEFT", 16 + col * (sw + 8), -(y + row * 58))
        b:SetWidth(sw)
        b.label:SetText(s[1])
        b.value:SetText(s[2])
        b.value:SetTextColor(s[3][1], s[3][2], s[3][3])
    end
    y = y + math.ceil(#stats / cols) * 58 + 4

    -- What it gives
    local items = {}
    -- Fish: show what it becomes (cooked dish or alchemy oil), not the raw catch
    if r.item and r.type ~= "fish" then items[#items + 1] = { r.item } end
    for _, id in ipairs(r.extra or {}) do items[#items + 1] = { id, true } end
    for i, id in ipairs(r.gives or {}) do items[#items + 1] = { id, r.type == "skin" and i > 1 } end
    if #items > 0 then
        y = SectionTitle(content, y, L["What it gives"])
        local x = 0
        for _, it in ipairs(items) do
            local chip = Acquire("chip", function() return NewChip(content) end)
            local name, _, quality = ns.GetItemInfo(it[1])
            chip.itemID = it[1]
            chip.icon:SetTexture(ns.GetItemIcon(it[1]))
            local text = name or ("#" .. it[1])
            if it[2] then text = text .. " |cffa3a3a3(" .. L["rare"] .. ")|r" end
            chip.text:SetText(text)
            local r1, g1, b1 = 1, 1, 1
            if quality and GetItemQualityColor then r1, g1, b1 = GetItemQualityColor(quality) end
            chip.text:SetTextColor(r1, g1, b1)
            local w = math.ceil(chip.text:GetStringWidth()) + 34
            if x > 0 and x + w > cw then x = 0 y = y + 28 end
            chip:SetWidth(w)
            chip:SetPoint("TOPLEFT", 16 + x, -y)
            x = x + w + 6
        end
        y = y + 36
    end

    -- Vendor-only items: where to buy them
    if r.buy then
        y = SectionTitle(content, y, L["Where to buy"])
        for _, v in ipairs(r.buy) do
            local row = Acquire("vendor", function() return NewVendorRow(content) end)
            row:SetPoint("TOPLEFT", 28, -y)
            row:SetWidth(cw - 12)
            row.mapID, row.x, row.y = v[2], v[3], v[4]
            row.label = v[1] or L["Vendor"]
            row.purpose = L["Sells %s"]:format(EntryName(r))
            local coords = v[3] and ("  |cfff2f2f2" .. ("%.1f, %.1f"):format(v[3], v[4]) .. "|r") or ""
            row.text:SetText("|cfff2f2f2" .. (v[1] or L["Vendor"]) .. "|r  |cffa3a3a3" .. ns.ZoneName(v[2]) .. "|r" .. coords)
            y = y + 24
        end
        y = y + 8
    end

    -- Recipe, then one clickable line per vendor (player's faction first)
    if r.recipe or r.source then
        y = SectionTitle(content, y, L["Recipes and where to get them"])
        local rec = r.recipe
        if rec then
            local head = Acquire("recipe", function() return NewRecipeRow(content) end)
            head:SetPoint("TOPLEFT", 16, -y)
            head:SetWidth(cw)
            local name = ns.GetItemInfo(rec.item)
            if name and not rec.isRecipe then name = L["Recipe: %s"]:format(name) end
            head.itemID = rec.item
            head.icon:SetTexture(ns.GetItemIcon(rec.item))
            head.name:SetText("|cff1eff00" .. (name or ("#" .. rec.item)) .. "|r")
            y = y + 32
            local mine = state.faction ~= "all" and state.faction or UnitFactionGroup("player")
            local order = { own = {}, neutral = {}, other = {} }
            for _, v in ipairs(rec.vendors or {}) do
                local bucket = (not v[3] and "neutral") or (v[3] == mine and "own") or "other"
                if bucket ~= "other" or state.faction == "all" then table.insert(order[bucket], v) end
            end
            local lines = {}
            for _, k in ipairs({ "own", "neutral", "other" }) do
                for _, v in ipairs(order[k]) do lines[#lines + 1] = { v[1], v[2], v[3], k == "other", v[4], v[5] } end
            end
            if rec.drop then lines[#lines + 1] = { L["Rare drop"], rec.drop } end
            if rec.object then
                local o = rec.object
                lines[#lines + 1] = { L["Found in the world"], o.map, nil, false, o.x, o.y, name, true }
            end
            if #lines == 0 then
                local hint = Acquire("hint", function() local t = Text(content, 12, MUTED) t:SetWordWrap(true) return t end)
                hint:SetPoint("TOPLEFT", 28, -y)
                hint:SetWidth(cw - 12)
                hint:SetText(L["No vendor for this faction."])
                y = y + 22
            end
            for _, v in ipairs(lines) do
                local row = Acquire("vendor", function() return NewVendorRow(content) end)
                row:SetPoint("TOPLEFT", 28, -y)
                row:SetWidth(cw - 12)
                row.mapID, row.x, row.y = v[2], v[5], v[6]
                -- Vendor: "Sells <recipe>"; world object: the recipe found there
                local recipeName = name or ("#" .. rec.item)
                if v[8] then
                    row.label, row.purpose = recipeName, L["Found in the world"]
                else
                    row.label, row.purpose = v[1], L["Sells %s"]:format(recipeName)
                end
                local fac = v[3] and (v[3] == "Horde" and (FACTION_HORDE or "Horde") or (FACTION_ALLIANCE or "Alliance")) or nil
                local c = v[4] and "|cff7a7a7a" or "|cfff2f2f2"
                local coords = v[5] and ("  |cfff2f2f2" .. ("%.1f, %.1f"):format(v[5], v[6]) .. "|r") or ""
                row.text:SetText(c .. v[1] .. "|r  |cffa3a3a3" .. ns.ZoneName(v[2]) .. (fac and (" · " .. fac) or "") .. "|r" .. coords)
                y = y + 24
            end
        end
        if r.source and r.source.trainer == "alchemy" then
            local row = Acquire("info", function() return NewInfoRow(content) end)
            row:SetPoint("TOPLEFT", 16, -y)
            row:SetWidth(cw)
            row.left:SetText("|cff1eff00" .. L["Used in alchemy"] .. "|r")
            row.right:SetText(L["SRC_ALCHEMY_TRAINER"])
            y = y + 30
        end
        y = y + 8
    end

    -- Skinning above 300: bonuses needed; dungeon and raid sources
    if r.type == "skin" and r.req > ns.MaxCap then
        local hint = Acquire("hint", function() local t = Text(content, 12, MUTED) t:SetWordWrap(true) return t end)
        hint:SetPoint("TOPLEFT", 16, -y)
        hint:SetWidth(cw)
        hint:SetText(L["SKIN_BONUS_HINT"])
        y = y + math.max(18, math.ceil(hint:GetStringHeight() or 14) + 8)
    end
    if r.where then
        local inst, open = false, false
        for _, w in ipairs(r.where) do if w[1] then inst = true else open = true end end
        y = SectionTitle(content, y, (inst and open and L["Creatures and dungeons"]) or (inst and L["Dungeons and raids"]) or L["Creatures"])
        for _, w in ipairs(r.where) do
            local row = Acquire("info", function() return NewInfoRow(content) end)
            row:SetPoint("TOPLEFT", 16, -y)
            row:SetWidth(cw)
            local inst = w[1]
            local name = inst and ((C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(inst[1]) or {}).name or inst[2]) or ""
            local who = w[2] and (rawget(L, "BOSS_" .. w[2]) or w[2]) or ""
            row.left:SetText(name ~= "" and name or who)
            row.right:SetText((name ~= "" and who or "") .. (w[3] and ("  |cffa3a3a3" .. L["Req"] .. " " .. w[3] .. "|r") or ""))
            y = y + 30
        end
        y = y + 4
    end

    -- Fishing above 300: requirements include pole and lure bonuses
    if r.type == "fish" then
        local high = r.req > ns.MaxCap
        for _, id in ipairs(ns.Data:Zones(r)) do
            if (ns.Data.FishZoneSkill[id] or 0) > ns.MaxCap then high = true end
        end
        if high then
            local hint = Acquire("hint", function() local t = Text(content, 12, MUTED) t:SetWordWrap(true) return t end)
            hint:SetPoint("TOPLEFT", 16, -y)
            hint:SetWidth(cw)
            hint:SetText(L["FISH_BONUS_HINT"])
            y = y + math.max(18, math.ceil(hint:GetStringHeight() or 14) + 8)
        end
    end

    -- Fishing details
    if r.type == "fish" then
        local hour = GetGameTime()
        local night = hour >= 18 or hour < 6
        local boxes = {
            { L["Time of day"], TimeOfDayText(r), night and L["It is currently night"] or L["It is currently day"] },
            { L["Recommended lure"], LureText(r, rank) },
        }
        local bcols, bw = Grid(cw, #boxes, 220)
        for i, s in ipairs(boxes) do
            local b = Acquire("stat", function() return NewStat(content) end)
            local col, row = (i - 1) % bcols, math.floor((i - 1) / bcols)
            b:SetPoint("TOPLEFT", 16 + col * (bw + 8), -(y + row * 58))
            b:SetWidth(bw)
            b.label:SetText(s[1] .. (s[3] and (" · " .. s[3]) or ""))
            b.value:SetText(s[2])
            b.value:SetTextColor(i == 2 and 0.12 or 0.95, i == 2 and 1 or 0.95, i == 2 and 0 or 0.95)
        end
        y = y + math.ceil(#boxes / bcols) * 58 + 4
    end

    -- Zones
    local zoneTitle = (r.type == "skin" and L["Zones for these beasts"]) or (r.type == "fish" and L["Fishing zones"]) or L["Gathering zones"]
    y = SectionTitle(content, y, zoneTitle)
    local zones, seen = ns.Data:Zones(r)
    local zcols, zw = Grid(cw, 2, 200)
    for i, id in ipairs(zones) do
        local b = Acquire("zone", function() return NewZone(content) end)
        local col2 = (i - 1) % zcols
        b:SetPoint("TOPLEFT", 16 + col2 * (zw + 8), -y)
        b:SetWidth(zw)
        b.mapID = id
        b.name:SetText(ns.ZoneName(id))
        local info
        if seen[id] == "learned" then
            info = L["Recorded by you"]
        elseif r.type == "skin" then
            local lv = ns.Data.ZoneLevels[id]
            info = lv and L["Level %s"]:format(lv[1] .. "-" .. lv[2]) or ""
            local n = byMap and byMap[id]
            if n then info = info .. "  ·  " .. L["%d places skinned"]:format(n) end
        elseif r.type == "fish" then
            info = L["Fishing min. %d"]:format(math.max(ns.Data.FishZoneSkill[id] or 1, r.req))
            local n = byMap and byMap[id]
            if n then info = info .. "  ·  " .. L["%d fishing spots"]:format(n) end
        else
            info = ns.ZoneName(ns.Data.Continent(id) == "KA" and ns.Data.KALIMDOR_ID or ns.Data.EASTERN_ID)
            local n = byMap and byMap[id]
            if n then info = info .. "  ·  " .. L["%d spawn points"]:format(n) end
        end
        b.info:SetText(info)
        -- Zones with points: click shows them on the world map (only this zone)
        b.res = r
        b.clickable = byMap and (byMap[id] or 0) > 0
        b.active = b.clickable and SM:IsShowing(r, id)
        b:EnableMouse(b.clickable and true or false)
        b.map:SetShown(b.clickable and true or false)
        b.map:SetAlpha(b.active and 1 or 0.6)
        b:SetBackdropBorderColor(b.active and A[1] or 0, b.active and A[2] or 0, b.active and A[3] or 0, 1)
        if col2 == zcols - 1 or i == #zones then y = y + 44 end
    end
    y = y + 10

    content:SetHeight(y)
    self.detail:SetVerticalScroll(0)
    self.detail:UpdateThumb()
end

-- Nat Pagle quest fish: status, fishing spot with a map pin, quest giver
function Window:BuildQuestDetail(r, content, cw, y, rank, max)
    local np = ns.Data.NAT_PAGLE
    local done, onQuest = ns.IsQuestDone(np.quest), ns.IsOnQuest(np.quest)
    local caught, total = 0, 0
    for _, q in ipairs(ns.Data.Resources) do
        if q.quest == np.quest then
            total = total + 1
            if (ns.GetItemCount(q.item) or 0) > 0 then caught = caught + 1 end
        end
    end
    local status = done and L["Completed"] or (onQuest and L["In progress"] or L["Not taken"])
    local stats = {
        { L["Required skill"], tostring(r.req), ns.BAND[ns.Band(r.req, rank)] },
        { L["Quest status"], status, done and { 0.25, 0.75, 0.25 } or (onQuest and { 0.95, 0.95, 0.95 } or MUTED) },
        { L["Caught"], ("%d/%d"):format(caught, total), caught == total and { 0.25, 0.75, 0.25 } or { 0.95, 0.95, 0.95 } },
    }
    local cols, sw = Grid(cw, #stats, 130)
    for i, s in ipairs(stats) do
        local b = Acquire("stat", function() return NewStat(content) end)
        local col, row = (i - 1) % cols, math.floor((i - 1) / cols)
        b:SetPoint("TOPLEFT", 16 + col * (sw + 8), -(y + row * 58))
        b:SetWidth(sw)
        b.label:SetText(s[1])
        b.value:SetText(s[2])
        b.value:SetTextColor(s[3][1], s[3][2], s[3][3])
    end
    y = y + math.ceil(#stats / cols) * 58 + 4

    local function SpotRow(label, map, x, yy, purpose)
        local row = Acquire("vendor", function() return NewVendorRow(content) end)
        row:SetPoint("TOPLEFT", 28, -y)
        row:SetWidth(cw - 12)
        row.mapID, row.x, row.y = map, x, yy
        row.label = label
        row.purpose = purpose
        row.text:SetText("|cfff2f2f2" .. label .. "|r  |cffa3a3a3" .. ns.ZoneName(map) .. "|r  |cfff2f2f2"
            .. ("%.1f, %.1f"):format(x, yy) .. "|r")
        y = y + 24
    end
    local function Hint(text)
        local hint = Acquire("hint", function() local t = Text(content, 12, MUTED) t:SetWordWrap(true) return t end)
        hint:SetPoint("TOPLEFT", 28, -y)
        hint:SetWidth(cw - 12)
        hint:SetText(text)
        y = y + math.max(18, math.ceil(hint:GetStringHeight() or 14) + 6)
    end

    y = SectionTitle(content, y, L["Fishing spot"])
    SpotRow(EntryName(r), r.spot.map, r.spot.x, r.spot.y, L["Fishing spot"] .. " - " .. L["Nat Pagle quest"])
    Hint(L["Only caught while the quest is active. Click to place a map pin."])
    y = y + 8

    y = SectionTitle(content, y, L["Nat Pagle quest"])
    SpotRow(np.npc, np.map, np.x, np.y, L["Nat Pagle quest"])
    Hint(L["Quest: level %d and Fishing %d. Unlocks Artisan Fishing."]:format(np.level, np.skill))
    return y
end

---------------------------------------------------------------------------
-- Refresh
---------------------------------------------------------------------------
-- Flow the toolbar elements onto as many lines as the window width needs
function Window:LayoutBar()
    if not self.barItems then return end
    local maxW = self.frame:GetWidth() - 2 * GAP
    local x, y, lineH = 0, 0, 32
    for _, item in ipairs(self.barItems) do
        local w = item:GetWidth()
        if x > 0 and x + w > maxW then x, y = 0, y + lineH + BAR_PAD end
        item:ClearAllPoints()
        item:SetPoint("TOPLEFT", self.bar, "TOPLEFT", GAP + x, -(BAR_PAD + y))
        x = x + w + GAP
    end
    self.bar:SetHeight(BAR_PAD + y + lineH + BAR_PAD)
end

-- Header: drop the subtitle, then the session box, when the title would overlap them
function Window:LayoutHeader()
    if not self.title then return end
    local short = "Field|cff3aa0e8Guide|r"
    local full = short .. " |cffa3a3a3- " .. L["Field guide"] .. "|r"
    self.title:SetText(full)
    local free = self.frame:GetWidth() - 110
    local sessionOn = ns.db.profile.window.session
    local sw = (sessionOn and self.session:GetWidth() or 0) + (self.version:GetStringWidth() or 0) + 6
    if self.title:GetStringWidth() + sw > free then
        self.title:SetText(short)
    end
    if sessionOn then
        self.session:SetShown(self.title:GetStringWidth() + sw <= free)
    end
end

-- List column width: at least 180, and leaves the detail panel at least 320 wide
local LIST_MIN, DETAIL_MIN = 180, 320
function Window:ClampListWidth(w)
    local maxW = math.max(LIST_MIN, self.frame:GetWidth() - DETAIL_MIN)
    return math.floor(math.max(LIST_MIN, math.min(w, maxW)) + 0.5)
end

function Window:Layout()
    if not self.frame then return end
    if self.listBg then
        self.listBg:SetWidth(self:ClampListWidth(ns.db.profile.window.listW or LIST_W))
    end
    self:LayoutHeader()
    self:LayoutBar()
    self:LayoutCards()
end

-- Spread the four progression cards over the window width (4, 2 or 1 per line)
function Window:LayoutCards()
    if not self.cards then return end
    local n = #ns.PROFS
    local cols, cw = Grid(self.frame:GetWidth() - 2 * GAP, n, CARD_MIN)
    if cols == 3 then cols, cw = Grid(self.frame:GetWidth() - 2 * GAP, 2, CARD_MIN) end -- avoid a lonely card
    local rows = math.ceil(n / cols)
    self.prog:SetHeight(8 + rows * CARD_H + (rows - 1) * 8 + 8)
    for i, prof in ipairs(ns.PROFS) do
        local c = self.cards[prof]
        local col, row = (i - 1) % cols, math.floor((i - 1) / cols)
        c:ClearAllPoints()
        c:SetPoint("TOPLEFT", GAP + col * (cw + 8), -(8 + row * (CARD_H + 8)))
        c:SetWidth(cw)
        c.barW = cw - 22
        local rank, max = FG:Skill(prof)
        if rank then c.bar:SetWidth(math.max(1, c.barW * rank / math.max(1, max))) end
    end
end

function Window:UpdateProgression()
    for _, prof in ipairs(ns.PROFS) do
        local c = self.cards[prof]
        local rank, max = FG:Skill(prof)
        c.tipLines = {}
        c.zone.mapID = nil
        if rank then
            c.name:SetTextColor(0.95, 0.95, 0.95)
            c.level:SetText(rank .. "/" .. max)
            c.barBg:Show()
            c.bar:SetWidth(math.max(1, c.barW * rank / math.max(1, max)))
            if rank >= max then c.bar:SetColorTexture(1, 0.5, 0.25, 1) else c.bar:SetColorTexture(AD[1], AD[2], AD[3], 1) end
            local t = ns.Tracker:NextTarget(prof)
            if t then
                local b = ns.Band(t.req, FG:EffSkill(prof), ns.Data:Thresholds(t))
                local zone = ns.Tracker:BestZone(t)
                c.target:SetText("|cffa3a3a3" .. L["Next target"] .. ns.COLON .. "|r" .. ns.Colorize(ns.Data:Name(t), b))
                c.zone.mapID = zone
                c.targetBtn.res, c.targetBtn.mapID = t, zone
                c.targetBtn:Show()
                c.zone.text:SetText(zone and ns.ZoneName(zone) or "")
                c.zone:SetShown(zone ~= nil)
                c.tipLines[#c.tipLines + 1] = { L["Next target"] .. ns.COLON .. ns.Data:Name(t) .. (zone and (" (" .. ns.ZoneName(zone) .. ")") or ""), 0.9, 0.9, 0.9 }
            else
                c.target:SetText("|cffa3a3a3" .. L["Next target"] .. ns.COLON .. L["none"] .. "|r")
                c.zone:Hide()
                c.targetBtn.res = nil
                c.targetBtn:Hide()
            end
        else
            c.name:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
            c.level:SetText(L["Not learned"])
            c.barBg:Hide()
            c.target:SetText("")
            c.zone:Hide()
            c.targetBtn.res = nil
            c.targetBtn:Hide()
        end
        local alerts = {}
        local tool = ns.Tracker:MissingTool(prof)
        if tool then alerts[#alerts + 1] = { L["Missing tool: %s"]:format(ns.GetItemInfo(tool) or "?"), 1, 0.54, 0.54 } end
        local trainer, loc = ns.Tracker:TrainerText(prof)
        if trainer then alerts[#alerts + 1] = { trainer, 0.49, 0.77, 0.96, loc = loc } end
        local first = alerts[1]
        c.alertBtn.loc = nil
        if first then
            c.alert:SetText(first[1])
            c.alert:SetTextColor(first[2], first[3], first[4])
            if first.loc then
                -- Split after the first colon: "Artisan :" | " quête de Nat Pagle..."
                local cut = first[1]:find(":", 1, true)
                c.alertBtn.loc = first.loc
                c.alertBtn.purpose = L["PROF_" .. prof] .. " - " .. first[1]
                c.alertBtn.prefix = cut and first[1]:sub(1, cut) or ""
                c.alertBtn.rest = cut and first[1]:sub(cut + 1) or first[1]
                c.alertBtn:Render(c.alertBtn:IsMouseOver())
            end
        else
            c.alert:SetText("")
        end
        for _, a in ipairs(alerts) do
            c.tipLines[#c.tipLines + 1] = a
            if a.loc then
                c.tipLines[#c.tipLines + 1] = { ("%s, %s  %.1f, %.1f"):format(a.loc[1], ns.ZoneName(a.loc[2]), a.loc[3], a.loc[4]), 0.95, 0.95, 0.95 }
                c.tipLines[#c.tipLines + 1] = { L["Click to place a map pin."], 0.64, 0.64, 0.64 }
            end
        end
    end
end

-- "Map opened" message: cleared as soon as the world map is closed
function Window:PinStatus(mapID, x, y, placed)
    if not placed then return end
    local where = ns.ZoneName(mapID) .. (" (%.1f, %.1f)"):format(x, y)
    self:MapStatus(L["Map pin placed: %s. Open the map to see it."]:format(where))
end

-- Footer message about the world map, cleared when the map is closed
function Window:MapStatus(text, kind)
    state.status, state.statusKind = text, kind
    if WorldMapFrame and not self.mapHooked then
        self.mapHooked = true
        -- HookScript only adds a post-hook: it does not taint the map
        WorldMapFrame:HookScript("OnHide", function()
            if state.status then
                state.status = nil
                if Window.frame then Window:UpdateFooter() end
            end
        end)
    end
    self:UpdateFooter()
end

function Window:UpdateSpawnButton()
    local sb = self.spawnBtn
    if not sb then return end
    local SM = ns.SpawnMap
    if SM:HasPoints() or SM.last then
        sb.text:SetText(SM.current and L["Hide the spawn points"] or L["Show the spawn points"])
        sb.icon:SetAlpha(SM.current and 1 or 0.5)
        sb:SetWidth((sb.text:GetStringWidth() or 100) + 18)
        sb:Show()
    else
        sb:Hide()
    end
end

-- Points of one resource in one zone; the sheet is rebuilt at the same scroll position
function Window:ShowZonePoints(r, mapID)
    if ns.SpawnMap:Show(r, mapID) then
        self:MapStatus(ns.SpawnMap:StatusText(), "spawn")
    end
    self:RebuildDetailKeepScroll(r)
end

function Window:HideZonePoints(r)
    ns.SpawnMap:HideCurrent()
    self:MapStatus(L["Spawn points hidden from the world map."], "spawn")
    self:RebuildDetailKeepScroll(r)
end

function Window:RebuildDetailKeepScroll(r)
    local scroll = self.detail:GetVerticalScroll()
    self:BuildDetail(r)
    self.detail:SetVerticalScroll(math.min(scroll, self.detail:GetVerticalScrollRange() or scroll))
    self.detail:UpdateThumb()
end

-- Open a resource's sheet from elsewhere (cards): filters are relaxed so it is in the list
function Window:Select(r)
    if not r then return end
    state.tab = r.type
    state.cont, state.harv, state.grey, state.myZone = "all", false, false, false
    if self.searchBox and (self.searchBox:GetText() or "") ~= "" then self.searchBox:SetText("") end
    state.q = ""
    state.sel = r.key
    state.status = nil
    self:Refresh()
end

function Window:UpdateFooter()
    self:UpdateSpawnButton()
    if state.status then
        self.statusText:SetText(state.status)
    elseif state.myZone then
        local z = ns.CurrentZone()
        self.statusText:SetText(L["Filter: %s"]:format(z and ns.ZoneName(z) or "?"))
    else
        self.statusText:SetText("")
    end
end

function Window:UpdateSession()
    local s = ns.Tracker.session
    local show = ns.db.profile.window.session
    self.session:SetShown(show)
    if not show then return end
    self.session.text:SetText(("%s   |cfff2f2f2%s|r   |cff40c040%s|r   %s"):format(
        L["Session"], L["%d gathers"]:format(s.gathers), L["+%d points"]:format(s.points), ns.FormatMoney(s.value)))
    self.session:SetWidth(math.ceil(self.session.text:GetStringWidth()) + 20)
    self:LayoutHeader()
end

function Window:Refresh(forceDetail)
    if not self.frame then return end
    local f = self.frame
    f:SetScale(ns.db.profile.window.scale)
    local alpha = ns.db.profile.window.alpha
    f:SetBackdropColor(0.1, 0.1, 0.1, alpha)
    f.bg:SetColorTexture(0.1, 0.1, 0.1, alpha)

    local sv = ns.db.char.filters
    if sv then
        sv.faction, sv.tab, sv.cont = state.faction, state.tab, state.cont
        sv.harv, sv.grey, sv.myZone, sv.sel = state.harv, state.grey, state.myZone, state.sel
    end

    self.tabs:Update(function(k) return state.tab == k end)
    self.conts:Update(function(k) return state.cont == k end)
    self.chips:Update(function(k) return state[k] end)
    self.facs:Update(function(k) return state.faction == k end)

    local list = self:BuildList()
    local sel
    for _, r in ipairs(list) do if r.key == state.sel then sel = r end end
    sel = sel or list[1]
    state.sel = sel and sel.key
    if sv then sv.sel = state.sel end

    local child = self.list.child
    -- Separator shown above each group (special skins, Nat Pagle quest fish)
    if not self.questHeader then
        self.questHeader = self:NewGroupHeader(child)
    end
    self.groupHeaders = self.groupHeaders or { quest = self.questHeader }
    for _, h in pairs(self.groupHeaders) do h:Hide() end
    local y, shown = 0, {}
    for i, r in ipairs(list) do
        local g = r.group
        if g and not shown[g] then
            shown[g] = true
            local h = self.groupHeaders[g]
            if not h then
                h = self:NewGroupHeader(child)
                self.groupHeaders[g] = h
            end
            h.text:SetText(L[GROUP_LABEL[g] or g]:upper())
            h:ClearAllPoints()
            h:SetPoint("TOPLEFT", 0, -y)
            h:SetPoint("RIGHT", child, "RIGHT", -6, 0)
            h:Show()
            y = y + h:GetHeight()
        end
        local row = self.rows[i] or CreateRow(child)
        self.rows[i] = row
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -y)
        y = y + ROW_H
        row:SetPoint("RIGHT", child, "RIGHT", -6, 0)
        local rank = FG:EffSkill(r.type)
        local band = (r.mobs or r.loot) and "grey" or ns.Band(r.req, rank, ns.Data:Thresholds(r))
        local c = r.loot and { 0.95, 0.95, 0.95 } or ns.BAND[band]
        local d = DOT[r.type]
        row.dot:SetVertexColor(d[1], d[2], d[3], 1)
        row.name:SetText(EntryName(r))
        row.name:SetTextColor(c[1], c[2], c[3])
        row.req:SetText((r.mobs or r.loot) and "" or r.req)
        row.selected = (r == sel)
        if row.selected then row:SetBackdropColor(0.09, 0.23, 0.33, 1) else row:SetBackdropColor(0, 0, 0, 0) end
        row:SetScript("OnClick", function()
            state.sel = r.key
            state.status = nil
            Window:Refresh()
        end)
        row:Show()
    end
    for i = #list + 1, #self.rows do self.rows[i]:Hide() end
    child:SetHeight(math.max(1, y))
    self.list:UpdateThumb()
    self.empty:SetShown(#list == 0)

    self.count:SetText(L["%d results"]:format(#list))
    self:UpdateFooter()
    self:UpdateSession()
    self:UpdateProgression()
    if forceDetail or self.lastSel ~= state.sel then self:BuildDetail(sel) end
    self.lastSel = state.sel
end

function Window:NewGroupHeader(parent)
    local h = CreateFrame("Frame", nil, parent)
    h:SetHeight(ROW_H + 6)
    h.text = Text(h, 11, A)
    h.text:SetPoint("BOTTOMLEFT", 12, 7)
    local line = h:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(A[1], A[2], A[3], 0.6)
    line:SetPoint("LEFT", h.text, "RIGHT", 8, 0)
    line:SetPoint("RIGHT", -12, 0)
    line:SetHeight(1)
    local under = h:CreateTexture(nil, "BORDER")
    under:SetColorTexture(0, 0, 0, 1)
    under:SetPoint("BOTTOMLEFT")
    under:SetPoint("BOTTOMRIGHT")
    under:SetHeight(1)
    return h
end

-- Re-anchor the window by its top-left corner, kept inside the screen, and save that position
function Window:PinTopLeft()
    local f = self.frame
    local left, top = f:GetLeft(), f:GetTop()
    if not (left and top) then return end
    local ratio = UIParent:GetEffectiveScale() / f:GetEffectiveScale()
    local sw, sh = UIParent:GetWidth() * ratio, UIParent:GetHeight() * ratio
    local w, h = f:GetWidth(), f:GetHeight()
    -- Never larger than the screen (recovers a window saved too big)
    local fw, fh = math.min(w, sw), math.min(h, sh)
    if fw < w or fh < h then
        w, h = math.max(self.minResizeW or fw, fw), math.max(MIN_H, fh)
        f:SetSize(w, h)
        ns.db.profile.window.w, ns.db.profile.window.h = w, h
    end
    left = math.max(0, math.min(left, sw - w))
    top = math.min(sh, math.max(top, h))
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
    ns.db.profile.window.point = { "TOPLEFT", "BOTTOMLEFT", left, top }
end

-- Back to the default size, centred on screen
function Window:ResetGeometry()
    local w = ns.db.profile.window
    w.w, w.h, w.point, w.listW = nil, nil, nil, nil
    if not self.frame then return end
    self.frame:ClearAllPoints()
    self.frame:SetPoint("CENTER")
    self.frame:SetSize(self.minW or W, H)
    if self.frame:IsShown() then self:Refresh(true) end
end

function Window:Toggle()
    if not self.frame then self:Create() end
    if self.frame:IsShown() then
        self.frame:Hide()
    else
        FG:ScanSkills()
        self.frame:Show()
    end
end
