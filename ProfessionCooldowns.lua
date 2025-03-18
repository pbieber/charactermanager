-- ProfessionCooldowns.lua
CharacterManager_ProfessionCooldowns = {}
-- Handles profession cooldown tracking functionality

-- ProfessionCooldowns.lua
CharacterManager_ProfessionCooldowns = {}
-- Handles profession cooldown tracking functionality

-- Reference the data from Constants.lua
local professionCooldowns = CharacterManager_ProfessionCooldownsData
local SpellsToTrack = CharacterManager_SpellsToTrack

-- Function to get tracked spell IDs
local function GetTrackedSpellIDs()
    local spellIDs = {}
    for profession, spells in pairs(SpellsToTrack) do
        for _, spell in ipairs(spells) do
            table.insert(spellIDs, spell.id)
        end
    end
    return spellIDs
end

-- Add this function to the module
function CharacterManager_ProfessionCooldowns.FormatTime(seconds)
    if seconds <= 0 then
        return "0d 0h"
    end
    
    -- If less than 12 hours, show hours and minutes
    if seconds < 43200 then -- 12 hours = 43200 seconds
        local hours = math.floor(seconds / 3600)
        local minutes = math.floor((seconds % 3600) / 60)
        return string.format("%02dh%02dm", hours, minutes)
    else
        -- Otherwise show days and hours
        local days = math.floor(seconds / 86400)
        local hours = math.floor((seconds % 86400) / 3600)
        return string.format("%dd %dh", days, hours)
    end
end


-- Function to check professions and spells
local function CheckProfessionsAndSpells(characters, fullName)
    if not characters[fullName] then
        characters[fullName] = { 
            name = UnitName("player"), 
            professions = {},
            professionCooldowns = {}
        }
    elseif not characters[fullName].professions then
        characters[fullName].professions = {}
    end

    -- Check professions
    for i = 1, GetNumSkillLines() do
        local skillName, isHeader, _, skillRank, _, _, skillMaxRank = GetSkillLineInfo(i)
        if not isHeader and (skillName == "Alchemy" or skillName == "Leatherworking" or skillName == "Tailoring") then
            characters[fullName].professions[skillName] = {rank = skillRank, maxRank = skillMaxRank}
        end
    end

    -- Check for any active cooldowns that might not be properly tracked
    local currentCharacter = fullName
    if characters[currentCharacter] and characters[currentCharacter].professions then
        for profession, spells in pairs(SpellsToTrack) do
            if characters[currentCharacter].professions[profession] then
                for _, spell in ipairs(spells) do
                    local start, duration = GetSpellCooldown(spell.id)
                    if start > 0 and duration > 0 then
                        -- There's an active cooldown from the API
                        local currentTime = GetTime()
                        local serverTime = GetServerTime()
                        local remainingTime = start + duration - currentTime
                        print("Cooldown detected for" .. spell.name)
                        
                        -- Initialize professionCooldowns if it doesn't exist
                        if not characters[currentCharacter].professionCooldowns then
                            characters[currentCharacter].professionCooldowns = {}
                        end
                        
                        -- Check if we need to update the stored cooldown
                        local needsUpdate = true
                        if characters[currentCharacter].professionCooldowns[spell.name] then
                            local storedData = characters[currentCharacter].professionCooldowns[spell.name]
                            local storedRemaining = (storedData.remainingTime or 0) - (serverTime - (storedData.lastUpdated or 0))
                            
                            -- If the difference is small, we don't need to update
                            if math.abs(storedRemaining - remainingTime) < 60 then
                                needsUpdate = false
                            end
                        end
                        
                        -- Update the cooldown if needed
                        if needsUpdate then
                            print("Updating cooldown for " .. spell.name .. " - API shows active cooldown")
                            characters[currentCharacter].professionCooldowns[spell.name] = {
                                startTime = start,
                                duration = duration,
                                remainingTime = remainingTime,
                                lastUpdated = serverTime
                            }
                        end
                    end
                end
            end
        end
    end

    return characters
end

