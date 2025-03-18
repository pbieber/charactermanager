local MyAddon = CreateFrame("Frame", "MyAddonFrame", UIParent, "BasicFrameTemplateWithInset")
MyAddon:SetSize(400, 370)
MyAddon:SetPoint("CENTER")
MyAddon:EnableMouse(true)
MyAddon:SetMovable(true)
MyAddon:RegisterForDrag("LeftButton")
MyAddon:SetScript("OnDragStart", MyAddon.StartMoving)
MyAddon:SetScript("OnDragStop", MyAddon.StopMovingOrSizing)
MyAddon.title = MyAddon:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
MyAddon.title:SetPoint("TOP", 0, -5)
MyAddon.title:SetText("Character Manager")


-- Initializations
characters = {}
local raidFrames = {}
local collapsedCharacters = {}
local cooldownBars = {}
local tabFrames = {}
local buffCheckboxes = {}
local buffSettingsContainer = nil
local cooldownDebugText = nil
CharacterManager_ProfessionCooldowns = CharacterManager_ProfessionCooldowns or {}

-- Getting Constants
local raids = CharacterManager_Raids
local raidDisplayNames = CharacterManager_RaidDisplayNames
local raidActualNames = CharacterManager_RaidActualNames

local trackedBuffs = CharacterManager_TrackedBuffs
local CHRONOBOON_AURA_ID = CharacterManager_CHRONOBOON_AURA_ID

local function GetClassColor(class)
    return CharacterManager_ClassColors[class] or "|cFFFFFFFF" -- Use constants from Constants.lua
end

-- to be replaced
local professionCooldowns = CharacterManager_ProfessionCooldowns.professionCooldowns

local SpellsToTrack = CharacterManager_ProfessionCooldowns.SpellsToTrack

------------------------ 
-- Start of addon
------------------------


local function FormatTime(seconds)
    if seconds <= 0 then
        return "0d 0h"
    end
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    return string.format("%dd %dh", days, hours)
end

local function LoadCharacterData()
    if not MyAddonDB then
        MyAddonDB = {}  -- Initialize if not present
        print("MyAddonDB initialized as empty.")
    else
        print("Loaded MyAddonDB")
    end
    characters = MyAddonDB  -- Assign global storage
end

local function InitializeAddon()
    -- Initialize buff tracking module
    local buffTrackingFrame = CharacterManager_BuffTracking.Initialize(CharacterManager_TrackedBuffs, CharacterManager_CHRONOBOON_AURA_ID)


end

local function InitializeSettings()
    -- Nothing to initialize yet, but we'll keep this function for future use
end

InitializeAddon()
------------------------
---- To-dos Tab
------------------------

-- Not implemented yet


------------------------
---- Professions Tab
------------------------
local function GetTrackedSpellIDs()
    return CharacterManager_ProfessionCooldowns.GetTrackedSpellIDs()
end


local function CreateCooldownBars()
    -- Use the module function to create cooldown bars
    cooldownBars, cooldownDebugText = CharacterManager_ProfessionCooldowns.CreateCooldownBars(tabFrames[2])
end

local function UpdateProfessionCooldowns()
    -- Use the module function to update cooldown bars
    CharacterManager_ProfessionCooldowns.UpdateProfessionCooldowns(cooldownBars, MyAddonDB, cooldownDebugText)
end

local function FormatTimeMinutes(seconds)
    local minutes = math.floor(seconds / 60)
    return string.format("%d min", minutes)
end

local function CheckProfessionsAndSpells()
    local playerName = UnitName("player")
    local realmName = GetRealmName()
    local fullName = playerName .. " - " .. realmName
    
    -- Use the new module function to check professions
    CharacterManager_ProfessionCooldowns.CheckProfessionsAndSpells(characters, fullName)
    
    -- Save character data
    MyAddonDB = characters

end

local function SaveProfessionCooldowns()
    local playerName = UnitName("player")
    local realmName = GetRealmName()
    local fullName = playerName .. " - " .. realmName
    
    -- Use the new module function to save cooldowns
    CharacterManager_ProfessionCooldowns.SaveProfessionCooldowns(characters, fullName)
    
    MyAddonDB = characters
end

