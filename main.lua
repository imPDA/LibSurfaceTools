local floor = math.floor

local addon = {
    name = 'LibSurfaceTools'
}

local EVENT_NAMESPACE = addon.name


local function class()
	local cls = {}
	cls.__index = cls

	setmetatable(cls, {
        __call = function(self, ...)
            local obj = setmetatable({}, cls)
            if self.__init then self.__init(obj, ...) end
            return obj
        end
	})

	return cls
end

local function _atlasIndexToAtlasXY(atlasIndex, atlasSizeX, atlasSizeY)
    atlasIndex = atlasIndex - 1
    return atlasIndex % atlasSizeX + 1, floor(atlasIndex / atlasSizeY) + 1
end

local function _atlasXYToAtlasIndex(atlasX, atlasY, atlasSizeX, atlasSizeY)
    return atlasSizeX * (atlasY - 1) + atlasX
end

local function _getTextureInsets(atlasX, atlasY, atlasSizeX, atlasSizeY)
    if atlasY == nil then
        atlasX, atlasY = _atlasIndexToAtlasXY(atlasX, atlasSizeX, atlasSizeY)
    end

    local atlasStepX, atlasStepY = 1 / atlasSizeX, 1 / atlasSizeY
    local tiL, tiR = (atlasX - 1) * atlasStepX, atlasX * atlasStepX
    local tiT, tiB = (atlasY - 1) * atlasStepY, atlasY * atlasStepY

    return tiL, tiR, tiT, tiB
end

-- ----------------------------------------------------------------------------
--[[
local RigidGrid = class()

function RigidGrid:__init(sizeX, sizeY, cellW, cellH)
    self.sizeX = sizeX
    self.sizeY = sizeY
    self.cellW = cellW
    self.cellH = cellH

    local control = CreateControl('$(parent)Grid'..addon.control:GetNumChildren(), addon.control, CT_TEXTURECOMPOSITE)
    assert(control, 'TextureComposite was not created!')

    control:SetDimensions(sizeX * cellW, sizeY * cellH)
    control:ClearAllSurfaces()

    self.control = control

    return self
end

function RigidGrid:SetAnchor(...)
    self.control:ClearAnchors()  -- only 1 anchor!
    self.control:SetAnchor(...)
    return self
end

function RigidGrid:SetTexture(fileName, atlasSizeX, atlasSizeY)
    atlasSizeX = atlasSizeX or 1
    atlasSizeY = atlasSizeY or 1

    self.control:SetTexture(fileName)

    if atlasSizeX > 1 or atlasSizeY > 1 then
        self.atlas = true
        self.atlasSizeX = atlasSizeX
        self.atlasSizeY = atlasSizeY
    end

    return self
end

function RigidGrid:Add(gridX, gridY, offsetX, offsetY, w, h, atlasX, atlasY)
    offsetX = offsetX or 0
    offsetY = offsetY or 0

    local tiL, tiR, tiT, tiB
    if self.atlas then
        tiL, tiR, tiT, tiB = _getTextureInsets(atlasX, atlasY, self.atlasSizeX, self.atlasSizeY)
    end

    gridX = gridX - 1
    gridY = gridY - 1

    local centerX = self.cellW * (gridX + 0.5) + offsetX
    local centerY = self.cellH * (gridY + 0.5) + offsetY

    local half_w, half_h = w/2, h/2
    local iL, iR = centerX - half_w, centerX + half_w
    local iT, iB = centerY - half_h, centerY + half_h

    local surfaceNumber = self.control:AddSurface(tiL, tiR, tiT, tiB)
    self.control:SetInsets(surfaceNumber, iL, iR, iT, iB)
end
--]]
-- ----------------------------------------------------------------------------

local FlexRect = class()

function FlexRect:__init(parent, name)
    parent = parent or addon.control
    name = name or ('$(parent)FlexRect'..parent:GetNumChildren())

    local control = CreateControl(name, parent, CT_TEXTURECOMPOSITE)
    assert(control, 'TextureComposite was not created!')

    control:ClearAllSurfaces()
    control:SetPixelRoundingEnabled(false)
    control:SetHandler('OnUpdate', function() self:_updatePositions() end)

    self.control = control

    self.surfaces = {}

    return self
