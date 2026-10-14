-- unwrappable 组件：捆绑包内容清单（每样一条：名称由客户端渲染，含数量与保鲜剩余天数）
local Describe = function(self, context)
    -- show_buddle_item：客户端显式设置优先，客户端为默认档(1)时跟随服务器设置
    local show_buddle_item = context.config.client.show_buddle_item
    if show_buddle_item == 1 then
        show_buddle_item = context.config.server.show_buddle_item
    end
    if show_buddle_item ~= 1 or type(self.itemdata) ~= "table" then
        return nil
    end

    local entries = {}
    for _, v in ipairs(self.itemdata) do
        if v.prefab then
            --发送预制件的名称和天数。delta 可为 nil：第三参条件插入，避免 params 表尾 nil 让 unpack 展开数不确定
            local delta = v.data and v.data.perishable and v.data.perishable.time
            local count = v.data and v.data.stackable and v.data.stackable.stack
            local params = { v.prefab, count or 0 }
            if delta then
                params[3] = context.utils.round2(delta / TUNING.TOTAL_DAY_TIME, 2)
            end
            table.insert(entries, { data_key = "perish_product", params = params })
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
