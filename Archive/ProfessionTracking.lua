local CM = CharacterManager

-- Initialize profession tracking
function CM.InitProfessionTracking()
    -- Initialize default profession settings if needed
    if not MyAddonSettings.professionTracking then
        MyAddonSettings.professionTracking = {
            enabled = true,
            showCooldowns = true,
            showSkillLevels = true
        }
    end
end

-- Check player professions and update data
function CM.CheckProfessions()
    local fullName = CM.GetFullCharacterName()
    
    -- Initialize character data if needed
    if not MyAddonDB[fullName] then
        MyAddonDB[fullName] = {
            class = select(2, UnitClass("player")),
            level = UnitLevel("player"),
            professions = {},
            cooldowns = {}
        }
    end
    
    -- Initialize professions table if needed
    if not MyAddonDB[fullName].professions then
        MyAddonDB[fullName].professions = {}
    end
    
    -- Initialize cooldowns table if needed
    if not MyAddonDB[fullName].cooldowns then
        MyAddonDB[fullName].cooldowns = {}
    end
    
    -- Get profession data
    local professions = {}
    local cooldowns = {}
    
    -- Check primary professions
    for i = 1, 2 do
        local name, icon, skillLevel, maxSkillLevel = GetProfessionInfo(i)
        if name then
            professions[name] = {
                icon = icon,
                skillLevel = skillLevel,
                maxSkillLevel = maxSkillLevel,
                isPrimary = true
            }
            
            -- Check for profession cooldowns
            CM.CheckProfessionCooldowns(name, cooldowns)
        end
    end
    
    -- Check secondary professions (cooking, fishing, first aid)
    for i = 3, 5 do
        local name, icon, skillLevel, maxSkillLevel = GetProfessionInfo(i)
        if name then
            professions[name] = {
                icon = icon,
                skillLevel = skillLevel,
                maxSkillLevel = maxSkillLevel,
                isPrimary = false
            }
            
            -- Check for profession cooldowns
            CM.CheckProfessionCooldowns(name, cooldowns)
        end
    end
    
    -- Update character's profession data
    MyAddonDB[fullName].professions = professions
    MyAddonDB[fullName].cooldowns = cooldowns
    
    -- Update UI if it's open
    if CM.professionFrame and CM.professionFrame:IsShown() then
        CM.UpdateProfessionDisplay()
    end
end

-- Check profession-specific cooldowns
function CM.CheckProfessionCooldowns(professionName, cooldowns)
    -- Get profession-specific cooldowns based on profession name
    if professionName == "Alchemy" then
        CM.CheckAlchemyCooldowns(cooldowns)
    elseif professionName == "Tailoring" then
        CM.CheckTailoringCooldowns(cooldowns)
    elseif professionName == "Leatherworking" then
        CM.CheckLeatherworkingCooldowns(cooldowns)
    elseif professionName == "Mining" then
        CM.CheckSmeltingCooldowns(cooldowns)
    elseif professionName == "Enchanting" then
        -- No cooldowns for Enchanting in Classic Era
    elseif professionName == "Engineering" then
        CM.CheckEngineeringCooldowns(cooldowns)
    elseif professionName == "Blacksmithing" then
        CM.CheckBlacksmithingCooldowns(cooldowns)
    end
end

-- Check Alchemy cooldowns
function CM.CheckAlchemyCooldowns(cooldowns)
    -- Transmutes
    local transmuteName = "Transmute"
    local start, duration = GetSpellCooldown(11479) -- Transmute: Iron to Gold as reference
    
    if start > 0 and duration > 0 then
        local remaining = start + duration - GetTime()
        if remaining > 0 then
            cooldowns[transmuteName] = {
                name = transmuteName,
                icon = GetSpellTexture(11479),
                expirationTime = start + duration,
                remainingTime = remaining,
                status = CM.FormatTimeHours(remaining)
            }
        end
    end
end

-- Check Tailoring cooldowns
function CM.CheckTailoringCooldowns(cooldowns)
    -- Mooncloth
    local moonclothName = "Mooncloth"
    local start, duration = GetSpellCooldown(18560) -- Mooncloth
    
    if start > 0 and duration > 0 then
        local remaining = start + duration - GetTime()
        if remaining > 0 then
            cooldowns[moonclothName] = {
                name = moonclothName,
                icon = GetSpellTexture(18560),
                expirationTime = start + duration,
                remainingTime = remaining,
                status = CM.FormatTimeHours(remaining)
            }
        end
    end
end

