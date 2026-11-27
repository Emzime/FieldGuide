-- FieldGuide - main file: addon object, database, skills, colours and shared helpers
local ADDON, ns = ...

local FG = LibStub("AceAddon-3.0"):NewAddon(ADDON, "AceConsole-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON)
ns.FG, ns.L = FG, L
_G.FieldGuide = FG

-- Colon with the right typography for the client language
local loc = GetLocale()
ns.COLON = (loc == "frFR" and " : ") or ((loc == "zhCN" or loc == "zhTW") and "：") or ": "

-- Addon textures (Media/*.tga)
ns.MEDIA = "Interface\\AddOns\\" .. ADDON .. "\\Media\\"

-- Version from the .toc (set from the tag by the release workflow)
do
    local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    local v = getMeta and getMeta(ADDON, "Version")
    if not v or v == "" or v:find("@", 1, true) then v = "1.0.0" end
    ns.VERSION = v
end

---------------------------------------------------------------------------
-- API compatibility (Classic Era, TBC, MoP Classic, WoW Forever)
---------------------------------------------------------------------------
ns.GetItemInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
ns.GetItemIcon = (C_Item and C_Item.GetItemIconByID) or GetItemIcon
ns.GetItemCount = (C_Item and C_Item.GetItemCount) or GetItemCount
ns.IsEquippedItem = (C_Item and C_Item.IsEquippedItem) or IsEquippedItem
ns.GetSpellName = function(id)
    if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) end
    return GetSpellInfo and (GetSpellInfo(id)) or nil
end

-- Midnight-era clients can return "secret" values that addons must not touch
function ns.IsSecret(v)
    return issecretvalue ~= nil and issecretvalue(v) == true
end

local TOC = select(4, GetBuildInfo())
ns.TOC = TOC
-- Gathering tools (pick, knife, pole) are required before Cataclysm
ns.ToolsRequired = TOC < 40000 or (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
-- Highest skill cap available in this game version
ns.MaxCap = (TOC >= 50000 and 600) or (TOC >= 40000 and 525) or (TOC >= 30000 and 450) or (TOC >= 20000 and 375) or 300

---------------------------------------------------------------------------
-- Colours
---------------------------------------------------------------------------
ns.ACCENT = { 0.227, 0.627, 0.910 }          -- #3aa0e8 (ElvUI-like blue)
ns.ACCENT_DARK = { 0.071, 0.439, 0.710 }     -- #1270b5
ns.BAND = {
    red    = { 1.00, 0.23, 0.23, "ffff3b3b" },
    orange = { 1.00, 0.50, 0.25, "ffff8040" },
    yellow = { 1.00, 1.00, 0.00, "ffffff00" },
    green  = { 0.25, 0.75, 0.25, "ff40c040" },
    grey   = { 0.55, 0.55, 0.55, "ff8c8c8c" },
}

-- Difficulty band of a resource for a given skill level
function ns.Band(req, skill, th)
    if not skill or not req then return "red" end
    if skill < req then return "red" end
    local y = th and th.yellow or req + 25
    local g = th and th.green or req + 50
    local gr = th and th.grey or req + 100
    if skill >= gr then return "grey" elseif skill >= g then return "green" elseif skill >= y then return "yellow" end
    return "orange"
end

function ns.Colorize(text, band)
    return "|c" .. ns.BAND[band][4] .. text .. "|r"
end

-- Font: use ElvUI's font when available
function ns.Font()
    local E = _G.ElvUI and _G.ElvUI[1]
    return (E and E.media and E.media.normFont) or STANDARD_TEXT_FONT
end

---------------------------------------------------------------------------
-- Skills
---------------------------------------------------------------------------
ns.PROFS = { "herb", "ore", "skin", "fish" }
local SKILLLINE_ID = { herb = 182, ore = 186, skin = 393, fish = 356 }

local function NameToProf(name)
    if not name or ns.IsSecret(name) then return nil end
    for _, p in ipairs(ns.PROFS) do
        if name == L["PROF_" .. p] then return p end
    end
end

-- Returns a table prof -> { rank = n, max = n } for learned gathering skills
function FG:ScanSkills()
    local res = {}
    local num = (C_SkillInfo and C_SkillInfo.GetNumSkillLines) or GetNumSkillLines
    local info = (C_SkillInfo and C_SkillInfo.GetSkillLineInfo) or GetSkillLineInfo
    if num and info then
        for i = 1, num() do
            local name, isHeader, _, rank, _, mod, maxRank = info(i)
            if type(name) == "table" then
                local t = name
                name, isHeader = t.name or t.skillName, t.isHeader
                rank, maxRank = t.rank or t.skillRank, t.maxRank or t.skillMaxRank
                mod = t.skillModifier or t.modifier
            end
            local p = not isHeader and NameToProf(name)
            if p and rank and not ns.IsSecret(rank) then
                if type(mod) ~= "number" or ns.IsSecret(mod) then mod = 0 end
                res[p] = { rank = rank, max = maxRank or rank, mod = mod }
            end
        end
    end
    -- Modern profession API fallback
    if next(res) == nil and GetProfessions and GetProfessionInfo then
        for _, idx in pairs({ GetProfessions() }) do
            if idx then
                local _, _, rank, maxRank, _, _, skillLine = GetProfessionInfo(idx)
                for p, id in pairs(SKILLLINE_ID) do
                    if skillLine == id then res[p] = { rank = rank, max = maxRank } end
                end
            end
        end
    end
    self.skills = res
    return res
end

function FG:Skill(prof)
    local s = self.skills and self.skills[prof]
    return s and s.rank, s and s.max, s and s.mod or 0
end

-- Skill used against requirements: equipment bonuses count (fishing pole/lure, skinning knife/gloves...)
-- (the 330 zones need 300 + bonuses, e.g. Aquadynamic Fish Attractor +100)
function FG:EffSkill(prof)
    local rank, _, mod = self:Skill(prof)
    if not rank then return nil end
    return rank + (mod or 0)
end

---------------------------------------------------------------------------
-- Zones
---------------------------------------------------------------------------
local zoneNameCache = {}
function ns.ZoneName(mapID)
    -- Forever zones whose uiMapID is not known yet use a string key with a localized name
    if type(mapID) == "string" then return L["ZONE_" .. mapID] end
    local n = zoneNameCache[mapID]
    if n then return n end
    local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
    n = info and info.name or ("#" .. mapID)
    zoneNameCache[mapID] = n
    return n
end

-- Current zone (walks up from sub-zones / dungeons to the zone map)
function ns.CurrentZone()
    if not (C_Map and C_Map.GetBestMapForUnit) then return nil end
    local id = C_Map.GetBestMapForUnit("player")
    local zoneType = Enum and Enum.UIMapType and Enum.UIMapType.Zone or 3
    local guard = 0
    while id and guard < 6 do
        local info = C_Map.GetMapInfo(id)
        if not info then return nil end
        if info.mapType == zoneType then return id end
        id = info.parentMapID
        guard = guard + 1
    end
    return nil
end

-- Optional x, y (0-100): also drop a map pin there when the client supports user waypoints
-- Map pin: a user waypoint, super-tracked. The world map is never opened from here:
-- opening it from addon code taints the map canvas, and Blizzard then blocks its pins
-- (ADDON_ACTION_BLOCKED "SetPassThroughButtons") the next time the player opens the map.
function ns.PlacePin(mapID, x, y)
    if type(mapID) ~= "number" or not (x and y) then return false end
    if not (C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates) then return false end
    local ok, placed = pcall(function()
        if C_Map.CanSetUserWaypointOnMap and not C_Map.CanSetUserWaypointOnMap(mapID) then return false end
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapID, x / 100, y / 100))
        if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then C_SuperTrack.SetSuperTrackedUserWaypoint(true) end
        return true
    end)
    return ok and placed or false
end

-- Quest state helpers (work on clients with or without C_QuestLog)
function ns.IsOnQuest(id)
    if C_QuestLog and C_QuestLog.IsOnQuest then
        local ok, v = pcall(C_QuestLog.IsOnQuest, id)
        if ok then return v and true or false end
    end
    if GetQuestLogIndexByID then
        local i = GetQuestLogIndexByID(id)
        return (i or 0) > 0
    end
    if GetNumQuestLogEntries and GetQuestLogTitle then
        for i = 1, GetNumQuestLogEntries() do
            if select(8, GetQuestLogTitle(i)) == id then return true end
        end
    end
    return false
end

function ns.IsQuestDone(id)
    local f = (C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted) or IsQuestFlaggedCompleted
    if not f then return false end
    local ok, v = pcall(f, id)
    return ok and v and true or false
end

-- Money as coloured text (gold / silver / copper), without coin icons
function ns.FormatMoney(copper)
    copper = math.floor(copper or 0)
    local g, sv, c = math.floor(copper / 10000), math.floor((copper % 10000) / 100), copper % 100
    local G, S, C = GOLD_AMOUNT_SYMBOL or "g", SILVER_AMOUNT_SYMBOL or "s", COPPER_AMOUNT_SYMBOL or "c"
    if g > 0 then
        return ("|cffffd100%d%s|r |cffc7c7cf%d%s|r"):format(g, G, sv, S)
    elseif sv > 0 then
        return ("|cffc7c7cf%d%s|r |cffeda55f%d%s|r"):format(sv, S, c, C)
    end
    return ("|cffeda55f%d%s|r"):format(c, C)
end

---------------------------------------------------------------------------
-- Database
---------------------------------------------------------------------------
local defaults = {
    profile = {
        tooltip = { nodes = true, mobs = true, req = true, gain = true, reagents = true },
        alerts = { newNode = true, grey = true, tool = true, trainer = true, questFish = true, sound = true, duration = 6 },
        minimap = { hide = false, lock = false, angle = 215 },
        window = { scale = 1, alpha = 1, session = true },
    },
    global = {
        learnedZones = {},   -- [resourceKey] = { [mapID] = count }
        learnedNodes = {},   -- [locale] = { [nodeName] = resourceKey }
        learnedMobs = {},    -- [prof] = { [name] = { [mapID] = true } }
    },
    char = {
        trainerWarned = {},  -- [prof .. max] = true
    },
}

function FG:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("FieldGuideDB", defaults, true)
    ns.db = self.db
    self:RegisterChatCommand("fg", "SlashCommand")
    self:RegisterChatCommand("fieldguide", "SlashCommand")
end

function FG:OnEnable()
    self:ScanSkills()
    ns.Data:Init()
    ns.Tooltip:Init()
    ns.Tracker:Init()
    ns.Minimap:Init()
    ns.Options:Init()
end

function FG:SlashCommand(msg)
    msg = (msg or ""):lower():match("^%s*(%S*)")
    if msg == "" then
        ns.Window:Toggle()
    elseif msg == "options" or msg == "config" then
        ns.Options:Open()
    elseif msg == "reset" then
        ns.Tracker:ResetSession()
        self:Print(L["Session reset."])
    else
        self:Print(L["Usage: /fg [options | reset]"])
    end
end
