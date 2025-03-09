local CM = CharacterManager

-- Default settings
local defaultSettings = {
    general = {
        minimap = {
            show = true,
            position = 45, -- Default angle
        },
        autoOpen = false,
        saveOnLogout = true,
    },
    buffs = {
        enabled = true,
        showExpired = true,
        showDuration = true,
        trackWorldBuffs = true,
        trackConsumables = true,
        trackRaidBuffs = true,
        trackClassBuffs = true,
    },
    professionTracking = {
        enabled = true,
        showCooldowns = true,
        showSkillLevels = true,
    },
    ui = {
        scale = 1.0,
        transparency = 0.9,
        showTooltips = true,
    }
}

-- Initialize settings
function CM.InitSettings()
    -- Create settings table if it doesn't exist
    if not MyAddonSettings then
        MyAddonSettings = {}
    end
    
    -- Apply defaults for any missing settings
    for category, options in pairs(defaultSettings) do
        if not MyAddonSettings[category] then
            MyAddonSettings[category] = {}
        end
        
        for option, value in pairs(options) do
            if type(value) == "table" then
                if not MyAddonSettings[category][option] then
                    MyAddonSettings[category][option] = {}
                end
                
                for subOption, subValue in pairs(value) do
                    if MyAddonSettings[category][option][subOption] == nil then
                        MyAddonSettings[category][option][subOption] = subValue
                    end
                end
            else
                if MyAddonSettings[category][option] == nil then
                    MyAddonSettings[category][option] = value
                end
            end
        end
    end
end

-- Create settings UI
function CM.ShowSettingsUI()
    -- Create settings frame if it doesn't exist
    if not CM.settingsFrame then
        CM.CreateSettingsUI()
    end
    
    -- Show the settings frame
    CM.settingsFrame:Show()
end

