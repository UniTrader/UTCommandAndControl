-- Generif UI by UniTrader, based on Original work by Itaros.
-- Script was so heavily modified though that even Itaros himself couldnt recognize it anymore :P
-- His work was really helpful and Inspirational though so i am gladly keeping the
-- Original Copyright Notice:
-- ==============================================================
-- Generic UI Script by Itaros. By using this you are bound to keep credit
-- and send vegan pancakes my way every time you copy it.
-- But, honestly, why do you need to copy it? It is from a LIBRARY mod already.
-- If you have special needs it would be faster to contact me directly instead of fiddling with this ^_^
-- Modifications to the script shall be marked correspondingly.
-- Modification of this line and lines above is forbidden.

-- You break it - you buy another copy of a game for everyone affected lol!

-- ==============================================================
--
---------------------------------------------------------------
-- New Param Structure:
-- Multi-line for better overview:
-- param == { 0, 0, 'title', 'instruction_text', {special_function} or null ,
-- {preselected_cell} or nil, {midtable_column_sizes} ,
-- { { { line_properties_A } , {cell_A1} , {cell_A2} , ... } ,
--   { { line_properties_B } , {cell_B1} , {cell_B2} , ... } ,
--   ... },
-- { {cell_bottom1} , {cell_bottom2} , {cell_bottom3} , {cell_bottom4} }
--
-- Special Functions Not Yet Implemented (and might never make it):
-- nil -- nothing
-- {'editbox','initialtext'} 
-- {'scrollbar',min_display_value,min_possible_value,initial_value,max_possible_value,max_display_value[,step_value]}
--
-- preselected_cell:
-- { row , column } (nil values also ok)
--
-- midtable_column_sizes are the Sizes of the midtable columns. 
-- you can set ONE Value to -1 which will set the Size of it that the Line is completely filled. (undefined behavior if its more than one entry)
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
-- Example usage (multi-line for overview):
-- <open_conversation_menu menu="ut_genericui" param="
-- [ 0 , 0 , 'Genericui Menu', 'HOT FOOD AND COOL DRINKS', null , null , [ -1 , 150 , 150 , 150 , 200 ] , [
-- [ [ 'header' , [ 4 , 1 ] ] , [ 'text' , 'Recommendations of the House' ] , [ 'text' , 'HOTNESS' ]] ,
-- [ [ 'regular' , [ 2 , 1 , 1 , 1 ] , null , 'pancakes'] , [ 'text' , 'Pancakes' ] ,  [ 'button' , 'Small' , 'select_size_small' , null , true , 'pancakes'  ] ,  [ 'button' , 'BIG' , 'select_size_big' , null , true , 'pancakes'  ] ,  [ 'statusbar' , 95 , 255 , 0 , 0 ,  100 ]  ],
-- [ [ 'regular' , [ 1 , 1 , 1 , 1 , 1 ] , null , 'pizza'] , [ 'text' , 'Pizza' ] ,  [ 'button' , 'Small' , 'select_size_small' , null , true , 'pizza'  ] ,  [ 'button' , 'Medium' , 'select_size_medium' , null , true , 'pizza'  ] ,  [ 'button' , 'BIG' , 'select_size_big' , null , true , 'pizza'  ] ,  [ 'statusbar' , 90 , 255 , 0 , 0 ,  100 ]  ] ,
-- [ [ 'regular' , [ 3 , 1 , 1 ] , null , 'core'] , [ 'text' , 'A part from the Core of the Planet' ] ,  [ 'button' , 'Small' , 'select_size_small' , null , true , 'core'  ] , [ 'statusbar' , 500 , 255 , 0 , 0 ,  100 ]  ],
-- [ [ 'invisible', [ 5 ] ] , null ] ,
-- [ [ 'header' , [ 4 , 1 ] ] , [ 'text' , 'Drinks' ] , [ 'text' , 'COOLNESS' ]] ,
-- [ [ 'regular' , [ 3 , 1 , 1 ] , null , 'cola'] , [ 'text' , 'Cola' ] ,  [ 'button' , 'one Glass' , 'select_size_any' , null , true , 'cola'  ] , [ 'statusbar' , 75 , 0 , 0 , 255 ,  100 ]  ],
-- [ [ 'regular' , [ 3 , 1 , 1 ] , null , 'beer'] , [ 'text' , 'Beer' ] ,  [ 'button' , 'one Glass' , 'select_size_any' , null , true , 'beer'  ] , [ 'statusbar' , 70 , 0 , 0 , 255 ,  100 ]  ],
-- [ [ 'regular' , [ 3 , 1 , 1 ] , null , 'LN'] , [ 'text' , 'Liquid Nitrogen' ] ,  [ 'button' , 'one Bucket' , 'select_size_any' , null , true , 'LN'  ] , [ 'statusbar' , 100 , 0 , 0 , 255 ,  100 ]  ],
-- [ [ 'regular' , [ 3 , 1 , 1 ] , null , 'LH'] , [ 'text' , 'Liquid Hydrogen' ] ,  [ 'button' , 'one Bucket' , 'select_size_any' , null , true , 'LH'  ] , [ 'statusbar' , 273 , 0 , 0 , 255 ,  100 ]  ],
-- ] , [ 
-- [ 'button' , 'Back' , null , 'INPUT_STATE_DETAILMONITOR_B' , true ] , [ 'button' , 'Classic Select small', 'select_size_small' , 'INPUT_STATE_DETAILMONITOR_BACK' , true ] , 
-- [ 'button' , 'Classic Select Med', 'select_size_medium' , 'INPUT_STATE_DETAILMONITOR_Y' , true ] , [ 'button' , 'Classic Select BIG', 'select_size_big' , 'INPUT_STATE_DETAILMONITOR_X' , true ]
-- ] ]"/>
--
--------------------------------------------------------------------------------------------------------

local menu = {
	name = "ut_genericui",
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
	
	--DebugError("Lua Menu Fetch:")
	
-- Menu in general
	menu.data.title = menu.param[3]
	menu.data.instruction_text = menu.param[4]
	if menu.data.instruction_text == nil then menu.data.instruction_text = "" end
	menu.data.special_function = menu.param[5]
	
	--print("Title: "..(menu.data.title or "nil").." Info: "..(menu.data.instruction_text or "nil").." Special: ")
	--print(menu.data.special_function)
	
-- Mid-Section definition
	if menu.param[6] then
		menu.data.preselected_row = menu.param[6][1] or nil
		menu.data.preselected_column = menu.param[6][2] or nil
	else
		menu.data.preselected_row = nil
		menu.data.preselected_column = nil
	end
		
	menu.data.midtable_column_sizes = menu.param[7]
	menu.data.midtable_rows = menu.param[8]
	
	-- Calculate Dynamic Row Size if we have a dynamic (-1) Entry
	local index = nil
	local totalwidth = 0
	local maxwidth = 1200
	if #menu.data.midtable_rows > 10 then maxwidth = 1179 end
	for i, v in pairs(menu.data.midtable_column_sizes) do
		if v == -1 then
			index = i
		else
			totalwidth = totalwidth + v + 4 -- 4 is the spacing between columns
		end
	end
	if index then
		--print("Found -1 Entry in column "..index.." will set it to remaining width of "..(maxwidth - 6 - totalwidth).."pixels - Totalwidth="..totalwidth)
		menu.data.midtable_column_sizes[index] = maxwidth - 6 - totalwidth
		totalwidth = totalwidth + menu.data.midtable_column_sizes[index]
	end
	if totalwidth > maxwidth then
		DebugError("Totalwidth of Table greater than 1200 ("..totalwidth..") - will probably not display")
	end
	
	--print("Selected: "..(menu.data.preselected_row or "nil").."/"..(menu.data.preselected_column or "nil").." Total Width: "..totalwidth.." Column count:"..#menu.data.midtable_column_sizes.." Sizes: ")
	--print(menu.data.midtable_column_sizes)
	--print("content: - "..#menu.data.midtable_rows.."entries")
	--print(menu.data.midtable_rows)
	
-- Bottom Row
	menu.data.bottom_row = menu.param[9]
	
	--print("Bottom Row: ")
	--print(menu.data.bottom_row)
	
	
	-- List for all Buttons to assign - set up by CreateCell and used in onShowMenu at the end
	menu.data.buttonlist_middle = {}
	menu.data.buttonlist_bottom = {}
	
end

function menu.onShowMenu()
	
	-- Set up CreateCell Function
	local function CreateCell(celldefinition,row,column,height,width,buttonlist)
		--if celldefinition then print("createCell called for a "..celldefinition[1].." Cell") end
		if celldefinition == nil then
			if row == menu.data.preselected_row and column == menu.data.preselected_column then
				DebugError("Preselected Cell is an empty Cell: Row "..row.." Column "..j.." - removing column")
				menu.data.preselected_column = nil
			end
			--print("createCell called for an empty Cell")
			return Helper.getEmptyCellDescriptor()
		elseif celldefinition[1] == "text" then
	-- { 'text' , 'Text' }
			if row == menu.data.preselected_row and column == menu.data.preselected_column then
				DebugError("Preselected Cell is a Text Cell: Row "..row.." Column "..j.." - removing column")
				menu.data.preselected_column = nil
			end
			return celldefinition[2]
		elseif celldefinition[1] == "button" then
	-- { 'button' , 'button text' [,'next_section' [ ,hotkey  [, selectable [,param [,keepvisible [,notsubsection]]]] ]] }
			-- Fill List with all Button Scripts to assign so i dont have to loop over the whole list twice
			if celldefinition[5] then
				-- Append Button Cell Values to buttonlist so they can be assigned their respective function later (not possible currently.. :( ) 
				table.insert(buttonlist,{row,column,celldefinition[3],celldefinition[6],celldefinition[7],celldefinition[8]})
			end
			return Helper.createButton(
					Helper.createButtonText(celldefinition[2], "center", Helper.standardFont, Helper.standardFontSize * 1.4 , 255, 255, 255, 100), 
					nil, 
					true,
					true, 
					0, 
					0, 
					width,
					height, 
					nil, 
					celldefinition[4] and Helper.createButtonHotkey(celldefinition[4], true) or nil, 
					nil, 
					nil)
		elseif celldefinition[1] == "statusbar" then
			if row == menu.data.preselected_row and column == menu.data.preselected_column then
				DebugError("Preselected Cell is a Statusbar Cell: Row "..row.." Column "..j.." - removing column")
				menu.data.preselected_column = nil
			end
	-- { 'statusbar' , fillpercent , red , green , blue , alpha }
		return Helper.createIcon(
				"solid", 
				true, 
				celldefinition[3], 
				celldefinition[4],
				celldefinition[5],
				celldefinition[6], 
				0, 
				0, 
				height, 
				celldefinition[2] * width / 100)
		else
			if row == menu.data.preselected_row and column == menu.data.preselected_column then
				DebugError("Preselected Cell is an unknown type of Cell: Row "..row.." Column "..j.." - removing column")
				menu.data.preselected_column = nil
			end
			DebugError("unknown Cell Definition in row "..row.." column "..column.." Type: "..celldefinition[1].." - filling with empty Cell")
			return Helper.getEmptyCellDescriptor()
		end
		DebugError("Cell Definition didnt return in row "..row.." column "..column.." Type: "..celldefinition[1].." - filling with empty Cell")
		return Helper.getEmptyCellDescriptor()
	end
	
	--FETCHING
	menu.fetch()
	--UI DATA
	menu.title = menu.data.title
	--TOP
	local setup = Helper.createTableSetup(menu)
	setup:addTitleRow({
		Helper.createFontString(menu.title, false, "left", 255, 255, 255, 100, Helper.headerRow1Font, Helper.headerRow1FontSize, false, Helper.headerRow1Offsetx, Helper.headerRow1Offsety, Helper.headerRow1Height, Helper.headerRow1Width)
	}, nil, {2})
	--print("Title Row created")
	setup:addTitleRow({ 
		Helper.createFontString(menu.data.instruction_text, false, "left", 129, 160, 182, 100, Helper.headerRow2Font, Helper.headerRow2FontSize, false, Helper.headerRow2Offsetx, Helper.headerRow2Offsety, Helper.headerRow2Height, Helper.headerRow1Width)	-- text depends on selection
	}, nil, {2})
	--print("Instruction Text created")
	local topdesc = setup:createCustomWidthTable({ 0, Helper.scaleX(Helper.e_IconEntrySize) + 37 }, false, true)
	--print("topdesc created")
	--MIDDLE(DATA)
	setup = Helper.createTableSetup(menu)
	local descriptionTableHeight = Helper.e_FigureHeight + 30 - Helper.headerRow2Height
	local row = 1
	for _,rowdef in ipairs(menu.data.midtable_rows) do
		--print("Creating Content for row "..row)
		-- first create the Row Content and then add it to the menu as the selected type of row
		rowcontent = {}
		local column = 1
		for i = 1,#rowdef-1 do
			local cellwidth = -5
			for j = column,column+rowdef[1][2][i]-1 do
				-- checking if we have a non-selettable cell pre-selectend and if yes nil that selection
				if row == menu.data.preselected_row and j == menu.data.preselected_column and cellwidth > 0 then
					DebugError("Preselected Cell is part of a spanned Cell: Row "..row.." Column "..j.." - removing column")
					menu.data.preselected_column = nil
				end
				cellwidth = cellwidth + ( menu.data.midtable_column_sizes[j] or 0 ) + 5
			end
													-- menu.createCell(celldefinition,row,column,height,width)
			table.insert(rowcontent,CreateCell(rowdef[i+1],row,column,36,cellwidth,menu.data.buttonlist_middle))
			column=column+rowdef[1][2][i]
		end
		--print("Row Content created")
		-- select type of Row 
		if rowdef[1][1] == "header" then
-- function setup:addHeaderRow(cells, rowdata, colspans, noscaling, bgColor)
			setup:addHeaderRow(rowcontent,false,rowdef[1][2],false)
			if row == menu.data.preselected_row  then
				DebugError("Preselected Cell is in a nonselectable Header Row: Row "..row.." - removing selection")
				menu.data.preselected_row = nil
				menu.data.preselected_column = nil
			end
			--print("Header Row created")
		elseif rowdef[1][1] == "regular" then
-- function setup:addSimpleRow(cells, rowdata, colspans, noscaling, bgColor)
			setup:addSimpleRow(rowcontent,rowdef[1],rowdef[1][2],false)
			--ToDo!!!!: Save Param and Section somewhere to evaluate it when line is selected
			--print("Regular Row Created")
		elseif rowdef[1][1] == "nonselectable" then
			-- using header here because simple row is selectable
			if row == menu.data.preselected_row  then
				DebugError("Preselected Cell is in a nonselectable Row: Row "..row.." - removing selection")
				menu.data.preselected_row = nil
				menu.data.preselected_column = nil
			end
			setup:addHeaderRow(rowcontent, false, rowdef[1][2], false, Helper.defaultSimpleBackgroundColor)
			--print("Nonselectable Row created")
		elseif rowdef[1][1] == "invisible" then
			-- using header here because simple row is selectable
			if row == menu.data.preselected_row  then
				DebugError("Preselected Cell is in a nonselectable Invisible Row: Row "..row.." - removing selection")
				menu.data.preselected_row = nil
				menu.data.preselected_column = nil
			end
			setup:addHeaderRow(rowcontent, false, rowdef[1][2], false, menu.transparent)
			--print("Invisible Row Created")
		else
			if row == menu.data.preselected_row  then
				DebugError("Preselected Cell is in an empty Row: Row "..row.." - removing selection")
				menu.data.preselected_row = nil
				menu.data.preselected_column = nil
			end
			DebugError("Unknown Row Type in row "..row.." Type: "..rowdef[1].." - filling with empty Row")
			setup:addHeaderRow({Helper.getEmptyCellDescriptor()}, false, nil , false, menu.transparent)
			-- error and add an empty row
		end
		DebugError("Row "..row.."Created")
		row = row + 1
	end
	--print("creating middesc")
	local middesc = setup:createCustomWidthTable(menu.data.midtable_column_sizes, false, true, true, 1, 0, 0, Helper.tableOffsety + ( menu.data.instruction_text and Helper.headerRow2Height or 0 - Helper.headerRow2Height/2 ) + Helper.headerRow2Offsetx , 650 - ( menu.data.instruction_text and Helper.headerRow2Height or 0 ), nil, nil, menu.data.preselected_row,menu.data.preselected_column)--{Helper.e_DescWidth}
	--print("middesc created")
	--BOTTOM
	setup = Helper.createTableSetup(menu)
	setup:addSimpleRow({ 
		Helper.getEmptyCellDescriptor(),
		CreateCell(menu.data.bottom_row[1],1,2,36,210,menu.data.buttonlist_bottom),
		Helper.getEmptyCellDescriptor(),
		CreateCell(menu.data.bottom_row[2],1,4,36,210,menu.data.buttonlist_bottom),
		Helper.getEmptyCellDescriptor(),
		CreateCell(menu.data.bottom_row[3],1,6,36,210,menu.data.buttonlist_bottom),
		Helper.getEmptyCellDescriptor(),
		CreateCell(menu.data.bottom_row[4],1,8,36,210,menu.data.buttonlist_bottom),
		Helper.getEmptyCellDescriptor()
	}, nil, nil, false, menu.transparent)
	local bottomdesc = setup:createCustomWidthTable({48, 150, 48, 150, 48, 150, 48, 150, 48}, false, false, true, 2, 1, 0, 550, 0, false)
	--COMMIT
	menu.toptable, menu.midtable, menu.bottomtable = Helper.displayThreeTableView(menu, topdesc, middesc, bottomdesc, false)
	--BUTTONS
	for _,v in ipairs(menu.data.buttonlist_middle) do
		--print("Assigned middle button in row "..v[1].." column "..v[2].." to point to section "..(v[3] or "nil"))
		-- Buttonlist Entry: {row,column,next_section,param,keepvisible,notsubsection}																	section,			param,			keepvisible,	notsubsection
		Helper.setButtonScript(menu, nil, menu.midtable, v[1], v[2], function () return menu.buttonSelect(v[3],v[4],v[5],v[6]) end)
	end
	for _,v in ipairs(menu.data.buttonlist_bottom) do
		--print("Assigned bottom button in row "..v[1].." column "..v[2].." to point to section "..(v[3] or "nil"))
		-- Buttonlist Entry: {row,column,next_section,param,keepvisible,notsubsection}																	section,			param,			keepvisible,	notsubsection
		Helper.setButtonScript(menu, nil, menu.bottomtable, v[1], v[2], function () return menu.buttonSelect(v[3],v[4],v[5],v[6]) end)
	end
	
	Helper.setButtonScript(menu, nil, menu.bottomtable, 1, 2, menu.button1)
	Helper.setButtonScript(menu, nil, menu.bottomtable, 1, 4, menu.button2)
	Helper.setButtonScript(menu, nil, menu.bottomtable, 1, 6, menu.button3)
	Helper.setButtonScript(menu, nil, menu.bottomtable, 1, 8, menu.button4)
	
	--FINALIZE
	Helper.releaseDescriptors()
end

--menu.updateInterval = 5.0

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
	if menu.rowDataMap[Helper.currentDefaultTableRow] or false then
		local selection = menu.rowDataMap[Helper.currentDefaultTableRow]
		--DebugError("Button Pressed")
		--print("rowDataMap Values: 3: "..(selection[3] or "nil").." 4: "..(selection[4] or "nil").." 5: "..(selection[5] or "nil").." 6: "..(selection[6] or "nil"))
		if not section then
			--print("replacing section "..(section or "nil").." with "..(selection[3] or "nil"))
			section = selection[3]
		end
		if not param then
			--print("replacing param "..(param or "nil").." with "..(selection[4] or "nil"))
			param = selection[4]
		end
		if not keepvisible then
			--print("replacing keepvisible "..(keepvisible or "nil").." with "..(selection[5] or "nil"))
			keepvisible = selection[5]
		end
		if not notsubsection then
			--print("replacing notsubsection "..(notsubsection or "nil").." with "..(selection[6] or "nil"))
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