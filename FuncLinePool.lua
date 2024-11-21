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
        colour = colour or Breadcrumbs.sV.colour or {1, 1, 1}
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

-- todo, replace this with ZO_ControlPool
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
        line = Breadcrumbs.CreateLineControl( "BreadcrumbsLine" .. (#linePool+1) )
        linePool[#linePool + 1] = line
    end
    -- store line data
    line.use = true
    line.x1, line.y1, line.z1 = x1, y1, z1
    line.x2, line.y2, line.z2 = x2, y2, z2
    line.colour = colour or Breadcrumbs.sV.colour or {1, 1, 1}
    return line
end

function Breadcrumbs.DiscardLine(line)
    line.use = false
end

function Breadcrumbs.GetLinePool()
    return Breadcrumbs.linePool or {}
end

function Breadcrumbs.ClearLinePool()
    Breadcrumbs.linePool = {}
end

-- Lines don't simply vanish from the screen when we remove savedVariables data
-- So we set old lines to be replaced using this function.
-- This ensures their registered control names aren't trying to be overwritten uselessly
-- Avoids "Failure to create control BreadcrumbsLine0. Duplicate name." error
function Breadcrumbs.NilLinePool()
    local linePool = Breadcrumbs.GetLinePool()
    for _, line in pairs( linePool ) do
        Breadcrumbs.DiscardLine(line)
    end
end

function Breadcrumbs.GetSavedZoneLines(zoneId)
    return Breadcrumbs.sV.savedLines[zoneId] or {}
end

function Breadcrumbs.ClearSavedZoneLines(zoneId)
    Breadcrumbs.sV.savedLines[zoneId] = {}
    Breadcrumbs.RefreshLines()
end

function Breadcrumbs.ClearSavedZoneLinesFromThisZone()
    local zoneId = Breadcrumbs.GetZoneId()
    Breadcrumbs.ClearSavedZoneLines(zoneId)
end

function Breadcrumbs.InitialiseZone()
    local zoneId = Breadcrumbs.GetZoneId()
    Breadcrumbs.sV.savedLines[zoneId] = Breadcrumbs.GetSavedZoneLines(zoneId)
end

function Breadcrumbs.InitialiseExternalZone(zoneId)
    Breadcrumbs.sV.savedLines[zoneId] = Breadcrumbs.GetSavedZoneLines(zoneId)
end

function Breadcrumbs.CreateSavedZoneLine(x1, y1, z1, x2, y2, z2, colour --[[ Nilable --]] )
    Breadcrumbs.InitialiseZone()
    local zoneId = Breadcrumbs.GetZoneId()
    local line = Breadcrumbs.CreateLinePrimitive(x1, y1, z1, x2, y2, z2, colour)
    if line then 
        table.insert(Breadcrumbs.sV.savedLines[zoneId], line)
    end    
    Breadcrumbs.RefreshLines()
    return zoneId
end

function Breadcrumbs.Generate3DAxisLines() -- /script Breadcrumbs.Generate3DAxisLines() 
    Breadcrumbs.InitialiseZone()
    local zoneId, x, y, z = GetUnitRawWorldPosition("player")
    table.insert(Breadcrumbs.sV.savedLines[zoneId], Breadcrumbs.CreateLinePrimitive(x, y, z, x + 1000, y, z, {1,0,0}))
    table.insert(Breadcrumbs.sV.savedLines[zoneId], Breadcrumbs.CreateLinePrimitive(x, y, z, x, y + 1000, z, {0,1,0}))
    table.insert(Breadcrumbs.sV.savedLines[zoneId], Breadcrumbs.CreateLinePrimitive(x, y, z, x, y, z + 1000, {0,0,1}))
    Breadcrumbs.RefreshLines()
    return zoneId
end

function Breadcrumbs.Loc1() -- /script Breadcrumbs.Loc1()
    local _, x, y, z = GetUnitRawWorldPosition("player")
    Breadcrumbs.sV.loc1 = {
        x = x,
        y = y,
        z = z
    }
end

function Breadcrumbs.Loc2() -- /script Breadcrumbs.Loc2()
    local _, x, y, z = GetUnitRawWorldPosition("player")
    Breadcrumbs.sV.loc2 = {
        x = x,
        y = y,
        z = z
    }
end

function Breadcrumbs.CreateLineFromLocs(colour) -- /script Breadcrumbs.CreateLineFromLocs({1,0,1})
    Breadcrumbs.InitialiseZone()
    local zoneId = Breadcrumbs.GetZoneId()
    local loc1 = Breadcrumbs.sV.loc1
    local loc2 = Breadcrumbs.sV.loc2
    if not loc1 or not loc2 then return end
    if loc1 == loc2 then return end
    local line = Breadcrumbs.CreateLinePrimitive(loc1.x, loc1.y, loc1.z, loc2.x, loc2.y, loc2.z, colour)
    if line then
        table.insert(Breadcrumbs.sV.savedLines[zoneId], line)
    end
    Breadcrumbs.RefreshLines()
    return zoneId
end

function Breadcrumbs.DrawPolygon(r, n, colour)
    if n < 3 then return end
    Breadcrumbs.InitialiseZone()
    local zoneId, playerX, playerY, playerZ = GetUnitRawWorldPosition("player")
    local radius = r * 100
    local _, _, heading = GetMapPlayerPosition("player")

    local points = {}
    for i = 1, n do
        local angle = heading + math.pi + (2 * math.pi / n) * (i - 1)
        if n % 2 == 0 then
            angle = angle + math.pi / 4
        end
        local x = playerX + radius * math.sin(angle)
        local y = playerY
        local z = playerZ + radius * math.cos(angle)

        table.insert(points, {x = x, y = y, z = z})
    end

    for i = 1, n do
        local sP = points[i]
        local eP = points[i % n + 1]
        local line = Breadcrumbs.CreateLinePrimitive(
            sP.x, sP.y, sP.z,
            eP.x, eP.y, eP.z,
            colour or Breadcrumbs.sV.colour or {1, 1, 1}
        )
        if line then
            table.insert(Breadcrumbs.sV.savedLines[zoneId], line)
        end
    end

    Breadcrumbs.RefreshLines()
    return zoneId
end

function Breadcrumbs.DrawPentagram(r, num)
    if r <= 0.99 then return end
    Breadcrumbs.InitialiseZone()
    local zoneId, playerX, playerY, playerZ = GetUnitRawWorldPosition("player")
    local radius = r * 100
    local _, _, heading = GetMapPlayerPosition("player")
    local n = num or 32

    local circlePoints = {}
    local pentagramPoints = {}

    for i = 1, n do
        local angle = heading + math.pi + (2 * math.pi / n) * (i - 1)
        local x = playerX + radius * math.sin(angle)
        local y = playerY
        local z = playerZ + radius * math.cos(angle)
        table.insert(circlePoints, {x = x, y = y, z = z})
    end

    for i = 1, 5 do
        local angle = heading + math.pi + (2 * math.pi / 5) * (i - 1)
        local x = playerX + radius * math.sin(angle)
        local y = playerY
        local z = playerZ + radius * math.cos(angle)
        table.insert(pentagramPoints, {x = x, y = y, z = z})
    end

    for i = 1, n do
        local sP = circlePoints[i]
        local eP = circlePoints[i % n + 1]
        local line = Breadcrumbs.CreateLinePrimitive(
            sP.x, sP.y, sP.z,
            eP.x, eP.y, eP.z,
            Breadcrumbs.sV.colour or {1, 0, 0}
        )
        if line then
            table.insert(Breadcrumbs.sV.savedLines[zoneId], line)
        end
    end

    local starIndices = {1, 3, 5, 2, 4, 1}
    for i = 1, #starIndices - 1 do
        local sP = pentagramPoints[starIndices[i]]
        local eP = pentagramPoints[starIndices[i + 1]]
        local line = Breadcrumbs.CreateLinePrimitive(
            sP.x, sP.y, sP.z,
            eP.x, eP.y, eP.z,
            Breadcrumbs.sV.colour or {1, 0, 0}
        )
        if line then
            table.insert(Breadcrumbs.sV.savedLines[zoneId], line)
        end
    end

    Breadcrumbs.RefreshLines()
    return zoneId
end


function Breadcrumbs.PopulateZoneLinesFromTable(zoneId, lines)
    Breadcrumbs.InitialiseExternalZone(zoneId)
    for _, line in pairs(lines) do
        table.insert(Breadcrumbs.sV.savedLines[zoneId], line)
    end
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
        table.remove(Breadcrumbs.sV.savedLines[zoneId], closest_line_index)
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
    Breadcrumbs.UpdateExportString()
    if Breadcrumbs.sV.enabled then 
        Breadcrumbs.StartPolling()
    else 
        Breadcrumbs.HideAllLines()
    end
end