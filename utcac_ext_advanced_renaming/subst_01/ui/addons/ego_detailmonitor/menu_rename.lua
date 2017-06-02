
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

function menu.cleanup()
	menu.title = nil
	menu.object = nil

	menu.infotable = nil
	menu.selecttable = nil

	menu.renamesubordinates = nil --UniTrader change: add script-local bool to indicate that Subordinates should be renamed rather than the Ship itself
	menu.keymod = nil -- Modifier for Caps and Shift on InGame-Keyboard
end

-- Menu member functions

function menu.editboxUpdateText(_, text, textchanged)
	-- UniTrader change: Mass renaming function added
	if menu.renamesubordinates then
		if menu.renamesubordinates == "all" then
			SignalObject(GetComponentData(menu.object, "galaxyid" ) , "Subordinates Name Updated" , menu.object , text )
		elseif menu.renamesubordinates == "bigships" then
			SignalObject(GetComponentData(menu.object, "galaxyid" ) , "Subordinates Name Updated - bigships" , menu.object , text )
		elseif menu.renamesubordinates == "smallships" then
			SignalObject(GetComponentData(menu.object, "galaxyid" ) , "Subordinates Name Updated - smallships" , menu.object , text )
		end
	-- Renaming Function - now always renaming to force an update if needed
	elseif menu.controlentity then
		SetNPCBlackboard(menu.controlentity, "$unformatted_object_name" , text)
		SignalObject(GetComponentData(menu.object, "galaxyid" ) , "Object Name Updated" , menu.object )
	-- UniTrader Changes end (next line was a if before, but i have some diffrent conditions)
	elseif textchanged then
		SetComponentName(menu.object, text)
	end
	Helper.closeMenuAndReturn(menu)
	menu.cleanup()
end

function menu.buttonOK()
	Helper.confirmEditBoxInput(menu.selecttable, 1, 1)
end

-- UniTrader new Functions: Mass Rename Subordinates
function menu.buttonRenameSubordinates()
	menu.renamesubordinates = "all"
	Helper.confirmEditBoxInput(menu.selecttable, 1, 1)
end
function menu.buttonRenameSubordinatesBigShips()
	menu.renamesubordinates = "bigships"
	Helper.confirmEditBoxInput(menu.selecttable, 1, 1)
end
function menu.buttonRenameSubordinatesSmallShips()
	menu.renamesubordinates = "smallships"
	Helper.confirmEditBoxInput(menu.selecttable, 1, 1)
end
-- Functions for Keyboard
function menu.TypeText(text)
  TypeInEditBox(menu.selecttable, 1, 1,text)
