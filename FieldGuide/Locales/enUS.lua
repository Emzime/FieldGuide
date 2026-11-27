-- FieldGuide - English (default) locale
local L = LibStub("AceLocale-3.0"):NewLocale("FieldGuide", "enUS", true)
local _, ns = ...

-- English node names are also kept apart, to spot the ones not translated in the client language
ns.NODE_EN = {}
local function Node(key, name)
    L["NODE_" .. key] = name
    ns.NODE_EN[key] = name
end

-- Profession names as shown in the skill list (used to read skill levels)
L["PROF_herb"] = "Herbalism"
L["PROF_ore"] = "Mining"
L["PROF_skin"] = "Skinning"
L["PROF_fish"] = "Fishing"

-- Tooltip lines
L["Req"] = "Req:"
L["CURRENT_herb"] = "Your current Herbalism: %d/%d"
L["CURRENT_ore"] = "Your current Mining: %d/%d"
L["CURRENT_skin"] = "Your current Skinning: %d/%d"
L["CURRENT_fish"] = "Your current Fishing: %d/%d"
L["Skill gain: %s"] = "Skill gain: %s"
L["You are missing %d points"] = "You are missing %d points"
L["Max skinnable level: %d"] = "Max skinnable level: %d"
L["Not learned"] = "Not learned"

-- Difficulty / gain
L["GAIN_red"] = "impossible"
L["GAIN_orange"] = "guaranteed"
L["GAIN_yellow"] = "likely"
L["GAIN_green"] = "rare"
L["GAIN_grey"] = "none"
L["BAND_orange"] = "orange"
L["BAND_yellow"] = "yellow"
L["BAND_green"] = "green"

-- Window
L["Field guide"] = "Field guide"
L["Search..."] = "Search..."
L["All"] = "All"
L["Herbs"] = "Herbs"
L["Ores"] = "Ores"
L["Skinning"] = "Skinning"
L["Fishing"] = "Fishing"
L["East"] = "East"
L["All continents"] = "All continents"
L["Harvestable"] = "Harvestable"
L["Harvestable_tip"] = "Only show what my skill allows"
L["No grey"] = "No grey"
L["No grey_tip"] = "Hide what no longer gives skill points"
L["My zone"] = "My zone"
L["My zone_tip"] = "Only show what can be gathered in: %s"
L["Session"] = "Session"
L["%d gathers"] = "%d gathers"
L["+%d points"] = "+%d points"
L["%d results"] = "%d results"
L["Filter: %s"] = "Filter: %s"
L["Map pin placed: %s. Open the map to see it."] = "Map pin placed: %s. Open the map to see it."
L["No results with these filters."] = "No results with these filters."
L["Required skill"] = "Required skill"
L["Your level"] = "Your level"
L["Skill points"] = "Skill points"
L["What it gives"] = "What it gives"
L["Recipes and where to get them"] = "Recipes and where to get them"
L["Time of day"] = "Time of day"
L["Recommended lure"] = "Recommended lure"
L["None needed"] = "None needed"
L["Day and night"] = "Day and night"
L["Night only (18:00 - 06:00)"] = "Night only (18:00 - 06:00)"
L["Day only (06:00 - 18:00)"] = "Day only (06:00 - 18:00)"
L["It is currently day"] = "It is currently day"
L["It is currently night"] = "It is currently night"
L["Also on creatures"] = "Also on creatures"
L["Gathering zones"] = "Gathering zones"
L["Zones for these beasts"] = "Zones for these beasts"
L["Fishing zones"] = "Fishing zones"
L["Click a zone to open it on the world map."] = "Click a zone to open it on the world map."
L["Level %s"] = "Level %s"
L["Fishing min. %d"] = "Fishing min. %d"
L["Recorded by you"] = "Recorded by you"
L["Beasts level %d-%d"] = "Beasts level %d-%d"
L["Creatures (mining)"] = "Creatures (mining)"
L["Creatures (herbalism)"] = "Creatures (herbalism)"
L["Creatures you have seen that can be gathered."] = "Creatures you have seen that can be gathered."
L["Next target"] = "Next target"
L["none"] = "none"
L["rare"] = "rare"
L["Options"] = "Options"
L["Close"] = "Close"
L["Used in alchemy"] = "Used in alchemy"

