local CM = CharacterManager

-- Initialize buff tracking
function CM.InitBuffTracking()
    -- Initialize default buff settings if needed
    if not MyAddonSettings.defaultBuffs then
        MyAddonSettings.defaultBuffs = {}
        for _, buffInfo in ipairs(CM.trackedBuffs) do
            MyAddonSettings.defaultBuffs[buffInfo.name] = true
        end
    end
end

-- Check player buffs and update data
function CM.CheckBuffs()
    local fullName = CM.GetFullCharacterName()
    
    -- Initialize character data if needed
    if not MyAddonDB[fullName] then
        MyAddonDB[fullName] = {
            class = select(2, UnitClass("player")),
            level = UnitLevel("player"),
            buffs = {},
            chronoboon = {}
        }
    end
    
    -- Initialize character settings if needed
    if not MyAddonSettings.characters[fullName] then
        MyAddonSettings.characters[fullName] = {
            trackedBuffs = {}
        }
        
        -- Copy default settings
        for buffName, enabled in pairs(MyAddonSettings.defaultBuffs) do
            MyAddonSettings.characters[fullName].trackedBuffs[buffName] = enabled
        end
    end
    
    -- Update character data
    MyAddonDB[fullName].class = select(2, UnitClass("player"))
    MyAddonDB[fullName].level = UnitLevel("player")
    
    -- Check buffs
    local buffs = {}
    for i = 1, 40 do
        local name, icon, count, debuffType, duration, expirationTime = UnitBuff("player", i)
        if not name then break end
        
        -- Check if this is a tracked buff
        for _, buffInfo in ipairs(CM.trackedBuffs) do
            if name == buffInfo.name then
                local remainingTime = expirationTime - GetTime()
                buffs[name] = {
                    icon = icon,
                    count = count,
                    duration = duration,
                    expirationTime = expirationTime,
                    remainingTime = remainingTime,
                    status = CM.FormatTimeMinutes(remainingTime)
                }
                break
            end
        end
    end
    
    -- Update character's buffs
    MyAddonDB[fullName].buffs = buffs
    
    -- Update UI if it's open
    if CM.buffFrame and CM.buffFrame:IsShown() then
        CM.UpdateBuffDisplay()
    end
end

-- Check Chronoboon Displacer buffs
function CM.CheckChronoboonBuffs()
    local fullName = CM.GetFullCharacterName()
    
    -- Initialize character data if needed
    if not MyAddonDB[fullName] then
        MyAddonDB[fullName] = {
            class = select(2, UnitClass("player")),
            level = UnitLevel("player"),
            buffs = {},
            chronoboon = {}
        }
    end
    
    -- Check for Chronoboon Displacer in bags
    local chronoboonData = {}
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemID = GetContainerItemID(bag, slot)
            if itemID == 184937 then -- Chronoboon Displacer
                local itemLink = GetContainerItemLink(bag, slot)
                -- Check if it has stored buffs
                if itemLink and itemLink:find("item:184937") then
                    local tooltipData = {}
                    
                    -- Use tooltip scanning to get stored buff info
                    CM.scanTooltip = CM.scanTooltip or CreateFrame("GameTooltip", "CMScanTooltip", nil, "GameTooltipTemplate")
                    local tooltip = CM.scanTooltip
                    tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
                    tooltip:SetBagItem(bag, slot)
                    
                    local storedBuffs = {}
                    for i = 1, tooltip:NumLines() do
                        local line = _G["CMScanTooltipTextLeft" .. i]:GetText()
                        if line then
                            -- Look for buff names in tooltip
                            for _, buffInfo in ipairs(CM.trackedBuffs) do
                                if line:find(buffInfo.name) then
                                    -- Extract time if possible
                                    local timeStr = line:match("%((.+)%)")
                                    storedBuffs[buffInfo.name] = {
                                        name = buffInfo.name,
                                        timeText = timeStr or "Unknown"
                                    }
                                    break
                                end
                            end
                        end
                    end
                    
                    if next(storedBuffs) then
                        table.insert(chronoboonData, {
                            bag = bag,
                            slot = slot,
                            link = itemLink,
                            buffs = storedBuffs
                        })
                    end
                    
                    tooltip:Hide()
                end
            end
        end
    end
    
    -- Update character's chronoboon data
    MyAddonDB[fullName].chronoboon = chronoboonData
    
    -- Update UI if it's open
    if CM.buffFrame and CM.buffFrame:IsShown() then
        CM.UpdateBuffDisplay()
    end
