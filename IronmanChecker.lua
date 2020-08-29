IronmanChecker_Init = false
IronmanChecker_UpdateInterval = 15
IronmanChecker_LastUpdate = 0
IronmanCheckerEditBox = nil
IronmanCheckerEditBoxEditBox = nil
IronmanCheckerEditBoxScrollFrame = nil

IronmanChecker_Util = {}

function IronmanChecker_Util.debug(str)
    if not IronmanCheckerDB then
        print('IronmanChecker_Util.debug: No DB ' .. str)
    end

    if not IronmanCheckerDB["Debug"] then
        return
    end

    print('IronmanChecker_Util.debug: ' .. str)
end

-- return: bool, msg|nil
function IronmanChecker_Util:check_gear()
    local QUALITY_COMMON = 1
    local SLOTS = {
        "AmmoSlot",
        "BackSlot",
        "ChestSlot",
        "FeetSlot",
        "Finger0Slot",
        "Finger1Slot",
        "HandsSlot",
        "LegsSlot",
        "MainHandSlot",
        "NeckSlot",
        "RangedSlot",
        "SecondaryHandSlot",
        "ShirtSlot",
        "ShoulderSlot",
        "TabardSlot",
        "Trinket0Slot",
        "Trinket1Slot",
        "WaistSlot",
        "WristSlot",
    }
    self.debug('>> Starting gear check...')

    for _, slot_name in ipairs(SLOTS) do
        self.debug('Checking:' .. slot_name)
        local result, quality_idx, _ = IronmanChecker_Util.check_max_quality(slot_name, QUALITY_COMMON)
        if result then
            self.debug('OK:' .. slot_name)
        else
            self.debug('ERROR:' .. slot_name .. ' has quality ' .. quality_idx)
            return false, slot_name .. ' has quality ' .. quality_idx
        end
    end

    return true, nil
end

-- return bool, msg|nil
function IronmanChecker_Util:check_talents()
    self.debug('>> Starting talent check...')
    local total_talents = 0

    for i = 1, GetNumTalentTabs() do
        local _, _, pointsSpent = GetTalentTabInfo(i, false, false)
        total_talents = total_talents + pointsSpent
    end

    if total_talents == 0 then
        self.debug('OK: no talents learned')
        return true, nil
    end
    self.debug('ERROR: ' .. total_talents .. ' talents learned')

    return false, total_talents .. ' talents learned'
end

function IronmanChecker_Util:check_professions()
    self.debug('>> Starting profession check...')
    local bad_skills = {
        ["Alchemy"] = 1,
        ["Blacksmithing"] = 1,
        ["Enchanting"] = 1,
        ["Engineering"] = 1,
        ["Herbalism"] = 1,
        ["Inscription"] = 1,
        ["Jewelcrafting"] = 1,
        ["Leatherworking"] = 1,
        ["Mining"] = 1,
        ["Skinning"] = 1,
        ["Tailoring"] = 1,
        --
        ["Fishing"] = 1,
        ["Cooking"] = 1,
    }

    local num_skills = GetNumSkillLines()
    for i = 1, num_skills do
        local skill, is_header = GetSkillLineInfo(i);
        if not is_header then
            if bad_skills[skill] == 1 then
                self.debug('ERROR: found bad profession: ' .. skill)
                return false, 'found bad profession: ' .. skill
            end
        end
    end

    self.debug('OK: professions')
    return true, nil
end

-- check slot on target, if quality idx > max_quality return false
-- returns check_bool, quality_idx|nil, item_id|nil
function IronmanChecker_Util.check_max_quality(slot_str, max_quality, target)
    target = target or "player"
    local slot_id = GetInventorySlotInfo(slot_str)
    local item_id = GetInventoryItemID(target, slot_id)
    local quality_idx = GetInventoryItemQuality(target, slot_id)

    if quality_idx == nil then
        return true, nil, nil
    end

    -- print('check_max_quality ' .. slot_str .. ' ' .. max_quality .. ' ' .. quality_idx .. ' ' .. target)
    if quality_idx > max_quality then
        return false, quality_idx, item_id
    end

    return true, nil, item_id
end

