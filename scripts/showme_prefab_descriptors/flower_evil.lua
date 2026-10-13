-- flower_evil：恶魔花的噩梦光环——靠近掉精神，以负回san显示
local Describe = function(context)
    return { data_key = "sanity", params = { -TUNING.SANITY_TINY, 1 } }
end

return {
    Describe = Describe,
}
