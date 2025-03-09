-- BuffTracking.lua
CharacterManager_BuffTracking = {}

-- Local references to global data
local trackedBuffs = CharacterManager_TrackedBuffs
local CHRONOBOON_AURA_ID = CharacterManager_CHRONOBOON_AURA_ID
local collapsedCharacters = {}
local buffFrames = {}  -- Store dynamically created UI elements
local buffCheckboxes = {}
local buffSettingsContainer = nil
local buffSettingsDropdown = nil

-- Format time in minutes for display
local function FormatTimeMinutes(seconds)
    local minutes = math.floor(seconds / 60)
    return string.format("%d min", minutes)
end

-- Parse Chronoboon buff data
function CharacterManager_BuffTracking.ParseChronoboonSlots(unit)
    local boonData = {}
    if not UnitExists(unit) or not UnitIsConnected(unit) then
        return boonData
    end
    for i = 1, 40 do
        local buffName, _, _, _, _, _, _, _, _, spellId,
              _, _, _, _, _, _, v17,v18,v19,v20,v21,v22,v23,v24,v25,v26,v27,v28,v29
              = UnitBuff(unit, i)
        if not buffName then
            break
        end
        if spellId == CHRONOBOON_AURA_ID then
            boonData[17] = v17 or 0
            boonData[18] = v18 or 0
            boonData[19] = v19 or 0
            boonData[20] = v20 or 0
            boonData[21] = v21 or 0
            boonData[22] = v22 or 0
            boonData[23] = v23 or 0
            boonData[24] = v24 or 0
            boonData[25] = v25 or 0
            boonData[26] = v26 or 0
            boonData[27] = v27 or 0
            boonData[28] = v28 or 0
            boonData[29] = v29 or 0
            break
        end
    end
    return boonData
end

