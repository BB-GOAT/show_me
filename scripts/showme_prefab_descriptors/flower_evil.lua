-- flower_evil：恶魔花：显示查看者采摘时的精神变化
local Describe = function(context)
    local skilltree = context.player.components.skilltreeupdater
    local delta = -TUNING.SANITY_TINY
    if skilltree and skilltree:IsActivated("wendy_gravestone_1") then
        delta = TUNING.SANITY_TINY
    end
    return { data_key = "sanity", params = { delta, 1 } }
end

return {
    Describe = Describe,
}
