-- Character Manager UI Module
local addonName, CM = ...

-- Local variables
local currentTab = 1
local tabFrames = {}
local tabButtons = {}

-- Create main UI frame
function CM.CreateMainFrame()
    -- Main frame
    CM.mainFrame = CreateFrame("Frame", "CharacterManagerFrame", UIParent, "BackdropTemplate")
    CM.mainFrame:SetSize(600, 400)
    CM.mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    CM.mainFrame:SetBackdrop({
        bgFile = "Interface\DialogFrame\UI-DialogBox-Background",
        edgeFile = "Interface\DialogFrame\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    CM.mainFrame:SetMovable(true)
    CM.mainFrame:EnableMouse(true)
    CM.mainFrame:RegisterForDrag("LeftButton")
    CM.mainFrame:SetScript("OnDragStart", CM.mainFrame.StartMoving)
    CM.mainFrame:SetScript("OnDragStop", CM.mainFrame.StopMovingOrSizing)
    CM.mainFrame:SetClampedToScreen(true)
    
    -- Apply settings
    CM.mainFrame:SetScale(MyAddonSettings.ui.scale)
    CM.mainFrame:SetAlpha(MyAddonSettings.ui.transparency)
    
    -- Title
    local title = CM.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOPLEFT", CM.mainFrame, "TOPLEFT", 16, -16)
    title:SetText("Character Manager")
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, CM.mainFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", CM.mainFrame, "TOPRIGHT", -5, -5)
    
    -- Settings button
    local settingsButton = CreateFrame("Button", nil, CM.mainFrame, "UIPanelButtonTemplate")
    settingsButton:SetSize(80, 22)
    settingsButton:SetPoint("TOPRIGHT", CM.mainFrame, "TOPRIGHT", -30, -14)
    settingsButton:SetText("Settings")
    settingsButton:SetScript("OnClick", function()
        CM.ShowSettingsUI()
    end)
    
    -- Create tab buttons
    local tabWidth = 100
    local tabHeight = 24
    local tabs = {"Characters", "Buffs", "Professions", "Notes"}
    
    for i, tabName in ipairs(tabs) do
        -- Create tab button
        local tabButton = CreateFrame("Button", "CharacterManagerTab"..i, CM.mainFrame, "CharacterFrameTabButtonTemplate")
        tabButton:SetPoint("TOPLEFT", CM.mainFrame, "BOTTOMLEFT", (i-1) * tabWidth + 15, 0)
        tabButton:SetSize(tabWidth, tabHeight)
        tabButton:SetText(tabName)
        tabButton:SetID(i)
        
        -- Create tab content frame
        local tabFrame = CreateFrame("Frame", "CharacterManagerTabFrame"..i, CM.mainFrame)
        tabFrame:SetPoint("TOPLEFT", CM.mainFrame, "TOPLEFT", 20, -40)
        tabFrame:SetPoint("BOTTOMRIGHT", CM.mainFrame, "BOTTOMRIGHT", -20, 20)
        tabFrame:Hide()
        
        -- Store references
        tabButtons[i] = tabButton
        tabFrames[i] = tabFrame
        
        -- Tab button click handler
        tabButton:SetScript("OnClick", function()
            CM.SwitchTab(i)
        end)
    end
    
    -- Select first tab by default
    CM.SwitchTab(1)
    
    -- Create tab content
    CM.CreateCharactersTab(tabFrames[1])
    CM.CreateBuffsTab(tabFrames[2])
    CM.CreateProfessionsTab(tabFrames[3])
    CM.CreateNotesTab(tabFrames[4])
    
    -- Hide by default
    CM.mainFrame:Hide()
    
    -- Register events
    CM.mainFrame:SetScript("OnEvent", CM.OnEvent)
    CM.mainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    CM.mainFrame:RegisterEvent("PLAYER_LOGOUT")
end

-- Switch between tabs
function CM.SwitchTab(tabIndex)
    for i, frame in ipairs(tabFrames) do
        frame:Hide()
        PanelTemplates_DeselectTab(tabButtons[i])
    end
    
    tabFrames[tabIndex]:Show()
    PanelTemplates_SelectTab(tabButtons[tabIndex])
    currentTab = tabIndex
    
    -- Update tab content
    if tabIndex == 1 then
        CM.UpdateCharactersTab()
    elseif tabIndex == 2 then
        CM.UpdateBuffsTab()
    elseif tabIndex == 3 then
        CM.UpdateProfessionsTab()
    elseif tabIndex == 4 then
        CM.UpdateNotesTab()
    end
end

-- Create Characters tab
function CM.CreateCharactersTab(parent)
    -- Character selection dropdown
    local dropdown = CreateFrame("Frame", "CharacterManagerCharacterDropdown", parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -10)
    
    UIDropDownMenu_SetWidth(dropdown, 200)
    UIDropDownMenu_SetText(dropdown, "Select Character")
    
    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        info.func = function(self)
            UIDropDownMenu_SetText(dropdown, self.value)
            CM.selectedCharacter = self.value
            CM.UpdateCharacterInfo()
        end
        
        -- Add all characters from database
        for fullName, _ in pairs(MyAddonDB or {}) do
            info.text = fullName
            info.value = fullName
            info.checked = (CM.selectedCharacter == fullName)
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    -- Character info frame
    local infoFrame = CreateFrame("Frame", "CharacterManagerCharacterInfo", parent, "BackdropTemplate")
    infoFrame:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -10)
    infoFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
    infoFrame:SetBackdrop({
        bgFile = "Interface\DialogFrame\UI-DialogBox-Background",
        edgeFile = "Interface\Tooltips\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    
    -- Character name
    local nameText = infoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    nameText:SetPoint("TOPLEFT", infoFrame, "TOPLEFT", 10, -10)
    nameText:SetText("No character selected")
    CM.characterNameText = nameText
    
    -- Character level and class
    local levelClassText = infoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    levelClassText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -5)
    levelClassText:SetText("")
    CM.levelClassText = levelClassText
    
    -- Last seen
    local lastSeenText = infoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lastSeenText:SetPoint("TOPLEFT", levelClassText, "BOTTOMLEFT", 0, -10)
    lastSeenText:SetText("")
    CM.lastSeenText = lastSeenText
    
    -- Gold
    local goldText = infoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    goldText:SetPoint("TOPLEFT", lastSeenText, "BOTTOMLEFT", 0, -10)
    goldText:SetText("")
    CM.goldText = goldText
    
    -- Location
    local locationText = infoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    locationText:SetPoint("TOPLEFT", goldText, "BOTTOMLEFT", 0, -10)
    locationText:SetText("")
    CM.locationText = locationText
    
    -- Guild
    local guildText = infoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    guildText:SetPoint("TOPLEFT", locationText, "BOTTOMLEFT", 0, -10)
    guildText:SetText("")
    CM.guildText = guildText
    
    -- Played time
    local playedText = infoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    playedText:SetPoint("TOPLEFT", guildText, "BOTTOMLEFT", 0, -10)
    playedText:SetText("")
    CM.playedText = playedText
end

-- Update Characters tab
function CM.UpdateCharactersTab()
    -- Update dropdown with current characters
    UIDropDownMenu_Initialize(CharacterManagerCharacterDropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        info.func = function(self)
            UIDropDownMenu_SetText(CharacterManagerCharacterDropdown, self.value)
            CM.selectedCharacter = self.value
            CM.UpdateCharacterInfo()
        end
        
        -- Add all characters from database
        for fullName, _ in pairs(MyAddonDB or {}) do
            info.text = fullName
            info.value = fullName
            info.checked = (CM.selectedCharacter == fullName)
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    -- If no character is selected, select current character
    if not CM.selectedCharacter then
        local playerName = UnitName("player")
        local realmName = GetRealmName()
        local fullName = playerName .. "-" .. realmName
        
        if MyAddonDB and MyAddonDB[fullName] then
            CM.selectedCharacter = fullName
            UIDropDownMenu_SetText(CharacterManagerCharacterDropdown, fullName)
        end
    end
    
    -- Update character info
    CM.UpdateCharacterInfo()
end

-- Update character info display
function CM.UpdateCharacterInfo()
    if not CM.selectedCharacter or not MyAddonDB or not MyAddonDB[CM.selectedCharacter] then
        CM.characterNameText:SetText("No character selected")
        CM.levelClassText:SetText("")
        CM.lastSeenText:SetText("")
        CM.goldText:SetText("")
        CM.locationText:SetText("")
        CM.guildText:SetText("")
        CM.playedText:SetText("")
        return
    end
    
    local charData = MyAddonDB[CM.selectedCharacter]
    local name, realm = strsplit("-", CM.selectedCharacter)
    
    -- Set character name
    CM.characterNameText:SetText(name)
    
    -- Set level and class
    local levelClass = ""
    if charData.level then
        levelClass = "Level " .. charData.level
    end
    if charData.class then
        if levelClass ~= "" then
            levelClass = levelClass .. " " .. charData.class
        else
            levelClass = charData.class
        end
    end
    CM.levelClassText:SetText(levelClass)
    
    -- Set last seen
    if charData.lastSeen then
        local lastSeenText = "Last seen: " .. date("%Y-%m-%d %H:%M", charData.lastSeen)
        CM.lastSeenText:SetText(lastSeenText)
    else
        CM.lastSeenText:SetText("Last seen: Unknown")
    end
    
    -- Set gold
    if charData.money then
        local gold = math.floor(charData.money / 10000)
        local silver = math.floor((charData.money % 10000) / 100)
        local copper = charData.money % 100
        CM.goldText:SetText(string.format("Gold: %dg %ds %dc", gold, silver, copper))
    else
        CM.goldText:SetText("Gold: Unknown")
    end
    
    -- Set location
    if charData.zone then
        local locationText = "Location: " .. charData.zone
        if charData.subZone and charData.subZone ~= "" then
            locationText = locationText .. " (" .. charData.subZone .. ")"
        end
        CM.locationText:SetText(locationText)
    else
        CM.locationText:SetText("Location: Unknown")
    end
    
    -- Set guild
    if charData.guild and charData.guild ~= "" then
        CM.guildText:SetText("Guild: " .. charData.guild)
    else
        CM.guildText:SetText("Guild: None")
    end
    
    -- Set played time
    if charData.playedTotal then
        local days = math.floor(charData.playedTotal / 86400)
        local hours = math.floor((charData.playedTotal % 86400) / 3600)
        local minutes = math.floor((charData.playedTotal % 3600) / 60)
        CM.playedText:SetText(string.format("Played: %dd %dh %dm", days, hours, minutes))
    else
        CM.playedText:SetText("Played: Unknown")
    end
end

-- Create Buffs tab
function CM.CreateBuffsTab(parent)
    -- Character selection dropdown
    local dropdown = CreateFrame("Frame", "CharacterManagerBuffsDropdown", parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -10)
    
    UIDropDownMenu_SetWidth(dropdown, 200)
    UIDropDownMenu_SetText(dropdown, "Select Character")
    
    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        info.func = function(self)
            UIDropDownMenu_SetText(dropdown, self.value)
            CM.selectedBuffCharacter = self.value
            CM.UpdateBuffsList()
        end
        
        -- Add all characters from database
        for fullName, _ in pairs(MyAddonDB or {}) do
            info.text = fullName
            info.value = fullName
            info.checked = (CM.selectedBuffCharacter == fullName)
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    -- Buffs scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", "CharacterManagerBuffsScrollFrame", parent, "FauxScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -30, 10)
    CM.buffsScrollFrame = scrollFrame
    
    -- Create buff entries
    CM.buffEntries = {}
    for i = 1, 15 do -- Show 15 buffs at a time
        local entry = CreateFrame("Frame", "CharacterManagerBuffEntry"..i, scrollFrame)
        entry:SetSize(scrollFrame:GetWidth(), 20)
        entry:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 5, -((i-1)*22))
        
        -- Buff icon
        local icon = entry:CreateTexture("CharacterManagerBuffIcon"..i, "ARTWORK")
        icon:SetSize(20, 20)
        icon:SetPoint("LEFT", entry, "LEFT", 0, 0)
        
        -- Buff name
        local name = entry:CreateFontString("CharacterManagerBuffName"..i, "OVERLAY", "GameFontNormal")
        name:SetPoint("LEFT", icon, "RIGHT", 5, 0)
        name:SetWidth(200)
        name:SetJustifyH("LEFT")
        
        -- Buff time remaining
        local time = entry:CreateFontString("CharacterManagerBuffTime"..i, "OVERLAY", "GameFontNormal")
        time:SetPoint("LEFT", name, "RIGHT", 10, 0)
        time:SetWidth(100)
        time:SetJustifyH("RIGHT")
        
        entry.icon = icon
        entry.name = name
        entry.time = time
        entry:Hide()
        
        CM.buffEntries[i] = entry
    end
    
    -- Set up scroll frame
    scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, 22, CM.UpdateBuffsList)
    end)
