-- Settings.lua
-- Handles all settings functionality for Character Manager

CharacterManager_Settings = {}

function CharacterManager_Settings.AdjustCharacterSettingsContainerHeight(container)
    local bottomPoint = 0
    local debugInfo = {}
    
    -- Function to recursively check all child frames
    local function checkFrame(frame, depth, accumulatedY)
        if frame:IsVisible() then
            local point, relativeTo, relativePoint, xOffset, yOffset = frame:GetPoint()
            local height = frame:GetHeight()
            
            -- Calculate absolute Y position
            local absoluteY
            if relativeTo then
                -- If the frame is positioned relative to another frame
                local _, parentY = relativeTo:GetCenter()
                local _, frameY = frame:GetCenter()
                absoluteY = accumulatedY + (parentY - frameY)
            else
                -- If the frame is positioned relative to its parent
                absoluteY = accumulatedY + (yOffset or 0)
            end
            
            local childBottom = math.abs(absoluteY) + height
            bottomPoint = math.max(bottomPoint, childBottom)
            
            -- Check children of this frame
            for _, child in ipairs({frame:GetChildren()}) do
                checkFrame(child, depth + 1, absoluteY)
            end
        end
    end
    
    -- Check all direct children of the container
    for _, child in ipairs({container:GetChildren()}) do
        checkFrame(child, 0, 0)
    end
    
    -- Add padding
    bottomPoint = bottomPoint + 60
    
    -- Set minimum height
    bottomPoint = math.max(bottomPoint, 100)  -- Adjust this value as needed
    container:SetHeight(bottomPoint)
end

