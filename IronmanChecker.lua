local util = {}

function util.check_gear()
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
    print('>> Starting gear check...')

    for _, slot_name in ipairs(SLOTS) do
        print('Checking:' .. slot_name)
        local result, quality_idx, item_id = util.check_max_quality(slot_name, QUALITY_COMMON)
        if result then
            print('OK:' .. slot_name)
        else
            print('ERROR:' .. slot_name .. ' has quality ' .. quality_idx)
        end
    end
end

function util.check_talents()
    print('>> Starting talent check...')
    local total_talents = 0
    local num_tabs = GetNumTalentTabs()

    for i = 1, GetNumTalentTabs() do
        local name, _, pointsSpent = GetTalentTabInfo(i, false, false)
        total_talents = total_talents + pointsSpent
    end

    if total_talents == 0 then
        print('OK: no talents learned')
    end
    print('ERROR: ' .. total_talents .. ' talents learned')
end

function util.check_professions()
    print('>> Starting profession check...')
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
                print('ERROR: found bad profession: ' .. skill)
                return false
            end
        end
    end

    print('OK: professions')
    return true
end

-- check slot on target, if quality idx > max_quality return false
-- returns check_bool, quality_idx|nil, item_id|nil
function util.check_max_quality(slot_str, max_quality, target)
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

function util.check_aura()
    print('>> Starting aura check...')
    local player_applied = {}
    local all_helpful = {}

    -- get all helpful but cancelable
    print('-- All helpful')
    for i=1, 40 do
        local aura_name = UnitAura("player", i, "HELPFUL|CANCELABLE")
        if aura_name == nil then
            break
        end
        print('  ' .. aura_name)
        all_helpful[aura_name] = 1
    end

    -- remove those the player casted
    print('-- Player casted')
    for i=1, 40 do
        local aura_name = UnitAura("player", i, "PLAYER|HELPFUL|CANCELABLE")
        if aura_name == nil then
            break
        end

        print('  ' .. aura_name)
        all_helpful[aura_name] = 0
    end

    total_helpful = 0
    for k, v in pairs(all_helpful) do
        if v == 1 then
            print('ERROR: found helpful cancelable buff not casted by player: ' .. k)
            return false
        end
    end

    print('OK: auras')
    return true
end

function util.check_all()
    util.check_gear()
    util.check_talents()
    util.check_professions()
    util.check_aura()
end

SLASH_IRONCHECK1 = "/ironmanchecker"
SLASH_IRONCHECK2 = "/ironcheck"
SlashCmdList["IRONCHECK"] = function(self, txt)
    util.check_all()
end
