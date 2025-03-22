-- ProfessionCooldowns.lua
CharacterManager_ProfessionCooldowns = {}
-- Handles profession cooldown tracking functionality

-- Reference the data from Constants.lua
local professionCooldowns = CharacterManager_ProfessionCooldownsData
local SpellsToTrack = CharacterManager_SpellsToTrack
local PROFESSIONS_TO_TRACK = CharacterManager_PROFESSIONS_TO_TRACK 

-- Function to get tracked spell IDs
local function GetTrackedSpellIDs()
    local spellIDs = {}
    for _, spells in pairs(SpellsToTrack) do
        for _, spell in ipairs(spells) do
            table.insert(spellIDs, spell.id)
        end
    end
    return spellIDs
end

-- Helper function to initialize character data
local function InitializeCharacterData(characters, fullName)
    if not characters[fullName] then
        characters[fullName] = {
            name = UnitName("player"),
            professions = {},
            professionCooldowns = {}
        }
    elseif not characters[fullName].professions then
        characters[fullName].professions = {}
    end
    if not characters[fullName].professionCooldowns then
        characters[fullName].professionCooldowns = {}
    end
end

-- Helper function to check and update professions
local function UpdateProfessions(characters, fullName)
    for i = 1, GetNumSkillLines() do
        local skillName, isHeader, _, skillRank, _, _, skillMaxRank = GetSkillLineInfo(i)
        if not isHeader and tContains(PROFESSIONS_TO_TRACK, skillName) then
            characters[fullName].professions[skillName] = {rank = skillRank, maxRank = skillMaxRank}
        end
    end
end

-- Helper function to check spell cooldowns
local function CheckSpellCooldowns(characters, fullName)
    local serverTimeResetDetected = false
    local currentTime = GetTime()
    local serverTime = GetServerTime()

    for profession, spells in pairs(CharacterManager_ProfessionCooldowns.SpellsToTrack) do
        if characters[fullName].professions[profession] then
            for _, spell in ipairs(spells) do
                local start, duration = GetSpellCooldown(spell.id)
                if start > 0 and duration > 0 then
                    local remainingTime = start + duration - currentTime
                    
                    -- Check if start time is in the future (indicating a server time reset)
                    if start > currentTime then
                        serverTimeResetDetected = true
                        -- Adjust the start time to be current time
                        remainingTime = duration - currentTime
                    end
                    
                    --print(string.format("Spell: %s, currentTime: %.2f, start: %.2f, duration: %.2f, remainingTime: %.2f", spell.name, currentTime, start, duration, remainingTime))
                    
                    characters[fullName].professionCooldowns[spell.name] = {
                        startTime = start,
                        duration = duration,
                        remainingTime = remainingTime,
                        lastUpdated = serverTime,
                        serverTimeResetDetected = serverTimeResetDetected
                    }
                else
                    -- If the spell is not on cooldown, we can remove it from the cooldowns or mark it as ready
                    if characters[fullName].professionCooldowns[spell.name] then
                        characters[fullName].professionCooldowns[spell.name] = {
                            startTime = 0,
                            duration = 0,
                            remainingTime = 0,
                            lastUpdated = serverTime,
                            isReady = true
                        }
                    end
                end
            end
        end
    end
    
    return serverTimeResetDetected
end

-- Format time function
function CharacterManager_ProfessionCooldowns.FormatTime(seconds)
    if seconds <= 0 then
        return "0d 0h"
    end
    
    if seconds < 43200 then -- 12 hours
        local hours = math.floor(seconds / 3600)
        local minutes = math.floor((seconds % 3600) / 60)
        return string.format("%02dh%02dm", hours, minutes)
    else
        local days = math.floor(seconds / 86400)
        local hours = math.floor((seconds % 86400) / 3600)
        return string.format("%dd %dh", days, hours)
    end
end

-- This function remains for comprehensive updates
function CharacterManager_ProfessionCooldowns.CheckProfessionsAndSpells(characters, fullName)
    InitializeCharacterData(characters, fullName)
    UpdateProfessions(characters, fullName)
    local serverTimeResetDetected = CheckSpellCooldowns(characters, fullName)
    
    if serverTimeResetDetected then
        print("Warning: Server time reset detected. Cooldowns may be inaccurate.")
    end
    
    return characters, serverTimeResetDetected
end

