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
    
    print("SaveProfessionCooldowns for " .. fullName)
    print("Current GetTime(): " .. currentTime)
    print("Current GetServerTime(): " .. serverTime)

    -- Check for cooldowns based on professions
    for profession, spells in pairs(SpellsToTrack) do
        if characters[fullName].professions and characters[fullName].professions[profession] then
            print("Checking " .. profession .. " spells")
            for _, spell in ipairs(spells) do
                print("  Checking spell: " .. spell.name .. " (ID: " .. spell.id .. ")")
                local start, duration = GetSpellCooldown(spell.id)
                print("  Spell cooldown - start: " .. start .. ", duration: " .. duration)
                
                if start > 0 and duration > 0 then
                    local remainingTime = start + duration - currentTime
                    print("  Cooldown active! Remaining time: " .. remainingTime)
                    
                    characters[fullName].professionCooldowns[spell.name] = {
                        startTime = start,
                        duration = duration,
                        remainingTime = remainingTime,
                        lastUpdated = serverTime  -- Use server time for consistency
                    }
                    print("  Saved cooldown for " .. spell.name .. ": " .. CharacterManager_ProfessionCooldowns.FormatTime(remainingTime))
                else
                    print("  No active cooldown for this spell")
                end
            end
        else
            print("Character doesn't have profession: " .. profession)
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

-- Update the UpdateProfessionCooldowns function to handle shared cooldowns
function CharacterManager_ProfessionCooldowns.UpdateProfessionCooldowns(cooldownBars, characters, debugText)
    local currentTime = GetServerTime()
    local visibleBars = 0
    
    -- Debug output
    print("UpdateProfessionCooldowns called with " .. #cooldownBars .. " bars")
    
    -- First, hide all bars
    for i = 1, #cooldownBars do
        cooldownBars[i]:Hide()
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
                    
                    -- Calculate remaining time
                    local elapsedTime = currentTime - lastUpdated
                    local remainingTime = (cooldownData.remainingTime or 0) - elapsedTime
                    
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
                    bar.timeText:SetText("READY")
                    bar:SetMinMaxValues(0, 1)
                    bar:SetValue(1) -- Full bar
                    bar:SetStatusBarColor(0, 1, 0) -- Vibrant green for available cooldowns
                else
                    -- Cooldown is active
                    -- Format the time
                    bar.timeText:SetText(CharacterManager_ProfessionCooldowns.FormatTime(cooldownInfo.remainingTime))
                    
                    -- Set the bar value - REVERSED LOGIC: 
                    -- We want the bar to be empty at start of cooldown and full when cooldown is complete
                    local elapsedCooldown = cooldownInfo.duration - cooldownInfo.remainingTime
                    bar:SetMinMaxValues(0, cooldownInfo.duration)
                    bar:SetValue(elapsedCooldown)
                    
                    -- Color the bar based on progress - darker green for active cooldowns
                    local r, g, b = 0, 0.5, 0.2 -- Darker green (was 0, 0.7, 0.3)
                    local progress = elapsedCooldown / cooldownInfo.duration
                    if progress < 0.25 then -- Less than 25% complete
                        r, g, b = 0.7, 0, 0 -- Red
                    elseif progress < 0.5 then -- Less than 50% complete
                        r, g, b = 0.7, 0.7, 0 -- Yellow
                    end
                    bar:SetStatusBarColor(r, g, b)
                end
            end
        end
    end
    
    -- Show or hide the debug text based on whether we found any cooldowns
    if debugText then
        if hasCooldowns then
            debugText:Hide()
        else
            debugText:Show()
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