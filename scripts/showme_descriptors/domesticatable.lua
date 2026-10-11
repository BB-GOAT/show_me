-- domesticatable 组件：驯服度
local Describe = function(self, context)
    local utils = context.utils
    local entries = {}

    if self.GetObedience ~= nil then
        local obedience = self:GetObedience()
        if obedience ~= 0 then
            table.insert(entries, { data_key = "obedience", params = { utils.round2(obedience * 100, 0) } })
        end
    end

    if self.GetDomestication ~= nil then
        local domest = self:GetDomestication()
        if domest ~= 0 then
            table.insert(entries, { data_key = "domest", params = { utils.round2(domest * 100, 0) } })
        end
    end

    if #entries == 0 then
        return nil
    end
    return entries
end

return {
    Describe = Describe
}
