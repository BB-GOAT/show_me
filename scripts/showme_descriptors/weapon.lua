-- weapon 组件：武器伤害（含增益与位面抵抗换算）、位面伤害与特殊伤害类型
-- 查询无特定目标时的武器基础伤害；不调用攻击流程或伪造目标。
local function GetWeaponDamage(weapon, viewer)
    if not weapon then
        return nil
    end
    local damage = weapon.damage
    if type(damage) == "function" then
        -- 与原版 FunctionOrValue 的参数一致
        damage = damage(weapon.inst, viewer, nil)
    end
    if type(damage) == "number" and damage == damage and damage >= 0 and damage < math.huge then
        return damage
    end
end

local Describe = function(self, context)
    -- item_info_mod：客户端显式开启优先，客户端为默认档(0)时跟随服务器设置
    local item_info_mod = context.config.client.item_info_mod
    if item_info_mod == 0 then
        item_info_mod = context.config.server.item_info_mod
    end
    if item_info_mod ~= 0 then
        return nil
    end
    local entity = context.entity
    local utils = context.utils
    local c = entity.components
    local entries = {}
    local has_entity_damage = type(entity.damage) == "number" and entity.damage > 0
    local damage = not has_entity_damage and GetWeaponDamage(self, context.player) or nil

    if has_entity_damage then
        table.insert(entries, { data_key = "dmg", params = { utils.round2(entity.damage, 1) } })
        if entity.basedamage and type(entity.basedamage) == "number" and entity.basedamage > 0 then
            table.insert(entries, { data_key = "basedmg", params = { utils.round2(entity.basedamage, 1) } })
        end
    elseif damage and damage > 0 then
        -- show_planar_resist：客户端显式关闭优先，客户端为默认档(true)时跟随服务器设置
        local show_planar_resist = context.config.client.show_planar_resist
        if show_planar_resist then
            show_planar_resist = context.config.server.show_planar_resist
        end
        local r = damage
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
        if show_planar_resist then
            pr_val = " ( " .. context.modenv.OTHER_TITLES.resist .. prval .. " )"
        end

        table.insert(entries, { data_key = "dmg", params = { utils.round2(r, 1) .. pr_val, tm_buff and utils.round2(tm_buff) } })

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
    end

    -- 位面伤害独立于物理伤害，纯位面武器也需要显示；不吃物理攻击增益。
    if not has_entity_damage
        and c.planardamage and type(c.planardamage.basedamage) == "number" and c.planardamage.basedamage > 0
    then
        table.insert(entries, { data_key = "basedmg", params = { utils.round2(math.floor(c.planardamage.basedamage)) } })
    end

    -- 射程与伤害独立：弹弓的 weapon.damage 为 0，伤害由弹药投射物提供
    if (c.health == nil or entity.grow_stage)
        and self.damage and type(self.attackrange) == "number" and self.attackrange > 0.3
    then
        table.insert(entries, { data_key = "range", params = { utils.round2(self.attackrange, 1) } })
    end
    return #entries > 0 and entries or nil
end

return {
    Describe = Describe,
}