-- Check Leatherworking cooldowns
function CM.CheckLeatherworkingCooldowns(cooldowns)
    -- Salt Shaker
    local saltShakerName = "Salt Shaker"
    local start, duration = GetSpellCooldown(19566) -- Salt Shaker
    
    if start > 0 and duration > 0 then
        local remaining = start + duration - GetTime()
        if remaining > 0 then
            cooldowns[saltShakerName] = {
                name = saltShakerName,
                icon = GetSpellTexture(19566),
                expirationTime = start + duration,
                remainingTime = remaining,
                status = CM.FormatTimeHours(remaining)
            }
        end
    end
end

-- Check Smelting cooldowns
function CM.CheckSmeltingCooldowns(cooldowns)
    -- Smelt Elementium
    local elementiumName = "Smelt Elementium"
    local start, duration = GetSpellCooldown(22967) -- Smelt Elementium
    
    if start > 0 and duration > 0 then
        local remaining = start + duration - GetTime()
        if remaining > 0 then
            cooldowns[elementiumName] = {
                name = elementiumName,
                icon = GetSpellTexture(22967),
                expirationTime = start + duration,
                remainingTime = remaining,
                status = CM.FormatTimeHours(remaining)
            }
        end
    end
end

-- Check Engineering cooldowns
function CM.CheckEngineeringCooldowns(cooldowns)
    -- Arcanite Dragonling
    local dragonlingName = "Arcanite Dragonling"
    local start, duration = GetSpellCooldown(19804) -- Arcanite Dragonling
    
    if start > 0 and duration > 0 then
        local remaining = start + duration - GetTime()
        if remaining > 0 then
            cooldowns[dragonlingName] = {
                name = dragonlingName,
                icon = GetSpellTexture(19804),
                expirationTime = start + duration,
                remainingTime = remaining,
                status = CM.FormatTimeHours(remaining)
            }
        end
    end
    
    -- Gnomish Battle Chicken
    local chickenName = "Gnomish Battle Chicken"
    local start, duration = GetSpellCooldown(12906) -- Gnomish Battle Chicken
    
    if start > 0 and duration > 0 then
        local remaining = start + duration - GetTime()
        if remaining > 0 then
            cooldowns[chickenName] = {
                name = chickenName,
                icon = GetSpellTexture(12906),
                expirationTime = start + duration,
                remainingTime = remaining,
                status = CM.FormatTimeHours(remaining)
            }
        end
    end
end

-- Check Blacksmithing cooldowns
function CM.CheckBlacksmithingCooldowns(cooldowns)
    -- Nothing specific in Classic Era
end

-- Save character profession data
function CM.SaveProfessionData()
    local fullName = CM.GetFullCharacterName()
    
    -- Check professions
    CM.CheckProfessions()
    
    -- Update last seen time
    if not MyAddonDB[fullName] then
        MyAddonDB[fullName] = {}
    end
    
    MyAddonDB[fullName].lastSeen = time()
end

