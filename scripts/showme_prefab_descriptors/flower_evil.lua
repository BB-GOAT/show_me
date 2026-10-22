-- flower_evil：恶魔花：显示靠近时的精神损失
local Describe = function(context)
    return { data_key = "sanity", params = { -TUNING.SANITY_TINY, 1 } }
end

return {
    Describe = Describe,
}
