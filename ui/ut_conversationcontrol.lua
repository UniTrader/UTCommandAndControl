
-- section == gMain_map
-- param == { 0, 0, action, nextsection , choiceparam }
-- Supported Actions: return next_section next_subsection

-- ffi setup
local ffi = require("ffi")
local C = ffi.C
ffi.cdef[[
	typedef uint64_t UniverseID;
	typedef struct {
		const char* factionName;
		const char* factionIcon;
	} FactionDetails;
	typedef struct {
		UniverseID softtargetID;
		const char* softtargetName;
		const char* softtargetConnectionName;
	} SofttargetDetails;
	UniverseID AddHoloMap(const char* texturename, float x0, float x1, float y0, float y1);
	void ClearHighlightMapComponent(UniverseID holomapid);
	const char* GetBuildSourceSequence(UniverseID componentid);
	const char* GetComponentClass(UniverseID componentid);
	const char* GetComponentName(UniverseID componentid);
	UniverseID GetContextByClass(UniverseID componentid, const char* classname, bool includeself);
	FactionDetails GetFactionDetails(const char* factionid);
	UniverseID GetMapComponentBelowCamera(UniverseID holomapid);
	const char* GetMapShortName(UniverseID componentid);
	FactionDetails GetOwnerDetails(UniverseID componentid);
	UniverseID GetParentComponent(UniverseID componentid);
	UniverseID GetPickedMapComponent(UniverseID holomapid);
	SofttargetDetails GetSofttarget(void);
	bool IsComponentOperational(UniverseID componentid);
	bool IsInfoUnlockedForPlayer(UniverseID componentid, const char* infostring);
	bool IsSellOffer(UniverseID tradeofferdockid);
	void RemoveHoloMap(UniverseID holomapid);
	void SetHighlightMapComponent(UniverseID holomapid, UniverseID componentid, bool resetplayerpan);
	bool SetSofttarget(UniverseID componentid);
	void ShowUniverseMap(UniverseID holomapid, UniverseID componentid, bool resetplayerzoom, int overridezoom);
	void StartPanMap(UniverseID holomapid);
	void StartRotateMap(UniverseID holomapid);
	void StopPanMap(UniverseID holomapid);
	void StopRotateMap(UniverseID holomapid);
	void ZoomMap(UniverseID holomapid, float zoomstep);
]]

local utf8 = require("utf8")

local menu = {
	name = "UTConversationControl"
}

local function init()
	Menus = Menus or { }
	table.insert(Menus, menu)
	if Helper then
		Helper.registerMenu(menu)
	end
	menu.extendedcontainer = {}
	menu.extendedsequences = {}
	menu.holomap = 0
end

function menu.cleanup()
	UnregisterAddonBindings("ego_detailmonitor")

	menu.title = nil
	menu.component = 0
	menu.componenttype = nil
	menu.activatemap = nil
	menu.setrow = nil
	menu.settoprow = nil
	menu.setcol = nil
	menu.history = {}
	menu.lastchild = 0
	menu.lastsequence = nil
	menu.mode = nil
	menu.modeparam = {}
	menu.createChildListRunning = nil
	menu.lastUpdateHolomapTime = nil
	menu.activeguidancemissioncomponent = nil
	menu.noupdate = nil
	menu.playership = nil
	if menu.holomap ~= 0 then
		C.RemoveHoloMap(menu.holomap)
		menu.holomap = 0
	end
	menu.selectedcomponent = nil
	menu.subordinatedata = {}
	menu.buildtreedata = {}
	menu.commanderlist = {}
	menu.lastchildstationdata = {}
	menu.autopilottarget = nil
	menu.lastactivetable = nil
	menu.rendertargetWidth = nil
	menu.searchtext = nil
	menu.stationtradeoffers = {}
	menu.searchkeywords = {}
	menu.holomapcolor = {}
	menu.onplatform = nil
	menu.softtarget = nil

	menu.infotable = nil
	menu.selecttable = nil
	menu.rendertarget = nil

	UnregisterEvent("updateHolomap", menu.updateHolomap)
	UnregisterEvent("holomap_zoom_in", menu.autoZoomIn)
	UnregisterEvent("holomap_zoom_out", menu.autoZoomOut)

	-- Reset Helper
	Helper.standardFontSize = 14
	Helper.standardTextHeight = 24
	Helper.headerRow2FontSize = 14
	Helper.headerRow2Height = 24
	Helper.standardButtonWidth = 36
end

-- Menu member functions

function menu.onShowMenu()
	-- Override some Helper settings
	Helper.standardFontSize = 11
	Helper.standardTextHeight = 20
	Helper.headerRow2FontSize = 11
	Helper.headerRow2Height = 20
	Helper.standardButtonWidth = 30


	menu.action = menu.param[3]
	menu.nextsection = menu.param[4]
	menu.choiceparam = menu.param[5]
	
	if menu.action == 'return' then
		Helper.closeMenuAndReturn(menu, false)
	elseif menu.action == 'next_section' then
		Helper.closeMenuForSection(menu, false, menu.nextsection, menu.choiceparam)
	elseif menu.action == 'next_subsection' then
		Helper.closeMenuForSubSection(menu, keepvisible, menu.nextsection, menu.choiceparam)
	end
  
	menu.cleanup()
end

init()
