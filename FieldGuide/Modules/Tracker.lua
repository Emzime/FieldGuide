-- FieldGuide - session statistics, skill-change alerts, tool checks and learning
local _, ns = ...
local L, FG = ns.L, ns.FG

local Tracker = {}
ns.Tracker = Tracker

-- Gathering spells (any rank shares the same name)
local GATHER_SPELLS = { herb = 2366, ore = 2575, skin = 8613, fish = 7620 }
local spellToProf = {}

Tracker.session = { gathers = 0, points = 0, value = 0 }
local toolWarned = {}

---------------------------------------------------------------------------
-- Prices: Auctionator if installed, otherwise vendor price
---------------------------------------------------------------------------
function Tracker:Price(itemID)
    local api = _G.Auctionator and _G.Auctionator.API and _G.Auctionator.API.v1
    if api and api.GetAuctionPriceByItemID then
        local ok, price = pcall(api.GetAuctionPriceByItemID, "FieldGuide", itemID)
        if ok and price then return price end
    end
    local sell = select(11, ns.GetItemInfo(itemID))
    return sell or 0
end

function Tracker:ResetSession()
    self.session.gathers, self.session.points, self.session.value = 0, 0, 0
    self:RefreshWindow()
end

function Tracker:RefreshWindow()
    if ns.Window and ns.Window.frame and ns.Window.frame:IsShown() then ns.Window:Refresh() end
end

---------------------------------------------------------------------------
-- Progression helpers
---------------------------------------------------------------------------
-- Best resource to level up with: highest orange/yellow requirement
function Tracker:NextTarget(prof)
    local rank = FG:EffSkill(prof)
    if not rank then return nil end
    local best
    for _, r in ipairs(ns.Data.Resources) do
        if r.type == prof and not r.group then
            local b = ns.Band(r.req, rank, ns.Data:Thresholds(r))
            if (b == "orange" or b == "yellow") and (not best or r.req > best.req) then best = r end
        end
    end
    return best
end

-- Preferred zone of a resource: one on the player's continent when possible
function Tracker:BestZone(r)
    local zones = ns.Data:Zones(r)
    local here = ns.CurrentZone()
    local cont = here and ns.Data.Continent(here)
    for _, id in ipairs(zones) do
        if id == here then return id end
    end
    if cont then
        for _, id in ipairs(zones) do
            if ns.Data.Continent(id) == cont then return id end
        end
    end
    return zones[1]
end

-- Returns the reminder text and where to go: { name, mapID, x, y }
function Tracker:TrainerText(prof)
    local rank, max = FG:Skill(prof)
    if not rank or max >= ns.MaxCap or rank < max - 10 then return nil end
    local T = ns.Data.TRAINERS
    if prof == "fish" and max == 150 then
        local book = ns.GetItemInfo(ns.Data.ExpertFishingBook) or "Expert Fishing"
        return L["TRAINER_FISH_150"]:format(book), T.heming
    elseif prof == "fish" and max == 225 then
        local np = ns.Data.NAT_PAGLE
        return L["TRAINER_FISH_225"], { np.npc, np.map, np.x, np.y }
    end
    local text = rawget(L, "TRAINER_" .. max)
    local byFaction = T[prof]
    return text, byFaction and byFaction[UnitFactionGroup("player") or "Horde"]
end

-- Returns the tool item ID when a required tool is missing
function Tracker:MissingTool(prof)
    if not ns.ToolsRequired or not FG:Skill(prof) then return nil end
    local tools = ns.Data.Tools[prof]
    if not tools then return nil end
    for _, id in ipairs(tools) do
        if (ns.GetItemCount(id) or 0) > 0 or ns.IsEquippedItem(id) then return nil end
    end
    return tools[1]
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
function Tracker:CheckTools()
    if not ns.db.profile.alerts.tool then return end
    for _, prof in ipairs(ns.PROFS) do
        local id = self:MissingTool(prof)
        if id and not toolWarned[prof] then
            toolWarned[prof] = true
            ns.Alerts:Show("tool", L["Missing tool"], L["No %s in your bags"]:format(ns.GetItemInfo(id) or "?"), ns.GetItemIcon(id))
        elseif not id then
            toolWarned[prof] = nil
        end
    end
end

function Tracker:CheckTrainers()
    if not ns.db.profile.alerts.trainer then return end
    local warned = ns.db.char.trainerWarned
    for _, prof in ipairs(ns.PROFS) do
        local text = self:TrainerText(prof)
        local _, max = FG:Skill(prof)
        if text and not warned[prof .. max] then
            warned[prof .. max] = true
            ns.Alerts:Show("trainer", L["Next skill tier"] .. " - " .. L["PROF_" .. prof], text)
        end
    end
end