end

-- Update buffs list
function CM.UpdateBuffsList()
    if not CM.selectedBuffCharacter or not MyAddonDB or not MyAddonDB[CM.selectedBuffCharacter] or not MyAddonDB[CM.selectedBuffCharacter].buffs then
        -- Hide all entries
        for i = 1, #CM.buffEntries do
            CM.buffEntries[i]:Hide()
        end
        return
    end
    
    local buffs = MyAddonDB[CM.selectedBuffCharacter].buffs
    local numBuffs = #buffs
    
    -- Update the scroll frame
    FauxScrollFrame_Update(CM.buffsScrollFrame, numBuffs, 15, 22)
    local offset = FauxScrollFrame_GetOffset(CM.buffsScrollFrame)
    
    -- Update buff entries
    for i = 1, 15 do
        local index = i + offset
        if index <= numBuffs then
            local buff = buffs[index]
            local entry = CM.buffEntries[i]
            
            -- Set buff icon
            if buff.icon then
                entry.icon:SetTexture(buff.icon)
            else
                entry.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            end
            
            -- Set buff name
            entry.name:SetText(buff.name or "Unknown Buff")
            
            -- Set buff time remaining
            if buff.expirationTime and buff.expirationTime > 0 then
                local remaining = buff.expirationTime - GetTime()
                if remaining > 0 then
                    entry.time:SetText(CM.FormatTime(remaining))
                else
                    entry.time:SetText("Expired")
                end
            else
                entry.time:SetText("")
            end
            
            entry:Show()
        else
            CM.buffEntries[i]:Hide()
        end
    end
