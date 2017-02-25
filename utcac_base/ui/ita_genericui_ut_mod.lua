
-- Generic UI Script by Itaros. By using this you are bound to keep credit
-- and send vegan pancakes my way every time you copy it.
-- But, honestly, why do you need to copy it? It is from a LIBRARY mod already.
-- If you have special needs it would be faster to contact me directly instead of fiddling with this ^_^
-- Modifications to the script shall be marked correspondingly.
-- Modification of this line and lines above is forbidden.

-- You break it - you buy another copy of a game for everyone affected lol!

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
	name = "ita_genericui",
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
	local dataset_selector = menu.param[3]
	menu.data.entries = {}
	--Should be proper tables. If moddev is not good enough to follow instructions I can't get better.
	menu.data.entries = dataset_selector
	menu.data.mode = menu.param[4]
	menu.data.title = menu.param[5]
	--mode
	menu.data.mode = menu.param[4]
	--subsection
	menu.data.subsection = menu.param[6]
	--instructions
	menu.data.instruction_text = menu.param[7]
	--POSTVALIDATION
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
	local descriptionTableHeight = Helper.e_FigureHeight + 30 - Helper.headerRow2Height
	--menu.data.mode = 1 -- testhack
	for _,v in ipairs(menu.data.entries) do
		if menu.data.mode == 0 then
			--OP MODE: Select One, Native
			setup:addSimpleRow({v[3]}, v, {3})
		elseif menu.data.mode == 1 then
			--OP MODE: Select One, Local
			local selectThisLocalBtn = Helper.createButton(Helper.createButtonText(ReadText(455600, 12), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 150, 25, nil, nil, nil, nil)
			setup:addSimpleRow({v[3], selectThisLocalBtn}, v, {2,1})
		end
		--TODO: More modes
	end
	local middesc = setup:createCustomWidthTable({Helper.scaleX(Helper.standardButtonWidth), 0 , 150-10-5}, false, true, true, 1, 0, 0, Helper.tableOffsety - Helper.headerRow2Height/2 + Helper.headerRow2Offsetx, 445)--{Helper.e_DescWidth}
	--BOTTOM
	setup = Helper.createTableSetup(menu)
	local selectAllButton
	local selectCurrentButton
	if menu.data.mode == 2 then
		selectAllButton = Helper.createButton(Helper.createButtonText(ReadText(455600, 13), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_Y", true), nil, nil)
	else
		selectAllButton = Helper.getEmptyCellDescriptor()
	end
	if menu.data.mode ~= 1 then
		selectCurrentButton = Helper.createButton(Helper.createButtonText(ReadText(455600, 11), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_X", true), nil, nil)
	else
		selectCurrentButton = Helper.getEmptyCellDescriptor()
	end
	setup:addSimpleRow({ 
		Helper.getEmptyCellDescriptor(),
		Helper.createButton(Helper.createButtonText(ReadText(455600, 10), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_B", true), nil, nil),
		Helper.getEmptyCellDescriptor(),
		Helper.getEmptyCellDescriptor(),
		Helper.getEmptyCellDescriptor(),
		selectAllButton,
		Helper.getEmptyCellDescriptor(),
		selectCurrentButton,
		Helper.getEmptyCellDescriptor()
	}, nil, nil, false, menu.transparent)
	local bottomdesc = setup:createCustomWidthTable({48, 150, 48, 150, 0, 150, 48, 150, 48}, false, false, true, 2, 1, 0, 550, 0, false)
	--COMMIT
	menu.toptable, menu.midtable, menu.bottomtable = Helper.displayThreeTableView(menu, topdesc, middesc, bottomdesc, false)
	--BUTTONS
	Helper.setButtonScript(menu, nil, menu.bottomtable, 1, 2, function () return menu.onCloseElement("back") end)
	--Helper.setButtonScript(menu, nil, menu.buttontable, 1, 6, menu.buttonSelect)
	--Selector button(s)
	if menu.data.mode ~= 1 then
		Helper.setButtonScript(menu, nil, menu.bottomtable, 1, 8, menu.buttonOK)
	else
		for i,v in ipairs(menu.data.entries) do
			Helper.setButtonScript(menu, nil, menu.midtable, i, 3, function () return menu.buttonSelectLocal(v) end)
		end
	end
	--FINALIZE
	Helper.releaseDescriptors()
end

--menu.updateInterval = 5.0

function menu.buttonSelectLocal(entry)
	Helper.closeMenuForSubSection(menu, false, menu.data.subsection, entry[4])
end

function menu.buttonOK()
	if menu.rowDataMap[Helper.currentDefaultTableRow] then
		local selection = menu.rowDataMap[Helper.currentDefaultTableRow]
		Helper.closeMenuForSubSection(menu, false, menu.data.subsection, selection[4])
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