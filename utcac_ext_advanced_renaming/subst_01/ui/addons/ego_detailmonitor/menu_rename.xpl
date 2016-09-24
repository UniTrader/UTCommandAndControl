
-- section == gMain_rename
-- param == { 0, 0, object }

local menu = {
	name = "RenameMenu",
	white = { r = 255, g = 255, b = 255, a = 100 },
	red = { r = 255, g = 0, b = 0, a = 100 }
}

local function init()
	Menus = Menus or { }
	table.insert(Menus, menu)
	if Helper then
		Helper.registerMenu(menu)
	end
end

local renamesubordinates = false --UniTrader change: add script-local bool to indicate that Subordinates should be renamed rather than the Ship itself

function menu.cleanup()
	menu.title = nil
	menu.object = nil

	menu.infotable = nil
	menu.selecttable = nil
end

-- Menu member functions

function menu.editboxUpdateText(_, text, textchanged)
	if textchanged then
-- UniTrader Change: dont change Object Name directly - instead Set local Var and Signal Name Managment MD Script to handle the rest
		if GetComponentData(menu.object, "controlentity") then
		    if renamesubordinates then
			    SignalObject(GetComponentData(menu.object, "galaxyid" ) , "Subordinates Name Updated" , menu.object , text )
			else
			    SetNPCBlackboard(GetComponentData(menu.object, "controlentity"), "$unformatted_object_name" , text)
			    SignalObject(GetComponentData(menu.object, "galaxyid" ) , "Object Name Updated" , menu.object )
			end
		else
			SetComponentName(menu.object, text) -- this line was previously by itself, not in the if
		end
-- UniTrader Change end
	end
	Helper.closeMenuAndReturn(menu)
	menu.cleanup()
end

function menu.buttonOK()
	Helper.confirmEditBoxInput(menu.selecttable, 1, 1)
end

-- UniTrader new Function: Rename all Subordinates of Object (instead of current Object)
function menu.buttonRenameSubordinates()
	renamesubordinates = true
	Helper.confirmEditBoxInput(menu.selecttable, 1, 1)
end
-- UniTrader new Function end

function menu.buttonCancel()
	Helper.cancelEditBoxInput(menu.selecttable, 1, 1)
	Helper.closeMenuAndReturn(menu)
	menu.cleanup()
end

function menu.onShowMenu()
	menu.object = menu.param[3]

	local container = GetContextByClass(menu.object, "container", false)
	local isship = IsComponentClass(menu.object, "ship")
-- UniTrader Change: Split Name Var into displayname (from Object) and (edit)name (from Local Var of Control Entity , fallback to displayname)
	local displayname, name, objectowner = GetComponentData(menu.object, "name", "name", "owner")
	if GetNPCBlackboard(GetComponentData(menu.object, "controlentity"), "$unformatted_object_name") then
		name = GetNPCBlackboard(GetComponentData(menu.object, "controlentity"), "$unformatted_object_name")
	end
	if container then
		menu.title = GetComponentData(container, "name") .. " - " .. (name ~= "" and displayname or ReadText(1001, 56))
	else
		menu.title = (name ~= "" and displayname or ReadText(1001, 56))
	end
