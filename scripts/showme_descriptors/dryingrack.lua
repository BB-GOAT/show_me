-- dryingrack 组件：新晾肉架
local Describe = function(self, context)
    if not self.GetDryingInfoSnapshot then
        return nil
    end
    local snapshot = self:GetDryingInfoSnapshot()
    if not snapshot then
        return nil
    end

    local o_t = context.modenv.OTHER_TITLES
    local entries = {}
    for k, v in pairs(snapshot) do
        if type(v) == "number" then
            table.insert(entries, { description = (k.name or k.prefab or tostring(k)) .. " " .. o_t.will_other .. context.utils.round2(v / TUNING.TOTAL_DAY_TIME, 1) .. context.modenv.SHOWME_STRINGS.days })
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
