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

local tabWidth = 120
local tabHeight = 32
local tabSpacing = 6
local selectedTab = 2  -- Default to Professions tab

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

local function UpdateProfessionCooldowns()
    -- Use the module function to update cooldown bars
    CharacterManager_ProfessionCooldowns.UpdateProfessionCooldowns(cooldownBars, MyAddonDB, cooldownDebugText)
end


local function UpdateUIBasedOnSelectedTab()
    if selectedTab == 2 then
        UpdateProfessionCooldowns()
    elseif selectedTab == 3 and raidFrames then
        for _, raidData in ipairs(raidFrames) do
            if raidData.characters and raidData.characters:IsShown() then
                raidData.populate(raidData.raidName)
            end
        end
    elseif selectedTab == 4 then
        CharacterManager_BuffTracking.UpdateBuffDisplay(tabFrames, MyAddonDB, WoWCharacterManagerSettings)
    end
end

local function SetTabState(tab, isSelected)
    if isSelected then
        tab.bg:SetColorTexture(0.8, 0.1, 0.1, 1)
        tab.text:SetTextColor(1, 1, 1)
    else
        tab.bg:SetColorTexture(0.2, 0.2, 0.2, 1)
        tab.text:SetTextColor(0.8, 0.8, 0.8)
    end
end
local function SelectTab(index)
    selectedTab = index
    for i, frame in ipairs(tabFrames) do
        if frame then frame:Hide() end
        SetTabState(_G["MyAddonTab" .. i], i == index)
    end
    if tabFrames[index] then
        tabFrames[index]:Show()
    end

    -- Handle raid frames visibility
    if index == 3 then  -- Raids tab
        if _G.raidFrames then
            for _, raidData in ipairs(_G.raidFrames) do
                if raidData.frame then
                    raidData.frame:Show()
                end
            end
            CharacterManager_RaidLockouts.UpdateRaidFramesPosition(_G.raidFrames, tabFrames)
            CharacterManager_RaidLockouts.UpdateAllRaidStatusOverviews(_G.raidFrames)
        else
            -- Recreate raid frames if they don't exist
            CharacterManager_RaidLockouts.RecreateRaidFrames(tabFrames, WoWCharacterManagerSettings, true)
        end
    else
        -- Hide raid frames when not on the Raids tab
        if _G.raidFrames then
            for _, raidData in ipairs(_G.raidFrames) do
                if raidData.frame then
                    raidData.frame:Hide()
                end
                if raidData.characters then
                    raidData.characters:Hide()
                end
            end
        end
    end

    UpdateUIBasedOnSelectedTab()
end

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

local function CheckProfessionsAndSpells()
    local playerName = UnitName("player")
    local realmName = GetRealmName()
    local fullName = playerName .. " - " .. realmName
    
    -- Initialize the characters table if it's nil
    if not characters then
        characters = {}
    end

    -- Use the new module function to check professions
    CharacterManager_ProfessionCooldowns.CheckProfessionsAndSpells(characters, fullName)
    
    -- Save character data
    MyAddonDB = characters

end

local function UpdateCooldowns()
    local playerName = UnitName("player")
    local realmName = GetRealmName()
    local fullName = playerName .. " - " .. realmName
        -- Initialize the characters table if it's nil
        if not characters then
            characters = {}
        end
    
    -- Use the new module function to save cooldowns
    CharacterManager_ProfessionCooldowns.UpdateCooldowns(characters, fullName)
    
    MyAddonDB = characters
end

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
    
    UpdateCooldowns()
    CheckProfessionsAndSpells()
end

local function GetTrackedSpellIDs()
    return CharacterManager_ProfessionCooldowns.GetTrackedSpellIDs()
end

local function CreateCooldownBars()
    -- Use the module function to create cooldown bars
    cooldownBars, cooldownDebugText = CharacterManager_ProfessionCooldowns.CreateCooldownBars(tabFrames[2])
end

local function FormatTimeMinutes(seconds)
    local minutes = math.floor(seconds / 60)
    return string.format("%d min", minutes)
end