-- Recipe sources
L["SRC_COOKING_VENDOR"] = "Cooking supply vendors"
L["SRC_COOKING_TRAINER"] = "Cooking trainers"
L["SRC_FERALAS"] = "Sheendra Tallgrass (Horde) / Vivianna (Alliance), Feralas"
L["SRC_ALCHEMY_TRAINER"] = "Alchemy trainers"

-- Progression / trainer reminders
L["Missing tool: %s"] = "Missing tool: %s"
L["TRAINER_75"] = "Journeyman: visit a trainer in a capital (level 10)"
L["TRAINER_150"] = "Expert: visit a trainer in a capital (level 20)"
L["TRAINER_225"] = "Artisan: visit an artisan trainer (level 35)"
L["TRAINER_300"] = "Master: visit a trainer in Hellfire Peninsula (level 50)"
L["TRAINER_FISH_150"] = "Expert: book %s, sold by Old Man Heming in Booty Bay"
L["TRAINER_FISH_225"] = "Artisan: quest from Nat Pagle, Dustwallow Marsh (skill 225)"
L["Cap reached"] = "Cap reached"
L["Almost capped"] = "Almost capped"

-- Alerts
L["New node available"] = "New node available"
L["%s: %s %d reached"] = "%s: %s %d reached"
L["Turned grey"] = "Turned grey"
L["%s no longer gives skill points"] = "%s no longer gives skill points"
L["Missing tool"] = "Missing tool"
L["No %s in your bags"] = "No %s in your bags"
L["Next skill tier"] = "Next skill tier"

-- Minimap
L["Left-click"] = "Left-click"
L["Right-click"] = "Right-click"
L["Drag"] = "Drag"
L["open the window"] = "open the window"
L["options"] = "options"
L["move the icon"] = "move the icon"

-- Options
L["Tooltips"] = "Tooltips"
L["Show on herbs and ores"] = "Show on herbs and ores"
L["Show on creatures"] = "Show on creatures"
L["Show the required skill"] = "Show the required skill"
L["Show the skill gain"] = "Show the skill gain"
L["Alerts"] = "Alerts"
L["New harvestable node"] = "New harvestable node"
L["Node turned grey"] = "Node turned grey"
L["Trainer reminder (skill tiers)"] = "Trainer reminder (skill tiers)"
L["Play a sound"] = "Play a sound"
L["Display time (seconds)"] = "Display time (seconds)"
L["Minimap"] = "Minimap"
L["Show the icon"] = "Show the icon"
L["Lock the position"] = "Lock the position"
L["Window and session"] = "Window and session"
L["Scale"] = "Scale"
L["Opacity"] = "Opacity"
L["Show session statistics"] = "Show session statistics"
L["Reset the session"] = "Reset the session"
L["Test alerts"] = "Test alerts"
L["Session reset."] = "Session reset."
L["Usage: /fg [options | reset]"] = "Usage: /fg [options | reset]"

-- Creature type returned by UnitCreatureType for beasts
L["CREATURE_BEAST"] = "Beast"

