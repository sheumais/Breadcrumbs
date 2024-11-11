Breadcrumbs = Breadcrumbs or {}
Breadcrumbs.name = "Breadcrumbs"
Breadcrumbs.version = "1.1"
Breadcrumbs.author = "TheMrPancake"
Breadcrumbs.title = "|cff7f40BREADCRUMBS|r"

Breadcrumbs.savedVariablesVersion = 1 -- don't change
Breadcrumbs.showUI = false
Breadcrumbs.ui = {}
Breadcrumbs.defaults = {
    linePool = {},
    savedLines = {},
    loc1 = nil,
    loc2 = nil,
    colour = {1,1,1},
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

function Breadcrumbs.InitialiseUI()
    Breadcrumbs.ui.interface = Breadcrumbs_Menu_Window or {}
    Breadcrumbs.ui.square = Breadcrumbs_Menu_Window_Coloured_Square or {}

    Breadcrumbs.ui.square:SetColor(unpack(Breadcrumbs.sV.colour or {1, 1, 1}))
    Breadcrumbs.showUI = false
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
    local color = ZO_ColorDef:New(unpack(Breadcrumbs.sV.colour or {1, 1, 1}))
    COLOR_PICKER:Show(function(r,g,b) Breadcrumbs.SetLineColour(r, g, b) end, color:UnpackRGB())
end

function Breadcrumbs.SetLineWhite()   Breadcrumbs.SetLineColour(1, 1, 1) end
function Breadcrumbs.SetLineMagenta() Breadcrumbs.SetLineColour(1, 0, 1) end
function Breadcrumbs.SetLineBlue()    Breadcrumbs.SetLineColour(0, 0, 1) end
function Breadcrumbs.SetLineGreen()   Breadcrumbs.SetLineColour(0, 1, 0) end
function Breadcrumbs.SetLineRed()     Breadcrumbs.SetLineColour(1, 0, 0) end

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
    --Breadcrumbs.RegisterSettingsPanel()
    Breadcrumbs.ClearLinePool()
    Breadcrumbs.RefreshLines()
    Breadcrumbs.StartPolling()

    SLASH_COMMANDS["/loc1"] = Breadcrumbs.Loc1
    SLASH_COMMANDS["/loc2"] = Breadcrumbs.Loc2
    SLASH_COMMANDS["/breadcrumbs"] = Breadcrumbs.ToggleUIVisibility
end

EVENT_MANAGER:RegisterForEvent(Breadcrumbs.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)