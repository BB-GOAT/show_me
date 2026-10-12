-- 攻击范围：武器的范围由 weapon.lua 随伤害输出，纯 combat 物品的范围由 combat.lua 输出，本文件处理投射物
-- 注册 projectile 键触发
local Describe = function(self, context)
    if context.config.client.item_info_mod ~= 0 then
        return nil
    end
    local entity = context.entity
    local c = entity.components
    if c.health and not entity.grow_stage then
        return nil -- 生物不显示攻击范围（原版行为）
    end
    if c.weapon and c.weapon.attackrange and type(c.weapon.attackrange) == "number" and c.weapon.attackrange > 0.3 then
        return nil -- 武器自身范围由 weapon.lua 输出，避免重复
    end

    local r
    if c.projectile and c.projectile.damage and type(c.projectile.range) == "number" and c.projectile.range > 0.3 then
        r = c.projectile.range
    elseif c.combat and c.combat.damage and type(c.combat.attackrange) == "number" and c.combat.attackrange > 2.5 then
        r = c.combat.attackrange
    end
    if not r then
        return nil
    end
    return {
        data_key = "range",
        params = { context.utils.round2(r, 1) },
    }
end

return {
    Describe = Describe,
}