end

-- Save character buff data
function CM.SaveBuffData()
    local fullName = CM.GetFullCharacterName()
    
    -- Check buffs
    CM.CheckBuffs()
    
    -- Check Chronoboon Displacers
    CM.CheckChronoboonBuffs()
    
    -- Update last seen time
    if not MyAddonDB[fullName] then
        MyAddonDB[fullName] = {}
    end
    
    MyAddonDB[fullName].lastSeen = time()
end

-- Handle spell cast for buff tracking
function CM.OnBuffSpellCast(unit, _, spellID)
    if unit ~= "player" then return end
    
    local spellName = GetSpellInfo(spellID)
    if not spellName then return end
    
    -- Check if it's a tracked buff
    local isTrackedBuff = false
    for _, buffInfo in ipairs(CM.trackedBuffs) do
        if buffInfo.spellID == spellID or buffInfo.name == spellName then
            isTrackedBuff = true
            break
        end
    end
    
    -- Check if it's a Chronoboon use
    if spellID == 353220 then -- Chronoboon Displacer spell ID
        isTrackedBuff = true
    end
    
    -- Save character data if needed
    if isTrackedBuff then
        CM.SaveBuffData()
    end
end

-- Update buff display in the UI
function CM.UpdateBuffDisplay()
    if not CM.buffFrame then return end
    
    -- Clear existing buff frames
    if CM.buffFrames then
        for _, frame in ipairs(CM.buffFrames) do
            frame:Hide()
        end
    end
    CM.buffFrames = {}
    
    local yOffset = -10
    
    -- Sort characters by name
    local characters = {}
    for name, data in pairs(MyAddonDB) do
        table.insert(characters, {name = name, data = data})
    end
    table.sort(characters, function(a, b) return a.name < b.name end)
    
    -- Display each character's buffs
    for _, charInfo in ipairs(characters) do
        local name = charInfo.name
        local data = charInfo.data
        
        -- Extract character name without realm if it's the same realm
        local displayName = name
        local currentRealm = "-" .. GetRealmName()
        if name:find(currentRealm) then
            displayName = name:gsub(currentRealm, "")
        end
        
        -- Character header
        local headerFrame = CreateFrame("Frame", nil, CM.buffFrame)
        headerFrame:SetSize(CM.buffFrame:GetWidth() - 20, 20)
        headerFrame:SetPoint("TOPLEFT", CM.buffFrame, "TOPLEFT", 10, yOffset)
        
        local classColor = RAID_CLASS_COLORS[data.class] or RAID_CLASS_COLORS["WARRIOR"]
        local headerText = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        headerText:SetPoint("LEFT", 25, 0)
        headerText:SetText(displayName)
        headerText:SetTextColor(classColor.r, classColor.g, classColor.b)
        
        -- Class icon
        local classIcon = headerFrame:CreateTexture(nil, "OVERLAY")
        classIcon:SetSize(18, 18)
        classIcon:SetPoint("LEFT", 0, 0)
        classIcon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
        
        -- Set class icon texture coordinates
        if CM.CLASS_ICON_TCOORDS[data.class] then
            classIcon:SetTexCoord(unpack(CM.CLASS_ICON_TCOORDS[data.class]))
        end
        
        -- Settings button
        local settingsButton = CreateFrame("Button", nil, headerFrame)
        settingsButton:SetSize(16, 16)
        settingsButton:SetPoint("RIGHT", 0, 0)
        settingsButton:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
        settingsButton:SetHighlightTexture("Interface\\Buttons\\UI-OptionsButton", "ADD")
        settingsButton:SetScript("OnClick", function()
            CM.ShowBuffSettingsDropdown(name, headerFrame)
        end)
        
        table.insert(CM.buffFrames, headerFrame)
        table.insert(CM.buffFrames, classIcon)
        table.insert(CM.buffFrames, headerText)
        table.insert(CM.buffFrames, settingsButton)
        
        yOffset = yOffset - 25
        
        -- Check if we should display this character's buffs
        local shouldDisplay = true
        
        if shouldDisplay then
            -- Display buffs
            local hasBuffs = false
            
            -- Check if character has settings
            if not MyAddonSettings.characters[name] then
                MyAddonSettings.characters[name] = {
                    trackedBuffs = {}
                }
                
                -- Copy default settings
                for buffName, enabled in pairs(MyAddonSettings.defaultBuffs) do
                    MyAddonSettings.characters[name].trackedBuffs[buffName] = enabled
                end
            end
            
            -- Display active buffs
            for _, buffInfo in ipairs(CM.trackedBuffs) do
                local buffName = buffInfo.name
                
                -- Check if this buff should be tracked for this character
                if MyAddonSettings.characters[name].trackedBuffs[buffName] ~= false then
                    local buffData = data.buffs and data.buffs[buffName]
                    
                    -- Create buff frame
                    local buffFrame = CreateFrame("Frame", nil, CM.buffFrame)
                    buffFrame:SetSize(CM.buffFrame:GetWidth() - 40, 20)
                    buffFrame:SetPoint("TOPLEFT", CM.buffFrame, "TOPLEFT", 30, yOffset)
                    
                    -- Buff name
                    local nameText = buffFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    nameText:SetPoint("LEFT", 0, 0)
                    nameText:SetText(buffName)
                    
                    -- Buff status
                    local buffText = buffFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    buffText:SetPoint("RIGHT", 0, 0)
                    
                    if buffData then
                        buffText:SetText(buffData.status)
                        hasBuffs = true
                    else
                        buffText:SetText("Not Active")
                        buffText:SetTextColor(0.5, 0.5, 0.5)
                    end
                    
                    table.insert(CM.buffFrames, buffFrame)
                    table.insert(CM.buffFrames, nameText)
                    table.insert(CM.buffFrames, buffText)
                    
                    yOffset = yOffset - 20
                end
            end
            
            -- Display Chronoboon buffs if any
            if data.chronoboon and #data.chronoboon > 0 then
                for i, chronoboon in ipairs(data.chronoboon) do
                    -- Chronoboon header
                    local cbHeader = CreateFrame("Frame", nil, CM.buffFrame)
                    cbHeader:SetSize(CM.buffFrame:GetWidth() - 40, 20)
                    cbHeader:SetPoint("TOPLEFT", CM.buffFrame, "TOPLEFT", 30, yOffset)
                    
                    local cbText = cbHeader:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    cbText:SetPoint("LEFT", 0, 0)
                    cbText:SetText("Chronoboon Displacer #" .. i)
                    cbText:SetTextColor(0.95, 0.95, 0.32)
                    
                    table.insert(CM.buffFrames, cbHeader)
                    table.insert(CM.buffFrames, cbText)
                    
                    yOffset = yOffset - 20
                    
                    -- Display stored buffs
                    for buffName, buffData in pairs(chronoboon.buffs) do
                        -- Check if this buff should be tracked for this character
                        if MyAddonSettings.characters[name].trackedBuffs[buffName] ~= false then
                            local cbBuffFrame = CreateFrame("Frame", nil, CM.buffFrame)
                            cbBuffFrame:SetSize(CM.buffFrame:GetWidth() - 60, 20)
                            cbBuffFrame:SetPoint("TOPLEFT", CM.buffFrame, "TOPLEFT", 50, yOffset)
                            
                            local cbBuffName = cbBuffFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                            cbBuffName:SetPoint("LEFT", 0, 0)
                            cbBuffName:SetText(buffName)
                            
                            local cbBuffTime = cbBuffFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                            cbBuffTime:SetPoint("RIGHT", 0, 0)
                            cbBuffTime:SetText(buffData.timeText or "")
                            
                            table.insert(CM.buffFrames, cbBuffFrame)
                            table.insert(CM.buffFrames, cbBuffName)
                            table.insert(CM.buffFrames, cbBuffTime)
                            
                            yOffset = yOffset - 20
                            hasBuffs = true
                        end
                    end
                end
            end
            
            -- If no buffs were displayed, show a message
            if not hasBuffs then
                local noBuffsFrame = CreateFrame("Frame", nil, CM.buffFrame)
                noBuffsFrame:SetSize(CM.buffFrame:GetWidth() - 40, 20)
                noBuffsFrame:SetPoint("TOPLEFT", CM.buffFrame, "TOPLEFT", 30, yOffset)
                
                local noBuffsText = noBuffsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                noBuffsText:SetPoint("LEFT", 0, 0)
                noBuffsText:SetText("No active buffs")
                noBuffsText:SetTextColor(0.5, 0.5, 0.5)
                
                table.insert(CM.buffFrames, noBuffsFrame)
                table.insert(CM.buffFrames, noBuffsText)
                
                yOffset = yOffset - 20
            end
        end
        
        -- Add some space between characters
        yOffset = yOffset - 10
    end
    
    -- Resize the frame to fit all content
    CM.buffFrame:SetHeight(math.abs(yOffset) + 20)
