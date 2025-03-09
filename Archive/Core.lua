-- Create main addon namespace
CharacterManager = CharacterManager or {}
local CM = CharacterManager
local addonName = "CharacterManager"

-- Initialize addon settings with defaults
function CM.InitializeSettings()
    -- Create default settings if they don't exist
    if not MyAddonSettings then
        MyAddonSettings = {
            professionTracking = {
                showSkillLevels = true,
                showCooldowns = true
            },
            raidTracking = {
                showCompleted = true,
                showResetTimes = true
            },
            minimap = {
                show = true,
                position = 45
            }
        }
    end
end

-- Create main event frame
CM.eventFrame = CreateFrame("Frame")

-- Main initialization function
function CM.Initialize()
    -- Load saved variables
    CM.InitializeSettings()
    
    -- Create main UI components
    CM.CreateMainFrame()
    
    -- Register events
    CM.RegisterEvents()
    
    -- Print welcome message
    print("|cFF33FF99Character Manager|r: Addon loaded. Type |cFFFFFF00/cm|r or |cFFFFFF00/charmanager|r for options.")
end

-- Create the main addon frame
function CM.CreateMainFrame()
    -- Main frame
    CM.mainFrame = CreateFrame("Frame", "CharacterManagerFrame", UIParent, "BackdropTemplate")
    CM.mainFrame:SetSize(400, 300)
    CM.mainFrame:SetPoint("CENTER")
    CM.mainFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    CM.mainFrame:SetMovable(true)
    CM.mainFrame:EnableMouse(true)
    CM.mainFrame:RegisterForDrag("LeftButton")
    CM.mainFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    CM.mainFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    
    -- Title
    local title = CM.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", 0, -15)
    title:SetText("Character Manager")
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, CM.mainFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", CM.mainFrame, "TOPRIGHT", -5, -5)
    
    -- Create tabs
    CM.CreateTabs()
    
    -- Hide by default
    CM.mainFrame:Hide()
end

