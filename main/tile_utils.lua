local _nutrientgrid
local _moisturegrid
local _drinkersgrid
local _overlaygrid

local farming_manager
AddComponentPostInit("farming_manager", function(self)
    if not (_G.TheWorld and _G.TheWorld.ismastersim) then return end
    farming_manager = self
    self.inst:ListenForEvent("worldmapsetsize", function(...)
        _nutrientgrid = Upvaluehelper.GetUpvalue(self.OnSave, "_nutrientgrid")
        _moisturegrid = Upvaluehelper.GetUpvalue(self.OnSave, "_moisturegrid")
        _drinkersgrid = Upvaluehelper.GetUpvalue(self.GetDebugString, "_drinkersgrid")
        _overlaygrid = Upvaluehelper.GetUpvalue(self.GetDebugString, "_overlaygrid")
    end)
end)

--- Get tile nutrients at point
local function GetTileNutrientsAtPoint(x, y, z)
    if not farming_manager then return end
    local tx, ty = _G.TheWorld.Map:GetTileCoordsAtPoint(x, y, z)
    local nutrients = {farming_manager:GetTileNutrients(tx, ty)}
    return {
        formula = nutrients[1],
        compost = nutrients[2],
        manure = nutrients[3]
    }
end

local function GetTileDataAtPoint(x, y, z)
    if not _nutrientgrid or not _moisturegrid or not _drinkersgrid or not _overlaygrid then
        if not _nutrientgrid then print("[Show Me] 警告：未找到上值 _nutrientgrid") end
        if not _moisturegrid then print("[Show Me] 警告：未找到上值 _moisturegrid") end
        if not _drinkersgrid then print("[Show Me] 警告：未找到上值 _drinkersgrid") end
        if not _overlaygrid then print("[Show Me] 警告：未找到上值 _overlaygrid") end
        return
    end

    local tx, ty = _G.TheWorld.Map:GetTileCoordsAtPoint(x, y, z)

    return {
        belowsoiltile = _G.TheWorld.components.undertile and _G.TheWorld.components.undertile:GetTileUnderneath(tx, ty) or nil,
        soil_drinkers = _drinkersgrid:GetDataAtPoint(tx, ty),
        nutrients_overlay = _overlaygrid:GetDataAtPoint(tx, ty),
        nutrients = _nutrientgrid:GetDataAtPoint(tx, ty),
        soilmoisture = _moisturegrid:GetDataAtPoint(tx, ty)
    }
end

--- Gets tile moisture at point
local function GetTileMoistureAtPoint(x, y, z)
    local data = GetTileDataAtPoint(x, y, z)
    return data and data.soilmoisture or 0
end

return {
    GetTileNutrientsAtPoint = GetTileNutrientsAtPoint,
    GetTileMoistureAtPoint = GetTileMoistureAtPoint,
}