function CharacterManager_Settings.CreateSettingsTabContent(tabFrames)
    print("Debug: Entering CreateSettingsTabContent function")
        local settingsFrame = tabFrames[6]  -- Settings is the 6th tab
        if not settingsFrame then 
            print("Debug: settingsFrame is nil, exiting CreateSettingsTabContent")
            return 
        end

    -- Clear existing content
    for _, child in pairs({settingsFrame:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    -- Create a ScrollFrame for the entire settings content
    local scrollFrame = CreateFrame("ScrollFrame", nil, settingsFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 5, -25)
    scrollFrame:SetPoint("BOTTOMRIGHT", settingsFrame, "BOTTOMRIGHT", -25, 5)

    -- Create a content frame to hold all settings
    local contentFrame = CreateFrame("Frame", nil, scrollFrame)
    contentFrame:SetSize(scrollFrame:GetWidth() - 20, 600)  -- Set an initial height, adjust width
    scrollFrame:SetScrollChild(contentFrame)

    -- Adjust the width of the containers to fit within the scrollable area
    local containerWidth = contentFrame:GetWidth() - 10  -- Leave some padding
    -- General Settings Section with background
    local generalSettingsContainer = CreateFrame("Frame", nil, contentFrame, "BackdropTemplate")
    generalSettingsContainer:SetSize(containerWidth, 120)
    generalSettingsContainer:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 10, -10)
    generalSettingsContainer:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })

    -------------------
    -- General Settings Section
    -------------------

        -- General Settings Section Title
        local generalTitle = generalSettingsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        generalTitle:SetPoint("TOPLEFT", 15, -15)
        generalTitle:SetText("General Settings")

        -- Phase dropdown label and dropdown on the same line
        local phaseLabel = generalSettingsContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        phaseLabel:SetPoint("TOPLEFT", generalTitle, "BOTTOMLEFT", 5, -15)
        phaseLabel:SetText("Game Phase:")

        -- Check if the dropdown already exists
        local phaseDropdown = _G["CharacterManagerPhaseDropdown"]
        if not phaseDropdown then
            phaseDropdown = CreateFrame("Frame", "CharacterManagerPhaseDropdown", generalSettingsContainer, "UIDropDownMenuTemplate")
            phaseDropdown:SetPoint("LEFT", phaseLabel, "RIGHT", 10, -5)  -- Adjusted to be on the same line
        else
            -- If it exists, just reparent and reposition it
            phaseDropdown:SetParent(generalSettingsContainer)
            phaseDropdown:ClearAllPoints()
            phaseDropdown:SetPoint("LEFT", phaseLabel, "RIGHT", 10, -5)  -- Adjusted to be on the same line
            phaseDropdown:Show()
        end

    local phases = {"Phase 1", "Phase 2", "Phase 3", "Phase 4", "Phase 5", "Phase 6"}

    -- Ensure WoWCharacterManagerSettings exists
    if not WoWCharacterManagerSettings then
        WoWCharacterManagerSettings = {
            currentPhase = 3  -- Default to Phase 3
        }
    elseif not WoWCharacterManagerSettings.currentPhase then
        WoWCharacterManagerSettings.currentPhase = 3  -- Default to Phase 3
    end

    local currentPhase = WoWCharacterManagerSettings.currentPhase

    UIDropDownMenu_Initialize(phaseDropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        info.func = function(self)
            currentPhase = self.value
            UIDropDownMenu_SetText(phaseDropdown, phases[currentPhase])

            -- Save the setting to the global settings variable
            WoWCharacterManagerSettings.currentPhase = currentPhase

            -- Print debug message
            print("CharacterManager: Phase changed to " .. phases[currentPhase] .. " (Phase ID: " .. currentPhase .. ")")

            -- Update raid frames based on new phase, but don't show them unless on raid tab
            if CharacterManager_RaidLockouts and CharacterManager_RaidLockouts.RecreateRaidFrames then
                print("CharacterManager: Recreating raid frames for new phase...")
                _G.raidFrames = CharacterManager_RaidLockouts.RecreateRaidFrames(tabFrames, WoWCharacterManagerSettings, selectedTab == 3)
            else
                print("CharacterManager: ERROR - Could not recreate raid frames (function not found)")
            end

            -- Update buff display if on the buff tab
            if tabFrames and tabFrames[4] and CharacterManager_BuffTracking and CharacterManager_BuffTracking.UpdateBuffDisplay then
                print("CharacterManager: Updating buff display for new phase...")
                CharacterManager_BuffTracking.UpdateBuffDisplay(tabFrames, MyAddonDB, WoWCharacterManagerSettings)
            end
        end


        for i, phaseName in ipairs(phases) do
            info.text = phaseName
            info.value = i
            info.checked = (currentPhase == i)
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    UIDropDownMenu_SetWidth(phaseDropdown, 100)
    UIDropDownMenu_SetText(phaseDropdown, phases[currentPhase] or "Phase 3")

    -------------------
    -- Debug Section
    -------------------

        local debugSettingsContainer = CreateFrame("Frame", nil, contentFrame, "BackdropTemplate")
        debugSettingsContainer:SetSize(containerWidth, 130)
        debugSettingsContainer:SetPoint("TOPLEFT", generalSettingsContainer, "BOTTOMLEFT", 0, -20)
        debugSettingsContainer:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 16,
            insets = { left = 5, right = 5, top = 5, bottom = 5 }
        })

        -- Debug Tools Section Title
        local debugTitle = debugSettingsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        debugTitle:SetPoint("TOPLEFT", 15, -15)
        debugTitle:SetText("Debug Tools")

        -- Create a button to clear profession cooldowns
        local clearCooldownsButton = CreateFrame("Button", nil, debugSettingsContainer, "UIPanelButtonTemplate")
        clearCooldownsButton:SetSize(200, 24)
        clearCooldownsButton:SetPoint("TOPLEFT", debugTitle, "BOTTOMLEFT", 5, -15)
        clearCooldownsButton:SetText("Clear All Profession Cooldowns")
        clearCooldownsButton:SetScript("OnClick", function()
            local count = 0
            -- Loop through all characters and clear their profession cooldowns
            for fullName, charData in pairs(MyAddonDB) do
                if charData.professionCooldowns then
                    charData.professionCooldowns = {}
                    count = count + 1
                end
            end
            print("Cleared profession cooldowns for " .. count .. " characters.")

            -- Update the cooldown display if the function exists
            if _G.UpdateProfessionCooldowns then
                _G.UpdateProfessionCooldowns()
            end
        end)

        -- Add a tooltip to explain what the button does
        clearCooldownsButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Clear all stored profession cooldowns")
            GameTooltip:AddLine("This will reset all cooldown timers for debugging purposes", 1, 1, 1, true)
            GameTooltip:Show()
        end)
        clearCooldownsButton:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)

        -- Debug Buffs Button
        local debugBuffsButton = CreateFrame("Button", nil, debugSettingsContainer, "UIPanelButtonTemplate")
        debugBuffsButton:SetSize(120, 24)
        debugBuffsButton:SetPoint("TOPLEFT", clearCooldownsButton, "BOTTOMLEFT", 0, -10)
        debugBuffsButton:SetText("Debug Buffs")
        debugBuffsButton:SetScript("OnClick", function()
            -- Debug function to print buff data
            print("--- Buff Debug Info ---")
            print("Current Phase: " .. (WoWCharacterManagerSettings and WoWCharacterManagerSettings.currentPhase or "Not set (using default 3)"))
            for fullName, charData in pairs(MyAddonDB) do
                print("Character: " .. fullName)
                if charData.buffs then
                    print("  Active Buffs:")
                    for buffName, buffData in pairs(charData.buffs) do
                        print("    " .. buffName)
                    end
                else
                    print("  No active buffs")
                end

                if charData.chronoboon then
                    print("  Chronoboon Buffs:")
                    for slot, value in pairs(charData.chronoboon) do
                        print("    Slot " .. slot .. ": " .. tostring(value))
                    end
                else
                    print("  No chronoboon buffs")
                end
            end
        end)

        -- Add a tooltip to explain what the button does
        debugBuffsButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Debug Buff Information")
            GameTooltip:AddLine("Prints detailed information about character buffs to the chat window", 1, 1, 1, true)
            GameTooltip:Show()
        end)
        debugBuffsButton:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)

        -------------------
        -- Character-specific Settings Section
        -------------------

        local characterSettingsContainer = CreateFrame("Frame", nil, contentFrame, "BackdropTemplate")
        characterSettingsContainer:SetSize(containerWidth, 450)  -- Initial height, will be adjusted
        characterSettingsContainer:SetPoint("TOPLEFT", debugSettingsContainer, "BOTTOMLEFT", 0, -20)
        characterSettingsContainer:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 16,
            insets = { left = 5, right = 5, top = 5, bottom = 5 }
        })

        -- Character-specific Settings Section Title
        local characterTitle = characterSettingsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        characterTitle:SetPoint("TOPLEFT", 15, -15)
        characterTitle:SetText("Character-Specific Settings")

        -- Create character dropdown
        local characterDropdown = CreateFrame("Frame", "CharacterManagerSettingsDropdown", characterSettingsContainer, "UIDropDownMenuTemplate")
        characterDropdown:SetPoint("TOPLEFT", characterTitle, "BOTTOMLEFT", -15, -10)
        
        local selectedCharacter = nil
        
        local function UpdateCharacterDropdown()
            print("Debug: Entering UpdateCharacterDropdown function")
            local characters = {}
            for fullName, _ in pairs(MyAddonDB) do
                table.insert(characters, fullName)
            end
            table.sort(characters)
            print("Debug: Found " .. #characters .. " characters")
        
            -- Get the current character's name with realm, ensuring proper formatting
            local currentCharacter = UnitName("player") .. " - " .. GetRealmName()
            print("Debug: Current character is " .. currentCharacter)
        
            -- Only set the initial selected character if it hasn't been set yet
            if not selectedCharacter then
                selectedCharacter = currentCharacter
                print("Debug: Initially selected character set to " .. selectedCharacter)
            else
                print("Debug: Selected character already set to " .. selectedCharacter)
            end
        
            local function OnClick(self)
                selectedCharacter = self.value
                print("Debug: Character selected: " .. selectedCharacter)
                UIDropDownMenu_SetText(characterDropdown, selectedCharacter)
                -- Update character-specific settings display
                CharacterManager_Settings.UpdateCharacterSettings(characterSettingsContainer, selectedCharacter, characterDropdown)
            end
        
            local function Initialize(self, level)
                print("Debug: Initializing dropdown menu")
                local info = UIDropDownMenu_CreateInfo()
                info.func = OnClick
        
                for _, charName in ipairs(characters) do
                    info.text = charName
                    info.value = charName
                    info.checked = (charName == selectedCharacter)
                    UIDropDownMenu_AddButton(info, level)
                end
            end
        
            UIDropDownMenu_Initialize(characterDropdown, Initialize)
        
            -- Set the width to accommodate longer names
            UIDropDownMenu_SetWidth(characterDropdown, 200)
        
            if #characters > 0 then
                print("Debug: Characters found, setting up dropdown")
                -- Check if the selected character is in the list
                if not tContains(characters, selectedCharacter) then
                    print("Debug: Selected character " .. selectedCharacter .. " not found in list")
                    -- If the current character is in the list, use it; otherwise, use the first character
                    if tContains(characters, currentCharacter) then
                        selectedCharacter = currentCharacter
                        print("Debug: Switching to current character: " .. selectedCharacter)
                    else
                        selectedCharacter = characters[1]
                        print("Debug: Switching to first character in list: " .. selectedCharacter)
                    end
                else
                    print("Debug: Selected character " .. selectedCharacter .. " found in list")
                end
                UIDropDownMenu_SetText(characterDropdown, selectedCharacter)
                print("Debug: Dropdown text set to " .. selectedCharacter)
                -- Initialize character settings display
                CharacterManager_Settings.UpdateCharacterSettings(characterSettingsContainer, selectedCharacter, characterDropdown)
            else
                print("Debug: No characters found")
                UIDropDownMenu_SetText(characterDropdown, "No characters")
            end
            print("Debug: Exiting UpdateCharacterDropdown function")
        end
        
        print("Debug: Before calling UpdateCharacterDropdown")
        UpdateCharacterDropdown()
        print("Debug: After calling UpdateCharacterDropdown")
        
        characterSettingsContainer:SetScript("OnShow", function()
            print("Debug: characterSettingsContainer OnShow triggered")
            CharacterManager_Settings.AdjustCharacterSettingsContainerHeight(characterSettingsContainer)
        end)
        
        -- Set OnShow script to refresh content when tab is shown
        settingsFrame:SetScript("OnShow", function()
            print("Debug: settingsFrame OnShow triggered")
            -- We'll add refresh logic here later
        end)

end

-- Update character-specific settings display
function CharacterManager_Settings.UpdateCharacterSettings(settingsFrame, characterName, anchorFrame)
    -- Remove any existing character settings
    if settingsFrame.characterSettings then
        settingsFrame.characterSettings:Hide()
        settingsFrame.characterSettings:SetParent(nil)
    end
    
    if not characterName or not MyAddonDB[characterName] then return end
    
    -- Create container for character settings
    local settingsContainer = CreateFrame("Frame", nil, settingsFrame)
    settingsContainer:SetSize(settingsFrame:GetWidth() - 40, 150)
    settingsContainer:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 15, -20)
    settingsFrame.characterSettings = settingsContainer
    
    -- Character info
    local charInfo = settingsContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    charInfo:SetPoint("TOPLEFT", 0, 0)
    
    local charData = MyAddonDB[characterName]
    local infoText = characterName
    if charData.class then
        local classColor = RAID_CLASS_COLORS[charData.class] or {r=1, g=1, b=1}
        infoText = string.format("|cff%02x%02x%02x%s|r", 
            classColor.r*255, classColor.g*255, classColor.b*255, 
            infoText)
    end
    if charData.level then
        infoText = infoText .. " (Level " .. charData.level .. ")"
    end
    charInfo:SetText(infoText)
    
    -- Buff tracking settings
    local buffTrackingTitle = settingsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    buffTrackingTitle:SetPoint("TOPLEFT", charInfo, "BOTTOMLEFT", 0, -15)
    buffTrackingTitle:SetText("Buff Tracking")
    
    -- Initialize character settings if needed
    if not WoWCharacterManagerSettings.characters then
        WoWCharacterManagerSettings.characters = {}
    end
    
    if not WoWCharacterManagerSettings.characters[characterName] then
        WoWCharacterManagerSettings.characters[characterName] = {
            trackedBuffs = {}
        }
        
        -- Copy default settings
        if WoWCharacterManagerSettings.defaultBuffs then
            for buffName, enabled in pairs(WoWCharacterManagerSettings.defaultBuffs) do
                WoWCharacterManagerSettings.characters[characterName].trackedBuffs[buffName] = enabled
            end
        else
            -- Initialize default buff settings if they don't exist
            WoWCharacterManagerSettings.defaultBuffs = {}
            for _, buffInfo in ipairs(CharacterManager_TrackedBuffs) do
                WoWCharacterManagerSettings.defaultBuffs[buffInfo.name] = true
                WoWCharacterManagerSettings.characters[characterName].trackedBuffs[buffInfo.name] = true
            end
        end
    end
    
    -- Create buff tracking checkboxes
    local yOffset = -40  -- Start below the character info and title
    local checkboxes = {}
    
    for i, buffInfo in ipairs(CharacterManager_TrackedBuffs) do
        local buffName = buffInfo.name
        local checkbox = CreateFrame("CheckButton", nil, settingsContainer, "UICheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", 10, yOffset)
        checkbox:SetSize(24, 24)
        
        local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        label:SetText(buffName)
        
        -- Set initial state
        local isEnabled = WoWCharacterManagerSettings.characters[characterName].trackedBuffs[buffName]
        checkbox:SetChecked(isEnabled)
        
        checkbox:SetScript("OnClick", function(self)
            local checked = self:GetChecked()
            WoWCharacterManagerSettings.characters[characterName].trackedBuffs[buffName] = checked
            
            -- Update buff display if on the buff tab
            if CharacterManager_BuffTracking and CharacterManager_BuffTracking.UpdateBuffDisplay then
                -- Use C_Timer.After to ensure tabFrames is available
                C_Timer.After(0, function()
                    if _G.tabFrames then
                        CharacterManager_BuffTracking.UpdateBuffDisplay(_G.tabFrames, MyAddonDB, WoWCharacterManagerSettings)
                    else
                        print("Error: tabFrames is not available")
                    end
                end)
            end
        end)
        
        table.insert(checkboxes, checkbox)
        yOffset = yOffset - 25
    end
    
    -- Add "Set as Default" button
    local defaultButton = CreateFrame("Button", nil, settingsContainer, "UIPanelButtonTemplate")
    defaultButton:SetSize(120, 24)
    defaultButton:SetPoint("TOPLEFT", 10, yOffset - 10)
    defaultButton:SetText("Set as Default")
    defaultButton:SetScript("OnClick", function()
        -- Copy current character settings to default
        if not WoWCharacterManagerSettings.defaultBuffs then
            WoWCharacterManagerSettings.defaultBuffs = {}
        end
        
        for _, buffInfo in ipairs(CharacterManager_TrackedBuffs) do
            local buffName = buffInfo.name
            WoWCharacterManagerSettings.defaultBuffs[buffName] = 
                WoWCharacterManagerSettings.characters[characterName].trackedBuffs[buffName] or false
        end
        print("Default buff settings updated based on " .. characterName)
        
        -- Check if there are duplicate phase dropdowns
        local count = 0
        local phaseDropdown = _G["CharacterManagerPhaseDropdown"]
        if phaseDropdown then
            count = 1
            print("Found phase dropdown: " .. phaseDropdown:GetName())
            
            -- Check if the dropdown has multiple parents
            local parent = phaseDropdown:GetParent()
            if parent then
                print("Phase dropdown parent: " .. (parent:GetName() or "unnamed frame"))
            end
        end
        print("Number of phase dropdowns found: " .. count)
    end)  -- Added the missing closing parenthesis here
    
    -- Add "Apply to All" button
    local applyAllButton = CreateFrame("Button", nil, settingsContainer, "UIPanelButtonTemplate")
    applyAllButton:SetSize(120, 24)
    applyAllButton:SetPoint("LEFT", defaultButton, "RIGHT", 10, 0)
    applyAllButton:SetText("Apply to All")
    applyAllButton:SetScript("OnClick", function()
        -- Apply current character settings to all characters
        for charName, _ in pairs(WoWCharacterManagerSettings.characters) do
            for _, buffInfo in ipairs(CharacterManager_TrackedBuffs) do
                local buffName = buffInfo.name
                WoWCharacterManagerSettings.characters[charName].trackedBuffs[buffName] = 
                    WoWCharacterManagerSettings.characters[characterName].trackedBuffs[buffName] or false
            end
        end
        print("Applied buff settings to all characters")
        
        -- Update buff display if on the buff tab
        if CharacterManager_BuffTracking and CharacterManager_BuffTracking.UpdateBuffDisplay then
            CharacterManager_BuffTracking.UpdateBuffDisplay(_G.tabFrames, MyAddonDB, WoWCharacterManagerSettings)
        end
    end)
    C_Timer.After(0.1, function()
        CharacterManager_Settings.AdjustCharacterSettingsContainerHeight(settingsFrame)
    end)
end