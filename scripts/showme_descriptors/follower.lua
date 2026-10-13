-- follower 组件：主人与忠诚度
local Describe = function(self, context)
    local entries = {}

    if self.leader and self.leader:IsValid() and self.leader:HasTag("player")
        and self.leader.name and self.leader.name ~= ""
    then
        table.insert(entries, { data_key = "owner", params = { self.leader.name } })
    end

    if self.maxfollowtime then
        local mx = self.maxfollowtime
        local cur = math.floor(self:GetLoyaltyPercent() * mx + 0.5)
        if cur > 0 then
            table.insert(entries, { data_key = "loyal", params = { cur, mx } })
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
