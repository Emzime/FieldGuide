-- FieldGuide - spawn points of the selected herb or ore on the world map
-- Sources: bundled Forever database (from GatherLite, MIT), nodes recorded by FieldGuide,
-- and the nodes already recorded by GatherLite or GatherMate2 when they are installed.
-- Pins go through HereBeDragons-Pins, which keeps the world map free of taint.
local ADDON, ns = ...
local L = ns.L

local SpawnMap = {}
ns.SpawnMap = SpawnMap

local Pins = LibStub("HereBeDragons-Pins-2.0", true)
local REF = "FieldGuideSpawns"
local MERGE = 0.003   -- points closer than this (0.3% of the map) are the same spawn
local SIZE = 12

local pool, active = {}, {}
SpawnMap.current = nil   -- resource shown on the map
SpawnMap.counts = nil    -- { total, zones, bySource }

------------------------------------------------------------------------
-- Pin frames
------------------------------------------------------------------------
local function OnEnter(self)
    local r = SpawnMap.current
    if not r then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(ns.Data:Name(r), 1, 1, 1)
    if r.req then GameTooltip:AddLine(L["PROF_" .. r.type] .. " (" .. L["Req"] .. " " .. r.req .. ")", 0.64, 0.64, 0.64) end
    GameTooltip:AddLine(("%.1f, %.1f"):format(self.x * 100, self.y * 100), 0.95, 0.95, 0.95)
    GameTooltip:AddLine(L["SPAWN_SRC_" .. self.src], 0.23, 0.63, 0.91)
    GameTooltip:Show()
end

local function OnLeave() GameTooltip:Hide() end

local function AcquirePin()
    local f = table.remove(pool)
    if not f then
        f = CreateFrame("Frame", nil, UIParent)
        f:SetSize(SIZE, SIZE)
        f.border = f:CreateTexture(nil, "BACKGROUND")
        f.border:SetPoint("TOPLEFT", -1, 1)
        f.border:SetPoint("BOTTOMRIGHT", 1, -1)
        f.border:SetColorTexture(0, 0, 0, 0.9)
        f.tex = f:CreateTexture(nil, "ARTWORK")
        f.tex:SetAllPoints()
        f.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        f:EnableMouse(true)
        f:SetScript("OnEnter", OnEnter)
        f:SetScript("OnLeave", OnLeave)
        f:Hide()
    end
    return f
end

