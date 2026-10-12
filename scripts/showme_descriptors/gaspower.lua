-- gaspower 组件：不灵气体（第三方模组信息）
local Describe = function(self, context)
    local o_t = context.modenv.OTHER_TITLES
    return { description = o_t.gaspowerpower .. "< " .. self.power .. " / " .. self.PowerMax .. " >" }
end

return {
    Describe = Describe,
}
