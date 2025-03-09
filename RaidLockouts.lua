local raids = CharacterManager_Raids
local raidActualNames = CharacterManager_RaidActualNames


function GetRaidLockoutStatus(raidName)
    local actualRaidName = raidActualNames[raidName] or raidName
    local numSavedInstances = GetNumSavedInstances()
    for i = 1, numSavedInstances do
        local name, _, reset, _, _, _, _, _, _, difficultyName, numEncounters, encounterProgress = GetSavedInstanceInfo(i)
        if name == actualRaidName then
            if reset > 0 then
                -- Adjust for Molten Core
                if name == "Molten Core" then
                    numEncounters = 10
                    encounterProgress = math.min(encounterProgress, 10)
                end
                return "Locked", reset, encounterProgress, numEncounters
            else
                -- Adjust for Molten Core
                if name == "Molten Core" then
                    numEncounters = 10
                    encounterProgress = math.min(encounterProgress, 10)
                end
                return "Done", 0, encounterProgress, numEncounters
            end
        end
    end
    return "Open", 0, 0, 0
end


function UpdateAllRaidStatuses()
    local playerName = UnitName("player")
    local realmName = GetRealmName()
    local fullName = playerName .. " - " .. realmName

    if characters[fullName] then
        if not characters[fullName].raidStatus then
            characters[fullName].raidStatus = {}
        end
        for _, raidName in ipairs(raids) do
            local status, reset, progress, total = GetRaidLockoutStatus(raidName)
            characters[fullName].raidStatus[raidName] = {
                status = status,
                reset = reset,
                progress = progress,
                total = total,
                lastUpdated = time()
            }
        end
    end
    return characters
end