-- Create the settings UI
function CM.CreateSettingsUI()
    -- Main settings frame
    CM.settingsFrame = CreateFrame("Frame", "CharacterManagerSettingsFrame", UIParent, "BackdropTemplate")
    CM.settingsFrame:SetSize(400, 500)
    CM.settingsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    CM.settingsFrame:SetBackdrop({
        bgFile = "Interface\DialogFrame\UI-DialogBox-Background",
        edgeFile = "Interface\DialogFrame\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    CM.settingsFrame:SetMovable(true)
    CM.settingsFrame:EnableMouse(true)
    CM.settingsFrame:RegisterForDrag("LeftButton")
    CM.settingsFrame:SetScript("OnDragStart", CM.settingsFrame.StartMoving)
    CM.settingsFrame:SetScript("OnDragStop", CM.settingsFrame.StopMovingOrSizing)
    CM.settingsFrame:Hide()
    
    -- Title
    local title = CM.settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOPLEFT", CM.settingsFrame, "TOPLEFT", 16, -16)
    title:SetText("Character Manager Settings")
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, CM.settingsFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", CM.settingsFrame, "TOPRIGHT", -5, -5)
    
    -- Create tab buttons
    local tabWidth = 80
    local tabHeight = 24
    local tabButtons = {}
    local tabFrames = {}
    local tabs = {"General", "Buffs", "Professions", "UI"}
    
    for i, tabName in ipairs(tabs) do
        -- Create tab button
        local tabButton = CreateFrame("Button", "CharacterManagerSettingsTab"..i, CM.settingsFrame, "CharacterFrameTabButtonTemplate")
        tabButton:SetPoint("TOPLEFT", CM.settingsFrame, "BOTTOMLEFT", (i-1) * tabWidth + 15, 0)
        tabButton:SetSize(tabWidth, tabHeight)
        tabButton:SetText(tabName)
        tabButton:SetID(i)
        
        -- Create tab content frame
        local tabFrame = CreateFrame("Frame", "CharacterManagerSettingsTabFrame"..i, CM.settingsFrame)
        tabFrame:SetPoint("TOPLEFT", CM.settingsFrame, "TOPLEFT", 20, -40)
        tabFrame:SetPoint("BOTTOMRIGHT", CM.settingsFrame, "BOTTOMRIGHT", -20, 20)
        tabFrame:Hide()
        
        -- Store references
        tabButtons[i] = tabButton
        tabFrames[i] = tabFrame
        
        -- Tab button click handler
        tabButton:SetScript("OnClick", function()
            for j, frame in ipairs(tabFrames) do
                frame:Hide()
                PanelTemplates_DeselectTab(tabButtons[j])
            end
            tabFrame:Show()
            PanelTemplates_SelectTab(tabButton)
        end)
    end
    
    -- Select first tab by default
    PanelTemplates_SelectTab(tabButtons[1])
    tabFrames[1]:Show()
    
    -- Populate General tab
    CM.CreateGeneralSettingsTab(tabFrames[1])
    
    -- Populate Buffs tab
    CM.CreateBuffSettingsTab(tabFrames[2])
    
    -- Populate Professions tab
    CM.CreateProfessionSettingsTab(tabFrames[3])
    
    -- Populate UI tab
    CM.CreateUISettingsTab(tabFrames[4])
    
    -- Save button
    local saveButton = CreateFrame("Button", nil, CM.settingsFrame, "UIPanelButtonTemplate")
    saveButton:SetSize(100, 22)
    saveButton:SetPoint("BOTTOMRIGHT", CM.settingsFrame, "BOTTOMRIGHT", -20, 15)
    saveButton:SetText("Save")
    saveButton:SetScript("OnClick", function()
        CM.SaveSettings()
        CM.settingsFrame:Hide()
    end)
    
    -- Reset button
    local resetButton = CreateFrame("Button", nil, CM.settingsFrame, "UIPanelButtonTemplate")
    resetButton:SetSize(100, 22)
    resetButton:SetPoint("RIGHT", saveButton, "LEFT", -10, 0)
    resetButton:SetText("Reset")
    resetButton:SetScript("OnClick", function()
        StaticPopup_Show("CHARACTERMANAGER_RESET_SETTINGS")
    end)
    
    -- Confirmation dialog for reset
    StaticPopupDialogs["CHARACTERMANAGER_RESET_SETTINGS"] = {
        text = "Are you sure you want to reset all settings to default?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            CM.ResetSettings()
            CM.settingsFrame:Hide()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

-- Create General settings tab
function CM.CreateGeneralSettingsTab(parent)
    local yOffset = -10
    
    -- Minimap button settings
    local minimapHeader = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    minimapHeader:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    minimapHeader:SetText("Minimap Button")
    minimapHeader:SetTextColor(1, 0.82, 0)
    
    yOffset = yOffset - 25
    
    -- Show minimap button
    local showMinimapButton = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    showMinimapButton:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    showMinimapButton.Text:SetText("Show minimap button")
    showMinimapButton:SetChecked(MyAddonSettings.general.minimap.show)
    showMinimapButton:SetScript("OnClick", function(self)
        MyAddonSettings.general.minimap.show = self:GetChecked()
        if CM.minimapButton then
            if MyAddonSettings.general.minimap.show then
                CM.minimapButton:Show()
            else
                CM.minimapButton:Hide()
            end
        end
    end)
    
    yOffset = yOffset - 30
    
    -- Minimap position slider
    local minimapPosSlider = CreateFrame("Slider", "CharacterManagerMinimapSlider", parent, "OptionsSliderTemplate")
    minimapPosSlider:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    minimapPosSlider:SetWidth(200)
    minimapPosSlider:SetMinMaxValues(0, 360)
    minimapPosSlider:SetValueStep(1)
    minimapPosSlider:SetValue(MyAddonSettings.general.minimap.position)
    minimapPosSlider:SetObeyStepOnDrag(true)
    CharacterManagerMinimapSliderLow:SetText("0°")
    CharacterManagerMinimapSliderHigh:SetText("360°")
    CharacterManagerMinimapSliderText:SetText("Minimap Button Position")
    
    minimapPosSlider:SetScript("OnValueChanged", function(self, value)
        MyAddonSettings.general.minimap.position = value
        if CM.minimapButton then
            CM.UpdateMinimapButton()
        end
    end)
    
    yOffset = yOffset - 50
    
    -- Auto open settings
    local autoOpenHeader = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    autoOpenHeader:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    autoOpenHeader:SetText("Startup Options")
    autoOpenHeader:SetTextColor(1, 0.82, 0)
    
    yOffset = yOffset - 25
    
    -- Auto open on login
    local autoOpenButton = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    autoOpenButton:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    autoOpenButton.Text:SetText("Auto open main window on login")
    autoOpenButton:SetChecked(MyAddonSettings.general.autoOpen)
    autoOpenButton:SetScript("OnClick", function(self)
        MyAddonSettings.general.autoOpen = self:GetChecked()
    end)
    
    yOffset = yOffset - 30
    
    -- Save on logout
    local saveLogoutButton = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    saveLogoutButton:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    saveLogoutButton.Text:SetText("Save character data on logout")
    saveLogoutButton:SetChecked(MyAddonSettings.general.saveOnLogout)
    saveLogoutButton:SetScript("OnClick", function(self)
        MyAddonSettings.general.saveOnLogout = self:GetChecked()
    end)
    
    yOffset = yOffset - 40
    
    -- Data management
    local dataHeader = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dataHeader:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    dataHeader:SetText("Data Management")
    dataHeader:SetTextColor(1, 0.82, 0)
    
    yOffset = yOffset - 25
    
    -- Clear data button
    local clearDataButton = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    clearDataButton:SetSize(150, 22)
    clearDataButton:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    clearDataButton:SetText("Clear All Character Data")
    clearDataButton:SetScript("OnClick", function()
        StaticPopup_Show("CHARACTERMANAGER_CLEAR_DATA")
    end)
    
    -- Confirmation dialog for clearing data
    StaticPopupDialogs["CHARACTERMANAGER_CLEAR_DATA"] = {
        text = "Are you sure you want to clear ALL character data?\nThis cannot be undone!",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            MyAddonDB = {}
            print("|cFF00FF00Character Manager:|r All character data has been cleared.")
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    
    yOffset = yOffset - 30
    
    -- Clear current character data button
    local clearCurrentButton = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    clearCurrentButton:SetSize(150, 22)
    clearCurrentButton:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    clearCurrentButton:SetText("Clear Current Character")
    clearCurrentButton:SetScript("OnClick", function()
        StaticPopup_Show("CHARACTERMANAGER_CLEAR_CURRENT")
    end)
    
    -- Confirmation dialog for clearing current character data
    StaticPopupDialogs["CHARACTERMANAGER_CLEAR_CURRENT"] = {
        text = "Are you sure you want to clear data for your current character?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            local playerName = UnitName("player")
            local realmName = GetRealmName()
            local fullName = playerName .. "-" .. realmName
            
            if MyAddonDB[fullName] then
                MyAddonDB[fullName] = nil
                print("|cFF00FF00Character Manager:|r Data for " .. fullName .. " has been cleared.")
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

-- Create Buff settings tab
function CM.CreateBuffSettingsTab(parent)
    local yOffset = -10
    
    -- Enable buff tracking
    local enableBuffs = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    enableBuffs:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    enableBuffs.Text:SetText("Enable buff tracking")
    enableBuffs:SetChecked(MyAddonSettings.buffs.enabled)
    enableBuffs:SetScript("OnClick", function(self)
        MyAddonSettings.buffs.enabled = self:GetChecked()
    end)
    
    yOffset = yOffset - 30
    
    -- Show expired buffs
    local showExpired = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    showExpired:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    showExpired.Text:SetText("Show expired buffs")
    showExpired:SetChecked(MyAddonSettings.buffs.showExpired)
    showExpired:SetScript("OnClick", function(self)
        MyAddonSettings.buffs.showExpired = self:GetChecked()
    end)
    
    yOffset = yOffset - 30
    
    -- Show buff duration
    local showDuration = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    showDuration:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    showDuration.Text:SetText("Show buff duration")
    showDuration:SetChecked(MyAddonSettings.buffs.showDuration)
    showDuration:SetScript("OnClick", function(self)
        MyAddonSettings.buffs.showDuration = self:GetChecked()
    end)
    
    yOffset = yOffset - 40
    
    -- Buff types header
    local buffTypesHeader = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    buffTypesHeader:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    buffTypesHeader:SetText("Buff Types to Track")
    buffTypesHeader:SetTextColor(1, 0.82, 0)
    
    yOffset = yOffset - 25
    
    -- Track world buffs
    local trackWorldBuffs = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    trackWorldBuffs:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    trackWorldBuffs.Text:SetText("World buffs (Rallying Cry, Songflower, etc)")
    trackWorldBuffs:SetChecked(MyAddonSettings.buffs.trackWorldBuffs)
    trackWorldBuffs:SetScript("OnClick", function(self)
        MyAddonSettings.buffs.trackWorldBuffs = self:GetChecked()
    end)
    
    yOffset = yOffset - 30
    
    -- Track consumables
    local trackConsumables = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    trackConsumables:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    trackConsumables.Text:SetText("Consumables (Flasks, Elixirs, Food, etc)")
    trackConsumables:SetChecked(MyAddonSettings.buffs.trackConsumables)
    trackConsumables:SetScript("OnClick", function(self)
        MyAddonSettings.buffs.trackConsumables = self:GetChecked()
    end)
    
    yOffset = yOffset - 30
    
    -- Track raid buffs
    local trackRaidBuffs = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    trackRaidBuffs:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    trackRaidBuffs.Text:SetText("Raid buffs (Arcane Intellect, Fortitude, etc)")
    trackRaidBuffs:SetChecked(MyAddonSettings.buffs.trackRaidBuffs)
    trackRaidBuffs:SetScript("OnClick", function(self)
        MyAddonSettings.buffs.trackRaidBuffs = self:GetChecked()
    end)
    
    yOffset = yOffset - 30
    
    -- Track class buffs
    local trackClassBuffs = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    trackClassBuffs:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    trackClassBuffs.Text:SetText("Class buffs (Shields, Auras, Seals, etc)")
    trackClassBuffs:SetChecked(MyAddonSettings.buffs.trackClassBuffs)
    trackClassBuffs:SetScript("OnClick", function(self)
        MyAddonSettings.buffs.trackClassBuffs = self:GetChecked()
    end)
end

-- Create Profession settings tab
function CM.CreateProfessionSettingsTab(parent)
    local yOffset = -10
    
    -- Enable profession tracking
    local enableProfessions = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    enableProfessions:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    enableProfessions.Text:SetText("Enable profession tracking")
    enableProfessions:SetChecked(MyAddonSettings.professionTracking.enabled)
    enableProfessions:SetScript("OnClick", function(self)
        MyAddonSettings.professionTracking.enabled = self:GetChecked()
    end)
    
    yOffset = yOffset - 30
    
    -- Show cooldowns
    local showCooldowns = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    showCooldowns:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    showCooldowns.Text:SetText("Show profession cooldowns")
    showCooldowns:SetChecked(MyAddonSettings.professionTracking.showCooldowns)
    showCooldowns:SetScript("OnClick", function(self)
        MyAddonSettings.professionTracking.showCooldowns = self:GetChecked()
    end)
    
    yOffset = yOffset - 30
    
    -- Show skill levels
    local showSkillLevels = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    showSkillLevels:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    showSkillLevels.Text:SetText("Show skill levels")
    showSkillLevels:SetChecked(MyAddonSettings.professionTracking.showSkillLevels)
    showSkillLevels:SetScript("OnClick", function(self)
        MyAddonSettings.professionTracking.showSkillLevels = self:GetChecked()
    end)
end

-- Create UI settings tab
function CM.CreateUISettingsTab(parent)
    local yOffset = -10
    
    -- UI Scale
    local scaleText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    scaleText:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    scaleText:SetText("UI Scale")
    
    yOffset = yOffset - 25
    
    local scaleSlider = CreateFrame("Slider", "CharacterManagerScaleSlider", parent, "OptionsSliderTemplate")
    scaleSlider:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    scaleSlider:SetWidth(200)
    scaleSlider:SetMinMaxValues(0.5, 1.5)
    scaleSlider:SetValueStep(0.05)
    scaleSlider:SetValue(MyAddonSettings.ui.scale)
    scaleSlider:SetObeyStepOnDrag(true)
    CharacterManagerScaleSliderLow:SetText("0.5")
    CharacterManagerScaleSliderHigh:SetText("1.5")
    CharacterManagerScaleSliderText:SetText(string.format("%.2f", MyAddonSettings.ui.scale))
    
    scaleSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value * 20 + 0.5) / 20 -- Round to nearest 0.05
        MyAddonSettings.ui.scale = value
        CharacterManagerScaleSliderText:SetText(string.format("%.2f", value))
        
        if CM.mainFrame then
            CM.mainFrame:SetScale(value)
        end
    end)
    
    yOffset = yOffset - 50
    
    -- Transparency
    local transparencyText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    transparencyText:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    transparencyText:SetText("Window Transparency")
    
    yOffset = yOffset - 25
    
    local transparencySlider = CreateFrame("Slider", "CharacterManagerTransparencySlider", parent, "OptionsSliderTemplate")
    transparencySlider:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    transparencySlider:SetWidth(200)
    transparencySlider:SetMinMaxValues(0.1, 1.0)
    transparencySlider:SetValueStep(0.05)
    transparencySlider:SetValue(MyAddonSettings.ui.transparency)
    transparencySlider:SetObeyStepOnDrag(true)
    CharacterManagerTransparencySliderLow:SetText("0.1")
    CharacterManagerTransparencySliderHigh:SetText("1.0")
    CharacterManagerTransparencySliderText:SetText(string.format("%.2f", MyAddonSettings.ui.transparency))
    
    transparencySlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value * 20 + 0.5) / 20 -- Round to nearest 0.05
        MyAddonSettings.ui.transparency = value
        CharacterManagerTransparencySliderText:SetText(string.format("%.2f", value))
        
        if CM.mainFrame then
            CM.mainFrame:SetAlpha(value)
        end
    end)
    
    yOffset = yOffset - 50
    
    -- Show tooltips
    local showTooltips = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    showTooltips:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    showTooltips.Text:SetText("Show tooltips")
    showTooltips:SetChecked(MyAddonSettings.ui.showTooltips)
    showTooltips:SetScript("OnClick", function(self)
        MyAddonSettings.ui.showTooltips = self:GetChecked()
    end)
end

-- Save settings
function CM.SaveSettings()
    -- Apply settings to UI elements
    if CM.mainFrame then
        CM.mainFrame:SetScale(MyAddonSettings.ui.scale)
        CM.mainFrame:SetAlpha(MyAddonSettings.ui.transparency)
    end
    
    -- Update minimap button
    if CM.minimapButton then
        if MyAddonSettings.general.minimap.show then
            CM.minimapButton:Show()
        else
            CM.minimapButton:Hide()
        end
        CM.UpdateMinimapButton()
    end
    
    print("|cFF00FF00Character Manager:|r Settings saved.")
end

-- Reset settings to default
function CM.ResetSettings()
    -- Reset all settings to default
    MyAddonSettings = {}
    
    -- Re-initialize with defaults
    CM.InitSettings()
    
    -- Apply default settings
    CM.SaveSettings()
    
    -- Refresh settings UI if it's open
    if CM.settingsFrame and CM.settingsFrame:IsShown() then
        CM.settingsFrame:Hide()
        CM.ShowSettingsUI()
    end
    
    print("|cFF00FF00Character Manager:|r Settings reset to default.")
end