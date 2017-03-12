
-- section == gMain_map
-- param == { 0, 0, componenttype, component [, history] [, lastchild] [, mode, modeparam] }

-- modes: - "selectplayerobject", param: { returnsection, refcomponent, includeconstruction, disablezoom, , potentialsubordinate, disablestations, disablecapships, disablesmallships, canhavedrones, nosubordinate, noorder, haspilot, hascargocapacity, checkforbuildmodule, hasbuildingmodule, hascontrolentity, allowbuildingmodules }
--		  - "selectzone", param: { returnsection }
--		  - "selectsector", param: { returnsection }
--		  - "selectcluster", param: { returnsection }
--		  - "selectspace", param: { returnsection }
--		  - "selectspaceorstation", param: { returnsection }
--		  - "selectobject", param: { returnsection }
--		  - "selectposition", param: { returnsection }

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
	typedef struct {
		float x;
		float y;
		float z;
		float yaw;
		float pitch;
		float roll;
	} UIPosRot;
	void AbortPlayerPrimaryShipJump(void);
	UniverseID AddHoloMap(const char* texturename, float x0, float x1, float y0, float y1);
	void ClearHighlightMapComponent(UniverseID holomapid);
	void EnableMapPicking(UniverseID holomapid);
	const char* GetBuildSourceSequence(UniverseID componentid);
	const char* GetComponentClass(UniverseID componentid);
	const char* GetComponentName(UniverseID componentid);
	UniverseID GetContextByClass(UniverseID componentid, const char* classname, bool includeself);
	FactionDetails GetFactionDetails(const char* factionid);
	UniverseID GetMapComponentBelowCamera(UniverseID holomapid);
	bool GetMapPositionOnEcliptic(UniverseID holomapid, UIPosRot* position, bool showposition);
	const char* GetMapShortName(UniverseID componentid);
	FactionDetails GetOwnerDetails(UniverseID componentid);
	UniverseID GetParentComponent(UniverseID componentid);
	UniverseID GetPickedMapComponent(UniverseID holomapid);
	SofttargetDetails GetSofttarget(void);
	UniverseID GetZoneAt(UniverseID sectorid, UIPosRot* uioffset);
	bool HasPlayerJumpKickstarter(void);
	bool InitPlayerPrimaryShipJump(UniverseID objectid);
	bool IsComponentOperational(UniverseID componentid);
	bool IsInfoUnlockedForPlayer(UniverseID componentid, const char* infostring);
	bool IsSellOffer(UniverseID tradeofferdockid);
	void RemoveHoloMap2(void);
	void SetHighlightMapComponent(UniverseID holomapid, UniverseID componentid, bool resetplayerpan);
	void SetPlayerCameraCockpitView(bool force);
	void SetPlayerCameraTargetView(UniverseID targetid, bool force);
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
	name = "UTMapMenu",
	grey = { r = 128, g = 128, b = 128, a = 100 },
	red = { r = 255, g = 0, b = 0, a = 100 },
	green = { r = 0, g = 255, b = 0, a = 100 },
	transparent = { r = 0, g = 0, b = 0, a = 0 },
	autopilotmarker = ">> ",
	softtargetmarker_r = " <",
	softtargetmarker_l = "> "
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
		C.RemoveHoloMap2()
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
	menu.offset = nil
	menu.jumpdrive = {}

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

-- button scripts
function menu.buttonDetails()
	C.RemoveHoloMap2()
	menu.holomap = 0
	table.remove(menu.history)
	if menu.mode == "selectplayerobject" then
		Helper.closeMenuForSection(menu, false, menu.modeparam[1], { 0, 0, menu.selectedcomponent })
		menu.cleanup()
	elseif menu.mode == "selectobject" then
		Helper.closeMenuForSection(menu, false, menu.modeparam[1], { 0, 0, menu.selectedcomponent })
		menu.cleanup()
	elseif menu.mode == "selectzone" then
		Helper.closeMenuForSection(menu, false, menu.modeparam[1], { 0, 0, menu.selectedcomponent })
		menu.cleanup()
	elseif menu.mode == "selectsector" then
		Helper.closeMenuForSection(menu, false, menu.modeparam[1], { 0, 0, menu.selectedcomponent })
		menu.cleanup()
	elseif menu.mode == "selectcluster" then
		Helper.closeMenuForSection(menu, false, menu.modeparam[1], { 0, 0, menu.selectedcomponent })
		menu.cleanup()
	else
		Helper.closeMenuForSection(menu, false, "gMain_object_closeup", { 0, 0, menu.selectedcomponent, menu.history })
		menu.cleanup()
	end
end

function menu.buttonNavigation(type, component, overridezoom)
	menu.offset = nil
	if type == "back" then
		local numhistory = #menu.history
		if numhistory > 1 and C.GetParentComponent(menu.component) == menu.history[numhistory - 1][1] then
			menu.lastchild = menu.component
			menu.component = menu.history[numhistory - 1][1]
			menu.componenttype = menu.history[numhistory - 1][2]
			table.remove(menu.history)
			menu.createChildList()
			if menu.holomap ~= 0 then
				C.ClearHighlightMapComponent(menu.holomap)
				C.ShowUniverseMap(menu.holomap, menu.component, true, overridezoom)
			end
		else
			if menu.componenttype == "galaxy" then
				-- Do nothing
			elseif menu.componenttype == "cluster" then
				menu.lastchild = menu.component
				menu.component = C.GetContextByClass(menu.component, "galaxy", true)
				menu.componenttype = "galaxy"
				table.insert(menu.history, { ConvertStringTo64Bit(tostring(menu.component)), menu.componenttype })
				menu.createChildList()
				if menu.holomap ~= 0 then
					C.ClearHighlightMapComponent(menu.holomap)
					C.ShowUniverseMap(menu.holomap, menu.component, true, overridezoom)
				end
			elseif menu.componenttype == "sector" then
				menu.lastchild = menu.component
				menu.component = C.GetContextByClass(menu.component, "cluster", true)
				menu.componenttype = "cluster"
				table.insert(menu.history, { ConvertStringTo64Bit(tostring(menu.component)), menu.componenttype })
				menu.createChildList()
				if menu.holomap ~= 0 then
					C.ClearHighlightMapComponent(menu.holomap)
					C.ShowUniverseMap(menu.holomap, menu.component, true, overridezoom)
				end
			elseif menu.componenttype == "zone" then
				menu.lastchild = menu.component
				menu.component = C.GetContextByClass(menu.component, "sector", true)
				menu.componenttype = "sector"
				table.insert(menu.history, { ConvertStringTo64Bit(tostring(menu.component)), menu.componenttype })
				menu.createChildList()
				if menu.holomap ~= 0 then
					C.ClearHighlightMapComponent(menu.holomap)
					C.ShowUniverseMap(menu.holomap, menu.component, true, overridezoom)
				end
			elseif menu.componenttype == "container" then
				menu.lastchild = menu.component
				menu.component = C.GetContextByClass(menu.component, "zone", true)
				menu.componenttype = "zone"
				table.insert(menu.history, { ConvertStringTo64Bit(tostring(menu.component)), menu.componenttype })
				menu.createChildList()
				if menu.holomap ~= 0 then
					C.ClearHighlightMapComponent(menu.holomap)
					C.ShowUniverseMap(menu.holomap, menu.component, true, overridezoom)
				end
			end
		end
	else
		local numhistory = #menu.history
		if numhistory > 1 and component == menu.history[numhistory - 1][1] then
			menu.component = menu.history[numhistory - 1][1]
			menu.componenttype = menu.history[numhistory - 1][2]
			if numhistory > 2 then
				if C.GetParentComponent(menu.history[numhistory - 2][1]) == menu.component then
					menu.lastchild = menu.history[numhistory - 2][1]
				end
			end
			table.remove(menu.history)
			menu.createChildList()
			if menu.holomap ~= 0 then
				C.ClearHighlightMapComponent(menu.holomap)
				C.ShowUniverseMap(menu.holomap, menu.component, true, overridezoom)
			end
		else
			if menu.componenttype == "galaxy" then
				if menu.mode == "selectcluster" then
					Helper.closeMenuForSection(menu, false, menu.modeparam[1], { 0, 0, ffi.new("UniverseID", ConvertStringTo64Bit(tostring(component))) })
					menu.cleanup()
				else
					menu.component = component
					menu.componenttype = "cluster"
					table.insert(menu.history, { ConvertStringTo64Bit(tostring(menu.component)), menu.componenttype })
					menu.createChildList()
					if menu.holomap ~= 0 then
						C.ClearHighlightMapComponent(menu.holomap)
						C.ShowUniverseMap(menu.holomap, menu.component, true, overridezoom)
					end
				end
			elseif menu.componenttype == "cluster" then
				if menu.mode == "selectsector" then
					Helper.closeMenuForSection(menu, false, menu.modeparam[1], { 0, 0, ffi.new("UniverseID", ConvertStringTo64Bit(tostring(component))) })
					menu.cleanup()
				else
					menu.component = component
					menu.componenttype = "sector"
					table.insert(menu.history, { ConvertStringTo64Bit(tostring(menu.component)), menu.componenttype })
					menu.createChildList()
					if menu.holomap ~= 0 then
					C.ClearHighlightMapComponent(menu.holomap)
						C.ShowUniverseMap(menu.holomap, menu.component, true, overridezoom)
					end
				end
			elseif menu.componenttype == "sector" then
				if menu.mode == "selectzone" then
					Helper.closeMenuForSection(menu, false, menu.modeparam[1], { 0, 0, ffi.new("UniverseID", ConvertStringTo64Bit(tostring(component))) })
					menu.cleanup()
				else
					menu.component = component
					menu.componenttype = "zone"
					table.insert(menu.history, { ConvertStringTo64Bit(tostring(menu.component)), menu.componenttype })
					menu.createChildList()
					if menu.holomap ~= 0 then
						C.ClearHighlightMapComponent(menu.holomap)
						C.ShowUniverseMap(menu.holomap, menu.component, true, overridezoom)
					end
				end
			elseif menu.componenttype == "zone" then
				if type == "station" then
					menu.component = component
					menu.componenttype = "container"
					table.insert(menu.history, { ConvertStringTo64Bit(tostring(menu.component)), menu.componenttype })
				elseif type == "ship" then
					if menu.isExtended(component) then
						for i, entry in ipairs(menu.extendedcontainer) do
							if entry == component then
								table.remove(menu.extendedcontainer, i)
							end
						end
					else
						table.insert(menu.extendedcontainer, component)
					end
					menu.settoprow = GetTopRow(menu.selecttable)
					menu.lastchild = component
				end
				menu.createChildList()
				if menu.holomap ~= 0 then
					C.ClearHighlightMapComponent(menu.holomap)
					C.ShowUniverseMap(menu.holomap, menu.component, true, overridezoom)
				end
			elseif menu.componenttype == "container" then
				C.RemoveHoloMap2()
				menu.holomap = 0
				table.remove(menu.history)
				Helper.closeMenuForSubSection(menu, false, "gMain_object_closeup", { 0, 0, ConvertStringTo64Bit(tostring(component)), menu.history })
				menu.cleanup()
			end
		end
	end
end

function menu.extendSequence(station, seqidx, notoggle)
	local found = false
	for i, entry in ipairs(menu.extendedsequences) do
		if IsSameComponent(entry.id, station) then
			found = true
			if (not notoggle) and entry.sequences[seqidx] then
				entry.sequences[seqidx] = nil
			else
				entry.sequences[seqidx] = true
			end
		end
	end
	if not found then
		table.insert(menu.extendedsequences, {id = station, sequences = { [seqidx] = true } })
	end
end

function menu.buttonExtendSequence(station, seqidx)
	menu.extendSequence(station, seqidx)

	menu.settoprow = GetTopRow(menu.selecttable)
	menu.lastchild = ConvertIDTo64Bit(station) or 0
	menu.lastsequence = seqidx
	menu.createChildList()
	if menu.holomap ~= 0 then
		C.ShowUniverseMap(menu.holomap, menu.component, true, 0)
	end
end

function menu.buttonComm()
	if menu.mode == "selectposition" then
		if menu.offset or (menu.componenttype == "zone") then
			local zone
			if menu.componenttype == "sector" then
				zone = C.GetZoneAt(menu.component, menu.offset)
			else 
				zone = menu.component
			end
			Helper.closeMenuForSection(menu, false, menu.modeparam[1], { 0, 0, ConvertStringToLuaID(tostring(zone)), menu.offset and { menu.offset.x, menu.offset.y, menu.offset.z } or nil })
		else
			Helper.closeMenuForSection(menu, false, menu.modeparam[1], { 0, 0, menu.selectedcomponent })
		end
		menu.cleanup()
	else
		C.RemoveHoloMap2()
		menu.holomap = 0
		local entities = Helper.getSuitableControlEntities(menu.selectedcomponent, true)
		if #entities == 1 then
			Helper.closeMenuForSubConversation(menu, false, "default", entities[1], menu.selectedcomponent, (not Helper.useFullscreenDetailmonitor()) and "facecopilot" or nil)
		else
			Helper.closeMenuForSubSection(menu, false, "gMain_propertyResult", menu.selectedcomponent)
		end
		menu.cleanup()
	end
end

function menu.buttonNewOrder()
	C.RemoveHoloMap2()
	menu.holomap = 0
	Helper.closeMenuForSubSection(menu, false, "gMain_charNewOrder", {0, 0, GetComponentData(menu.selectedcomponent, "pilot")})
	menu.cleanup()
end

function menu.buttonPlotCourse()
	if menu.mode == "selectposition" then
		if menu.offset or (menu.componenttype == "zone") then
			local zone
			if menu.componenttype == "sector" then
				zone = C.GetZoneAt(menu.component, menu.offset)
			else 
				zone = menu.component
			end
			Helper.closeMenuForSection(menu, false, menu.modeparam[1], { 0, 0, ConvertStringToLuaID(tostring(zone)), menu.offset and { menu.offset.x, menu.offset.y, menu.offset.z } or nil })
		else
			Helper.closeMenuForSection(menu, false, menu.modeparam[1], { 0, 0, menu.selectedcomponent })
		end
		menu.cleanup()
	else
		if IsSameComponent(GetActiveGuidanceMissionComponent(), menu.selectedcomponent) then
			Helper.closeMenuForSection(menu, false, "gMainNav_abort_plotcourse")
		else
			Helper.closeMenuForSection(menu, false, "gMainNav_plotcourse", {menu.selectedcomponent, false})
		end
		menu.cleanup()
	end
end

function menu.buttonSelectspaceorstation()
	C.RemoveHoloMap(menu.holomap)
	menu.holomap = 0
	table.remove(menu.history)
	Helper.closeMenuForSection(menu, false, menu.modeparam[1], { 0, 0, menu.selectedcomponent })
	menu.cleanup()
end