-- Update profession display in the UI
function CM.UpdateProfessionDisplay()
    if not CM.professionFrame then return end
    
    -- Clear existing profession frames
    if CM.professionFrames then
        for _, frame in ipairs(CM.professionFrames) do
            frame:Hide()
        end
    end
    CM.professionFrames = {}
    
    local yOffset = -10
    
    -- Sort characters by name
    local characters = {}
    for name, data in pairs(MyAddonDB) do
        table.insert(characters, {name = name, data = data})
    end
    table.sort(characters, function(a, b) return a.name < b.name end)
    
    -- Display each character's professions
    for _, charInfo in ipairs(characters) do
        local name = charInfo.name
        local data = charInfo.data
        
        -- Skip if no profession data
        if data.professions and next(data.professions) then
            -- Extract character name without realm if it's the same realm
            local displayName = name
            local currentRealm = "-" .. GetRealmName()
            if name:find(currentRealm) then
                displayName = name:gsub(currentRealm, "")
            end
            
            -- Character header
            local headerFrame = CreateFrame("Frame", nil, CM.professionFrame)
            headerFrame:SetSize(CM.professionFrame:GetWidth() - 20, 20)
            headerFrame:SetPoint("TOPLEFT", CM.professionFrame, "TOPLEFT", 10, yOffset)
            
            local classColor = RAID_CLASS_COLORS[data.class] or RAID_CLASS_COLORS["WARRIOR"]
            local headerText = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            headerText:SetPoint("LEFT", 25, 0)
            headerText:SetText(displayName)
            headerText:SetTextColor(classColor.r, classColor.g, classColor.b)
            
            -- Class icon
            local classIcon = headerFrame:CreateTexture(nil, "OVERLAY")
            classIcon:SetSize(18, 18)
            classIcon:SetPoint("LEFT", 0, 0)
            classIcon:SetTexture("Interface\GLUES\CHARACTERCREATE\UI-CHARACTERCREATE-CLASSES")
            
            -- Set class icon texture coordinates
            if CM.CLASS_ICON_TCOORDS[data.class] then
                classIcon:SetTexCoord(unpack(CM.CLASS_ICON_TCOORDS[data.class]))
            end
            
            table.insert(CM.professionFrames, headerFrame)
            table.insert(CM.professionFrames, classIcon)
            table.insert(CM.professionFrames, headerText)
            
            yOffset = yOffset - 25
            
            -- Display professions
            local professions = {}
            for name, info in pairs(data.professions) do
                table.insert(professions, {name = name, info = info})
            end
            
            -- Sort professions: primary first, then alphabetically
            table.sort(professions, function(a, b)
                if a.info.isPrimary ~= b.info.isPrimary then
                    return a.info.isPrimary
                end
                return a.name < b.name
            end)
            
            for _, prof in ipairs(professions) do
                local profName = prof.name
                local profInfo = prof.info
                
                -- Create profession frame
                local profFrame = CreateFrame("Frame", nil, CM.professionFrame)
                profFrame:SetSize(CM.professionFrame:GetWidth() - 30, 20)
                profFrame:SetPoint("TOPLEFT", CM.professionFrame, "TOPLEFT", 20, yOffset)
                
                -- Profession icon
                local profIcon = profFrame:CreateTexture(nil, "OVERLAY")
                profIcon:SetSize(16, 16)
                profIcon:SetPoint("LEFT", 0, 0)
                profIcon:SetTexture(profInfo.icon)
                
                -- Profession name
                local nameText = profFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                nameText:SetPoint("LEFT", 20, 0)
                nameText:SetText(profName)
                
                -- Profession skill level
                if MyAddonSettings.professionTracking.showSkillLevels then
                    local skillText = profFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    skillText:SetPoint("RIGHT", 0, 0)
                    skillText:SetText(profInfo.skillLevel .. "/" .. profInfo.maxSkillLevel)
                    
                    -- Color based on skill level
                    local ratio = profInfo.skillLevel / profInfo.maxSkillLevel
                    if ratio >= 0.9 then
                        skillText:SetTextColor(0, 1, 0) -- Green
                    elseif ratio >= 0.7 then
                        skillText:SetTextColor(1, 1, 0) -- Yellow
                    elseif ratio >= 0.5 then
                        skillText:SetTextColor(1, 0.5, 0) -- Orange
                    else
                        skillText:SetTextColor(1, 0, 0) -- Red
                    end
                    
                    table.insert(CM.professionFrames, skillText)
                end
                
                table.insert(CM.professionFrames, profFrame)
                table.insert(CM.professionFrames, profIcon)
                table.insert(CM.professionFrames, nameText)
                
                yOffset = yOffset - 20
            end
            
            -- Display cooldowns if any
            if MyAddonSettings.professionTracking.showCooldowns and data.cooldowns and next(data.cooldowns) then
                -- Cooldown header
                local cooldownHeader = CreateFrame("Frame", nil, CM.professionFrame)
                cooldownHeader:SetSize(CM.professionFrame:GetWidth() - 30, 20)
                cooldownHeader:SetPoint("TOPLEFT", CM.professionFrame, "TOPLEFT", 20, yOffset)
                
                local headerText = cooldownHeader:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                headerText:SetPoint("LEFT", 0, 0)
                headerText:SetText("Cooldowns:")
                headerText:SetTextColor(0.7, 0.7, 1)
                
                table.insert(CM.professionFrames, cooldownHeader)
                table.insert(CM.professionFrames, headerText)
                
                yOffset = yOffset - 20
                
                -- Sort cooldowns by name
                local cooldowns = {}
                for name, info in pairs(data.cooldowns) do
                    table.insert(cooldowns, {name = name, info = info})
                end
                table.sort(cooldowns, function(a, b) return a.name < b.name end)
                
                -- Display each cooldown
                for _, cd in ipairs(cooldowns) do
                    local cdName = cd.name
                    local cdInfo = cd.info
                    
                    -- Create cooldown frame
                    local cdFrame = CreateFrame("Frame", nil, CM.professionFrame)
                    cdFrame:SetSize(CM.professionFrame:GetWidth() - 40, 20)
                    cdFrame:SetPoint("TOPLEFT", CM.professionFrame, "TOPLEFT", 30, yOffset)
                    
                    -- Cooldown icon
                    local cdIcon = cdFrame:CreateTexture(nil, "OVERLAY")
                    cdIcon:SetSize(16, 16)
                    cdIcon:SetPoint("LEFT", 0, 0)
                    cdIcon:SetTexture(cdInfo.icon)
                    
                    -- Cooldown name
                    local nameText = cdFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    nameText:SetPoint("LEFT", 20, 0)
                    nameText:SetText(cdName)
                    
                    -- Cooldown time remaining
                    local timeText = cdFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    timeText:SetPoint("RIGHT", 0, 0)
                    timeText:SetText(cdInfo.status)
                    
                    -- Color based on time remaining
                    local timeRatio = cdInfo.remainingTime / (24 * 60 * 60) -- Assuming most cooldowns are daily
                    if timeRatio < 0.25 then
                        timeText:SetTextColor(0, 1, 0) -- Green - almost ready
                    elseif timeRatio < 0.5 then
                        timeText:SetTextColor(1, 1, 0) -- Yellow
                    else
                        timeText:SetTextColor(1, 0.5, 0) -- Orange - long time remaining
                    end
                    
                    table.insert(CM.professionFrames, cdFrame)
                    table.insert(CM.professionFrames, cdIcon)
                    table.insert(CM.professionFrames, nameText)
                    table.insert(CM.professionFrames, timeText)
                    
                    yOffset = yOffset - 20
                end
            end
            
            yOffset = yOffset - 10
        end
    end
    
    -- Adjust frame height based on content
    local height = math.abs(yOffset) + 20
    CM.professionFrame:SetHeight(math.max(height, 100))
