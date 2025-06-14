Breadcrumbs = Breadcrumbs or {}

local DrawLine, GetLinePool, DrawAllLines, sqrt, atan, min, max, abs, uiW, uiH, width, BreadcrumbsControl, negUiH

function Breadcrumbs.StopPolling()
    EVENT_MANAGER:UnregisterForUpdate( Breadcrumbs.name .. "Update" )
end

function Breadcrumbs.StartPolling()
    DrawLine = Breadcrumbs.DrawLine
    GetLinePool = Breadcrumbs.GetLinePool
    DrawAllLines = Breadcrumbs.DrawAllLines
    uiW, uiH = GuiRoot:GetDimensions()
    negUiH = -uiH
    sqrt = math.sqrt
    atan = math.atan
    min = math.min
    max = math.max
    abs = math.abs
    width = Breadcrumbs.sV.width
    BreadcrumbsControl = Breadcrumbs.ctrl
    local linePool = GetLinePool()
    for _, line in pairs( linePool ) do
        Breadcrumbs.InitialiseLine(line)
    end
    Breadcrumbs.scaleFactor = 1. / width

    EVENT_MANAGER:UnregisterForUpdate( Breadcrumbs.name .. "Update" )
    EVENT_MANAGER:RegisterForUpdate( Breadcrumbs.name .. "Update", Breadcrumbs.sV.polling, DrawAllLines )
end

local cX, cY, cZ, fX, fY, fZ, rX, rY, rZ, uX, uY, uZ
local pX, pY, pZ
local hash
local function GetMatrixValues()
    Set3DRenderSpaceToCurrentCamera(BreadcrumbsControl:GetName())
    cX, cY, cZ = GuiRender3DPositionToWorldPosition(BreadcrumbsControl:Get3DRenderSpaceOrigin())
    fX, fY, fZ = BreadcrumbsControl:Get3DRenderSpaceForward()
    rX, rY, rZ = BreadcrumbsControl:Get3DRenderSpaceRight()
    uX, uY, uZ = BreadcrumbsControl:Get3DRenderSpaceUp()

    _, pX, pY, pZ = GetUnitRawWorldPosition('player')

    hash = cX + cY + cZ + fX + fY + fZ + rX + rY + rZ + uX + uY + uZ
end

Breadcrumbs.GetMatrixValues = GetMatrixValues

local function clamp(val, minVal, maxVal)
    return max(minVal, min(val, maxVal))
end

local function GetViewCoordinates(wX, wY, wZ)
    local dX, dY, dZ = wX - cX, wY - cY, wZ - cZ
    local Z = fX * dX + fY * dY + fZ * dZ

    if Z < 1 then
        return nil, nil, false, 0
    end

    local X = rX * dX + rZ * dZ
    local Y = uX * dX + uY * dY + uZ * dZ

    local w, h = GetWorldDimensionsOfViewFrustumAtDepth(Z)
    local scaleW = uiW / w
    local scaleH = negUiH / h

    local screenX = X * scaleW
    local screenY = Y * scaleH

    local distX, distY, distZ = pX - wX, pY - wY, pZ - wZ
    local dist = max(100, sqrt(dX * dX + dY * dY + dZ * dZ))
    local scale = 2000 / dist

    return screenX, screenY, true, scale
end

Breadcrumbs.GetViewCoordinates = GetViewCoordinates

