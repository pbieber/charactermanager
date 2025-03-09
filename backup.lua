-- Function to create cooldown bars in the UI
function CreateCooldownBars(tabFrame)
    local cooldownBars = {}
    local barWidth = 380
    local barHeight = 20
    local yOffset = -30

    for i = 1, 5 do  -- Create 5 bars initially
        local bar = CreateFrame("StatusBar", nil, tabFrame)
        bar:SetSize(barWidth, barHeight)
        bar:SetPoint("TOPLEFT", tabFrame, "TOPLEFT", 10, yOffset)
        bar:SetStatusBarTexture("Interface\TargetingFrame\UI-StatusBar")
        bar:SetStatusBarColor(0, 0.7, 0.3)
        bar:Hide()

        bar.bg = bar:CreateTexture(nil, "BACKGROUND")
        bar.bg:SetAllPoints(true)
        bar.bg:SetTexture("Interface\TargetingFrame\UI-StatusBar")
        bar.bg:SetVertexColor(0.5, 0.5, 0.5, 0.3)

        bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        bar.text:SetPoint("LEFT", bar, "LEFT", 5, 0)
        bar.text:SetJustifyH("LEFT")

        bar.timeText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        bar.timeText:SetPoint("RIGHT", bar, "RIGHT", -5, 0)
        bar.timeText:SetJustifyH("RIGHT")

        cooldownBars[i] = bar
        yOffset = yOffset - (barHeight + 5)
    end
    
    return cooldownBars
end


-- Define spells to track
local SpellsToTrack = {
    Tailoring = {
        {id = 18560, name = "Mooncloth"}
    },
    Leatherworking = {
        {id = 19566, name = "Salt Shaker"}
    },
    Alchemy = {
        {id = 17187, name = "Transmute: Arcanite"},
        {id = 17559, name = "Transmute: Air to Fire"},
        {id = 17560, name = "Transmute: Fire to Earth"},
        {id = 17561, name = "Transmute: Earth to Water"},
        {id = 17562, name = "Transmute: Water to Air"},
        {id = 17563, name = "Transmute: Undeath to Water"},
        {id = 17564, name = "Transmute: Water to Undeath"},
        {id = 17565, name = "Transmute: Life to Earth"},
        {id = 17566, name = "Transmute: Earth to Life"}
    }
}

-- Tracked profession cooldowns
CharacterManager_TrackedProfessionCooldowns = {
    -- Alchemy
    {
        name = "Transmute",
        spellIDs = {11479, 11480, 17559, 17560, 17561, 17562, 17563, 17564, 17565, 17566, 25146},
        cooldown = 86400 -- 24 hours
    },
    -- Tailoring
    {
        name = "Mooncloth",
        spellIDs = {18560},
        cooldown = 259200 -- 3 days
    },
    -- Leatherworking
    {
        name = "Salt Shaker",
        spellIDs = {19566},
        cooldown = 86400 -- 24 hours
    },
    -- Add other profession cooldowns as needed
    -- TBC Spells {36686,31373,26751,28580,28581,28582, 28583, 28584, 28585, 28567, 28568, 28569, 28028,28027,29688}
}




local buffFrames = {}  -- Store dynamically created UI elements

local function ParseChronoboonSlots(unit)
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

