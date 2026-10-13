-- orchitwigs：兰草穗的挥击群体伤害（目前只能写死伤害）
local Describe = function(context)
    local weapon = context.entity.components.weapon
    if not (weapon and weapon.onattack) then
        return nil
    end
    return { data_key = "aoe", params = { TUNING.BASE_SURVIVOR_ATTACK * 0.7 } }
end

return {
    Describe = Describe,
}
