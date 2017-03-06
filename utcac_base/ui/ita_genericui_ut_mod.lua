
-- Generic UI Script by Itaros. By using this you are bound to keep credit
-- and send vegan pancakes my way every time you copy it.
-- But, honestly, why do you need to copy it? It is from a LIBRARY mod already.
-- If you have special needs it would be faster to contact me directly instead of fiddling with this ^_^
-- Modifications to the script shall be marked correspondingly.
-- Modification of this line and lines above is forbidden.

-- You break it - you buy another copy of a game for everyone affected lol!

-- Extensions/Changes by UniTrader (parameter-Incompatible with Itaros' Version and therefore using another Name)



---------------------------------------------------------------
-- New Param Structure (Planned, NYI):
-- Multi-line for better overview:
-- param == { 0, 0, 'title', 'instruction_text', {special_function} or null ,
-- preselected_line, {midtable_column_sizes} ,
-- { { { line_properties_A } , {cell_A1} , {cell_A2} , ... } ,
--   { { line_properties_B } , {cell_B1} , {cell_B2} , ... } ,
--   ... },
-- { {cell_bottom1} , {cell_bottom2} , {cell_bottom3} , {cell_bottom4} }
--
-- Special Functions:
-- nil -- nothing
-- {'editbox','initialtext'} 
-- {'scrollbar',min_display_value,min_possible_value,initial_value,max_possible_value,max_display_value[,step_value]}
-- 
-- Line Properties:
-- First Entry is the Type as String, the next Entries depend on its Type:
-- { 'header' , {combined_cells} }
-- { 'regular' , {combined_cells} [,section [,param [,keepvisible [,notsubsection ]]]] }
-- { 'nonselectable' , {combined_cells} }
-- { 'invisible' , {combined_cells} }
--
-- Cell definition:
-- First Entry is the Type as String, the next Entries depend on its Type:
-- { 'text' , 'Text' }
-- { 'button' , 'button text' [,'next_section' [ ,hotkey  [, selectable [,param [,keepvisible [,notsubsection]]]] ]] }
-- { 'statusbar' , fillpercent , red , green , blue , alpha }
--
-- Note: Priority of passed Values for Buttons: Self > Editbox/scrollbar > Selected Line
-- Note2: Omited next section means a return to previous Section (as in a back button)
--
--
--------------------------------------------------------------------------------------------------------

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
	
	DebugError("Menu Fetch:")
	
-- Menu in general
	menu.data.title = menu.param[3]
	menu.data.instruction_text = menu.param[4]
	if menu.data.instruction_text == nil then menu.data.instruction_text = "" end
	menu.data.special_function = menu.param[5]
	
	DebugError("Title: "..(menu.data.title or "nil").." Info: "..(menu.data.instruction_text or "nil").." Special: "..(print(menu.data.special_function) or "nil"))
	
-- Mid-Section definition
	menu.data.preselected_line = menu.param[6]
	menu.data.midtable_column_sizes = menu.param[7]
	menu.data.midtable_rows = menu.param[8]
	
	DebugError("Selected: "..(menu.data.preselected_line or "nil").." Column Sizes: "..(print(menu.data.midtable_column_sizes) or "nil").." content: "..(print(menu.data.midtable_rows) or "nil"))
	
-- Bottom Row
	menu.data.bottom_row = menu.param[9]
	DebugError("Bottom Row: "..(print(menu.data.bottom_row) or "nil"))
	
	-- just keeping this for reference until finished.
	if false then
	menu.data.mode = false -- not used by me, or at least in a diffrent way. Will be removed when Script is cleaned.
	-- Title and instructions
	menu.data.title = menu.param[3]
	menu.data.instruction_text = menu.param[4]
	-- figuring out how to do this currently.. just a placeholder atm
	menu.data.highlighted_line = menu.param[5]
	-- Menu Entries
	local dataset_selector = menu.param[6]
	--Should be proper tables. If moddev is not good enough to follow instructions I can't get better.
	menu.data.entries = dataset_selector
	--Buttons
	menu.data.button_1_text = menu.param[7]
	menu.data.button_1_section = menu.param[8]
	menu.data.button_2_text = menu.param[9]
	menu.data.button_2_section = menu.param[10]
	menu.data.button_3_text = menu.param[11]
	menu.data.button_3_section = menu.param[12]
	menu.data.button_4_text = menu.param[13]
	menu.data.button_4_section = menu.param[14]
	
	-- List for all Buttons to assign - set up by menu.CreateCell and used in onShowMenu at the end
	menu.data.buttonlist_middle = {}
	menu.data.buttonlist_bottom = {}
	
	menu.data.subsection = "TO BE REPLACED"
	end
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
	local descriptionTableHeight = Helper.e_FigureHeight + 30 - Helper.headerRow2Height
	local row = 1
	if menu.data.instruction_text then
		setup:addTitleRow({Helper.getEmptyCellDescriptor()}, nil, {3}, false, menu.transparent)
		row = row + 1
	end
	for _,rowdef in ipairs(menu.data.midtable_rows) do
		-- first create the Row Content and then add it to the menu as the selected type of row
		rowcontent = {}
		local column = 1
		for i = 1,#rowdef-1 do
			local cellwidth = 0
			for j = column,column+rowdef[1][2][i] do
				cellwidth = cellwidth+menu.data.midtable_column_sizes[j]
			end
			column=column+rowdef[1][2][i]
													-- menu.createCell(celldefinition,row,column,height,width)
			table.insert(rowcontent,menu.CreateCell(rowdef[i+1],row,column,25,cellwidth,menu.data.buttonlist_middle))
		end
		-- select type of Row 
		if rowdef[1][1] == "header" then
-- function setup:addHeaderRow(cells, rowdata, colspans, noscaling, bgColor)
			setup:addHeaderRow(rowcontent,false,rowdef[1][2],false)
		elseif rowdef[1][1] == "regular" then
-- function setup:addSimpleRow(cells, rowdata, colspans, noscaling, bgColor)
			setup:addSimpleRow(rowcontent,rowdef[1],rowdef[1][2],false)
			--ToDo!!!!: Save Param and Section somewhere to evaluate it when line is selected
		elseif rowdef[1][1] == "nonselectable" then
			-- using header here because simple row is selectable
			setup:addHeaderRow(rowcontent, false, rowdef[1][2], false, Helper.defaultSimpleBackgroundColor)
		elseif rowdef[1][1] == "invisible" then
			-- using header here because simple row is selectable
			setup:addHeaderRow(rowcontent, false, rowdef[1][2], false, menu.transparent)
		else
			DebugError("Unknown Row Type in row "..row.." Type: "..rowdef[1].." - filling with empty Row")
			setup:addHeaderRow({Helper.getEmptyCellDescriptor()}, false, nil , false, menu.transparent)
			-- error and add an empty row
		end
		DebugError("Row "..row.."Created")
		row = row + 1
	end
	local middesc = setup:createCustomWidthTable(menu.data.midtable_column_sizes, false, true, true, 1, 0, 0, Helper.tableOffsety - Helper.headerRow2Height/2 + Helper.headerRow2Offsetx, 445)--{Helper.e_DescWidth}
	--BOTTOM
	setup = Helper.createTableSetup(menu)
	setup:addSimpleRow({ 
		Helper.getEmptyCellDescriptor(),
		menu.CreateCell(menu.data.bottom_row[1],row,2,25,150,menu.data.buttonlist_bottom),
		Helper.getEmptyCellDescriptor(),
		menu.CreateCell(menu.data.bottom_row[2],row,4,25,150,menu.data.buttonlist_bottom),
		Helper.getEmptyCellDescriptor(),
		menu.CreateCell(menu.data.bottom_row[3],row,6,25,150,menu.data.buttonlist_bottom),
		Helper.getEmptyCellDescriptor(),
		menu.CreateCell(menu.data.bottom_row[4],row,8,25,150,menu.data.buttonlist_bottom),
		Helper.getEmptyCellDescriptor()
	}, nil, nil, false, menu.transparent)
	local bottomdesc = setup:createCustomWidthTable({48, 150, 48, 150, 48, 150, 48, 150, 48}, false, false, true, 2, 1, 0, 550, 0, false)
	--COMMIT
	menu.toptable, menu.midtable, menu.bottomtable = Helper.displayThreeTableView(menu, topdesc, middesc, bottomdesc, false)
	--BUTTONS
	for i in menu.data.buttonlist_middle do
		-- Buttonlist Entry: {row,column,next_section,param,keepvisible,notsubsection}																	section,			param,			keepvisible,	notsubsection
		Helper.setButtonScript(menu, nil, menu.midtable, menu.data.buttonlist_middle[i][1], menu.data.buttonlist_middle[i][2], function () return menu.buttonSelect(menu.data.buttonlist_middle[i][3],menu.data.buttonlist_middle[i][4],menu.data.buttonlist_middle[i][5],menu.data.buttonlist_middle[i][6]) end)
	end
	for i in menu.data.buttonlist_bottom do
		-- Buttonlist Entry: {row,column,next_section,param,keepvisible,notsubsection}																	section,			param,			keepvisible,	notsubsection
		Helper.setButtonScript(menu, nil, menu.bottomtable, menu.data.buttonlist_bottom[i][1], menu.data.buttonlist_bottom[i][2], function () return menu.buttonSelect(menu.data.buttonlist_bottom[i][3],menu.data.buttonlist_bottom[i][4],menu.data.buttonlist_bottom[i][5],menu.data.buttonlist_bottom[i][6]) end)
	end
	
	if false then
	for i,v in ipairs(menu.data.entries) do
		if v[5] and v[6] and v[7] and v[8] then
			Helper.setButtonScript(menu, nil, menu.midtable, i+1, 2, function () return menu.buttonSelectLocal(v[6],v[1]) end)
			Helper.setButtonScript(menu, nil, menu.midtable, i+1, 3, function () return menu.buttonSelectLocal(v[8],v[1]) end)
		elseif v[5] and v[6] then
			Helper.setButtonScript(menu, nil, menu.midtable, i+1, 3, function () return menu.buttonSelectLocal(v[6],v[1]) end)
		elseif v[7] and v[8] then
			Helper.setButtonScript(menu, nil, menu.midtable, i+1, 3, function () return menu.buttonSelectLocal(v[8],v[1]) end)
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
	
	end
	--FINALIZE
	Helper.releaseDescriptors()
end

--menu.updateInterval = 5.0

function menu.createCell(celldefinition,row,column,height,width,buttonlist)
	if celldefinition == nil then
		return Helper.getEmptyCellDescriptor()
	elseif celldefinition[1] == "text" then
-- { 'text' , 'Text' }
		return celldefinition[2]
	elseif celldefinition[1] == "button" then
-- { 'button' , 'button text' [,'next_section' [ ,hotkey  [, selectable [,param [,keepvisible [,notsubsection]]]] ]] }
		-- Fill List with all Button Scripts to assign so i dont have to loop over the whole list twice
		if celldefinition[5] then
			-- Append Button Cell Values to buttonlist so they can be assigned their respective function later (not possible currently.. :( ) 
			table.insert(buttonlist,{row,column,celldefinition[3],celldefinition[6],celldefinition[7],celldefinition[8]})
		end
		local hotkey
		if celldefinition[4] then 
			hotkey = Helper.createButtonHotkey(celldefinition[4], true) 
		end
		return Helper.createButton(
				Helper.createButtonText(celldefinition[2], "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), 
				nil, 
				false,
				true, 
				0, 
				0, 
				width, 
				height, 
				nil, 
				hotkey, 
				nil, 
				nil)
	elseif celldefinition[1] == "statusbar" then
-- { 'statusbar' , fillpercent , red , green , blue , alpha }
		return Helper.createIcon(
			"solid", 
			noscaling, 
			celldefinition[3], 
			celldefinition[4],
			celldefinition[5],
			celldefinition[6], 
			0, 
			0, 
			height, 
			celldefinition[3] * width / 100)
	else
		DebugError("unknown Cell Definition in row "..row.." column "..column.." Type: "..celldefinition[1].." - filling with empty Cell")
		return Helper.getEmptyCellDescriptor()
	end
	DebugError("Cell Definition didnt return in row "..row.." column "..column.." Type: "..celldefinition[1].." - filling with empty Cell")
	return Helper.getEmptyCellDescriptor()
end

function menu.buttonSelect(section,param,keepvisible,notsubsection)
	-- use slider/editbox Value to return if no param is specified
	if not param and false then -- deactivated while WiP - remove » and false « when finished
		if editboxvalue then
			param = editboxvalue
		elseif slidervalue then
			param = slidervalue
		end
	end
	
	-- use rowdata Values if there are no Values passed by the Button itself
	if menu.rowDataMap[Helper.currentDefaultTableRow] then
		local selection = menu.rowDataMap[Helper.currentDefaultTableRow]
		if not section then
			section = selection[3]
		end
		if not param then
			param = selection[4]
		end
		if not keepvisible then
			keepvisible = selection[5]
		end
		if not notsubsection then
			notsubsection = selection[6]
		end
	end
	
	if section and notsubsection then
		Helper.closeMenuForSection(menu, keepvisible, section, param)
	elseif section then
		Helper.closeMenuForSubSection(menu, keepvisible, section, param)
	else
	    menu.onCloseElement("back")
	end
end

function menu.buttonOK()
	DebugError("UT Custom Menu - menu.buttonOK called - to be depracted, forwarding to menu.buttonSelect ")
	if menu.rowDataMap[Helper.currentDefaultTableRow] then
		local selection = menu.rowDataMap[Helper.currentDefaultTableRow]
		menu.buttonSelect(menu.data.subsection,selection[4])
	end
end

function menu.button1()
	DebugError("UT Custom Menu - menu.button1 called - to be depracted, forwarding to menu.buttonSelect ")
	if menu.rowDataMap[Helper.currentDefaultTableRow] then
		local selection = menu.rowDataMap[Helper.currentDefaultTableRow]
		menu.buttonSelect(menu.data.subsection,selection[4])
	end
end

function menu.button2()
	DebugError("UT Custom Menu - menu.button2 called - to be depracted, forwarding to menu.buttonSelect ")
	if menu.rowDataMap[Helper.currentDefaultTableRow] then
		local selection = menu.rowDataMap[Helper.currentDefaultTableRow]
		menu.buttonSelect(menu.data.subsection,selection[4])
	end
end

function menu.button3()
	DebugError("UT Custom Menu - menu.button3 called - to be depracted, forwarding to menu.buttonSelect ")
	if menu.rowDataMap[Helper.currentDefaultTableRow] then
		local selection = menu.rowDataMap[Helper.currentDefaultTableRow]
		menu.buttonSelect(menu.data.subsection,selection[4])
	end
end

function menu.button4()
	DebugError("UT Custom Menu - menu.button4 called - to be depracted, forwarding to menu.buttonSelect ")
	if menu.rowDataMap[Helper.currentDefaultTableRow] then
		local selection = menu.rowDataMap[Helper.currentDefaultTableRow]
		menu.buttonSelect(menu.data.subsection,selection[4])
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