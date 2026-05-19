local floor = math.floor
local class = IMP_LibSurfaceTools__class
local Quadtree = IMP_LibSurfaceTools__Quadtree

-- ----------------------------------------------------------------------------

local addon = {
    name = 'LibSurfaceTools'
}

local EVENT_NAMESPACE = addon.name


local function _atlasIndexToAtlasXY(atlasIndex, atlasSizeX, atlasSizeY)
    atlasIndex = atlasIndex - 1
    return atlasIndex % atlasSizeX + 1, floor(atlasIndex / atlasSizeY) + 1
end

-- local function _atlasXYToAtlasIndex(atlasX, atlasY, atlasSizeX, atlasSizeY)
--     return atlasSizeX * (atlasY - 1) + atlasX
-- end

-- local function _getTextureInsets(atlasX, atlasY, atlasSizeX, atlasSizeY)
--     if atlasY == nil then
--         atlasX, atlasY = _atlasIndexToAtlasXY(atlasX, atlasSizeX, atlasSizeY)
--     end

--     local atlasStepX, atlasStepY = 1 / atlasSizeX, 1 / atlasSizeY
--     local tiL, tiR = (atlasX - 1) * atlasStepX, atlasX * atlasStepX
--     local tiT, tiB = (atlasY - 1) * atlasStepY, atlasY * atlasStepY

--     return tiL, tiR, tiT, tiB
-- end

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

function FlexRect:__init(parent, name, onMouseEnter, onMouseExit)
    -- parent = parent or addon.control
    name = name or ('$(parent)FlexRect'..parent:GetNumChildren())

    local control = CreateControl(name, parent, CT_TEXTURECOMPOSITE)
    assert(control, 'TextureComposite was not created!')

    control:ClearAllSurfaces()
    control:SetPixelRoundingEnabled(false)
    control:SetHandler('OnUpdate', function() self:_onParentUpdate() end)
    control:SetAnchor(TOPLEFT, parent)

    self.control = control
    self.parent = parent

    self.surfaces = {}

    if onMouseEnter then
        -- df('Mouse over enabled')
        self._onMouseEnter = onMouseEnter
        self._onMouseExit = onMouseExit
        self.mouseOver = {}

        self.hash = {}  -- setmetatable({}, {__mode='k'})

        control:SetMouseEnabled(true)

        control:SetHandler('OnMouseEnter', function()
            -- df('Mouse over %s', name)
            EVENT_MANAGER:RegisterForUpdate(EVENT_NAMESPACE..name, 0, function()
                self:_onUpdate()
            end)
        end)

        control:SetHandler('OnMouseExit', function()
            -- df('Mouse exit %s', name)
            EVENT_MANAGER:UnregisterForUpdate(EVENT_NAMESPACE..name)
        end)

        -- if surface hidden, need to update all previously mouse over pins, TODO: make it effectively
        control:SetHandler('OnEffectivelyHidden', function()
            for surface in pairs(self.mouseOver) do
                self._onMouseExit(surface)
                -- self:_updateSurface(self.hash[surface])
            end
        end)

        self.quadtree = Quadtree()
    end

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

function FlexRect:SetColor(surfaceIndex, r, g, b, a)
    self.control:SetColor(surfaceIndex, r, g, b, a)
    return self
end

function FlexRect:SetAlpha(surfaceIndex, alpha)
    self.control:SetSurfaceAlpha(surfaceIndex, alpha)
    return self
end

function FlexRect:Add(n_x, n_y, offsetX, offsetY, w, h, atlasIndex, tag)
    local surfaceIndex = self.control:AddSurface(self:GetTextureInsets(atlasIndex))
    self:_place(surfaceIndex, n_x, n_y, offsetX, offsetY, w, h)

    -- not very safe, but it should work OK until someone used it inproperly
    local surfaceData = {n_x, n_y, offsetX, offsetY, w, h, atlasIndex, tag = tag}
    self.surfaces[surfaceIndex] = surfaceData

    if self.quadtree then
        self.quadtree:Insert(n_x, n_y, surfaceData)
        self.hash[surfaceData] = surfaceIndex
    end

    -- yoooooooooooooooooooooo this is sick, don't do anything like that anymore
    -- but it might theoretically work out
    -- TODO: need to think about how to definetely determine surface and
    -- rebuild this nasty stuff
    -- TODO: wrapper `SurfaceManager`, wrapper `Surface`
    local nastyWrapper = setmetatable({}, {
        __index = function(t, k)
            local original = self.control[k]
            if type(original) == 'function' then
                return function(self_, ...)
                    original(self.control, self.hash[surfaceData], ...)
                    return t
                end
            else
                return original
            end
        end
    })

    return nastyWrapper
