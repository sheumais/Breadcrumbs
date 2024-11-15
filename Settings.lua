Breadcrumbs = Breadcrumbs or {}

local LAM = LibAddonMenu2

local panelData = {
    type = "panel",
    name = Breadcrumbs.name, -- sidebar name
    displayName = Breadcrumbs.title,
    author = Breadcrumbs.author,
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
        default = Breadcrumbs.defaults.alpha,
        getFunc = function() return Breadcrumbs.sV.alpha end,
        setFunc = function(value) Breadcrumbs.sV.alpha = value end,
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
        getFunc = function() return Breadcrumbs.sV.exportString end,
        setFunc = function(value) end,
    },
    {
        type = "header",
        name = "Draw Shapes",
    },
    {
        type = "submenu",
        name = "Regular Polyhedra",
        controls = {
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
                default = Breadcrumbs.defaults.colour,
                getFunc = function() return unpack(Breadcrumbs.sV.colour) end,
                setFunc = function(r,g,b,a) Breadcrumbs.sV.colour = {r,g,b} end,
            },
            {
                type = "button",
                name = "Draw",
                tooltip = "Draws the defined polygon centered around your current location",
                func = function(value) Breadcrumbs.DrawPolygon(Breadcrumbs.sV.polygon_radius, Breadcrumbs.sV.polygon_sides, Breadcrumbs.sV.colour) end,
            },
        },
    },
}

function Breadcrumbs.RegisterSettingsPanel()
    LAM:RegisterAddonPanel(Breadcrumbs.name.."Options", panelData)
    LAM:RegisterOptionControls(Breadcrumbs.name.."Options", optionsTable)
end