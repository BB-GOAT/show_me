-- winter_tree：冬季盛宴树的礼物冷却
local Describe = function(context)
    local giftable = context.player.components.wintertreegiftable
    if not (giftable and giftable.GetDaysSinceLastGift) then
        return nil
    end
    local days = giftable:GetDaysSinceLastGift()
    if type(days) ~= "number" then
        return nil
    end

    local strings = context.modenv.MY_STRINGS
    if days >= 4 then
        return { description = strings.winter_gift_ready }
    end
    return { description = string.format(strings.winter_gift_wait, math.ceil(4 - days)) }
end

return {
    tags = { winter_tree = true },
    Describe = Describe,
}
