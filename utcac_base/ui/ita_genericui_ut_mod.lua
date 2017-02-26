
-- Generic UI Script by Itaros. By using this you are bound to keep credit
-- and send vegan pancakes my way every time you copy it.
-- But, honestly, why do you need to copy it? It is from a LIBRARY mod already.
-- If you have special needs it would be faster to contact me directly instead of fiddling with this ^_^
-- Modifications to the script shall be marked correspondingly.
-- Modification of this line and lines above is forbidden.

-- You break it - you buy another copy of a game for everyone affected lol!

-- Extensions/Changes by UniTrader (parameter-Incompatible with Itaros' Version and therefore using another Name)
-- 
-- => Option to define up to 4 Buttons to the bottom of the Menu (including freely defineable position of back button)
-- => Up to two Quickselect Buttons per Entry, defined per-entry 
-- => 
-- 
-- Thanks for the excellent Template to base this on, Itaros.
-- Sorry it took me so long to finally make use of it, but i was busy with other stuff.

-- New Param Structure (Planned, NYI):
-- param == { 0, 0, title(string), instruction_text(string), [selector_rules,..], button_1_text(string), button_1_section(string), button_2_text(string), button_2_section(string), button_3_text(string), button_3_section(string), button_4_text(string), button_4_section(string)}
-- selector_rules format: [localid(integer),isNotDummy(bool)(NIY, must be true), usertext(string), payload(userdata)?, button_A_text(string), button_A_section(string),button_B_text(string), button_B_section(string)]]
-- button_*_text defines the availability of a bottom Button (not available if null), button_*_section defines its target Section (return if null)

-- param == { 0, 0, [selector_rules,..], operation_mode(integer), title(string), success_subsection(string), instruction_text(string)}
-- selector_rules format: [localid(integer),isNotDummy(bool)(NIY, must be true), usertext(string), payload(userdata)?, [deplist(integer, integer,...)]?(NIY, must be nil)]
-- Operation Modes:
--  *Select One, Native = 0
--  *Select One, Local = 1
--  *Select Multiple, Native = 2(NIY)
--  *Dummy Data Info = 4(NIY)
-- Properties marked with ? can be nil

-- Example:
--		<open_conversation_menu menu="ita_genericui" param="[0,0,[[1, true, 'Option 1', 'retr 1', null],[2, true, 'Option 2', 'retr 2', null] ], 0, 'Generic UI', 'comm_architect_someway']" />
--		<add_conversation_view view="closeupdetailmonitor" />   	

-- Oh my, too much docs... To the deal ->