function Tracker:OnSkillsChanged()
    local old = {}
    for p, s in pairs(FG.skills or {}) do old[p] = s.rank end
    FG:ScanSkills()
    local a = ns.db.profile.alerts
    for _, prof in ipairs(ns.PROFS) do
        local before, now = old[prof], FG:Skill(prof)
        if before and now and now > before then
            self.session.points = self.session.points + (now - before)
            for _, r in ipairs(ns.Data.Resources) do
                if r.type == prof and not r.group then
                    local th = ns.Data:Thresholds(r)
                    local icon = r.item and ns.GetItemIcon(r.item) or (r.gives and ns.GetItemIcon(r.gives[1]))
                    if a.newNode and before < r.req and now >= r.req then
                        ns.Alerts:Show("new", L["New node available"],
                            L["%s: %s %d reached"]:format(ns.Data:Name(r), L["PROF_" .. prof], r.req), icon)
                    end
                    if a.grey and before < th.grey and now >= th.grey then
                        ns.Alerts:Show("grey", L["Turned grey"], L["%s no longer gives skill points"]:format(ns.Data:Name(r)), icon)
                    end
                end
            end
        end
    end
    self:CheckTrainers()
    self:RefreshWindow()
end

function Tracker:OnSpellCast(unit, _, spellID)
    if unit ~= "player" or not spellID or ns.IsSecret(spellID) then return end
    local name = ns.GetSpellName(spellID)
    local prof = name and spellToProf[name]
    if prof then
        local tip = ns.Tooltip
        local node = tip.lastObjectTime and (GetTime() - tip.lastObjectTime) < 15 and tip.lastObjectName or nil
        self.lastGather = { prof = prof, time = GetTime(), node = node }
    end
end

function Tracker:OnLoot()
    local fishing = IsFishingLoot and IsFishingLoot()
    local g = self.lastGather
    local prof = fishing and "fish" or (g and (GetTime() - g.time) < 6 and g.prof)
    if not prof then return end
    self.lastGather = nil

    local zone = ns.CurrentZone()
    local got = false
    for slot = 1, GetNumLootItems() do
        local link = GetLootSlotLink(slot)
        local id = link and tonumber(link:match("item:(%d+)"))
        if id and ns.Data.gatherItems[id] then
            got = true
            local qty = select(3, GetLootSlotInfo(slot)) or 1
            self.session.value = self.session.value + self:Price(id) * qty
            local r = ns.Data.byItem[id]
            if r and zone and r.type == prof then
                local lz = ns.db.global.learnedZones
                lz[r.key] = lz[r.key] or {}
                lz[r.key][zone] = (lz[r.key][zone] or 0) + 1
                -- Learn the node name in the client language
                if (prof == "ore" or prof == "herb") and g and g.node and not ns.Data.nodeNames[g.node] then
                    local loc = GetLocale()
                    ns.db.global.learnedNodes[loc] = ns.db.global.learnedNodes[loc] or {}
                    ns.db.global.learnedNodes[loc][g.node] = r.key
                    ns.Data.nodeNames[g.node] = r
                end
            end
        end
    end
    if got then
        self.session.gathers = self.session.gathers + 1
        self:RefreshWindow()
    end
end

-- Toast when entering the zone of a Nat Pagle fish still missing while the quest is active
local questAlerted = {}
function Tracker:CheckQuestFish()
    local here = ns.CurrentZone()
    if not ns.db.profile.alerts.questFish or not here then return end
    if not ns.IsOnQuest(ns.Data.NAT_PAGLE.quest) then return end
    for _, r in ipairs(ns.Data.Resources) do
        if r.quest and r.spot then
            if r.spot.map ~= here then
                questAlerted[r.key] = nil
            elseif not questAlerted[r.key] and (ns.GetItemCount(r.item) or 0) == 0 then
                questAlerted[r.key] = true
                ns.Alerts:Show("trainer", L["Nat Pagle quest fish"],
                    L["%s: fish at %s"]:format(ns.Data:Name(r), ("%.0f, %.0f"):format(r.spot.x, r.spot.y)), ns.GetItemIcon(r.item))
            end
        end
    end
end

function Tracker:Init()
    -- Own frame: the addon object already uses ZONE_CHANGED_NEW_AREA for the window
    local zf = CreateFrame("Frame")
    zf:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    zf:RegisterEvent("QUEST_ACCEPTED")
    zf:SetScript("OnEvent", function() C_Timer.After(1, function() Tracker:CheckQuestFish() end) end)
    for prof, id in pairs(GATHER_SPELLS) do
        local n = ns.GetSpellName(id)
        if n then spellToProf[n] = prof end
    end
    FG:RegisterEvent("SKILL_LINES_CHANGED", function() Tracker:OnSkillsChanged() end)
    FG:RegisterEvent("CHAT_MSG_SKILL", function() Tracker:OnSkillsChanged() end)
    FG:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", function(_, ...) Tracker:OnSpellCast(...) end)
    FG:RegisterEvent("LOOT_OPENED", function() Tracker:OnLoot() end)
    local pendingBags
    FG:RegisterEvent("BAG_UPDATE_DELAYED", function()
        if pendingBags then return end
        pendingBags = true
        C_Timer.After(1, function() pendingBags = nil; Tracker:CheckTools() end)
    end)
    C_Timer.After(5, function()
        FG:ScanSkills()
        Tracker:CheckTools()
        Tracker:CheckTrainers()
    end)
end
