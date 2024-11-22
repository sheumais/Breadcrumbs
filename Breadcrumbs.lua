Breadcrumbs = Breadcrumbs or {}
Breadcrumbs.name = "Breadcrumbs"
Breadcrumbs.version = "1.2"
Breadcrumbs.author = "TheMrPancake"
Breadcrumbs.title = "|cff7f40Breadcrumbs|r"

Breadcrumbs.savedVariablesVersion = 1 -- don't change
Breadcrumbs.showUI = false
Breadcrumbs.ui = {}
Breadcrumbs.defaults = {
    savedLines = {},
    loc1 = nil,
    loc2 = nil,
    colour = {1,1,1},
    enabled = true,
    width = 6,
    alpha = 1,
    importString = "",
    exportString = "",
    polygon_radius = 5,
    polygon_sides = 8,
    polling = 10,
}

Breadcrumbs.window = GetWindowManager()
function Breadcrumbs.CreateTopLevelControl()
    Breadcrumbs.ctrl = Breadcrumbs.window:CreateControl( "BreadcrumbsControl", GuiRoot, CT_CONTROL )
    Breadcrumbs.ctrl:SetAnchorFill( GuiRoot )
    Breadcrumbs.ctrl:Create3DRenderSpace()
    Breadcrumbs.ctrl:SetHidden( true )

    Breadcrumbs.win = Breadcrumbs.window:CreateTopLevelWindow( "BreadcrumbsWindow" )
    Breadcrumbs.win:SetClampedToScreen( true )
    Breadcrumbs.win:SetMouseEnabled( false )
    Breadcrumbs.win:SetMovable( false )
    Breadcrumbs.win:SetAnchorFill( GuiRoot )
    Breadcrumbs.win:SetDrawLayer( DL_BACKGROUND )
    Breadcrumbs.win:SetDrawTier( DT_LOW )
    Breadcrumbs.win:SetDrawLevel( 0 )

    local frag = ZO_HUDFadeSceneFragment:New( Breadcrumbs.win )
    HUD_UI_SCENE:AddFragment( frag )
    HUD_SCENE:AddFragment( frag )
    LOOT_SCENE:AddFragment( frag )
end

function Breadcrumbs.LoadSavedZoneLines(event)
    Breadcrumbs.InitialiseZone()
    Breadcrumbs.RefreshLines()
end

Breadcrumbs.colour_palette = {
    {name = "Red", colour = {1, 0, 0}},
    {name = "Orange", colour = {1, 0.5, 0}},
    {name = "Yellow", colour = {1, 1, 0}},
    {name = "Green", colour = {0, 1, 0}},
    {name = "Light Blue", colour = {0, 1, 1}},
    {name = "Blue", colour = {0, 0, 1}},
    {name = "Violet", colour = {0.5, 0, 1}},
    {name = "Magenta", colour = {1, 0, 0.5}},
    {name = "White", colour = {1, 1, 1}},
    {name = "Black", colour = {0, 0, 0}},
}

function Breadcrumbs.SelectColourFromPalette(_, entryText, entry)
    local colour = Breadcrumbs.colour_palette[entry.colour_index].colour
    Breadcrumbs.SetLineColour(unpack(colour))
end

function Breadcrumbs.InitialiseUI()
    Breadcrumbs.ui.interface = Breadcrumbs_Menu_Window or {}
    Breadcrumbs.ui.square = Breadcrumbs_Menu_Window_Coloured_Square or {}
    Breadcrumbs.ui.colour = Breadcrumbs_Menu_Window_Colour or {}
    local colour_selection_control = Breadcrumbs.ui.colour:GetNamedChild("_Selection")
    Breadcrumbs.ui.combobox = ZO_ComboBox_ObjectFromContainer(colour_selection_control)
    Breadcrumbs.ui.combobox:SetSortsItems(false)
    Breadcrumbs.ui.combobox:SetDropdownFont("ZoFontHeader")
    Breadcrumbs.ui.combobox:SetSpacing(8)

    Breadcrumbs.ui.square:SetColor(unpack(Breadcrumbs.sV.colour or {1, 1, 1}))
    Breadcrumbs.showUI = false
    Breadcrumbs.sV.importString = ""
    for i, colour in ipairs( Breadcrumbs.colour_palette ) do
        local entry = Breadcrumbs.ui.combobox:CreateItemEntry(colour.name, Breadcrumbs.SelectColourFromPalette, true)
        entry.colour_index = i
        Breadcrumbs.ui.combobox:AddItem(entry)
    end
end

function Breadcrumbs.HideUI()
    Breadcrumbs.ui.interface = Breadcrumbs_Menu_Window or {}
    Breadcrumbs.ui.interface:SetHidden(true)
    Breadcrumbs.showUI = false
end

function Breadcrumbs.ShowUI()
    Breadcrumbs.ui.interface = Breadcrumbs_Menu_Window or {}
    Breadcrumbs.ui.interface:SetHidden(false)
    Breadcrumbs.showUI = true
end

function Breadcrumbs.SetLineColour(r, g, b)
    Breadcrumbs.sV.colour = {r, g, b}
    Breadcrumbs.ui.square:SetColor(r, g, b, 1)
end

function Breadcrumbs.ShowColourPicker()
    local colour = ZO_ColorDef:New(unpack(Breadcrumbs.sV.colour or {1, 1, 1}))
    COLOR_PICKER:Show(function(r,g,b) Breadcrumbs.SetLineColour(r, g, b) end, colour:UnpackRGB())
end

function Breadcrumbs.ToggleUIVisibility()
    if (Breadcrumbs.showUI) then
        Breadcrumbs.HideUI()
    else
        Breadcrumbs.ShowUI()
    end
end

local function OnAddOnLoaded(_, name)
    if name ~= Breadcrumbs.name then return end
    EVENT_MANAGER:UnregisterForEvent(Breadcrumbs.name, EVENT_ADD_ON_LOADED)

    EVENT_MANAGER:RegisterForEvent(Breadcrumbs.name, EVENT_ZONE_CHANGED, Breadcrumbs.LoadSavedZoneLines)
    EVENT_MANAGER:RegisterForEvent(Breadcrumbs.name, EVENT_PLAYER_ACTIVATED, Breadcrumbs.LoadSavedZoneLines)
    
    Breadcrumbs.sV = ZO_SavedVars:NewCharacterIdSettings("BreadcrumbsSavedVariables", Breadcrumbs.savedVariablesVersion, nil, Breadcrumbs.defaults)
    Breadcrumbs.CreateTopLevelControl()
    Breadcrumbs.InitialiseUI()
    Breadcrumbs.RegisterSettingsPanel()
    Breadcrumbs.ClearLinePool()
    Breadcrumbs.FuncLinePoolLocalise()
    Breadcrumbs.RefreshLines()
    Breadcrumbs.StartPolling()

    SLASH_COMMANDS["/breadcrumbs"] = Breadcrumbs.ToggleUIVisibility
end

EVENT_MANAGER:RegisterForEvent(Breadcrumbs.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)