end

function FlexRect:GetTextureInsets(atlasIndex)
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

function FlexRect:_place(surfaceIndex, n_x, n_y, offsetX, offsetY, w, h)
    offsetX = offsetX or 0
    offsetY = offsetY or 0

    local parent = self.parent
    local W, H = parent:GetWidth(), parent:GetHeight()

    local centerX = W * n_x + offsetX
    local centerY = H * n_y + offsetY

    local half_w, half_h = w/2, h/2
    local iL, iR = centerX - half_w, centerX + half_w
    local iT, iB = centerY - half_h, centerY + half_h

    self.control:SetInsets(surfaceIndex, iL, iR, iT, iB)
end

function FlexRect:_onParentUpdate()
    local parent = self.parent
    local surfaces = self.surfaces

    local W, H = parent:GetWidth(), parent:GetHeight()
    if self.W == W and self.H == H then return end
    self.W, self.H = W, H

    for surfaceIndex = 1, #surfaces do
        local s = surfaces[surfaceIndex]

        -- TODO: (..., unpack(s)) vs (..., s[1], s[2], ...)
        self:_place(surfaceIndex, s[1], s[2], s[3], s[4], s[5], s[6])
    end
end

function FlexRect:_updateSurface(surfaceIndex)
    local s = self.surfaces[surfaceIndex]
    self:_place(surfaceIndex, s[1], s[2], s[3], s[4], s[5], s[6])
end

function FlexRect:RemoveSurface(index)
    local surfaces = self.surfaces
    local surfaceData = surfaces[index]

    local surface = table.remove(surfaces, index)
    self.control:RemoveSurface(index)

    if self.quadtree then
        self.quadtree:Remove(surfaceData)

        self.mouseOver[surface] = nil
        self._onMouseExit(surface)

        -- TODO: rehashing is not the best thing to see... Very expensive deletion
        -- especially with clearing hash every time :>
        -- local hash = self.hash
        -- ZO_ClearTable(hash)
        -- for i = 1, #surfaces do
        --     hash[surfaces[i]] = i
        -- end
        -- TODO: check if is everything OK

        self.hash[surface] = nil
    end
end

function FlexRect:RemoveSurfacesOfKind(atlasX, atlasY)
    -- TODO: kinda slow, make hash table

    if not self.atlas then return end

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

    -- TODO: clear self.surfaces and self.hash

    ZO_ClearNumericallyIndexedTable(self.surfaces)

    if self.quadtree then
        self.quadtree:Clear()
    end
end

function FlexRect:_onUpdate()
    local x, y = self.control:GetLeft(), self.control:GetTop()
    local m_x, m_y = GetUIMousePosition()

    -- TODO: width, height optimization
    local parent = self.parent
    local W, H = parent:GetWidth(), parent:GetHeight()
    local mn_x, mn_y = (m_x - x) / W, (m_y - y) / H

    -- TODO: need some arbitrary width and height...
    -- 100 px, normalize for w and h
    local n_size = 64 / W
    local results = self.quadtree:Query(mn_x, mn_y, n_size)

    -- TODO: check if result is different

    -- df('%d', #results)

    local filtered = {}
    local mr_x, mr_y = m_x - x, m_y - y
    for _, result in ipairs(results) do
        -- local surfaceIndex = self.hash[result]
        local surfaceData = result.data
        local r_x, r_y = surfaceData[1] * W + surfaceData[3], surfaceData[2] * H + surfaceData[4]
        local halfSurfaceWidth, halfSurfaceHeight = surfaceData[5] / 2, surfaceData[6] / 2

        if r_x + halfSurfaceWidth > mr_x and
        r_x - halfSurfaceWidth < mr_x and
        r_y - halfSurfaceHeight < mr_y and
        r_y + halfSurfaceHeight > mr_y then
            filtered[#filtered+1] = self.hash[surfaceData]
        end
    end

    -- df('%d', #filtered)

    local previousMouseOver = self.mouseOver
    local mouseOver = {}
    self.mouseOver = mouseOver

    local added = {}

    for i = 1, #filtered do
        local surfaceIndex = filtered[i]
        local surface = self.surfaces[surfaceIndex]

        mouseOver[surface] = true

        if not previousMouseOver[surface] then
            added[surface] = true
        end
    end

    for surface in pairs(previousMouseOver) do
        if not mouseOver[surface] then
            self._onMouseExit(surface)
            self:_updateSurface(self.hash[surface])
        end
    end

    for surface in pairs(added) do
        self._onMouseEnter(surface)
        self:_updateSurface(self.hash[surface])
    end
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

IMP_LibSurfaceTools__Quadtree = nil
IMP_LibSurfaceTools__class = nil
