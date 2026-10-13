local Describe = function(self, context)
    local str = context.modenv.OTHER_TITLES -- 当前需要从模组环境获取语言数据
    local description = str.capacity .. self:GetMaterialTotal() .. " / " .. self.max_materials
    return {
        priority = 0,
        description = description,
    }
end

return {
	Describe = Describe
}