local function CalculateView(wX1, wY1, wZ1, wX2, wY2, wZ2)
    local dX1, dY1, dZ1 = wX1 - cX, wY1 - cY, wZ1 - cZ
    local dX2, dY2, dZ2 = wX2 - cX, wY2 - cY, wZ2 - cZ

    local Z1 = fX * dX1 + fY * dY1 + fZ * dZ1
    local Z2 = fX * dX2 + fY * dY2 + fZ * dZ2

    local nearZ = 1
    if Z1 < nearZ and Z2 < nearZ then
        return nil
    end

    local X1 = rX * dX1 + rZ * dZ1
    local Y1 = uX * dX1 + uY * dY1 + uZ * dZ1
    local X2 = rX * dX2 + rZ * dZ2
    local Y2 = uX * dX2 + uY * dY2 + uZ * dZ2

    if Z1 < nearZ or Z2 < nearZ then
        local t = (nearZ - Z1) / (Z2 - Z1)
        local clipX = X1 + t * (X2 - X1)
        local clipY = Y1 + t * (Y2 - Y1)
        if Z1 < nearZ then
            X1, Y1, Z1 = clipX, clipY, nearZ
        else
            X2, Y2, Z2 = clipX, clipY, nearZ
        end
    end

    local w1, h1 = GetWorldDimensionsOfViewFrustumAtDepth(Z1)
    local w2, h2 = GetWorldDimensionsOfViewFrustumAtDepth(Z2)

    local screenX1 = X1 * uiW / w1
    local screenY1 = Y1 * negUiH / h1
    local screenX2 = X2 * uiW / w2
    local screenY2 = Y2 * negUiH / h2

    local dist1 = dX1 * dX1 + dY1 * dY1 + dZ1 * dZ1
    local dist2 = dX2 * dX2 + dY2 * dY2 + dZ2 * dZ2
    local scale = sqrt(min(4e6 / dist1, 4e6 / dist2))

    return screenX1, screenY1, screenX2, screenY2, scale
end

Breadcrumbs.CalculateView = CalculateView

local function DrawMarker(x, y, marker, scale)
    marker:SetAnchor(BOTTOM, GuiRoot, CENTER, x, y)
    local s = Breadcrumbs.sV.width * 5 * scale
    marker:SetDimensions(s, s)
    local r, g, b = unpack(Breadcrumbs.sV.colour)
    marker:SetColor(r, g, b, Breadcrumbs.sV.alpha)
end

local function TryDrawMarker(loc, marker)
    if loc and next(loc) then
        local x, y, visible, scale = GetViewCoordinates(loc.x, loc.y, loc.z)
        if visible and (scale > Breadcrumbs.scaleFactor) then
            DrawMarker(x, y, marker, scale)
            marker:SetHidden(false)
            return
        end
    end
    marker:SetHidden(true)
end

local function DrawMarkers()
    TryDrawMarker(Breadcrumbs.sV.loc1, Breadcrumbs.marker1)
    TryDrawMarker(Breadcrumbs.sV.loc2, Breadcrumbs.marker2)
end

function Breadcrumbs.InitialiseLine(line)
    local lineBackdrop = line.backdrop
    lineBackdrop:SetAnchorFill()
    local r, g, b = unpack(line.colour)
    lineBackdrop:SetCenterColor(r, g, b, Breadcrumbs.sV.alpha)
    lineBackdrop:SetEdgeColor(0,0,0,0)
end

function Breadcrumbs.DrawLine(x1, y1, x2, y2, line, scale)
    local lineControl = line.lineControl
    local midX = (x1 + x2) / 2
    local midY = (y1 + y2) / 2
    lineControl:SetAnchor(CENTER, GuiRoot, CENTER, midX, midY)

    local dx = x2 - x1
    local dy = y2 - y1
    local length = sqrt(dx * dx + dy * dy)
    local angle = atan(dy / dx)

    lineControl:SetDimensions(length, width * scale)
    lineControl:SetTransformRotationZ(-angle)
end

function Breadcrumbs.DrawAllLines()
    local linePool = GetLinePool()
    local old_hash = hash
    GetMatrixValues()
    if Breadcrumbs.showUI then 
        DrawMarkers()
    end
    for _, line in pairs( linePool ) do
        if line.use then 
            if (old_hash == hash) then return end
            local x1, y1, x2, y2, scale = CalculateView(line.x1, line.y1, line.z1, line.x2, line.y2, line.z2)
            if x1 and y1 and x2 and y2 and scale >= Breadcrumbs.sV.minimumScale then 
                DrawLine(x1, y1, x2, y2, line, scale)
                line.lineControl:SetHidden(false)
            else 
                line.lineControl:SetHidden(true)
            end
        else
            line.lineControl:SetHidden(true) 
        end
    end
end

function Breadcrumbs.HideAllLines()
    local linePool = GetLinePool()
    for _, line in pairs( linePool ) do
        line.lineControl:SetHidden(true) 
    end
end