-- Show buff settings dropdown
function CharacterManager_BuffTracking.ShowBuffSettingsDropdown(fullName, anchor)
    if buffSettingsDropdown then
        buffSettingsDropdown:Hide()
    end
    
    buffSettingsDropdown = CreateFrame("Frame", "BuffSettingsDropdown", anchor, "BackdropTemplate")
    buffSettingsDropdown:SetSize(200, 250)
    buffSettingsDropdown:SetPoint("TOPLEFT", anchor, "BOTTOMRIGHT", 0, 0)
    buffSettingsDropdown:SetBackdrop({
        bgFile = "Interface\DialogFrame\UI-DialogBox-Background",
        edgeFile = "Interface\DialogFrame\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    buffSettingsDropdown.character = fullName
    
    -- Create container for buff checkboxes
    buffSettingsContainer = CreateFrame("Frame", nil, buffSettingsDropdown)
    buffSettingsContainer:SetSize(180, 200)
    buffSettingsContainer:SetPoint("TOP", 0, -20)
    
    -- Update buff settings for this character
    CharacterManager_BuffTracking.UpdateBuffSettings(fullName)
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, buffSettingsDropdown, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", buffSettingsDropdown, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function() buffSettingsDropdown:Hide() end)
end

-- Update buff settings in the settings tab
function CharacterManager_BuffTracking.UpdateBuffSettings(characterName)
    -- Clear existing checkboxes
    if buffCheckboxes then
        for _, checkbox in pairs(buffCheckboxes) do
            checkbox:Hide()
        end
    end
    buffCheckboxes = {}
    
    -- Initialize character settings if needed
    if not MyAddonSettings.characters[characterName] then
        MyAddonSettings.characters[characterName] = {
            trackedBuffs = {}
        }
        
        -- Copy default settings
        for buffName, enabled in pairs(MyAddonSettings.defaultBuffs) do
            MyAddonSettings.characters[characterName].trackedBuffs[buffName] = enabled
        end
    end
    
    -- Create buff tracking checkboxes
    local yOffset = 0
    for i, buffInfo in ipairs(trackedBuffs) do
        local buffName = buffInfo.name
        local checkbox = CreateFrame("CheckButton", nil, buffSettingsContainer, "UICheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", 0, yOffset)
        checkbox:SetSize(24, 24)
        
        local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        label:SetText(buffName)
        
        -- Set initial state
        local isEnabled = MyAddonSettings.characters[characterName].trackedBuffs[buffName]
        checkbox:SetChecked(isEnabled)
        
        -- Handle checkbox changes
        checkbox:SetScript("OnClick", function(self)
            local checked = self:GetChecked()
            MyAddonSettings.characters[characterName].trackedBuffs[buffName] = checked
        end)
        
        table.insert(buffCheckboxes, checkbox)
        yOffset = yOffset - 25
    end
    
    -- Add "Set as Default" button
    local defaultButton = CreateFrame("Button", nil, buffSettingsContainer, "UIPanelButtonTemplate")
    defaultButton:SetSize(150, 24)
    defaultButton:SetPoint("TOPLEFT", 0, yOffset - 20)
    defaultButton:SetText("Set as Default")
    defaultButton:SetScript("OnClick", function()
        -- Copy current character settings to default
        for _, buffInfo in ipairs(trackedBuffs) do
            local buffName = buffInfo.name
            MyAddonSettings.defaultBuffs[buffName] = MyAddonSettings.characters[characterName].trackedBuffs[buffName] or false
        end
        print("Default buff settings updated based on " .. characterName)
    end)
    
    -- Add "Apply to All" button
    local applyAllButton = CreateFrame("Button", nil, buffSettingsContainer, "UIPanelButtonTemplate")
    applyAllButton:SetSize(150, 24)
    applyAllButton:SetPoint("TOPLEFT", 0, yOffset - 50)
    applyAllButton:SetText("Apply to All")
    applyAllButton:SetScript("OnClick", function()
        -- Apply current character settings to all characters
        for charName, _ in pairs(MyAddonSettings.characters) do
            for _, buffInfo in ipairs(trackedBuffs) do
                local buffName = buffInfo.name
                MyAddonSettings.characters[charName].trackedBuffs[buffName] = 
                    MyAddonSettings.characters[characterName].trackedBuffs[buffName] or false
            end
        end
        print("Applied buff settings to all characters")
    end)
    
    table.insert(buffCheckboxes, defaultButton)
    table.insert(buffCheckboxes, applyAllButton)
end

-- Update buff display in the UI
function CharacterManager_BuffTracking.UpdateBuffDisplay(tabFrames, MyAddonDB, MyAddonSettings)
    local buffFrame = tabFrames[4]

    -- Clear old UI elements
    for _, frame in ipairs(buffFrames) do
        frame:Hide()
        frame:SetParent(nil)
    end
    buffFrames = {}

    local yOffset = -20  -- Start closer to the top for more compact layout
    local frameWidth = buffFrame:GetWidth()

    for fullName, charData in pairs(MyAddonDB) do
        -- Skip characters below level 55
        if not charData.level or charData.level < 55 then
            -- Skip this character
        else
            -- Default collapse state
            if collapsedCharacters[fullName] == nil then
                collapsedCharacters[fullName] = true
            end

            -- Initialize character settings if they don't exist
            if not MyAddonSettings.characters[fullName] then
                MyAddonSettings.characters[fullName] = {
                    trackedBuffs = {}
                }
                
                -- Copy default settings
                for buffName, isTracked in pairs(MyAddonSettings.defaultBuffs) do
                    MyAddonSettings.characters[fullName].trackedBuffs[buffName] = isTracked
                end
            end

            local isCollapsed = collapsedCharacters[fullName]

            -- Create character frame
            local characterFrame = CreateFrame("Frame", nil, buffFrame)
            characterFrame:SetSize(frameWidth - 20, 22)  -- Reduced height for compactness
            characterFrame:SetPoint("TOPLEFT", 10, yOffset)
            
            -- Create a standard button that stretches across the entire tab
            local characterButton = CreateFrame("Button", nil, characterFrame, "UIPanelButtonTemplate")
            characterButton:SetSize(frameWidth - 20, 22)  -- Full width
            characterButton:SetAllPoints(characterFrame)
            
            -- Extract just the character name from fullName
            local charName = charData.name or fullName:match("([^-]+)")
            
            -- Count active and tracked buffs
            local activeBuffs = 0
            local totalBuffs = 0
            
            -- Count active buffs among tracked ones
            if charData.buffs then
                for _, buffInfo in ipairs(trackedBuffs) do
                    -- Only count buffs that are tracked for this character
                    if MyAddonSettings.characters[fullName].trackedBuffs[buffInfo.name] then
                        totalBuffs = totalBuffs + 1
                        if charData.buffs[buffInfo.name] then
                            activeBuffs = activeBuffs + 1
                        else
                            -- Check chronoboon for this buff
                            local boonData = charData.chronoboon or {}
                            for _, slot in ipairs(buffInfo.boonSlots or {}) do
                                if boonData[slot] and boonData[slot] > 0 then
                                    activeBuffs = activeBuffs + 1
                                    break -- Count each buff only once
                                end
                            end
                        end
                    end
                end
            end
            
            -- Create class icon
            local classIcon = characterButton:CreateTexture(nil, "ARTWORK")
            classIcon:SetSize(16, 16)
            classIcon:SetPoint("LEFT", characterButton, "LEFT", 5, 0)
            
            -- Set class icon texture based on character's class
            if charData.class then
                local classTexture = "Interface\\TargetingFrame\\UI-Classes-Circles"
                local coords = CLASS_ICON_TCOORDS[charData.class]
                if coords then
                    classIcon:SetTexture(classTexture)
                    classIcon:SetTexCoord(unpack(coords))
                end
            end
            
            -- Create character name text centered on the button
            local nameText = characterButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameText:SetPoint("CENTER", 0, 0)
            nameText:SetText(charName .. " (" .. activeBuffs .. "/" .. totalBuffs .. ")")
            
            -- Create expand/collapse button on the right side
            local expandButton = CreateFrame("Button", nil, characterButton)
            expandButton:SetSize(16, 16)
            expandButton:SetPoint("RIGHT", characterButton, "RIGHT", -5, 0)
            expandButton:SetNormalFontObject("GameFontNormalLarge")
            
            -- Set the appropriate text based on collapsed state
            if collapsedCharacters[fullName] then
                expandButton:SetText("+")
            else
                expandButton:SetText("-")
            end
            
            -- Make the entire button clickable
            characterButton:SetScript("OnClick", function() 
                collapsedCharacters[fullName] = not collapsedCharacters[fullName]
                CharacterManager_BuffTracking.UpdateBuffDisplay(tabFrames, MyAddonDB, MyAddonSettings)
            end)

            table.insert(buffFrames, characterFrame)
            yOffset = yOffset - 24  -- Reduced spacing between character entries

            -- If not collapsed, show buff details
            if not isCollapsed then
                -- Create buff detail frame
                local buffDetailFrame = CreateFrame("Frame", nil, buffFrame)
                buffDetailFrame:SetSize(frameWidth - 40, 5)  -- Start with minimal height
                buffDetailFrame:SetPoint("TOPLEFT", 30, yOffset)
                
                local detailYOffset = 0
                local detailHeight = 0
                
                -- Add each tracked buff
                for _, buffInfo in ipairs(trackedBuffs) do
                    local buffName = buffInfo.name
                    
                    -- Only show buffs that are tracked for this character
                    if MyAddonSettings.characters[fullName].trackedBuffs[buffName] then
                        local isActive = false
                        local isInBoon = false
                        
                        -- Check if buff is active
                        if charData.buffs and charData.buffs[buffName] then
                            isActive = true
                        end
                        
                        -- Check if buff is in chronoboon
                        local boonData = charData.chronoboon or {}
                        for _, slot in ipairs(buffInfo.boonSlots or {}) do
                            if boonData[slot] and boonData[slot] > 0 then
                                isInBoon = true
                                break
                            end
                        end
                        
                        -- Create buff row
                        local buffRow = CreateFrame("Frame", nil, buffDetailFrame)
                        buffRow:SetSize(frameWidth - 50, 16)  -- Compact height
                        buffRow:SetPoint("TOPLEFT", 0, detailYOffset)
                        
                        -- Add buff icon
                        local buffIcon = buffRow:CreateTexture(nil, "ARTWORK")
                        buffIcon:SetSize(14, 14)  -- Small icon
                        buffIcon:SetPoint("LEFT", 0, 0)
                        
                        -- Set buff icon texture
                        if buffInfo.icon then
                            buffIcon:SetTexture(buffInfo.icon)
                        else
                            -- Try to get icon from game data
                            local _, _, icon = GetSpellInfo(buffInfo.spellId or 0)
                            if icon then
                                buffIcon:SetTexture(icon)
                            else
                                -- Fallback icon
                                buffIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                            end
                        end
                        
                        -- Create buff text with status
                        local statusText = buffRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                        statusText:SetPoint("LEFT", buffIcon, "RIGHT", 5, 0)
                        
                        local textColor = {r=1, g=0.5, b=0.5} -- Default: reddish (not active)
                        local statusString = "Missing"
                        
                        if isActive then
                            textColor = {r=0.5, g=1, b=0.5} -- Green for active
                            statusString = "Active"
                        elseif isInBoon then
                            textColor = {r=0.5, g=0.8, b=1} -- Blue for in chronoboon
                            statusString = "In Chronoboon"
                        end
                        
                        statusText:SetText(buffName .. ": " .. statusString)
                        statusText:SetTextColor(textColor.r, textColor.g, textColor.b)
                        
                        -- Add to detail frame height
                        detailYOffset = detailYOffset - 16
                        detailHeight = detailHeight + 16
                        
                        table.insert(buffFrames, buffRow)
                    end
                end
                
                -- Set final height of detail frame
                buffDetailFrame:SetHeight(detailHeight)
                table.insert(buffFrames, buffDetailFrame)
                
                -- Adjust yOffset for next character
                yOffset = yOffset - detailHeight - 5
            end
        end
    end
end

-- Track current player's buffs
function CharacterManager_BuffTracking.TrackCurrentPlayerBuffs(MyAddonDB)
    local playerName = UnitName("player")
    local realmName = GetRealmName()
    local fullName = playerName .. " - " .. realmName
    
    if not MyAddonDB[fullName] then
        return -- Character not found in database
    end
    
    -- Initialize buffs table if it doesn't exist
    if not MyAddonDB[fullName].buffs then
        MyAddonDB[fullName].buffs = {}
    end
    
    -- Check for each tracked buff
    for _, buffInfo in ipairs(trackedBuffs) do
        local found = false
        
        -- Check player buffs
        for i = 1, 40 do
            local name, icon, count, _, duration, expirationTime, source, _, _, spellId = UnitBuff("player", i)
            if not name then break end
            
            if name == buffInfo.name or spellId == buffInfo.id then
                MyAddonDB[fullName].buffs[buffInfo.name] = {
                    name = name,
                    icon = icon,
                    count = count,
                    duration = duration,
                    expirationTime = expirationTime,
                    source = source,
                    spellId = spellId,
                    lastUpdated = time()
                }
                found = true
                break
            end
        end
        
        -- If buff not found, mark it as not active
        if not found and MyAddonDB[fullName].buffs[buffInfo.name] then
            -- Only update if the buff was previously active
            MyAddonDB[fullName].buffs[buffInfo.name] = nil
        end
    end
    
    -- Check for Chronoboon Displacer buff
    local boonData = CharacterManager_BuffTracking.ParseChronoboonSlots("player")
    if next(boonData) then -- If boonData is not empty
        MyAddonDB[fullName].chronoboon = boonData
    end
    
    return MyAddonDB
end




-- Initialize buff tracking
function CharacterManager_BuffTracking.Initialize(trackedBuffsList, chronoboonAuraId)
    trackedBuffs = trackedBuffsList
    CHRONOBOON_AURA_ID = chronoboonAuraId
    
    -- Set up event handling for buff tracking
    local buffTrackingFrame = CreateFrame("Frame")
    buffTrackingFrame:RegisterEvent("UNIT_AURA")
    buffTrackingFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    buffTrackingFrame:SetScript("OnEvent", function(self, event, unit)
        if event == "UNIT_AURA" and unit == "player" then
            -- Update buff data when player buffs change
            MyAddonDB = CharacterManager_BuffTracking.TrackCurrentPlayerBuffs(MyAddonDB)
        elseif event == "PLAYER_ENTERING_WORLD" then
            -- Initial buff scan when logging in
            MyAddonDB = CharacterManager_BuffTracking.TrackCurrentPlayerBuffs(MyAddonDB)
        end
    end)
    
    return buffTrackingFrame
end

-- Return the module
return CharacterManager_BuffTracking