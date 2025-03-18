-- Constants.lua - Contains all constant values for Character Manager addon

-- Raid information
CharacterManager_Raids = {
    "mc",
    "ony",
    "bwl",
    "zg",
    "aq20",
    "aq40",
    "naxx"
}
CharacterManager_RaidDisplayNames = {
    ["mc"] = "Molten Core",
    ["ony"] = "Onyxia",
    ["bwl"] = "Blackwing Lair",
    ["zg"] = "Zul'Gurub",
    ["aq20"] = "Ruins of Ahn'Qiraj",
    ["aq40"] = "Temple of Ahn'Qiraj",
    ["naxx"] = "Naxxramas"
}

CharacterManager_RaidActualNames = {
    ["ony"] = "Onyxia's Lair",
    ["mc"] = "Molten Core",
    ["bwl"] = "Blackwing Lair",
    ["zg"] = "Zul'Gurub",
    ["aq20"] = "Ruins of Ahn'Qiraj",
    ["aq40"] = "Temple of Ahn'Qiraj",
    ["naxx"] = "Naxxramas"
}


-- Class colors
CharacterManager_ClassColors = {
    ["WARRIOR"] = "|cFFC79C6E",
    ["PALADIN"] = "|cFFF58CBA",
    ["HUNTER"] = "|cFFABD473",
    ["ROGUE"] = "|cFFFFF569",
    ["PRIEST"] = "|cFFFFFFFF",
    ["SHAMAN"] = "|cFF0070DE",
    ["MAGE"] = "|cFF69CCF0",
    ["WARLOCK"] = "|cFF9482C9",
    ["DRUID"] = "|cFFFF7D0A"
}

-- Constants.lua

-- Define profession cooldowns data
CharacterManager_ProfessionCooldownsData = {
    {name = "Transmute: Arcanite", profession = "Alchemy", totalDuration = 172800}, -- 2 days
    {name = "Transmute: Other", profession = "Alchemy", totalDuration = 86400}, -- 1 day
    {name = "Salt Shaker", profession = "Leatherworking", totalDuration = 259200}, -- 3 days
    {name = "Mooncloth", profession = "Tailoring", totalDuration = 345600} -- 4 days
}

-- Define spells to track
CharacterManager_SpellsToTrack = {
    Tailoring = {
        {id = 18560, name = "Mooncloth"}
    },
    Leatherworking = {
        {id = 19566, name = "Salt Shaker"}
    },
    Alchemy = {
        {id = 17187, name = "Transmute: Arcanite"},
        {id = 17559, name = "Transmute: Air to Fire"},
        {id = 17560, name = "Transmute: Fire to Earth"},
        {id = 17561, name = "Transmute: Earth to Water"},
        {id = 17562, name = "Transmute: Water to Air"},
        {id = 17563, name = "Transmute: Undeath to Water"},
        {id = 17564, name = "Transmute: Water to Undeath"},
        {id = 17565, name = "Transmute: Life to Earth"},
        {id = 17566, name = "Transmute: Earth to Life"}
    }
}

-- Tracked buffs with boonSlots
CharacterManager_TrackedBuffs = {
    {
        name       = "Rallying Cry of the Dragonslayer", -- / Horn of the Dawn"
        checkType  = "ANY",
        spellIds   = {
            22888,   -- Rallying Cry of the Dragonslayer
            --355363,  -- Also Rallying Cry of the Dragonslayer?
            --473387,  -- Horn of the Dawn (SoD)
        },
        boonSlots  = {20},
        phase      = 1,  -- Available from Phase 1
    },
    {
        name       = "Warchief's Blessing", --"Might of Stormwind / Blackrock /
        checkType  = "ANY",
        spellIds   = {
            --460939,  -- Might of Stormwind (SoD)
            --460940,  -- Also Might of Stormwind (SoD)?
            --473441,  -- Might of Blackrock (SoD)
            16609,   -- Warchief's Blessing
        },
        boonSlots  = {21, 29},
        phase      = 1,  -- Available from Phase 1
    },
    {
        name       = "Songflower Serenade", -- / Lullaby
        checkType  = "ANY",
        spellIds   = {
            15366,   -- Songflower Serenade
            --473399,  -- Songflower Lullaby (SoD)
        },
        boonSlots  = {23},
        phase      = 1,  -- Available from Phase 1
    },
    {
        name       = "Dire Maul Tribute Buffs", 
        checkType  = "ANY",
        spellIds   = {
            22817,   -- Fengus' Ferocity
            22766,   -- Slip'kik's Savvy
            22818,   -- Mol'dar's Moxie
            --473403,  -- Blessing of Neptulon (SoD) (UPDATED ID)
        },
        boonSlots  = {17,18,19},
        phase      = 2,  -- Available from Phase 2 (Dire Maul)
    },
    {
        name       = "Any Darkmoon Faire Buff",
        checkType  = "ANY",
        spellIds   = {
            23766, -- Sayge's Dark Fortune of Agility
            23737, -- Sayge's Dark Fortune of Armor
            23735, -- Sayge's Dark Fortune of Resistance
            23738, -- Sayge's Dark Fortune of Spirit
            23769, -- Sayge's Dark Fortune of Strength
            23736, -- Sayge's Dark Fortune of Stamina
            23767, -- Sayge's Dark Fortune of Intellect
            23768, -- Sayge's Dark Fortune of Damage
            --473450,-- Dark Fortune of Damage (SoD)
        },
        boonSlots  = {24},
        phase      = 3,  -- Available from Phase 3 (Darkmoon Faire)
    },
    {
        name       = "Spirit of Zandalar", -- / Dreams
        checkType  = "ANY",
        spellIds   = {
            24425,   -- Spirit of Zandalar
            355365,  -- Also Spirit of Zandalar?
            --473476,  -- Dreams of Zandalar (SoD)
        },
        boonSlots  = {22},
        phase      = 4,  -- Available from Phase 4 (ZG)
    },
}

-- Chronoboon constant
CharacterManager_CHRONOBOON_AURA_ID = 349981