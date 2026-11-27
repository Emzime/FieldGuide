-- FieldGuide - options panel (AceConfig, skinned automatically by ElvUI)
local ADDON, ns = ...
local L = ns.L

local Options = {}
ns.Options = Options

local function refreshAll()
    if ns.SpawnMap then ns.SpawnMap:Refresh() end
    if ns.Window.frame and ns.Window.frame:IsShown() then ns.Window:Refresh() end
    ns.Minimap:Refresh()
end

local function toggle(section, key, name, order)
    return {
        type = "toggle", name = name, order = order, width = "full",
        get = function() return ns.db.profile[section][key] end,
        set = function(_, v) ns.db.profile[section][key] = v refreshAll() end,
    }
end

local function build()
    return {
        type = "group",
        name = "FieldGuide",
        args = {
            tooltip = {
                type = "group", inline = true, order = 1, name = L["Tooltips"],
                args = {
                    nodes = toggle("tooltip", "nodes", L["Show on herbs and ores"], 1),
                    mobs = toggle("tooltip", "mobs", L["Show on creatures"], 2),
                    req = toggle("tooltip", "req", L["Show the required skill"], 3),
                    gain = toggle("tooltip", "gain", L["Show the skill gain"], 4),
                    reagents = toggle("tooltip", "reagents", L["Label the reagents in recipe tooltips"], 5),
                },
            },
            alerts = {
                type = "group", inline = true, order = 2, name = L["Alerts"],
                args = {
                    newNode = toggle("alerts", "newNode", L["New harvestable node"], 1),
                    grey = toggle("alerts", "grey", L["Node turned grey"], 2),
                    tool = toggle("alerts", "tool", L["Missing tool"], 3),
                    trainer = toggle("alerts", "trainer", L["Trainer reminder (skill tiers)"], 4),
                    questFish = toggle("alerts", "questFish", L["Nat Pagle quest fish in this zone"], 4.5),
                    sound = toggle("alerts", "sound", L["Play a sound"], 5),
                    duration = {
                        type = "range", order = 6, name = L["Display time (seconds)"], min = 2, max = 20, step = 1,
                        get = function() return ns.db.profile.alerts.duration end,
                        set = function(_, v) ns.db.profile.alerts.duration = v end,
                    },
                    test = {
                        type = "execute", order = 7, name = L["Test alerts"],
                        func = function() ns.Alerts:Test() end,
                    },
                },
            },
            minimap = {
                type = "group", inline = true, order = 3, name = L["Minimap"],
                args = {
                    show = {
                        type = "toggle", order = 1, width = "full", name = L["Show the icon"],
                        get = function() return not ns.db.profile.minimap.hide end,
                        set = function(_, v) ns.db.profile.minimap.hide = not v refreshAll() end,
                    },
                    lock = toggle("minimap", "lock", L["Lock the position"], 2),
                },
            },
            window = {
                type = "group", inline = true, order = 4, name = L["Window and session"],
                args = {
                    scale = {
                        type = "range", order = 1, name = L["Scale"], min = 0.5, max = 1.5, step = 0.05, isPercent = true,
                        get = function() return ns.db.profile.window.scale end,
                        set = function(_, v) ns.db.profile.window.scale = v refreshAll() end,
                    },
                    alpha = {
                        type = "range", order = 2, name = L["Opacity"], min = 0.2, max = 1, step = 0.05, isPercent = true,
                        get = function() return ns.db.profile.window.alpha end,
                        set = function(_, v) ns.db.profile.window.alpha = v refreshAll() end,
                    },
                    session = toggle("window", "session", L["Show session statistics"], 3),
                    reset = {
                        type = "execute", order = 4, name = L["Reset the session"],
                        func = function() ns.Tracker:ResetSession() ns.FG:Print(L["Session reset."]) end,
                    },
                    windowDefault = {
                        type = "execute", order = 5, name = L["Default window size and position"], width = "double",
                        func = function() ns.Window:ResetGeometry() end,
                    },
                },
            },
            spawns = {
                type = "group", inline = true, order = 4.5, name = L["Spawn points on the world map"],
                args = {
                    enabled = toggle("spawns", "enabled", L["Show the spawn points of the selected herb or ore"], 1),
                    bundled = toggle("spawns", "bundled", L["Use the bundled database"], 2),
                    recorded = toggle("spawns", "recorded", L["Use the nodes I gathered"], 3),
                    addons = toggle("spawns", "addons", L["Use the nodes recorded by GatherLite and GatherMate2"], 4),
                },
            },
            resetGroup = {
                type = "group", inline = true, order = 5, name = L["Reset"],
                args = {
                    resetAll = {
                        type = "execute", order = 1, name = L["Reset all settings"], width = "double",
                        confirm = true, confirmText = L["Reset all settings?"],
                        func = function()
                            ns.db:ResetProfile()
                            ns.Window:ResetGeometry()
                            refreshAll()
                            ns.FG:Print(L["Settings reset."])
                        end,
                    },
                },
            },
        },
    }
end

function Options:Init()
    LibStub("AceConfig-3.0"):RegisterOptionsTable(ADDON, build)
    self.panel = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ADDON, "FieldGuide")
    LibStub("AceConfigDialog-3.0"):SetDefaultSize(ADDON, 560, 620)
end

function Options:Open()
    local dialog = LibStub("AceConfigDialog-3.0")
    if dialog.OpenFrames[ADDON] then
        dialog:Close(ADDON)
    else
        dialog:Open(ADDON)
    end
end
