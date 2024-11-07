Breadcrumbs = Breadcrumbs or {}

function Breadcrumbs.CreateLinePrimitive(x1, y1, z1, x2, y2, z2, colour)
    return {
        x1 = x1,
        y1 = y1,
        z1 = z1,
        x2 = x2,
        y2 = y2,
        z2 = z2,
        colour = colour or {1, 1, 1, 1}
    }
end

function Breadcrumbs.GetZoneId()
    return select(1, GetUnitRawWorldPosition("player")) 
end

function Breadcrumbs.CreateLineControl( name )
    local line = {}
    line.lineControl = WINDOW_MANAGER:CreateControl(name, Breadcrumbs.win, CT_CONTROL)
    line.backdrop = WINDOW_MANAGER:CreateControl("$(parent)Backdrop", line.lineControl, CT_BACKDROP)
    return {
        ["lineControl"] = line.lineControl,
        ["backdrop"] = line.backdrop,
    }
end

function Breadcrumbs.AddLineToPool( x1, y1, z1, x2, y2, z2, colour )
    local line
    local linePool = Breadcrumbs.GetLinePool()
    -- try to find an unused line
    for _, i in pairs( linePool ) do
        if not i.use then
            line = i
            break
        end
    end
    -- create a new line if no unused line is available
    if not line then
        line = Breadcrumbs.CreateLineControl( "BreadcrumbsLine" .. #linePool )
        linePool[#linePool + 1] = line
    end
    -- store line data
    line.use = true
    line.x1, line.y1, line.z1 = x1, y1, z1
    line.x2, line.y2, line.z2 = x2, y2, z2
    line.colour = colour or {1, 1, 1, 1}
    return line
end

function Breadcrumbs.DiscardLine(line)
    line.use = false
end

function Breadcrumbs.GetLinePool()
    return Breadcrumbs.savedVariables.linePool or {}
end

function Breadcrumbs.ClearLinePool()
    Breadcrumbs.savedVariables.linePool = {}
end

function Breadcrumbs.GetSavedZoneLines(zoneId)
    return Breadcrumbs.savedVariables.savedLines[zoneId] or {}
end

function Breadcrumbs.ClearSavedZoneLines(zoneId)
    Breadcrumbs.savedVariables.savedLines[zoneId] = {}
end

function Breadcrumbs.InitialiseZone()
    local zoneId = Breadcrumbs.GetZoneId()
    Breadcrumbs.savedVariables.savedLines[zoneId] = Breadcrumbs.GetSavedZoneLines(zoneId)
end

function Breadcrumbs.CreateSavedZoneLine(x1, y1, z1, x2, y2, z2, colour)
    local zoneId = Breadcrumbs.GetZoneId()
    local line = Breadcrumbs.CreateLinePrimitive(x1, y1, z1, x2, y2, z2, colour)

    Breadcrumbs.savedVariables.savedLines[zoneId] = Breadcrumbs.GetSavedZoneLines(zoneId)
    table.insert(Breadcrumbs.savedVariables.savedLines[zoneId], line)
    return zoneId
end

function Breadcrumbs.GenerateSavedLines()
    Breadcrumbs.ClearLinePool()
    local zoneId, _, _, _ = GetUnitRawWorldPosition("player")
    local lines = Breadcrumbs.GetSavedZoneLines(zoneId)
    for _, line in pairs( lines ) do
        Breadcrumbs.AddLineToPool(line.x1, line.y1, line.z1, line.x2, line.y2, line.z2, line.colour)
    end
end