-- This function can be used for frequent updates
function CharacterManager_ProfessionCooldowns.UpdateCooldowns(characters, fullName)
    local serverTimeResetDetected = CheckSpellCooldowns(characters, fullName)
    return characters, serverTimeResetDetected
end

-- Function to handle profession cooldown tracking when spells are cast
function CharacterManager_ProfessionCooldowns.OnSpellCast(characters, fullName, spellID)
    if not characters then
        characters = {}
    end
    
    if not characters[fullName] or not characters[fullName].professionCooldowns then
        return characters
    end

    local spellName = GetSpellInfo(spellID)
    if not spellName then return characters end
    
    -- Check if the cast spell is one we're tracking
    local isTrackedSpell = false
    for _, spells in pairs(CharacterManager_ProfessionCooldowns.SpellsToTrack) do
        for _, spell in ipairs(spells) do
            if spell.id == spellID then
                isTrackedSpell = true
                break
            end
        end
        if isTrackedSpell then break end
    end
    
    -- If it's a tracked spell, update cooldowns
    if isTrackedSpell then
        characters, serverTimeResetDetected = CharacterManager_ProfessionCooldowns.UpdateCooldowns(characters, fullName)
        
        if serverTimeResetDetected then
            print("Warning: Server time reset detected during spell cast. Cooldowns may be inaccurate.")
        end
    end
    
    return characters
end

function CharacterManager_ProfessionCooldowns.CreateCooldownBars(parentFrame)
    local cooldownBars = {}
    local barWidth, barHeight, yOffset = 380, 20, -30

    for i = 1, 10 do
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

    local debugText = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    debugText:SetPoint("CENTER", parentFrame, "CENTER", 0, 0)
    debugText:SetText("No active profession cooldowns found")
    
    return cooldownBars, debugText
end

function CharacterManager_ProfessionCooldowns.UpdateProfessionCooldowns(cooldownBars, characters, debugText)
    local currentTime = GetServerTime()
    local visibleBars = 0
    local currentCharacter = UnitName("player") .. " - " .. GetRealmName()
    local serverTimeResetWarning = false

    if not cooldownBars or #cooldownBars == 0 then
        if debugText then
            debugText:SetText("No cooldown bars available")
            debugText:Show()
        end
        return 0
    end

    for i = 1, #cooldownBars do
        cooldownBars[i]:Hide()
    end

    if not characters then
        characters = {}
    end

    if not characters[currentCharacter] or not characters[currentCharacter].professionCooldowns then
        if debugText then
            debugText:SetText("No profession cooldowns for this character")
            debugText:Show()
        end
        return 0
    end

    -- Create a warning text frame if it doesn't exist
    if not cooldownBars.warningText then
        local parentFrame = cooldownBars[1]:GetParent()
        cooldownBars.warningText = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        cooldownBars.warningText:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 10, -25)
        cooldownBars.warningText:SetSize(380, 20)
        cooldownBars.warningText:SetTextColor(1, 0, 0) -- Red color
        cooldownBars.warningText:SetFont(cooldownBars.warningText:GetFont(), 10, "OUTLINE") 
    end
    cooldownBars.warningText:Hide()

    characters, serverTimeResetDetected = CharacterManager_ProfessionCooldowns.UpdateCooldowns(characters, currentCharacter)

    local hasCooldowns = false
    local sharedCooldowns = {}


    if characters then
        for fullName, charData in pairs(characters) do
            if charData.professionCooldowns then
                local longestTransmuteRemaining = -1
                local transmuteName = ""
                local transmuteDuration = 0
                local transmuteStartTime = 0
    
                for spellName, cooldownData in pairs(charData.professionCooldowns) do
                    local lastUpdated = cooldownData.lastUpdated or currentTime
    
                    -- Calculate remaining time for all cooldowns
                    local elapsedTime = currentTime - lastUpdated
                    local remainingTime = (cooldownData.remainingTime or 0) - elapsedTime
    
                    if remainingTime <= 0 then
                        remainingTime = 0
                        cooldownData.isReady = true
                    end
    
                    if string.match(spellName, "Transmute:") then
                        if longestTransmuteRemaining == -1 or remainingTime > longestTransmuteRemaining then
                            longestTransmuteRemaining = remainingTime
                            transmuteName = spellName
                            transmuteDuration = cooldownData.duration or 86400
                            transmuteStartTime = cooldownData.startTime or 0
                        end
                    else
                        local cooldownKey = fullName .. "_" .. spellName
                        sharedCooldowns[cooldownKey] = {
                            fullName = fullName,
                            spellName = spellName,
                            remainingTime = remainingTime,
                            duration = cooldownData.duration or 86400,
                            startTime = cooldownData.startTime or 0,
                            isReady = cooldownData.isReady or false 
                        }
                    end
                end
    
                if longestTransmuteRemaining ~= -1 then
                    local displayName = "Transmute: Other"
                    if transmuteDuration >= 172800 or transmuteName == "Transmute: Arcanite" then
                        displayName = "Transmute: Arcanite"
                    end
                
                    local cooldownKey = fullName .. "_Transmute"
                    sharedCooldowns[cooldownKey] = {
                        fullName = fullName,
                        spellName = displayName,
                        remainingTime = longestTransmuteRemaining,
                        duration = transmuteDuration,
                        startTime = transmuteStartTime,
                        isReady = longestTransmuteRemaining <= 0  -- Calculate isReady based on remaining time
                    }
                end
            end
        end

        local sortedCooldowns = {}
        for _, info in pairs(sharedCooldowns) do
            table.insert(sortedCooldowns, info)
        end

        table.sort(sortedCooldowns, function(a, b)
            if a.remainingTime <= 0 and b.remainingTime > 0 then
                return true
            elseif a.remainingTime > 0 and b.remainingTime <= 0 then
                return false
            end

            if a.remainingTime <= 0 and b.remainingTime <= 0 then
                return a.spellName < b.spellName
            end

            return a.remainingTime < b.remainingTime
        end)

        local warningShown = false
        local effectiveVisibleBars = 0

