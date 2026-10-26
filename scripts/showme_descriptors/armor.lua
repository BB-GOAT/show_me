-- armor 组件：护甲防御（含增益）、位面防御、吸收分类与耐久
local Describe = function(self, context)
    -- item_info_mod：客户端显式开启优先，客户端为默认档(0)时跟随服务器设置
    local item_info_mod = context.config.client.item_info_mod
    if item_info_mod == 0 then
        item_info_mod = context.config.server.item_info_mod
    end
    if item_info_mod ~= 0 then
        return nil
    end
    if not (self.absorb_percent and type(self.absorb_percent) == "number") then
        return nil
    end

    local entity = context.entity
    local utils = context.utils

    local r = self.absorb_percent -- 0.8
    local tm_buff = utils.GetDebuffTime(context.player, "buff_playerabsorption")
    if tm_buff then
        local power = TUNING[utils.KNOWN_BUFFS.buff_playerabsorption.power]
        if power then
            r = r + (1 - r) * power
        end
    end

    local entries = {
        { data_key = "armor", params = { utils.round2(r * 100, 0), tm_buff and utils.round2(tm_buff) } },
    }

    -- 位面防御
    local planardefense = entity.components.planardefense
    local defense = planardefense and planardefense:GetDefense()
    if type(defense) == "number" and defense > 0 then
        table.insert(entries, {
            data_key = "basearmor",
            params = { utils.round2(defense, 0) .. context.modenv.OTHER_TITLES.point },
        })
    end

    -- 吸收分类 mod 支持
    local phys = entity.phys
    if phys and (phys.blunt or phys.pierc or phys.slash) then
        table.insert(entries, {
            data_key = "absorb",
            params = { (phys.blunt or 0) .. " / " .. (phys.pierc or 0) .. " / " .. (phys.slash or 0) },
        })
    end

    -- 耐久度
    if self.condition and self.condition > 0 and self.maxcondition and not entity:HasTag("hide_percentage") then
        table.insert(entries, {
            data_key = "durability",
            params = { math.floor(self.condition + 0.5), math.floor(self.maxcondition + 0.5) },
        })
    end

    return entries
end

return {
    Describe = Describe,
}
