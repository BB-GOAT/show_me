-- combat 组件：增伤、攻击力（PVP 修正）、位面伤害/抵抗与 AoE
local is_PvP = TheNet:GetDefaultPvpSetting() --PVP

local Describe = function(self, context)
    local entity = context.entity
    local utils = context.utils
    local entries = {}

    -- item_info_mod：客户端显式开启优先，客户端为默认档(0)时跟随服务器设置
    local item_info_mod = context.config.client.item_info_mod
    if item_info_mod == 0 then
        item_info_mod = context.config.server.item_info_mod
    end
    -- show_planar_resist：客户端显式关闭优先，客户端为默认档(true)时跟随服务器设置
    local show_planar_resist = context.config.client.show_planar_resist
    if show_planar_resist then
        show_planar_resist = context.config.server.show_planar_resist
    end

    if self.damagemultiplier and self.damagemultiplier ~= 1 then
        --伤害增加百分比。 例如，女武神 +25%
        table.insert(entries, { data_key = "dmg_character", params = { utils.round2((self.damagemultiplier - 1) * 100, 0) } })
    end

    if self.defaultdamage and self.defaultdamage > 0 then
        local dmg = self.defaultdamage
        local pvp_perc = tonumber(self.playerdamagepercent) --玩家 NPC 伤害修正，仅适用于无武器
        if pvp_perc then
            if pvp_perc == 1 or not is_PvP and entity.prefab == "abigail" then
                pvp_perc = nil
            else
                pvp_perc = utils.round2((pvp_perc - 1) * 100)
            end
        end
        table.insert(entries, { data_key = "strength", params = { tostring(utils.round2(dmg, 1)), pvp_perc } })

        local planardamage = entity.components.planardamage
        if planardamage and planardamage.basedamage and planardamage.basedamage > 0 then
            --位面伤害不计算小数？向下整取试试, 不知有没pvp
            table.insert(entries, { data_key = "basedmg", params = { math.floor(planardamage.basedamage) } })
        end

        if show_planar_resist and entity.components.planarentity then
            table.insert(entries, { description = context.modenv.OTHER_TITLES.dmgresist })
        end

        if self.areahitdamagepercent then --AoE
            table.insert(entries, { data_key = "aoe", params = { math.floor(dmg * self.areahitdamagepercent + 0.5) } })
        end
    end

    -- 攻击范围：原版范围链的 combat 兑底分支（纯 combat 物品），
    -- 生物/武器/投射物场景分别由 health、weapon、range 描述文件处理
    if item_info_mod == 0
        and (entity.components.health == nil or entity.grow_stage)
        and entity.components.weapon == nil
        and entity.components.projectile == nil
        and self.attackrange and type(self.attackrange) == "number" and self.attackrange > 2.5
    then
        table.insert(entries, { data_key = "range", params = { utils.round2(self.attackrange, 1) } })
    end

    if #entries == 0 then
        return nil
    end
    return entries
end

return {
    Describe = Describe
}