function IronmanChecker_Util:check_aura()
    self.debug('>> Starting aura check...')
    local all_helpful = {}

    -- get all helpful but cancelable
    self.debug('-- All helpful')
    for i=1, 40 do
        local aura_name = UnitAura("player", i, "HELPFUL|CANCELABLE")
        if aura_name == nil then
            break
        end
        print('  ' .. aura_name)
        all_helpful[aura_name] = 1
    end

    -- remove those the player casted
    self.debug('-- Player casted')
    for i=1, 40 do
        local aura_name = UnitAura("player", i, "PLAYER|HELPFUL|CANCELABLE")
        if aura_name == nil then
            break
        end

        self.debug('  ' .. aura_name)
        all_helpful[aura_name] = 0
    end

    for k, v in pairs(all_helpful) do
        if v == 1 then
            self.debug('ERROR: found helpful cancelable buff not casted by player: ' .. k)
            return false, 'found helpful cancelable buff not casted by player: ' .. k
        end
    end

    self.debug('OK: auras')
    return true, nil
end

function IronmanChecker_Util:check_death()
    local count = 0
    if IronmanCheckerDB and not (IronmanCheckerDB["DeathCount"] == nil) and IronmanCheckerDB["DeathCount"] >= 0 then
        count = IronmanCheckerDB["DeathCount"]
    end

    if count > 0 then
        self.debug('ERROR: ' .. count .. ' is more than 0 deaths')
        return false, "died " .. count .. " times"
    end

    self.debug('OK: no deaths ' .. count)
    return true, nil
end

function IronmanChecker_Util.check_all()
    -- over all checks
    local full_out = ''
    local failures = 0

    -- per check
    local result = true
    local msg = ''

    full_out = full_out .. 'Ironcheck at ' .. date() .. "\n"

    result, msg = IronmanChecker_Util:check_death()
    if not result then
        failures = failures + 1
        full_out = full_out .. "[FAIL] Death check: " .. msg .. "\n"
    end

    result, msg = IronmanChecker_Util:check_gear()
    if not result then
        failures = failures + 1
        full_out = full_out .. "[FAIL] Gear check: " .. msg .. "\n"
    end

    result, msg = IronmanChecker_Util:check_talents()
    if not result then
        failures = failures + 1
        full_out = full_out .. "[FAIL] Talent check: " .. msg .. "\n"
    end

    result, msg = IronmanChecker_Util:check_professions()
    if not result then
        failures = failures + 1
        full_out = full_out .. "[FAIL] Profession check: " .. msg .. "\n"
    end

    result, msg = IronmanChecker_Util:check_aura()
    if not result then
        failures = failures + 1
        full_out = full_out .. "[FAIL] Aura check " .. msg .. "\n"
    end

    if failures > 0 then
        IronmanChecker_ShowFrame(full_out)
        return
    end

    IronmanChecker_ShowFrame(full_out .. 'All good')
end