end

-- Create Professions tab
function CM.CreateProfessionsTab(parent)
    -- Character selection dropdown
    local dropdown = CreateFrame("Frame", "CharacterManagerProfessionsDropdown", parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -10)
    
    UIDropDownMenu_SetWidth(dropdown, 200)
    UIDropDownMenu_SetText(dropdown, "Select Character")
    
    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        info.func = function(self)
            UIDropDownMenu_SetText(dropdown, self.value)
            CM.selectedProfessionCharacter = self.value
            CM.UpdateProfessionsList()
        end
        
        -- Add all characters from database
        for fullName, _ in pairs(MyAddonDB or {}) do
            info.text = fullName
            info.value = fullName
            info.checked = (CM.selectedProfessionCharacter == fullName)
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    -- Professions container
    local container = CreateFrame("Frame", "CharacterManagerProfessionsContainer", parent)
    container:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -10)
    container:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 10)
    CM.professionsContainer = container
end

-- Update professions list
function CM.UpdateProfessionsList()
    -- Clear existing profession frames
    if CM.professionFrames then
        for _, frame in pairs(CM.professionFrames) do
            frame:Hide()
        end
    end
    
    CM.professionFrames = {}
    
    if not CM.selectedProfessionCharacter or not MyAddonDB or not MyAddonDB[CM.selectedProfessionCharacter] or not MyAddonDB[CM.selectedProfessionCharacter].professions then
        return
    end
    
    local professions = MyAddonDB[CM.selectedProfessionCharacter].professions
    local yOffset = 0
    
    for profName, profData in pairs(professions) do
        -- Create profession frame
        local frame = CreateFrame("Frame", nil, CM.professionsContainer, "BackdropTemplate")
        frame:SetSize(CM.professionsContainer:GetWidth(), 80)
        frame:SetPoint("TOPLEFT", CM.professionsContainer, "TOPLEFT", 0, -yOffset)
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        
        -- Profession name
        local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        nameText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -10)
        nameText:SetText(profName)
        
        -- Profession level
        local levelText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        levelText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -5)
        levelText:SetText(string.format("Skill: %d/%d", profData.skillLevel or 0, profData.maxSkillLevel or 0))
        
        -- Profession specialization
        if profData.specialization then
            local specText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            specText:SetPoint("LEFT", levelText, "RIGHT", 20, 0)
            specText:SetText("Specialization: " .. profData.specialization)
        end
        
        CM.professionFrames[profName] = frame
        yOffset = yOffset + 90
    end