end

-- Show buff settings dropdown menu
function CM.ShowBuffSettingsDropdown(characterName, anchor)
    if not CM.buffSettingsDropdown then
        CM.buffSettingsDropdown = CreateFrame("Frame", "CMBuffSettingsDropdown", UIParent, "UIDropDownMenuTemplate")
    end
    
    local function Initialize(self, level)
        local info = UIDropDownMenu_CreateInfo()
        
        if level == 1 then
            -- Header
            info.text = "Buff Settings"
            info.isTitle = true
            info.notCheckable = true
            UIDropDownMenu_AddButton(info, level)
            
            -- Tracked buffs submenu
            info = UIDropDownMenu_CreateInfo()
            info.text = "Tracked Buffs"
            info.hasArrow = true
            info.notCheckable = true
            info.value = "TRACKED_BUFFS"
            UIDropDownMenu_AddButton(info, level)
            
            -- Delete character
            info = UIDropDownMenu_CreateInfo()
            info.text = "Delete Character"
            info.notCheckable = true
            info.func = function()
                StaticPopupDialogs["CM_CONFIRM_DELETE"] = {
                    text = "Are you sure you want to delete " .. characterName .. "?",
                    button1 = "Yes",
                    button2 = "No",
                    OnAccept = function()
                        MyAddonDB[characterName] = nil
                        MyAddonSettings.characters[characterName] = nil
                        CM.UpdateBuffDisplay()
                    end,
                    timeout = 0,
                    whileDead = true,
                    hideOnEscape = true,
                    preferredIndex = 3,
                }
                StaticPopup_Show("CM_CONFIRM_DELETE")
            end
            UIDropDownMenu_AddButton(info, level)
            
        elseif level == 2 then
            if UIDROPDOWNMENU_MENU_VALUE == "TRACKED_BUFFS" then
                -- Make sure character settings exist
                if not MyAddonSettings.characters[characterName] then
                    MyAddonSettings.characters[characterName] = {
                        trackedBuffs = {}
                    }
                    
                    -- Copy default settings
                    for buffName, enabled in pairs(MyAddonSettings.defaultBuffs) do
                        MyAddonSettings.characters[characterName].trackedBuffs[buffName] = enabled
                    end
                end
                
                -- Add each buff as a toggle
                for _, buffInfo in ipairs(CM.trackedBuffs) do
                    local buffName = buffInfo.name
                    
                    info = UIDropDownMenu_CreateInfo()
                    info.text = buffName
                    info.checked = MyAddonSettings.characters[characterName].trackedBuffs[buffName] ~= false
                    info.func = function()
                        local current = MyAddonSettings.characters[characterName].trackedBuffs[buffName]
                        MyAddonSettings.characters[characterName].trackedBuffs[buffName] = not current
                        CM.UpdateBuffDisplay()
                    end
                    UIDropDownMenu_AddButton(info, level)
                end
            end
        end
    end
    
    UIDropDownMenu_Initialize(CM.buffSettingsDropdown, Initialize, "MENU")
    ToggleDropDownMenu(1, nil, CM.buffSettingsDropdown, anchor, 0, 0)
end

-- Format time in minutes and seconds
function CM.FormatTimeMinutes(seconds)
    if not seconds or seconds <= 0 then
        return "Expired"
    end
    
    local minutes = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    
    if minutes > 0 then
        return string.format("%dm %ds", minutes, secs)
    else
        return string.format("%ds", secs)
    end
end