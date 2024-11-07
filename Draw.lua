Breadcrumbs = Breadcrumbs or {}
Breadcrumbs.interval = 10

function Breadcrumbs.StopPolling()
    EVENT_MANAGER:UnregisterForUpdate( Breadcrumbs.name .. "Update" )
end

function Breadcrumbs.StartPolling()
    EVENT_MANAGER:UnregisterForUpdate( Breadcrumbs.name .. "Update" )
    EVENT_MANAGER:RegisterForUpdate( Breadcrumbs.name .. "Update", Breadcrumbs.interval, Breadcrumbs.DrawAllLines )
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
local function GetViewCoordinates(wX, wY, wZ)
    -- prepare render space
    Set3DRenderSpaceToCurrentCamera( Breadcrumbs.ctrl:GetName() )
    
    -- retrieve camera world position and orientation vectors
    local cX, cY, cZ = GuiRender3DPositionToWorldPosition( Breadcrumbs.ctrl:Get3DRenderSpaceOrigin() )
    local fX, fY, fZ = Breadcrumbs.ctrl:Get3DRenderSpaceForward()
    local rX, rY, rZ = Breadcrumbs.ctrl:Get3DRenderSpaceRight()
    local uX, uY, uZ = Breadcrumbs.ctrl:Get3DRenderSpaceUp()

    -- https://semath.info/src/inverse-cofactor-ex4.html
    -- calculate determinant for camera matrix
    -- local det = rX * uY * fZ - rX * uZ * fY - rY * uX * fZ + rZ * uX * fY + rY * uZ * fX - rZ * uY * fX
    -- local mul = 1 / det
    -- determinant should always be -1
    -- instead of multiplying simply negate
    -- calculate inverse camera matrix
    local i11 = -( uY * fZ - uZ * fY )
    local i12 = -( rZ * fY - rY * fZ )
    local i13 = -( rY * uZ - rZ * uY )
    local i21 = -( uZ * fX - uX * fZ )
    local i22 = -( rX * fZ - rZ * fX )
    local i23 = -( rZ * uX - rX * uZ )
    local i31 = -( uX * fY - uY * fX )
    local i32 = -( rY * fX - rX * fY )
    local i33 = -( rX * uY - rY * uX )
    local i41 = -( uZ * fY * cX + uY * fX * cZ + uX * fZ * cY - uX * fY * cZ - uY * fZ * cX - uZ * fX * cY )
    local i42 = -( rX * fY * cZ + rY * fZ * cX + rZ * fX * cY - rZ * fY * cX - rY * fX * cZ - rX * fZ * cY )
    local i43 = -( rZ * uY * cX + rY * uX * cZ + rX * uZ * cY - rX * uY * cZ - rY * uZ * cX - rZ * uX * cY )

    -- screen dimensions
    local uiW, uiH = GuiRoot:GetDimensions()

    -- calculate unit view position
    local pX = wX * i11 + wY * i21 + wZ * i31 + i41
    local pY = wX * i12 + wY * i22 + wZ * i32 + i42
    local pZ = wX * i13 + wY * i23 + wZ * i33 + i43

    -- calculate unit screen position
    -- Kyz: this is the only thing I did, really. Taking the absolute value of pZ allows the conversion
    -- to still work; the line doesn't draw particularly well, but the idea of it being behind the
    -- camera object is still conveyed. I don't claim to know anything about this math though...
    local w, h = GetWorldDimensionsOfViewFrustumAtDepth(math.abs(pZ))

    return pX * uiW / w, -pY * uiH / h, pZ > 0
end

function Breadcrumbs.DrawLine(x1, y1, x2, y2, line)
    line.backdrop:SetAnchorFill()
    line.backdrop:SetCenterColor(unpack(line.colour))
    line.backdrop:SetEdgeColor(unpack(line.colour))
    line.lineControl:ClearAnchors()
    line.lineControl:SetAnchor(CENTER, GuiRoot, CENTER, (x1 + x2) / 2, (y1 + y2) / 2)
    local x = x2 - x1
    local y = y2 - y1
    local length = math.sqrt(x*x + y*y)
    line.lineControl:SetDimensions(length, 8)
    local angle = math.atan(y/x)
    line.lineControl:SetTransformRotationZ(-angle)
end

function Breadcrumbs.DrawAllLines()
    local linePool = Breadcrumbs.GetLinePool()
    for _, line in pairs( linePool ) do
        if line.use ~= true then line.lineControl:SetHidden(true) break end
        local x1, y1, visible1 = GetViewCoordinates(line.x1, line.y1, line.z1)
        local x2, y2, visible2 = GetViewCoordinates(line.x2, line.y2, line.z2)
        
        if line.lineControl == nil then break end
        if (not visible1 and not visible2) then
            line.lineControl:SetHidden(true)
        else
            line.lineControl:SetHidden(false)
            Breadcrumbs.DrawLine(x1, y1, x2, y2, line)
        end
    end
end