------------------------
---- Raids Tab
------------------------
local function GetRaidLockoutStatus(raidName)
    return _G.GetRaidLockoutStatus(raidName)
end

local function UpdateAllRaidStatuses()
    MyAddonDB = _G.UpdateAllRaidStatuses(characters)
        -- Update raid status overviews if the raids tab is currently shown
        if selectedTab == 3 and raidFrames then
            CharacterManager_RaidLockouts.UpdateAllRaidStatusOverviews(raidFrames)
        end
end

------------------------
---- Buffs Tab
------------------------

local function OnSpellCast(self, event, unit, _, spellID)
    if unit ~= "player" then return end
    
    local spellName = GetSpellInfo(spellID)
    if not spellName then return end
    
    local needsSave = false
    local fullName = UnitName("player") .. " - " .. GetRealmName()
    
    -- Check if it's a tracked profession cooldown
    local trackedSpellIDs = GetTrackedSpellIDs()
    for _, trackedSpellID in ipairs(trackedSpellIDs) do
        if spellID == trackedSpellID then
            print("Tracked profession spell cast detected:", spellName, "(ID:", spellID, ")") -- Debug output
            
            -- Use the new function to update cooldown data
            characters = CharacterManager_ProfessionCooldowns.OnSpellCast(characters, fullName, spellID)
            
            -- Update the UI
            UpdateProfessionCooldowns()
            needsSave = true
            break
        end
    end
    
    -- Check if it's a tracked buff
    for _, buffInfo in ipairs(trackedBuffs) do
        if buffInfo.spellID == spellID or buffInfo.name == spellName then
            print("Tracked buff spell cast detected:", spellName, "(ID:", spellID, ")") -- Debug output
            needsSave = true
            break
        end
    end
    
    -- Check if it's a Chronoboon use
    if spellID == 353220 then -- Chronoboon Displacer spell ID
        print("Chronoboon use detected") -- Debug output
        needsSave = true
    end
    
    -- Save character data if needed
    if needsSave then
        SaveCharacter()
        MyAddonDB = characters -- Ensure global DB is updated
    end
end

-- Function to create the settings tab content
local function CreateSettingsTabContent()
    -- Use the module function to create settings tab content
    CharacterManager_Settings.CreateSettingsTabContent(tabFrames)
end

-- First, define the original SaveCharacter function
function SaveCharacter()
    local playerName = UnitName("player")
    local realmName = GetRealmName()
    local fullName = playerName .. " - " .. realmName
    local _, class = UnitClass("player")
    local level = UnitLevel("player")

    if not characters[fullName] then
        characters[fullName] = { 
            name = playerName, 
            class = class, 
            level = level, 
            raidStatus = {} 
        }
    else
        characters[fullName].class = class  -- Update class in case of class change
        characters[fullName].level = level  -- Update level
        if not characters[fullName].raidStatus then
            characters[fullName].raidStatus = {}
        end
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
    characters[fullName].buffs = {}
    for _, buffInfo in ipairs(trackedBuffs) do
        for _, spellId in ipairs(buffInfo.spellIds) do
            local name, _, _, _, duration, expirationTime = AuraUtil.FindAuraByName(GetSpellInfo(spellId), "player")
            if name then
                characters[fullName].buffs[buffInfo.name] = {
                    status = "Active",
                    remainingTime = expirationTime - GetTime()
                }
                break
            end
        end
    end
    print("Character saved:", fullName)
    MyAddonDB = characters
    
    -- Add these lines to handle profession cooldowns directly in the main SaveCharacter function
    -- instead of trying to override it
    SaveProfessionCooldowns()
    CheckProfessionsAndSpells()
end

