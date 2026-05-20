local floor = math.floor
local class = IMP_LibSurfaceTools__class

-- ----------------------------------------------------------------------------


local function __surfaceProxy(compositeManager, stableId)
    local compositeControl = compositeManager.composite
    local proxy = {}

    local mt = {
        __index = function(_, methodName)
            local method = compositeControl[methodName]
            if method then
                return function(_, ...)
                    local surfaceIndex = compositeManager:GetSurfaceIndex(stableId)
                    method(compositeControl, surfaceIndex, ...)

                    return proxy
                end
            end
            return nil
        end
    }

    function proxy:RemoveSurface()
        -- local surfaceIndex = compositeManager:GetSurfaceIndex(stableIdentifier)
        -- compositeControl.RemoveSurface(compositeControl, surfaceIndex, ...)
        -- compositeManager:MarkDead(stableIdentifier)

        compositeManager:RemoveSurface(stableId)
    end

    setmetatable(proxy, mt)
    return proxy
end

local _surfaceId = 0
local function _generateSurfaceId()
    _surfaceId = _surfaceId + 1
    return _surfaceId
end

local SurfaceManager = class()

function SurfaceManager:__init(composite)
    self.composite = composite
    -- composite:ClearAllSurfaces()
    -- composite:SetPixelRoundingEnabled(false)

    self.surfaces = {}
    self.hash = {}
end

function SurfaceManager:GetSurfaceIndex(stableId)
    return self.hash[stableId]
end

function SurfaceManager:AddSurface(l, r, t, b)
    local surfaceIndex = self.composite:AddSurface(l, r, t, b)
    local stableId = _generateSurfaceId()

    self.surfaces[surfaceIndex] = stableId
    self.hash[stableId] = surfaceIndex

    return __surfaceProxy(self, stableId)
end

function SurfaceManager:RemoveSurface(stableId)
    local surfaces = self.surfaces

    local surfaceIndex = self.hash[stableId]
    self.hash[stableId] = nil
    table.remove(surfaces, surfaceIndex)

    for i = surfaceIndex, #surfaces do
        self.hash[surfaces[i]] = i
    end
end

-- local function _atlasIndexToAtlasXY(atlasIndex, atlasSizeX, atlasSizeY)
--     atlasIndex = atlasIndex - 1
--     return atlasIndex % atlasSizeX + 1, floor(atlasIndex / atlasSizeY) + 1
-- end

-- function SurfaceManager:GetTextureInsets(atlasIndex)
--     if atlasIndex == nil then
--         return 0, 1, 0, 1
--     else
--         -- TODO: can store as precomputed values
--         local atlasStepX, atlasStepY = 1 / self.atlasSizeX, 1 / self.atlasSizeY

--         local atlasX, atlasY = _atlasIndexToAtlasXY(atlasIndex, self.atlasSizeX, self.atlasSizeY)

--         local tiR = atlasX * atlasStepX
--         local tiL = tiR - atlasStepX
--         local tiB = atlasY * atlasStepY
--         local tiT = tiB - atlasStepY

--         return tiL, tiR, tiT, tiB
--     end
-- end


IMP_LibSurfaceTools__SurfaceManager = SurfaceManager


-- RemoveSurface(*luaindex* _surfaceIndex_)
-- SetInsets(*luaindex* _surfaceIndex_, *number* _left_, *number* _right_, *number* _top_, *number* _bottom_)
-- SetColor(*luaindex* _surfaceIndex_, *number* _r_, *number* _g_, *number* _b_, *number* _a_)
-- SetSurfaceAlpha(*luaindex* _surfaceIndex_, *number* _a_)
-- SetSurfaceHidden(*luaindex* _surfaceIndex_, *bool* _hidden_)
-- SetSurfaceScale(*luaindex* _surfaceIndex_, *number* _scale_)
-- SetSurfaceTextureRotation(*luaindex* _surfaceIndex_, *number* _angleInRadians_, *number* _normalizedRotationPointX_, *number* _normalizedRotationPointY_)
-- SetTextureCoords(*luaindex* _surfaceIndex_, *number* _left_, *number* _right_, *number* _top_, *number* _bottom_)
-- GetColor(*luaindex* _surfaceIndex_)
-- GetInsets(*luaindex* _surfaceIndex_)
-- GetSurfaceAlpha(*luaindex* _surfaceIndex_)
-- GetTextureCoords(*luaindex* _surfaceIndex_)
-- IsSurfaceHidden(*luaindex* _surfaceIndex_)

-- AddSurface(*number* _left_, *number* _right_, *number* _top_, *number* _bottom_)
-- SetTexture(*string* _filename_)
-- GetNumSurfaces()
-- ClearAllSurfaces()
-- GetBlendMode()
-- GetDesaturation()
-- GetTextureFileDimensions()
-- GetTextureFileName()
-- IsPixelRoundingEnabled()
-- IsTextureLoaded()
-- SetBlendMode(*[TextureBlendMode|#TextureBlendMode]* _blendMode_)
-- SetDesaturation(*number* _desaturation_)
-- SetPixelRoundingEnabled(*bool* _pixelRoundingEnabled_)
-- SetTextureReleaseOption(*[ReleaseReferenceOptions|#ReleaseReferenceOptions]* _releaseOption_)
