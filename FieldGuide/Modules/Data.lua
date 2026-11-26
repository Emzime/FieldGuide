-- FieldGuide - static gathering data (Classic world) and lookup tables
-- Zones are uiMapIDs: names are localized at runtime with C_Map.GetMapInfo.
local _, ns = ...
local L = ns.L

local Data = {}
ns.Data = Data

---------------------------------------------------------------------------
-- Zones
---------------------------------------------------------------------------
local Z = {
    DUROTAR = 1411, MULGORE = 1412, BARRENS = 1413, ALTERAC = 1416, ARATHI = 1417, BADLANDS = 1418,
    BLASTED = 1419, TIRISFAL = 1420, SILVERPINE = 1421, WPL = 1422, EPL = 1423, HILLSBRAD = 1424,
    HINTERLANDS = 1425, DUNMOROGH = 1426, SEARING = 1427, BURNING = 1428, ELWYNN = 1429, DEADWIND = 1430, DUSKWOOD = 1431,
    LOCHMODAN = 1432, REDRIDGE = 1433, STV = 1434, SWAMP = 1435, WESTFALL = 1436, WETLANDS = 1437,
    TELDRASSIL = 1438, DARKSHORE = 1439, ASHENVALE = 1440, NEEDLES = 1441, STONETALON = 1442,
    DESOLACE = 1443, FERALAS = 1444, DUSTWALLOW = 1445, TANARIS = 1446, AZSHARA = 1447, FELWOOD = 1448,
    UNGORO = 1449, MOONGLADE = 1450, SILITHUS = 1451, WINTERSPRING = 1452,
}
Data.Z = Z

Data.KALIMDOR_ID, Data.EASTERN_ID = 1414, 1415
local KALIMDOR = {}
for _, id in ipairs({ Z.DUROTAR, Z.MULGORE, Z.BARRENS, Z.TELDRASSIL, Z.DARKSHORE, Z.ASHENVALE, Z.NEEDLES,
    Z.STONETALON, Z.DESOLACE, Z.FERALAS, Z.DUSTWALLOW, Z.TANARIS, Z.AZSHARA, Z.FELWOOD, Z.UNGORO,
    Z.MOONGLADE, Z.SILITHUS, Z.WINTERSPRING, 1454, 1456, 1457 }) do KALIMDOR[id] = true end

function Data.Continent(mapID)
    if KALIMDOR[mapID] then return "KA" end
    return "EK"
end

-- Creature level range per zone { min, max }
Data.ZoneLevels = {
    [Z.ELWYNN] = { 1, 10 }, [Z.DUNMOROGH] = { 1, 10 }, [Z.TIRISFAL] = { 1, 10 }, [Z.DUROTAR] = { 1, 10 },
    [Z.MULGORE] = { 1, 10 }, [Z.TELDRASSIL] = { 1, 10 }, [Z.WESTFALL] = { 10, 20 }, [Z.LOCHMODAN] = { 10, 20 },
    [Z.SILVERPINE] = { 10, 20 }, [Z.DARKSHORE] = { 10, 20 }, [Z.BARRENS] = { 10, 25 }, [Z.REDRIDGE] = { 15, 25 },
    [Z.DUSKWOOD] = { 18, 30 }, [Z.WETLANDS] = { 20, 30 }, [Z.HILLSBRAD] = { 20, 30 }, [Z.ASHENVALE] = { 18, 30 },
    [Z.STONETALON] = { 15, 27 }, [Z.NEEDLES] = { 25, 35 }, [Z.ARATHI] = { 30, 40 }, [Z.DESOLACE] = { 30, 40 },
    [Z.ALTERAC] = { 30, 40 }, [Z.STV] = { 30, 45 }, [Z.BADLANDS] = { 35, 45 }, [Z.DUSTWALLOW] = { 35, 45 },
    [Z.SWAMP] = { 35, 45 }, [Z.TANARIS] = { 40, 50 }, [Z.FERALAS] = { 40, 50 }, [Z.HINTERLANDS] = { 40, 50 },
    [Z.SEARING] = { 43, 50 }, [Z.AZSHARA] = { 45, 55 }, [Z.BLASTED] = { 45, 55 }, [Z.UNGORO] = { 48, 55 },
    [Z.FELWOOD] = { 48, 55 }, [Z.BURNING] = { 50, 58 }, [Z.WPL] = { 51, 58 }, [Z.EPL] = { 53, 60 },
    [Z.WINTERSPRING] = { 53, 60 }, [Z.SILITHUS] = { 55, 60 }, [Z.MOONGLADE] = { 55, 60 },
}

-- Minimum fishing skill to fish a zone without losing catches
Data.FishZoneSkill = {
    [Z.ELWYNN] = 1, [Z.DUNMOROGH] = 1, [Z.TIRISFAL] = 1, [Z.DUROTAR] = 1, [Z.MULGORE] = 1, [Z.TELDRASSIL] = 1,
    [Z.WESTFALL] = 1, [Z.LOCHMODAN] = 1, [Z.SILVERPINE] = 1, [Z.DARKSHORE] = 1, [Z.BARRENS] = 1,
    [Z.REDRIDGE] = 55, [Z.DUSKWOOD] = 55, [Z.WETLANDS] = 55, [Z.HILLSBRAD] = 55, [Z.ASHENVALE] = 55,
    [Z.STONETALON] = 55, [Z.NEEDLES] = 130, [Z.ARATHI] = 130, [Z.DESOLACE] = 130, [Z.ALTERAC] = 130,
    [Z.STV] = 130, [Z.SWAMP] = 130, [Z.DUSTWALLOW] = 130, [Z.TANARIS] = 205, [Z.FERALAS] = 205,
    [Z.HINTERLANDS] = 205, [Z.AZSHARA] = 205, [Z.UNGORO] = 205, [Z.FELWOOD] = 205, [Z.WPL] = 205,
    [Z.MOONGLADE] = 205, [Z.EPL] = 300, [Z.WINTERSPRING] = 330, [Z.BURNING] = 330, [Z.SILITHUS] = 330,
    [1453] = 1, [1454] = 1, [1455] = 1, [1456] = 1, [1457] = 1, [1458] = 1,
}

