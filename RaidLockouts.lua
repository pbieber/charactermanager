CharacterManager_RaidLockouts = {}

local raids = CharacterManager_Raids
local raidDisplayNames = CharacterManager_RaidDisplayNames
local raidActualNames = CharacterManager_RaidActualNames


function CharacterManager_RaidLockouts.GetRaidsForPhase(phase)
    local phaseRaids = {}
    
    -- Phase 1-2: MC and Onyxia
    if phase >= 1 then
        table.insert(phaseRaids, "mc")
        table.insert(phaseRaids, "ony")
    end
    
    -- Phase 3: Add BWL
    if phase >= 3 then
        table.insert(phaseRaids, "bwl")
    end
    
    -- Phase 4: Add ZG
    if phase >= 4 then
        table.insert(phaseRaids, "zg")
    end
    
    -- Phase 5: Add AQ20 and AQ40
    if phase >= 5 then
        table.insert(phaseRaids, "aq20")
        table.insert(phaseRaids, "aq40")
    end
    
    -- Phase 6: Add Naxx
    if phase >= 6 then
        table.insert(phaseRaids, "naxx")
    end
    
    return phaseRaids
end

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

-- Format time for display
function CharacterManager_RaidLockouts.FormatTime(seconds)
    if seconds <= 0 then
        return "0d 0h"
    end
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    return string.format("%dd %dh", days, hours)
end
-- Add this function to RaidLockouts.lua

function CharacterManager_RaidLockouts.RemoveAllRaidFrames()
    if _G.raidFrames then
        for _, raidData in ipairs(_G.raidFrames) do
            if raidData.frame then
                raidData.frame:Hide()
                raidData.frame:SetParent(nil)
            end
            if raidData.characters then
                raidData.characters:Hide()
                raidData.characters:SetParent(nil)
            end
        end
        table.wipe(_G.raidFrames)
    end
end