-- Function to save profession cooldowns
local function SaveProfessionCooldowns(characters, fullName)
    if not characters[fullName] then
        characters[fullName] = { 
            name = UnitName("player"), 
            professions = {},
            professionCooldowns = {}
        }
    elseif not characters[fullName].professionCooldowns then
        characters[fullName].professionCooldowns = {}
    end

    local currentTime = GetTime()
    local serverTime = GetServerTime()
    
    --print("SaveProfessionCooldowns for " .. fullName)
    --print("Current GetTime(): " .. currentTime)
    --print("Current GetServerTime(): " .. serverTime)

    -- Check for cooldowns based on professions
    for profession, spells in pairs(SpellsToTrack) do
        if characters[fullName].professions and characters[fullName].professions[profession] then
            --print("Checking " .. profession .. " spells")
            for _, spell in ipairs(spells) do
                --print("  Checking spell: " .. spell.name .. " (ID: " .. spell.id .. ")")
                local start, duration = GetSpellCooldown(spell.id)
                --print("  Spell cooldown - start: " .. start .. ", duration: " .. duration)
                
                if start > 0 and duration > 0 then
                    local remainingTime = start + duration - currentTime
                    --print("  Cooldown active! Remaining time: " .. remainingTime)
                    
                    characters[fullName].professionCooldowns[spell.name] = {
                        startTime = start,
                        duration = duration,
                        remainingTime = remainingTime,
                        lastUpdated = serverTime  -- Use server time for consistency
                    }
                    --print("  Saved cooldown for " .. spell.name .. ": " .. CharacterManager_ProfessionCooldowns.FormatTime(remainingTime))
                else
                    -- No active cooldown, mark as ready if it was previously tracked
                    if characters[fullName].professionCooldowns[spell.name] then
                        characters[fullName].professionCooldowns[spell.name] = {
                            startTime = 0,
                            duration = 0,
                            remainingTime = 0,
                            lastUpdated = serverTime,
                            isReady = true
                        }
                        --print("  Cooldown for " .. spell.name .. " is now READY")
                    else
                        --print("  No active cooldown for this spell (not previously tracked)")
                    end
                end
            end
        else
            --print("Character doesn't have profession: " .. profession)
        end
    end

    -- Ensure all existing cooldowns have the lastUpdated field
    if characters[fullName].professionCooldowns then
        for spellName, cooldownData in pairs(characters[fullName].professionCooldowns) do
            if not cooldownData.lastUpdated then
                cooldownData.lastUpdated = serverTime
                print("Updated lastUpdated field for " .. spellName)
            end
        end
    end

    return characters
end

-- Add the OnSpellCast function to handle profession cooldown tracking when spells are cast
function CharacterManager_ProfessionCooldowns.OnSpellCast(characters, fullName, spellID)
    if not characters[fullName] then
        characters[fullName] = { 
            name = UnitName("player"), 
            professions = {},
            professionCooldowns = {}
        }
    elseif not characters[fullName].professionCooldowns then
        characters[fullName].professionCooldowns = {}
    end

    local spellName = GetSpellInfo(spellID)
    if not spellName then return characters end
    
    print("OnSpellCast detected: " .. spellName .. " (ID: " .. spellID .. ")")
    
    -- Find which profession this spell belongs to
    local foundSpell = nil
    local foundProfession = nil
    
    for profession, spells in pairs(CharacterManager_ProfessionCooldowns.SpellsToTrack) do
        for _, spell in ipairs(spells) do
            if spell.id == spellID then
                foundSpell = spell
                foundProfession = profession
                break
            end
        end
        if foundSpell then break end
    end
    
    if foundSpell then
        print("Found tracked profession spell: " .. foundSpell.name .. " in profession: " .. foundProfession)
        
        local start, duration = GetSpellCooldown(spellID)
        local currentTime = GetTime()
        local serverTime = GetServerTime()
        
        if start > 0 and duration > 0 then
            local remainingTime = start + duration - currentTime
            
            characters[fullName].professionCooldowns[foundSpell.name] = {
                startTime = start,
                duration = duration,
                remainingTime = remainingTime,
                lastUpdated = serverTime  -- Use server time for consistency
            }
            
            print("Updated cooldown for " .. foundSpell.name .. ": " .. 
                  CharacterManager_ProfessionCooldowns.FormatTime(remainingTime))
        else
            print("No cooldown detected for " .. foundSpell.name)
        end
    else
        print("Spell ID " .. spellID .. " is not in our tracked profession spells list")
    end
    
    return characters
