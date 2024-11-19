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

    local dX, dY, dZ = wX - cX, wY - cY, wZ - cZ
    local dist = 1 + zo_sqrt( dX * dX + dY * dY + dZ * dZ )
    local scale = 2000 / dist or 1

    return pX * uiW / w, -pY * uiH / h, pZ > 0, scale
end

function Breadcrumbs.DrawLine(x1, y1, x2, y2, line, scale)
    line.backdrop:SetAnchorFill()
    local r, g, b = unpack(line.colour)
    line.backdrop:SetCenterColor(r, g, b, Breadcrumbs.sV.alpha)
    line.backdrop:SetEdgeColor(0,0,0,0)
    line.lineControl:ClearAnchors()
    line.lineControl:SetAnchor(CENTER, GuiRoot, CENTER, (x1 + x2) / 2, (y1 + y2) / 2)
    local x = x2 - x1
    local y = y2 - y1
    local length = math.sqrt(x*x + y*y)
    line.lineControl:SetDimensions(length, Breadcrumbs.sV.width * scale)
    local angle = math.atan(y/x)
    line.lineControl:SetTransformRotationZ(-angle)
end

function Breadcrumbs.DrawAllLines()
    local linePool = Breadcrumbs.GetLinePool()
    -- local _, x, y, z = GetUnitRawWorldPosition("player")
    for _, line in pairs( linePool ) do
        -- local x1, y1, visible1, scale1 = GetViewCoordinates(line.x1, line.y1, line.z1)
        -- local x2, y2, visible2, scale2 = GetViewCoordinates(line.x2, line.y2, line.z2)
        -- local scale = math.max(scale1, scale2)
        -- -- local maxYDistance = 1 + math.min(math.abs(y - line.y1), math.abs(y - line.y2)) / 500
        -- -- scale = math.min(scale * (1 / maxYDistance), 1)
        -- if line.use ~= true then visible1 = false visible2 = false end
        -- if scale < ( 1. / Breadcrumbs.sV.width ) then visible1 = false visible2 = false end -- fade out far away lines

        -- if (not visible1 and not visible2) then
        --     line.lineControl:SetHidden(true)
        -- else
        --     line.lineControl:SetHidden(false)
        --     Breadcrumbs.DrawLine(x1, y1, x2, y2, line, scale)
        -- end
        if line.use then line.lineControl:SetHidden(false) else line.lineControl:SetHidden(true) end
        line.lineControl:SetTexture("esoui/art/icons/icon_missing.dds")
        if not line.lineControl:Has3DRenderSpace() then
            line.lineControl:Create3DRenderSpace()
        end
        local dx = (line.x2-line.x1)/2
        local dy = (line.y2-line.y1)/2
        local dz = (line.z2-line.z1)/2
        local mx = line.x1+dx
        local my = line.y1+dy
        local mz = line.z1+dz
        local length = math.sqrt(dx*dx + dy*dy + dz*dz)
        local width = length / 50
        local height = 0.5
        line.lineControl:Set3DLocalDimensions(width, height)
        line.lineControl:SetDrawLevel(3)
        line.lineControl:SetColor(1, 1, 1, 1)
        line.lineControl:Set3DRenderSpaceUsesDepthBuffer(true)
        line.lineControl:Set3DRenderSpaceOrigin(0,0,0)
        local worldX, worldY, worldZ = WorldPositionToGuiRender3DPosition(mx, my+45, mz)
        line.lineControl:Set3DRenderSpaceOrigin(worldX, worldY, worldZ)
        d(worldX .. " | " .. worldY .. " | " .. worldZ)
        -- local heading = GetPlayerCameraHeading()
        -- if heading > math.pi then --normalize heading to [-pi,pi]
        --     heading = heading - 2 * math.pi
        -- end
        local roll = Breadcrumbs.calculateRoll(dx, dy, dz)
        local yaw = Breadcrumbs.calculateYaw(dx, dy, dz)
        --d(yaw .. " | dx: " .. dx .. " dz: " .. dz)
        --d(roll .. " | dx: " .. dx .. " dy: " .. dy)
        line.lineControl:Set3DRenderSpaceOrientation(0,-yaw,roll)
    end
    d(GetUnitRawWorldPosition("player"))
end

function Breadcrumbs.calculateRoll(x, y, z)
    local roll = math.atan2(y, x)
    if (x < 0) then 
        roll = roll - math.pi
    end
    return roll
end

function Breadcrumbs.calculateYaw(x, y, z)
    local yaw = math.atan2(z, x)
    return yaw
end

function Breadcrumbs.HideAllLines()
    local linePool = Breadcrumbs.GetLinePool()
    for _, line in pairs( linePool ) do
        line.lineControl:SetHidden(true) 
    end
end