-- fuel 组件：建筑/物品的燃料燃烧总时长
local Describe = function(self, context)
    -- show_fuel：客户端显式关闭优先，客户端为默认档(true)时跟随服务器设置
    local show_fuel = context.config.client.show_fuel
    if show_fuel then
        show_fuel = context.config.server.show_fuel
    end
    if show_fuel == false or not self.fuelvalue then
        return nil
    end

    local o_t = context.modenv.OTHER_TITLES
    return { description = o_t.ot_fuelval .. context.utils.DataTimerFn(self.fuelvalue) }
end

return {
    Describe = Describe,
}
