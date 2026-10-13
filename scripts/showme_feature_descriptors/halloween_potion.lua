-- halloween_potion：万圣节药水的效果说明（生命/理智药水显示词条，勇气药水显示持续时间）
local OTHER_TAG = {
    halloweenpotion_health_large = "halloweenpotion_health",
    halloweenpotion_health_small = "halloweenpotion_health",
    halloweenpotion_sanity_large = "halloweenpotion_sanity",
    halloweenpotion_sanity_small = "halloweenpotion_sanity",
}
local BRAVERY_TIME = {
    halloweenpotion_bravery_small = 0.5,
    halloweenpotion_bravery_large = 0.75,
}

local Describe = function(context)
    local prefab = context.entity.prefab
    local other_tag = OTHER_TAG[prefab]
    if other_tag then
        return { data_key = "other_tag", params = { other_tag } }
    end
    local potion_time = BRAVERY_TIME[prefab]
    if potion_time then
        return { description = string.format(context.modenv.OTHER_TITLES.hpotion_bravery, potion_time) }
    end
    return nil
end

return {
    prefabs = { halloweenpotion_health_large = true, halloweenpotion_health_small = true, halloweenpotion_sanity_large = true, halloweenpotion_sanity_small = true, halloweenpotion_bravery_small = true, halloweenpotion_bravery_large = true },
    Describe = Describe,
}
