Breadcrumbs = Breadcrumbs or {}

function Breadcrumbs.CreateLinePrimitive(x1, y1, z1, x2, y2, z2, colour --[[ Nilable --]] )
    if x1 == nil or y1 == nil or z1 == nil or x2 == nil or y2 == nil or z2 == nil or colour == "" then return end
    return {
        x1 = x1,
        y1 = y1,
        z1 = z1,
        x2 = x2,
        y2 = y2,
        z2 = z2,
        colour = colour or Breadcrumbs.savedVariables.colour or {1, 1, 1}
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

function Breadcrumbs.AddLineToPool( x1, y1, z1, x2, y2, z2, colour --[[ Nilable --]] )
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
    line.colour = colour or Breadcrumbs.savedVariables.colour or {1, 1, 1}
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

-- Lines don't simply vanish from the screen when we remove savedVariables data
-- So we set old lines to be replaced using this function.
-- This ensures their registered control names aren't trying to be overwritten uselessly
-- Avoids "Failure to create control BreadcrumbsLine0. Duplicate name." error
function Breadcrumbs.NilLinePool()
    local linePool = Breadcrumbs.GetLinePool()
    for _, line in pairs( linePool ) do
        line.use = false
    end
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

function Breadcrumbs.CreateSavedZoneLine(x1, y1, z1, x2, y2, z2, colour --[[ Nilable --]] )
    Breadcrumbs.InitialiseZone()
    local zoneId = Breadcrumbs.GetZoneId()
    local line = Breadcrumbs.CreateLinePrimitive(x1, y1, z1, x2, y2, z2, colour)
    if line then 
        table.insert(Breadcrumbs.savedVariables.savedLines[zoneId], line)
    end    
    Breadcrumbs.RefreshLines()
    return zoneId
end

function Breadcrumbs.Generate3DAxisLines() -- /script Breadcrumbs.Generate3DAxisLines() 
    Breadcrumbs.InitialiseZone()
    local zoneId, x, y, z = GetUnitRawWorldPosition("player")
    table.insert(Breadcrumbs.savedVariables.savedLines[zoneId], Breadcrumbs.CreateLinePrimitive(x, y, z, x + 1000, y, z, {1,0,0}))
    table.insert(Breadcrumbs.savedVariables.savedLines[zoneId], Breadcrumbs.CreateLinePrimitive(x, y, z, x, y + 1000, z, {0,1,0}))
    table.insert(Breadcrumbs.savedVariables.savedLines[zoneId], Breadcrumbs.CreateLinePrimitive(x, y, z, x, y, z + 1000, {0,0,1}))
    Breadcrumbs.RefreshLines()
    return zoneId
end

function Breadcrumbs.Loc1() -- /script Breadcrumbs.Loc1()
    local _, x, y, z = GetUnitRawWorldPosition("player")
    Breadcrumbs.savedVariables.loc1 = {
        x = x,
        y = y,
        z = z
    }
end

function Breadcrumbs.Loc2() -- /script Breadcrumbs.Loc2()
    local _, x, y, z = GetUnitRawWorldPosition("player")
    Breadcrumbs.savedVariables.loc2 = {
        x = x,
        y = y,
        z = z
    }
end

function Breadcrumbs.CreateLineFromLocs(colour) -- /script Breadcrumbs.CreateLineFromLocs({1,0,1})
    Breadcrumbs.InitialiseZone()
    local zoneId = Breadcrumbs.GetZoneId()
    local loc1 = Breadcrumbs.savedVariables.loc1
    local loc2 = Breadcrumbs.savedVariables.loc2
    if not loc1 or not loc2 then return end
    if loc1 == loc2 then return end
    local line = Breadcrumbs.CreateLinePrimitive(loc1.x, loc1.y, loc1.z, loc2.x, loc2.y, loc2.z, colour)
    if line then
        table.insert(Breadcrumbs.savedVariables.savedLines[zoneId], line)
    end
    Breadcrumbs.RefreshLines()
    return zoneId
end

function Breadcrumbs.CreateCircle(r, N, colour) -- /script Breadcrumbs.CreateCircle(10, 16, {1, 0.5, 0})
    if N < 3 then return end  -- A circle needs at least 3 points (triangle) to form a polygon
    Breadcrumbs.InitialiseZone()
    local zoneId, playerX, playerY, playerZ = GetUnitRawWorldPosition("player")
    local radius = r * 100 -- Convert from metres to in-game units

    local points = {}
    -- Generate N points along the circle's circumference
    for i = 1, N do
        local angle = (2 * math.pi / N) * i
        local x = playerX + radius * math.cos(angle)
        local y = playerY
        local z = playerZ + radius * math.sin(angle)

        table.insert(points, {x = x, y = y, z = z})
    end

    -- Create lines between consecutive points (close the circle by connecting the last point to the first)
    for i = 1, N do
        local startPoint = points[i]
        local endPoint = points[i % N + 1]  -- Modulo N to wrap around to the first point
        local line = Breadcrumbs.CreateLinePrimitive(startPoint.x, startPoint.y, startPoint.z, endPoint.x, endPoint.y, endPoint.z, colour)
        if line then
            table.insert(Breadcrumbs.savedVariables.savedLines[zoneId], line)
        end
    end

    Breadcrumbs.RefreshLines()
    return zoneId
end


local function squaredDistance(x1, y1, z1, x2, y2, z2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dz = z2 - z1
    return dx * dx + dy * dy + dz * dz
end

function Breadcrumbs.RemoveClosestLine() -- /script Breadcrumbs.RemoveClosestLine()
    Breadcrumbs.InitialiseZone()
    local zoneId, x, y, z = GetUnitRawWorldPosition("player")
    local lines = Breadcrumbs.GetSavedZoneLines(zoneId)

    local closest_line_index = nil
    local min_distance = math.huge

    for index, line in pairs(lines) do
        local dist1 = squaredDistance(x, y, z, line.x1, line.y1, line.z1)
        local dist2 = squaredDistance(x, y, z, line.x2, line.y2, line.z2)
        
        local closest_dist = math.min(dist1, dist2)
        if closest_dist < min_distance then
            min_distance = closest_dist
            closest_line_index = index
        end
    end

    if closest_line_index then
        local closest_line = lines[closest_line_index]
        Breadcrumbs.DiscardLine(closest_line)
        table.remove(Breadcrumbs.savedVariables.savedLines[zoneId], closest_line_index)
    end
    Breadcrumbs.RefreshLines()
end

function Breadcrumbs.GenerateSavedLines() -- /script Breadcrumbs.GenerateSavedLines()
    local zoneId = Breadcrumbs.GetZoneId()
    local lines = Breadcrumbs.GetSavedZoneLines(zoneId)
    for _, line in pairs( lines ) do
        Breadcrumbs.AddLineToPool(line.x1, line.y1, line.z1, line.x2, line.y2, line.z2, line.colour)
    end
end

function Breadcrumbs.RefreshLines()
    Breadcrumbs.StopPolling()
    Breadcrumbs.NilLinePool()
    Breadcrumbs.GenerateSavedLines()
    Breadcrumbs.StartPolling()
end