function menu.buttonClearEditbox()
	Helper.cancelEditBoxInput(menu.editboxtable, 1, 1)

	menu.searchtext = ""

	Helper.removeButtonScripts(menu, menu.buttontable, 2, 7)
	SetCellContent(menu.buttontable, Helper.createButton(Helper.createButtonText(IsSameComponent(GetActiveGuidanceMissionComponent(), menu.selectedcomponent) and ReadText(1001, 1110) or ReadText(1001, 1109), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, (not menu.mode) and (not IsSameComponent(menu.selectedcomponent, GetComponentData(menu.playership, "zoneid"))), 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_Y", true)), 2, 7)
	Helper.setButtonScript(menu, nil, menu.buttontable, 2, 7, menu.buttonPlotCourse)

	local rowdata = Helper.currentTableRowData
	if rowdata and rowdata ~= "back" then
		menu.lastchild = ConvertIDTo64Bit(rowdata[2]) or 0
		menu.lastsequence = rowdata[3]
	else
		menu.lastchild = 0
	end
	menu.settoprow = GetTopRow(menu.selecttable)
	menu.setrow = Helper.currentTableRow[menu.selecttable]
	menu.setcol = Helper.currentTableCol[menu.selecttable]
	menu.setbuttoncol = Helper.currentTableCol[menu.buttontable]
	if not menu.createChildListRunning then
		menu.createChildList()
	end
end

function menu.buttonJumpDrive()
	if GetComponentData(menu.playership, "isjumpdrivecharging") then
		C.AbortPlayerPrimaryShipJump()
	else
		C.InitPlayerPrimaryShipJump(ConvertIDTo64Bit(menu.selectedcomponent))
	end
	menu.updateJumpButton()
end

function menu.buttonStats()
	Helper.closeMenuForSubSection(menu, false, "gMain_economystats", { 0, 0, ConvertStringTo64Bit(tostring(menu.component)), menu.history })
	menu.cleanup()
end

function menu.editboxUpdateText(_, text, textchanged)
	if textchanged then
		menu.searchtext = text
	end
	menu.noupdate = false

	local rowdata = Helper.currentTableRowData
	if rowdata and rowdata ~= "back" then
		menu.lastchild = ConvertIDTo64Bit(rowdata[2]) or 0
		menu.lastsequence = rowdata[3]
	else
		menu.lastchild = 0
	end
	menu.settoprow = GetTopRow(menu.selecttable)
	menu.setrow = Helper.currentTableRow[menu.selecttable]
	menu.setcol = Helper.currentTableCol[menu.selecttable]
	menu.setbuttoncol = Helper.currentTableCol[menu.buttontable]
	if not menu.createChildListRunning then
		menu.createChildList()
	end
end

function menu.hotkey(action)
	local rowdata = Helper.currentTableRowData
	if rowdata ~= "back" then
		if action == "INPUT_ACTION_ADDON_DETAILMONITOR_G" then
			if rowdata and rowdata ~= "back" then
				if menu.componenttype == "galaxy" then
					local sectors = GetSectors(rowdata[2])
					if sectors[1] then
						local zones = GetZones(sectors[1])
						MovePlayerToZone(zones[1])
					end
				elseif menu.componenttype == "cluster" then
					local zones = GetZones(rowdata[2])
					MovePlayerToZone(zones[1])
				elseif menu.componenttype == "sector" then
					MovePlayerToZone(rowdata[2])
				elseif menu.componenttype == "zone" then
					MovePlayerToZone(ConvertStringTo64Bit(tostring(menu.component)))
				end
			end
		elseif action == "INPUT_ACTION_ADDON_DETAILMONITOR_C" then
			if rowdata and (rowdata[1] == "station" or rowdata[1] == "ship") and (not menu.mode) and IsComponentOperational(menu.selectedcomponent) and (not IsSameComponent(menu.selectedcomponent, menu.playership)) and GetComponentData(menu.selectedcomponent, "caninitiatecomm") then
				menu.buttonComm()
			end
		elseif action == "INPUT_ACTION_ADDON_DETAILMONITOR_I" then
			if rowdata and (rowdata[1] == "station" or rowdata[1] == "ship") and (not menu.mode) and IsInfoUnlockedForPlayer(menu.selectedcomponent, "name") and CanViewLiveData(menu.selectedcomponent) then
				menu.buttonDetails()
			end
		elseif action == "INPUT_ACTION_ADDON_DETAILMONITOR_T" then
			if rowdata and ((rowdata[1] == "ship") or (rowdata[1] == "gate")) then
				menu.targetObject(menu.selectedcomponent)
			end
		elseif action == "INPUT_ACTION_ADDON_DETAILMONITOR_A_SHIFT" then
			if menu.componenttype == "zone" then
				if IsSameComponent(menu.autopilottarget, menu.selectedcomponent) then
					StopAutoPilot()
				else
					StartAutoPilot(menu.selectedcomponent)
				end

				menu.lastchild = menu.selectedcomponent
				menu.settoprow = GetTopRow(menu.selecttable)
				menu.setrow = Helper.currentDefaultTableRow
				if not menu.createChildListRunning then
					menu.createChildList(false)
				end
			end
		elseif action == "INPUT_ACTION_ADDON_DETAILMONITOR_F1" then
			C.SetPlayerCameraCockpitView(true)
		elseif action == "INPUT_ACTION_ADDON_DETAILMONITOR_F3" then
			if rowdata and IsFullscreenWidgetSystem() and (not IsFirstPerson()) then
				C.SetPlayerCameraTargetView(ConvertIDTo64Bit(menu.selectedcomponent), true)
			end
		elseif action == "INPUT_ACTION_ADDON_DETAILMONITOR_COMMA" then
			if menu.componenttype == "zone" then
				menu.buttonNavigation("back", nil, 0)
			end
		elseif action == "INPUT_ACTION_ADDON_DETAILMONITOR_RIGHT" or action == "INPUT_ACTION_ADDON_DETAILMONITOR_LEFT" then
			if (menu.lastactivetable == menu.selecttable) and (not menu.createChildListRunning) then
				if menu.componenttype == "zone" then
					if rowdata then
						if (rowdata[1] == "station") or rowdata[1] == "ship" then
							local isextended = menu.isExtended(ConvertIDTo64Bit(rowdata[2]))
							if ((action == "INPUT_ACTION_ADDON_DETAILMONITOR_RIGHT") and (not isextended)) or ((action == "INPUT_ACTION_ADDON_DETAILMONITOR_LEFT") and isextended) then
								if rowdata[1] == "station" then
									if (not menu.mode) or (menu.mode == "selectobject") then
										menu.buttonNavigation("ship", ConvertIDTo64Bit(rowdata[2]), 0)
									end
								elseif rowdata[1] == "ship" then
									local idx = menu.findSubordinateDataIdx(rowdata[2])
									if idx then
										local subordinates = menu.subordinatedata[idx].table
										if #subordinates > 0 then
											menu.buttonNavigation("ship", ConvertIDTo64Bit(rowdata[2]), 0)
										end
									end
								end
							elseif action == "INPUT_ACTION_ADDON_DETAILMONITOR_LEFT" then
								if rowdata[1] == "ship" then
									local commander = GetCommander(rowdata[2])
									if commander then
										menu.settoprow = GetTopRow(menu.selecttable)
										menu.lastchild = ConvertIDTo64Bit(commander) or 0
										menu.createChildList()
										if menu.holomap ~= 0 then
											C.ClearHighlightMapComponent(menu.holomap)
											C.ShowUniverseMap(menu.holomap, menu.component, true, 0)
										end
									end
								end
							end
						elseif rowdata[1] == "sequence" then
							local isextended = menu.isSequenceExtended(rowdata[2], rowdata[3])
							if ((action == "INPUT_ACTION_ADDON_DETAILMONITOR_RIGHT") and (not isextended)) or ((action == "INPUT_ACTION_ADDON_DETAILMONITOR_LEFT") and isextended) then
								menu.extendSequence(rowdata[2], rowdata[3])
								menu.settoprow = GetTopRow(menu.selecttable)
								menu.lastchild = ConvertIDTo64Bit(rowdata[2]) or 0
								menu.lastsequence = rowdata[3]
								menu.createChildList()
								if menu.holomap ~= 0 then
									C.ShowUniverseMap(menu.holomap, menu.component, true, 0)
								end
							elseif action == "INPUT_ACTION_ADDON_DETAILMONITOR_LEFT" then
								menu.settoprow = GetTopRow(menu.selecttable)
								menu.lastchild = ConvertIDTo64Bit(rowdata[2]) or 0
								menu.createChildList()
								if menu.holomap ~= 0 then
									C.ClearHighlightMapComponent(menu.holomap)
									C.ShowUniverseMap(menu.holomap, menu.component, true, 0)
								end
							end
						elseif rowdata[1] == "module" then
							if action == "INPUT_ACTION_ADDON_DETAILMONITOR_LEFT" then
								menu.settoprow = GetTopRow(menu.selecttable)
								menu.lastchild = ConvertIDTo64Bit(GetContextByClass(rowdata[2], "station")) or 0
								menu.lastsequence = rowdata[3]
								menu.createChildList()
								if menu.holomap ~= 0 then
									C.ShowUniverseMap(menu.holomap, menu.component, true, 0)
								end
							end
						end
					end
				end
			end
		end
	end
end

function menu.targetObject(object)
	if menu.mode or IsSameComponent(object, menu.playership) then
		return -- no targeting of playership or when menu.mode is set
	end
	
	menu.onplatform = menu.onplatform or IsComponentClass(GetPlayerRoom(), "dockingbay")
	if menu.onplatform then
		return -- no targeting while on platforms
	end
	
	if C.SetSofttarget(ConvertIDTo64Bit(object)) then
		menu.lastchild = object
		menu.settoprow = GetTopRow(menu.selecttable)
		menu.setrow = Helper.currentDefaultTableRow
		if not menu.createChildListRunning then
			menu.createChildList(false)
		end

		return true
	end

	return false
end

function menu.onShowMenu()
	-- Override some Helper settings
	Helper.standardFontSize = 11
	Helper.standardTextHeight = 20
	Helper.headerRow2FontSize = 11
	Helper.headerRow2Height = 20
	Helper.standardButtonWidth = 30

	if menu.param2 == nil or menu.param2[1] then
		menu.component = ConvertIDTo64Bit(menu.param[4]) or 0
		menu.componenttype = menu.param[3]
		menu.history = menu.param[5] or {}
		for _, entry in ipairs(menu.history) do
			entry[1] = ConvertIDTo64Bit(entry[1])
		end
		table.insert(menu.history, { ConvertStringTo64Bit(tostring(menu.component)), menu.componenttype })
		menu.lastchild = ConvertIDTo64Bit(menu.param[6]) or 0
		menu.mode = menu.param[7]
		menu.modeparam = menu.param[8] or {}
		if menu.param2 and menu.lastchild == 0 then
			menu.lastchild = ConvertIDTo64Bit(menu.param2[2]) or 0
		end
	else
		menu.component = ConvertIDTo64Bit(menu.param2[2][4]) or 0
		menu.componenttype = menu.param2[2][3]
		menu.history = menu.param2[2][5] or {}
		for _, entry in ipairs(menu.history) do
			entry[1] = ConvertIDTo64Bit(entry[1])
		end
		table.insert(menu.history, { ConvertStringTo64Bit(tostring(menu.component)), menu.componenttype })
		menu.lastchild = ConvertIDTo64Bit(menu.param2[2][6]) or 0
		menu.mode = menu.param2[2][7]
		menu.modeparam = menu.param2[2][8] or {}
	end

	RegisterAddonBindings("ego_detailmonitor")

	menu.activeguidancemissioncomponent = GetActiveGuidanceMissionComponent()
	menu.playership = GetPlayerPrimaryShipID()
	menu.subordinatedata = {}
	menu.buildtreedata = {}
	menu.lastchildstationdata = {}
	menu.searchtext = ""
	menu.offset = nil

	if ffi.string(C.GetComponentClass(menu.lastchild)) == "entity" then
		menu.lastchild = C.GetContextByClass(menu.lastchild, "container", false)
	end

	if menu.lastchild ~= 0 then
		local stationcontext = C.GetContextByClass(menu.lastchild, "station", false)
		if stationcontext ~= 0 and (stationcontext ~= menu.lastchild) then
			local sequence = ffi.string(C.GetBuildSourceSequence(menu.lastchild))
			menu.lastchildstationdata = { station = stationcontext, sequence = (sequence == "") and "a" or sequence }
		end
	end

	if menu.componenttype == "zone" and ffi.string(C.GetComponentClass(menu.lastchild)) == "controllable" then
		menu.commanderlist = (menu.lastchild ~= 0) and GetAllCommanders(ConvertStringTo64Bit(tostring(menu.lastchild))) or {}
	else
		menu.commanderlist = {}
	end

	local trades = GetTradeList()
	menu.stationtradeoffers = {}
	for _, trade in ipairs(trades) do
		if menu.stationtradeoffers[tostring(trade.station)] then
			table.insert(menu.stationtradeoffers[tostring(trade.station)], trade)
		else
			menu.stationtradeoffers[tostring(trade.station)] = { trade }
		end
	end
	
	local keywordpage = 1014
	local keywordids = { 101, 201, 301, 401, 501 }
	menu.searchkeywords = {}
	for _, id in ipairs(keywordids) do
		menu.searchkeywords[id] = utf8.lower(ReadText(keywordpage, id))
		menu.searchkeywords[id + 1] = utf8.lower(ReadText(keywordpage, id + 1))
	end

	local productioncolor, buildcolor, storagecolor, radarcolor, dronedockcolor, efficiencycolor, defencecolor, playercolor, friendcolor, enemycolor, missioncolor = GetHoloMapColors()
	menu.holomapcolor = { productioncolor = productioncolor, buildcolor = buildcolor, storagecolor = storagecolor, radarcolor = radarcolor, dronedockcolor = dronedockcolor, efficiencycolor = efficiencycolor, defencecolor = defencecolor, playercolor = playercolor, friendcolor = friendcolor, enemycolor = enemycolor, missioncolor = missioncolor }

	menu.createChildList(true)

	menu.activatemap = true
	RegisterEvent("updateHolomap", menu.updateHolomap)
	RegisterEvent("holomap_zoom_in", menu.autoZoomIn)
	RegisterEvent("holomap_zoom_out", menu.autoZoomOut)
end

function menu.updateHolomap()
	if not menu.lastUpdateHolomapTime then
		menu.lastUpdateHolomapTime = 0
	end
	local curTime = GetCurRealTime()
	if (menu.componenttype == "zone" or menu.componenttype == "sector") and menu.lastUpdateHolomapTime < curTime - 5 and not menu.noupdate then
		menu.lastUpdateHolomapTime = curTime
		local rowdata = Helper.currentTableRowData
		if rowdata and rowdata ~= "back" then
			menu.lastchild = ConvertIDTo64Bit(rowdata[2]) or 0
			menu.lastsequence = rowdata[3]
		else
			menu.lastchild = 0
		end
		menu.taborderoverride = menu.lastactivetable == menu.buttontable
		menu.settoprow = GetTopRow(menu.selecttable)
		menu.setrow = Helper.currentTableRow[menu.selecttable]
		menu.setcol = Helper.currentTableCol[menu.selecttable]
		menu.setbuttoncol = Helper.currentTableCol[menu.buttontable]
		if not menu.createChildListRunning then
			menu.createChildList()
		end
	end
end

function menu.createChildList(isfirsttime)
	menu.createChildListRunning = true;

	-- remove old data
	Helper.removeAllKeyBindings(menu)
	Helper.removeAllButtonScripts(menu)
	Helper.currentTableRow = {}
	Helper.currentTableRowData = nil
	menu.rowDataMap = {}
	menu.subordinatedata = {}
	menu.buildtreedata = {}

	-- prepare map information depending on map type
	local yields, children, gates, jumpbeacons, ships, stations, shortname
	if menu.componenttype == "galaxy" then
		menu.title = ReadText(20001, 901)
		yields = {}
		children = GetClusters(true)
		for i = #children, 1, -1 do
			if (menu.searchtext ~= "") and (not menu.filterComponentByText(children[i], menu.searchtext, true)) then
				table.remove(children, i)
			end
		end
		gates = {}
		jumpbeacons = {}
		ships = {}
		stations = {}
		entries = {}
		shortname = ""
		menu.parenttitle = " "
		menu.mot_parent = nil
		menu.childtitle = ReadText(20001, 101)
		menu.mot_child = ReadText(1026, 3212)
		Helper.setKeyBinding(menu, menu.hotkey)
	elseif menu.componenttype == "cluster" then
		menu.title = ReadText(20001, 101) .. ReadText(1001, 120) .. " " .. ffi.string(C.GetComponentName(menu.component))
		yields = {}
		children = GetSectors(ConvertStringTo64Bit(tostring(menu.component)))
		for i = #children, 1, -1 do
			if (menu.searchtext ~= "") and (not menu.filterComponentByText(children[i], menu.searchtext, true)) then
				table.remove(children, i)
			end
		end
		gates = {}
		jumpbeacons = {}
		ships = {}
		stations = {}
		entries = {}
		shortname = ffi.string(C.GetMapShortName(menu.component))
		menu.parenttitle = ReadText(20001, 901)
		menu.mot_parent = ReadText(1026, 3210)
		menu.childtitle = ReadText(20001, 201)
		menu.mot_child = ReadText(1026, 3211)
		Helper.setKeyBinding(menu, menu.hotkey)
	elseif menu.componenttype == "sector" then
		menu.title = ReadText(20001, 201) .. ReadText(1001, 120) .. " " .. ffi.string(C.GetComponentName(menu.component))
		yields = {}
		children = GetZones(ConvertStringTo64Bit(tostring(menu.component)))
		for i = #children, 1, -1 do
			if (menu.searchtext ~= "") and (not menu.filterComponentByText(children[i], menu.searchtext, true)) then
				table.remove(children, i)
			end
		end
		gates = {}
		jumpbeacons = {}
		ships = {}
		stations = {}
		entries = {}
		shortname = ffi.string(C.GetMapShortName(C.GetContextByClass(menu.component, "cluster", false))) .. "." .. ffi.string(C.GetMapShortName(menu.component))
		menu.parenttitle = ReadText(20001, 101)
		menu.mot_parent = ReadText(1026, 3207)
		menu.childtitle = ReadText(20001, 301)
		menu.mot_child = ReadText(1026, 3209)
		Helper.setKeyBinding(menu, menu.hotkey)
	elseif menu.componenttype == "zone" then
		menu.title = ReadText(20001, 301) .. ReadText(1001, 120) .. " " .. ffi.string(C.GetComponentName(menu.component))
		yields = GetZoneYield(ConvertStringTo64Bit(tostring(menu.component)))
		children = {}
		gates = GetGates(ConvertStringTo64Bit(tostring(menu.component)), true)
		for i = #gates, 1, -1 do
			if (menu.searchtext ~= "") and (not menu.filterComponentByText(gates[i], menu.searchtext, true)) then
				table.remove(gates, i)
			end
		end
		jumpbeacons = GetJumpBeacons(ConvertStringTo64Bit(tostring(menu.component)))
		for i = #jumpbeacons, 1, -1 do
			if (menu.searchtext ~= "") and (not menu.filterComponentByText(jumpbeacons[i], menu.searchtext, true)) then
				table.remove(jumpbeacons, i)
			end
		end
		ships = GetContainedShips(ConvertStringTo64Bit(tostring(menu.component)), true)
		for i = #ships, 1, -1 do
			if IsComponentClass(ships[i], "ship_xs") then
				table.remove(ships, i)
			else
				local commander = GetCommander(ships[i])
				if commander and menu.component == ConvertIDTo64Bit(GetComponentData(commander, "zoneid")) then
					table.remove(ships, i)
				elseif (menu.searchtext ~= "") and (not menu.filterComponentByText(ships[i], menu.searchtext, true)) then
					table.remove(ships, i)
				end
			end
		end
		stations = GetContainedStations(ConvertStringTo64Bit(tostring(menu.component)), true, menu.modeparam[3] and (menu.modeparam[3] ~= 0))
		for i = #stations, 1, -1 do
			local isplayer = GetComponentData(stations[i], "isplayerowned")
			local entries = {}
			menu.createBuildtreeData(ConvertIDTo64Bit(stations[i]), entries, isplayer)
			table.insert(menu.buildtreedata, {id = stations[i], table = entries})

			local commander = IsComponentClass(stations[i], "controllable") and GetCommander(stations[i]) or nil
			if commander and menu.component == ConvertIDTo64Bit(GetComponentData(commander, "zoneid")) then
				table.remove(stations, i)
			elseif (menu.searchtext ~= "") and (not menu.filterComponentByText(stations[i], menu.searchtext, true)) then
				table.remove(stations, i)
			end
		end
		entries = {}
		shortname = ""
		menu.parenttitle = ReadText(20001, 201)
		menu.mot_parent = ReadText(1026, 3204)
		menu.childtitle = " "
		menu.mot_child = nil
		Helper.setKeyBinding(menu, menu.hotkey)
	elseif menu.componenttype == "container" then
		menu.title = C.IsInfoUnlockedForPlayer(menu.component, "name") and ffi.string(C.GetComponentName(menu.component)) or ReadText(1001, 3210)
		yields = {}
		children = {}
		gates = {}
		jumpbeacons = {}
		ships = {}
		stations = {}
		entries = {}
		shortname = ""
		menu.parenttitle = ReadText(20001, 301)
		menu.mot_parent = nil
		menu.childtitle = " "
		menu.mot_child = nil
	end

	local setup = Helper.createTableSetup(menu)

	menu.autopilottarget = GetAutoPilotTarget()
	menu.softtarget = C.GetSofttarget().softtargetID

	local displayedyields, displayedchildren, displayedstations, displayedships
	local numhistory = #menu.history
	local environmentobject = GetPlayerPrimaryShipID() --GetPlayerEnvironmentObject()
	local playerzone = GetComponentData(menu.playership, "zoneid")
	local emptyFontStringSmall = Helper.createFontString("", false, Helper.standardHalignment, Helper.standardColor.r, Helper.standardColor.g, Helper.standardColor.b, Helper.standardColor.a, Helper.standardFont, 6, false, Helper.headerRow1Offsetx, Helper.headerRow1Offsety, 6)
	local lines = 2

	-- title
	if menu.componenttype ~= "component" then
		local statsactive = PlayerPrimaryShipHasContents("economymk1")
		setup:addSimpleRow({
			Helper.createButton(nil, Helper.createButtonIcon("menu_stats", nil, 255, 255, 255, 100), false, (not menu.mode) and statsactive, 0, 0, 0, Helper.headerRow1Height, nil, nil, nil, statsactive and ReadText(1026, 3214) or ReadText(1026, 3218)),
			Helper.createFontString(menu.title, false, "left", 255, 255, 255, 100, Helper.headerRow1Font, Helper.headerRow1FontSize, false, Helper.headerRow1Offsetx, Helper.headerRow1Offsety, Helper.headerRow1Height, Helper.headerRow1Width)
		}, nil, {2, 3}, false, Helper.defaultTitleBackgroundColor)
	else
		setup:addTitleRow({
			Helper.createFontString(menu.title, false, "left", 255, 255, 255, 100, Helper.headerRow1Font, Helper.headerRow1FontSize, false, Helper.headerRow1Offsetx, Helper.headerRow1Offsety, Helper.headerRow1Height, Helper.headerRow1Width)
		}, nil, {5})
	end

	-- menu.component owner
	local ownerDetails = C.GetOwnerDetails(menu.component)
	if ffi.string(ownerDetails.factionIcon) ~= "" then
		lines = lines + 1
		setup:addTitleRow({
			Helper.createIcon(ffi.string(ownerDetails.factionIcon), false, 255, 255, 255, 100, 0, 0, Helper.standardTextHeight, Helper.standardButtonWidth),
			Helper.createFontString(ffi.string(ownerDetails.factionName), false, "left", 255, 255, 255, 100, Helper.standardFont, Helper.standardfFontSize, false, Helper.standardTextOffsetx, Helper.standardTextOffsety, Helper.standardTextHeight, Helper.standardTextWidth)
		}, nil, {1, 4})
	end
	setup:addHeaderRow({
		emptyFontStringSmall
	}, nil, {5})

	-- yields
	if #yields > 0 then
		displayedyields = true
		lines = lines + 1
		setup:addHeaderRow({ 
			ReadText(1001, 3212) .. (yields.snapshottime ~= 0 and " (" .. ConvertTimeString(GetCurTime() - yields.snapshottime, ReadText(1001, 3211)) .. ")" or "") 
		}, nil, {5})
		for i, ware in ipairs(yields) do
			lines = lines + 1
			setup:addTitleRow({ 
				ware.name .. ReadText(1001, 120) .. " " .. ConvertIntegerString(ware.amount, true, 3, true) .. " / " .. ConvertIntegerString(ware.max, true, 3, true) 
			}, nil, {5})
		end
		lines = lines + 1
		setup:addHeaderRow({ 
			emptyFontStringSmall 
		}, nil, {5})
	end

	-- included gates
	if #gates > 0 then
		for _, gate in ipairs(gates) do
			if (not menu.mode) then
				lines = lines + 1
				if (ConvertIDTo64Bit(gate) == menu.lastchild) or ((menu.lastchild == 0) and numhistory == 1 and menu.componenttype == "zone" and menu.component == ConvertIDTo64Bit(playerzone) and IsSameComponent(gate, environmentobject)) then
					menu.setrow = lines
				end
				local name, destination = GetComponentData(gate, "name", "destination")
				if not menu.mode then
					if menu.softtarget == ConvertIDTo64Bit(gate) then
						name = menu.softtargetmarker_l .. name .. menu.softtargetmarker_r
					end
					if IsSameComponent(menu.autopilottarget, gate) then
						name = menu.autopilotmarker .. name
					end
				end

				local destinationname
				if destination then
					destinationname = GetComponentData(GetContextByClass(destination, "cluster"), "name")
				else
					destinationname = ReadText(20006, 101)
				end
			
				local color = { r = 255, g = 255, b = 255, a = 100 }
				if GetComponentData(gate, "ismissiontarget") then
					color = menu.holomapcolor.missioncolor
				end

				setup:addSimpleRow({ 
					Helper.createFontString(name .. ReadText(1001, 120) .. " " .. destinationname, false, "left", color.r, color.g, color.b, 100, Helper.standardFont, Helper.standardFontSize, true)
				}, {"gate", gate}, {5})
			end
		end
	end

	-- included jumpbeacons
	if #jumpbeacons > 0 then
		for _, jumpbeacon in ipairs(jumpbeacons) do
			if (not menu.mode) then
				lines = lines + 1
				if (ConvertIDTo64Bit(gate) == menu.lastchild) or ((menu.lastchild == 0) and numhistory == 1 and menu.componenttype == "zone" and menu.component == ConvertIDTo64Bit(playerzone) and IsSameComponent(jumpbeacon, environmentobject)) then
					menu.setrow = lines
				end
				local name, destination = GetComponentData(jumpbeacon, "name")
				if not menu.mode then
					if menu.softtarget == ConvertIDTo64Bit(jumpbeacon) then
						name = menu.softtargetmarker_l .. name .. menu.softtargetmarker_r
					end
					if IsSameComponent(menu.autopilottarget, jumpbeacon) then
						name = menu.autopilotmarker .. name
					end
				end
			
				local color = { r = 255, g = 255, b = 255, a = 100 }
				if GetComponentData(jumpbeacon, "ismissiontarget") then
					color = menu.holomapcolor.missioncolor
				end

				setup:addSimpleRow({ 
					Helper.createFontString(name, false, "left", color.r, color.g, color.b, 100, Helper.standardFont, Helper.standardFontSize, true)
				}, {"jumpbeacon", jumpbeacon}, {5})
			end
		end
	end
	
	-- included spaces
	if #children > 0 then
		displayedchildren = true
		for i, child in ipairs(children) do
			lines = lines + 1
			if (ConvertIDTo64Bit(child) == menu.lastchild) or ((menu.lastchild == 0) and numhistory == 1 and menu.componenttype == "zone" and menu.component == ConvertIDTo64Bit(playerzone) and IsSameComponent(child, environmentobject)) then
				menu.setrow = lines
			end
			local name, icon, revealpercent, childshortname = GetComponentData(child, "name", "icon", "revealpercent", "mapshortname")
			
			local esc = ""
			if numhistory > 1 and ConvertIDTo64Bit(child) == menu.history[numhistory - 1][1] then
				esc = " " .. ReadText(1001, 3209) .. " "
			end
			local containedstring = "\n"
			if menu.componenttype == "cluster" then
				if HasShipyard(child) then
					containedstring = containedstring .. "[" .. ReadText(1001, 92) .. "]"
				end
			elseif menu.componenttype == "sector" then
				if HasShipyard(child) then
					containedstring = containedstring .. "[" .. ReadText(1001, 92) .. "]"
				end
				if GetComponentData(child, "hasjumpbeacon") then
					containedstring = containedstring .. " [" .. ReadText(20109, 2101) .. "]"
				end
			end
			local yieldstring = ""
			if menu.componenttype == "sector" then
				local zoneyields = GetZoneYield(child)
				if #zoneyields > 0 then
					yieldstring = " [" .. ReadText(1001, 3212) .. ReadText(1001, 120) .. " "
					for i, ware in ipairs(zoneyields) do
						if i == 1 then
							yieldstring = yieldstring .. GetWareData(ware.ware, "shortname")
						else
							yieldstring = yieldstring .. ", " .. GetWareData(ware.ware, "shortname")
						end
					end
					yieldstring = yieldstring .. "]"
				end
			end
			
			local color = { r = 255, g = 255, b = 255, a = 100 }
			if GetComponentData(child, "ismissiontarget") then
				color = menu.holomapcolor.missioncolor
			elseif #GetContainedObjectsByOwner("player", child) > 0 then
				color = menu.holomapcolor.playercolor
			end
			
			local standardicon = "menu_info"
			if menu.componenttype == "sector" then
				standardicon = "menu_zone"
			elseif menu.componenttype == "cluster" then
				standardicon = "menu_sector"
			elseif menu.componenttype == "galaxy" then
				standardicon = "menu_cluster"
			end
			setup:addSimpleRow({ 
				Helper.createButton(nil, Helper.createButtonIcon(icon ~= "" and icon or standardicon, nil, 255, 255, 255, 100), false, ((menu.mode ~= "selectplayerobject") or (menu.modeparam[4] == 0)), 0, 0, 0, 2 * Helper.standardTextHeight),
				Helper.createFontString((shortname .. ((childshortname == "-1") and "" or ((shortname == "" and "" or ".") .. childshortname))) .. ReadText(1001, 120) .. " " .. name .. " (" .. revealpercent .. " %)" .. esc .. containedstring .. yieldstring, false, "left", color.r, color.g, color.b, 100, Helper.standardFont, Helper.standardFontSize, true)
			}, {"child", child}, {2, 3})
		end
	end

	-- helper functions
	function displayShip(ship, counter, iteration)
		counter = counter + 1

		if (ConvertIDTo64Bit(ship) == menu.lastchild) or ((menu.lastchild == 0) and numhistory == 1 and menu.componenttype == "zone" and menu.component == ConvertIDTo64Bit(playerzone) and IsSameComponent(ship, environmentobject)) then
			menu.setrow = counter
		end
		if isfirsttime and (not menu.isExtended(ConvertIDTo64Bit(ship))) and menu.isCommander(ship) then
			table.insert(menu.extendedcontainer, ConvertIDTo64Bit(ship))
		end

		local isplayer = GetComponentData(ship, "isplayerowned")

		local rawname, revealpercent = GetComponentData(ship, "name", "revealpercent")
		local unlocked = IsInfoUnlockedForPlayer(ship, "name")
		local name = Helper.unlockInfo(unlocked, rawname) .. (isplayer and "" or " (" .. revealpercent .. " %)")
		if not menu.mode then
			if menu.softtarget == ConvertIDTo64Bit(ship) then
				name = menu.softtargetmarker_l .. name .. menu.softtargetmarker_r
			end
			if IsSameComponent(menu.autopilottarget, ship) then
				name = menu.autopilotmarker .. name
			end
		end
		for i = 1, iteration do
			name = "  " .. name
		end
		if numhistory > 1 and ConvertIDTo64Bit(ship) == menu.history[numhistory - 1][1] then
			name = name .. " " .. ReadText(1001, 3209)
		end

		local color = { r = 255, g = 255, b = 255, a = 100 }
		if GetComponentData(ship, "ismissiontarget") then
			color = menu.holomapcolor.missioncolor
		elseif not unlocked then
			color = menu.grey
		elseif isplayer then
			color = menu.holomapcolor.playercolor
		elseif GetComponentData(ship, "isenemy") then
			color = menu.holomapcolor.enemycolor
		end

		local isextended = menu.isExtended(ConvertIDTo64Bit(ship))
		local subordinates = GetSubordinates(ship)
		for i = #subordinates, 1, -1 do
			if IsComponentClass(subordinates[i], "ship_xs") then
				table.remove(subordinates, i)
			else
				if menu.component ~= ConvertIDTo64Bit(GetComponentData(subordinates[i], "zoneid")) then
					table.remove(subordinates, i)
				elseif (menu.searchtext ~= "") and (not menu.filterComponentByText(subordinates[i], menu.searchtext, true)) then
					table.remove(subordinates, i)
				end
			end
		end
		table.insert(menu.subordinatedata, {id = ship, table = subordinates})

		local warning = 0
		if isplayer then
			warning = Helper.hasObjectWarning(ship)
		end
		if isplayer and warning > 0 then
			if GetBuildAnchor(ship) and GetComponentData(ship, "tradesubscription") then
				setup:addSimpleRow({ 
					#subordinates > 0 and Helper.createButton(Helper.createButtonText(isextended and "-" or "+", "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 0, Helper.standardTextHeight) or "",
					Helper.createFontString(name, false, "left", color.r, color.g, color.b, 100),
					Helper.createIcon("menu_eye", false, 255, 255, 255, 100, 0, 0, Helper.standardTextHeight, Helper.standardButtonWidth),
					Helper.createIcon("workshop_error", false, warning == 2 and 255 or 192, warning == 2 and 0 or 192, 0, 100, 0, 0, Helper.standardTextHeight, Helper.standardButtonWidth)
				}, {"ship", ship}, {1, 2, 1, 1})
			else
				setup:addSimpleRow({ 
					#subordinates > 0 and Helper.createButton(Helper.createButtonText(isextended and "-" or "+", "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 0, Helper.standardTextHeight) or "",
					Helper.createFontString(name, false, "left", color.r, color.g, color.b, 100),
					Helper.createIcon("workshop_error", false, warning == 2 and 255 or 192, warning == 2 and 0 or 192, 0, 100, 0, 0, Helper.standardTextHeight, Helper.standardButtonWidth)
				}, {"ship", ship}, {1, 3, 1})
			end
		else
			if GetBuildAnchor(ship) and GetComponentData(ship, "tradesubscription") then
				setup:addSimpleRow({ 
					#subordinates > 0 and Helper.createButton(Helper.createButtonText(isextended and "-" or "+", "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 0, Helper.standardTextHeight) or "",
					Helper.createFontString(name, false, "left", color.r, color.g, color.b, 100),
					Helper.createIcon("menu_eye", false, 255, 255, 255, 100, 0, 0, Helper.standardTextHeight, Helper.standardButtonWidth)
				}, {"ship", ship}, {1, 3, 1})
			else
				setup:addSimpleRow({ 
					#subordinates > 0 and Helper.createButton(Helper.createButtonText(isextended and "-" or "+", "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 0, Helper.standardTextHeight) or "",
					Helper.createFontString(name, false, "left", color.r, color.g, color.b, 100)
				}, {"ship", ship}, {1, 4})
			end
		end

		if isextended and #subordinates > 0 then
			for _, subordinate in ipairs(subordinates) do
				counter = displayShip(subordinate, counter, iteration + 1)
			end
		end

		return counter
	end

	-- included stations
	if #stations > 0 then
		for i, station in ipairs(stations) do
			if (not menu.mode) or (menu.mode == "selectplayerobject" and GetComponentData(station, "owner") == "player") or (menu.mode == "selectobject" and GetComponentData(station, "owner") ~= "player") or (menu.mode == "selectspaceorstation" ) then
				displayedstations = true
				lines = lines + 1
				local islastchild = false
				if (ConvertIDTo64Bit(station) == menu.lastchild) or ((menu.lastchild == 0) and numhistory == 1 and menu.componenttype == "zone" and menu.component == ConvertIDTo64Bit(playerzone) and IsSameComponent(station, environmentobject)) then
					islastchild = true
					menu.setrow = lines
				end
				if isfirsttime and (not menu.isExtended(ConvertIDTo64Bit(station))) and (menu.isCommander(station) or ConvertIDTo64Bit(station) == menu.lastchildstationdata.station) then
					table.insert(menu.extendedcontainer, ConvertIDTo64Bit(station))
				end

				local isplayer = GetComponentData(station, "isplayerowned")

				local revealpercent = GetComponentData(station, "revealpercent")
				local unlocked = IsInfoUnlockedForPlayer(station, "name")
				local name = Helper.unlockInfo(unlocked, GetComponentData(station, "name")) .. (isplayer and "" or " (" .. revealpercent .. " %)")
				if not menu.mode then 
					if menu.softtarget == ConvertIDTo64Bit(station) then
						name = menu.softtargetmarker_l .. name .. menu.softtargetmarker_r
					end
					if IsSameComponent(menu.autopilottarget, station) then
						name = menu.autopilotmarker .. name
					end
				end
				if numhistory > 1 and ConvertIDTo64Bit(ship) == menu.history[numhistory - 1][1] then
					name = name .. " " .. ReadText(1001, 3209)
				end
			
				local color = { r = 255, g = 255, b = 255, a = 100 }
				if GetComponentData(station, "ismissiontarget") then
					color = menu.holomapcolor.missioncolor
				elseif not unlocked then
					color = menu.grey
				elseif isplayer then
					color = menu.holomapcolor.playercolor
				elseif GetComponentData(station, "isenemy") then
					color = menu.holomapcolor.enemycolor
				end

				local isextended = menu.isExtended(ConvertIDTo64Bit(station))
				local subordinates = IsComponentClass(station, "controllable") and GetSubordinates(station) or {}
				for i = #subordinates, 1, -1 do
					if IsComponentClass(subordinates[i], "ship_xs") then
						table.remove(subordinates, i)
					else
						if menu.component ~= ConvertIDTo64Bit(GetComponentData(subordinates[i], "zoneid")) then
							table.remove(subordinates, i)
					elseif (menu.searchtext ~= "") and (not menu.filterComponentByText(subordinates[i], menu.searchtext, true)) then
						table.remove(subordinates, i)
						end
					end
				end
				table.insert(menu.subordinatedata, {id = station, table = subordinates})

				local buildidx = menu.findBuildtreeDataIdx(station)
				local entries = buildidx and menu.buildtreedata[buildidx].table or {}

				-- station itself
				local warning = 0
				if isplayer then
					warning = Helper.hasObjectWarning(station)
				end
				if isplayer and warning > 0 then
					if GetComponentData(station, "tradesubscription") then
						setup:addSimpleRow({ 
							Helper.createButton(Helper.createButtonText(isextended and "-" or "+", "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, ((not menu.mode) or (menu.mode == "selectobject")) and (#entries > 0), 0, 0, 0, Helper.standardTextHeight),
							Helper.createFontString(name, false, "left", color.r, color.g, color.b, 100),
							Helper.createIcon("menu_eye", false, 255, 255, 255, 100, 0, 0, Helper.standardTextHeight, Helper.standardButtonWidth),
							Helper.createIcon("workshop_error", false, warning == 2 and 255 or 192, warning == 2 and 0 or 192, 0, 100, 0, 0, Helper.standardTextHeight, Helper.standardButtonWidth)
						}, {"station", station}, {1, 2, 1, 1})
					else
						setup:addSimpleRow({ 
							Helper.createButton(Helper.createButtonText(isextended and "-" or "+", "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, ((not menu.mode) or (menu.mode == "selectobject")) and (#entries > 0), 0, 0, 0, Helper.standardTextHeight),
							Helper.createFontString(name, false, "left", color.r, color.g, color.b, 100),
							Helper.createIcon("workshop_error", false, warning == 2 and 255 or 192, warning == 2 and 0 or 192, 0, 100, 0, 0, Helper.standardTextHeight, Helper.standardButtonWidth)
						}, {"station", station}, {1, 3, 1})
					end
				else
					if GetComponentData(station, "tradesubscription") then
						setup:addSimpleRow({ 
							Helper.createButton(Helper.createButtonText(isextended and "-" or "+", "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, ((not menu.mode) or (menu.mode == "selectobject")) and (#entries > 0), 0, 0, 0, Helper.standardTextHeight),
							Helper.createFontString(name, false, "left", color.r, color.g, color.b, 100),
							Helper.createIcon("menu_eye", false, 255, 255, 255, 100, 0, 0, Helper.standardTextHeight, Helper.standardButtonWidth)
						}, {"station", station}, {1, 3, 1})
					else
						setup:addSimpleRow({ 
							Helper.createButton(Helper.createButtonText(isextended and "-" or "+", "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, ((not menu.mode) or (menu.mode == "selectobject")) and (#entries > 0), 0, 0, 0, Helper.standardTextHeight),
							Helper.createFontString(name, false, "left", color.r, color.g, color.b, 100)
						}, {"station", station}, {1, 4})
					end
				end

				-- buildtree
				if isextended then
					for seqidx, sequence in pairs(entries) do
						if isfirsttime and (not menu.isSequenceExtended(station, seqidx)) and (sequence.sequence == menu.lastchildstationdata.sequence) then
							 menu.extendSequence(station, seqidx, true)
						end

						local isseqextended = menu.isSequenceExtended(station, seqidx)
						
						setup:addSimpleRow({ 
							Helper.createButton(Helper.createButtonText(isseqextended and "-" or "+", "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, not menu.mode or menu.mode == "selectobject", 0, 0, 0, Helper.standardTextHeight),
							sequence.seqname
						}, {"sequence", station, seqidx}, {1, 4})
						lines = lines + 1
						if islastchild and menu.lastsequence == seqidx then
							menu.setrow = lines
							menu.lastsequence = nil
						end
						if isseqextended then
							if seqidx == 1 and sequence[0] then
								for k, module in ipairs(sequence[0]) do
									lines = lines + 1
									if ConvertIDTo64Bit(module.component) == menu.lastchild then
										menu.setrow = lines
									end
									local moduleunlocked = isplayer or IsInfoUnlockedForPlayer(module.component, "name")
									setup:addSimpleRow({ 
										"",
										moduleunlocked and module.name or Helper.createFontString("    " .. ReadText(1001, 3210) .. " (" .. module.revealpercent .. " %)", false, Helper.standardHalignment, menu.grey.r,  menu.grey.g,  menu.grey.b, menu.grey.a)
									}, {"module", module.component, seqidx}, {1, 4})
								end
							end
							for stageidx, stage in ipairs(sequence) do
								if (stageidx > 1 or seqidx == 1) and #stage > 0 then
									setup:addHeaderRow({ 
										emptyFontStringSmall 
									}, nil, {5})
									lines = lines + 1
								end
								for _, module in ipairs(stage) do
									lines = lines + 1
									if ConvertIDTo64Bit(module.component) == menu.lastchild then
										menu.setrow = lines
									end
									local moduleunlocked = isplayer or IsInfoUnlockedForPlayer(module.component, "name")
									setup:addSimpleRow({ 
										"",
										moduleunlocked and module.name or Helper.createFontString("      " .. ReadText(1001, 3210) .. " (" .. module.revealpercent .. " %)", false, Helper.standardHalignment, menu.grey.r, menu.grey.g, menu.grey.b, menu.grey.a)
									}, {"module", module.component, seqidx}, {1, 4})
								end
							end
						end
					end
				end

				-- subordinates
				if isextended and #subordinates > 0 then
					for _, subordinate in ipairs(subordinates) do
						lines = displayShip(subordinate, lines, 1)
					end
				end
			end
		end
	end

	-- included ships
	if #ships > 0 then
		for i, ship in ipairs(ships) do
			if (not menu.mode) or (menu.mode == "selectplayerobject" and GetComponentData(ship, "owner") == "player") or (menu.mode == "selectobject" and GetComponentData(ship, "owner") ~= "player") then
				displayedships = true
				lines = displayShip(ship, lines, 0)
			end
		end
	end

	-- old buildtree display
	if menu.componenttype == "container" then
		local entries = {}
		menu.createBuildtreeData(menu.component, entries)

		for seqidx, sequence in ipairs(entries) do
			setup:addHeaderRow({ 
				sequence.seqname 
			}, nil, {5})
			lines = lines + 1
			if seqidx == 1 then
				for _, module in ipairs(sequence[0]) do
					lines = lines + 1
					if ConvertIDTo64Bit(module.component) == menu.lastchild then
						menu.setrow = lines
					end
					local moduleunlocked = IsInfoUnlockedForPlayer(module.component, "name")
					setup:addSimpleRow({ 
						"",
						moduleunlocked and module.name or Helper.createFontString("      " .. ReadText(1001, 3210) .. " (" .. module.revealpercent .. " %)", false, Helper.standardHalignment, menu.grey.r,  menu.grey.g,  menu.grey.b, menu.grey.a)
					}, {"module", module.component}, {1, 4})
				end
			end
			for stageidx, stage in ipairs(sequence) do
				if stageidx > 1 or seqidx == 1 then
					setup:addHeaderRow({ 
						emptyFontStringSmall 
					}, nil, {5})
					lines = lines + 1
				end
				for _, module in ipairs(stage) do
					lines = lines + 1
					if ConvertIDTo64Bit(module.component) == menu.lastchild then
						menu.setrow = lines
					end
					local moduleunlocked = IsInfoUnlockedForPlayer(module.component, "name")
					setup:addSimpleRow({ 
						"",
						moduleunlocked and module.name or Helper.createFontString("      " .. ReadText(1001, 3210) .. " (" .. module.revealpercent .. " %)", false, Helper.standardHalignment, menu.grey.r, menu.grey.g, menu.grey.b, menu.grey.a)
					}, {"module", module.component}, {1, 4})
				end
			end
		end
	end

	-- disable fill rows for spaces
	if not (menu.componenttype == "galaxy" or menu.componenttype == "cluster" or menu.componenttype == "sector") then
		setup:addFillRows(19, nil, {5})
	end

	local offsety = Helper.tableOffsety + 30

	if menu.setrow and menu.setrow > lines then
		menu.setrow = nil
	end
	-- print(tostring(menu.settoprow) .. ", " .. tostring((not menu.settoprow) and ((menu.setrow and menu.setrow > (((menu.componenttype == "zone") and 16 or 8) + (ffi.string(ownerDetails.factionIcon) ~= "" and 3 or 2))) and ((menu.componenttype == "zone") and (menu.setrow - 13) or (menu.setrow - 7)) or (ffi.string(ownerDetails.factionIcon) ~= "" and 4 or 3)) or menu.settoprow) .. ", " .. tostring(menu.setrow) .. ", " .. tostring(lines))
	local selectdesc = setup:createCustomWidthTable({Helper.scaleX(Helper.standardButtonWidth), Helper.scaleX((2 * Helper.standardTextHeight) - Helper.standardButtonWidth) - 5, 0, Helper.scaleX(Helper.standardButtonWidth), Helper.scaleX(Helper.standardButtonWidth)}, false, true, true, menu.taborderoverride and 2 or 1, ffi.string(ownerDetails.factionIcon) ~= "" and 3 or 2, Helper.scaleY(Helper.standardSizeY - offsety + 5), 0, Helper.scaleY(Helper.standardSizeY - offsety), true, (not menu.settoprow) and ((menu.setrow and menu.setrow > (((menu.componenttype == "zone") and 16 or 8) + (ffi.string(ownerDetails.factionIcon) ~= "" and 3 or 2))) and ((menu.componenttype == "zone") and (menu.setrow - 13) or (menu.setrow - 7)) or (ffi.string(ownerDetails.factionIcon) ~= "" and 4 or 3)) or menu.settoprow, menu.setrow)
	menu.setrow = nil
	menu.settoprow = nil
	menu.setcol = nil
	
	-- button table
	setup = Helper.createTableSetup(menu)
	setup:addTitleRow({ 
		Helper.createFontString("", false, "left", 255, 255, 255, 100, Helper.headerRow2Font, Helper.headerRow2FontSize, true, Helper.headerRow2Offsetx, Helper.headerRow2Offsety, Helper.headerRow2Height * 3, Helper.headerRow1Width / 2),	-- text depends on selection
		Helper.createFontString("", false, "left", 255, 255, 255, 100, Helper.headerRow2Font, Helper.headerRow2FontSize, true, Helper.headerRow2Offsetx, Helper.headerRow2Offsety, Helper.headerRow2Height * 3, Helper.headerRow1Width / 2)
	}, nil, {5, 5})	
	setup:addSimpleRow({ 
		"",
		Helper.createButton(Helper.createButtonText(ReadText(1001, 2669), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_B", true)),
		"",
		Helper.createButton(Helper.createButtonText(menu.parenttitle, "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, menu.componenttype ~= "galaxy" and ((menu.mode ~= "selectplayerobject") or (menu.modeparam[4] == 0)), 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_BACK", true), nil, menu.mot_parent),
		"",
		Helper.createButton(Helper.createButtonText(menu.mode == "selectposition" and ReadText(1001, 2821) or (menu.componenttype == "sector" and (IsSameComponent(GetActiveGuidanceMissionComponent(), menu.selectedcomponent) and ReadText(1001, 1110) or ReadText(1001, 1109)) or ReadText(1001, 3216)), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, (menu.mode == "selectposition") or (menu.componenttype == "sector"), 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_Y", true)),
		"",
		Helper.createButton(Helper.createButtonText((menu.componenttype == "galaxy" or menu.componenttype == "cluster" or menu.componenttype == "sector") and menu.childtitle or ReadText(1001, 2961), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, false, 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_X", true)),
		""
	}, nil, {1, 1, 1, 1, 2, 1, 1, 1, 1}, false, menu.transparent)

	local buttondesc = setup:createCustomWidthTable({48, 150, 48, 150, 22, 0, 150, 48, 150, 48}, false, false, true, menu.taborderoverride and 1 or 2, 2, 0, Helper.standardSizeY - offsety + 5, 0, false, nil, nil, menu.setbuttoncol)
	menu.setbuttoncol = nil
	menu.taborderoverride = nil

	-- editbox table
	setup = Helper.createTableSetup(menu)

	local editboxwidth = 200
	local editboxheight = 30

	setup:addSimpleRow({ 
		Helper.createEditBox(Helper.createButtonText(menu.searchtext, "left", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), false, 0, 0, editboxwidth, editboxheight, {r = 33, g = 46, b = 55, a = 40}, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_0", true), false),
		Helper.createButton(Helper.createButtonText("X", "center", Helper.standardFontBold, Helper.scaleFont(Helper.standardFontBold, Helper.standardFontSize), 255, 255, 255, 100), nil, true, true, 0, 2, Helper.scaleX(editboxheight / 2), Helper.scaleY(editboxheight / 2), {r = 33, g = 46, b = 55, a = 40})
	}, nil, nil, false, menu.transparent)

	local editboxdesc = setup:createCustomWidthTable({editboxwidth, editboxheight / 2}, false, false, true, 3, 1, Helper.standardSizeY - offsety - editboxwidth - editboxheight / 2 - 5, 0, editboxheight, false)
	
	-- rendertarget
	menu.rendertargetWidth = Helper.standardSizeY - offsety
	local rendertargetdesc = Helper.createRenderTarget(menu.rendertargetWidth, menu.rendertargetWidth, 0, 0)

	-- create tableview
	menu.selecttable, menu.buttontable, menu.editboxtable, menu.rendertarget = Helper.displayThreeTableRenderTargetView(menu, selectdesc, buttondesc, editboxdesc, rendertargetdesc, false, "", "", 0, 0, 0, 0, "both", false)
	
	-- set button scripts
	if menu.componenttype ~= "component" then
		Helper.setButtonScript(menu, nil, menu.selecttable, 1, 1, menu.buttonStats)
	end

	local nooflines = (ffi.string(ownerDetails.factionIcon) ~= "" and 4 or 3) + (displayedyields and #yields + 2 or 0) + ((not menu.mode) and (#gates + #jumpbeacons) or 0)

	-- helper function
	function setShipScript(ship, counter)
		local idx = menu.findSubordinateDataIdx(ship)
		if idx then
			local subordinates = menu.subordinatedata[idx].table
			if #subordinates > 0 then
				Helper.setButtonScript(menu, nil, menu.selecttable, counter, 1, function () return menu.buttonNavigation("ship", ConvertIDTo64Bit(ship), 0) end)
			end
			counter = counter + 1
			if menu.isExtended(ConvertIDTo64Bit(ship)) and #subordinates > 0 then
				for _, subordinate in ipairs(subordinates) do
					counter = setShipScript(subordinate, counter)
				end
			end
		end

		return counter
	end

	if displayedchildren then
		for i, child in ipairs(children) do
			Helper.setButtonScript(menu, nil, menu.selecttable, nooflines, 1, function () return menu.buttonNavigation("child", ConvertIDTo64Bit(child), 0) end)
			nooflines = nooflines + 1
		end
	end
	if displayedstations then
		for i, station in ipairs(stations) do 
			if (not menu.mode) or (menu.mode == "selectplayerobject" and GetComponentData(station, "owner") == "player") or (menu.mode == "selectobject" and GetComponentData(station, "owner") ~= "player") then
				local isextended = menu.isExtended(ConvertIDTo64Bit(station))

				Helper.setButtonScript(menu, nil, menu.selecttable, nooflines, 1, function () return menu.buttonNavigation("ship", ConvertIDTo64Bit(station), 0) end)
				nooflines = nooflines + 1
				
				-- buildtree
				local buildidx = menu.findBuildtreeDataIdx(station)
				if isextended and buildidx then
					local entries = menu.buildtreedata[buildidx].table

					for seqidx, sequence in pairs(entries) do
						Helper.setButtonScript(menu, nil, menu.selecttable, nooflines, 1, function () return menu.buttonExtendSequence(station, seqidx) end)
						nooflines = nooflines + 1
						if menu.isSequenceExtended(station, seqidx) then
							if seqidx == 1 and sequence[0] then
								for _, module in ipairs(sequence[0]) do
									
									nooflines = nooflines + 1
								end
							end
							for stageidx, stage in ipairs(sequence) do
								if (stageidx > 1 or seqidx == 1) and #stage > 0 then
									nooflines = nooflines + 1
								end
								for _, module in ipairs(stage) do
									
									nooflines = nooflines + 1
								end
							end
						end
					end
				end

				-- subordinates
				local idx = menu.findSubordinateDataIdx(station)
				local subordinates
				if idx then
					subordinates = menu.subordinatedata[idx].table
					
					if menu.isExtended(ConvertIDTo64Bit(station)) and #subordinates > 0 then
						for _, subordinate in ipairs(subordinates) do
							nooflines = setShipScript(subordinate, nooflines)
						end
					end
				end
			end
		end
	end
	if displayedships then
		for i, ship in ipairs(ships) do
			if (not menu.mode) or (menu.mode == "selectplayerobject" and GetComponentData(ship, "owner") == "player") or (menu.mode == "selectobject" and GetComponentData(ship, "owner") ~= "player") then
				nooflines = setShipScript(ship, nooflines)
			end
		end
	end
	if menu.componenttype == "container" then
		for seqidx, sequence in ipairs(entries) do
			nooflines = nooflines + 1
			if seqidx == 1 then
				for _, module in ipairs(sequence[0]) do
					
					nooflines = nooflines + 1
				end
			end
			for stageidx, stage in ipairs(sequence) do
				if stageidx > 1 or seqidx == 1 then
					nooflines = nooflines + 1
				end
				for _, module in ipairs(stage) do
					
					nooflines = nooflines + 1
				end
			end
		end
	end

	-- button table
	Helper.setButtonScript(menu, nil, menu.buttontable, 2, 2, function () return menu.onCloseElement("back") end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 2, 4, function () return menu.buttonNavigation("back", nil, 0) end)
	if menu.mode == "selectspace" or menu.mode == "selectspaceorstation" then
		Helper.setButtonScript(menu, nil, menu.buttontable, 2, 7, menu.buttonSelectspaceorstation)
	elseif menu.componenttype == "sector" then
		Helper.setButtonScript(menu, nil, menu.buttontable, 2, 7, menu.buttonPlotCourse)
	else
		Helper.setButtonScript(menu, nil, menu.buttontable, 2, 7, menu.buttonComm)
	end
	Helper.setButtonScript(menu, nil, menu.buttontable, 2, 9, menu.buttonDetails)

	-- editbox table
	Helper.setEditBoxScript(menu, nil, menu.editboxtable, 1, 1, menu.editboxUpdateText)
	Helper.setButtonScript(menu, nil, menu.editboxtable, 1, 2, menu.buttonClearEditbox)

	-- clear descriptors again
	Helper.releaseDescriptors()
	
	menu.createChildListRunning = false;
end

menu.updateInterval = 0.5

function menu.onUpdate()
	local rowdata = Helper.currentTableRowData

	if menu.activatemap then
		-- pass relative screenspace of the holomap rendertarget to the holomap (value range = -1 .. 1)
		local renderX0, renderX1, renderY0, renderY1 = Helper.getRelativeRenderTargetSize(menu.rendertarget)
		local rendertargetTexture = GetRenderTargetTexture(menu.rendertarget)
		if rendertargetTexture then
			menu.holomap = C.AddHoloMap(rendertargetTexture, renderX0, renderX1, renderY0, renderY1)
			if menu.holomap ~= 0 then
				C.ShowUniverseMap(menu.holomap, menu.component, true, 0)
				C.EnableMapPicking(menu.holomap)
			
				if rowdata then
					if rowdata ~= "back" then
						C.SetHighlightMapComponent(menu.holomap, ConvertIDTo64Bit(rowdata[2]), true)
					else
						C.ClearHighlightMapComponent(menu.holomap)
					end
				end
			end
		end
		menu.activatemap = false
		menu.onRowChanged(Helper.currentTableRow[menu.selecttable], Helper.currentTableRowData)
	end

	if rowdata then
		menu.updateInfoText(rowdata[1], rowdata[2])
		if rowdata[1] == "gate" or rowdata[1] == "jumpbeacon" then
			menu.updateJumpButton()
		end
	end
end

function menu.updateJumpButton()
	menu.onplatform = menu.onplatform or IsComponentClass(GetPlayerRoom(), "dockingbay")

	local jumpdrivetext = ReadText(1001, 3218)
	local mouseovertext = ReadText(1026, 3201)
	local active = false
	local hasjumpdrive, nextjumptime, ischarging, isjumpdrivebusy = GetComponentData(menu.playership, "hasjumpdrive", "nextjumptime", "isjumpdrivecharging", "isjumpdrivebusy")
	nextjumptime = nextjumptime - GetCurTime()
	if hasjumpdrive then
		if nextjumptime > 0 then
			jumpdrivetext = ConvertTimeString(nextjumptime, ReadText(1001, 3220))
			active = (not menu.onplatform) and C.HasPlayerJumpKickstarter()
			if active then
				mouseovertext = string.format(ReadText(1026, 3200), GetWareData("inv_kickstarter", "name"))
			else
				mouseovertext = string.format(ReadText(1026, 3203), GetWareData("inv_kickstarter", "name"))
			end
		elseif isjumpdrivebusy then
			jumpdrivetext = ReadText(1001, 3221)
			mouseovertext = ""
		else
			if ischarging then
				jumpdrivetext = ReadText(1001, 3219)
				mouseovertext = ""
			end
			active = not menu.onplatform
		end
	else
		mouseovertext = ReadText(1026, 3202)
	end
	if (jumpdrivetext ~= menu.jumpdrive.text) or (mouseovertext ~= menu.jumpdrive.mouseovertext) or (active ~= menu.jumpdrive.active) then
		menu.jumpdrive.text = jumpdrivetext
		menu.jumpdrive.mouseovertext = mouseovertext
		menu.jumpdrive.active = active
		Helper.removeButtonScripts(menu, menu.buttontable, 2, 9)
		SetCellContent(menu.buttontable, Helper.createButton(Helper.createButtonText((menu.mode == "selectplayerobject" or menu.mode == "selectobject") and ReadText(1001, 3102) or jumpdrivetext, "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, active, 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_X", true), nil, mouseovertext), 2, 9)
		Helper.setButtonScript(menu, nil, menu.buttontable, 2, 9, menu.buttonJumpDrive)
	end
end

function menu.onRowChanged(row, rowdata)
	-- print("onRowChanged: " .. tostring(row) .. ", row name: " .. tostring(rowdata))
	if menu.holomap == 0 then
		return
	end
	local resetplayerpan = (menu.lastUpdateHolomapTime == nil) or (menu.lastUpdateHolomapTime + 0.1 < GetCurRealTime())
	if rowdata then
		if rowdata ~= "back" then
			if rowdata[1] == "sequence" then
				C.ShowUniverseMap(menu.holomap, ConvertIDTo64Bit(rowdata[2]), false, 0)
				C.SetHighlightMapComponent(menu.holomap, ConvertIDTo64Bit(rowdata[2]), resetplayerpan)
				local buildidx = menu.findBuildtreeDataIdx(rowdata[2])
				if buildidx then
					local entries = menu.buildtreedata[buildidx].table
					for stageidx, stage in ipairs(entries[rowdata[3]]) do
						for _, module in ipairs(stage) do
							--C.SetHighlightMapComponent(menu.holomap, ConvertIDTo64Bit(module.component), true)
						end
					end
				end
				-- COMM
				Helper.removeButtonScripts(menu, menu.buttontable, 2, 7)
				SetCellContent(menu.buttontable, Helper.createButton(Helper.createButtonText(ReadText(1001, 3216), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, false, 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_Y", true)), 2, 7)
				Helper.setButtonScript(menu, nil, menu.buttontable, 2, 7, menu.buttonComm)
				-- DETAILS
				Helper.removeButtonScripts(menu, menu.buttontable, 2, 9)
				SetCellContent(menu.buttontable, Helper.createButton(Helper.createButtonText(ReadText(1001, 2961), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, false, 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_X", true)), 2, 9)
				Helper.setButtonScript(menu, nil, menu.buttontable, 2, 9, menu.buttonDetails)
			else
				menu.selectedcomponent = rowdata[2]
				C.SetHighlightMapComponent(menu.holomap, ConvertIDTo64Bit(rowdata[2]), resetplayerpan)
				if menu.componenttype == "zone" then
					local isextended = menu.isExtended(ConvertIDTo64Bit(rowdata[2]))
					if isextended then
						C.ShowUniverseMap(menu.holomap, ConvertIDTo64Bit(rowdata[2]), false, 0)
						C.SetHighlightMapComponent(menu.holomap, ConvertIDTo64Bit(rowdata[2]), resetplayerpan)
					end
					if rowdata[1] == "module" then
						local station = GetContextByClass(rowdata[2], "station")
						C.ShowUniverseMap(menu.holomap, ConvertIDTo64Bit(station), false, 0)
						C.SetHighlightMapComponent(menu.holomap, ConvertIDTo64Bit(rowdata[2]), resetplayerpan)
						-- COMM
						Helper.removeButtonScripts(menu, menu.buttontable, 2, 7)
						SetCellContent(menu.buttontable, Helper.createButton(Helper.createButtonText(ReadText(1001, 3216), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, false, 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_Y", true)), 2, 7)
						Helper.setButtonScript(menu, nil, menu.buttontable, 2, 7, menu.buttonComm)
						-- DETAILS
						local active = ((not menu.mode) or (menu.mode == "selectobject")) and IsInfoUnlockedForPlayer(menu.selectedcomponent, "name") and (CanViewLiveData(station) or GetComponentData(menu.selectedcomponent, "tradesubscription") or menu.mode == "selectobject")
						Helper.removeButtonScripts(menu, menu.buttontable, 2, 9)
						SetCellContent(menu.buttontable, Helper.createButton(Helper.createButtonText((menu.mode == "selectplayerobject" or menu.mode == "selectobject") and ReadText(1001, 3102) or ReadText(1001, 2961), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, active, 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_X", true), nil, active and ReadText(1026, 3206) or nil), 2, 9)
						Helper.setButtonScript(menu, nil, menu.buttontable, 2, 9, menu.buttonDetails)
					elseif rowdata[1] == "gate" or rowdata[1] == "jumpbeacon" then
						-- COMM
						Helper.removeButtonScripts(menu, menu.buttontable, 2, 7)
						SetCellContent(menu.buttontable, Helper.createButton(Helper.createButtonText(ReadText(1001, 3216), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, false, 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_Y", true)), 2, 7)
						Helper.setButtonScript(menu, nil, menu.buttontable, 2, 7, menu.buttonComm)
						-- DETAILS
						menu.jumpdrive = {}
						menu.updateJumpButton()
					else
						if not isextended then
							C.ShowUniverseMap(menu.holomap, menu.component, false, 0)
							C.SetHighlightMapComponent(menu.holomap, ConvertIDTo64Bit(rowdata[2]), resetplayerpan)
						end
						-- COMM
						local isplayership = IsSameComponent(menu.selectedcomponent, menu.playership)
						local neworder = (rowdata[1] == "ship") and GetComponentData(rowdata[2], "isplayerowned") and (not isplayership) and (not GetBuildAnchor(rowdata[2]))
						local active = (not menu.mode) and IsComponentOperational(menu.selectedcomponent) and (not isplayership) and GetComponentData(menu.selectedcomponent, "caninitiatecomm")
						if neworder then
							local pilot = GetComponentData(menu.selectedcomponent, "pilot")
							local blackboard_shiptrader_docking = pilot and GetNPCBlackboard(pilot, "$shiptrader_docking") or nil
							blackboard_shiptrader_docking = blackboard_shiptrader_docking and blackboard_shiptrader_docking ~= 0
							local blackboard_ship_parking = pilot and GetNPCBlackboard(pilot, "$ship_parking") or nil
							blackboard_ship_parking = blackboard_ship_parking and blackboard_ship_parking ~= 0
							local isdocked, isdocking = GetComponentData(menu.selectedcomponent, "isdocked", "isdocking")
							local commander = GetCommander(menu.selectedcomponent)
							active = active and pilot and (not blackboard_shiptrader_docking) and (not blackboard_ship_parking) and (not isdocked) and (not isdocking) and ((not commander) or IsSameComponent(commander, menu.playership))
						end
						Helper.removeButtonScripts(menu, menu.buttontable, 2, 7)
						SetCellContent(menu.buttontable, Helper.createButton(Helper.createButtonText(neworder and ReadText(1002, 2020) or ReadText(1001, 3216), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, active, 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_Y", true), nil, active and (neworder and "" or ReadText(1026, 3205)) or (neworder and ReadText(1026, 20004) or nil)), 2, 7)
						Helper.setButtonScript(menu, nil, menu.buttontable, 2, 7, neworder and menu.buttonNewOrder or menu.buttonComm)
						-- DETAILS
						Helper.removeButtonScripts(menu, menu.buttontable, 2, 9)
						local activate = false
						if IsInfoUnlockedForPlayer(menu.selectedcomponent, "name") and (CanViewLiveData(menu.selectedcomponent) or GetComponentData(menu.selectedcomponent, "tradesubscription") or menu.mode == "selectobject") then
							if menu.mode ~= "selectplayerobject" then
								activate = true
							else
								if Helper.checkObjectSelectConditions(menu.selectedcomponent, menu.modeparam) then
									activate = true
								end
							end
						end
						SetCellContent(menu.buttontable, Helper.createButton(Helper.createButtonText((menu.mode == "selectplayerobject" or menu.mode == "selectobject") and ReadText(1001, 3102) or ReadText(1001, 2961), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, activate, 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_X", true), nil, activate and ((menu.mode ~= "selectplayerobject" and menu.mode ~= "selectobject") and ReadText(1026, 3206) or nil) or nil), 2, 9)
						Helper.setButtonScript(menu, nil, menu.buttontable, 2, 9, menu.buttonDetails)
					end
				elseif menu.componenttype == "container" then
					-- DETAILS
					local active = (not menu.mode) and IsInfoUnlockedForPlayer(menu.selectedcomponent, "name") and CanViewLiveData(menu.selectedcomponent)
					if menu.mode == "selectspaceorstation" and ffi.string(C.GetComponentClass(menu.selectedcomponent)) == "station" then
						Helper.removeButtonScripts(menu, menu.buttontable, 2, 7)
						SetCellContent(menu.buttontable, Helper.createButton(Helper.createButtonText(ReadText(1001, 3102), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_Y", true)), 2, 7)
						Helper.setButtonScript(menu, nil, menu.buttontable, 2, 7, menu.buttonSelectspaceorstation)
					end
					Helper.removeButtonScripts(menu, menu.buttontable, 2, 9)
					SetCellContent(menu.buttontable, Helper.createButton(Helper.createButtonText(ReadText(1001, 2961), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, active, 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_X", true), nil, active and ReadText(1026, 3206) or nil), 2, 9)
					Helper.setButtonScript(menu, nil, menu.buttontable, 2, 9, menu.buttonDetails)
				elseif menu.componenttype == "sector" then
					-- PLOT COURSE or SELECT SPACE
					local active = ((not menu.mode) and (not IsSameComponent(menu.selectedcomponent, GetComponentData(menu.playership, "zoneid")))) or (menu.mode == "selectposition")
					if menu.mode == "selectspace" or menu.mode == "selectspaceorstation" then
						Helper.removeButtonScripts(menu, menu.buttontable, 2, 7)
						SetCellContent(menu.buttontable, Helper.createButton(Helper.createButtonText(ReadText(1001, 3102), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_Y", true)), 2, 7)
						Helper.setButtonScript(menu, nil, menu.buttontable, 2, 7, menu.buttonSelectspaceorstation)
					else
						Helper.removeButtonScripts(menu, menu.buttontable, 2, 7)
						SetCellContent(menu.buttontable, Helper.createButton(Helper.createButtonText(menu.mode == "selectposition" and ReadText(1001, 2821) or (IsSameComponent(GetActiveGuidanceMissionComponent(), menu.selectedcomponent) and ReadText(1001, 1110) or ReadText(1001, 1109)), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, active, 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_Y", true), nil, active and ReadText(1026, 3208) or nil), 2, 7)
						Helper.setButtonScript(menu, nil, menu.buttontable, 2, 7, menu.buttonPlotCourse)
					end
					-- DETAILS
					local active = ((menu.mode ~= "selectplayerobject") or (menu.modeparam[4] == 0))
					Helper.removeButtonScripts(menu, menu.buttontable, 2, 9)
					SetCellContent(menu.buttontable, Helper.createButton(Helper.createButtonText(menu.mode == "selectzone" and ReadText(1001, 3102) or menu.childtitle, "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, active, 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_X", true), nil, active and ((menu.mode ~= "selectzone") and ReadText(1026, 3209) or nil) or nil), 2, 9)
					Helper.setButtonScript(menu, nil, menu.buttontable, 2, 9, menu.mode == "selectzone" and menu.buttonDetails or function () return menu.buttonNavigation("child", ConvertIDTo64Bit(menu.selectedcomponent), 0) end)
				elseif menu.componenttype == "cluster" then
					-- SELECT SPACE
					if menu.mode == "selectspace" or menu.mode == "selectspaceorstation" then
						Helper.removeButtonScripts(menu, menu.buttontable, 2, 7)
						SetCellContent(menu.buttontable, Helper.createButton(Helper.createButtonText(ReadText(1001, 3102), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_Y", true)), 2, 7)
						Helper.setButtonScript(menu, nil, menu.buttontable, 2, 7, menu.buttonSelectspaceorstation)
					end
					-- DETAILS
					Helper.removeButtonScripts(menu, menu.buttontable, 2, 9)
					SetCellContent(menu.buttontable, Helper.createButton(Helper.createButtonText(menu.mode == "selectsector" and ReadText(1001, 3102) or menu.childtitle, "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, ((menu.mode ~= "selectplayerobject") or (menu.modeparam[4] == 0)), 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_X", true)), 2, 9)
					Helper.setButtonScript(menu, nil, menu.buttontable, 2, 9, menu.mode == "selectsector" and menu.buttonDetails or function () return menu.buttonNavigation("child", ConvertIDTo64Bit(menu.selectedcomponent), 0) end)
				elseif menu.componenttype == "galaxy" then
					-- SELECT SPACE
					if menu.mode == "selectspace" or menu.mode == "selectspaceorstation" then
						Helper.removeButtonScripts(menu, menu.buttontable, 2, 7)
						SetCellContent(menu.buttontable, Helper.createButton(Helper.createButtonText(ReadText(1001, 3102), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_Y", true)), 2, 7)
						Helper.setButtonScript(menu, nil, menu.buttontable, 2, 7, menu.buttonSelectspaceorstation)
					end
					-- DETAILS
					Helper.removeButtonScripts(menu, menu.buttontable, 2, 9)
					SetCellContent(menu.buttontable, Helper.createButton(Helper.createButtonText(menu.mode == "selectcluster" and ReadText(1001, 3102) or menu.childtitle, "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, ((menu.mode ~= "selectplayerobject") or (menu.modeparam[4] == 0)), 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_X", true)), 2, 9)
					Helper.setButtonScript(menu, nil, menu.buttontable, 2, 9, menu.mode == "selectcluster" and menu.buttonDetails or function () return menu.buttonNavigation("child", ConvertIDTo64Bit(menu.selectedcomponent), 0) end)
				else
					-- DETAILS
					local active = ((menu.mode ~= "selectplayerobject") or (menu.modeparam[4] == 0))
					Helper.removeButtonScripts(menu, menu.buttontable, 2, 9)
					SetCellContent(menu.buttontable, Helper.createButton(Helper.createButtonText(menu.childtitle, "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, active, 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_X", true), nil, active and menu.mot_child or nil), 2, 9)
					Helper.setButtonScript(menu, nil, menu.buttontable, 2, 9, function () return menu.buttonNavigation("child", ConvertIDTo64Bit(menu.selectedcomponent), 0) end)
				end
				menu.updateInfoText(rowdata[1], rowdata[2])
			end
		else
			C.ClearHighlightMapComponent(menu.holomap)
		end
	end
end

function menu.onSelectElement()
	local rowdata = Helper.currentTableRowData
	if rowdata and (rowdata[1] == "ship" or rowdata[1] == "gate") then
		menu.targetObject(menu.selectedcomponent)
	end
end

function menu.updateInfoText(type, component)
	if IsValidComponent(component) then
		if menu.componenttype == "zone" or menu.componenttype == "container" then
			if type ~= "gate" and type ~= "jumpbeacon" then
				local updatetext = ""
				local hullpercent, shieldpercent, shieldmax = GetComponentData(component, "hullpercent", "shieldpercent", "shieldmax")
				updatetext = updatetext .. ReadText(1001, 1) .. ReadText(1001, 120) .. " " .. hullpercent .. "%" .. (shieldmax ~= 0 and ", " .. ReadText(1001, 2) .. ReadText(1001, 120) .. " " .. shieldpercent .. "%" or "")
				local owner = GetComponentData(component, "owner")
				if owner then
					local factionDetails = C.GetFactionDetails(owner)
					updatetext = updatetext .. "\n" .. ReadText(1001, 43) .. ReadText(1001, 120) .. " " .. ffi.string(factionDetails.factionName)
				end
				local storagearray = GetStorageData(component)
				local units = { }
				if IsComponentClass(component, "defensible") then
					units = GetUnitStorageData(component)
				end
				if next(storagearray) and (storagearray.capacity > 0 or storagearray.estimated) then
					updatetext = updatetext .. string.format("\n%s%s %s%s / %s", ReadText(1001, 1400), ReadText(1001, 120), Helper.estimateString(storagearray.estimated), ConvertIntegerString(storagearray.stored, true, 3, true), ConvertIntegerString(storagearray.capacity, true, 3, true))
				elseif #units > 0 then
					updatetext = updatetext .. string.format("\n%s%s %d / %d", ReadText(1001, 22), ReadText(1001, 120), units.stored, units.capacity)
				else
					updatetext = updatetext .. "\n" .. ReadText(1001, 1400) .. ReadText(1001, 120) .. " " .. ReadText(1001, 9)
				end
				Helper.updateCellText(menu.buttontable, 1, 1, updatetext)
				local weapons = GetAllWeapons(component)
				local upgrades = GetAllUpgrades(component, false)
				local notupgradeturrets = GetNotUpgradesByClass(component, "turret")
				notupgradeturrets.totaloperational = 0
				for i, turret in ipairs(notupgradeturrets) do
					local defence_status = IsInfoUnlockedForPlayer(turret, "defence_status")
					if not defence_status then
						notupgradeturrets.estimated = true
					end
					if IsComponentOperational(turret) and defence_status then
						notupgradeturrets.totaloperational = notupgradeturrets.totaloperational + 1
					end
				end
				if (next(upgrades) and (upgrades.totaltotal ~= 0 or upgrades.estimated)) or notupgradeturrets.totaloperational ~= 0 or (next(weapons) and ((next(weapons.weapons) and (#weapons.weapons ~= 0)) or (next(weapons.missiles) and #weapons.missiles ~= 0))) then
					updatetext = ReadText(1001, 1105) .. ReadText(1001, 120) .. " " .. Helper.estimateString(upgrades.estimated) .. upgrades.totaloperational + notupgradeturrets.totaloperational + #weapons.weapons + #weapons.missiles
				else
					updatetext = ReadText(1001, 1105) .. ReadText(1001, 120) .. " " .. ReadText(1001, 28)
				end
				if IsComponentClass(component, "station") or GetContextByClass(component, "station") then
					local productionmodules = GetProductionModules(component)
					if next(productionmodules) and #productionmodules > 0 then
						updatetext = updatetext .. "\n" .. ReadText(1001, 1613) .. ReadText(1001, 120) .. " " .. #productionmodules
					else
						updatetext = updatetext .. "\n" .. ReadText(1001, 1613) .. ReadText(1001, 120) .. " " .. ReadText(1001, 29)
					end
					if GetContextByClass(component, "station") then
						local efficiency = GetComponentData(component, "efficiencybonus")
						if efficiency > 0 then
							updatetext = updatetext .. "\n" .. ReadText(1001, 1602) .. ReadText(1001, 120) .. " " .. Helper.round(efficiency * 100) .. " %"
						end
					end
				elseif IsComponentClass(component, "ship") then
					local buildanchor = GetBuildAnchor(component)
					if buildanchor then
						local _, _, progress = GetCurrentBuildSlot(buildanchor)
						if progress then
							updatetext = updatetext .. "\n" .. string.format(ReadText(1001, 1805), progress)
						end
					end
					if not IsSameComponent(menu.playership, component) then
						local pilot = GetComponentData(component, "pilot")
						if pilot then
							local unlocked_operator_commands = IsInfoUnlockedForPlayer(component, "operator_commands")
							local aicommandstack, aicommand, aicommandparam, aicommandaction, aicommandactionparam = GetComponentData(pilot, "aicommandstack", "aicommand", "aicommandparam", "aicommandaction", "aicommandactionparam")
							numaicommands = #aicommandstack

							if numaicommands > 0 then
								aicommand = aicommandstack[1].command
								aicommandparam = aicommandstack[1].param
							end
							updatetext = updatetext .. "\n" .. ReadText(1001, 78) .. ReadText(1001, 120) .. " " .. Helper.unlockInfo(unlocked_operator_commands, string.format(aicommand, IsComponentClass(aicommandparam, "component") and GetComponentData(aicommandparam, "name") or nil))
				
							if numaicommands > 1 then
								aicommandaction = aicommandstack[numaicommands].command
								aicommandactionparam = aicommandstack[numaicommands].param
							end
							if aicommandaction ~= "" then
								updatetext = updatetext .. " - " .. Helper.unlockInfo(unlocked_operator_commands, string.format(aicommandaction, IsComponentClass(aicommandactionparam, "component") and GetComponentData(aicommandactionparam, "name") or nil))
							end
						end
					end
				end
				Helper.updateCellText(menu.buttontable, 1, 6, updatetext)
			else
				Helper.updateCellText(menu.buttontable, 1, 1, "")
				Helper.updateCellText(menu.buttontable, 1, 6, "")
			end
		elseif menu.componenttype == "sector" then
			local updatetext = ""
			local updatetext2 = ""
			local yields = GetZoneYield(component)
			if next(yields) then
				if yields.snapshottime ~= 0 then
					updatetext = updatetext .. "--- " .. ConvertTimeString(GetCurTime() - yields.snapshottime, ReadText(1001, 3211)) .. " ---\n"
				end
			end
			local owner = GetComponentData(component, "ownername")
			if owner then
				updatetext = updatetext .. ReadText(1001, 3213) .. ReadText(1001, 120) .. " " .. owner .. "\n"
			end
			for i, ware in ipairs(yields) do
				if i <= ((yields.snapshottime ~= 0 and 2 or 3) - (owner and 1 or 0)) then
					updatetext = updatetext .. ware.name .. ReadText(1001, 120) .. " " .. ConvertIntegerString(ware.amount, true, 3, true) .. " / " .. ConvertIntegerString(ware.max, true, 3, true) .. "\n"
				elseif i < ((yields.snapshottime ~= 0 and 5 or 6) - (owner and 1 or 0)) then
					updatetext2 = updatetext2 .. ware.name .. ReadText(1001, 120) .. " " .. ConvertIntegerString(ware.amount, true, 3, true) .. " / " .. ConvertIntegerString(ware.max, true, 3, true) .. "\n"
				elseif i == ((yields.snapshottime ~= 0 and 5 or 6) - (owner and 1 or 0)) and #yields == ((yields.snapshottime ~= 0 and 5 or 6) - (owner and 1 or 0)) then
					updatetext2 = updatetext2 .. ware.name .. ReadText(1001, 120) .. " " .. ConvertIntegerString(ware.amount, true, 3, true) .. " / " .. ConvertIntegerString(ware.max, true, 3, true) .. "\n"
				elseif i == ((yields.snapshottime ~= 0 and 5 or 6) - (owner and 1 or 0)) then
					updatetext2 = updatetext2 .. "... \n"
				end
			end
			Helper.updateCellText(menu.buttontable, 1, 1, updatetext)
			Helper.updateCellText(menu.buttontable, 1, 6, updatetext2)
		end
	end
end

function menu.onRenderTargetSelect()
	if (not menu.lock) or (menu.lock + 0.5 > GetCurRealTime()) then
		if (menu.mode == "selectposition") and (menu.componenttype ~= "galaxy")  and (menu.componenttype ~= "cluster") then
			local offset = ffi.new("UIPosRot")
			local offsetvalid = C.GetMapPositionOnEcliptic(menu.holomap, offset, true)
			if offsetvalid then
				menu.offset = offset
			end
		else
			local pickedcomponent = C.GetPickedMapComponent(menu.holomap)
			if pickedcomponent ~= 0 then
				local pickedcomponentclass = ffi.string(C.GetComponentClass(pickedcomponent))
				local ispickedcomponentship = (pickedcomponentclass == "ship_xs") or (pickedcomponentclass == "ship_s") or (pickedcomponentclass == "ship_m") or (pickedcomponentclass == "ship_l") or (pickedcomponentclass == "ship_xl")
				if pickedcomponentclass == "tradeofferdock" then
					C.RemoveHoloMap2()
					menu.holomap = 0
					Helper.closeMenuForSubSection(menu, false, "gTrade_offerselect", { 0, 0, C.IsSellOffer(pickedcomponent), nil, nil, ConvertStringTo64Bit(tostring(C.GetContextByClass(pickedcomponent, "container", false))) })
					menu.cleanup()
				elseif (ispickedcomponentship or pickedcomponentclass == "gate") and IsSameComponent(menu.selectedcomponent, ConvertStringTo64Bit(tostring(pickedcomponent))) then
					-- click on current selected object -> make it the current target
					-- main reason: so double-clicking works correctly, which sometimes is retrieved as two separate single-clicks
					menu.targetObject(menu.selectedcomponent)
				elseif menu.searchtext == "" or menu.filterComponentByText(ConvertStringTo64Bit(tostring(pickedcomponent)), menu.searchtext, true) then
					if C.IsComponentOperational(pickedcomponent) and pickedcomponentclass ~= "player" and pickedcomponentclass ~= "ship_xs" and pickedcomponentclass ~= "highwayentrygate" and pickedcomponentclass ~= "tradeofferdock" and pickedcomponentclass ~= "collectablewares" and (menu.componenttype == "zone" or (pickedcomponentclass ~= "gate" and pickedcomponentclass ~= "jumpbeacon" and pickedcomponentclass ~= "station" and (not ispickedcomponentship))) and not menu.createChildListRunning then
						menu.lastchild = pickedcomponent
						local lastchildzone = C.GetContextByClass(menu.lastchild, "zone", false)
						if menu.componenttype == "zone" and menu.component ~= lastchildzone then
							menu.component = lastchildzone
						end
						local lastchildclass = ffi.string(C.GetComponentClass(menu.lastchild))
						local islastchildcontainer = (lastchildclass == "station") or (lastchildclass == "ship_xs") or (lastchildclass == "ship_s") or (lastchildclass == "ship_m") or (lastchildclass == "ship_l") or (lastchildclass == "ship_xl")
						if menu.componenttype == "zone" and islastchildcontainer then
							menu.commanderlist = menu.lastchild ~= 0 and GetAllCommanders(ConvertStringTo64Bit(tostring(menu.lastchild))) or {}
						else
							menu.commanderlist = {}
						end
						if menu.componenttype == "zone" and (not islastchildcontainer) then
							local sequence = ffi.string(C.GetBuildSourceSequence(menu.lastchild))
							menu.lastchildstationdata = { station = C.GetContextByClass(menu.lastchild, "station", false), sequence = (sequence == "") and "a" or sequence }
						else
							menu.lastchildstationdata = {}
						end
						menu.createChildList(true)
					elseif (pickedcomponentclass == "gate") or (pickedcomponentclass == "jumpbeacon") then
						if menu.componenttype == "sector" then
							menu.lastchild = C.GetContextByClass(pickedcomponent, "zone", false)
						elseif menu.componenttype == "cluster" then
							menu.lastchild = C.GetContextByClass(pickedcomponent, "sector", false)
						end
						menu.commanderlist = {}
						menu.lastchildstationdata = {}
						menu.createChildList(true)
					end
				end
			end
		end
	end
	menu.lock = nil
end

function menu.onRenderTargetDoubleClick()
	local pickedcomponent = C.GetPickedMapComponent(menu.holomap)
	if pickedcomponent ~= 0 then
		local pickedcomponentclass = ffi.string(C.GetComponentClass(pickedcomponent))
		local ispickedcomponentship = (pickedcomponentclass == "ship_xs") or (pickedcomponentclass == "ship_s") or (pickedcomponentclass == "ship_m") or (pickedcomponentclass == "ship_l") or (pickedcomponentclass == "ship_xl")
		local isplayership = IsSameComponent(ConvertStringToLuaID(tostring(pickedcomponent)), menu.playership)
		if isplayership then
			if menu.componenttype == "sector" then
				menu.buttonNavigation("child", C.GetContextByClass(pickedcomponent, "zone", false), 1)
			elseif menu.componenttype == "cluster" then
				menu.buttonNavigation("child", C.GetContextByClass(pickedcomponent, "sector", false), 1)
			end
		elseif ispickedcomponentship or (pickedcomponentclass == "gate") then
			if not menu.targetObject(ConvertStringTo64Bit(tostring(pickedcomponent))) then
				if (menu.componenttype == "sector") and (pickedcomponentclass == "gate") then
					menu.buttonNavigation("child", C.GetContextByClass(pickedcomponent, "zone", false), 1)
				elseif (menu.componenttype == "cluster") and (pickedcomponentclass == "gate") then
					menu.buttonNavigation("child", C.GetContextByClass(pickedcomponent, "sector", false), 1)
				end
			end
		elseif menu.searchtext == "" or menu.filterComponentByText(ConvertStringTo64Bit(tostring(pickedcomponent)), menu.searchtext, true) then
			if C.IsComponentOperational(pickedcomponent) and pickedcomponentclass ~= "player" and pickedcomponentclass ~= "ship_xs" and pickedcomponentclass ~= "highwayentrygate" and pickedcomponentclass ~= "gate" and pickedcomponentclass ~= "jumpbeacon" and pickedcomponentclass ~= "collectablewares" and (menu.componenttype == "zone" or (pickedcomponentclass ~= "station")) and not menu.createChildListRunning then
				local type
				if pickedcomponentclass == "station" then
					type = "ship"
				else
					type = "child"
				end
				menu.buttonNavigation(type, pickedcomponent, 0)
			end
		end
	elseif not menu.createChildListRunning then
		if menu.componenttype == "zone" then
			local rowdata = Helper.currentTableRowData
			if rowdata then
				local component = 0
				local convertedRowData2 = ConvertIDTo64Bit(rowdata[2]) or 0

				if rowdata[1] == "station" or rowdata[1] == "sequence" then
					if menu.isExtended(convertedRowData2) then
						component = convertedRowData2
					end
				elseif rowdata[1] == "module" then
					component = convertedRowData2
				end

				if component ~= 0 then
					for i, entry in ipairs(menu.extendedcontainer) do
						if entry == component then
							table.remove(menu.extendedcontainer, i)
						end
					end
					menu.settoprow = GetTopRow(menu.selecttable)
					menu.lastchild = component
					menu.createChildList()
					if menu.holomap ~= 0 then
						C.ClearHighlightMapComponent(menu.holomap)
						C.ShowUniverseMap(menu.holomap, menu.component, true, 0)
					end
				end
			end
		end
	end
end

function menu.onRenderTargetMouseDown()
	menu.lock = GetCurRealTime()
	C.StartPanMap(menu.holomap)
end

function menu.onRenderTargetMouseUp()
	C.StopPanMap(menu.holomap)
end

function menu.onRenderTargetRightMouseDown()
	C.StartRotateMap(menu.holomap)
end

function menu.onRenderTargetRightMouseUp()
	C.StopRotateMap(menu.holomap)
end

function menu.onRenderTargetScrollDown()
	C.ZoomMap(menu.holomap, 1)
end

function menu.onRenderTargetScrollUp()
	C.ZoomMap(menu.holomap, -1)
end

function menu.autoZoomOut()
	if (menu.mode ~= "selectplayerobject") or (menu.modeparam[4] == 0) then
		if not menu.createChildListRunning then
			if menu.componenttype == "zone" then
				local rowdata = Helper.currentTableRowData
				local component = 0
				if rowdata then
					local convertedRowData2 = ConvertIDTo64Bit(rowdata[2]) or 0
					if rowdata[1] == "station" or rowdata[1] == "sequence" then
						if menu.isExtended(convertedRowData2) then
							component = convertedRowData2
						end
					elseif rowdata[1] == "module" then
						component = C.GetContextByClass(convertedRowData2, "container", false)
					end
				end
				if component ~= 0 then
					for i, entry in ipairs(menu.extendedcontainer) do
						if entry == component then
							table.remove(menu.extendedcontainer, i)
						end
					end
					menu.settoprow = GetTopRow(menu.selecttable)
					menu.lastchild = component
					menu.createChildList()
					if menu.holomap ~= 0 then
						C.ClearHighlightMapComponent(menu.holomap)
						C.ShowUniverseMap(menu.holomap, menu.component, false, -1)
					end
				else
					menu.buttonNavigation("back", nil, -1)
				end
			else
				menu.buttonNavigation("back", nil, -1)
			end
		end
	end
end

function menu.autoZoomIn(component)
	if (menu.mode ~= "selectplayerobject") or (menu.modeparam[4] == 0) then
		local curtime = GetCurRealTime()
		if (not menu.autoZoomInLock) or (menu.autoZoomInLock < curtime) then
		local pickedcomponent = C.GetPickedMapComponent(menu.holomap)
			if pickedcomponent == 0 then
				pickedcomponent = ConvertIDTo64Bit(menu.selectedcomponent)
			end
			if pickedcomponent ~= 0 then
				local pickedcomponentclass = ffi.string(C.GetComponentClass(pickedcomponent))
				local isplayership = IsSameComponent(ConvertStringToLuaID(tostring(pickedcomponent)), menu.playership)
				if C.IsComponentOperational(pickedcomponent) then
					if ((pickedcomponentclass == "station" and menu.componenttype == "zone") or pickedcomponentclass == "cluster" or pickedcomponentclass == "sector" or pickedcomponentclass == "zone") and not menu.createChildListRunning then
						local type
						if pickedcomponentclass == "station" then
							type = "ship" -- sic!
						else
							type = "child"
						end
						menu.buttonNavigation(type, pickedcomponent, 1)
						menu.autoZoomInLock = curtime + 0.2
					elseif (menu.componenttype == "sector") and ((pickedcomponentclass == "station") or (pickedcomponentclass == "gate") or isplayership) then
						menu.buttonNavigation("child", C.GetContextByClass(pickedcomponent, "zone", false), 1)
						menu.autoZoomInLock = curtime + 0.2
					elseif (menu.componenttype == "cluster") and ((pickedcomponentclass == "gate") or isplayership) then
						menu.buttonNavigation("child", C.GetContextByClass(pickedcomponent, "sector", false), 1)
						menu.autoZoomInLock = curtime + 0.2
					end
				end
			end
		end
	end
end

function menu.onButtonDown()
	menu.noupdate = true
	PlaySound("ui_btn_down")
end

function menu.onTableScrollBarDown()
	menu.noupdate = true
	PlaySound("ui_sbar_table_down")
end

function menu.onTableScrollBarUp()
	menu.noupdate = false
end

function menu.onInteractiveElementChanged(element)
	menu.lastactivetable = element
	if menu.lastactivetable == menu.editboxtable then
		menu.noupdate = true
	end
end

function menu.onCloseElement(dueToClose)
	if dueToClose == "close" then
		C.RemoveHoloMap2()
		menu.holomap = 0
		Helper.closeMenuAndCancel(menu)
		menu.cleanup()
	else
		local numhistory = #menu.history
		if numhistory > 1 then
			menu.lastchild = menu.component
			menu.component = menu.history[numhistory - 1][1]
			menu.componenttype = menu.history[numhistory - 1][2]
			menu.offset = nil
			table.remove(menu.history)
			menu.createChildList()
			if menu.holomap ~= 0 then
				C.ClearHighlightMapComponent(menu.holomap)
				C.ShowUniverseMap(menu.holomap, menu.component, true, 0)
			end
		else
			C.RemoveHoloMap2()
			menu.holomap = 0
			Helper.closeMenuAndReturn(menu)
			menu.cleanup()
		end
	end
end

function menu.isExtended(id)
	for i, entry in ipairs(menu.extendedcontainer) do
		if entry == id then
			return true
		end
	end
	return false
end

function menu.isSequenceExtended(station, seqidx)
	for i, entry in ipairs(menu.extendedsequences) do
		if IsSameComponent(entry.id, station) then
			return entry.sequences[seqidx]
		end
	end
	return false
end

function menu.findSubordinateDataIdx(id)
	for i, entry in ipairs(menu.subordinatedata) do
		if IsSameComponent(entry.id, id) then
			return i
		end
	end
	return nil
end

function menu.findBuildtreeDataIdx(id)
	for i, entry in ipairs(menu.buildtreedata) do
		if IsSameComponent(entry.id, id) then
			return i
		end
	end
	return nil
end

function menu.isCommander(id)
	for i, entry in ipairs(menu.commanderlist) do
		if IsSameComponent(entry, id) then
			return true
		end
	end
	return false
end

function menu.keywordHelper(keywordid, text)
	return (text == menu.searchkeywords[keywordid]) or (text == menu.searchkeywords[keywordid + 1])
end

function menu.filterComponentByText(component, text, includeobjects)
	text = utf8.lower(text)
	-- NAME
	if not IsComponentClass(component, "jumpbeacon") then
		if string.find(utf8.lower(GetComponentData(component, "name")), text, 1, true) then
			return true
		end
	end
	
	-- KEYWORDS	
	-- KEYWORD: PLAYER
	if menu.keywordHelper(101, text) and GetComponentData(component, "isplayerowned") then
		return true
	end
	-- KEYWORD: SHIPYARD
	if menu.keywordHelper(201, text) and GetComponentData(component, "isshipyard") then
		return true
	end
	-- KEYWORD: JUMP BEACON
	if menu.keywordHelper(301, text) and IsComponentClass(component, "jumpbeacon") then
		return true
	end
	-- KEYWORD: GATE
	if menu.keywordHelper(401, text) and IsComponentClass(component, "gate") then
		return true
	end
	-- KEYWORD: ENEMY
	if menu.keywordHelper(501, text) and GetComponentData(component, "isenemy") then
		return true
	end

	-- FACTION
	if IsComponentClass(component, "space") or (menu.componenttype == "zone") then
		local ownername = GetComponentData(component, "ownername")
		if ownername and string.find(utf8.lower(ownername), text, 1, true) then
			return true
		end
	end

	if IsComponentClass(component, "space") then
		if includeobjects then
			-- SHIPS
			local ships = GetContainedShips(component, true)
			for i = #ships, 1, -1 do
				if IsComponentClass(ships[i], "ship_xs") then
					table.remove(ships, i)
				else
					local commander = GetCommander(ships[i])
					if commander and menu.component == ConvertIDTo64Bit(GetComponentData(commander, "zoneid")) then
						table.remove(ships, i)
					end
				end
			end
			for _, ship in ipairs(ships) do
				if (not menu.mode) or (menu.mode == "selectplayerobject" and GetComponentData(ship, "owner") == "player") or (menu.mode == "selectobject" and GetComponentData(ship, "owner") ~= "player") then
					if menu.filterComponentByText(ship, text, false) then
						return true
					end
				end
			end

			-- STATIONS
			local stations = GetContainedStations(component, true, menu.modeparam[3] and (menu.modeparam[3] ~= 0))
			for i = #stations, 1, -1 do
				local commander = IsComponentClass(stations[i], "controllable") and GetCommander(stations[i]) or nil
				if commander and menu.component == ConvertIDTo64Bit(GetComponentData(commander, "zoneid")) then
					table.remove(stations, i)
				end
			end
			for _, station in ipairs(stations) do
				if (not menu.mode) or (menu.mode == "selectplayerobject" and GetComponentData(station, "owner") == "player") or (menu.mode == "selectobject" and GetComponentData(station, "owner") ~= "player") then
					if menu.filterComponentByText(station, text, false) then
						return true
					end
				end
			end

			-- GATES
			local gates = GetGates(component, true)
			for _, gate in ipairs(gates) do
				if menu.filterComponentByText(gate, text, false) then
					return true
				end
			end
		end

		if IsComponentClass(component, "cluster") then
			-- SECTORS
			local sectors = GetSectors(component)
			for _, sector in ipairs(sectors) do
				if menu.filterComponentByText(sector, text, false) then
					return true
				end
			end
		elseif IsComponentClass(component, "sector") then
			-- ZONES
			local zones = GetZones(component)
			for _, zone in ipairs(zones) do
				if menu.filterComponentByText(zone, text, false) then
					return true
				end
			end
		elseif IsComponentClass(component, "zone") then
			-- YIELDS
			local yields = GetZoneYield(component, true)
			for _, ware in ipairs(yields) do
				if string.find(utf8.lower(ware.name), text, 1, true) then
					return true
				end
			end
			
			-- JUMP BEACONS
			local jumpbeacons = GetJumpBeacons(component, true)
			for _, jumpbeacon in ipairs(jumpbeacons) do
				if menu.filterComponentByText(jumpbeacon, text, false) then
					return true
				end
			end
		end
	end

	-- GATE
	if IsComponentClass(component, "gate") then
		if menu.componenttype == "cluster" or menu.componenttype == "sector" or menu.componenttype == "zone" then
			local destination = GetComponentData(component, "destination")
			if destination then
				if string.find(utf8.lower(GetComponentData(destination, "name")), text, 1, true) then
					return true
				end
				if string.find(utf8.lower(GetComponentData(GetContextByClass(destination, "sector"), "name")), text, 1, true) then
					return true
				end
				if string.find(utf8.lower(GetComponentData(GetContextByClass(destination, "cluster"), "name")), text, 1, true) then
					return true
				end
			end
		end
	end

	-- STATION & SHIP
	if IsComponentClass(component, "station") or IsComponentClass(component, "ship") then
		if menu.componenttype == "zone" then
			-- SUBORDINATES
			local subordinates = IsComponentClass(component, "controllable") and GetSubordinates(component) or {}
			for i = #subordinates, 1, -1 do
				if IsComponentClass(subordinates[i], "ship_xs") then
					table.remove(subordinates, i)
				else
					if menu.component ~= ConvertIDTo64Bit(GetComponentData(subordinates[i], "zoneid")) then
						table.remove(subordinates, i)
					end
				end
			end
			for _, subordinate in ipairs(subordinates) do
				if (not menu.mode) or (menu.mode == "selectplayerobject" and GetComponentData(subordinate, "owner") == "player") or (menu.mode == "selectobject" and GetComponentData(subordinate, "owner") ~= "player") then
					if menu.filterComponentByText(subordinate, text, false) then
						return true
					end
				end
			end
		end
	end

	-- STATION
	if IsComponentClass(component, "station") then
		if menu.componenttype == "zone" then
			-- MODULES
			local buildidx = menu.findBuildtreeDataIdx(component)
			local entries = buildidx and menu.buildtreedata[buildidx].table or {}

			for seqidx, sequence in pairs(entries) do
				if seqidx == 1 then
					for _, module in ipairs(sequence[0]) do
						if menu.filterComponentByText(module.component, text, false) then
							return true
						end
					end
				end
				for stageidx, stage in ipairs(sequence) do
					for _, module in ipairs(stage) do
						if menu.filterComponentByText(module.component, text, false) then
							return true
						end
					end
				end
			end
		end

		local tradeoffers = menu.stationtradeoffers[tostring(component)] or {}
		for _, trade in ipairs(tradeoffers) do
			if string.find(utf8.lower(trade.name), text, 1, true) then
				return true
			end
		end
	end

	return false
end

function menu.createseqdata(entries, station, seqidx, seqdata, isplayer)
	entries[seqidx] = { sequence = seqdata.sequence }
	local productionname = ""
	local numproductions, numbuild, numstorages, numradar, numdronelaunchpad, numoperational = 0, 0, 0, 0, 0, 0
	local nummodules = 0
	local sumreveal = 0
	-- handle basestation as ("a", 0)
	if seqidx == 1 then
		entries[seqidx][0] = {}
		modules = GetBuildStageModules(ConvertStringTo64Bit(tostring(station)), "", 0)
		nummodules = nummodules + #modules

		numproductions = numproductions + modules.numproductions
		numbuild = numbuild + modules.numbuild
		numstorages = numstorages + modules.numstorages
		numradar = numradar + modules.numradar
		numdronelaunchpad = numdronelaunchpad + modules.numdronelaunchpad

		for _, module in ipairs(modules) do
			if IsComponentOperational(module.component) and (menu.searchtext == "" or menu.filterComponentByText(module.component, menu.searchtext, true)) then
				numoperational = numoperational + 1
				local revealpercent = GetComponentData(module.component, "revealpercent")
				sumreveal = sumreveal + revealpercent
				local unlocked = IsInfoUnlockedForPlayer(module.component, "name")
				local color = { r = 255, g = 255, b = 255, a = 100 }
				if not unlocked then
					color = menu.grey
				elseif GetComponentData(module.component, "ismissiontarget") then
					color = menu.holomapcolor.missioncolor
				elseif module.library == "moduletypes_production" then
					color = menu.holomapcolor.productioncolor
					productionname = module.name
				elseif module.library == "moduletypes_build" then
					color = menu.holomapcolor.buildcolor
					productionname = module.name
				elseif module.library == "moduletypes_storage" then
					color = menu.holomapcolor.storagecolor
				elseif module.library == "moduletypes_communication" then
					color = menu.holomapcolor.radarcolor
				elseif module.library == "moduletypes_dronedock" then
					color = menu.holomapcolor.dronedockcolor
				elseif module.library == "moduletypes_efficiency" then
					color = menu.holomapcolor.efficiencycolor
				elseif module.library == "moduletypes_defence" then
					color = menu.holomapcolor.defencecolor
				end
				module.name = Helper.unlockInfo(unlocked, module.name)
				if not menu.mode then
					if menu.softtarget == ConvertIDTo64Bit(module.component) then
						module.name = menu.softtargetmarker_l .. module.name .. menu.softtargetmarker_r
					end
					if IsSameComponent(menu.autopilottarget, module.component) then
						module.name = menu.autopilotmarker .. module.name
					end
				end
				table.insert(entries[seqidx][0],	{ name = Helper.createFontString("      " .. module.name .. (isplayer and "" or " (" .. revealpercent .. " %)"), false, "left", color.r, color.g, color.b, 100, Helper.standardFont), library = module.library, macro = module.macro, component = module.component, revealpercent = revealpercent })
				if revealpercent >= 10 then
					AddKnownItem(module.library, module.macro)
				end
			end
		end
		if #entries[seqidx][0] == 0 then
			entries[seqidx][0] = nil
		end
	end
	if seqdata then
		for stageidx, stagedata in ipairs(seqdata) do
			if stagedata.stage <= seqdata.currentstage then
				-- stage
				entries[seqidx][stageidx] = {}
				modules = GetBuildStageModules(ConvertStringTo64Bit(tostring(station)), seqdata.sequence, stagedata.stage)
				nummodules = nummodules + #modules

				numproductions = numproductions + modules.numproductions
				numbuild = numbuild + modules.numbuild
				numstorages = numstorages + modules.numstorages
				numradar = numradar + modules.numradar
				numdronelaunchpad = numdronelaunchpad + modules.numdronelaunchpad

				for _, module in ipairs(modules) do
					if IsComponentOperational(module.component) and (menu.searchtext == "" or menu.filterComponentByText(module.component, menu.searchtext, true)) then
						numoperational = numoperational + 1
						local revealpercent = GetComponentData(module.component, "revealpercent")
						sumreveal = sumreveal + revealpercent
						local unlocked = IsInfoUnlockedForPlayer(module.component, "name")
						local color = { r = 255, g = 255, b = 255, a = 100 }
						if not unlocked then
							color = menu.grey
						elseif module.library == "moduletypes_production" then
							color = menu.holomapcolor.productioncolor
							productionname = module.name
						elseif module.library == "moduletypes_build" then
							color = menu.holomapcolor.buildcolor
							productionname = module.name
						elseif module.library == "moduletypes_storage" then
							color = menu.holomapcolor.storagecolor
						elseif module.library == "moduletypes_communication" then
							color = menu.holomapcolor.radarcolor
						elseif module.library == "moduletypes_dronedock" then
							color = menu.holomapcolor.dronedockcolor
						elseif module.library == "moduletypes_efficiency" then
							color = menu.holomapcolor.efficiencycolor
						elseif module.library == "moduletypes_defence" then
							color = menu.holomapcolor.defencecolor
						end
						module.name = Helper.unlockInfo(unlocked, module.name)
						if not menu.mode then
							if menu.softtarget == ConvertIDTo64Bit(module.component) then
								module.name = menu.softtargetmarker_l .. module.name .. menu.softtargetmarker_r
							end
							if IsSameComponent(menu.autopilottarget, module.component) then
								module.name = menu.autopilotmarker .. module.name
							end
						end
						table.insert(entries[seqidx][stageidx],	{ name = Helper.createFontString("      " .. module.name .. (isplayer and "" or " (" .. revealpercent .. " %)"), false, "left", color.r, color.g, color.b, 100, Helper.standardFont), library = module.library, macro = module.macro, component = module.component, revealpercent = revealpercent })
						if isplayer or revealpercent >= 10 then
							AddKnownItem(module.library, module.macro)
						end
					end
				end
				if #entries[seqidx][stageidx] == 0 then
					entries[seqidx][stageidx] = nil
				end
			end
		end
	end
	sumreveal = sumreveal / nummodules
	if isplayer or sumreveal >= 1 then
		if numoperational == 0 then
			entries[seqidx].seqname = "  --- " .. ReadText(1001, 3217) .. " ---"
		elseif numproductions > 0 or numbuild > 0 then
			entries[seqidx].seqname = "  " .. productionname
		elseif numstorages > 0 then
			entries[seqidx].seqname = "  " .. ReadText(1001, 1400)
		elseif numradar > 0 then
			entries[seqidx].seqname = "  " .. ReadText(1001, 1706)
		elseif numdronelaunchpad > 0 then
			entries[seqidx].seqname = "  " .. ReadText(1001, 1707)
		else
			entries[seqidx].seqname = "  " .. ReadText(1001, 1310)
		end
		entries[seqidx].seqname = entries[seqidx].seqname .. (isplayer and "" or " (" .. string.format("%.0f", sumreveal) .. " %)")
	else
		entries[seqidx].seqname = Helper.createFontString("   " .. ReadText(1001, 3210) .. " (" .. string.format("%.0f", sumreveal) .. " %)", false, Helper.standardHalignment, menu.grey.r, menu.grey.g, menu.grey.b, menu.grey.a)
	end
	if (entries[seqidx][0] == nil) and (#entries[seqidx] == 0) then
		entries[seqidx] = nil
	end
end

function menu.createBuildtreeData(station, entries, isplayer)
	local buildtree = GetBuildTree(ConvertStringTo64Bit(tostring(station)))

	-- TEMP: Just making sure that we have a name for display
	if not buildtree.name or buildtree.name == "" then
		buildtree.name = ReadText(1001, 3)
	end

	-- entries = {
	-- 	[seqidx] = {
	-- 		seqname = name of sequence,
	--		[stageidx] = {
	--			[1] = { name = module name, macro = module macro, component = module component, library = module library }
	--			[2] = { ... }
	--		}
	-- 	}
	-- }
	table.sort(buildtree, function (a, b) return a.name < b.name end)
		
	if buildtree[1] then
		menu.createseqdata(entries, station, 1, buildtree[1], isplayer)
	end
	for seqidx, seqdata in ipairs(buildtree) do
		if seqidx ~= 1 and seqdata.currentstage > 0 then
			menu.createseqdata(entries, station, seqidx, seqdata, isplayer)
		end
	end
end

init()
