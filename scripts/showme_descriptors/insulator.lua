-- insulator 组件：保暖（冬）/隔热（夏）数值
local Describe = function(self, context)
    -- item_info_mod：客户端显式开启优先，客户端为默认档(0)时跟随服务器设置
    local item_info_mod = context.config.client.item_info_mod
    if item_info_mod == 0 then
        item_info_mod = context.config.server.item_info_mod
    end
    if item_info_mod ~= 0 then
        return nil
    end
    if not (self.insulation and type(self.insulation) == "number" and self.insulation ~= 0) then
        return nil
    end

    local entries = {}
    if self.SetInsulationEx then -- 服务器扩展接口，可同时提供冬夏数值
        local winter, summer = self:GetInsulationEx()
        if winter ~= 0 then
            table.insert(entries, { data_key = "warm", params = { context.utils.round2(winter, 0) } })
        end
        if summer ~= 0 then
            table.insert(entries, { data_key = "summer", params = { context.utils.round2(summer, 0) } })
        end
    elseif self.GetInsulation then
        local insul, typ = self:GetInsulation()
        if insul ~= 0 then
            if typ == SEASONS.WINTER then
                table.insert(entries, { data_key = "warm", params = { context.utils.round2(insul, 0) } })
            elseif typ == SEASONS.SUMMER then
                table.insert(entries, { data_key = "summer", params = { context.utils.round2(insul, 0) } })
            end
        end
    end

    if #entries == 0 then
        return nil
    end
    return entries
end

return {
    Describe = Describe,
}