end
function menu.SetKeyMod(mod)
   if mod == "1" then
     --toggle Shift
	 if menu.keymod & 1 then
	   menu.keymod = menu.keymod - 1
       SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 510), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 9, 1)
	 else
	   menu.keymod = menu.keymod + 1
       SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 511), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 9, 1)
  elseif mod == "2" then
    --toggle Alt
	 if menu.keymod & 2 then
	   menu.keymod = menu.keymod - 2
       SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 520), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 9, 2)
	 else
	   menu.keymod = menu.keymod + 2
       SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 521), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 9, 2)
  elseif mod == "4" then
    --toggle Super
	 if menu.keymod & 4 then
	   menu.keymod = menu.keymod - 4
       SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 540), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 9, 4)
	 else
	   menu.keymod = menu.keymod + 4
       SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 541), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 9, 4)
  end
  -- Update displayed Characters
  -- Number Row
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 110+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 5, 1)
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 120+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 5, 2)
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 130+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 5, 3)
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 140+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 5, 4)
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 150+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 5, 5)
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 160+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 5, 6)
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 170+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 5, 7)
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 180+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 5, 8)
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 190+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 5, 9)
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 100+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 5, 10)
  -- Top Row
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 210+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 6, 1)
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 220+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 6, 2)
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 230+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 6, 3)
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 240+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 6, 4)
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 250+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 6, 5)
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 260+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 6, 6)
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 270+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 6, 7)
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 280+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 6, 8)
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 290+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 6, 9)
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 200+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 6, 10)
  -- Middle Row
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 310+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 7, 1)
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 320+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 7, 2)
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 330+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 7, 3)
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 340+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 7, 4)
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 350+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 7, 5)
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 360+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 7, 6)
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 370+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 7, 7)
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 380+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 7, 8)
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 390+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 7, 9)
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 300+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 7, 10)
  -- Bottom Row
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 410+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 8, 1)
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 420+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 8, 2)
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 430+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 8, 3)
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 440+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 8, 4)
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 450+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 8, 5)
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 460+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 8, 6)
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 470+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 8, 7)
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 480+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 8, 8)
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 490+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 8, 9)
  SetCellContent(menu.buttontable,Helper.createButton(Helper.createButtonText(ReadText(5554303, 400+menu.keymod), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25) , 8, 10)
end
-- UniTrader new Functions: Logo Setting (currently same as Cancel Menu)
function menu.buttonSetLogoFromSuperior()
	Helper.cancelEditBoxInput(menu.selecttable, 1, 1)
	Helper.closeMenuAndReturn(menu)
	menu.cleanup()
end
function menu.buttonSetLogoCurrent()
	Helper.cancelEditBoxInput(menu.selecttable, 1, 1)
	Helper.closeMenuAndReturn(menu)
	menu.cleanup()
end
function menu.buttonSetLogoPlayer_1()
	Helper.cancelEditBoxInput(menu.selecttable, 1, 1)
	Helper.closeMenuAndReturn(menu)
	menu.cleanup()
end
function menu.buttonSetLogoPlayer_2()
	Helper.cancelEditBoxInput(menu.selecttable, 1, 1)
	Helper.closeMenuAndReturn(menu)
	menu.cleanup()
end
function menu.buttonSetLogoPlayer_3()
	Helper.cancelEditBoxInput(menu.selecttable, 1, 1)
	Helper.closeMenuAndReturn(menu)
	menu.cleanup()
end
function menu.buttonSetLogoPlayer_4()
	Helper.cancelEditBoxInput(menu.selecttable, 1, 1)
	Helper.closeMenuAndReturn(menu)
	menu.cleanup()
end
function menu.buttonSetLogoPlayer_5()
	Helper.cancelEditBoxInput(menu.selecttable, 1, 1)
	Helper.closeMenuAndReturn(menu)
	menu.cleanup()
end
function menu.buttonSetLogoPlayer_6()
	Helper.cancelEditBoxInput(menu.selecttable, 1, 1)
	Helper.closeMenuAndReturn(menu)
	menu.cleanup()
end
function menu.buttonSetLogoPlayer_7()
	Helper.cancelEditBoxInput(menu.selecttable, 1, 1)
	Helper.closeMenuAndReturn(menu)
	menu.cleanup()
end
function menu.buttonSetLogoPlayer_8()
	Helper.cancelEditBoxInput(menu.selecttable, 1, 1)
	Helper.closeMenuAndReturn(menu)
	menu.cleanup()
end
-- UniTrader new Functions end

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
    menu.controlentity = GetControlEntity(menu.object, "manager") or GetComponentData(menu.object, "controlentity") or ( ( menu.object == GetPlayerPrimaryShipID() ) and GetPlayerEntityID() ) -- last is for playership
	local displayname, name, objectowner = GetComponentData(menu.object, "name", "name", "owner")
	if menu.controlentity and GetNPCBlackboard(menu.controlentity, "$unformatted_object_name") then
		name = GetNPCBlackboard(menu.controlentity, "$unformatted_object_name")
	end
	if container then
		menu.title = GetComponentData(container, "name") .. " - " .. (name ~= "" and displayname or ReadText(1001, 56))
	else
		menu.title = (name ~= "" and displayname or ReadText(1001, 56))
	end
	
	menu.keymod = 0
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
	}, nil, {2, 2, 2, 2, 2}, false, menu.transparent)
	
	-- Mass Renaming Functions
	setup:addSimpleRow({ReadText(5554302, 1001),Helper.getEmptyCellDescriptor()}, nil, {3, 2})
	setup:addSimpleRow({ 
		Helper.createButton(Helper.createButtonText(ReadText(5554302, 1002), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25, nil, nil, nil, ReadText(5554302, 1003)),
		Helper.createButton(Helper.createButtonText(ReadText(5554302, 1004), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25, nil, nil, nil, ReadText(5554302, 1005)),
		Helper.createButton(Helper.createButtonText(ReadText(5554302, 1006), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25, nil, nil, nil, ReadText(5554302, 1007)),
		Helper.getEmptyCellDescriptor(),
		Helper.getEmptyCellDescriptor()
	}, nil, {2, 2, 2, 2, 2}, false, menu.transparent)
	
	-- Keyboard
	setup:addSimpleRow({"Keyboard"}, nil, {10})
	-- Numbeer Row
	setup:addSimpleRow({ 
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 110), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 120), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 130), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 140), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 150), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 160), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 170), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 180), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 190), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 100), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25)
	}, nil, {1, 1, 1, 1, 1, 1, 1, 1, 1, 1}, false, menu.transparent)
	-- Top Row
	setup:addSimpleRow({ 
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 210), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 220), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 230), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 240), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 250), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 260), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 270), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 280), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 290), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 200), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25)
	}, nil, {1, 1, 1, 1, 1, 1, 1, 1, 1, 1}, false, menu.transparent)
	-- Middle Row
	setup:addSimpleRow({ 
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 310), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 320), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 330), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 340), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 350), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 360), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 370), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 380), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 390), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 300), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25)
	}, nil, {1, 1, 1, 1, 1, 1, 1, 1, 1, 1}, false, menu.transparent)
	-- Bottom Row
	setup:addSimpleRow({ 
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 410), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 420), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 430), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 440), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 450), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 460), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 470), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 480), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 490), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 400), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25)
	}, nil, {1, 1, 1, 1, 1, 1, 1, 1, 1, 1}, false, menu.transparent)
	-- Function Row
	setup:addSimpleRow({ 
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 510), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 520), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 530), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 540), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
		Helper.createButton(Helper.createButtonText(ReadText(5554303, 550), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 160, 25),
	}, nil, {2,2,2,2,2}, false, menu.transparent)
	
	-- Expressions Help - Static Info Text
	if ( ReadText(5554302, 6) == "All" ) or ( ReadText(5554302, 6) == "Static" ) then
		setup:addSimpleRow({Helper.getEmptyCellDescriptor()}, nil, {10})
		setup:addHeaderRow({ReadText(5554302, 1100)}, nil, {10})
		setup:addSimpleRow({ReadText(5554302, 1101)}, nil, {10})
		setup:addSimpleRow({ReadText(5554302, 1102)}, nil, {10})
		setup:addSimpleRow({ReadText(5554302, 1103)}, nil, {10})
		setup:addSimpleRow({ReadText(5554302, 1104)}, nil, {10})
		setup:addSimpleRow({ReadText(5554302, 1105)}, nil, {10})
		setup:addSimpleRow({ReadText(5554302, 1106)}, nil, {10})
		setup:addSimpleRow({ReadText(5554302, 1107)}, nil, {10})
		setup:addSimpleRow({ReadText(5554302, 1108)}, nil, {10})
		setup:addSimpleRow({ReadText(5554302, 1109)}, nil, {10})
		setup:addSimpleRow({ReadText(5554302, 1110)}, nil, {10})
	end
	-- Expressions Help - Script-Defined Expressions Overview
	local namereplacement =  GetNPCBlackboard(menu.controlentity, "$namereplacement")
	if ( ( ReadText(5554302, 6) == "All" ) and namereplacement ) or ( ReadText(5554302, 6) == "Script" ) then
		setup:addSimpleRow({Helper.getEmptyCellDescriptor()}, nil, {10})
		setup:addSimpleRow({ReadText(5554302, 1111),ReadText(5554302, 1112)}, nil, {3,2})
		if namereplacement and table.getn(namereplacement) then
			local key1 = nil
			local value1 = nil
			local key2 = nil
			local value2 = nil
			for key,value in pairs(namereplacement) do
				if key1 and key2 then
					setup:addSimpleRow({Helper.createButton(Helper.createButtonText("$"..key1, "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 266, 25, nil, nil, nil, value1),Helper.createButton(Helper.createButtonText("$"..key2, "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 106, 0, 266, 25, nil, nil, nil, value2),Helper.createButton(Helper.createButtonText("$"..key, "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 212, 0, 266, 25, nil, nil, nil, value)}, nil, {1,1,3})
					key1 = nil
					value1 = nil
					key2 = nil
					value2 = nil
				elseif key1 then
					key2 = key
					value2 = value
				else
					key1 = key
					value1 = value
				end
			end
			if key1 and key2 then
				setup:addSimpleRow({Helper.createButton(Helper.createButtonText("$"..key1, "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 266, 25, nil, nil, nil, value1),Helper.createButton(Helper.createButtonText("$"..key2, "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 106, 0, 266, 25, nil, nil, nil, value2),Helper.getEmptyCellDescriptor()}, nil, {1,1,3})
				key1 = nil
				value1 = nil
				key2 = nil
				value2 = nil
			elseif key1 then
				setup:addSimpleRow({Helper.createButton(Helper.createButtonText("$"..key1, "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 266, 25, nil, nil, nil, value1),Helper.getEmptyCellDescriptor()}, nil, {1,4})
				key1 = nil
				value1 = nil
			end
		end
	end
	
	-- Experimental Faction Icons, not intended to be useable yet..
	local extensionSettings = GetAllExtensionSettings()
	if false and ( extensionSettings["utfactionlogos"].enabled or extensionSettings["ws_329415910"].enabled ) and extensionSettings["utcac_ext_advanced_renaming_user"].enabled then
		setup:addHeaderRow({ReadText(5554302, 1008)}, nil, {10})
		setup:addSimpleRow({ 
			-- Display Superior or Default Logo as first Item in this Row (selectable if Logo is useable)
			Helper.createButton(nil, Helper.createButtonIcon("faction_player"  , nil, 255, 255, 255, 100), false, true, 16, 0, 128, 128, nil, nil, nil, ReadText(5554302, 1009)),
			Helper.createButton(nil, Helper.createButtonIcon("faction_player_1", nil, 255, 255, 255, 100), false, true, 16, 0, 128, 128, nil, nil, nil, "NOT IMPLEMENTED YET - Set Icon"),
			Helper.createButton(nil, Helper.createButtonIcon("faction_player_2", nil, 255, 255, 255, 100), false, true, 16, 0, 128, 128, nil, nil, nil, "NOT IMPLEMENTED YET - Set Icon"),
			Helper.createButton(nil, Helper.createButtonIcon("faction_player_3", nil, 255, 255, 255, 100), false, true, 16, 0, 128, 128, nil, nil, nil, "NOT IMPLEMENTED YET - Set Icon"),
			Helper.createButton(nil, Helper.createButtonIcon("faction_player_4", nil, 255, 255, 255, 100), false, true, 16, 0, 128, 128, nil, nil, nil, "NOT IMPLEMENTED YET - Set Icon")
		}, nil, {1, 1, 1, 1, 1}, false, menu.transparent)
		setup:addSimpleRow({
			-- Display current Logo as first Item in this Row (not selectable)
			Helper.createButton(nil, Helper.createButtonIcon("faction_player"  , nil, 255, 255, 255, 100), false, true, 16, 32, 128, 128, nil, nil, nil, ReadText(5554302, 1010)),
			Helper.createButton(nil, Helper.createButtonIcon("faction_player_5", nil, 255, 255, 255, 100), false, true, 16, 32, 128, 128, nil, nil, nil, "NOT IMPLEMENTED YET - Set Icon"),
			Helper.createButton(nil, Helper.createButtonIcon("faction_player_6", nil, 255, 255, 255, 100), false, true, 16, 32, 128, 128, nil, nil, nil, "NOT IMPLEMENTED YET - Set Icon"),
			Helper.createButton(nil, Helper.createButtonIcon("faction_player_7", nil, 255, 255, 255, 100), false, true, 16, 32, 128, 128, nil, nil, nil, "NOT IMPLEMENTED YET - Set Icon"),
			Helper.createButton(nil, Helper.createButtonIcon("faction_player_8", nil, 255, 255, 255, 100), false, true, 16, 32, 128, 128, nil, nil, nil, "NOT IMPLEMENTED YET - Set Icon")
		}, nil, {1, 1, 1, 1, 1}, false, menu.transparent)
	end
	
	local buttondesc = setup:createCustomWidthTable({80, 80, 80, 80, 80, 80, 80, 80, 80, 80}, false, false, false, 2, 1, 0, 150)

	-- create tableview
	menu.infotable, menu.selecttable, menu.buttontable = Helper.displayThreeTableView(menu, infodesc, selectdesc, buttondesc, false)

	-- set scripts
	Helper.setEditBoxScript(menu, nil, menu.selecttable, 1, 1, menu.editboxUpdateText)
	Helper.setButtonScript(menu, nil, menu.buttontable, 1, 3, menu.buttonOK)
	Helper.setButtonScript(menu, nil, menu.buttontable, 1, 7, menu.buttonCancel)
  -- New Buttons by UniTrader
	Helper.setButtonScript(menu, nil, menu.buttontable, 3, 1, menu.buttonRenameSubordinates)
	Helper.setButtonScript(menu, nil, menu.buttontable, 3, 2, menu.buttonRenameSubordinatesBigShips)
	Helper.setButtonScript(menu, nil, menu.buttontable, 3, 3, menu.buttonRenameSubordinatesSmallShips)
	-- Experimental Keyboard Buttons
	--  Number Row
	Helper.setButtonScript(menu, nil, menu.buttontable, 5, 1, function () return TypeInEditBox(nil,ReadText(5554303, 110+menu.keymod)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 5, 2, function () return TypeInEditBox(nil,ReadText(5554303, 120+menu.keymod)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 5, 3, function () return TypeInEditBox(nil,ReadText(5554303, 130+menu.keymod)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 5, 4, function () return TypeInEditBox(nil,ReadText(5554303, 140+menu.keymod)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 5, 5, function () return TypeInEditBox(nil,ReadText(5554303, 150+menu.keymod)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 5, 6, function () return TypeInEditBox(nil,ReadText(5554303, 160+menu.keymod)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 5, 7, function () return TypeInEditBox(nil,ReadText(5554303, 170+menu.keymod)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 5, 8, function () return TypeInEditBox(nil,ReadText(5554303, 180+menu.keymod)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 5, 9, function () return TypeInEditBox(nil,ReadText(5554303, 190+menu.keymod)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 5, 0, function () return TypeInEditBox(nil,ReadText(5554303, 100+menu.keymod)) end)
	--  Top Row
	Helper.setButtonScript(menu, nil, menu.buttontable, 6, 1, function () return TypeInEditBox(nil,ReadText(5554303, 210+menu.keymod)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 6, 2, function () return TypeInEditBox(nil,ReadText(5554303, 220+menu.keymod)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 6, 3, function () return TypeInEditBox(nil,ReadText(5554303, 230+menu.keymod)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 6, 4, function () return TypeInEditBox(nil,ReadText(5554303, 240+menu.keymod)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 6, 5, function () return TypeInEditBox(nil,ReadText(5554303, 250+menu.keymod)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 6, 6, function () return TypeInEditBox(nil,ReadText(5554303, 260+menu.keymod)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 6, 7, function () return TypeInEditBox(nil,ReadText(5554303, 270+menu.keymod)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 6, 8, function () return TypeInEditBox(nil,ReadText(5554303, 280+menu.keymod)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 6, 9, function () return TypeInEditBox(nil,ReadText(5554303, 290+menu.keymod)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 6, 0, function () return TypeInEditBox(nil,ReadText(5554303, 200+menu.keymod)) end)
	--  Middle Row
	Helper.setButtonScript(menu, nil, menu.buttontable, 7, 1, function () return TypeInEditBox(nil,ReadText(5554303, 310+menu.keymod)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 7, 2, function () return TypeInEditBox(nil,ReadText(5554303, 320+menu.keymod)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 7, 3, function () return TypeInEditBox(nil,ReadText(5554303, 330+menu.keymod)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 7, 4, function () return TypeInEditBox(nil,ReadText(5554303, 340+menu.keymod)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 7, 5, function () return TypeInEditBox(nil,ReadText(5554303, 350+menu.keymod)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 7, 6, function () return TypeInEditBox(nil,ReadText(5554303, 360+menu.keymod)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 7, 7, function () return TypeInEditBox(nil,ReadText(5554303, 370+menu.keymod)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 7, 8, function () return TypeInEditBox(nil,ReadText(5554303, 380+menu.keymod)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 7, 9, function () return TypeInEditBox(nil,ReadText(5554303, 390+menu.keymod)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 7, 0, function () return TypeInEditBox(nil,ReadText(5554303, 300+menu.keymod)) end)
	--  Bottom Row
	Helper.setButtonScript(menu, nil, menu.buttontable, 8, 1, function () return TypeInEditBox(nil,ReadText(5554303, 410+menu.keymod)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 8, 2, function () return TypeInEditBox(nil,ReadText(5554303, 420+menu.keymod)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 8, 3, function () return TypeInEditBox(nil,ReadText(5554303, 430+menu.keymod)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 8, 4, function () return TypeInEditBox(nil,ReadText(5554303, 440+menu.keymod)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 8, 5, function () return TypeInEditBox(nil,ReadText(5554303, 450+menu.keymod)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 8, 6, function () return TypeInEditBox(nil,ReadText(5554303, 460+menu.keymod)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 8, 7, function () return TypeInEditBox(nil,ReadText(5554303, 470+menu.keymod)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 8, 8, function () return TypeInEditBox(nil,ReadText(5554303, 480+menu.keymod)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 8, 9, function () return TypeInEditBox(nil,ReadText(5554303, 490+menu.keymod)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 8, 0, function () return TypeInEditBox(nil,ReadText(5554303, 400+menu.keymod)) end)
	--  Function Row
	Helper.setButtonScript(menu, nil, menu.buttontable, 9, 1, function () return TypeInEditBox(nil,ReadText(5554303, 110)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 9, 3, function () return TypeInEditBox(nil,ReadText(5554303, 120)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 9, 5, function () return TypeInEditBox(nil,ReadText(5554303, 130)) end)
	--Helper.setButtonScript(menu, nil, menu.buttontable, 9, 7, function () return TypeInEditBox(nil,ReadText(5554303, 140)) end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 9, 9, function () return TypeInEditBox(nil,"\8")end)
  
	if false and ( extensionSettings["utfactionlogos"].enabled or extensionSettings["ws_329415910"].enabled ) and extensionSettings["utcac_ext_advanced_renaming_user"].enabled then
		Helper.setButtonScript(menu, nil, menu.buttontable, 4, 1, menu.buttonSetLogoFromSuperior)
		Helper.setButtonScript(menu, nil, menu.buttontable, 5, 1, menu.buttonSetLogoCurrent)
		Helper.setButtonScript(menu, nil, menu.buttontable, 4, 2, menu.buttonSetLogoPlayer_1)
		Helper.setButtonScript(menu, nil, menu.buttontable, 4, 3, menu.buttonSetLogoPlayer_2)
		Helper.setButtonScript(menu, nil, menu.buttontable, 4, 4, menu.buttonSetLogoPlayer_3)
		Helper.setButtonScript(menu, nil, menu.buttontable, 4, 5, menu.buttonSetLogoPlayer_4)
		Helper.setButtonScript(menu, nil, menu.buttontable, 5, 2, menu.buttonSetLogoPlayer_5)
		Helper.setButtonScript(menu, nil, menu.buttontable, 5, 3, menu.buttonSetLogoPlayer_6)
		Helper.setButtonScript(menu, nil, menu.buttontable, 5, 4, menu.buttonSetLogoPlayer_7)
		Helper.setButtonScript(menu, nil, menu.buttontable, 5, 5, menu.buttonSetLogoPlayer_8)
	end
	-- End New Buttons by UniTrader
	
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
