-- Make sure we have a global namespace
if not CharacterManager then CharacterManager = {} end

-- Use the global namespace
local CM = CharacterManager

-- Class icon coordinates
CM.CLASS_ICON_TCOORDS = {
    ["WARRIOR"] = {0, 0.25, 0, 0.25},
    ["MAGE"] = {0.25, 0.5, 0, 0.25},
    ["ROGUE"] = {0.5, 0.75, 0, 0.25},
    ["DRUID"] = {0.75, 1, 0, 0.25},
    ["HUNTER"] = {0, 0.25, 0.25, 0.5},
    ["SHAMAN"] = {0.25, 0.5, 0.25, 0.5},
    ["PRIEST"] = {0.5, 0.75, 0.25, 0.5},
    ["WARLOCK"] = {0.75, 1, 0.25, 0.5},
    ["PALADIN"] = {0, 0.25, 0.5, 0.75}
}

-- Tracked buffs configuration
CM.trackedBuffs = {
    { name = "Rallying Cry of the Dragonslayer", spellID = 22888, boonSlots = {1} },
    { name = "Spirit of Zandalar", spellID = 24425, boonSlots = {2} },
    { name = "Songflower Serenade", spellID = 15366, boonSlots = {3} },
    { name = "Slip'kik's Savvy", spellID = 22820, boonSlots = {4} },
    { name = "Fengus' Ferocity", spellID = 22817, boonSlots = {5} },
    { name = "Mol'dar's Moxie", spellID = 22818, boonSlots = {6} },
    { name = "Warchief's Blessing", spellID = 16609, boonSlots = {7} },
    { name = "Sayge's Dark Fortune of Damage", spellID = 23768, boonSlots = {8} },
    { name = "Sayge's Dark Fortune of Resistance", spellID = 23767, boonSlots = {9} },
    { name = "Sayge's Dark Fortune of Armor", spellID = 23766, boonSlots = {10} },
    { name = "Sayge's Dark Fortune of Intelligence", spellID = 23769, boonSlots = {11} },
    { name = "Sayge's Dark Fortune of Spirit", spellID = 23738, boonSlots = {12} },
    { name = "Sayge's Dark Fortune of Stamina", spellID = 23737, boonSlots = {13} },
    { name = "Sayge's Dark Fortune of Strength", spellID = 23735, boonSlots = {14} },
    { name = "Sayge's Dark Fortune of Agility", spellID = 23736, boonSlots = {15} },
    { name = "Dire Maul Tribute", spellID = 22817, boonSlots = {4, 5, 6} }, -- Special case for all DM buffs
}

-- Tracked profession cooldowns
CM.trackedProfessionCooldowns = {
    -- Alchemy
    { name = "Transmute", spellIDs = {17559, 17560, 17561, 17562, 17563, 17564, 17565, 17566} },
    -- Tailoring
    { name = "Mooncloth", spellIDs = {18560} },
    -- Leatherworking
    { name = "Salt Shaker", spellIDs = {25659} },
    -- Blacksmithing
    { name = "Elemental Sharpening Stone", spellIDs = {22757} },
}