end

-- Create Notes tab
function CM.CreateNotesTab(parent)
    -- Character selection dropdown
    local dropdown = CreateFrame("Frame", "CharacterManagerNotesDropdown", parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -10)
    
    UIDropDownMenu_SetWidth(dropdown, 200)
    UIDropDownMenu_SetText(dropdown, "Select Character")
    
    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        info.func = function(self)
            UIDropDownMenu_SetText(dropdown, self.value)
            CM.selectedNotesCharacter = self.value
            CM.UpdateNotesDisplay()
        end
        
        -- Add all characters from database
        for fullName, _ in pairs(MyAddonDB or {}) do
            info.text = fullName
            info.value = fullName
            info.checked = (CM.selectedNotesCharacter == fullName)
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    -- Notes edit box
    local scrollFrame = CreateFrame("ScrollFrame", "CharacterManagerNotesScrollFrame", parent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -30, 40)
    
    local editBox = CreateFrame("EditBox", "CharacterManagerNotesEditBox", scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(scrollFrame:GetWidth())
    editBox:SetAutoFocus(false)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    editBox:SetScript("OnTextChanged", function(self)
        if CM.selectedNotesCharacter and MyAddonDB and MyAddonDB[CM.selectedNotesCharacter] then
            MyAddonDB[CM.selectedNotesCharacter].notes = self:GetText()
        end
    end)
    
    scrollFrame:SetScrollChild(editBox)
    CM.notesEditBox = editBox
    
    -- Save button
    local saveButton = CreateFrame("Button", "CharacterManagerNotesSaveButton", parent, "UIPanelButtonTemplate")
    saveButton:SetSize(100, 25)
    saveButton:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -10, 10)
    saveButton:SetText("Save Notes")
    saveButton:SetScript("OnClick", function()
        if CM.selectedNotesCharacter and MyAddonDB and MyAddonDB[CM.selectedNotesCharacter] then
            MyAddonDB[CM.selectedNotesCharacter].notes = CM.notesEditBox:GetText()
            print("Notes saved for " .. CM.selectedNotesCharacter)
        else
            print("No character selected or database error")
        end
    end)