local menu = {
	name = "ita_genericui_ut_mod",
	defaultColor = { r = 255, g = 255, b = 255, a = 100 },
	availColor = { r = 0, g = 192, b = 0, a = 100 },
	buildingColor = { r = 192, g = 192, b = 0, a = 100 },
	textwidth = 632,
	fullwidth = 792,
	transparent = { r = 0, g = 0, b = 0, a = 0 },
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
	menu.data = nil
	-- I am so smart... 
	-- I wonder if it will leak memory, but by default I assume egosoft made a good job ^_^
end

function menu.fetch()
	menu.data = {}
	menu.data.entries = {}
	menu.data.mode = false -- not used by me, or at least in a diffrent way. Will be removed when Script is cleaned.
	-- Title and instructions
	menu.data.title = menu.param[3]
	menu.data.instruction_text = menu.param[4]
	-- Menu Entries
	local dataset_selector = menu.param[5]
	--Should be proper tables. If moddev is not good enough to follow instructions I can't get better.
	menu.data.entries = dataset_selector
	--Buttons
	menu.data.button_1_text = menu.param[6]
	menu.data.button_1_section = menu.param[7]
	menu.data.button_2_text = menu.param[8]
	menu.data.button_2_section = menu.param[9]
	menu.data.button_3_text = menu.param[10]
	menu.data.button_3_section = menu.param[11]
	menu.data.button_4_text = menu.param[12]
	menu.data.button_4_section = menu.param[13]
	
	menu.data.subsection = "TO BE REPLACED"
	if menu.data.instruction_text == nil then menu.data.instruction_text = "" end
end

function menu.onShowMenu()

	--FETCHING
	menu.fetch()
	--UI DATA
	menu.title = menu.data.title
	--TOP
	local setup = Helper.createTableSetup(menu)
	setup:addTitleRow({
		Helper.createFontString(menu.title, false, "left", 255, 255, 255, 100, Helper.headerRow1Font, Helper.headerRow1FontSize, false, Helper.headerRow1Offsetx, Helper.headerRow1Offsety, Helper.headerRow1Height, Helper.headerRow1Width)
	}, nil, {2})
	setup:addTitleRow({ 
		Helper.createFontString(menu.data.instruction_text, false, "left", 129, 160, 182, 100, Helper.headerRow2Font, Helper.headerRow2FontSize, false, Helper.headerRow2Offsetx, Helper.headerRow2Offsety, Helper.headerRow2Height, Helper.headerRow1Width)	-- text depends on selection
	}, nil, {2})
	local topdesc = setup:createCustomWidthTable({ 0, Helper.scaleX(Helper.e_IconEntrySize) + 37 }, false, true)
	--MIDDLE(DATA)
	setup = Helper.createTableSetup(menu)
	local descriptionTableHeight = Helper.e_FigureHeight + 30 -- Helper.headerRow2Height
	for _,v in ipairs(menu.data.entries) do
		if ( v[5] and v[6] and v[7] and v[8] ) then
			local buttonA = Helper.createButton(Helper.createButtonText(v[5], "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 150, 25, nil, nil, nil, nil)
			local buttonB = Helper.createButton(Helper.createButtonText(v[7], "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 150, 25, nil, nil, nil, nil)
			setup:addSimpleRow({v[3], buttonA, buttonB}, v, {1,1,1})
		elseif ( v[5] and v[6] ) then
			local buttonA = Helper.createButton(Helper.createButtonText(v[5], "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 150, 25, nil, nil, nil, nil)
			setup:addSimpleRow({v[3], buttonA}, v, {2,1})
		elseif ( v[7] and v[8] ) then
			local buttonA = Helper.createButton(Helper.createButtonText(v[7], "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 150, 25, nil, nil, nil, nil)
			setup:addSimpleRow({v[3], buttonA}, v, {2,1})
		else
			setup:addSimpleRow({v[3]}, v, {3})
		end
		--setup:addSimpleRow({v}, v, {3})
		--	  OP MODE: Select One, Local
		--	local selectThisLocalBtn = Helper.createButton(Helper.createButtonText(ReadText(455600, 12), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 150, 25, nil, nil, nil, nil)
		--	setup:addSimpleRow({v[3], selectThisLocalBtn}, v, {2,1})
	end
	local middesc = setup:createCustomWidthTable({789, 200 , 200}, false, true, true, 1, 0, 0, Helper.tableOffsety - Helper.headerRow2Height/2 + Helper.headerRow2Offsetx, 445)--{Helper.e_DescWidth}
	--BOTTOM
	setup = Helper.createTableSetup(menu)
	local button1entry
	local button2entry
	local button3entry
	local button4entry
	if menu.data.button_1_text then 
		button1entry = Helper.createButton(Helper.createButtonText(menu.data.button_1_text, "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_B", true), nil, nil)
	else button1entry = Helper.getEmptyCellDescriptor() end
	if menu.data.button_2_text then 
		button2entry = Helper.createButton(Helper.createButtonText(menu.data.button_2_text, "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_BACK", true), nil, nil)
	else button2entry = Helper.getEmptyCellDescriptor() end
	if menu.data.button_3_text then 
		button3entry = Helper.createButton(Helper.createButtonText(menu.data.button_3_text, "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_Y", true), nil, nil)
	else button3entry = Helper.getEmptyCellDescriptor() end
	if menu.data.button_4_text then 
		button4entry = Helper.createButton(Helper.createButtonText(menu.data.button_4_text, "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_X", true), nil, nil)
	else button4entry = Helper.getEmptyCellDescriptor() end
	
	setup:addSimpleRow({ 
		Helper.getEmptyCellDescriptor(),
		button1entry,
		Helper.getEmptyCellDescriptor(),
		button2entry,
		Helper.getEmptyCellDescriptor(),
		button3entry,
		Helper.getEmptyCellDescriptor(),
		button4entry,
		Helper.getEmptyCellDescriptor()
	}, nil, nil, false, menu.transparent)
	local bottomdesc = setup:createCustomWidthTable({48, 150, 48, 150, 48, 150, 48, 150, 48}, false, false, true, 2, 1, 0, 550, 0, false)
	--COMMIT
	menu.toptable, menu.midtable, menu.bottomtable = Helper.displayThreeTableView(menu, topdesc, middesc, bottomdesc, false)
	--BUTTONS
	for i,v in ipairs(menu.data.entries) do
		if v[4] and v[5] and v[6] and v[7] then
			Helper.setButtonScript(menu, nil, menu.midtable, i, 2, function () return menu.buttonSelectLocal(v[5],v[1]) end)
			Helper.setButtonScript(menu, nil, menu.midtable, i, 3, function () return menu.buttonSelectLocal(v[7],v[1]) end)
		elseif v[4] and v[5] then
			Helper.setButtonScript(menu, nil, menu.midtable, i, 3, function () return menu.buttonSelectLocal(v[5],v[1]) end)
		elseif v[6] and v[7] then
			Helper.setButtonScript(menu, nil, menu.midtable, i, 3, function () return menu.buttonSelectLocal(v[7],v[1]) end)
		else
--			PANIC!!!
		end
	end
	Helper.setButtonScript(menu, nil, menu.bottomtable, 1, 2, menu.button1)
	Helper.setButtonScript(menu, nil, menu.bottomtable, 1, 4, menu.button2)
	Helper.setButtonScript(menu, nil, menu.bottomtable, 1, 6, menu.button3)
	Helper.setButtonScript(menu, nil, menu.bottomtable, 1, 8, menu.button4)
	
--	   Dynamic per-Entry button template
--		for i,v in ipairs(menu.data.entries) do
--			Helper.setButtonScript(menu, nil, menu.midtable, i, 3, function () return menu.buttonSelectLocal(v) end)
--		end
	
	--FINALIZE
	Helper.releaseDescriptors()
end

--menu.updateInterval = 5.0

function menu.buttonSelectLocal(section,param)
	Helper.closeMenuForSubSection(menu, false, section, param)
end

function menu.buttonOK()
	if menu.rowDataMap[Helper.currentDefaultTableRow] then
		local selection = menu.rowDataMap[Helper.currentDefaultTableRow]
		Helper.closeMenuForSubSection(menu, false, menu.data.subsection, selection[4])
	end
end

function menu.button1()
	if menu.rowDataMap[Helper.currentDefaultTableRow] then
		local selection = menu.rowDataMap[Helper.currentDefaultTableRow]
		Helper.closeMenuForSubSection(menu, false, menu.data.button_1_section, selection[4])
	end
	if menu.data.button_1_section == nil then
	    menu.onCloseElement("back")
	end
end

function menu.button2()
	if menu.rowDataMap[Helper.currentDefaultTableRow] then
		local selection = menu.rowDataMap[Helper.currentDefaultTableRow]
		Helper.closeMenuForSubSection(menu, false, menu.data.button_2_section, selection[4])
	end
	if menu.data.button_2_section == nil then
	    menu.onCloseElement("back")
	end
end

function menu.button3()
	if menu.rowDataMap[Helper.currentDefaultTableRow] then
		local selection = menu.rowDataMap[Helper.currentDefaultTableRow]
		Helper.closeMenuForSubSection(menu, false, menu.data.button_3_section, selection[4])
	end
	if menu.data.button_3_section == nil then
	    menu.onCloseElement("back")
	end
end

function menu.button4()
	if menu.rowDataMap[Helper.currentDefaultTableRow] then
		local selection = menu.rowDataMap[Helper.currentDefaultTableRow]
		Helper.closeMenuForSubSection(menu, false, menu.data.button_4_section, selection[4])
	end
	if menu.data.button_4_section == nil then
	    menu.onCloseElement("back")
	end
end

function menu.onRowChanged(row, rowdata)
end

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