-- Update the ADDON_LOADED event handler
MyAddon:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and ... == "CharacterManager" then
        print("WoWCharacter Manager Loaded")
        
        -- Initialize settings if they don't exist
        if not WoWCharacterManagerSettings then
            WoWCharacterManagerSettings = {
                characters = {},
                defaultBuffs = {} -- Store default buff settings for new characters
            }
            
            -- Set default buff settings (all buffs enabled by default)
            for _, buffInfo in ipairs(trackedBuffs) do
                WoWCharacterManagerSettings.defaultBuffs[buffInfo.name] = true
            end
        end
        
        LoadCharacterData()
        CheckProfessionsAndSpells()
        UpdateProfessionCooldowns()
        UpdateAllRaidStatuses()
        CreateCooldownBars()
        InitializeSettings()
        
        -- Create settings tab content
        CreateSettingsTabContent()
        
    elseif event == "PLAYER_ENTERING_WORLD" or event == "RAID_INSTANCE_WELCOME" or event == "UPDATE_INSTANCE_INFO" then
        SaveCharacter()
        UpdateAllRaidStatuses()

        -- Update UI based on the selected tab
        if selectedTab == 2 then
            UpdateProfessionCooldowns()
        elseif selectedTab == 3 then
            if raidFrames then  -- Check if raidFrames exists
                for _, raidData in ipairs(raidFrames) do
                    if raidData.characters and raidData.characters:IsShown() then
                        raidData.populate(raidData.raidName)
                    end
                end
            end
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        OnSpellCast(self, event, ...)
    end

    -- Ensure MyAddonDB is always updated
    MyAddonDB = characters
end)

-- Register for necessary events
MyAddon:RegisterEvent("ADDON_LOADED")
MyAddon:RegisterEvent("PLAYER_ENTERING_WORLD")
MyAddon:RegisterEvent("RAID_INSTANCE_WELCOME")
MyAddon:RegisterEvent("UPDATE_INSTANCE_INFO")
MyAddon:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")


local tabWidth = 100
local tabHeight = 24
local tabSpacing = -5  -- Adjust spacing to fit nicely

-- Create Tabs
local tabs = {"To-dos", "Professions", "Raids", "Buffs", "Consumes", "Settings"}
local selectedTab = 2

-- Ensure tabFrames is defined
if not tabFrames then
    tabFrames = {}
end

local tabWidth = 120
local tabHeight = 32
local tabSpacing = 6

-- Create a container for the tabs on the left
local tabContainer = CreateFrame("Frame", nil, MyAddon)
tabContainer:SetPoint("TOPRIGHT", MyAddon, "TOPLEFT", -2, 0)
tabContainer:SetPoint("BOTTOMRIGHT", MyAddon, "BOTTOMLEFT", -2, 0)
tabContainer:SetWidth(tabWidth + 8)

-- Background for tab container
local tabBg = tabContainer:CreateTexture(nil, "BACKGROUND")
tabBg:SetAllPoints(tabContainer)
tabBg:SetColorTexture(0.1, 0.1, 0.1, 0.9) -- Dark semi-transparent background