function CharacterManager_RaidLockouts.CreateRaidFrames(tabFrames, raids, raidDisplayNames, currentPhase)
    local raidFrames = {}
    currentPhase = currentPhase or 6
    print("CharacterManager: Creating raid frames for Phase " .. currentPhase)
     -- Get raids for the current phase
     local phaseRaids = CharacterManager_RaidLockouts.GetRaidsForPhase(currentPhase or 6)

     if not tabFrames or not tabFrames[3] then
        print("CharacterManager Error: tabFrames[3] is nil. Cannot create raid frames.")
        return {}
    end
    
         -- Clear any existing frames in the tab
    for _, child in pairs({tabFrames[3]:GetChildren()}) do
        if child:GetName() ~= tabFrames[3]:GetName() then
            child:Hide()
            child:SetParent(nil)
        end
    end
    
    
    for i, raidName in ipairs(phaseRaids) do
        -- Create a button for the entire raid header instead of a frame with separate button
        local raidFrame = CreateFrame("Button", nil, tabFrames[3], "UIPanelButtonTemplate")
        raidFrame:SetSize(380, 30)
        
        -- Clear the default button text
        raidFrame:SetText("")
        
        -- Add raid icon
        local raidIcon = raidFrame:CreateTexture(nil, "ARTWORK")
        raidIcon:SetSize(20, 20)
        raidIcon:SetPoint("LEFT", 110, 0)
        
        -- Set appropriate icon based on raid name
        local iconPath
        if raidName == "mc" then
            iconPath = "Interface\\Icons\\inv_hammer_unique_sulfuras"
        elseif raidName == "bwl" then
            iconPath = "Interface\\Icons\\inv_misc_head_dragon_black"
        elseif raidName == "ony" then
            iconPath = "Interface\\Icons\\inv_misc_head_dragon_01"
        elseif raidName == "zg" then
            iconPath = "Interface\\Icons\\inv_misc_idol_03"
        elseif raidName == "aq20" then
            iconPath = "Interface\\Icons\\inv_misc_ahnqirajtrinket_01"
        elseif raidName == "aq40" then
            iconPath = "Interface\\Icons\\inv_misc_qirajicrystal_05"
        elseif raidName == "naxx" then
            iconPath = "Interface\\Icons\\inv_trinket_naxxramas04"
        else
            iconPath = "Interface\\Icons\\inv_misc_questionmark"
        end
        raidIcon:SetTexture(iconPath)
        
        -- Create raid title text (centered)
        local raidTitle = raidFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        raidTitle:SetPoint("CENTER", 0, 0)
        raidTitle:SetText(raidDisplayNames[raidName] or raidName)
        
        -- Add status overview text
        local statusOverview = raidFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        statusOverview:SetPoint("RIGHT", -30, 0)
        statusOverview:SetText("")  -- Will be updated when populated
        raidFrame.statusOverview = statusOverview

        -- Add expand/collapse indicator
        local expandIndicator = raidFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        expandIndicator:SetPoint("RIGHT", -10, 0)
        expandIndicator:SetText("+")
        raidFrame.expandIndicator = expandIndicator

        -- Character Frame (Initially Hidden)
        local characterFrame = CreateFrame("Frame", nil, tabFrames[3])
        characterFrame:SetSize(380, 5)  -- Start with minimal height
        characterFrame:SetPoint("TOPLEFT", raidFrame, "BOTTOMLEFT", 0, -2)  -- Reduced gap
        characterFrame:Hide()

        local function PopulateCharacterFrame(raidName)
            characterFrame:SetHeight(5)
            local yOffset = -2
        
            -- Clear existing font strings
            for _, child in ipairs({characterFrame:GetChildren()}) do
                if child:IsObjectType("FontString") then
                    child:Hide()
                    child:SetText("")
                end
            end
        
            -- Add headers
            local headerName = characterFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            local headerStatus = characterFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            local headerTime = characterFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            local headerProgress = characterFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        
            headerName:SetPoint("TOPLEFT", 10, yOffset)
            headerStatus:SetPoint("TOPLEFT", 120, yOffset)
            headerTime:SetPoint("TOPLEFT", 220, yOffset)
            headerProgress:SetPoint("TOPLEFT", 320, yOffset)
        
            headerName:SetText("Name")
            headerStatus:SetText("ID Status")
            headerTime:SetText("Reset")
            headerProgress:SetText("Progress")
        
            yOffset = yOffset - 20  -- Add extra space after headers
            characterFrame:SetHeight(characterFrame:GetHeight() + 20)
        
            -- Collect and sort character data
            local sortedCharacters = {}
            local lockedCount = 0
            local totalCount = 0

            if MyAddonDB then
                for fullName, char in pairs(MyAddonDB) do
                    if char.name and char.raidStatus and char.raidStatus[raidName] and char.level and char.level >= 60 then
                        totalCount = totalCount + 1
                        
                        -- Count locked characters
                        local status = char.raidStatus[raidName].status or "Unknown"
                        if status == "Locked" or status == "Done" then
                            lockedCount = lockedCount + 1
                        end
                        
                        table.insert(sortedCharacters, {
                            name = char.name,
                            class = char.class,
                            raidInfo = char.raidStatus[raidName],
                            fullName = fullName
                        })
                    end
                end
            end
            -- Update the status overview in the raid header
            raidFrame.statusOverview:SetText(lockedCount .. "/" .. totalCount)
            
            -- Sort characters: Open status first, then by name
            table.sort(sortedCharacters, function(a, b)
                local statusA = a.raidInfo.status or "Unknown"
                local statusB = b.raidInfo.status or "Unknown"
                
                -- If one is Open and the other isn't, Open comes first
                if statusA == "Open" and statusB ~= "Open" then
                    return true
                elseif statusA ~= "Open" and statusB == "Open" then
                    return false
                end
                
                -- Otherwise sort by name
                return a.name < b.name
            end)
            
            -- Add character data
            for _, charData in ipairs(sortedCharacters) do
                local nameText = characterFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                local statusText = characterFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                local timeText = characterFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                local progressText = characterFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                
                nameText:SetPoint("TOPLEFT", 10, yOffset)
                statusText:SetPoint("TOPLEFT", 120, yOffset)
                timeText:SetPoint("TOPLEFT", 220, yOffset)
                progressText:SetPoint("TOPLEFT", 320, yOffset)
                
                -- Set text with class color
                local classColor = RAID_CLASS_COLORS[charData.class] or {r=1, g=1, b=1}
                nameText:SetText(charData.name)
                nameText:SetTextColor(classColor.r, classColor.g, classColor.b)
                
                -- Set status text
                local status = charData.raidInfo.status or "Unknown"
                statusText:SetText(status)
                
                -- Set color based on status - FIXED COLOR CODING
                if status == "Locked" or status == "Done" then
                    statusText:SetTextColor(0, 1, 0)  -- Green for locked(done)
                elseif status == "Open" then
                    statusText:SetTextColor(1, 0, 0) -- Red open/available
                else
                    statusText:SetTextColor(1, 1, 0)  -- Yellow for unknown/other
                end
                
                -- Set reset time
                local resetTime = charData.raidInfo.reset or 0
                if resetTime > 0 then
                    timeText:SetText(CharacterManager_RaidLockouts.FormatTime(resetTime))
                else
                    timeText:SetText("N/A")
                end
                
                -- Set progress
                local progress = charData.raidInfo.progress or 0
                local total = charData.raidInfo.total or 0
                if total > 0 then
                    progressText:SetText(progress .. "/" .. total)
                else
                    progressText:SetText("N/A")
                end
                
                yOffset = yOffset - 16
                characterFrame:SetHeight(characterFrame:GetHeight() + 16)
            end
            
            -- If no characters found, show a message
            if #sortedCharacters == 0 then
                local noDataText = characterFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                noDataText:SetPoint("TOPLEFT", 10, yOffset)
                noDataText:SetText("No characters with raid data found.")
                characterFrame:SetHeight(characterFrame:GetHeight() + 16)
            end
            
            return lockedCount, totalCount
        end
        
        -- Function to update just the status overview without showing the character frame
        local function UpdateStatusOverview(raidName)
            local lockedCount = 0
            local totalCount = 0
            
            if MyAddonDB then
                for fullName, char in pairs(MyAddonDB) do
                    if char.name and char.raidStatus and char.raidStatus[raidName] and char.level and char.level >= 60 then
                        totalCount = totalCount + 1
                        
                        -- Count locked characters
                        local status = char.raidStatus[raidName].status or "Unknown"
                        if status == "Locked" or status == "Done" then
                            lockedCount = lockedCount + 1
                        end
                    end
                end
            end
            
            -- Update the status overview in the raid header
            raidFrame.statusOverview:SetText(lockedCount .. "/" .. totalCount)
        end
        
        -- Store the tabFrames reference in the raidData for later use
        local raidData = {
            frame = raidFrame,
            characters = characterFrame,
            raidName = raidName,
            populate = PopulateCharacterFrame,
            updateStatus = UpdateStatusOverview,
            tabFrames = tabFrames  -- Store tabFrames reference
        }

        -- Toggle character frame visibility on button click
        raidFrame:SetScript("OnClick", function()
            if characterFrame:IsShown() then
                characterFrame:Hide()
                expandIndicator:SetText("+")
            else
                characterFrame:Show()
                expandIndicator:SetText("-")
                PopulateCharacterFrame(raidName)
            end
            CharacterManager_RaidLockouts.UpdateRaidFramesPosition(raidFrames, tabFrames)
        end)
        
        -- Initialize the status overview immediately
        UpdateStatusOverview(raidName)
        
        -- Store raid data for later use
        table.insert(raidFrames, raidData)
    end
    
    return raidFrames
