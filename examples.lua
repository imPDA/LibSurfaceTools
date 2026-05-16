-- Examples

local RANDOM_STRING = 'sgjkjngf325gjnkf'

--[[
ZO_PostHook(_G, 'ZO_WorldMap_MouseDown', function() d('ZO_WorldMap_MouseDown') end)
ZO_PostHook(_G, 'ZO_WorldMap_MouseUp', function() d('ZO_WorldMap_MouseUp') end)
ZO_PostHook(_G, 'ZO_WorldMap_MouseWheel', function() d('ZO_WorldMap_MouseWheel') end)
ZO_PostHook(_G, 'ZO_WorldMap_MouseEnter', function() d('ZO_WorldMap_MouseEnter') end)
ZO_PostHook(_G, 'ZO_WorldMap_MouseExit', function() d('ZO_WorldMap_MouseExit') end)
--]]

local function example1()
    local function OnMouseEnter(surface)
        surface[5], surface[6] = 64, 64
    end

    local function OnMouseExit(surface)
        surface[5], surface[6] = 32, 32
    end

    local map = LibSurfaceTools.Tools.FlexRect(ZO_WorldMapContainer, nil, OnMouseEnter, OnMouseExit)
        :SetAnchor(TOPLEFT)
        :SetAnchor(BOTTOMRIGHT)
        -- :SetTexture('/esoui/art/tutorial/poi_wayshrine_complete.dds', 2, 2)
        :SetTexture('/esoui/art/tutorial/poi_wayshrine_complete.dds')

    local control = map.control

    ZO_PostHook(_G, 'ZO_WorldMap_MouseEnter', function(_, ...) control:GetHandler('OnMouseEnter')(control) end)
    ZO_PostHook(_G, 'ZO_WorldMap_MouseExit', function(_, ...) control:GetHandler('OnMouseExit')(control) end)

    -- GLOBAL_MAP = map

    --[[
    local function inner()
        if #map.surfaces > 1 then return map:Clear() end

        local N = 100

        for i = 1, N do
            local j = 2 * math.pi * (i / N)
            local x = math.cos(j) * 0.2
            local y = math.sin(j) * 0.2

            map:Add(0.5 + x, 0.5 - y, 0, 0, 16, 16, math.ceil(4 * i / N))
        end

        map:RemoveSurfacesOfKind(3)
    end
    --]]

    local function inner()
        if #map.surfaces > 1 then return map:Clear() end

        local N = 16

        for i = 1, N do
            local j = 2 * math.pi * (i / N)
            local x = math.cos(j) * 0.2
            local y = math.sin(j) * 0.2

            map:Add(0.5 + x, 0.5 - y, 0, 0, 32, 32)
        end

        -- map:RemoveSurfacesOfKind(3)
    end

    return inner
end


local function example2()
    local function OnMouseEnter(surface)
        surface[5], surface[6] = 36, 36
    end

    local function OnMouseExit(surface)
        surface[5], surface[6] = 24, 24
    end

    local map = LibSurfaceTools.Tools.FlexRect(ZO_WorldMapContainer, nil, OnMouseEnter, OnMouseExit)
        :SetAnchor(TOPLEFT)
        :SetAnchor(BOTTOMRIGHT)
        :SetTexture('EsoUI/Art/Miscellaneous/Gamepad/gp_bullet.dds')

    local control = map.control

    ZO_PostHook(_G, 'ZO_WorldMap_MouseEnter', function(_, ...) control:GetHandler('OnMouseEnter')(control) end)
    ZO_PostHook(_G, 'ZO_WorldMap_MouseExit', function(_, ...) control:GetHandler('OnMouseExit')(control) end)

    local function inner()
        if #map.surfaces > 1 then GLOBAL_MAP = nil return map:Clear() end

        local cyroCache
        for _, cache in pairs(Harvest.Data.mapCaches) do
            if cache.map == 'cyrodiil/ava_whole' then
                cyroCache = cache
                break
            end
        end

        local zoneId = GetZoneId(GetUnitZoneIndex('player'))

        for i = 1, #cyroCache.worldX do
            if cyroCache.worldX[i] and cyroCache.worldY[i] then
                local x, y = cyroCache.worldX[i] * 100, cyroCache.worldY[i] * 100
                local n_x, n_y = GetNormalizedWorldPosition(zoneId, x, 40000, y)

                map:Add(n_x, n_y, 0, 0, 24, 24)
            end
        end

        GLOBAL_MAP = map
    end

    return inner
end


EVENT_MANAGER:RegisterForEvent(RANDOM_STRING, EVENT_ADD_ONS_LOADED, function()
    EVENT_MANAGER:UnregisterForEvent(RANDOM_STRING, EVENT_ADD_ONS_LOADED)

    LibSurfaceToolsExamples = {
        e1 = example1(),
        e2 = example2(),
    }
end)