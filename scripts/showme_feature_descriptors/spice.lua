-- spice：调味料粉末 的食用BUFF预览
local BUFF_KEY = {
    spice_garlic = { buff = "buff_playerabsorption", delta = 1 }, -- 蒜粉功率需 +1（吸收倍率制）
    spice_chili = { buff = "buff_attack", delta = 0 },
    spice_sugar = { buff = "buff_workeffectiveness", delta = 0 },
}

local Describe = function(context)
    local cfg = BUFF_KEY[context.entity.prefab]
    local data = context.utils.KNOWN_BUFFS[cfg.buff]
    return { data_key = "buff", params = { data.name, 0, TUNING[data.power] + cfg.delta } }
end

return {
    prefabs = { spice_garlic = true, spice_chili = true, spice_sugar = true },
    Describe = Describe,
}