-- Create tabs for the main frame
function CM.CreateTabs()
    -- Tab definitions
    local tabs = {
        {name = "Characters", frame = "characterTab"},
        {name = "Professions", frame = "professionTab"},
        {name = "Raids", frame = "raidTab"},
        {name = "Settings", frame = "settingsTab"}
    }
    
    CM.tabs = {}
    CM.tabFrames = {}
    
    -- Create tab buttons
    for i, tab in ipairs(tabs) do
        -- Create tab button
        local tabButton = CreateFrame("Button", "CharacterManagerTab"..i, CM.mainFrame, "CharacterFrameTabButtonTemplate")
        tabButton:SetID(i)
        tabButton:SetText(tab.name)
        tabButton:SetScript("OnClick", function()
            CM.SelectTab(i)
        end)
        
        -- Position tabs
        if i == 1 then
            tabButton:SetPoint("BOTTOMLEFT", CM.mainFrame, "BOTTOMLEFT", 20, -25)
        else
            tabButton:SetPoint("LEFT", CM.tabs[i-1], "RIGHT", -15, 0)
        end
        
        -- Create tab content frame
        local tabFrame = CreateFrame("Frame", nil, CM.mainFrame)
        tabFrame:SetPoint("TOPLEFT", CM.mainFrame, "TOPLEFT", 10, -30)
        tabFrame:SetPoint("BOTTOMRIGHT", CM.mainFrame, "BOTTOMRIGHT", -10, 10)
        tabFrame:Hide()
        
        -- Store references
        CM.tabs[i] = tabButton
        CM.tabFrames[i] = tabFrame
    end
    
    -- Show first tab by default
    if #CM.tabs > 0 then
        PanelTemplates_SetNumTabs(CM.mainFrame, #tabs)
        PanelTemplates_SetTab(CM.mainFrame, 1)
        CM.tabFrames[1]:Show()
    end
end

-- Select a tab
function CM.SelectTab(tabIndex)
    PanelTemplates_SetTab(CM.mainFrame, tabIndex)
    
    for i, frame in ipairs(CM.tabFrames) do
        if i == tabIndex then
            frame:Show()
        else
            frame:Hide()
        end
    end
    
    -- Update content for the selected tab
    if tabIndex == 1 and CM.UpdateCharacterTab then
        -- Characters tab
        CM.UpdateCharacterTab()
    elseif tabIndex == 2 and CM.UpdateProfessionDisplay then
        -- Professions tab
        CM.UpdateProfessionDisplay()
    elseif tabIndex == 3 and CM.UpdateRaidDisplay then
        -- Raids tab
        CM.UpdateRaidDisplay()
    elseif tabIndex == 4 and CM.UpdateSettingsTab then
        -- Settings tab
        CM.UpdateSettingsTab()
    end
end

-- Register main events
function CM.RegisterEvents()
    -- Core events
    CM.eventFrame:RegisterEvent("ADDON_LOADED")
    CM.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    CM.eventFrame:RegisterEvent("PLAYER_LOGOUT")
    
    -- Set up event handler
    CM.eventFrame:SetScript("OnEvent", function(self, event, arg1)
        if event == "ADDON_LOADED" and arg1 == addonName then
            -- Initialize immediately
            CM.Initialize()
            -- Register for a later update to ensure everything is loaded
            CM.eventFrame:RegisterEvent("PLAYER_LOGIN")
        elseif event == "PLAYER_LOGIN" then
            -- This event fires after ADDON_LOADED but before PLAYER_ENTERING_WORLD
            -- Re-initialize to ensure everything is properly set up
            CM.Initialize()
            CM.eventFrame:UnregisterEvent("PLAYER_LOGIN")
        elseif event == "PLAYER_ENTERING_WORLD" then
            -- Save character data when entering world
            if CM.SaveCharacterData then
                CM.SaveCharacterData()
            end
        elseif event == "PLAYER_LOGOUT" then
            -- Save data on logout
            if CM.SaveCharacterData then
                CM.SaveCharacterData()
            end
        end
    end)
    
    -- Register profession-specific events
    if CM.RegisterProfessionEvents then
        CM.RegisterProfessionEvents()
    end
    
    -- Register raid-specific events
    if CM.RegisterRaidEvents then
        CM.RegisterRaidEvents()
    end
end

-- Get full character name (name-realm)
function CM.GetFullCharacterName()
    local playerName = UnitName("player")
    local realmName = GetRealmName()
    return playerName .. " - " .. realmName
end

-- Save character data
function CM.SaveCharacterData()
    local fullName = CM.GetFullCharacterName()
    
    -- Initialize character data if needed
    if not MyAddonDB then MyAddonDB = {} end
    if not MyAddonDB[fullName] then MyAddonDB[fullName] = {} end
    
    -- Save basic character info
    local _, class = UnitClass("player")
    local level = UnitLevel("player")
    
    MyAddonDB[fullName].name = UnitName("player")
    MyAddonDB[fullName].class = class
    MyAddonDB[fullName].level = level
    MyAddonDB[fullName].lastSeen = time()
    
    -- Save profession data if available
    if CM.SaveProfessionData then
        CM.SaveProfessionData()
    end
    
    -- Save raid data if available
    if CM.SaveRaidData then
        CM.SaveRaidData()
    end
end

-- Format time in hours:minutes:seconds
function CM.FormatTime(seconds)
    if seconds <= 0 then
        return "Ready"
    end
    
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    
    if hours > 0 then
        return string.format("%d:%02d:%02d", hours, minutes, secs)
    else
        return string.format("%d:%02d", minutes, secs)
    end
end

-- Format time in days and hours for longer cooldowns
function CM.FormatTimeHours(seconds)
    if seconds <= 0 then
        return "Ready"
    end
    
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    
    if days > 0 then
        return string.format("%dd %dh", days, hours)
    elseif hours > 0 then
        return string.format("%dh %dm", hours, minutes)
    else
        return string.format("%dm", minutes)
    end
end

-- Class icon texture coordinates
CM.CLASS_ICON_TCOORDS = {
    ["WARRIOR"] = {0, 0.25, 0, 0.25},
    ["MAGE"] = {0.25, 0.49609375, 0, 0.25},
    ["ROGUE"] = {0.49609375, 0.7421875, 0, 0.25},
    ["DRUID"] = {0.7421875, 0.98828125, 0, 0.25},
    ["HUNTER"] = {0, 0.25, 0.25, 0.5},
    ["SHAMAN"] = {0.25, 0.49609375, 0.25, 0.5},
    ["PRIEST"] = {0.49609375, 0.7421875, 0.25, 0.5},
    ["WARLOCK"] = {0.7421875, 0.98828125, 0.25, 0.5},
    ["PALADIN"] = {0, 0.25, 0.5, 0.75},
}

-- Placeholder functions that will be implemented in other files
if not CM.UpdateCharacterTab then
    function CM.UpdateCharacterTab()
        local frame = CM.tabFrames[1]
        if not frame then return end
        
        local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("CENTER")
        text:SetText("Character tracking will be implemented soon")
    end
end

if not CM.UpdateProfessionDisplay then
    function CM.UpdateProfessionDisplay()
        local frame = CM.tabFrames[2]
        if not frame then return end
        
        local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("CENTER")
        text:SetText("Profession tracking will be implemented soon")
    end
end

if not CM.UpdateRaidDisplay then
    function CM.UpdateRaidDisplay()
        local frame = CM.tabFrames[3]
        if not frame then return end
        
        local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("CENTER")
        text:SetText("Raid tracking will be implemented soon")
    end
end

if not CM.UpdateSettingsTab then
    function CM.UpdateSettingsTab()
        local frame = CM.tabFrames[4]
        if not frame then return end
        
        local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("CENTER")
        text:SetText("Settings will be implemented soon")
    end
end

-- Toggle UI functions
function CM.ToggleMainUI()
    if CM.mainFrame:IsShown() then
        CM.mainFrame:Hide()
    else
        CM.mainFrame:Show()
    end
end

function CM.ToggleProfessionUI()
    CM.mainFrame:Show()
    CM.SelectTab(2)
end

function CM.ToggleRaidUI()
    CM.mainFrame:Show()
    CM.SelectTab(3)
end

function CM.ShowSettingsUI()
    CM.mainFrame:Show()
    CM.SelectTab(4)
end

-- Slash command handler
SLASH_CHARACTERMANAGER1 = "/cm"
SLASH_CHARACTERMANAGER2 = "/charmanager"
SlashCmdList["CHARACTERMANAGER"] = function(msg)
    -- Check if the addon is initialized
    if not CM.mainFrame then
        print("|cFF33FF99Character Manager|r: Addon is still initializing. Please try again in a moment.")
        -- Initialize if not already done
        CM.Initialize()
        return
    end

    if msg == "professions" or msg == "prof" then
        if CM.ToggleProfessionUI then
            CM.ToggleProfessionUI()
        end
    elseif msg == "raids" then
        if CM.ToggleRaidUI then
            CM.ToggleRaidUI()
        end
    elseif msg == "settings" then
        if CM.ShowSettingsUI then
            CM.ShowSettingsUI()
        end
    else
        -- Toggle main UI
        if CM.mainFrame:IsShown() then
            CM.mainFrame:Hide()
        else
            CM.mainFrame:Show()
        end
    end
end