-- First, check if we need to show the warning
if serverTimeResetDetected then
    cooldownBars.warningText:SetText("|cFFFF0000Warning: Server time reset detected. Cooldowns may be inaccurate.|r")
    cooldownBars.warningText:Show()
    warningShown = true
    effectiveVisibleBars = 1
else
    cooldownBars.warningText:Hide()
end

for index, cooldownInfo in ipairs(sortedCooldowns) do
    local barIndex = index + (warningShown and 1 or 0)
    
    if barIndex <= #cooldownBars then
        local bar = cooldownBars[barIndex]
        bar:Show()
        effectiveVisibleBars = effectiveVisibleBars + 1

        local charName = string.match(cooldownInfo.fullName, "(.+) %- ") or cooldownInfo.fullName
        bar.text:SetText(charName .. " - " .. cooldownInfo.spellName)

        if cooldownInfo.startTime and cooldownInfo.startTime > currentTime then
            cooldownInfo.startTime = 0
            cooldownInfo.remainingTime = 0
            cooldownInfo.isReady = true
            serverTimeResetWarning = true
        end
        
        if cooldownInfo.remainingTime <= 0 or cooldownInfo.isReady then
            bar.timeText:SetText("READY")
            bar:SetMinMaxValues(0, 1)
            bar:SetValue(1)
            bar:SetStatusBarColor(0, 0.7, 0.3)
        else
            local timeString = CharacterManager_ProfessionCooldowns.FormatTime(cooldownInfo.remainingTime)
            bar.timeText:SetText(timeString)
            bar:SetMinMaxValues(0, cooldownInfo.duration)
            bar:SetValue(cooldownInfo.duration - cooldownInfo.remainingTime)
        
            local percentRemaining = cooldownInfo.remainingTime / cooldownInfo.duration
            if percentRemaining > 0.5 then
                local factor = (percentRemaining - 0.5) * 2
                bar:SetStatusBarColor(1.0, 1.0 - factor, 0)
            else
                local factor = percentRemaining * 2
                bar:SetStatusBarColor(factor, 0.7, 0)
            end
        end
    end
end

-- Hide unused bars
for i = effectiveVisibleBars + 1, #cooldownBars do
    cooldownBars[i]:Hide()
end

if effectiveVisibleBars == (warningShown and 1 or 0) then
    if debugText then
        debugText:Show()
    end
else
    if debugText then
        debugText:Hide()
    end
end

return effectiveVisibleBars
end
end

-- Export the functions and data
CharacterManager_ProfessionCooldowns.GetTrackedSpellIDs = GetTrackedSpellIDs
CharacterManager_ProfessionCooldowns.SaveProfessionCooldowns = SaveProfessionCooldowns
CharacterManager_ProfessionCooldowns.SpellsToTrack = SpellsToTrack
CharacterManager_ProfessionCooldowns.professionCooldowns = professionCooldowns