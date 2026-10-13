-- cannonball_rock_item：炮弹
local Describe = function(context)
    return { data_key = "dmg", params = { TUNING.CANNONBALL_DAMAGE } } -- 返回固定伤害
end

return {
    Describe = Describe,
}