---------------------------------------------------------------------------
-- Items
---------------------------------------------------------------------------
local GEM = {
    malachite = 774, tigerseye = 818, shadowgem = 1210, mossAgate = 1206, moonstone = 1705, jade = 1529,
    citrine = 3864, aquamarine = 7909, starRuby = 7910, sapphire = 12361, opal = 12799, emerald = 12364,
    diamond = 12800, arcane = 12363,
}
local STONE = { rough = 2835, coarse = 2836, heavy = 2838, solid = 7912, dense = 12365 }

-- Tools: any of these items satisfies the requirement
Data.Tools = {
    ore = { 2901 },                                                         -- Mining Pick
    skin = { 7005, 12709 },                                                 -- Skinning Knife, Finkle's Skinner
    fish = { 6256, 6365, 6366, 6367, 12225, 19022, 19970 },                 -- fishing poles
}

-- Fishing lures: { itemID, bonus }
Data.Lures = { { 6529, 25 }, { 6530, 50 }, { 6532, 75 }, { 6533, 100 } }

Data.ExpertFishingBook = 16083

-- City maps used by recipe vendors
local CITY = { STORMWIND = 1453, ORGRIMMAR = 1454, IRONFORGE = 1455, THUNDERBLUFF = 1456, DARNASSUS = 1457, UNDERCITY = 1458 }
Data.CITY = CITY

