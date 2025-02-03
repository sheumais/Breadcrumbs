Breadcrumbs = Breadcrumbs or {}

local DrawLine, GetLinePool, DrawAllLines, sqrt, atan, min, abs, uiW, uiH

function Breadcrumbs.StopPolling()
    EVENT_MANAGER:UnregisterForUpdate( Breadcrumbs.name .. "Update" )
end

function Breadcrumbs.StartPolling()
    DrawLine = Breadcrumbs.DrawLine
    GetLinePool = Breadcrumbs.GetLinePool
    DrawAllLines = Breadcrumbs.DrawAllLines
    uiW, uiH = GuiRoot:GetDimensions()
    sqrt = math.sqrt
    atan = math.atan
    min = math.min
    abs = math.abs
    local linePool = GetLinePool()
    -- local _, x, y, z = GetUnitRawWorldPosition("player")
    for _, line in pairs( linePool ) do
        Breadcrumbs.InitialiseLine(line)
    end
    Breadcrumbs.scaleFactor = 1. / Breadcrumbs.sV.width

    EVENT_MANAGER:UnregisterForUpdate( Breadcrumbs.name .. "Update" )
    EVENT_MANAGER:RegisterForUpdate( Breadcrumbs.name .. "Update", Breadcrumbs.sV.polling, DrawAllLines )
end

---------------------------------------------------------------------
-- Convert in-world coordinates to view via fancy linear algebra.
-- This is ripped almost entirely from OSI, with only minor changes
-- to not modify icons, and instead only return coordinates
-- Credit: OdySupportIcons (@Lamierina7)
--
-- I'm [Kyzeragon] doing this because OSI icons do not show/update when the
-- position is far enough behind the camera, and therefore I can't
-- naively draw a line between 2 player icons, because one or both
-- could be hidden or have outdated coords.
--
-- Returns: x, y, isInFront (of camera)
---------------------------------------------------------------------
-- FROM CRUTCH ALERTS https://www.esoui.com/downloads/info3137-CrutchAlerts.html
---------------------------------------------------------------------
local cX, cY, cZ, fX, fY, fZ, rX, rY, rZ, uX, uY, uZ
local i11, i12, i13, i21, i22, i23, i31, i32, i33, i41, i42, i43
local function GetMatrixValues()
    Set3DRenderSpaceToCurrentCamera( Breadcrumbs.ctrl:GetName() )
    cX, cY, cZ = GuiRender3DPositionToWorldPosition( Breadcrumbs.ctrl:Get3DRenderSpaceOrigin() )
    fX, fY, fZ = Breadcrumbs.ctrl:Get3DRenderSpaceForward()
    rX, rY, rZ = Breadcrumbs.ctrl:Get3DRenderSpaceRight()
    uX, uY, uZ = Breadcrumbs.ctrl:Get3DRenderSpaceUp()
    -- https://semath.info/src/inverse-cofactor-ex4.html
    -- calculate determinant for camera matrix
    -- local det = rX * uY * fZ - rX * uZ * fY - rY * uX * fZ + rZ * uX * fY + rY * uZ * fX - rZ * uY * fX
    -- local mul = 1 / det
    -- determinant should always be -1
    -- instead of multiplying simply negate
    -- calculate inverse camera matrix
    i11 = -( uY * fZ - uZ * fY )
    i12 = -( rZ * fY - rY * fZ )
    i13 = -( rY * uZ - rZ * uY )
    i21 = -( uZ * fX - uX * fZ )
    i22 = -( rX * fZ - rZ * fX )
    i23 = -( rZ * uX - rX * uZ )
    i31 = -( uX * fY - uY * fX )
    i32 = -( rY * fX - rX * fY )
    i33 = -( rX * uY - rY * uX )
    i41 = -( uZ * fY * cX + uY * fX * cZ + uX * fZ * cY - uX * fY * cZ - uY * fZ * cX - uZ * fX * cY )
    i42 = -( rX * fY * cZ + rY * fZ * cX + rZ * fX * cY - rZ * fY * cX - rY * fX * cZ - rX * fZ * cY )
    i43 = -( rZ * uY * cX + rY * uX * cZ + rX * uZ * cY - rX * uY * cZ - rY * uZ * cX - rZ * uX * cY )
end

Breadcrumbs.GetMatrixValues = GetMatrixValues

-- legacy function used for markers only and compatibility with other addons
local function GetViewCoordinates(wX, wY, wZ)
    -- calculate unit view position
    local pX = wX * i11 + wY * i21 + wZ * i31 + i41
    local pY = wX * i12 + wY * i22 + wZ * i32 + i42
    local pZ = wX * i13 + wY * i23 + wZ * i33 + i43

    -- calculate unit screen position
    -- Kyz: this is the only thing I did, really. Taking the absolute value of pZ allows the conversion
    -- to still work; the line doesn't draw particularly well, but the idea of it being behind the
    -- camera object is still conveyed. I don't claim to know anything about this math though...
    local w, h = GetWorldDimensionsOfViewFrustumAtDepth(abs(pZ))

    local dX, dY, dZ = wX - cX, wY - cY, wZ - cZ
    local dist = 1 + sqrt( dX * dX + dY * dY + dZ * dZ )
    local scale = 2000 / dist or 1

    return pX * uiW / w, -pY * uiH / h, pZ > 0, scale
