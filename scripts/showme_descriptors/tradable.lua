-- tradable 组件：物品价值 -- TODO 兼容岛屿冒险的交易方式
local Describe = function(self, context)
    local entries = {}
    if self.goldvalue and self.goldvalue > 1 then -- 价值金块
        table.insert(entries, { data_key = "trade_gold", params = { self.goldvalue } })
    end
    if self.rocktribute and self.rocktribute > 0 and TheWorld.state.issummer then -- 价值石头(仅在夏季显示)
        table.insert(entries, { data_key = "trade_rock", params = { self.rocktribute } })
    end
    if #entries == 0 then
        return nil
    end
    return entries
end

return {
    Describe = Describe,
}
