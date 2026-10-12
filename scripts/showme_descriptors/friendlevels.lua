-- friendlevels 组件：好感度（猪人/兔人等跟随者的好感等级）
local Describe = function(self, context)
    return {
        data_key = "friendlevels",
        params = { context.utils.round2(self.level, 0) },
    }
end

return {
    Describe = Describe,
}