end

Breadcrumbs.GetViewCoordinates = GetViewCoordinates

local function CalculateView(wX1, wY1, wZ1, wX2, wY2, wZ2)
    local pX1 = wX1 * i11 + wY1 * i21 + wZ1 * i31 + i41
    local pY1 = wX1 * i12 + wY1 * i22 + wZ1 * i32 + i42
    local pZ1 = wX1 * i13 + wY1 * i23 + wZ1 * i33 + i43
    local pX2 = wX2 * i11 + wY2 * i21 + wZ2 * i31 + i41
    local pY2 = wX2 * i12 + wY2 * i22 + wZ2 * i32 + i42
    local pZ2 = wX2 * i13 + wY2 * i23 + wZ2 * i33 + i43


    local nearZ = 0.1  -- define near clipping plane
    if pZ1 < nearZ and pZ2 < nearZ then -- both points behind the near plane, discard the line
        return nil
    end
    if pZ1 < 0 or pZ2 < 0 then -- find point on near-clipping plane
        local t = (nearZ - pZ1) / (pZ2 - pZ1)
        local clipX = pX1 + t * (pX2 - pX1)
        local clipY = pY1 + t * (pY2 - pY1)
        if pZ1 < 0 then -- only one of z1 or z2 can be < 0
            pX1, pY1, pZ1 = clipX, clipY, nearZ
        else 
            pX2, pY2, pZ2 = clipX, clipY, nearZ
        end
    end

    local w1, h1 = GetWorldDimensionsOfViewFrustumAtDepth(pZ1)
    local w2, h2 = GetWorldDimensionsOfViewFrustumAtDepth(pZ2)
    
    local dX1, dY1, dZ1 = wX1 - cX, wY1 - cY, wZ1 - cZ
    local dist1 = dX1 * dX1 + dY1 * dY1 + dZ1 * dZ1
    local scale1 = 4e6 / dist1
    local dX2, dY2, dZ2 = wX2 - cX, wY2 - cY, wZ2 - cZ
    local dist2 = dX2 * dX2 + dY2 * dY2 + dZ2 * dZ2
    local scale2 = 4e6 / dist2
    local scale = sqrt(min(scale1, scale2))

    return pX1 * uiW / w1, -pY1 * uiH / h1, pX2 * uiW / w2, -pY2 * uiH / h2, scale
end

local function DrawMarker(x, y, marker, scale)
    marker:SetAnchor(BOTTOM, GuiRoot, CENTER, x, y)
    local s = Breadcrumbs.sV.width * 5 * scale
    marker:SetDimensions(s, s)
    local r, g, b = unpack(Breadcrumbs.sV.colour)
    marker:SetColor(r, g, b, Breadcrumbs.sV.alpha)
end

local function DrawMarkers()
    local loc1 = Breadcrumbs.sV.loc1
    local loc2 = Breadcrumbs.sV.loc2
    if loc1 ~= {} then 
        local x1, y1, visible1, scale1 = GetViewCoordinates(loc1.x, loc1.y, loc1.z)
        if visible1 and (scale1 > Breadcrumbs.scaleFactor) then 
            Breadcrumbs.marker1:SetHidden(false)
            DrawMarker(x1, y1, Breadcrumbs.marker1, scale1)
        else 
            Breadcrumbs.marker1:SetHidden(true)
        end
    else 
        Breadcrumbs.marker1:SetHidden(true)
    end
    if loc2 ~= {} then 
        local x2, y2, visible2, scale2 = GetViewCoordinates(loc2.x, loc2.y, loc2.z)
        if visible2 and (scale2 > Breadcrumbs.scaleFactor)then 
            Breadcrumbs.marker2:SetHidden(false)
            DrawMarker(x2, y2, Breadcrumbs.marker2, scale2)
        else 
            Breadcrumbs.marker2:SetHidden(true)
        end
    else 
        Breadcrumbs.marker2:SetHidden(true)
    end
end

function Breadcrumbs.InitialiseLine(line)
    line.backdrop:SetAnchorFill()
    local r, g, b = unpack(line.colour)
    line.backdrop:SetCenterColor(r, g, b, Breadcrumbs.sV.alpha)
    line.backdrop:SetEdgeColor(0,0,0,0)
end

function Breadcrumbs.DrawLine(x1, y1, x2, y2, line, scale)
    line.lineControl:SetAnchor(CENTER, GuiRoot, CENTER, (x1 + x2) / 2, (y1 + y2) / 2)
    local x = x2 - x1
    local y = y2 - y1
    local length = sqrt(x*x + y*y)
    line.lineControl:SetDimensions(length, Breadcrumbs.sV.width * scale)
    local angle = atan(y/x)
    line.lineControl:SetTransformRotationZ(-angle)
end

function Breadcrumbs.DrawAllLines() -- use TextureCompositeControl ?
    local linePool = GetLinePool()
    GetMatrixValues()
    if Breadcrumbs.showUI then 
        DrawMarkers()
    end
    for _, line in pairs( linePool ) do
        if line.use then 
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