end

-- Add this function to update all raid status overviews
function CharacterManager_RaidLockouts.UpdateAllRaidStatusOverviews(raidFrames)
    if not raidFrames or not MyAddonDB then return end
    
    for _, raidData in ipairs(raidFrames) do
        local raidName = raidData.raidName
        local lockedCount = 0
        local totalCount = 0
        
        for fullName, char in pairs(MyAddonDB) do
            if char.name and char.raidStatus and char.raidStatus[raidName] and char.level and char.level >= 60 then
                totalCount = totalCount + 1
                
                -- Count locked characters
                local status = char.raidStatus[raidName].status or "Unknown"
                if status == "Locked" or status == "Done" then
                    lockedCount = lockedCount + 1
                end
            end
        end
        
        -- Update the status overview in the raid header
        raidData.frame.statusOverview:SetText(lockedCount .. "/" .. totalCount)
    end
end

-- Update position of raid frames in the UI
function CharacterManager_RaidLockouts.UpdateRaidFramesPosition(raidFrames, tabFrames)
    if not raidFrames or #raidFrames == 0 then return end
    
    local yOffset = -20  -- Start closer to the top
    
    for i, raidData in ipairs(raidFrames) do
        if raidData and raidData.frame and raidData.frame:IsShown() then
            raidData.frame:ClearAllPoints()
            raidData.frame:SetPoint("TOPLEFT", tabFrames[3], "TOPLEFT", 10, yOffset)
            yOffset = yOffset - raidData.frame:GetHeight()
            
            if raidData.characters and raidData.characters:IsShown() then
                yOffset = yOffset - raidData.characters:GetHeight() - 3 -- Reduced gap between character frame and next raid
            else
                yOffset = yOffset - 3  -- Small gap when character frame is not shown
            end
        end
    end
end

function CharacterManager_RaidLockouts.RecreateRaidFrames(tabFrames, MyAddonSettings, isRaidTabSelected)
    -- Get current phase from settings
    local currentPhase = MyAddonSettings and MyAddonSettings.currentPhase or 6
    print("CharacterManager: Recreating raid frames for Phase " .. currentPhase)
    
    -- Remove all existing raid frames
    CharacterManager_RaidLockouts.RemoveAllRaidFrames()

    -- Clear all children of the raid tab frame
    local raidTabFrame = tabFrames[3]
    for _, child in pairs({raidTabFrame:GetChildren()}) do
        if child ~= raidTabFrame then
            child:Hide()
            child:SetParent(nil)
        end
    end

    -- Create new raid frames based on current phase
    local newRaidFrames = CharacterManager_RaidLockouts.CreateRaidFrames(tabFrames, raids, raidDisplayNames, currentPhase)
    
    -- Ensure all new frames are properly parented and positioned
    for _, raidData in ipairs(newRaidFrames) do
        if raidData.frame then
            raidData.frame:SetParent(raidTabFrame)
            raidData.frame:SetShown(isRaidTabSelected) -- Only show if raid tab is selected
        end
        if raidData.characters then
            raidData.characters:SetParent(raidTabFrame)
            raidData.characters:Hide() -- Always hide character frames initially
        end
    end

    if isRaidTabSelected then
        CharacterManager_RaidLockouts.UpdateRaidFramesPosition(newRaidFrames, tabFrames)
        CharacterManager_RaidLockouts.UpdateAllRaidStatusOverviews(newRaidFrames)
    end
    
    -- Update the global reference
    _G.raidFrames = newRaidFrames
    
    -- Force a redraw of the raid tab if it's selected
    if isRaidTabSelected then
        raidTabFrame:Hide()
        raidTabFrame:Show()
    end
    
    return newRaidFrames
end