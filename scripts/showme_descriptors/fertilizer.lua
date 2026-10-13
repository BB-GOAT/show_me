-- fertilizer 组件：肥料值（作物三种养分含量，按 show_nutrients 档位显示详细/简洁格式）
local Describe = function(self, context)
    -- show_nutrients：客户端显式设置优先，客户端为默认档(1)时跟随服务器设置
    local show_nutrients = context.config.client.show_nutrients
    if show_nutrients == 1 then
        show_nutrients = context.config.server.show_nutrients
    end
    if show_nutrients == false then
        return nil
    end
    local o_t = context.modenv.OTHER_TITLES
    local n = self.nutrients
    if show_nutrients == 1 then
        return { description = o_t.nutrients_1 .. n[1] .. " / " .. o_t.nutrients_2 .. n[2] .. " / " .. o_t.nutrients_3 .. n[3] }
    elseif show_nutrients == 2 then
        return { description = o_t.nutrients .. n[1] .. " / " .. n[2] .. " / " .. n[3] }
    end
    return nil
end

return {
    Describe = Describe
}