function SpawnMap:Clear()
    if Pins then Pins:RemoveAllWorldMapIcons(REF) end
    for _, f in ipairs(active) do
        f:Hide()
        pool[#pool + 1] = f
    end
    wipe(active)
    self.current, self.currentMap, self.counts = nil, nil, nil
    self:UpdateMapButton()
end

------------------------------------------------------------------------
-- Sources
------------------------------------------------------------------------
-- points[mapID] = { { x, y, src }, ... }
local function AddPoint(points, mapID, x, y, src)
    if type(mapID) ~= "number" or not x or not y or x <= 0 or y <= 0 or x >= 1 or y >= 1 then return end
    local list = points[mapID]
    if not list then list = {} points[mapID] = list end
    for _, p in ipairs(list) do
        if math.abs(p[1] - x) < MERGE and math.abs(p[2] - y) < MERGE then return end
    end
    list[#list + 1] = { x, y, src }
end

-- Nodes recorded by FieldGuide (personal ones first: they are the most reliable)
local function FromRecorded(points, key)
    local rec = ns.db.global.spawns[key]
    if not rec then return end
    for mapID, flat in pairs(rec) do
        for i = 1, #flat - 1, 2 do AddPoint(points, mapID, flat[i], flat[i + 1], "own") end
    end
end

local function FromBundled(points, key, r)
    -- Fish: catches reported on Wowhead and fishing pools (where it bites, not exact spawns)
    local data, src
    if r.type == "fish" then
        data, src = ns.Data.FISH_SPOTS and ns.Data.FISH_SPOTS[r.item], "catch"
    else
        data, src = ns.Data.SPAWNS and ns.Data.SPAWNS[key], "bundled"
    end
    if not data then return end
    for mapID, flat in pairs(data) do
        for i = 1, #flat - 1, 2 do AddPoint(points, mapID, flat[i], flat[i + 1], src) end
    end
end

local function GetAce(name)
    local Ace = LibStub("AceAddon-3.0", true)
    return Ace and Ace:GetAddon(name, true)
end

-- GatherLite: db.global.nodes.mining / .herbalism = { { object, mapID, posX, posY }, ... }
local function FromGatherLite(points, key, r)
    local GL = GetAce("GatherLite")
    local nodes = GL and GL.db and GL.db.global and GL.db.global.nodes
    local list = nodes and nodes[r.type == "ore" and "mining" or "herbalism"]
    if type(list) ~= "table" then return end
    local objects = ns.Data.SPAWN_OBJECTS
    for _, n in pairs(list) do
        if type(n) == "table" and objects[n.object] == key then
            AddPoint(points, n.mapID, n.posX, n.posY, "gatherlite")
        end
    end
end

-- GatherMate2: GatherMate2HerbDB / GatherMate2MineDB[mapID][coord] = nodeID, names in GM.reverseNodeIDs
local function FromGatherMate(points, key, r)
    local GM = GetAce("GatherMate2")
    if not GM then return end
    local kind = r.type == "ore" and "Mining" or "Herb Gathering"
    local db = _G[r.type == "ore" and "GatherMate2MineDB" or "GatherMate2HerbDB"]
    if type(db) ~= "table" then return end
    local names = GM.reverseNodeIDs and GM.reverseNodeIDs[kind]
    if not names and GM.nodeIDs and GM.nodeIDs[kind] then
        names = {}
        for name, id in pairs(GM.nodeIDs[kind]) do names[id] = name end
    end
    if not names then return end
    local wanted = {}
    for id, name in pairs(names) do
        local res = ns.Data.nodeNames[name]
        if res and res.key == key then wanted[id] = true end
    end
    if not next(wanted) then return end
    for mapID, coords in pairs(db) do
        if type(coords) == "table" then
            for coord, id in pairs(coords) do
                if wanted[id] and type(coord) == "number" then
                    local x = math.floor(coord / 1000000) / 10000
                    local y = math.floor((coord % 1000000) / 100) / 10000
                    AddPoint(points, mapID, x, y, "gathermate")
                end
            end
        end
    end
end

function SpawnMap:Collect(r)
    local points = {}
    local opt = ns.db.profile.spawns
    local ok = function(f, ...) pcall(f, ...) end
    if opt.recorded then ok(FromRecorded, points, r.key) end
    if opt.addons and (r.type == "herb" or r.type == "ore") then
        ok(FromGatherLite, points, r.key, r)
        ok(FromGatherMate, points, r.key, r)
    end
    if opt.bundled then ok(FromBundled, points, r.key, r) end
    return points
end

------------------------------------------------------------------------
-- Display
------------------------------------------------------------------------
function SpawnMap:Supports(r)
    if not r then return false end
    -- Skinning: only the places where the player skinned (beasts move, no database)
    if r.type == "skin" then return r.group == nil or r.group == "special" end
    if not r.item then return false end
    if r.type == "fish" then return r.group == nil or r.group == "quest" end
    return (r.type == "herb" or r.type == "ore") and not r.group
end

-- Number of points per zone for a resource (cached until a new point or an option change)
function SpawnMap:Count(r)
    if not self:Supports(r) then return nil end
    self.cache = self.cache or {}
    local c = self.cache[r.key]
    if not c then
        c = {}
        for mapID, list in pairs(self:Collect(r)) do c[mapID] = #list end
        self.cache[r.key] = c
    end
    return c
end

-- True while points are drawn on the map
function SpawnMap:HasPoints()
    return self.current ~= nil and self.counts ~= nil and self.counts.total > 0
end

function SpawnMap:IsShowing(r, mapID)
    return self.current ~= nil and self.current == r and (mapID == nil or self.currentMap == mapID)
end

-- Points of one resource in one zone (the zone clicked in the sheet)
function SpawnMap:Show(r, mapID)
    if not Pins or not ns.db.profile.spawns.enabled or not self:Supports(r) or not mapID then return false end
    self:Clear()
    local list = self:Collect(r)[mapID]
    if not list or #list == 0 then return false end
    self.current, self.currentMap, self.last = r, mapID, nil
    local icon = (r.item and ns.GetItemIcon(r.item)) or (r.gives and ns.GetItemIcon(r.gives[1])) or 134400
    local counts = { total = 0, src = {} }
    for _, p in ipairs(list) do
        local f = AcquirePin()
        f.tex:SetTexture(icon)
        f.x, f.y, f.src = p[1], p[2], p[3]
        active[#active + 1] = f
        Pins:AddWorldMapIconMap(REF, f, mapID, p[1], p[2])
        counts.total = counts.total + 1
        counts.src[p[3]] = (counts.src[p[3]] or 0) + 1
    end
    self.counts = counts
    self:UpdateMapButton()
    return true
end

-- Empty map; the last zone shown can be shown again
function SpawnMap:HideCurrent()
    if self.current then self.last = { key = self.current.key, mapID = self.currentMap } end
    self:Clear()
end

function SpawnMap:StatusText()
    return L["SPAWN_STATUS_ZONE"]:format(ns.Data:Name(self.current), self.counts.total, ns.ZoneName(self.currentMap))
end

-- Map, minimap and window buttons: hide the points or show the last zone again
function SpawnMap:Toggle()
    if self:HasPoints() then
        self:HideCurrent()
        ns.FG:Print(L["Spawn points hidden from the world map."])
    elseif self.last then
        local r = ns.Data.byKey[self.last.key]
        if r and self:Show(r, self.last.mapID) then ns.FG:Print(self:StatusText()) end
    else
        return
    end
    self:UpdateMapButton()
    local W = ns.Window
    if W.frame and W.frame:IsShown() then W:Refresh(true) end
end

-- Redraw after an option change or a new recorded point
function SpawnMap:Refresh()
    self.cache = nil
    local r, mapID = self.current, self.currentMap
    if r then
        if not self:Show(r, mapID) then self:Clear() end
    end
end

------------------------------------------------------------------------
-- Recording: position of every herb or ore gathered by the player
------------------------------------------------------------------------
function ns.PlayerMapPosition()
    if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition) then return nil end
    local mapID = C_Map.GetBestMapForUnit("player")
    local pos = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
    if not pos then return nil end
    local x, y
    if type(pos.GetXY) == "function" then x, y = pos:GetXY() else x, y = pos.x, pos.y end
    if not (x and y) or (x == 0 and y == 0) then return nil end
    return mapID, x, y
end

function SpawnMap:Record(key, mapID, x, y)
    if not (key and mapID and x and y) then return end
    if IsInInstance and IsInInstance() then return end
    local all = ns.db.global.spawns
    all[key] = all[key] or {}
    local flat = all[key][mapID] or {}
    all[key][mapID] = flat
    for i = 1, #flat - 1, 2 do
        if math.abs(flat[i] - x) < MERGE and math.abs(flat[i + 1] - y) < MERGE then return end
    end
    flat[#flat + 1] = math.floor(x * 10000 + 0.5) / 10000
    flat[#flat + 1] = math.floor(y * 10000 + 0.5) / 10000
    if self.cache then self.cache[key] = nil end
    if self.current and self.current.key == key and self.currentMap == mapID then self:Refresh() end
end

------------------------------------------------------------------------
-- World map button: hide or show the points
-- Placed in the top-left corner, under the lowest button already there (the map's own,
-- OneForAll's, RareScanner's...), or in the corner itself when there is none.
-- It sits inside its own holder frame: addons that stack under the corner buttons
-- (OneForAll looks at the map's direct children) do not see it, so they keep their place.
-- Our own frames only: nothing of the map itself is modified, so no taint
------------------------------------------------------------------------
local function CornerButton(host, holder)
    local cl, ct = host:GetLeft(), host:GetTop()
    if not (cl and ct) then return nil end
    local best
    local function check(f)
        if f == holder or type(f) ~= "table" or not (f.IsShown and f:IsShown() and f.GetLeft) then return end
        local l, t = f:GetLeft(), f:GetTop()
        local w, h = f:GetWidth() or 0, f:GetHeight() or 0
        if not (l and t) or w < 12 or w > 60 or h < 12 or h > 60 then return end
        if math.abs(l - cl) < 50 and ct - t > -12 and ct - t < 260 then
            if not best or f:GetBottom() < best:GetBottom() then best = f end
        end
    end
    for _, f in ipairs(WorldMapFrame.overlayFrames or {}) do check(f) end
    for _, f in ipairs({ WorldMapFrame:GetChildren() }) do check(f) end
    if host ~= WorldMapFrame then for _, f in ipairs({ host:GetChildren() }) do check(f) end end
    return best
end

function SpawnMap:PlaceMapButton()
    local b, host = self.mapButton, self.mapHost
    if not b then return end
    local above = CornerButton(host, self.mapHolder)
    b:ClearAllPoints()
    if above then
        -- The ring's hole is centred 1.5 px right of the frame's centre
        b:SetPoint("TOP", above, "BOTTOM", -1, -2)
    else
        b:SetPoint("TOPLEFT", host, "TOPLEFT", 4, -4)
    end
end

function SpawnMap:InitMapButton()
    if self.mapButton or not WorldMapFrame then return end
    local host = WorldMapFrame.ScrollContainer
    if type(host) ~= "table" or not host.GetFrameLevel then host = WorldMapFrame end
    local holder = CreateFrame("Frame", nil, host)
    holder:SetSize(1, 1)
    holder:SetPoint("TOPLEFT")
    holder:SetFrameLevel((host:GetFrameLevel() or 1) + 20)
    self.mapHost, self.mapHolder = host, holder
    local b = CreateFrame("Button", "FieldGuideWorldMapButton", holder)
    b:SetSize(31, 31)
    b:SetFrameStrata("HIGH")
    b:SetFrameLevel(500)
    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(20, 20)
    bg:SetPoint("TOPLEFT", 7, -5)
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetSize(25, 25)
    b.icon:SetPoint("CENTER", b, "TOPLEFT", 17, -15)
    b.icon:SetTexture(ns.MEDIA .. "Logo")
    local border = b:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    b:RegisterForClicks("LeftButtonUp")
    b:SetScript("OnClick", function(self)
        SpawnMap:Toggle()
        if self:IsMouseOver() then self:GetScript("OnEnter")(self) end
    end)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Field|cff3aa0e8Guide|r")
        local r = SpawnMap.current or (SpawnMap.last and ns.Data.byKey[SpawnMap.last.key])
        local mapID = SpawnMap.currentMap or (SpawnMap.last and SpawnMap.last.mapID)
        if r then GameTooltip:AddLine(ns.Data:Name(r) .. (mapID and ("  |cffa3a3a3" .. ns.ZoneName(mapID) .. "|r") or ""), 1, 1, 1) end
        if SpawnMap:HasPoints() then
            GameTooltip:AddLine(SpawnMap:StatusText(), 0.64, 0.64, 0.64, true)
            GameTooltip:AddLine("|cff40c040" .. L["Click"] .. "|r" .. ns.COLON .. L["hide the spawn points"], 1, 1, 1)
        else
            GameTooltip:AddLine(L["Spawn points hidden from the world map."], 0.64, 0.64, 0.64, true)
            GameTooltip:AddLine("|cff40c040" .. L["Click"] .. "|r" .. ns.COLON .. L["show the spawn points again"], 1, 1, 1)
        end
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.mapButton = b
    self:PlaceMapButton()
    -- Placed again on each map open, and a moment later (other addons add their buttons late)
    WorldMapFrame:HookScript("OnShow", function()
        SpawnMap:PlaceMapButton()
        if C_Timer then C_Timer.After(0.3, function() SpawnMap:PlaceMapButton() end) end
    end)
    self:UpdateMapButton()
end

-- Shown only while there are points on the map, or points that were hidden
-- True while points are drawn on the map
function SpawnMap:HasPoints()
    return self.current ~= nil and self.counts ~= nil and self.counts.total > 0
end

function SpawnMap:UpdateMapButton()
    if ns.Window.UpdateSpawnButton then ns.Window:UpdateSpawnButton() end
    local b = self.mapButton
    if not (b and b.icon) then return end
    if self:HasPoints() or self.last then
        b:Show()
        b.icon:SetDesaturated(not self.current)
        b.icon:SetAlpha(self.current and 1 or 0.6)
    else
        b:Hide()
    end
end
