Breadcrumbs = Breadcrumbs or {}
Breadcrumbs.name = "Breadcrumbs"
Breadcrumbs.version = "1.1"
Breadcrumbs.author = "TheMrPancake"

Breadcrumbs.savedVariablesVersion = 1 -- don't change
Breadcrumbs.defaults = {
    linePool = {},
    savedLines = {},
    loc1 = nil,
    loc2 = nil,
}

--------------------------
-- From OdySupportIcons --
--------------------------
Breadcrumbs.window = GetWindowManager()
function Breadcrumbs.CreateUI()
    -- create render space control
    Breadcrumbs.ctrl = Breadcrumbs.window:CreateControl( "BreadcrumbsControl", GuiRoot, CT_CONTROL )
    Breadcrumbs.ctrl:SetAnchorFill( GuiRoot )
    Breadcrumbs.ctrl:Create3DRenderSpace()
    Breadcrumbs.ctrl:SetHidden( true )

    -- create parent window for icons
	Breadcrumbs.win = Breadcrumbs.window:CreateTopLevelWindow( "BreadcrumbsWindow" )
    Breadcrumbs.win:SetClampedToScreen( true )
    Breadcrumbs.win:SetMouseEnabled( false )
    Breadcrumbs.win:SetMovable( false )
    Breadcrumbs.win:SetAnchorFill( GuiRoot )
	Breadcrumbs.win:SetDrawLayer( DL_BACKGROUND )
	Breadcrumbs.win:SetDrawTier( DT_LOW )
	Breadcrumbs.win:SetDrawLevel( 0 )

    -- create parent window scene fragment
	local frag = ZO_HUDFadeSceneFragment:New( Breadcrumbs.win )
	HUD_UI_SCENE:AddFragment( frag )
    HUD_SCENE:AddFragment( frag )
    LOOT_SCENE:AddFragment( frag )
end

local function OnAddOnLoaded(_, name)
    if name ~= Breadcrumbs.name then return end
    EVENT_MANAGER:UnregisterForEvent(Breadcrumbs.name, EVENT_ADD_ON_LOADED)
    
    Breadcrumbs.savedVariables = ZO_SavedVars:NewCharacterIdSettings("BreadcrumbsSavedVariables", Breadcrumbs.savedVariablesVersion, nil, Breadcrumbs.defaults)
    Breadcrumbs.CreateUI()
    Breadcrumbs.ClearLinePool()
    Breadcrumbs.RefreshLines() 
    Breadcrumbs.StartPolling()
end

EVENT_MANAGER:RegisterForEvent(Breadcrumbs.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)