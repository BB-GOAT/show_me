-- pearldecorationscore 组件：寄居蟹房子的装饰度评分
local Describe = function(self, context)
    if not self.GetScore then
        return nil
    end
    local o_t = context.modenv.OTHER_TITLES
    local line = o_t.decor_score .. tostring(context.utils.round2(self:GetScore(), 1))
    if self.IsEnabled then
        line = line .. (self:IsEnabled()
            and ""
            or " (" .. o_t.decor_disabled .. ")")
    end
    return { description = line }
end

return {
    Describe = Describe,
}
