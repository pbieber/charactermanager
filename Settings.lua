-- Settings.lua
-- Handles all settings functionality for Character Manager

CharacterManager_Settings = {}

-- Create the settings tab content
function CharacterManager_Settings.CreateSettingsTabContent(tabFrames)
        local settingsFrame = tabFrames[6]  -- Settings is the 6th tab
        if not settingsFrame then return end
        
        -- Title
        local title = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 20, -20)
        title:SetText("Settings")
        
        -- General Settings Section with background
        local generalSettingsContainer = CreateFrame("Frame", nil, settingsFrame, "BackdropTemplate")
        generalSettingsContainer:SetSize(360, 120)
        generalSettingsContainer:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
        generalSettingsContainer:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 16,
            insets = { left = 5, right = 5, top = 5, bottom = 5 }
        })
        
        -- General Settings Section Title
        local generalTitle = generalSettingsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        generalTitle:SetPoint("TOPLEFT", 15, -15)
        generalTitle:SetText("General Settings")
        
        -- Phase dropdown
        local phaseLabel = generalSettingsContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        phaseLabel:SetPoint("TOPLEFT", generalTitle, "BOTTOMLEFT", 5, -15)
        phaseLabel:SetText("Game Phase:")
        
        -- Check if the dropdown already exists
        local phaseDropdown = _G["CharacterManagerPhaseDropdown"]
        if not phaseDropdown then
            phaseDropdown = CreateFrame("Frame", "CharacterManagerPhaseDropdown", generalSettingsContainer, "UIDropDownMenuTemplate")
            phaseDropdown:SetPoint("TOPLEFT", phaseLabel, "BOTTOMLEFT", -15, -5)
        else
            -- If it exists, just reparent and reposition it
            phaseDropdown:SetParent(generalSettingsContainer)
            phaseDropdown:ClearAllPoints()
            phaseDropdown:SetPoint("TOPLEFT", phaseLabel, "BOTTOMLEFT", -15, -5)
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
                
                -- Update raid frames based on new phase
                if CharacterManager_RaidLockouts and CharacterManager_RaidLockouts.RecreateRaidFrames then
                    print("CharacterManager: Recreating raid frames for new phase...")
                    raidFrames = CharacterManager_RaidLockouts.RecreateRaidFrames(tabFrames, WoWCharacterManagerSettings)
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
        
        -- Debug Tools Section with background
        local debugSettingsContainer = CreateFrame("Frame", nil, settingsFrame, "BackdropTemplate")
        debugSettingsContainer:SetSize(360, 100)
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
        
        -- Character-specific Settings Section with background
        local characterSettingsContainer = CreateFrame("Frame", nil, settingsFrame, "BackdropTemplate")
        characterSettingsContainer:SetSize(360, 200)
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
        
        -- Character dropdown
        local characterDropdown = CreateFrame("Frame", "CharacterManagerSettingsDropdown", characterSettingsContainer, "UIDropDownMenuTemplate")
        characterDropdown:SetPoint("TOPLEFT", characterTitle, "BOTTOMLEFT", -15, -10)
        
        local selectedCharacter = nil
        
        local function UpdateCharacterDropdown()
            local characters = {}
            for fullName, _ in pairs(MyAddonDB) do
                table.insert(characters, fullName)
            end
            table.sort(characters)
            
            UIDropDownMenu_Initialize(characterDropdown, function(self, level)
                local info = UIDropDownMenu_CreateInfo()
                info.func = function(self)
                    selectedCharacter = self.value
                    UIDropDownMenu_SetText(characterDropdown, selectedCharacter)
                    -- Update character-specific settings display
                    CharacterManager_Settings.UpdateCharacterSettings(characterSettingsContainer, selectedCharacter, characterDropdown)
                end
                
                for _, charName in ipairs(characters) do
                    info.text = charName
                    info.value = charName
                    info.checked = (selectedCharacter == charName)
                    UIDropDownMenu_AddButton(info, level)
                end
            end)
            
            if #characters > 0 and not selectedCharacter then
                selectedCharacter = characters[1]
                UIDropDownMenu_SetText(characterDropdown, selectedCharacter)
                -- Initialize character settings display
                CharacterManager_Settings.UpdateCharacterSettings(characterSettingsContainer, selectedCharacter, characterDropdown)
            else
                UIDropDownMenu_SetText(characterDropdown, selectedCharacter or "Select Character")
            end
        end
        
        UpdateCharacterDropdown()
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
        
        -- Handle checkbox changes
        checkbox:SetScript("OnClick", function(self)
            local checked = self:GetChecked()
            WoWCharacterManagerSettings.characters[characterName].trackedBuffs[buffName] = checked
            
            -- Update buff display if on the buff tab
            if CharacterManager_BuffTracking and CharacterManager_BuffTracking.UpdateBuffDisplay then
                CharacterManager_BuffTracking.UpdateBuffDisplay(_G.tabFrames, MyAddonDB, WoWCharacterManagerSettings)
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
    
    -- Adjust container height based on content
    settingsContainer:SetHeight(math.abs(yOffset) + 50)  -- Add some padding
end