end

-- Update notes display
function CM.UpdateNotesDisplay()
    if not CM.selectedNotesCharacter or not MyAddonDB or not MyAddonDB[CM.selectedNotesCharacter] then
        CM.notesEditBox:SetText("")
        return
    end
    
    local notes = MyAddonDB[CM.selectedNotesCharacter].notes or ""
    CM.notesEditBox:SetText(notes)
end

-- Create Raids tab
function CM.CreateRaidsTab(parent)
    -- Character selection dropdown
    local dropdown = CreateFrame("Frame", "CharacterManagerRaidsDropdown", parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -10)
    
    UIDropDownMenu_SetWidth(dropdown, 200)
    UIDropDownMenu_SetText(dropdown, "Select Character")
    
    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        info.func = function(self)
            UIDropDownMenu_SetText(dropdown, self.value)
            CM.selectedRaidCharacter = self.value
            CM.UpdateRaidsList()
        end
        
        -- Add all characters from database
        for fullName, _ in pairs(MyAddonDB or {}) do
            info.text = fullName
            info.value = fullName
            info.checked = (CM.selectedRaidCharacter == fullName)
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    -- Raids container
    local container = CreateFrame("Frame", "CharacterManagerRaidsContainer", parent)
    container:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -10)
    container:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 10)
    CM.raidsContainer = container
end

