local CM = CharacterManager

-- Format time in minutes and seconds
function CM.FormatTimeMinutes(seconds)
    if not seconds or seconds <= 0 then
        return "Not Active"
    end
    
    local minutes = math.floor(seconds / 60)
    local remainingSeconds = math.floor(seconds % 60)
    
    if minutes > 0 then
        return string.format("%dm %ds", minutes, remainingSeconds)
    else
        return string.format("%ds", remainingSeconds)
    end
end

-- Get character's full name (name-realm)
function CM.GetFullCharacterName()
    local name = UnitName("player")
    local realm = GetRealmName()
    return name .. " - " .. realm
end

-- Get tracked spell IDs for profession cooldowns
function CM.GetTrackedSpellIDs()
    local spellIDs = {}
    for _, cooldownInfo in ipairs(CM.trackedProfessionCooldowns) do
        for _, spellID in ipairs(cooldownInfo.spellIDs) do
            table.insert(spellIDs, spellID)
        end
    end
    return spellIDs
end