end

-- Create profession UI
function CM.CreateProfessionUI()
    -- Main frame
    CM.professionFrame = CreateFrame("Frame", "CharacterManagerProfessionFrame", UIParent, "BackdropTemplate")
    CM.professionFrame:SetSize(300, 400)
    CM.professionFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    CM.professionFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    CM.professionFrame:SetMovable(true)
    CM.professionFrame:EnableMouse(true)
    CM.professionFrame:RegisterForDrag("LeftButton")
    CM.professionFrame:SetScript("OnDragStart", CM.professionFrame.StartMoving)
    CM.professionFrame:SetScript("OnDragStop", CM.professionFrame.StopMovingOrSizing)
    CM.professionFrame:Hide()
    
    -- Title
    local title = CM.professionFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOPLEFT", CM.professionFrame, "TOPLEFT", 16, -16)
    title:SetText("Character Professions")
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, CM.professionFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", CM.professionFrame, "TOPRIGHT", -5, -5)
    
    -- Refresh button
    local refreshButton = CreateFrame("Button", nil, CM.professionFrame, "UIPanelButtonTemplate")
    refreshButton:SetSize(80, 22)
    refreshButton:SetPoint("TOPRIGHT", CM.professionFrame, "TOPRIGHT", -30, -13)
    refreshButton:SetText("Refresh")
    refreshButton:SetScript("OnClick", function()
        CM.CheckProfessions()
        CM.UpdateProfessionDisplay()
    end)
    
    -- Settings button
    local settingsButton = CreateFrame("Button", nil, CM.professionFrame, "UIPanelButtonTemplate")
    settingsButton:SetSize(80, 22)
    settingsButton:SetPoint("RIGHT", refreshButton, "LEFT", -5, 0)
    settingsButton:SetText("Settings")
    settingsButton:SetScript("OnClick", function()
        -- Toggle settings panel
        if CM.settingsFrame and CM.settingsFrame:IsShown() then
            CM.settingsFrame:Hide()
        else
            CM.ShowSettingsUI()
        end
    end)
    
    -- Initialize profession frames container
    CM.professionFrames = {}
    
    -- Update display
    CM.UpdateProfessionDisplay()
end

-- Toggle profession UI visibility
function CM.ToggleProfessionUI()
    if not CM.professionFrame then
        CM.CreateProfessionUI()
    end
    
    if CM.professionFrame:IsShown() then
        CM.professionFrame:Hide()
    else
        CM.UpdateProfessionDisplay()
        CM.professionFrame:Show()
    end
end

-- Register events
function CM.RegisterProfessionEvents()
    -- Update profession data when skills change
    CM.eventFrame:RegisterEvent("SKILL_LINES_CHANGED")
    CM.eventFrame:RegisterEvent("SPELLS_CHANGED")
    
    -- Hook into event handler
    local originalEventHandler = CM.eventFrame:GetScript("OnEvent")
    CM.eventFrame:SetScript("OnEvent", function(self, event, ...)
        if originalEventHandler then
            originalEventHandler(self, event, ...)
        end
        
        if event == "SKILL_LINES_CHANGED" or event == "SPELLS_CHANGED" then
            CM.CheckProfessions()
        end
    end)
end