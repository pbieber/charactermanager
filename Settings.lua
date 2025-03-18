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
        
        local phaseDropdown = CreateFrame("Frame", "CharacterManagerPhaseDropdown", generalSettingsContainer, "UIDropDownMenuTemplate")
        phaseDropdown:SetPoint("TOPLEFT", phaseLabel, "BOTTOMLEFT", -15, -5)
        
        local phases = {"Phase 1", "Phase 2", "Phase 3", "Phase 4", "Phase 5", "Phase 6"}
        local currentPhase = MyAddonSettings and MyAddonSettings.currentPhase or 1
        
        UIDropDownMenu_Initialize(phaseDropdown, function(self, level)
            local info = UIDropDownMenu_CreateInfo()
            info.func = function(self)
                currentPhase = self.value
                UIDropDownMenu_SetText(phaseDropdown, phases[currentPhase])
                -- Save the setting
                if not MyAddonSettings then MyAddonSettings = {} end
                MyAddonSettings.currentPhase = currentPhase
            end
            
            for i, phaseName in ipairs(phases) do
                info.text = phaseName
                info.value = i
                info.checked = (currentPhase == i)
                UIDropDownMenu_AddButton(info, level)
            end
        end)
        
        UIDropDownMenu_SetWidth(phaseDropdown, 100)
        UIDropDownMenu_SetText(phaseDropdown, phases[currentPhase] or "Phase 1")
        
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
end