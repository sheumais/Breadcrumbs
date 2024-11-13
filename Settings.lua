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
        getFunc = function() 
            return Breadcrumbs.sV.enabled
        end,
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
        getFunc = function() 
            return Breadcrumbs.sV.width
        end,
        setFunc = function(value)
            Breadcrumbs.sV.width = value
        end,
    },
    {
        type = "slider",
        name = "Line opacity",
        min = 0.1,
        max = 1,
        step = 0.05,
        decimals = 2,
        default = Breadcrumbs.defaults.alpha,
        getFunc = function() 
            return Breadcrumbs.sV.alpha
        end,
        setFunc = function(value)
            Breadcrumbs.sV.alpha = value
        end,
    },
    {
        type = "button",
        name = "Clear Zone",
        warning = "This will delete all lines from your current zone",
        isDangerous = true,
        func = function(value)
            Breadcrumbs.ClearSavedZoneLinesFromThisZone()
        end,
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
        getFunc = function() 
            return Breadcrumbs.sV.importString
        end,
        setFunc = function(value)
            Breadcrumbs.sV.importString = value
        end,
    },
    {
        type = "button",
        name = "Import",
        tooltip = "Import the Breadcrumbs line string",
        func = function(value)
            Breadcrumbs.ImportStringToLines()
        end,
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
        getFunc = function() 
            return Breadcrumbs.sV.exportString
        end,
        setFunc = function(value)
        end,
    },
}

function Breadcrumbs.RegisterSettingsPanel()
    LAM:RegisterAddonPanel(Breadcrumbs.name.."Options", panelData)
    LAM:RegisterOptionControls(Breadcrumbs.name.."Options", optionsTable)
end