-- creates frame if doesn't exist, does not show frame
-- return: frame, editbox
function IronmanChecker_CreateFrame()
    if IronmanCheckerEditBox then
        return IronmanCheckerEditBox, IronmanCheckerEditBoxEditBox
    end

    local timerFrame = CreateFrame("Frame", "IronmanCheckerTimer", UIParent)
    timerFrame:SetSize(0, 0)
    timerFrame:SetPoint("BOTTOM")
    timerFrame:Show()

    -- Example from: https://www.wowinterface.com/forums/showpost.php?p=336114&postcount=5
    local f = CreateFrame("Frame", "IronmanCheckerEditBox", UIParent, "DialogBoxFrame")
    f:SetPoint("CENTER")
    f:SetSize(600, 300)

    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight", -- this one is neat
        edgeSize = 16,
        insets = { left = 8, right = 6, top = 8, bottom = 8 },
    })
    f:SetBackdropBorderColor(0, .44, .87, 0.5) -- darkblue

    -- Movable
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self:StartMoving()
        end
    end)
    f:SetScript("OnMouseUp", f.StopMovingOrSizing)

    -- ScrollFrame
    local sf = CreateFrame("ScrollFrame", "IronmanCheckerEditBoxScrollFrame",
        IronmanCheckerEditBox, "UIPanelScrollFrameTemplate")

    sf:SetPoint("LEFT", 16, 0)
    sf:SetPoint("RIGHT", -32, 0)
    sf:SetPoint("TOP", 0, -16)
    -- TODO sf:SetPoint("BOTTOM", IronmanCheckerEditBoxButton, "TOP", 0, 0)

    -- EditBox
    local eb = CreateFrame("EditBox", "IronmanCheckerEditBoxEditBox", IronmanCheckerEditBoxScrollFrame)
    eb:SetSize(sf:GetSize())
    eb:SetMultiLine(true)
    eb:SetAutoFocus(false) -- dont automatically focus
    eb:SetFontObject("ChatFontNormal")
    eb:SetScript("OnEscapePressed", function() f:Hide() end)
    sf:SetScrollChild(eb)

    -- Resizable
    f:SetResizable(true)
    f:SetMinResize(150, 100)

    local rb = CreateFrame("Button", "IronmanCheckerEditBoxResizeButton", IronmanCheckerEditBox)
    rb:SetPoint("BOTTOMRIGHT", -6, 7)
    rb:SetSize(16, 16)

    rb:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    rb:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    rb:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

    rb:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            f:StartSizing("BOTTOMRIGHT")
            self:GetHighlightTexture():Hide() -- more noticeable
        end
    end)

    rb:SetScript("OnMouseUp", function(self)
        f:StopMovingOrSizing()
        self:GetHighlightTexture():Show()
        eb:SetWidth(sf:GetWidth())
    end)

    -- On addon load: init slash checks and data
    local initDB = function()
        IronmanCheckerDB = {}
        IronmanCheckerDB["Debug"] = false
        IronmanCheckerDB["DeathCount"] = 0
    end

    local slashUsage = function()
        print('Usage: /ironcheck [check||debug||reset||help]')
        print('  check: performs ironman checks')
        print('  debug: toggles debug messages')
        print('  reset: resets stored data (death count etc)')
        print('  help: displays this help')
    end

    local registerSlash = function()
        SLASH_IRONCHECK1 = "/ironmanchecker"
        SLASH_IRONCHECK2 = "/ironcheck"
        SlashCmdList["IRONCHECK"] = function(msg)
            local tokeni = 0
            for token in string.gmatch(msg, "[^%s]+") do
                tokeni = tokeni + 1

                -- print('token i:' .. tokeni .. ' token:' .. token)
                if tokeni == 1 and token == 'help' then
                    slashUsage()
                    return
                end

                if tokeni == 1 and token == 'debug' then
                    IronmanCheckerDB["Debug"] = not IronmanCheckerDB["Debug"]
                    print('Set debug to ' .. (IronmanCheckerDB["Debug"] and 'true' or 'false'))
                    return
                end

                if tokeni == 1 and token == 'check' then
                    IronmanChecker_Util.check_all()
                    return
                end

                if tokeni == 1 and token == 'reset' then
                    initDB()
                    print('Reset IronmanCheckerDB')
                    return
                end
            end

            print('Command not found')
            slashUsage()
        end

    end

    -- call this on login
    local init = function()
        print('Ironcheck init')
        if not IronmanCheckerDB then
            initDB()
        end

        registerSlash()

        IronmanChecker_Init = true
    end

    local eventHandlers = {}
    function eventHandlers.PLAYER_DEAD()
        IronmanCheckerDB["DeathCount"] = IronmanCheckerDB["DeathCount"] + 1
        -- check again on death
        IronmanChecker_Util.check_all()
    end

    function eventHandlers.PLAYER_LOGIN()
        f:UnregisterEvent("PLAYER_LOGIN")
        init()
        -- first check on login
        IronmanChecker_Util.check_all()
    end


    local function parentHandler(_, event)
        -- print('Got event: ' .. event)
        if eventHandlers[event] then
            -- print('Calling handler: ' .. event)
            eventHandlers[event](event)
        end
    end

    local function onLoopHandler(_, elapsed)
        if not IronmanChecker_Init then
            return
        end

        IronmanChecker_LastUpdate = IronmanChecker_LastUpdate + elapsed;
        if (IronmanChecker_LastUpdate > IronmanChecker_UpdateInterval) then
            -- on update interval
            IronmanChecker_Util.check_all()
            IronmanChecker_LastUpdate = 0;
        end
    end

    f:RegisterEvent("PLAYER_DEAD");
    f:RegisterEvent("PLAYER_LOGIN");
    f:SetScript("OnEvent", parentHandler);

    timerFrame:SetScript('OnUpdate', onLoopHandler)

    return f, eb
end

function IronmanChecker_ShowFrame(text)
    local frame, editbox = IronmanChecker_CreateFrame()
    if text then
        editbox:SetText(text)
    end
    frame:Show()
end

IronmanChecker_CreateFrame()
