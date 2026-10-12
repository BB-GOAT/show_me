-- weapon 组件：武器伤害（含增益与位面抵抗换算）、位面伤害与特殊伤害类型
-- 注册 weapon 与 zupalexsrangedweapons（远程武器 mod）两个键，逻辑内部按优先级互斥
local Describe = function(self, context)
    if context.config.client.item_info_mod ~= 0 then
        return nil
    end
    local entity = context.entity
    local utils = context.utils
    local c = entity.components

    if entity.damage and type(entity.damage) == "number" and entity.damage > 0 then
        local entries = { { data_key = "dmg", params = { utils.round2(entity.damage, 1) } } }
        if entity.basedamage and type(entity.basedamage) == "number" and entity.basedamage > 0 then
            table.insert(entries, { data_key = "basedmg", params = { utils.round2(entity.basedamage, 1) } })
        end
        return entries
    end

    if c.weapon ~= nil and c.weapon.damage and type(c.weapon.damage) == "number" and c.weapon.damage > 0 then
        local r = c.weapon.damage
        local tm_buff = utils.GetDebuffTime(context.player, "buff_attack")
        if tm_buff then
            local power = TUNING[utils.KNOWN_BUFFS.buff_attack.power]
            if power then
                r = r * power
            end
        end
        -- 位面伤害对暗影/梦魇怪的等效抵抗换算
        local prval = tostring(utils.round2((math.sqrt(r * 4 + 64) - 8) * 4, 1))
        local pr_val = ""
        if context.config.client.show_planar_resist then
            pr_val = " ( " .. context.modenv.OTHER_TITLES.resist .. prval .. " )"
        end

        local entries = {
            { data_key = "dmg", params = { utils.round2(r, 1) .. pr_val, tm_buff and utils.round2(tm_buff) } },
        }

        -- 武器/工具的位面伤害，不吃增益
        if c.planardamage ~= nil and c.planardamage.basedamage and type(c.planardamage.basedamage) == "number" and c.planardamage.basedamage > 0 then
            table.insert(entries, { data_key = "basedmg", params = { utils.round2(math.floor(c.planardamage.basedamage)) } })
        end

        -- 吸收分类 mod 支持
        if entity.phys_dmg then
            local p = entity.phys_dmg == "blunt" and "Blunt" or (
                entity.phys_dmg == "pierc" and "Piercing" or (
                    entity.phys_dmg == "slash" and "Slashing" or nil
                )
            )
            if p ~= nil then
                table.insert(entries, { description = "Type: " .. p })
            end
        end

        -- 武器攻击范围（原版为独立显示块，随伤害一并迁入）
        if c.weapon.attackrange and type(c.weapon.attackrange) == "number" and c.weapon.attackrange > 0.3 then
            table.insert(entries, { data_key = "range", params = { utils.round2(c.weapon.attackrange, 1) } })
        end
        return entries
    end

    local zrw = c.zupalexsrangedweapons -- 远程武器 mod 的弓箭
    if zrw ~= nil and zrw.GetArrowBaseDamage ~= nil and type(zrw.GetArrowBaseDamage) == "function" then
        local dmg = zrw:GetArrowBaseDamage()
        if dmg ~= nil and type(dmg) == "number" and dmg > 0 then
            return { { data_key = "dmg", params = { utils.round2(dmg, 1) } } }
        end
    end

    return nil
end

return {
    Describe = Describe,
}
