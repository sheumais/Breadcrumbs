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

local optionsTable = {}

function Breadcrumbs.RegisterSettingsPanel()
    LAM:RegisterAddonPanel(Breadcrumbs.name, panelData)
    LAM:RegisterOptionControls(Breadcrumbs.name, optionsTable)
end