local function InitializeAddon()
    -- Initialize buff tracking module
    local buffTrackingFrame = CharacterManager_BuffTracking.Initialize(CharacterManager_TrackedBuffs, CharacterManager_CHRONOBOON_AURA_ID)
    
    -- Load character data
    LoadCharacterData()
    
    -- Initialize or load settings
    if not WoWCharacterManagerSettings then
        WoWCharacterManagerSettings = {
            currentPhase = 3,  -- Default to Phase 3
            characters = {},
            defaultBuffs = {}
        }
        -- Set default buff settings (all buffs enabled by default)
        for _, buffInfo in ipairs(trackedBuffs) do
            WoWCharacterManagerSettings.defaultBuffs[buffInfo.name] = true
        end
        print("CharacterManager: Created new settings with default Phase 3")
    else
        -- Ensure currentPhase exists
        WoWCharacterManagerSettings.currentPhase = WoWCharacterManagerSettings.currentPhase or 3
        print("CharacterManager: Loaded existing settings with Phase " .. WoWCharacterManagerSettings.currentPhase)
    end

    -- Initialize other components
    CheckProfessionsAndSpells()
    UpdateProfessionCooldowns()
    UpdateAllRaidStatuses()
    CreateCooldownBars()

    -- Initialize raid frames with the current phase setting
    if CharacterManager_RaidLockouts then
        local currentPhase = WoWCharacterManagerSettings.currentPhase
        print("CharacterManager: Creating raid frames for Phase " .. currentPhase)
        raidFrames = CharacterManager_RaidLockouts.CreateRaidFrames(tabFrames, raids, raidDisplayNames, currentPhase)
        CharacterManager_RaidLockouts.UpdateRaidFramesPosition(raidFrames, tabFrames)
    end

    if CharacterManager_Settings and CharacterManager_Settings.CreateSettingsTabContent then
        CharacterManager_Settings.CreateSettingsTabContent(tabFrames)
    end
end

local function InitializeSettings()
    -- Nothing to initialize yet, but we'll keep this function for future use
end


local function OnAddonLoaded()
    print("WoWCharacter Manager Loaded")
    InitializeAddon()
end

local function OnPlayerEnteringWorld()
    SaveCharacter()
    UpdateAllRaidStatuses()
    UpdateUIBasedOnSelectedTab()
end


------------------------
---- To-dos Tab
------------------------

------------------------
---- Professions Tab
------------------------

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



MyAddon:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and ... == "CharacterManager" then
        OnAddonLoaded()
    elseif event == "PLAYER_ENTERING_WORLD" or event == "RAID_INSTANCE_WELCOME" or event == "UPDATE_INSTANCE_INFO" then
        OnPlayerEnteringWorld()
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


-- Create a container for the tabs on the left
local tabContainer = CreateFrame("Frame", nil, MyAddon)
tabContainer:SetPoint("TOPRIGHT", MyAddon, "TOPLEFT", -2, 0)
tabContainer:SetPoint("BOTTOMRIGHT", MyAddon, "BOTTOMLEFT", -2, 0)
tabContainer:SetWidth(tabWidth + 8)

-- Background for tab container
local tabBg = tabContainer:CreateTexture(nil, "BACKGROUND")
tabBg:SetAllPoints(tabContainer)
tabBg:SetColorTexture(0.1, 0.1, 0.1, 0.9) -- Dark semi-transparent background

local function CreateTabs()
    local tabs = {"To-dos", "Professions", "Raids", "Buffs", "Consumes", "Settings"}

    for i, tabName in ipairs(tabs) do
        local tab = CreateFrame("Button", "MyAddonTab" .. i, tabContainer)
        tab:SetSize(tabWidth, tabHeight)
        
        if i == 1 then
            tab:SetPoint("TOPLEFT", tabContainer, "TOPLEFT", 5, -25)
        else
            tab:SetPoint("TOPLEFT", _G["MyAddonTab" .. (i-1)], "BOTTOMLEFT", 0, -tabSpacing)
        end

        local tabBg = tab:CreateTexture(nil, "BACKGROUND")
        tabBg:SetAllPoints()
        tabBg:SetColorTexture(0.3, 0.3, 0.3, 0.8)
        tab.bg = tabBg

        local highlight = tab:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetColorTexture(0.5, 0.1, 0.1, 0.9)
        tab:SetHighlightTexture(highlight)

        local tabText = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        tabText:SetPoint("CENTER")
        tabText:SetText(tabName)
        tab.text = tabText

        tab:SetScript("OnClick", function()
            SelectTab(i)
        end)

        if not tabFrames[i] then
            tabFrames[i] = CreateFrame("Frame", nil, MyAddon)
            tabFrames[i]:SetPoint("TOPLEFT", MyAddon, "TOPLEFT", 128 - (tabWidth + 8), -10)
            tabFrames[i]:SetPoint("BOTTOMRIGHT", MyAddon, "BOTTOMRIGHT", -10, 10)
            tabFrames[i]:Hide()
        end

        SetTabState(tab, i == selectedTab)
    end
end


local function CreateUpdateTimer()
    local updateTimer = CreateFrame("Frame")
    updateTimer:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed >= 30 then  -- Update every 30 seconds
            UpdateUIBasedOnSelectedTab()
            self.elapsed = 0
        end
    end)
end


local function UpdateDisplay()
    if selectedTab == 3 then
        for _, raidData in ipairs(raidFrames) do
            if raidData.characters:IsShown() then
                raidData.populate(raidData.raidName)
            end
        end
    end
end


CreateTabs()
CreateUpdateTimer()



-- Set up the initial tab
if _G["MyAddonTab" .. selectedTab] then
    _G["MyAddonTab" .. selectedTab]:Click()
end

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