-- Update raids list
function CM.UpdateRaidsList()
    -- Clear existing raid frames
    if CM.raidFrames then
        for _, frame in pairs(CM.raidFrames) do
            frame:Hide()
        end
    end
    
    CM.raidFrames = {}
    
    if not CM.selectedRaidCharacter or not MyAddonDB or not MyAddonDB[CM.selectedRaidCharacter] or not MyAddonDB[CM.selectedRaidCharacter].raidStatus then
        return
    end
    
    local raidStatus = MyAddonDB[CM.selectedRaidCharacter].raidStatus
    local yOffset = 0
    
    for raidName, raidData in pairs(raidStatus) do
        -- Create raid frame
        local frame = CreateFrame("Frame", nil, CM.raidsContainer, "BackdropTemplate")
        frame:SetSize(CM.raidsContainer:GetWidth(), 60)
        frame:SetPoint("TOPLEFT", CM.raidsContainer, "TOPLEFT", 0, -yOffset)
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        
        -- Raid name
        local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        nameText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -10)
        nameText:SetText(raidName)
        
        -- Raid status
        local statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        statusText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -5)
        
        if raidData.status then
            statusText:SetText("Status: Locked")
            
            -- Raid reset time
            local resetText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            resetText:SetPoint("TOPLEFT", statusText, "BOTTOMLEFT", 0, -5)
            
            if raidData.reset then
                local resetTime = date("%Y-%m-%d %H:%M", raidData.reset)
                resetText:SetText("Resets: " .. resetTime)
            else
                resetText:SetText("Reset: Unknown")
            end
            
            -- Raid progress
            if raidData.progress and raidData.total then
                local progressText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                progressText:SetPoint("RIGHT", statusText, "RIGHT", -10, 0)
                progressText:SetText(string.format("Progress: %d/%d", raidData.progress, raidData.total))
            end
        else
            statusText:SetText("Status: Available")
        end
        
        CM.raidFrames[raidName] = frame
        yOffset = yOffset + 70
    end
end

-- Create Inventory tab
function CM.CreateInventoryTab(parent)
    -- Character selection dropdown
    local dropdown = CreateFrame("Frame", "CharacterManagerInventoryDropdown", parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -10)
    
    UIDropDownMenu_SetWidth(dropdown, 200)
    UIDropDownMenu_SetText(dropdown, "Select Character")
    
    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        info.func = function(self)
            UIDropDownMenu_SetText(dropdown, self.value)
            CM.selectedInventoryCharacter = self.value
            CM.UpdateInventoryDisplay()
        end
        
        -- Add all characters from database
        for fullName, _ in pairs(MyAddonDB or {}) do
            info.text = fullName
            info.value = fullName
            info.checked = (CM.selectedInventoryCharacter == fullName)
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    -- Simple inventory display
    local container = CreateFrame("Frame", "CharacterManagerInventoryContainer", parent)
    container:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -10)
    container:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 10)
    CM.inventoryContainer = container
    
    -- Create a simple text display for inventory
    local inventoryText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    inventoryText:SetPoint("TOPLEFT", container, "TOPLEFT", 10, -10)
    inventoryText:SetText("Inventory information will be displayed here.")
    CM.inventoryText = inventoryText
end

-- Update inventory display
function CM.UpdateInventoryDisplay()
    if not CM.selectedInventoryCharacter or not MyAddonDB or not MyAddonDB[CM.selectedInventoryCharacter] then
        CM.inventoryText:SetText("No character selected or no inventory data available.")
        return
    end
    
    local charData = MyAddonDB[CM.selectedInventoryCharacter]
    
    -- Display basic inventory information
    local infoText = CM.selectedInventoryCharacter .. "'s Inventory\n\n"
    
    -- Add any relevant inventory information you want to keep
    if charData.gold then
        infoText = infoText .. "Gold: " .. GetCoinTextureString(charData.gold) .. "\n"
    end
    
    -- Add any other inventory information you want to display
    
    CM.inventoryText:SetText(infoText)
end

-- Format time function (converts seconds to a readable format)
function CM.FormatTime(seconds)
    if seconds <= 0 then
        return "0s"
    end
    
    if seconds < 60 then
        return string.format("%ds", seconds)
    elseif seconds < 3600 then
        local mins = math.floor(seconds / 60)
        local secs = seconds % 60
        return string.format("%dm %ds", mins, secs)
    elseif seconds < 86400 then
        local hours = math.floor(seconds / 3600)
        local mins = math.floor((seconds % 3600) / 60)
        return string.format("%dh %dm", hours, mins)
    else
        local days = math.floor(seconds / 86400)
        local hours = math.floor((seconds % 86400) / 3600)
        return string.format("%dd %dh", days, hours)
    end
