local floor = math.floor
local class = IMP_LibSurfaceTools__class

-- ----------------------------------------------------------------------------

local SurfaceManager = class()
local Surface = class()

function SurfaceManager:__init(composite)
    self.composite = composite
    composite:ClearAllSurfaces()
    composite:SetPixelRoundingEnabled(false)

    self.surfaces = {}
end

function SurfaceManager:AddSurface(atlasIndex)
    -- self.control:AddSurface(self:GetTextureInsets(atlasIndex))
    local surface, idx = Surface:Create(self, self:GetTextureInsets(atlasIndex))
    self.surfaces[idx] = surface
end

local function _atlasIndexToAtlasXY(atlasIndex, atlasSizeX, atlasSizeY)
    atlasIndex = atlasIndex - 1
    return atlasIndex % atlasSizeX + 1, floor(atlasIndex / atlasSizeY) + 1
end

function SurfaceManager:GetTextureInsets(atlasIndex)
    if atlasIndex == nil then
        return 0, 1, 0, 1
    else
        -- TODO: can store as precomputed values
        local atlasStepX, atlasStepY = 1 / self.atlasSizeX, 1 / self.atlasSizeY

        local atlasX, atlasY = _atlasIndexToAtlasXY(atlasIndex, self.atlasSizeX, self.atlasSizeY)

        local tiR = atlasX * atlasStepX
        local tiL = tiR - atlasStepX
        local tiB = atlasY * atlasStepY
        local tiT = tiB - atlasStepY

        return tiL, tiR, tiT, tiB
    end
end


function Surface:__init(manager, ...)
    self.manager = manager
    self.composite = manager.composite
    return self, manager.composite:AddSurface(...)
end

function Surface:Delete()
    self.composite:RemoveSurface(self:GetIndex())
end

function Surface:GetIndex()
    return self.manager:GetSurfcaeIndex(self)
end

function Surface:SetInsets()
    self.composite:SetInsets()
    -- ...
end


-- IMP_LibSurfaceTools__SurfaceManager = SurfaceManager
-- IMP_LibSurfaceTools__Surface = Surface