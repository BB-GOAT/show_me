-- charged_days：避雷针/灯等充能物品的剩余可用天数（chargeleft 是实体自由字段，非组件）
local Describe = function(context)
    local chargeleft = context.entity.chargeleft
    if not chargeleft or chargeleft <= 0 then
        return nil
    end
    local modenv = context.modenv
    return { description = modenv.OTHER_TITLES.will_other .. tostring(math.floor(chargeleft + 0.5)) .. modenv.SHOWME_STRINGS.days }
end

return {
    fields = { chargeleft = true },
    Describe = Describe,
}