for i, tabName in ipairs(tabs) do
    local tab = CreateFrame("Button", "MyAddonTab" .. i, tabContainer)
    tab:SetSize(tabWidth, tabHeight)
    
    -- Attach buttons vertically on the left
    if i == 1 then
        tab:SetPoint("TOPLEFT", tabContainer, "TOPLEFT", 5, -25)
    else
        tab:SetPoint("TOPLEFT", _G["MyAddonTab" .. (i-1)], "BOTTOMLEFT", 0, -tabSpacing)
    end

    -- Background for button (normal state)
    local tabBg = tab:CreateTexture(nil, "BACKGROUND")
    tabBg:SetAllPoints()
    tabBg:SetColorTexture(0.3, 0.3, 0.3, 0.8)  -- Default dark gray background
    tab.bg = tabBg

    -- Highlight frame (hover & selection effect)
    local highlight = tab:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(0.5, 0.1, 0.1, 0.9)-- Dark red
    tab:SetHighlightTexture(highlight)

    -- Button label
    local tabText = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tabText:SetPoint("CENTER")
    tabText:SetText(tabName)
    tab.text = tabText

    tab:SetScript("OnClick", function()
        selectedTab = i
        for j, frame in ipairs(tabFrames) do
            if frame then frame:Hide() end
        end
        if tabFrames[i] then
            tabFrames[i]:Show()
        end
        
        -- Update visual state of tabs
        for j=1, #tabs do
            local otherTab = _G["MyAddonTab" .. j]
            if j == i then
                otherTab.bg:SetColorTexture(0.8, 0.1, 0.1, 1) -- Selected tab (blue)
                otherTab.text:SetTextColor(1, 1, 1) -- White text
            else
                otherTab.bg:SetColorTexture(0.2, 0.2, 0.2, 1) -- Default gray
                otherTab.text:SetTextColor(0.8, 0.8, 0.8) -- Light gray text
            end
        end
        
        -- Trigger updates for specific tabs
        if i == 2 then  -- Professions tab
            UpdateProfessionCooldowns()
        elseif i == 3 then  -- Raids tab
            CharacterManager_RaidLockouts.UpdateAllRaidStatusOverviews(raidFrames)
            if raidFrames then
                for _, raidData in ipairs(raidFrames) do
                    if raidData.characters and raidData.characters:IsShown() then
                        raidData.populate(raidData.raidName)
                    end
                end
            end
        elseif i == 4 then  -- Buffs tab
            CharacterManager_BuffTracking.UpdateBuffDisplay(tabFrames, MyAddonDB, WoWCharacterManagerSettings)
        end
    end)

    -- Create tab content frames
    if not tabFrames[i] then
        tabFrames[i] = CreateFrame("Frame", nil, MyAddon)
        tabFrames[i]:SetPoint("TOPLEFT", MyAddon, "TOPLEFT", 128 - (tabWidth + 8), -10)  -- Shift left
        tabFrames[i]:SetPoint("BOTTOMRIGHT", MyAddon, "BOTTOMRIGHT", -10, 10)
        tabFrames[i]:Hide()
    end

    -- Set initial tab state
    if i == selectedTab then
        tab.bg:SetColorTexture(0.8, 0.1, 0.1, 1)  -- 
        tab.text:SetTextColor(1, 1, 1) -- White text
        tabFrames[i]:Show()
    else
        tab.bg:SetColorTexture(0.2, 0.2, 0.2, 1) -- Default gray
        tab.text:SetTextColor(0.8, 0.8, 0.8) -- Light gray text
    end
end


-- Keep the professionUpdateTimer
local professionUpdateTimer = CreateFrame("Frame")
professionUpdateTimer:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed >= 30 then  -- Update every second
        if selectedTab == 2 then
            UpdateProfessionCooldowns()
        end
        self.elapsed = 0
    end
end)
-- Create raid frames using the module function
-- Initialize raid frames with current phase setting
if CharacterManager_RaidLockouts then
    local currentPhase = WoWCharacterManagerSettings and WoWCharacterManagerSettings.currentPhase or 3
    print("CharacterManager: Initial raid frame creation for Phase " .. currentPhase)
    raidFrames = CharacterManager_RaidLockouts.CreateRaidFrames(tabFrames, raids, raidDisplayNames, currentPhase)
    CharacterManager_RaidLockouts.UpdateRaidFramesPosition(raidFrames, tabFrames)
end
-- Update raid frames position
CharacterManager_RaidLockouts.UpdateRaidFramesPosition(raidFrames, tabFrames)

local function UpdateDisplay()
    if selectedTab == 3 then
        for _, raidData in ipairs(raidFrames) do
            if raidData.characters:IsShown() then
                raidData.populate(raidData.raidName)
            end
        end
    end
end

local updateTimer = CreateFrame("Frame")
updateTimer:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed >= 60 then  -- Update every minute
        if selectedTab == 3 then
            for _, raidData in ipairs(raidFrames) do
                if raidData.characters:IsShown() then
                    raidData.populate(raidData.raidName)
                end
            end
        elseif selectedTab == 4 then
            CharacterManager_BuffTracking.UpdateBuffDisplay(tabFrames, MyAddonDB, WoWCharacterManagerSettings)
        end
        self.elapsed = 0
    end
end)


-- Minimap Button
-- Update the minimap button code to use settings:
local minimapButton = CreateFrame("Button", "MyAddonMinimapButton", Minimap)
minimapButton:SetSize(32, 32)
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
minimapButton:SetNormalTexture("Interface\\Icons\\spell_holy_holyguidance")
minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")
minimapButton:SetScript("OnClick", function()
    if MyAddon:IsShown() then
        MyAddon:Hide()
    else
        MyAddon:Show()
    end
end)

MyAddon:Show()
