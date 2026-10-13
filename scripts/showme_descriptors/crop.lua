-- crop 组件：种植的幼苗生长进度（旧农场作物）
local Describe = function(self, context)
    if self.product_prefab and type(self.growthpercent) == "number" and self.growthpercent < 1 then
        return {
            data_key = "crop",
            params = { self.product_prefab, context.utils.round2(self.growthpercent * 100, 0) },
        }
    end
    return nil
end

return {
    Describe = Describe,
}