local function UpdateBuffDisplay()
    print("UpdateBuffDisplay started") -- Debug print

    local buffFrame = tabFrames[4]

    -- Clear old UI elements
    for _, frame in ipairs(buffFrames) do
        frame:Hide()
        frame:SetParent(nil) -- Completely remove from UI hierarchy
    end
    buffFrames = {}  -- Reset storage

    local yOffset = -30
    local frameWidth = buffFrame:GetWidth()

    for fullName, charData in pairs(MyAddonDB) do
        -- Skip characters below level 55
        if not charData.level or charData.level < 55 then
            -- Skip this character
            print("Skipping character " .. fullName .. " with level " .. (charData.level or "unknown"))
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
                -- Apply default buff settings for new character
                for buffName, isTracked in pairs(MyAddonSettings.defaultBuffs) do
                    MyAddonSettings.characters[fullName].trackedBuffs[buffName] = isTracked
                end
            end

            local isCollapsed = collapsedCharacters[fullName]

            -- Create character button
            local characterButton = CreateFrame("Button", nil, buffFrame, "UIPanelButtonTemplate")
            characterButton:SetSize(frameWidth - 20, 24)
            characterButton:SetPoint("TOPLEFT", 10, yOffset)
            
            -- Create class icon
            local classIcon = characterButton:CreateTexture(nil, "ARTWORK")
            classIcon:SetSize(18, 18)
            classIcon:SetPoint("LEFT", characterButton, "LEFT", 135, 0)
            
            -- Set class icon texture based on character's class
            if charData.class then
                local classTexture = "Interface\\TargetingFrame\\UI-Classes-Circles"
                local coords = CLASS_ICON_TCOORDS[charData.class]
                if coords then
                    classIcon:SetTexture(classTexture)
                    classIcon:SetTexCoord(unpack(coords))
                end
            end
            
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
                            for _, slot in ipairs(buffInfo.boonSlots) do
                                if boonData[slot] and boonData[slot] > 0 then
                                    activeBuffs = activeBuffs + 1
                                    break -- Count each buff only once
                                end
                            end
                        end
                    end
                end
            end
            
            -- Extract just the character name from fullName
            local charName = string.match(fullName, "(.+) %- ")
            
            -- Create text label and position it relative to the icon
            local nameText = characterButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameText:SetPoint("LEFT", classIcon, "RIGHT", 10, 0)  -- Position text 10px to the right of the icon
            nameText:SetText(charName .. "  " .. activeBuffs .. "/" .. totalBuffs)
            
            -- Clear the button's text since we're using our own text element
            characterButton:SetText("")

            -- Create settings button for this character
            local settingsButton = CreateFrame("Button", nil, characterButton)
            settingsButton:SetSize(16, 16)
            settingsButton:SetPoint("RIGHT", characterButton, "RIGHT", -5, 0)
            
            local settingsTexture = settingsButton:CreateTexture(nil, "ARTWORK")
            settingsTexture:SetAllPoints()
            settingsTexture:SetTexture("Interface\\Buttons\\UI-OptionsButton")
            
            settingsButton:SetScript("OnClick", function()
                -- Toggle settings dropdown for this character
                if buffSettingsDropdown and buffSettingsDropdown:IsShown() and buffSettingsDropdown.character == fullName then
                    buffSettingsDropdown:Hide()
                else
                    ShowBuffSettingsDropdown(fullName, settingsButton)
                end
            end)

            table.insert(buffFrames, characterButton)
            table.insert(buffFrames, settingsButton)

            characterButton:SetScript("OnClick", function()
                collapsedCharacters[fullName] = not isCollapsed
                UpdateBuffDisplay() -- Refresh UI properly
            end)

            yOffset = yOffset - 30

            -- If expanded, show buffs
            if not isCollapsed then
                local boonData = charData.chronoboon or {}
                local hasAnyBuff = false

                for _, buffInfo in ipairs(trackedBuffs) do
                    -- Only show buffs that are tracked for this character
                    if MyAddonSettings.characters[fullName].trackedBuffs[buffInfo.name] then
                        local buffText = buffFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                        buffText:SetPoint("TOPLEFT", 40, yOffset)  -- Indented for readability
                        buffText:SetWidth(frameWidth - 60)
                        buffText:SetJustifyH("LEFT")  -- Ensure left alignment

                        local buffStatus = "Not Active"
                        local remainingTime = 0
                        local textColor = "|cffff0000"  -- Default red (inactive)

                        -- Check for active buff
                        if charData.buffs and charData.buffs[buffInfo.name] then
                            buffStatus = charData.buffs[buffInfo.name].status
                            remainingTime = charData.buffs[buffInfo.name].remainingTime
                            textColor = "|cff00ff00"  -- Green (active)
                            hasAnyBuff = true
                        end

                        -- Check Chronoboon status if not active
                        local chronoboonActive = false
                        local chronoboonRemaining = 0
                        if buffStatus == "Not Active" then
                            for _, slot in ipairs(buffInfo.boonSlots) do
                                if boonData[slot] and boonData[slot] > 0 then
                                    chronoboonActive = true
                                    chronoboonRemaining = boonData[slot]
                                    buffStatus = FormatTimeMinutes(chronoboonRemaining)  -- Just show the time remaining
                                    textColor = "|cff00ff00"  -- Green for Chronoboon stored buffs too
                                    hasAnyBuff = true
                                    break
                                end
                            end
                        end

                        -- Format remaining time
                        local timeString = remainingTime > 0 and (" (" .. FormatTimeMinutes(remainingTime) .. ")") or ""

                        -- Set text without bullet point
                        buffText:SetText(textColor .. buffInfo.name .. ": " .. buffStatus .. timeString .. "|r")
                        table.insert(buffFrames, buffText)
                        yOffset = yOffset - 20

                        -- Add Chronoboon icon if applicable
                        if chronoboonActive then
                            local boonIcon = buffFrame:CreateTexture(nil, "OVERLAY")
                            boonIcon:SetSize(16, 16)
                            boonIcon:SetPoint("RIGHT", buffText, "LEFT", -3, 0)  -- Position icon before the time text
                            boonIcon:SetTexture("Interface\\Icons\\inv_misc_enggizmos_24")  -- Updated Chronoboon icon
                            table.insert(buffFrames, boonIcon)
                        end
                    end
                end

                yOffset = yOffset - 10  -- Extra spacing between characters
            end
        end
    end

    buffFrame:SetHeight(math.abs(yOffset) + 20)
    print("UpdateBuffDisplay finished") -- Debug print
end


-- Function to update buff settings in the settings tab
local function UpdateBuffSettings(characterName)
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
    applyAllButton:SetPoint("LEFT", defaultButton, "RIGHT", 10, 0)
    applyAllButton:SetText("Apply to All Characters")
    applyAllButton:SetScript("OnClick", function()
        -- Apply current character settings to all characters
        for charName, _ in pairs(MyAddonDB) do
            if not MyAddonSettings.characters[charName] then
                MyAddonSettings.characters[charName] = { trackedBuffs = {} }
            end
            
            for _, buffInfo in ipairs(trackedBuffs) do
                local buffName = buffInfo.name
                MyAddonSettings.characters[charName].trackedBuffs[buffName] = 
                    MyAddonSettings.characters[characterName].trackedBuffs[buffName]
            end
        end
        print("Applied buff settings from " .. characterName .. " to all characters")
    end)
end