end

function CharacterManager_ProfessionCooldowns.CreateCooldownBars(parentFrame)
    local cooldownBars = {}
    local barWidth = 380
    local barHeight = 20
    local yOffset = -30

    for i = 1, 10 do  -- Create 10 bars initially for more capacity
        local bar = CreateFrame("StatusBar", nil, parentFrame)
        bar:SetSize(barWidth, barHeight)
        bar:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 10, yOffset)
        bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        bar:SetStatusBarColor(0, 0.7, 0.3)
        bar:Hide()

        bar.bg = bar:CreateTexture(nil, "BACKGROUND")
        bar.bg:SetAllPoints(true)
        bar.bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
        bar.bg:SetVertexColor(0.5, 0.5, 0.5, 0.3)

        bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        bar.text:SetPoint("LEFT", bar, "LEFT", 5, 0)
        bar.text:SetJustifyH("LEFT")

        bar.timeText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        bar.timeText:SetPoint("RIGHT", bar, "RIGHT", -5, 0)
        bar.timeText:SetJustifyH("RIGHT")

        cooldownBars[i] = bar
        yOffset = yOffset - (barHeight + 5)
    end

    
    -- Add debug text to show when the tab is empty
    local debugText = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    debugText:SetPoint("CENTER", parentFrame, "CENTER", 0, 0)
    debugText:SetText("No active profession cooldowns found")
    
    -- Return both the bars and the debug text
    return cooldownBars, debugText
end