-- UniTrader Change end

	-- Title line as one TableView
	local setup = Helper.createTableSetup(menu)	
	
	local isplayer, reveal = GetComponentData(menu.object, "isplayerowned", "revealpercent")
	setup:addSimpleRow({
		Helper.createFontString(menu.title .. (isplayer and "" or " (" .. reveal .. " %)"), false, "left", 255, 255, 255, 100, Helper.headerRow1Font, Helper.headerRow1FontSize, false, Helper.headerRow1Offsetx, Helper.headerRow1Offsety, Helper.headerRow1Height, Helper.headerRow1Width, isship and ReadText(1026, 1117) or nil)
	}, nil, nil, false, Helper.defaultTitleBackgroundColor)
	setup:addTitleRow({
		Helper.getEmptyCellDescriptor()
	})
	
	local infodesc = setup:createCustomWidthTable({ 0 }, false, false, true, 3, 1)

	setup = Helper.createTableSetup(menu)

	setup:addSimpleRow({ 
		Helper.createEditBox(Helper.createButtonText(name, "left", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), false, 0, 0, 880, 24, nil, nil, true, isship and ReadText(1026, 1118) or nil)
	})

	local selectdesc = setup:createCustomWidthTable({0}, false, false, true, 1, 0, 0, Helper.tableOffsety, nil, nil, nil, 1)

	setup = Helper.createTableSetup(menu)
	setup:addSimpleRow({ 
		Helper.getEmptyCellDescriptor(),
		Helper.createButton(Helper.createButtonText(ReadText(1001, 14), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_A", true), nil, isship and ReadText(1026, 1119) or nil),
		Helper.getEmptyCellDescriptor(),
		Helper.createButton(Helper.createButtonText(ReadText(1001, 64), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_ESC", true), nil, isship and ReadText(1026, 1120) or nil),
		Helper.getEmptyCellDescriptor()
	}, nil, {1, 1, 1, 1, 1}, false, menu.transparent)
	
	-- Mass Renaming Functions
	setup:addHeaderRow({ReadText(5554302, 1001),"Future Functions"}, nil, {3, 2})
	setup:addSimpleRow({ 
		Helper.createButton(Helper.createButtonText(ReadText(5554302, 1002), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25, nil, nil, nil, "Rename all Subordinates of this Object"),
		Helper.createButton(Helper.createButtonText(ReadText(5554302, 1004), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25, nil, nil, nil, "Rename Big Ship Subordinates of this Object"),
		Helper.createButton(Helper.createButtonText(ReadText(5554302, 1006), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25, nil, nil, nil, "Rename Small Ship Subordinates of this Object"),
		Helper.getEmptyCellDescriptor(),
		Helper.getEmptyCellDescriptor()
	}, nil, {1, 1, 1, 1, 1}, false, menu.transparent)
	
	
	
	-- Experimental Faction Icons, not intended to be useable yet..
	local extensionSettings = GetAllExtensionSettings()
	if false then
	--if true or extensionSettings["utfactionlogos"].enabled or extensionSettings["utfactionlogos"].enabled then
		setup:addHeaderRow({ReadText(5554302, 1005)}, nil, {5})
		setup:addSimpleRow({ 
			-- Display Superior or Default Logo as first Item in this Row (selectable if Logo is useable)
			Helper.createButton(nil, Helper.createButtonIcon("faction_player"  , nil, 255, 255, 255, 100), false, true, 16, 0, 128, 128, nil, nil, nil, "Use Icon of Superior (or Playership)"),
			Helper.createButton(nil, Helper.createButtonIcon("faction_player_1", nil, 255, 255, 255, 100), false, true, 16, 0, 128, 128, nil, nil, nil, "NOT IMPLEMENTED YET - Set Icon"),
			Helper.createButton(nil, Helper.createButtonIcon("faction_player_2", nil, 255, 255, 255, 100), false, true, 16, 0, 128, 128, nil, nil, nil, "NOT IMPLEMENTED YET - Set Icon"),
			Helper.createButton(nil, Helper.createButtonIcon("faction_player_3", nil, 255, 255, 255, 100), false, true, 16, 0, 128, 128, nil, nil, nil, "NOT IMPLEMENTED YET - Set Icon"),
			Helper.createButton(nil, Helper.createButtonIcon("faction_player_4", nil, 255, 255, 255, 100), false, true, 16, 0, 128, 128, nil, nil, nil, "NOT IMPLEMENTED YET - Set Icon")
		}, nil, {1, 1, 1, 1, 1}, false, menu.transparent)
		setup:addSimpleRow({
			-- Display current Logo as first Item in this Row (not selectable)
			Helper.createButton(nil, Helper.createButtonIcon("faction_player"  , nil, 255, 255, 255, 100), false, true, 16, 32, 128, 128, nil, nil, nil, "Current Icon  just for Info"),
			Helper.createButton(nil, Helper.createButtonIcon("faction_player_5", nil, 255, 255, 255, 100), false, true, 16, 32, 128, 128, nil, nil, nil, "NOT IMPLEMENTED YET - Set Icon"),
			Helper.createButton(nil, Helper.createButtonIcon("faction_player_6", nil, 255, 255, 255, 100), false, true, 16, 32, 128, 128, nil, nil, nil, "NOT IMPLEMENTED YET - Set Icon"),
			Helper.createButton(nil, Helper.createButtonIcon("faction_player_7", nil, 255, 255, 255, 100), false, true, 16, 32, 128, 128, nil, nil, nil, "NOT IMPLEMENTED YET - Set Icon"),
			Helper.createButton(nil, Helper.createButtonIcon("faction_player_8", nil, 255, 255, 255, 100), false, true, 16, 32, 128, 128, nil, nil, nil, "NOT IMPLEMENTED YET - Set Icon")
		}, nil, {1, 1, 1, 1, 1}, false, menu.transparent)
	end
	
	local buttondesc = setup:createCustomWidthTable({160, 160, 160, 160, 160}, false, false, false, 2, 1, 0, 150)

	-- create tableview
	menu.infotable, menu.selecttable, menu.buttontable = Helper.displayThreeTableView(menu, infodesc, selectdesc, buttondesc, false)

	-- set scripts
	Helper.setEditBoxScript(menu, nil, menu.selecttable, 1, 1, menu.editboxUpdateText)
	Helper.setButtonScript(menu, nil, menu.buttontable, 1, 2, menu.buttonOK)
	Helper.setButtonScript(menu, nil, menu.buttontable, 1, 4, menu.buttonCancel)
	Helper.setButtonScript(menu, nil, menu.buttontable, 2, 1, menu.buttonRenameSubordinates) -- UniTrader new Button: Rename all Subordinates
	
	menu.activateEditBox = true

	-- clear descriptors again
	Helper.releaseDescriptors()
end

menu.updateInterval = 1.0

function menu.onUpdate()
	if menu.activateEditBox then
		menu.activateEditBox = nil
		Helper.activateEditBox(menu.selecttable, 1, 1)
	end
end

-- function menu.onRowChanged(row, rowdata)
-- end

function menu.onSelectElement()
end

function menu.onCloseElement(dueToClose)
	if dueToClose == "close" then
		Helper.closeMenuAndCancel(menu)
		menu.cleanup()
	else
		Helper.closeMenuAndReturn(menu)
		menu.cleanup()
	end
end

init()
