Breadcrumbs = Breadcrumbs or {}

local LAM = LibAddonMenu2

local panelData = {
    type = "panel",
    name = Breadcrumbs.name, -- sidebar name
    author = Breadcrumbs.author,
    displayName = Breadcrumbs.title,
    version = Breadcrumbs.version,
    registerForRefresh = true,
    registerForDefaults = true,
}

local optionsTable = {
    {
        type = "header",
        name = "Settings",
    },
    {
        type = "checkbox",
        name = "Enabled",
        tooltip = "Toggles visibility of the lines",
        default = Breadcrumbs.defaults.enabled,
        getFunc = function() return Breadcrumbs.sV.enabled end,
        setFunc = function(value)
            Breadcrumbs.sV.enabled = value
            Breadcrumbs.RefreshLines()
        end,
    },
    {
        type = "button",
        name = "Clear Zone",
        warning = "This will delete all lines from your current zone",
        isDangerous = true,
        func = function(value) Breadcrumbs.ClearSavedZoneLinesFromThisZone() end,
    },
    {
        type = "header",
        name = "Import",
    },
    {
        type = "editbox",
        name = "Config",
        tooltip = "Insert a valid Breadcrumbs string to import new lines into the correct zone",
        default = Breadcrumbs.defaults.importString,
        isMultiline = true,
        isExtraWide = true,
        maxChars = 30000,
        getFunc = function() return Breadcrumbs.sV.importString end,
        setFunc = function(value) Breadcrumbs.sV.importString = value end,
    },
    {
        type = "button",
        name = "Import",
        func = function(value) Breadcrumbs.ImportStringToLines() end,
    },
    {
        type = "header",
        name = "Export String",
    },
    {
        type = "editbox",
        name = "Config",
        tooltip = "String that describes the lines for the current zone",
        default = Breadcrumbs.defaults.exportString,
        isMultiline = true,
        isExtraWide = true,
        maxChars = 10000,
        getFunc = function() return Breadcrumbs.sV.exportString end,
        setFunc = function(value) end,
    },
    {
        type = "submenu",
        name = "General Settings",
        controls = {
            {
                type = "slider",
                name = "Line width",
                min = 3,
                max = 24,
                default = Breadcrumbs.defaults.width,
                getFunc = function() return Breadcrumbs.sV.width end,
                setFunc = function(value) Breadcrumbs.sV.width = value end,
            },
            {
                type = "slider",
                name = "Line opacity",
                min = 0.1,
                max = 1,
                step = 0.05,
                decimals = 2,
                default = Breadcrumbs.interval,
                getFunc = function() return Breadcrumbs.sV.alpha end,
                setFunc = function(value) Breadcrumbs.sV.alpha = value end,
            },
            {
                type = "slider",
                name = "Polling frquency (ms)",
                min = 1,
                max = 24,
                step = 1,
                default = Breadcrumbs.defaults.polling,
                getFunc = function() return Breadcrumbs.sV.polling end,
                setFunc = function(value) Breadcrumbs.sV.polling = value Breadcrumbs.StopPolling() Breadcrumbs.StartPolling() end,
            },
        },
    },
    {
        type = "header",
        name = "Draw lines",
    },
    {
        type = "button",
        name = "/breadcrumbs",
        func = function(value) Breadcrumbs.ToggleUIVisibility() end,
    },
    {
        type = "submenu",
        name = "Drawing Readme/Guide",
        controls = {
            {
                type = "description",
                text = "To draw lines using the draw menu simply save your current location into either location 1 (loc1) or location 2 (loc2) at two different positions, then click draw. This will create a line between these two positions.\nUsing the pin icon next to loc1 or loc2 will snap it to the nearest point to you. This is useful for modifying line connections. Also, it reduces the length of your export string.\nYou can select the colour of the line from a palette using the dropdown, or specify your own colour using the colour picker accessed through the custom button.\nTo remove a line, simply press remove. Finally, you can use the functions below to draw special shapes, such as polygons.",
            },
        },
    },
    {
        type = "header",
        name = "Shapes",
    },
    {
        type = "submenu",
        name = "Regular Polygon",
        controls = {
            {
                type = "description",
                text = "Select the appropriate parameters and then click draw to create a regular polygon around yourself. For shapes with an odd number of vertices, the first vertex is placed directly in front of you. For those with an even number, the first edge is placed in front of you instead.",
            },
            {
                type = "slider",
                name = "Number of sides",
                min = 3,
                max = 24,
                default = Breadcrumbs.defaults.polygon_sides,
                getFunc = function() return Breadcrumbs.sV.polygon_sides end,
                setFunc = function(value) Breadcrumbs.sV.polygon_sides = value end,
            },
            {
                type = "slider",
                name = "Radius of shape",
                min = 1,
                max = 100,
                step = 1,
                decimals = 1,
                default = Breadcrumbs.defaults.polygon_radius,
                getFunc = function() return Breadcrumbs.sV.polygon_radius end,
                setFunc = function(value) Breadcrumbs.sV.polygon_radius = value end,
            },
            {
                type = "colorpicker",
                name = "Colour",
                default = ZO_ColorDef:New(unpack(Breadcrumbs.defaults.colour)),
                getFunc = function() return unpack(Breadcrumbs.sV.colour) end,
                setFunc = function(r,g,b,a) Breadcrumbs.SetLineColour(r, g, b) end,
            },
            {
                type = "button",
                name = "Draw Polygon",
                tooltip = "Draws the defined polygon centered around your current location",
                func = function(value) Breadcrumbs.DrawPolygon(Breadcrumbs.sV.polygon_radius, Breadcrumbs.sV.polygon_sides, Breadcrumbs.sV.colour) end,
            },
        },
    },
    {
        type = "submenu",
        name = "Pentagram",
        controls = {
            {
                type = "description",
                text = "Similar to polygon, but a pentagram because it looks cool. I mainly used this to test, but thought maybe someone could use the function. Uses your selected brush colour from the draw menu.",
            },
            {
                type = "slider",
                name = "Number of sides",
                min = 5,
                max = 32,
                default = Breadcrumbs.defaults.polygon_sides,
                getFunc = function() return Breadcrumbs.sV.polygon_sides end,
                setFunc = function(value) Breadcrumbs.sV.polygon_sides = value end,
                clampInput = true,
            },
            {
                type = "slider",
                name = "Radius of shape",
                min = 1,
                max = 24,
                step = 1,
                default = Breadcrumbs.defaults.polygon_radius,
                getFunc = function() return Breadcrumbs.sV.polygon_radius end,
                setFunc = function(value) Breadcrumbs.sV.polygon_radius = value end,
                clampInput = true,
            },
            {
                type = "button",
                name = "Draw Pentagram",
                tooltip = "Draws the defined polygon centered around your current location",
                func = function(value) Breadcrumbs.DrawPentagram(Breadcrumbs.sV.polygon_radius, Breadcrumbs.sV.polygon_sides) end,
            },
        },
    },
    {
        type = "submenu",
        name = "3D Axis",
        controls = {
            {
                type = "description",
                text = "For debugging, draws a set of three lines. |cff0000+X|r, |c00ff00+Y|r, |c0000ff+Z|r.",
            },
            {
                type = "button",
                name = "Draw Axis",
                func = function(value) Breadcrumbs.Generate3DAxisLines() end,
            },
        },
    },
}

function Breadcrumbs.RegisterSettingsPanel()
    Breadcrumbs.addon_panel = LAM:RegisterAddonPanel(Breadcrumbs.name.."Options", panelData)
    LAM:RegisterOptionControls(Breadcrumbs.name.."Options", optionsTable)
end