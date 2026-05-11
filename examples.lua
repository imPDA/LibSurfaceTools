-- Examples

local RANDOM_STRING = 'sgjkjngf325gjnkf'

local function example1()
    local map = LibSurfaceTools.Tools.FlexRect(ZO_WorldMapContainer)
        :SetAnchor(TOPLEFT)
        :SetAnchor(BOTTOMRIGHT)
        :SetTexture('/esoui/art/tutorial/poi_wayshrine_complete.dds', 2, 2)

    GLOBAL_MAP = map

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

    return inner
end

EVENT_MANAGER:RegisterForEvent(RANDOM_STRING, EVENT_ADD_ONS_LOADED, function()
    EVENT_MANAGER:UnregisterForEvent(RANDOM_STRING, EVENT_ADD_ONS_LOADED)

    LibSurfaceToolsExamples = {
        e1 = example1(),
    }
end)