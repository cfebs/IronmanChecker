util = {}

function util.check_all()
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
    print('Starting check...')

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

SLASH_IRONCHECK1 = "/ironmanchecker"
SLASH_IRONCHECK2 = "/ironcheck"
SlashCmdList["IRONCHECK"] = function(self, txt)
    util.check_all()
end
