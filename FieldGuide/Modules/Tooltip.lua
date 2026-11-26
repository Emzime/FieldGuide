-- FieldGuide - tooltip lines for herbs, ores and creatures
-- Lines are only appended (existing tooltip text is never modified, to avoid taint).
local _, ns = ...
local L, FG = ns.L, ns.FG

local Tooltip = {}
ns.Tooltip = Tooltip

local function StripColors(s)
    return (s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end

local function LineText(tt, i)
    local name = tt:GetName()
    local fs = name and _G[name .. "TextLeft" .. i]
    local t = fs and fs:GetText()
    if not t or ns.IsSecret(t) then return nil end
    return t
end

local function HasLine(tt, text)
    if not text or text == "" then return false end
    for i = 2, tt:NumLines() do
        local t = LineText(tt, i)
        if t and t:find(text, 1, true) then return true end
    end
    return false
end

-- Skill required to skin / mine / gather a creature of a given level (Classic formula)
function ns.CreatureReq(level)
    if level <= 10 then return 1 end
    if level <= 20 then return level * 10 - 100 end
    return level * 5
end

function ns.MaxCreatureLevel(skill)
    if skill < 100 then return math.max(10, math.floor((skill + 100) / 10)) end
    return math.floor(skill / 5)
end

-- Index of the line showing the profession name (or another given text) added by the game
local function FindLine(tt, ...)
    for i = 2, tt:NumLines() do
        local t = LineText(tt, i)
        if t then
            t = StripColors(t)
            for _, want in ipairs({ ... }) do
                if want and want ~= "" and t == want then return i end
            end
        end
    end
end

-- Rewrite one of the game's lines (returns false if it cannot be changed safely)
local function SetLine(tt, index, text)
    local fs = _G[tt:GetName() .. "TextLeft" .. index]
    if not fs then return false end
    local ok = pcall(fs.SetText, fs, text)
    return ok
end

-- matchTexts: game lines that can be replaced by the skill line (profession name, "Skinnable"...)
local function AddSkillLines(tt, prof, req, extra, ...)
    local opt = ns.db.profile.tooltip
    local rank, max = FG:Skill(prof)
    local band = ns.Band(req, FG:EffSkill(prof)) -- equipment bonuses count
    if opt.req then
        -- Whole line in the difficulty colour, "(Req : xx)" included
        local line = ns.Colorize(L["PROF_" .. prof] .. " (" .. L["Req"] .. " " .. req .. ")", band)
        local index = FindLine(tt, L["PROF_" .. prof], ...)
        if not (index and SetLine(tt, index, line)) then tt:AddLine(line) end
    end
    if rank then
        tt:AddLine(L["CURRENT_" .. prof]:format(rank, max), 1, 1, 1)
        if extra then
            tt:AddLine(extra, 0.64, 0.64, 0.64)
        elseif opt.gain then
            if band == "red" then
                tt:AddLine(L["You are missing %d points"]:format(req - (FG:EffSkill(prof) or rank)), 0.64, 0.64, 0.64)
            else
                tt:AddLine(L["Skill gain: %s"]:format(L["GAIN_" .. band]), 0.64, 0.64, 0.64)
            end
        end
    else
        tt:AddLine(L["Not learned"], 0.64, 0.64, 0.64)
    end
end

-- World objects (herb / ore nodes)
function Tooltip:HandleObject(tt)
    local first = LineText(tt, 1)
    if not first then return end
    first = StripColors(first)
    self.lastObjectName, self.lastObjectTime = first, GetTime()
    if not ns.db.profile.tooltip.nodes then return end
    local r = ns.Data.nodeNames[first]
    if not r then return end
    AddSkillLines(tt, r.type, r.req)
    return true
end

local function LearnMob(prof, name)
    local zone = ns.CurrentZone()
    local t = ns.db.global.learnedMobs
    t[prof] = t[prof] or {}
    t[prof][name] = t[prof][name] or {}
    if zone then t[prof][name][zone] = true end
end

-- Creatures (skinning, plus mining / herbalism creatures where the game has them)
function Tooltip:HandleUnit(tt, unit)
    if not ns.db.profile.tooltip.mobs then return end
    if not unit or ns.IsSecret(unit) or UnitIsPlayer(unit) then return end
    local level = UnitLevel(unit)
    if not level or ns.IsSecret(level) or level <= 0 then return end
    local name = UnitName(unit)
    if name and ns.IsSecret(name) then name = nil end

    local prof
    if HasLine(tt, _G.UNIT_SKINNABLE_ROCK) then
        prof = "ore"
    elseif HasLine(tt, _G.UNIT_SKINNABLE_HERB) then
        prof = "herb"
    elseif HasLine(tt, _G.UNIT_SKINNABLE_LEATHER) then
        prof = "skin"
    else
        local ctype = UnitCreatureType(unit)
        if ctype and not ns.IsSecret(ctype) and ctype == L["CREATURE_BEAST"] and FG:Skill("skin") then
            prof = "skin"
        end
    end
    if not prof then return end
    if name and prof ~= "skin" then LearnMob(prof, name) end

    local req = ns.CreatureReq(level)
    local extra
    local rank = FG:Skill(prof)
    if rank then extra = L["Max skinnable level: %d"]:format(ns.MaxCreatureLevel(rank)) end
    if prof ~= "skin" then extra = nil end
    AddSkillLines(tt, prof, req, extra, _G.UNIT_SKINNABLE_LEATHER, _G.UNIT_SKINNABLE_ROCK, _G.UNIT_SKINNABLE_HERB)
    return true
end

function Tooltip:Process(tt)
    if tt ~= GameTooltip or tt.fgDone then return end
    local unit
    if tt.GetUnit then
        local ok, _, u = pcall(tt.GetUnit, tt)
        if ok then unit = u end
    end
    local added
    if unit and not ns.IsSecret(unit) then
        added = self:HandleUnit(tt, unit)
    elseif not (tt.GetItem and select(2, tt:GetItem())) then
        added = self:HandleObject(tt)
    end
    if added then
        tt.fgDone = true
        tt:Show()
    end
end

---------------------------------------------------------------------------
-- Recipe items: label the reagent line ("Reagents needed: Raw ...")
-- The reagent line is the one just above "Requires <profession> (<skill>)".
---------------------------------------------------------------------------
local reqPattern
local function RequirePattern()
    if reqPattern ~= nil then return reqPattern end
    local fmt = _G.ITEM_MIN_SKILL
    if not fmt then reqPattern = false return false end
    local p = fmt:gsub("([%(%)%.%[%]%+%-%*%?%^%$])", "%%%1"):gsub("%%s", ".+"):gsub("%%d", "%%d+")
    reqPattern = "^" .. p .. "$"
    return reqPattern
end

local RECIPE_CLASS = (Enum and Enum.ItemClass and Enum.ItemClass.Recipe) or 9
local GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant

function Tooltip:LabelReagents(tt)
    if not ns.db.profile.tooltip.reagents then return end
    local name = tt:GetName()
    if not name or not tt.GetItem then return end
    local ok, _, link = pcall(tt.GetItem, tt)
    if not ok or not link or ns.IsSecret(link) then return end
    local classID = GetItemInfoInstant and select(6, GetItemInfoInstant(link))
    if classID ~= RECIPE_CLASS then return end
    local pattern = RequirePattern()
    if not pattern then return end
    local label = L["Reagents needed"] .. ns.COLON
    for i = 3, tt:NumLines() do
        local t = LineText(tt, i)
        if t and t:match(pattern) then
            local fs = _G[name .. "TextLeft" .. (i - 1)]
            local prev = fs and fs:GetText()
            if prev and not ns.IsSecret(prev) and prev ~= "" and prev ~= " " and not prev:find(label, 1, true) then
                fs:SetText(label .. prev)
                tt:Show()
            end
            return
        end
    end
end

function Tooltip:Init()
    local tt = GameTooltip
    tt:HookScript("OnTooltipCleared", function(t) t.fgDone = nil end)
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
        for _, kind in ipairs({ "Unit", "Object" }) do
            local dt = Enum.TooltipDataType[kind]
            if dt then
                TooltipDataProcessor.AddTooltipPostCall(dt, function(t) Tooltip:Process(t) end)
            end
        end
    end
    -- Recipe tooltips (bags, vendors, links, FieldGuide window)
    local function onItem(t) Tooltip:LabelReagents(t) end
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, onItem)
    end
    for _, t in ipairs({ GameTooltip, ItemRefTooltip }) do
        if t and t:HasScript("OnTooltipSetItem") then t:HookScript("OnTooltipSetItem", onItem) end
    end
    if tt:HasScript("OnTooltipSetUnit") then
        tt:HookScript("OnTooltipSetUnit", function(t) Tooltip:Process(t) end)
    end
    -- Classic world-object tooltips only fire OnShow
    tt:HookScript("OnShow", function(t) Tooltip:Process(t) end)
end
