Breadcrumbs = Breadcrumbs or {}

function Breadcrumbs.CreateLine( name )
    local line = {}
    line.lineControl = WINDOW_MANAGER:CreateControl(name, Breadcrumbs.win, CT_CONTROL)
    line.backdrop = WINDOW_MANAGER:CreateControl("$(parent)Backdrop", line.lineControl, CT_BACKDROP)
    return line
end

function Breadcrumbs.CreateNewLine( x1, y1, z1, x2, y2, z2, colour )
    local line
    local lines = Breadcrumbs.GetLines()
    -- try to find an unused line
    for _, i in pairs( lines ) do
        if not i.use then
            line = i
            break
        end
    end
    -- create a new line if no unused line is available
    if not line then
        line, lineControl = Breadcrumbs.CreateLine( "BreadcrumbsLine" .. #lines )
        lines[#lines + 1] = line
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

function Breadcrumbs.GetLines()
    return Breadcrumbs.savedVariables.lines or {}
end