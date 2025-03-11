-- Settings.lua
CharacterManager_Settings = {}

-- Helper function to deep copy tables
local function CopyTable(source)
    local copy = {}
    for key, value in pairs(source) do
        if type(value) == "table" then
            copy[key] = CopyTable(value)
        else
            copy[key] = value
        end
    end
    return copy
end

-- Default settings
local defaultSettings = {
    minimapButton = {
        show = true,
        position = 45, -- Default angle position
    },
    displayOptions = {
        showOfflineCharacters = true,
        showLowLevelCharacters = false,
        minimumLevel = 60,
    },
    sortOptions = {
        sortBy = "name", -- name, level, class
        sortOrder = "asc", -- asc, desc
    }
}

-- Initialize settings
function CharacterManager_Settings.InitializeSettings()
    -- Create the settings table if it doesn't exist
    if not WoWCharacterManagerSettings then
        WoWCharacterManagerSettings = {}
    end
    
    -- Ensure all default settings exist
    for category, options in pairs(defaultSettings) do
        if not WoWCharacterManagerSettings[category] then
            WoWCharacterManagerSettings[category] = CopyTable(options)
        else
            for option, value in pairs(options) do
                if WoWCharacterManagerSettings[category][option] == nil then
                    WoWCharacterManagerSettings[category][option] = value
                end
            end
        end
    end
    
    return WoWCharacterManagerSettings
end

-- Create settings UI
-- Create settings UI
function CharacterManager_Settings.CreateSettingsUI(parentFrame)
    -- Make sure settings are initialized before creating UI elements
    local settings = CharacterManager_Settings.InitializeSettings()
    
    local settingsFrame = CreateFrame("Frame", nil, parentFrame)
    settingsFrame:SetAllPoints()
    
    -- Title
    local title = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText("Settings")
    
    -- Minimap Button Settings
    local minimapSection = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    minimapSection:SetPoint("TOPLEFT", 20, -50)
    minimapSection:SetText("Minimap Button")
    
    local showMinimapButton = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
    showMinimapButton:SetPoint("TOPLEFT", 30, -70)
    showMinimapButton:SetChecked(settings.minimapButton.show)
    
    local showMinimapText = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    showMinimapText:SetPoint("LEFT", showMinimapButton, "RIGHT", 5, 0)
    showMinimapText:SetText("Show minimap button")
    
    showMinimapButton:SetScript("OnClick", function()
        settings.minimapButton.show = showMinimapButton:GetChecked()
        CharacterManager_Settings.UpdateMinimapButton()
    end)
    
    -- Display Options
    local displaySection = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    displaySection:SetPoint("TOPLEFT", 20, -110)
    displaySection:SetText("Display Options")
    
    local showOfflineChars = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
    showOfflineChars:SetPoint("TOPLEFT", 30, -130)
    showOfflineChars:SetChecked(settings.displayOptions.showOfflineCharacters)
    
    local showOfflineText = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    showOfflineText:SetPoint("LEFT", showOfflineChars, "RIGHT", 5, 0)
    showOfflineText:SetText("Show offline characters")
    
    showOfflineChars:SetScript("OnClick", function()
        settings.displayOptions.showOfflineCharacters = showOfflineChars:GetChecked()
    end)
    
    local showLowLevelChars = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
    showLowLevelChars:SetPoint("TOPLEFT", 30, -150)
    showLowLevelChars:SetChecked(settings.displayOptions.showLowLevelCharacters)
    
    local showLowLevelText = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    showLowLevelText:SetPoint("LEFT", showLowLevelChars, "RIGHT", 5, 0)
    showLowLevelText:SetText("Show low level characters")
    
    showLowLevelChars:SetScript("OnClick", function()
        settings.displayOptions.showLowLevelCharacters = showLowLevelChars:GetChecked()
        minLevelSlider:SetEnabled(showLowLevelChars:GetChecked())
    end)
    
    -- Minimum level slider
    local minLevelSlider = CreateFrame("Slider", nil, settingsFrame, "OptionsSliderTemplate")
    minLevelSlider:SetPoint("TOPLEFT", 30, -180)
    minLevelSlider:SetWidth(200)
    minLevelSlider:SetMinMaxValues(1, 60)
    minLevelSlider:SetValue(settings.displayOptions.minimumLevel)
    minLevelSlider:SetValueStep(1)
    minLevelSlider:SetObeyStepOnDrag(true)
    minLevelSlider:SetEnabled(settings.displayOptions.showLowLevelCharacters)
    
    minLevelSlider.Low:SetText("1")
    minLevelSlider.High:SetText("60")
    minLevelSlider.Text:SetText("Minimum Level: " .. settings.displayOptions.minimumLevel)
    
    minLevelSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        settings.displayOptions.minimumLevel = value
        self.Text:SetText("Minimum Level: " .. value)
    end)
    
    -- Save button
    local saveButton = CreateFrame("Button", nil, settingsFrame, "UIPanelButtonTemplate")
    saveButton:SetSize(100, 25)
    saveButton:SetPoint("BOTTOMRIGHT", -20, 20)
    saveButton:SetText("Save")
    
    saveButton:SetScript("OnClick", function()
        print("Settings saved!")
        -- Any additional save logic can go here
    end)
    
    return settingsFrame
end

-- Update minimap button based on settings
function CharacterManager_Settings.UpdateMinimapButton()
    if MyAddonMinimapButton then
        if WoWCharacterManagerSettings.minimapButton.show then
            MyAddonMinimapButton:Show()
        else
            MyAddonMinimapButton:Hide()
        end
    end
end

-- Get settings value
function CharacterManager_Settings.GetSetting(category, option)
        -- Make sure settings are initialized
        CharacterManager_Settings.InitializeSettings()
    if WoWCharacterManagerSettings and WoWCharacterManagerSettings[category] and WoWCharacterManagerSettings[category][option] ~= nil then
        return WoWCharacterManagerSettings[category][option]
    elseif defaultSettings[category] and defaultSettings[category][option] ~= nil then
        return defaultSettings[category][option]
    end
    return nil
end

-- Set settings value
function CharacterManager_Settings.SetSetting(category, option, value)
    if not WoWCharacterManagerSettings then
        CharacterManager_Settings.InitializeSettings()
    end
    
    if not WoWCharacterManagerSettings[category] then
        WoWCharacterManagerSettings[category] = {}
    end
    
    WoWCharacterManagerSettings[category][option] = value
end