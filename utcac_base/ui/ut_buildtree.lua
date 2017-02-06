
-- param == {0,0,architect, buildership, null(not used andmore), station }

local menu = {
	name = "UTBuildTreeMenu",
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
	menu.architect = nil
	menu.buildership = nil
	menu.canbuild = nil
	menu.station = nil
end

function menu.onShowMenu()
	--Importing params
	menu.architect = menu.param[3]
	menu.buildership = menu.param[4]
	menu.canbuild = menu.param[5]
	menu.station = menu.param[6]
	--Getting macros
	menu.stationmacro = GetComponentData(menu.station, "macro")
	local title = ReadText(1001,1700)
	--Getting global UI information
	local productioncolor, buildcolor, storagecolor, radarcolor, dronedockcolor, efficiencycolor, defencecolor = GetHoloMapColors()	
	--Creating UI Skeleton
	--Description at the top
	local setup  = Helper.createTableSetup(menu)
	local name, typestring, typeicon, typename, ownericon = GetComponentData(menu.architect, "name", "typestring", "typeicon", "typename", "ownericon")
	setup:addTitleRow{
		Helper.createIcon(typeicon, false, 255, 255, 255, 100, 0, 0, Helper.headerCharacterIconSize, Helper.headerCharacterIconSize),
		Helper.createFontString(typename .. " " .. name, false, "left", 255, 255, 255, 100, Helper.headerRow1Font, Helper.headerRow1FontSize),
		Helper.createIcon(ownericon, false, 255, 255, 255, 100, 0, 0, Helper.headerCharacterIconSize, Helper.headerCharacterIconSize)
	}
	local infodesc = setup:createCustomWidthTable({ Helper.scaleX(Helper.headerCharacterIconSize), 0, Helper.scaleX(Helper.headerCharacterIconSize) + 37 }, false, true)
	--Buildtree itself! NOOOO!!!! PAIN!!! SUFFERRING!!!
	--Some buildtree data
	local cursequence, curstage, curprogress = GetCurrentBuildSlot(menu.station)
	local sortedbuildorder_blackboard = GetNPCBlackboard(menu.architect, "$ut_cac")
	local utcac_buildplan = sortedbuildorder_blackboard.orderedbuildplanlist;
	menu.buildtree = GetBuildTree(menu.station)
	--Rebuilding the buildtree
	local entries = {}
	for seqidx, seqdata in ipairs(menu.buildtree) do
		entries[seqidx] = {}
		entries[seqidx].currentsequence = seqdata.sequence
		entries[seqidx].currentstage = seqdata.currentstage
		entries[seqidx].seqname = "SEQ: " .. seqdata.sequence
		
		-- Naming identities
		local numproductions, numbuild, numstorages, numradar, numdronelaunchpad = 0, 0, 0, 0, 0
		local productionname = ""
		
		--Special base sequence(zero sequence)
		if seqdata.sequence == "a" then
			DebugError("Positive seq!")
			modules = GetBuildStageModules(menu.station, "", 0)
			seqAidx=seqidx 
			entries[seqidx][0] = {}
			entries[seqidx][0].stagename = stagestring
			entries[seqidx][0].stageid = 0
			entries[seqidx][0].isCompleted = true
			entries[seqidx][0].isBuildingThis = false
			entries[seqidx][0].isScheduled = false
			entries[seqidx][0].isExtendable = false
			fillModules(entries, modules, seqidx, 0)
		end
		--General stages
		for stageidx, stagedata in ipairs(seqdata) do
			entries[seqidx][stageidx] = {}
			entries[seqidx][stageidx].stagename = stagestring
			entries[seqidx][stageidx].stageid = stagedata.stage
			entries[seqidx][stageidx].sequenceid = seqdata.sequence
			local isCompleted = false
			
			modules = GetBuildStageModules(menu.station, seqdata.sequence, stagedata.stage)
			local temp_prodname = fillModules(entries, modules, seqidx, stageidx)
			if temp_prodname ~= "" then productionname = temp_prodname end
			
			numproductions = numproductions + modules.numproductions
			numbuild = numbuild + modules.numbuild
			numstorages = numstorages + modules.numstorages
			numradar = numradar + modules.numradar
			numdronelaunchpad = numdronelaunchpad + modules.numdronelaunchpad
			
			if entries[seqidx].currentstage >= stageidx then isCompleted = true end
			-- TODO: Query UTCAC Buildorder ($actor.$ut_cac.$orderedbuildplanlist)
			local isBuildingThis = false
			if cursequence == seqdata.sequence then
				if curstage == stagedata.stage then
					isBuildingThis = true
				end
			end
			local isExtendable = false
			local isScheduled = false
			for _,bp in ipairs(utcac_buildplan) do
				if bp[1] == seqdata.sequence then
					if (bp[2] + 1) == stagedata.stage then
						isExtendable = true
					elseif stagedata.stage < (bp[2] + 1) then
						if isCompleted ~= true then
							isScheduled = true
						end
					end
				end
			end
			-- TODO: This mess above should be a function
			entries[seqidx][stageidx].isCompleted = isCompleted
			entries[seqidx][stageidx].isBuildingThis = isBuildingThis
			entries[seqidx][stageidx].isScheduled = isScheduled
			entries[seqidx][stageidx].isExtendable = isExtendable
		end
		--Seq virtual name
		if numproductions > 0 or numbuild > 0 then
			entries[seqidx].seqname = "   " .. productionname
		elseif numstorages > 0 then
			entries[seqidx].seqname = "   " .. ReadText(1001, 1400)
		elseif numradar > 0 then
			entries[seqidx].seqname = "   " .. ReadText(1001, 1706)
		elseif numdronelaunchpad > 0 then
			entries[seqidx].seqname = "   " .. ReadText(1001, 1707)
		else
			entries[seqidx].seqname = "   " .. ReadText(1001, 1310)
		end
	end
	--Stage 0 uplift
	table.insert(entries[seqAidx],entries[seqAidx][0])
	entries[seqAidx][0] = nil
	--Finalization
	table.sort(entries, function (a, b) return a.currentsequence < b.currentsequence end)
	for _,sequence  in ipairs(entries) do
		table.sort(sequence, function (a, b) return a.stageid < b.stageid end)
	end
	--Buildtree presentation
	setup = Helper.createTableSetup(menu)
	for seqidx, sequence in ipairs(entries) do
		setup:addSimpleRow({sequence.seqname, Helper.getEmptyCellDescriptor()},nil,{2,1}, false, Helper.defaultHeaderBackgroundColor)
		for stageidx, stage in ipairs(sequence) do
			local buildStateText = menu.getBuildStateText(stage)
			--..sequence.currentstage.."-"..sequence.currentstage
			setup:addSimpleRow({ 
				"       " .. ReadText(1001, 1701) .. " " .. stage.stageid,
				Helper.createFontString(buildStateText , false, "left")
			},{sequence = sequence.currentsequence, stage = stage.stageid, stagedescriptor = stage, isExtendable = stage.isExtendable}, {2,1}, false, Helper.defaultHeaderBackgroundColor)
			for moduleidx, module in ipairs(stage) do
				setup:addSimpleRow({ "", Helper.createFontString(module.name, false, "left", module.color.r, module.color.g,module.color.b,module.color.a), Helper.getEmptyCellDescriptor()}, module, {1,1,1})
			end
		end
	end
	local selectdesc = setup:createCustomWidthTable({ Helper.standardButtonWidth, menu.textwidth, 0 }, false, false, true, 1, 0, 0, Helper.tableOffsety, 445)
	--Buttons on the bottom
	setup = Helper.createTableSetup(menu)
	setup:addTitleRow({Helper.getEmptyCellDescriptor()}, nil, {9})
	setup:addSimpleRow({ 
		Helper.getEmptyCellDescriptor(),
		Helper.createButton(Helper.createButtonText(ReadText(1001, 2669), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_B", true)),
		Helper.getEmptyCellDescriptor(),
		Helper.getEmptyCellDescriptor(),
		Helper.getEmptyCellDescriptor(),
		Helper.getEmptyCellDescriptor(),
		Helper.getEmptyCellDescriptor(),
		--Button below by default is grayed out, awaiting selection ;)
		Helper.createButton(Helper.createButtonText(ReadText(1001, 1708), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, false, 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_X", true)),
		Helper.getEmptyCellDescriptor()
	}, nil, nil, false, menu.transparent)
	local buttondesc = setup:createCustomWidthTable({48, 150, 48, 150, 0, 150, 48, 150, 48}, false, false, true, 2, 2, 0, 520, 0, false)
	--Commiting
	menu.infotable, menu.selecttable, menu.buttontable = Helper.displayThreeTableView(menu, infodesc, selectdesc, buttondesc, false)
	
	--Button scripts
	Helper.setButtonScript(menu, nil, menu.buttontable, 2, 2, function () return menu.onCloseElement("back") end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 2, 8, menu.buttonExtend)
	
	if menu.station then
		menu.onUpdate()
	end
	
end

function menu.buttonExtend()
	local rowdata = menu.rowDataMap[Helper.currentDefaultTableRow]
	if rowdata then
		if rowdata.sequence then
			Helper.closeMenuForSection(menu, false, "comm_orders_extend_ui_selected", {rowdata.sequence})
			menu.cleanup()
		end
	end
end

menu.updateInterval = 1.0

function menu.onRowChanged(row, rowdata)
	local rowdata = menu.rowDataMap[Helper.currentDefaultTableRow]
	if rowdata then
		Helper.removeButtonScripts(menu, menu.buttontable, 2, 8)
		local isEnabled = false
		if rowdata.isExtendable then
			isEnabled = rowdata.isExtendable
		end
		SetCellContent(menu.buttontable, Helper.createButton(Helper.createButtonText(ReadText(1001, 1708), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, isEnabled, 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_X", true)), 2, 8)
		Helper.setButtonScript(menu, nil, menu.buttontable, 2, 8, menu.buttonExtend)	
	end
end

function menu.getBuildStateText(stage)
	buildStateText = ""
	if stage.isScheduled then buildStateText = ReadText(5554203, 1004) end
	if stage.isExtendable then buildStateText = ReadText(5554203, 1003) end
	if stage.isCompleted then buildStateText = ReadText(5554203, 1002) end
	if stage.isBuildingThis then buildStateText = ReadText(5554203, 1001) end
	return buildStateText
end

function menu.onUpdate()
	if menu.station and menu.rowDataMap then
		-- Update station's current build status, and the "available" flag
		local cursequence, curstage, curprogress = GetCurrentBuildSlot(menu.station)
		for row, rowdata in pairs(menu.rowDataMap) do
			if rowdata then
				if rowdata.stagedescriptor then
					if cursequence == rowdata.sequence and curstage == rowdata.stage then
						rowdata.stagedescriptor.isBuildingThis = true
					else
						if rowdata.stagedescriptor.isBuildingThis == true then
							--Assuming the process for successful
							--TODO: Account for CV destruction
							rowdata.stagedescriptor.isScheduled = false
							rowdata.stagedescriptor.isCompleted = true
						end
						rowdata.stagedescriptor.isBuildingThis = false
					end
					buildStateText = menu.getBuildStateText(rowdata.stagedescriptor)
					if rowdata.stagedescriptor.isBuildingThis == true then
						buildStateText = string.format("%s (%d %%)", buildStateText, curprogress)
					end
					Helper.updateCellText(menu.selecttable, row, 3, buildStateText)
				end
			end
		end
	end
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

function fillModules(entries, modules, seqidx, stageidx)
	local productionname = ""
	local productioncolor, buildcolor, storagecolor, radarcolor, dronedockcolor, efficiencycolor, defencecolor = GetHoloMapColors()	
	for moduleidx, module in ipairs(modules) do
		local color = {r = 255, g = 255, b = 255, a = 100}
		if module.library == "moduletypes_production" then
			color = productioncolor
			productionname = module.name
		elseif module.library == "moduletypes_build" then
			color = buildcolor
			productionname = module.name
		elseif module.library == "moduletypes_storage" then
			color = storagecolor
		elseif module.library == "moduletypes_communication" then
			color = radarcolor
		elseif module.library == "moduletypes_dronedock" then
			color = dronedockcolor
		elseif module.library == "moduletypes_efficiency" then
			color = efficiencycolor
		elseif module.library == "moduletypes_defence" then
			color = defencecolor
		end
		entries[seqidx][stageidx][moduleidx] = {name = module.name}
		entries[seqidx][stageidx][moduleidx].color = color
		AddKnownItem(module.library, module.macro)
	end
	return productionname
end

init()