end

function FlexRect:SetAnchor(...)
    self.control:SetAnchor(...)

    return self
end

function FlexRect:SetTexture(fileName, atlasSizeX, atlasSizeY)
    atlasSizeX = atlasSizeX or 1
    atlasSizeY = atlasSizeY or 1

    self.control:SetTexture(fileName)

    if atlasSizeX > 1 or atlasSizeY > 1 then
        self.atlas = true
        self.atlasSizeX = atlasSizeX
        self.atlasSizeY = atlasSizeY
    end

    return self
end

function FlexRect:Add(nX, nY, offsetX, offsetY, w, h, atlasX, atlasY)
    offsetX = offsetX or 0
    offsetY = offsetY or 0

    if atlasY == nil then
        atlasX, atlasY = _atlasIndexToAtlasXY(atlasX, self.atlasSizeX, self.atlasSizeY)
    end

    local tiL, tiR, tiT, tiB = 0, 1, 0, 1
    if self.atlas then
        tiL, tiR, tiT, tiB = _getTextureInsets(atlasX, atlasY, self.atlasSizeX, self.atlasSizeY)
    end

    local W, H = self.control:GetWidth(), self.control:GetHeight()

    local centerX = W * nX + offsetX
    local centerY = H * nY + offsetY

    local half_w, half_h = w/2, h/2
    local iL, iR = centerX - half_w, -W + centerX + half_w
    local iT, iB = centerY - half_h, -H + centerY + half_h

    local surfaceNumber = self.control:AddSurface(tiL, tiR, tiT, tiB)
    self.control:SetInsets(surfaceNumber, iL, iR, iT, iB)

    -- not very safe, but it should work OK until someone used it inproperly
    self.surfaces[surfaceNumber] = {nX, nY, offsetX, offsetY, w, h, atlasX, atlasY}
end

function FlexRect:_updatePositions()
    local W, H = self.control:GetWidth(), self.control:GetHeight()
    if self.W == W and self.H == H then return end

    for surfaceIndex = 1, #self.surfaces do
        local s = self.surfaces[surfaceIndex]
        local nX, nY, offsetX, offsetY, w, h = s[1], s[2], s[3], s[4], s[5], s[6]

        local centerX = W * nX + offsetX
        local centerY = H * nY + offsetY

        local half_w, half_h = w/2, h/2
        local iL, iR = centerX - half_w, -W + centerX + half_w
        local iT, iB = centerY - half_h, -H + centerY + half_h

        self.control:SetInsets(surfaceIndex, iL, iR, iT, iB)
    end
end

function FlexRect:RemoveSurface(index)
    table.remove(self.surfaces, index)
    self.control:RemoveSurface(index)
end

function FlexRect:RemoveSurfacesOfKind(atlasX, atlasY)
    -- TODO: kinda slow, make hash table

    if atlasY == nil then
        atlasX, atlasY = _atlasIndexToAtlasXY(atlasX, self.atlasSizeX, self.atlasSizeY)
    end

    local surfaces = self.surfaces
    for index = #surfaces, 1, -1 do
        local surface = surfaces[index]
        if surface[7] == atlasX and surface[8] == atlasY then
            self:RemoveSurface(index)
        end
    end
end

function FlexRect:Clear()
    self.control:ClearAllSurfaces()
    -- self.control:ClearAnchors()

    ZO_ClearNumericallyIndexedTable(self.surfaces)
end

addon.Tools = {
    FlexRect = FlexRect,
    -- RigidGrid = RigidGrid,
}

-- ----------------------------------------------------------------------------

function addon:Initialize()
    self.control = LibSurfaceTools_TLC

    LibSurfaceTools = self
end

-- ----------------------------------------------------------------------------

local function OnAddonLoaded(_, addonName)
    if addonName ~= addon.name then return end
    EVENT_MANAGER:UnregisterForEvent(EVENT_NAMESPACE, EVENT_ADD_ON_LOADED)

    addon:Initialize()
end


EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_ADD_ON_LOADED, OnAddonLoaded)