-- Ore node names (other languages are learned automatically after the first gather)
Node("copper", "Copper Vein")
Node("tin", "Tin Vein")
Node("silver", "Silver Vein")
Node("silverOoze", "Ooze Covered Silver Vein")
Node("iron", "Iron Deposit")
Node("gold", "Gold Vein")
Node("goldOoze", "Ooze Covered Gold Vein")
Node("mithril", "Mithril Deposit")
Node("mithrilOoze", "Ooze Covered Mithril Deposit")
Node("truesilver", "Truesilver Deposit")
Node("truesilverOoze", "Ooze Covered Truesilver Deposit")
Node("darkiron", "Dark Iron Deposit")
Node("smallthorium", "Small Thorium Vein")
Node("thoriumOoze", "Ooze Covered Thorium Vein")
Node("richthorium", "Rich Thorium Vein")
Node("heavythorium", "Heavy Thorium Vein")
Node("richthoriumOoze", "Ooze Covered Rich Thorium Vein")
L["Reset all settings"] = "Reset all settings"
L["Reset all settings?"] = "Reset every FieldGuide setting to its default value?"
L["Settings reset."] = "Settings reset."
L["Default window size and position"] = "Default window size and position"
L["Reset"] = "Reset"
L["Recipe: %s"] = "Recipe: %s"
L["+%d other vendors"] = "+%d other vendors"
L["Rare drop"] = "Rare drop"
L["Found in the world"] = "Cart (pick up)"
L["Special leathers and scales"] = "Special leathers and scales"
L["Dungeons and raids"] = "Dungeons and raids"
L["SKIN_BONUS_HINT"] = "Above 300 you need Skinning bonuses: glove enchant Skinning (+5) or Advanced Skinning (+10, new), Keen Skinning Knife (+3, Horde quest), plus a few items (+2 to +4). Pip's Skinner and the Zulian Slicer are not in Forever. \"Your level\" shows your bonus in green."
L["BOSS_CORE_HOUNDS"] = "Core Hounds"
L["BOSS_BEAST"] = "The Beast"
L["FISH_BONUS_HINT"] = "Above 300, requirements include pole and lure bonuses: 330 = skill 300 + at least 30 bonus (lure, pole). \"Your level\" shows your current bonus in green."
L["Click to place a map pin."] = "Click to place a map pin."
L["Nat Pagle quest"] = "Nat Pagle quest"
L["Raid loot"] = "Raid loot"
L["Sold by vendors"] = "Sold by vendors"
L["Where to buy"] = "Where to buy"
L["Vendor"] = "Vendor"
L["Creatures"] = "Creatures"
L["Creatures and dungeons"] = "Creatures and dungeons"
L["ZONE_RIVERGLADES"] = "Riverglades"
L["BOSS_HYJAL_BEASTS"] = "Mount Hyjal beasts (level 55-60)"
L["BOSS_SCALE_MOBS"] = "Murlocs, nagas, crustaceans and crawlers (level 19-44)"
L["BOSS_MUTANUS"] = "Mutanus the Devourer"
L["BOSS_COOKIE"] = "Cookie"
L["Fishing spot"] = "Fishing spot"
L["Only caught while the quest is active. Click to place a map pin."] = "Only caught while the quest is active. Click to place a map pin."
L["Quest: level %d and Fishing %d. Unlocks Artisan Fishing."] = "Quest: level %d and Fishing %d. Unlocks Artisan Fishing."
L["Quest status"] = "Quest status"
L["Completed"] = "Completed"
L["In progress"] = "In progress"
L["Not taken"] = "Not taken"
L["Caught"] = "Caught"
L["Nat Pagle quest fish in this zone"] = "Nat Pagle quest fish in this zone"
L["Nat Pagle quest fish"] = "Nat Pagle quest fish"
L["%s: fish at %s"] = "%s: fish at %s"
L["Mostly at night"] = "Mostly at night"
L["Not between 00:00 and 06:00"] = "Not between 00:00 and 06:00"
L["Spring to autumn (seasonal)"] = "Spring to autumn (seasonal)"
L["Autumn to spring (seasonal)"] = "Autumn to spring (seasonal)"
L["Reagents needed"] = "Reagents needed"
L["Label the reagents in recipe tooltips"] = "Label the reagents in recipe tooltips"
L["All factions"] = "All factions"
L["No vendor for this faction."] = "No vendor for this faction."
Node("incendicite", "Incendicite Mineral Vein")
Node("bloodstone", "Lesser Bloodstone Deposit")
Node("indurium", "Indurium Mineral Vein")
Node("hakkarithorium", "Hakkari Thorium Vein")