---------------------------------------------------------------------------
-- Resources
-- type: herb | ore | skin | fish
-- req: required skill; nodes: node name keys (L["NODE_*"]) for ores
---------------------------------------------------------------------------
local R = {}
Data.Resources = R
local function add(t) R[#R + 1] = t end

-- Herbs (node name = item name) - zones from Icy Veins' WoW Forever herbalism table
add({ key = "peacebloom", type = "herb", req = 1, item = 2447, zones = { Z.MULGORE, Z.TIRISFAL, Z.TELDRASSIL, Z.DUROTAR, Z.BARRENS, Z.DUNMOROGH, Z.ELWYNN } })
add({ key = "silverleaf", type = "herb", req = 1, item = 765, zones = { Z.MULGORE, Z.TIRISFAL, Z.ELWYNN, Z.TELDRASSIL, Z.DUNMOROGH, Z.BARRENS, Z.DUROTAR } })
add({ key = "earthroot", type = "herb", req = 15, item = 2449, zones = { Z.MULGORE, Z.BARRENS, Z.TIRISFAL, Z.TELDRASSIL, Z.DUNMOROGH, Z.ELWYNN, Z.DUROTAR } })
add({ key = "mageroyal", type = "herb", req = 50, item = 785, extra = { 2452 }, zones = { Z.BARRENS, Z.SILVERPINE, Z.LOCHMODAN, Z.WESTFALL, Z.REDRIDGE } })
add({ key = "briarthorn", type = "herb", req = 70, item = 2450, extra = { 2452 }, zones = { Z.BARRENS, Z.DUSKWOOD, Z.SILVERPINE, Z.REDRIDGE, Z.WESTFALL } })
add({ key = "stranglekelp", type = "herb", req = 85, item = 3820, zones = { Z.WETLANDS, Z.STV, Z.ASHENVALE, Z.DESOLACE, Z.WESTFALL } })
add({ key = "bruiseweed", type = "herb", req = 100, item = 2453, zones = { Z.STONETALON, Z.BARRENS, Z.ASHENVALE, Z.DUSKWOOD, Z.REDRIDGE } })
add({ key = "steelbloom", type = "herb", req = 115, item = 3355, zones = { Z.STV, Z.STONETALON, Z.ARATHI, Z.WETLANDS, Z.NEEDLES } })
add({ key = "gravemoss", type = "herb", req = 120, item = 3369, zones = { Z.DESOLACE, Z.DUSKWOOD } })
add({ key = "kingsblood", type = "herb", req = 125, item = 3356, zones = { Z.STV, Z.WETLANDS, Z.HILLSBRAD, Z.ASHENVALE, Z.STONETALON } })
add({ key = "liferoot", type = "herb", req = 150, item = 3357, zones = { Z.DUSTWALLOW, Z.STV, Z.SWAMP, Z.WETLANDS, Z.ALTERAC, Z.DESOLACE } })
add({ key = "fadeleaf", type = "herb", req = 160, item = 3818, zones = { Z.DUSTWALLOW, Z.STV, Z.ARATHI, Z.ALTERAC, Z.SWAMP } })
add({ key = "goldthorn", type = "herb", req = 170, item = 3821, zones = { Z.STV, Z.FERALAS, Z.ARATHI, Z.DUSTWALLOW, Z.SWAMP } })
add({ key = "khadgar", type = "herb", req = 185, item = 3358, zones = { Z.STV, Z.FERALAS, Z.ARATHI, Z.DUSTWALLOW, Z.SWAMP } })
add({ key = "wintersbite", type = "herb", req = 195, item = 3819, zones = { Z.ALTERAC } })
add({ key = "firebloom", type = "herb", req = 205, item = 4625, zones = { Z.TANARIS, Z.SEARING, Z.BLASTED, Z.BADLANDS } })
add({ key = "purplelotus", type = "herb", req = 210, item = 8831, extra = { 8153 }, zones = { Z.AZSHARA, Z.HINTERLANDS, Z.FERALAS, Z.TANARIS, Z.STV } })
add({ key = "arthastears", type = "herb", req = 220, item = 8836, zones = { Z.EPL, Z.WPL, Z.FELWOOD } })
add({ key = "sungrass", type = "herb", req = 230, item = 8838, zones = { Z.FERALAS, Z.AZSHARA, Z.HINTERLANDS, Z.UNGORO, Z.WPL } })
add({ key = "blindweed", type = "herb", req = 235, item = 8839, zones = { Z.SWAMP, Z.UNGORO } })
add({ key = "ghostmushroom", type = "herb", req = 245, item = 8845, zones = { Z.HINTERLANDS } })
add({ key = "gromsblood", type = "herb", req = 250, item = 8846, zones = { Z.FELWOOD, Z.BLASTED, Z.DESOLACE } })
add({ key = "goldensansam", type = "herb", req = 260, item = 13464, zones = { Z.AZSHARA, Z.UNGORO, Z.EPL, Z.FELWOOD, Z.BURNING } })
add({ key = "dreamfoil", type = "herb", req = 270, item = 13463, zones = { Z.AZSHARA, Z.EPL, Z.UNGORO, Z.FELWOOD, Z.BURNING, Z.SILITHUS, Z.WPL } })
add({ key = "silversage", type = "herb", req = 280, item = 13465, zones = { Z.WINTERSPRING, Z.EPL, Z.AZSHARA, Z.UNGORO, Z.BURNING } })
add({ key = "plaguebloom", type = "herb", req = 285, item = 13466, zones = { Z.EPL, Z.WPL, Z.FELWOOD } })
add({ key = "icecap", type = "herb", req = 290, item = 13467, zones = { Z.WINTERSPRING } })
add({ key = "blacklotus", type = "herb", req = 300, item = 13468, zones = { Z.BURNING, Z.SILITHUS, Z.WINTERSPRING, Z.EPL } })

-- Ores
add({ key = "copper", type = "ore", req = 1, nodes = { "copper" }, item = 2770, extra = { STONE.rough, GEM.malachite, GEM.tigerseye, GEM.shadowgem },
    zones = { Z.ELWYNN, Z.DUNMOROGH, Z.TIRISFAL, Z.DUROTAR, Z.MULGORE, Z.DARKSHORE, Z.WESTFALL, Z.LOCHMODAN, Z.SILVERPINE, Z.BARRENS, Z.REDRIDGE, Z.DUSKWOOD, Z.WETLANDS, Z.ASHENVALE, Z.STONETALON, Z.HILLSBRAD } })
add({ key = "tin", type = "ore", req = 65, nodes = { "tin" }, item = 2771, extra = { STONE.coarse, GEM.shadowgem, GEM.mossAgate, GEM.moonstone, GEM.jade },
    zones = { Z.LOCHMODAN, Z.SILVERPINE, Z.BARRENS, Z.REDRIDGE, Z.DUSKWOOD, Z.WETLANDS, Z.HILLSBRAD, Z.ASHENVALE, Z.STONETALON, Z.DARKSHORE, Z.NEEDLES, Z.ARATHI, Z.STV, Z.DESOLACE } })
add({ key = "silver", type = "ore", req = 75, nodes = { "silver", "silverOoze" }, item = 2775, extra = { STONE.coarse },
    zones = { Z.LOCHMODAN, Z.SILVERPINE, Z.BARRENS, Z.REDRIDGE, Z.DUSKWOOD, Z.WETLANDS, Z.HILLSBRAD, Z.ASHENVALE, Z.STONETALON, Z.NEEDLES, Z.ARATHI, Z.STV, Z.DESOLACE } })
add({ key = "incendicite", type = "ore", req = 65, nodes = { "incendicite" }, item = 3340, zones = { Z.WETLANDS } })
add({ key = "bloodstone", type = "ore", req = 75, nodes = { "bloodstone" }, item = 4278, zones = { Z.ARATHI } })
add({ key = "iron", type = "ore", req = 125, nodes = { "iron" }, item = 2772, extra = { STONE.heavy, GEM.jade, GEM.citrine, GEM.moonstone, GEM.aquamarine },
    zones = { Z.ARATHI, Z.STV, Z.DESOLACE, Z.NEEDLES, Z.ALTERAC, Z.BADLANDS, Z.HILLSBRAD, Z.STONETALON, Z.DUSTWALLOW, Z.FERALAS, Z.SWAMP, Z.ASHENVALE } })
add({ key = "indurium", type = "ore", req = 150, nodes = { "indurium" }, item = 5833, zones = { Z.BADLANDS } })
add({ key = "gold", type = "ore", req = 155, nodes = { "gold", "goldOoze" }, item = 2776, extra = { GEM.jade, GEM.citrine, GEM.moonstone },
    zones = { Z.ARATHI, Z.STV, Z.DESOLACE, Z.NEEDLES, Z.ALTERAC, Z.BADLANDS, Z.HINTERLANDS, Z.TANARIS, Z.SEARING, Z.FERALAS, Z.UNGORO, Z.AZSHARA } })
add({ key = "mithril", type = "ore", req = 175, nodes = { "mithril", "mithrilOoze" }, item = 3858, extra = { STONE.solid, GEM.citrine, GEM.aquamarine, GEM.starRuby },
    zones = { Z.HINTERLANDS, Z.SEARING, Z.BADLANDS, Z.TANARIS, Z.FERALAS, Z.AZSHARA, Z.FELWOOD, Z.BURNING, Z.UNGORO, Z.BLASTED, Z.STV, Z.ALTERAC, Z.SWAMP, Z.DUSTWALLOW, Z.DESOLACE, Z.WPL, Z.EPL, Z.WINTERSPRING, Z.SILITHUS } })
add({ key = "truesilver", type = "ore", req = 230, nodes = { "truesilver", "truesilverOoze" }, item = 7911, extra = { GEM.citrine, GEM.aquamarine, GEM.starRuby },
    zones = { Z.HINTERLANDS, Z.SEARING, Z.BADLANDS, Z.TANARIS, Z.FERALAS, Z.AZSHARA, Z.FELWOOD, Z.BURNING, Z.UNGORO, Z.BLASTED, Z.STV, Z.ALTERAC, Z.SWAMP, Z.WPL, Z.EPL, Z.WINTERSPRING, Z.SILITHUS } })
add({ key = "darkiron", type = "ore", req = 230, nodes = { "darkiron" }, item = 11370, zones = { Z.SEARING, Z.BURNING } })
add({ key = "smallthorium", type = "ore", req = 245, nodes = { "smallthorium", "thoriumOoze" }, item = 10620, extra = { STONE.dense, GEM.starRuby, GEM.sapphire, GEM.opal, GEM.emerald, GEM.diamond },
    zones = { Z.UNGORO, Z.BURNING, Z.WINTERSPRING, Z.SILITHUS, Z.FELWOOD, Z.AZSHARA, Z.WPL, Z.EPL, Z.BLASTED, Z.SEARING, Z.TANARIS, Z.FERALAS, Z.HINTERLANDS } })
add({ key = "hakkarithorium", type = "ore", req = 245, nodes = { "hakkarithorium" }, item = 10620, zones = { Z.STV } })
add({ key = "richthorium", type = "ore", req = 275, nodes = { "richthorium", "richthoriumOoze" }, item = 10620, extra = { STONE.dense, GEM.starRuby, GEM.sapphire, GEM.opal, GEM.emerald, GEM.diamond, GEM.arcane },
    zones = { Z.UNGORO, Z.BURNING, Z.WINTERSPRING, Z.SILITHUS, Z.EPL, Z.FELWOOD, Z.AZSHARA } })

-- Skinning brackets (creature level -> leather)
local function skin(key, lo, hi, req, gives)
    add({ key = key, type = "skin", req = req, minLvl = lo, maxLvl = hi, gives = gives })
end
skin("skin10", 1, 10, 1, { 2934, 2318, 783 })
skin("skin20", 10, 20, 100, { 2318, 783, 2319 })
skin("skin30", 20, 30, 150, { 2319, 4232, 4234 })
skin("skin40", 30, 40, 200, { 4234, 4235, 4304 })
skin("skin50", 40, 50, 250, { 4304, 8169, 8170 })
skin("skin60", 50, 60, 300, { 8170, 8171 })

-- Special leathers and scales: lowest skill of the creatures that give them (Forever data, Classic rule)
-- where = { { instance uiMapID, English fallback, boss or creature }, ... } for dungeon/raid sources
local INST = { WC = { 279, "Wailing Caverns" }, ST = { 220, "Sunken Temple" }, BRS = { 250, "Blackrock Spire" },
    MC = { 232, "Molten Core" }, BWL = { 287, "Blackwing Lair" }, ONY = { 248, "Onyxia's Lair" },
    ZG = { 233, "Zul'Gurub" }, AQ20 = { 247, "Ruins of Ahn'Qiraj" } }
local function special(key, req, item, zones, where)
    add({ key = key, type = "skin", group = "special", req = req, item = item, zones = zones, where = where })
end
special("blackwhelp", 70, 7286, { Z.REDRIDGE })
special("deviatescale", 100, 6470, { Z.BARRENS }, { { INST.WC } })
special("perfectdeviate", 100, 6471, { Z.BARRENS }, { { INST.WC } })
special("redwhelp", 115, 7287, { Z.WETLANDS })
special("turtlescale", 160, 8167, { Z.TANARIS, Z.HINTERLANDS })
special("greenwhelp", 170, 7392, { Z.SWAMP })
special("shadowcat", 185, 7428, { Z.STV, Z.SWAMP })
special("scorpidscale", 200, 8154, { Z.TANARIS, Z.BLASTED })
special("worndragonscale", 205, 8165, { Z.BURNING }, { { INST.BRS } })
special("greendragonscale", 205, 15412, { Z.SWAMP }, { { INST.ST }, { INST.BRS } })
special("chimera", 245, 15423, { Z.WINTERSPRING, Z.AZSHARA })
special("bluedragonscale", 250, 15415, { Z.WINTERSPRING }, { { INST.BRS } })
special("blackdragonscale", 250, 15416, { Z.BURNING }, { { INST.BRS } })
special("warbear", 255, 15419, { Z.WINTERSPRING, Z.WPL, Z.FELWOOD })
special("heavyscorpid", 260, 15408, { Z.SILITHUS, Z.BURNING }, { { INST.BRS } })
special("devilsaur", 270, 15417, { Z.UNGORO })
special("frostsaber", 275, 15422, { Z.WINTERSPRING })
special("silithidchitin", 280, 20498, { Z.SILITHUS }, { { INST.AQ20 } })
special("lightcarapace", 280, 20500, { Z.SILITHUS })
special("reddragonscale", 285, 15414, { Z.WETLANDS }, { { INST.BRS } })
special("heavycarapace", 290, 20501, { Z.SILITHUS }, { { INST.AQ20 } })
special("primalbat", 300, 19767, { Z.STV }, { { INST.ZG } })
special("primaltiger", 300, 19768, { Z.STV }, { { INST.ZG } })
-- Above 300: needs Skinning bonuses (glove enchants +5 / +10, Keen Skinning Knife +3...)
special("coreleather", 305, 17012, { Z.BURNING }, { { INST.MC, "CORE_HOUNDS", 305 }, { INST.MC, "Magmadar", 315 } })
special("beasthide", 310, 12731, { Z.BURNING }, { { INST.BRS, "BEAST", 310 } })
special("onyxiascale", 315, 15410, { Z.DUSTWALLOW }, { { INST.ONY, "Onyxia", 315 } })
special("chromaticscale", 315, 12607, { Z.BURNING }, { { INST.BWL, "Chromaggus", 315 } })
special("dreamscale", 315, 20381, { Z.DUSKWOOD, Z.ASHENVALE, Z.FERALAS, Z.HINTERLANDS }, { { nil, "Ysondre, Lethon, Emeriss, Taerar", 315 } })

-- Fish (zones from Wowhead Forever "fishing locations", most caught first; vendors from Warcraft Wiki / wow.gg)
-- req: minimum fishing skill ; time: "night" | "day" ; season: "summer" | "winter"
-- recipe = { item = recipe item (isRecipe) or cooked dish, vendors = { { npc, mapID, faction } } }
-- source = { drop = mapID } (rare drop) or { trainer = "alchemy" }
local A_, H_ = "Alliance", "Horde"
local CITIES = { CITY.STORMWIND, CITY.IRONFORGE, CITY.DARNASSUS, CITY.ORGRIMMAR, CITY.THUNDERBLUFF, CITY.UNDERCITY }
local function with(t, ...) local out = {} for _, v in ipairs(t) do out[#out + 1] = v end for _, v in ipairs({ ... }) do out[#out + 1] = v end return out end
-- Recipe vendors: { name, mapID, faction, x, y } (Classic positions, same in Forever)
local V = {
    catherine = { "Catherine Leland", CITY.STORMWIND, A_, 55.1, 69.6 }, gretta = { "Gretta Ganter", Z.DUNMOROGH, A_, 31.5, 44.6 },
    harn = { "Harn Longcast", Z.MULGORE, H_, 46.7, 59.1 }, khara = { "Khara Deepwater", Z.LOCHMODAN, A_, 40.3, 39.3 },
    lizbeth = { "Lizbeth Cromwell", CITY.UNDERCITY, H_, 81.0, 30.8 }, martine = { "Martine Tramblay", Z.TIRISFAL, H_, 65.9, 59.6 },
    nyoma = { "Nyoma", Z.TELDRASSIL, A_, 57.2, 61.3 }, sewa = { "Sewa Mistrunner", CITY.THUNDERBLUFF, H_, 55.8, 47.0 },
    tharynn = { "Tharynn Bouden", Z.ELWYNN, A_, 41.9, 67.1 }, zarrin = { "Zarrin", Z.TELDRASSIL, A_, 57.1, 61.3 },
    naal = { "Naal Mistrunner", CITY.THUNDERBLUFF, H_, 51.0, 52.5 }, tansy = { "Tansy Puddlefizz", CITY.IRONFORGE, A_, 48.2, 6.5 },
    killian = { "Killian Sanatha", Z.SILVERPINE, H_, 33.0, 17.9 }, lindea = { "Lindea Rabonne", Z.HILLSBRAD, A_, 50.1, 62.7 },
    kelsey = { "Kelsey Yance", Z.STV, nil, 28.2, 74.3 }, stuart = { "Stuart Fleming", Z.WETLANDS, A_, 8.0, 58.4 },
    shankys = { "Shankys", CITY.ORGRIMMAR, H_, 70.0, 29.8 }, heldan = { "Heldan Galesong", Z.DARKSHORE, A_, 37.0, 56.4 },
    wulan = { "Wulan", Z.DESOLACE, H_, 26.2, 69.7 }, wiktar = { "Wik'Tar", Z.ASHENVALE, H_, 11.8, 34.0 },
    kilxx = { "Kilxx", Z.BARRENS, nil, 62.8, 38.2 }, kriggon = { "Kriggon Talsone", Z.WESTFALL, A_, 36.0, 90.0 },
    nisha = { "Nessa Shadowsong", Z.TELDRASSIL, A_ }, zansul = { "Zansoa", Z.DUROTAR, H_, 57.0, 76.0 },
    gikkix = { "Gikkix", Z.TANARIS, nil, 66.6, 22.1 }, vivianna = { "Vivianna", Z.FERALAS, A_, 31.3, 43.5 },
    sheendra = { "Sheendra Tallgrass", Z.FERALAS, H_, 74.5, 42.7 },
}
-- Trainers shown by the skill-tier reminder: one per faction (capital city), plus the fishing special cases
Data.TRAINERS = {
    herb = { Alliance = { "Shylamiir", CITY.STORMWIND, 31.4, 62.9 }, Horde = { "Jandi", CITY.ORGRIMMAR, 55.6, 40.0 } },
    ore = { Alliance = { "Gelman Stonehand", CITY.STORMWIND, 59.1, 37.7 }, Horde = { "Makaru", CITY.ORGRIMMAR, 73.0, 27.0 } },
    skin = { Alliance = { "Maris Granger", CITY.STORMWIND, 72.3, 62.3 }, Horde = { "Thuwd", CITY.ORGRIMMAR, 63.1, 45.3 } },
    fish = { Alliance = { "Arnold Leland", CITY.STORMWIND, 55.1, 69.6 }, Horde = { "Lumak", CITY.ORGRIMMAR, 69.7, 29.3 } },
    heming = { "Old Man Heming", Z.STV, 27.0, 77.0 },
}
local COD_TROUT = { V.lindea, V.kelsey, V.stuart, V.shankys, V.heldan, V.lizbeth, V.tansy, V.wulan, V.wiktar }
local SOUTH_SEAS = { Z.AZSHARA, Z.FERALAS, Z.STV, Z.TANARIS, Z.HINTERLANDS }
local NIGHT_DAY = { Z.AZSHARA, Z.EPL, Z.FELWOOD, Z.FERALAS, Z.MOONGLADE, Z.HINTERLANDS, Z.UNGORO, Z.WPL, Z.WINTERSPRING }

add({ key = "smallfish", type = "fish", gives = { 6290 }, req = 1, item = 6291, zones = { CITY.STORMWIND, CITY.ORGRIMMAR, Z.ELWYNN, Z.DUROTAR, Z.BARRENS, CITY.DARNASSUS, Z.MULGORE, Z.TIRISFAL, CITY.IRONFORGE, Z.DUNMOROGH, Z.TELDRASSIL, CITY.THUNDERBLUFF, CITY.UNDERCITY },
    recipe = { item = 6325, isRecipe = true, vendors = { V.catherine, V.gretta, V.khara, V.nyoma, V.tharynn, V.zarrin, V.harn, V.lizbeth, V.martine, V.sewa } } })
add({ key = "slitherskin", type = "fish", gives = { 787 }, req = 1, item = 6303, zones = { Z.DUROTAR, Z.TELDRASSIL },
    recipe = { item = 787, vendors = { V.nisha, V.zansul } } })
add({ key = "longjaw", type = "fish", gives = { 4592 }, req = 1, item = 6289, zones = { CITY.STORMWIND, CITY.DARNASSUS, Z.ASHENVALE, Z.ELWYNN, CITY.UNDERCITY, CITY.ORGRIMMAR, Z.REDRIDGE, Z.HILLSBRAD, Z.DARKSHORE, CITY.IRONFORGE, CITY.THUNDERBLUFF },
    recipe = { item = 6328, isRecipe = true, vendors = { V.tharynn, V.khara, V.nyoma, V.tansy, V.naal, V.lizbeth, V.killian, V.harn } } })
add({ key = "rainbowfin", type = "fish", gives = { 5095 }, req = 1, item = 6361, zones = { Z.WETLANDS, Z.WESTFALL, Z.HILLSBRAD, Z.DARKSHORE, Z.BARRENS, Z.SILVERPINE, Z.ASHENVALE, CITY.STORMWIND },
    recipe = { item = 6368, isRecipe = true, vendors = { V.stuart, V.kriggon, V.shankys, V.kilxx } } })
add({ key = "sagefish", type = "fish", gives = { 21072 }, req = 1, item = 21071, zones = { Z.HILLSBRAD, Z.LOCHMODAN, Z.ASHENVALE, Z.SILVERPINE, Z.STONETALON },
    recipe = { item = 21099, isRecipe = true, vendors = { V.kelsey } } })
add({ key = "oilyblackmouth", type = "fish", gives = { 6370 }, req = 1, item = 6358, zones = { Z.STV, Z.WPL, Z.DUSTWALLOW, Z.MOONGLADE, Z.FERALAS, Z.WETLANDS, Z.DARKSHORE, Z.HILLSBRAD, Z.WESTFALL, Z.AZSHARA, Z.TANARIS, Z.HINTERLANDS, Z.SILVERPINE, Z.DESOLACE, Z.BARRENS, Z.ARATHI, Z.ASHENVALE, Z.UNGORO, CITY.STORMWIND, Z.SWAMP, Z.FELWOOD, Z.EPL },
    source = { trainer = "alchemy" } })
add({ key = "lochfrenzy", type = "fish", gives = { 6316 }, req = 1, item = 6317, zones = { Z.LOCHMODAN },
    recipe = { item = 6329, isRecipe = true, vendors = { V.khara } } })
-- Forever: Whimsyfin (new), recipe 251526 is a rare drop from Redridge Mountains mobs
add({ key = "whimsyfin", type = "fish", gives = { 251525 }, req = 1, item = 251524, zones = { Z.REDRIDGE },
    recipe = { item = 251526, isRecipe = true, drop = Z.REDRIDGE } })
add({ key = "deviate", type = "fish", gives = { 6657 }, req = 1, item = 6522, zones = { Z.BARRENS },
    recipe = { item = 6661, isRecipe = true, drop = Z.BARRENS } })
add({ key = "catfish", type = "fish", gives = { 4593 }, req = 55, item = 6308, zones = { Z.ASHENVALE, Z.DUSTWALLOW, CITY.STORMWIND, Z.HILLSBRAD, Z.REDRIDGE, Z.STV, Z.DUSKWOOD, Z.ALTERAC, Z.STONETALON, Z.WETLANDS, CITY.ORGRIMMAR, CITY.IRONFORGE, CITY.DARNASSUS, CITY.THUNDERBLUFF, CITY.UNDERCITY },
    recipe = { item = 6330, isRecipe = true, vendors = { V.catherine, V.naal, V.sewa, V.kilxx } } })
add({ key = "firefin", type = "fish", gives = { 6371 }, req = 55, item = 6359, zones = { Z.STV, Z.AZSHARA, Z.DUSTWALLOW, Z.WETLANDS, Z.TANARIS, Z.FERALAS, Z.HILLSBRAD, Z.DESOLACE, Z.HINTERLANDS, Z.STONETALON, Z.ARATHI, Z.SWAMP, Z.ASHENVALE, Z.BARRENS } })
add({ key = "mithriltrout", type = "fish", gives = { 8364 }, req = 130, item = 8365, zones = { Z.DESOLACE, Z.ARATHI, Z.DUSTWALLOW, Z.ALTERAC, Z.STV, Z.NEEDLES, Z.WPL, Z.FERALAS },
    recipe = { item = 17062, isRecipe = true, vendors = COD_TROUT } })
add({ key = "greatersagefish", type = "fish", gives = { 21217 }, req = 130, item = 21153, zones = { Z.ALTERAC, Z.STV },
    recipe = { item = 21219, isRecipe = true, vendors = { V.kelsey } } })
add({ key = "rockscale", type = "fish", gives = { 4594 }, req = 130, item = 6362, zones = { Z.ARATHI, Z.DESOLACE, Z.DUSTWALLOW, Z.STV, Z.SWAMP },
    recipe = { item = 6369, isRecipe = true, vendors = COD_TROUT } })
add({ key = "yellowtail", type = "fish", gives = { 6887 }, req = 205, item = 4603, zones = { Z.AZSHARA, Z.STV, Z.DUSTWALLOW, Z.FERALAS, Z.TANARIS, Z.HINTERLANDS, Z.SWAMP, Z.DESOLACE, Z.ARATHI, Z.NEEDLES },
    recipe = { item = 13939, isRecipe = true, vendors = { V.gikkix } } })
add({ key = "mightfish", type = "fish", gives = { 13927 }, req = 205, item = 13754, zones = { Z.AZSHARA, Z.TANARIS, Z.FERALAS, Z.HINTERLANDS, Z.STV },
    recipe = { item = 13940, isRecipe = true, vendors = { V.kelsey } } })
add({ key = "summerbass", type = "fish", gives = { 13929 }, req = 205, item = 13756, season = "summer", zones = SOUTH_SEAS,
    recipe = { item = 13943, isRecipe = true, vendors = { V.kelsey } } })
add({ key = "wintersquid", type = "fish", gives = { 13928 }, req = 205, item = 13755, season = "winter", zones = { Z.AZSHARA, Z.TANARIS, Z.FERALAS, Z.HINTERLANDS, Z.STV },
    recipe = { item = 13942, isRecipe = true, vendors = { V.gikkix } } })
add({ key = "redgill", type = "fish", gives = { 13930 }, req = 205, item = 13758, zones = { Z.EPL, Z.MOONGLADE, Z.BLASTED, Z.FELWOOD, Z.FERALAS, Z.UNGORO, Z.BADLANDS, Z.SILITHUS, Z.WINTERSPRING, Z.AZSHARA, Z.HINTERLANDS, Z.WPL },
    recipe = { item = 13930, vendors = { V.kelsey } } })
add({ key = "nightfin", type = "fish", gives = { 13931 }, req = 205, item = 13759, time = "night", zones = { Z.WPL, Z.MOONGLADE, Z.FERALAS, Z.HINTERLANDS, Z.EPL, Z.UNGORO, Z.AZSHARA, Z.FELWOOD, Z.DEADWIND, Z.WINTERSPRING, Z.ASHENVALE, Z.SILITHUS },
    recipe = { item = 13945, isRecipe = true, vendors = { V.gikkix } } })
add({ key = "sunscale", type = "fish", gives = { 13932 }, req = 205, item = 13760, time = "day", zones = { Z.WPL, Z.MOONGLADE, Z.FERALAS, Z.HINTERLANDS, Z.EPL, Z.AZSHARA, Z.FELWOOD, Z.UNGORO, Z.DEADWIND, Z.WINTERSPRING, Z.ASHENVALE, Z.SILITHUS },
    recipe = { item = 13946, isRecipe = true, vendors = { V.gikkix } } })
add({ key = "stonescale", type = "fish", gives = { 13423 }, req = 205, item = 13422, zones = { Z.AZSHARA, Z.STV, Z.TANARIS, Z.FERALAS, Z.HINTERLANDS, Z.EPL },
    source = { trainer = "alchemy" } })
add({ key = "whitescale", type = "fish", gives = { 13935 }, req = 330, item = 13889, zones = { Z.EPL, Z.DEADWIND, Z.FERALAS, Z.WINTERSPRING, Z.SILITHUS, Z.BURNING },
    recipe = { item = 13949, isRecipe = true, vendors = { V.vivianna, V.sheendra } } })
-- Nat Pagle, Angler Extreme (quest 6607): only caught while the quest is active, same spots as Classic
Data.NAT_PAGLE = { quest = 6607, npc = "Nat Pagle", map = Z.DUSTWALLOW, x = 58.6, y = 60.0, level = 35, skill = 225 }
add({ key = "feralasahi", type = "fish", group = "quest", quest = 6607, req = 225, item = 16967, zones = { Z.FERALAS }, spot = { map = Z.FERALAS, x = 62.0, y = 51.0 } })
add({ key = "mahimahi", type = "fish", group = "quest", quest = 6607, req = 225, item = 16970, zones = { Z.SWAMP }, spot = { map = Z.SWAMP, x = 90.0, y = 72.0 } })
add({ key = "sartheris", type = "fish", group = "quest", quest = 6607, req = 225, item = 16968, zones = { Z.DESOLACE }, spot = { map = Z.DESOLACE, x = 25.0, y = 77.0 } })
add({ key = "sailfin", type = "fish", group = "quest", quest = 6607, req = 225, item = 16969, zones = { Z.STV }, spot = { map = Z.STV, x = 33.0, y = 32.0 } })

-- Forever: recipe 286153 is picked up from a cart in Deadwind Pass (52.35, 34.48). Mount Hyjal also has the fish (no mapID yet)
add({ key = "armorfish", type = "fish", gives = { 286152 }, req = 205, item = 13890, zones = { Z.EPL, Z.DEADWIND, Z.FERALAS, Z.WINTERSPRING, Z.SILITHUS, Z.ALTERAC },
    recipe = { item = 286153, isRecipe = true, object = { map = Z.DEADWIND, x = 52.35, y = 34.48 } } })

---------------------------------------------------------------------------
-- Lookups
---------------------------------------------------------------------------
Data.byKey = {}
Data.byItem = {}       -- itemID -> resource (main item only)
Data.gatherItems = {}  -- every item a gathering action can give
Data.nodeNames = {}    -- localized node name -> resource

local function preload(id)
    if C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
end

function Data:Init()
    for _, r in ipairs(R) do
        self.byKey[r.key] = r
        if r.item then
            self.byItem[r.item] = self.byItem[r.item] or r
            self.gatherItems[r.item] = true
            preload(r.item)
        end
        for _, id in ipairs(r.extra or {}) do self.gatherItems[id] = true; preload(id) end
        for _, id in ipairs(r.gives or {}) do self.gatherItems[id] = true; preload(id) end
        if r.recipe then preload(r.recipe.item) end
        -- Skinning zones are derived from creature level ranges
        if r.type == "skin" and r.minLvl then
            r.zones = {}
            for mapID, lv in pairs(self.ZoneLevels) do
                if lv[1] <= r.maxLvl and lv[2] >= r.minLvl then r.zones[#r.zones + 1] = mapID end
            end
            table.sort(r.zones, function(a, b) return self.ZoneLevels[a][1] < self.ZoneLevels[b][1] end)
        end
    end
    for _, l in ipairs(self.Lures) do preload(l[1]) end
    preload(self.ExpertFishingBook)
    self:BuildNodeNames()
    ns.FG:RegisterEvent("GET_ITEM_INFO_RECEIVED", function() Data:OnItemInfo() end)
end

local pending
function Data:OnItemInfo()
    if pending then return end
    pending = true
    C_Timer.After(0.5, function()
        pending = nil
        Data:BuildNodeNames()
        if ns.Window and ns.Window.frame and ns.Window.frame:IsShown() then ns.Window:Refresh(true) end
    end)
end

function Data:BuildNodeNames()
    local names = self.nodeNames
    for _, r in ipairs(R) do
        if r.type == "herb" then
            local n = ns.GetItemInfo(r.item)
            if n then names[n] = r end
        elseif r.type == "ore" then
            for _, k in ipairs(r.nodes) do
                local n = rawget(L, "NODE_" .. k) or L["NODE_" .. k]
                if n and n ~= "" then names[n] = r end
            end
        end
    end
    -- Node names learned while gathering (covers every game language)
    local learned = ns.db and ns.db.global.learnedNodes[GetLocale()]
    if learned then
        for n, key in pairs(learned) do
            if self.byKey[key] then names[n] = self.byKey[key] end
        end
    end
end

-- Display name of a resource
function Data:Name(r)
    if r.type == "skin" and r.minLvl then return L["Beasts level %d-%d"]:format(r.minLvl, r.maxLvl) end
    if r.type == "ore" then
        local n = L["NODE_" .. r.nodes[1]]
        if n and n ~= "" then return n end
    end
    return (r.item and ns.GetItemInfo(r.item)) or r.key
end

-- Static + learned zones of a resource
function Data:Zones(r)
    local list, seen = {}, {}
    for _, id in ipairs(r.zones or {}) do list[#list + 1] = id; seen[id] = true end
    local learned = ns.db and ns.db.global.learnedZones[r.key]
    if learned then
        for id in pairs(learned) do
            if not seen[id] then list[#list + 1] = id; seen[id] = "learned" end
        end
    end
    return list, seen
end

-- Skill thresholds for colour bands
function Data:Thresholds(r)
    return { yellow = r.req + 25, green = r.req + 50, grey = r.req + 100 }
end