end

    
    -- Create Settings tab
    function CM.CreateSettingsTab(parent)
        local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, -16)
        title:SetText("Character Manager Settings")
        
        -- Minimap button toggle
        local minimapToggle = CreateFrame("CheckButton", "CharacterManagerMinimapToggle", parent, "UICheckButtonTemplate")
        minimapToggle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)
        minimapToggle:SetChecked(not CM.db.minimapButton.hide)
        _G[minimapToggle:GetName() .. "Text"]:SetText("Show Minimap Button")
        
        minimapToggle:SetScript("OnClick", function(self)
            CM.db.minimapButton.hide = not self:GetChecked()
            if CM.db.minimapButton.hide then
                CM.minimapButton:Hide()
            else
                CM.minimapButton:Show()
            end
        end)
        
        -- Auto-update toggle
        local autoUpdateToggle = CreateFrame("CheckButton", "CharacterManagerAutoUpdateToggle", parent, "UICheckButtonTemplate")
        autoUpdateToggle:SetPoint("TOPLEFT", minimapToggle, "BOTTOMLEFT", 0, -10)
        autoUpdateToggle:SetChecked(CM.db.autoUpdate)
        _G[autoUpdateToggle:GetName() .. "Text"]:SetText("Automatically Update Character Data")
        
        autoUpdateToggle:SetScript("OnClick", function(self)
            CM.db.autoUpdate = self:GetChecked()
        end)
        
        -- Update frequency slider
        local updateFrequencySlider = CreateFrame("Slider", "CharacterManagerUpdateFrequencySlider", parent, "OptionsSliderTemplate")
        updateFrequencySlider:SetPoint("TOPLEFT", autoUpdateToggle, "BOTTOMLEFT", 0, -30)
        updateFrequencySlider:SetWidth(200)
        updateFrequencySlider:SetMinMaxValues(1, 60)
        updateFrequencySlider:SetValueStep(1)
        updateFrequencySlider:SetValue(CM.db.updateFrequency or 5)
        
        _G[updateFrequencySlider:GetName() .. "Low"]:SetText("1 min")
        _G[updateFrequencySlider:GetName() .. "High"]:SetText("60 min")
        _G[updateFrequencySlider:GetName() .. "Text"]:SetText("Update Frequency: " .. (CM.db.updateFrequency or 5) .. " minutes")
        
        updateFrequencySlider:SetScript("OnValueChanged", function(self, value)
            value = math.floor(value)
            _G[self:GetName() .. "Text"]:SetText("Update Frequency: " .. value .. " minutes")
            CM.db.updateFrequency = value
        end)
        
        -- Data retention slider
        local dataRetentionSlider = CreateFrame("Slider", "CharacterManagerDataRetentionSlider", parent, "OptionsSliderTemplate")
        dataRetentionSlider:SetPoint("TOPLEFT", updateFrequencySlider, "BOTTOMLEFT", 0, -30)
        dataRetentionSlider:SetWidth(200)
        dataRetentionSlider:SetMinMaxValues(1, 90)
        dataRetentionSlider:SetValueStep(1)
        dataRetentionSlider:SetValue(CM.db.dataRetentionDays or 30)
        
        _G[dataRetentionSlider:GetName() .. "Low"]:SetText("1 day")
        _G[dataRetentionSlider:GetName() .. "High"]:SetText("90 days")
        _G[dataRetentionSlider:GetName() .. "Text"]:SetText("Data Retention: " .. (CM.db.dataRetentionDays or 30) .. " days")
        
        dataRetentionSlider:SetScript("OnValueChanged", function(self, value)
            value = math.floor(value)
            _G[self:GetName() .. "Text"]:SetText("Data Retention: " .. value .. " days")
            CM.db.dataRetentionDays = value
        end)
        
        -- Reset button
        local resetButton = CreateFrame("Button", "CharacterManagerResetButton", parent, "UIPanelButtonTemplate")
        resetButton:SetSize(120, 25)
        resetButton:SetPoint("TOPLEFT", dataRetentionSlider, "BOTTOMLEFT", 0, -30)
        resetButton:SetText("Reset All Data")
        
        resetButton:SetScript("OnClick", function()
            StaticPopup_Show("CHARACTERMANAGER_RESET_CONFIRM")
        end)
        
        -- Create confirmation dialog
        StaticPopupDialogs["CHARACTERMANAGER_RESET_CONFIRM"] = {
            text = "Are you sure you want to reset all Character Manager data? This cannot be undone.",
            button1 = "Yes",
            button2 = "No",
            OnAccept = function()
                MyAddonDB = {}
                ReloadUI()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        
        -- Version info
        local versionText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        versionText:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -16, 16)
        versionText:SetText("Character Manager v" .. CM.version)
    end