function CharacterManager_ProfessionCooldowns.UpdateProfessionCooldowns(cooldownBars, characters, debugText)
    local currentTime = GetServerTime()
    local visibleBars = 0
    
    -- Get current character name
    local currentCharacter = UnitName("player") .. " - " .. GetRealmName()
    print("DEBUG: Current character is", currentCharacter)
    
    -- First, hide all bars
    for i = 1, #cooldownBars do
        cooldownBars[i]:Hide()
    end
    
    -- Check if current character has profession cooldowns
    if not characters[currentCharacter] or not characters[currentCharacter].professionCooldowns then
        print("DEBUG: No profession cooldowns for current character")
        if debugText then
            debugText:SetText("No profession cooldowns for this character")
            debugText:Show()
        end
        return 0
    end

    -- Get the character's professions
    local characterProfessions = {}
    if characters[currentCharacter].professions then
        for profession, _ in pairs(characters[currentCharacter].professions) do
            characterProfessions[profession] = true
        end
    end

    local trackedSpellIDs = CharacterManager_ProfessionCooldowns.GetTrackedSpellIDs()
    local apiCooldowns = {}
    
    -- Map spell IDs to their professions for checking later
    local spellToProfession = {}
    for profession, spells in pairs(CharacterManager_ProfessionCooldowns.SpellsToTrack) do
        for _, spell in ipairs(spells) do
            spellToProfession[spell.id] = profession
        end
    end
    
    for _, spellID in ipairs(trackedSpellIDs) do
        local spellName = GetSpellInfo(spellID)
        local profession = spellToProfession[spellID]
        
        -- Only check cooldowns for professions the character actually has
        if spellName and profession and characterProfessions[profession] then
            local start, duration = GetSpellCooldown(spellID)
            
            if start > 0 and duration > 0 then
                local remaining = (start + duration) - GetTime()
                
                -- Store API cooldown data for comparison
                apiCooldowns[spellName] = {
                    startTime = start,
                    duration = duration,
                    remainingTime = remaining,
                    lastUpdated = currentTime
                }
            else
                -- If API shows no cooldown, mark it for removal from stored data
                apiCooldowns[spellName] = nil
            end
        end
    end    
          -- Update stored cooldowns based on API data
          if characters[currentCharacter] then
              -- Instead of removing cooldowns that are ready, mark them as ready
              for spellName, cooldownData in pairs(characters[currentCharacter].professionCooldowns) do
                  if apiCooldowns[spellName] == nil then
                      print("Marking cooldown for " .. spellName .. " as ready")
                      characters[currentCharacter].professionCooldowns[spellName] = {
                          remainingTime = 0,  -- Set to 0 to indicate ready
                          duration = cooldownData.duration or 86400,
                          lastUpdated = currentTime,
                          isReady = true  -- Add a flag to indicate it's ready
                      }
                  end
              end
              
              -- Add or update cooldowns from API
              for spellName, cooldownData in pairs(apiCooldowns) do
                  print("Updating cooldown for " .. spellName .. " from API data: " .. 
                        CharacterManager_ProfessionCooldowns.FormatTime(cooldownData.remainingTime))
                  cooldownData.isReady = false  -- Mark as not ready since it has an active cooldown
                  characters[currentCharacter].professionCooldowns[spellName] = cooldownData
              end
          end

    -- Check if we have any characters with cooldowns
    local hasCooldowns = false
    
    -- Track shared cooldowns (like Transmute)
    local sharedCooldowns = {}
    
    -- Then show and update only the ones with active cooldowns
    if characters then
        -- First pass: collect all cooldowns and handle shared cooldowns
        for fullName, charData in pairs(characters) do
            if charData.professionCooldowns then
                -- Track the longest transmute cooldown for each character
                local longestTransmuteRemaining = -1  -- Changed from 0 to -1 to track available transmutes
                local transmuteName = ""
                local transmuteDuration = 0
                
                for spellName, cooldownData in pairs(charData.professionCooldowns) do
                    -- Check if lastUpdated exists, if not use a default value
                    local lastUpdated = cooldownData.lastUpdated or currentTime
                    
                    -- Calculate remaining time for all cooldowns
                    local elapsedTime = currentTime - lastUpdated
                    local remainingTime = (cooldownData.remainingTime or 0) - elapsedTime
                    
                    -- If the calculated remaining time is now <= 0, mark it as ready
                    if remainingTime <= 0 then
                        remainingTime = 0
                        cooldownData.isReady = true  -- Explicitly mark as ready
                        -- Debug output to verify cooldowns are being marked as ready
                        print("Found READY cooldown: " .. fullName .. " - " .. spellName)
                    end
                    
                    -- Handle transmute spells specially
                    if string.match(spellName, "Transmute:") then
                        -- If this is the first transmute we've seen or it has a longer remaining time
                        if longestTransmuteRemaining == -1 or remainingTime > longestTransmuteRemaining then
                            longestTransmuteRemaining = remainingTime
                            transmuteName = spellName
                            transmuteDuration = cooldownData.duration or 86400
                        end
                    else
                        -- For non-transmute spells, process normally (including available ones)
                        local cooldownKey = fullName .. "_" .. spellName
                        sharedCooldowns[cooldownKey] = {
                            fullName = fullName,
                            spellName = spellName,
                            remainingTime = remainingTime,
                            duration = cooldownData.duration or 86400
                        }
                    end
                end
                
                -- Add the transmute cooldown if it exists
                if longestTransmuteRemaining ~= -1 then
                    -- Determine if it's Arcanite (48h) or other transmute (24h)
                    local displayName = "Transmute: Other"
                    if transmuteDuration >= 172800 or transmuteName == "Transmute: Arcanite" then
                        displayName = "Transmute: Arcanite"
                    end
                    
                    -- Debug output for transmute cooldowns
                    if longestTransmuteRemaining <= 0 then
                        print("Found READY transmute: " .. fullName .. " - " .. displayName)
                    end
                    
                    local cooldownKey = fullName .. "_Transmute"
                    sharedCooldowns[cooldownKey] = {
                        fullName = fullName,
                        spellName = displayName,
                        remainingTime = longestTransmuteRemaining,
                        duration = transmuteDuration
                    }
                end
            end
        end
        -- Second pass: display the cooldowns
        -- First sort the cooldowns - available ones first, then by remaining time
        local sortedCooldowns = {}
        for key, info in pairs(sharedCooldowns) do
            table.insert(sortedCooldowns, info)
        end
        
        -- Sort function: available cooldowns first, then by remaining time
        table.sort(sortedCooldowns, function(a, b)
            -- If one is available and the other isn't, available comes first
            if a.remainingTime <= 0 and b.remainingTime > 0 then
                return true
            elseif a.remainingTime > 0 and b.remainingTime <= 0 then
                return false
            end
            
            -- If both are available, sort alphabetically by spell name
            if a.remainingTime <= 0 and b.remainingTime <= 0 then
                return a.spellName < b.spellName
            end
            
            -- If both are on cooldown, sort by remaining time (shorter first)
            return a.remainingTime < b.remainingTime
        end)

        -- Display the sorted cooldowns
        for _, cooldownInfo in ipairs(sortedCooldowns) do
            visibleBars = visibleBars + 1
            hasCooldowns = true
            
            if visibleBars <= #cooldownBars then
                local bar = cooldownBars[visibleBars]
                bar:Show()
                
                -- Format the text: Character - Spell Name
                local charName = string.match(cooldownInfo.fullName, "(.+) %- ") or cooldownInfo.fullName
                bar.text:SetText(charName .. " - " .. cooldownInfo.spellName)
                
                -- Check if cooldown is available
                if cooldownInfo.remainingTime <= 0 then
                    -- Cooldown is available
                    print("Setting READY bar for " .. cooldownInfo.fullName .. " - " .. cooldownInfo.spellName)
                    bar.timeText:SetText("READY")
                    bar:SetMinMaxValues(0, 1)
                    bar:SetValue(1) -- Full bar
                    bar:SetStatusBarColor(0, 0.7, 0.3) -- Green for ready
                else
                    -- Cooldown is still active
                    local timeString = CharacterManager_ProfessionCooldowns.FormatTime(cooldownInfo.remainingTime)
                    bar.timeText:SetText(timeString)
                    bar:SetMinMaxValues(0, cooldownInfo.duration)
                    bar:SetValue(cooldownInfo.duration - cooldownInfo.remainingTime)
                    
                    -- Color based on remaining time (red -> yellow -> green)
                    local percentRemaining = cooldownInfo.remainingTime / cooldownInfo.duration
                    if percentRemaining > 0.5 then
                        -- Red to yellow gradient (50-100% remaining)
                        local factor = (percentRemaining - 0.5) * 2 -- 0 to 1
                        bar:SetStatusBarColor(1.0, 1.0 - factor, 0)
                    else
                        -- Yellow to green gradient (0-50% remaining)
                        local factor = percentRemaining * 2 -- 0 to 1
                        bar:SetStatusBarColor(factor, 0.7, 0)
                    end
                end
            end
        end
        
        -- Show debug text if no cooldowns are found
        if not hasCooldowns then
            if debugText then
                debugText:Show()
            end
        else
            if debugText then
                debugText:Hide()
            end
        end
        
        -- Hide unused bars
        for i = visibleBars + 1, #cooldownBars do
            cooldownBars[i]:Hide()
        end
    end
    return visibleBars
end


-- Export the functions and data
CharacterManager_ProfessionCooldowns.GetTrackedSpellIDs = GetTrackedSpellIDs
CharacterManager_ProfessionCooldowns.CheckProfessionsAndSpells = CheckProfessionsAndSpells
CharacterManager_ProfessionCooldowns.SaveProfessionCooldowns = SaveProfessionCooldowns
CharacterManager_ProfessionCooldowns.SpellsToTrack = SpellsToTrack
CharacterManager_ProfessionCooldowns.professionCooldowns = professionCooldowns