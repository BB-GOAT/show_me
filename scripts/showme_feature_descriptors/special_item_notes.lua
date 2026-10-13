-- special_item_notes：特定物品的专属说明词条
local SPECIAL_TAG = {
    slingshot_frame_wagpunk = "slingshot_frame_wagpunk_0",
}

local Describe = function(context)
    local prefab = context.entity.prefab
    return { data_key = "other_tag", params = { SPECIAL_TAG[prefab] or prefab } }
end

return {
    prefabs = {
        slingshot_frame_wagpunk = true, slingshot_frame_wagpunk_0 = true,
        wx78module_taser = true, wx78module_nightvision = true, wx78module_light = true,
        slingshotammo_thulecite = true, slingshotammo_freeze = true, slingshotammo_poop = true,
        wolfgang_whistle = true, lileaves = true, rosorns = true, shark_teethhat = true,
        brainjellyhat = true, gashat = true, onemanband = true, armorseashell = true,
        book_birds = true, book_brimstone = true, book_gardening = true, book_silviculture = true, book_sleep = true,
        slingshot_frame_bone = true, slingshot_frame_gems = true, slingshot_handle_voidcloth = true,
    },
    Describe = Describe,
}
