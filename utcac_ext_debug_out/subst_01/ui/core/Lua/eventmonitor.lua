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
		uint64_t poiID;
		UniverseID componentID;
		const char* messageType;
		const char* connectionName;
		bool isCollectable;
		bool isAssociative;
	} MessageDetails;
	typedef struct {
		int relationStatus;
		int relationValue;
		int relationLEDValue;
		bool isBoostedValue;
	} RelationDetails;
	typedef struct {
		UniverseID softtargetID;
		const char* softtargetName;
		const char* softtargetConnectionName;
	} SofttargetDetails;
	typedef struct {
		const char* ClusterName;
		const char* SectorName;
		const char* ZoneName;
		bool isLocalHighway;
		bool isSuperHighway;
	} ZoneDetails;
	void AbortCurrentNotification(void);
	bool AreShipSystemsEnabled(void);
	int GetConfigSetting(const char*const setting);
	UniverseID GetEnvironmentObject(void);
    UniverseID GetExternalTargetViewComponent(void);
	FactionDetails GetFactionDetails(const char* factionid);
	const char* GetFactionNameForEventMonitorHack(UniverseID componentid);
	RelationDetails GetFactionRelationStatus(const char* factionid);
	const char* GetLocalizedInteractiveNotificationKey(void);
	const char* GetLocalizedText(const uint32_t pageid, uint32_t textid, const char*const defaultvalue);
	MessageDetails GetMessageDetails(const uint32_t messageid);
	int GetNotificationID(const size_t num);
	size_t GetNumNotifications();
	FactionDetails GetOwnerDetails(UniverseID componentid);
	const char* GetPlayerZoneName(void);
	RelationDetails GetRelationStatus(const UniverseID componentid);
	SofttargetDetails GetSofttarget(void);
	ZoneDetails GetZoneDetails(const UniverseID zoneid);
	bool HasRemoteControl(void);
    bool IsExternalTargetMode(void);
	bool IsExternalViewActive(void);
	bool IsGateTransition(const UniverseID zone1id, const UniverseID zone2id);
	bool IsValidComponent(const UniverseID componentid);
	void NotifyDisplayNotification(const int notificationid);
	void SetConfigSetting(const char*const setting, const bool value);
	bool SetMapRenderTarget(const char*const rendertargettexture, const UniverseID referencecomponent, const bool mapmode);
    bool SetMapRenderTargetOnTarget(const char*const rendertargettexture, const UniverseID focuscomponentid, const UniverseID referencecomponent, const bool mapmode);
]]

-- settings
local config = {
	-- note that "-rendertarget" is a requirement from the GFX-system --- if not named like that, it would not be rendered at all
	renderTarget             = "ui\\core\\presentations\\eventmonitor\\eventmonitor_recovered\\eventmonitor-rendertarget",
	pipRenderTarget          = "ui\\core\\presentations\\eventmonitor\\eventmonitor_recovered\\border-rendertarget",
	displayPressHint         = true,  -- indicates whether we display the "Press A" text, when an interactive notification is displayed
	topRightPos              = true,  -- indicates whether the monitor should be positioned at the upper right (instead of the upper left corner of the screen)

	hudMonitorWidth = 640,  -- width of the eventmonitor in px
	cockpitMonitorWidth = 740,
	cockpitMonitorHeight = 512,
	hudMonitorScale = 0.716,
	cockpitMonitorScale = 1,
	cockpitMonitorOffsetX = -68,
	cockpitMonitorOffsetY = 78,
	notificationDelay = 5,    -- time (in s) a notification is being displayed - X3TC values: 100ms per character, min 4s, max 10s
	autoMapTime       = 7,    -- time (in s) a auto map (aka: map displayed in the eventmonitor as a response to a changed zone event) is being displayed
	-- #StefanLow --- get the time from the presentation directly rather than hardcoding it here
	appearTime        = 0.3,  -- time (in s) the eventmonitor needs to show-up when it was inactive before (0.1s longer, to make sure the final animation step is displayed too)
	priorization = {          -- priorization order (in cases of multiple requests from different systems, the one with the highest priority gets precedence)
		"notification",
		"automap",
		"softtarget",
		"externalTarget",
		"softenvironmentinfo",
		"environmentinfo"
	},

	-- table layout settings
	tableIconSize   =   80, -- size (in px) of icons in table rows
	tableTextOffset = -268, -- additional offset necessary to convert x-positions for text in tables

	-- notoriety settings
	notorietyIconColor = {	-- notoriety icons are not to be colored
		r = 255,
		g = 255,
		b = 255
	},

	-- relation text color (neutral, friendly, enemy text)
	relationColor = {
		[1] = {
			["r"] = 255, -- enemy
			["g"] =   0,
			["b"] =   0,
		},
		[2] = {
			["r"] =   0, -- neutral
			["g"] = 255,
			["b"] = 255,
		},
		[3] = {
			["r"] =   0, -- friendly
			["g"] = 255,
			["b"] = 255,
		},
		[4] = {
			["r"] =   0, -- own property
			["g"] = 255,
			["b"] =   0
		},
		[5] = {
			["r"] =   0, -- unknown (same as neutral)
			["g"] = 255,
			["b"] = 255,
		}
	},

	-- mouse related
	interactCursorIcon = "target", -- cursor icon used when hovering the mouse over the eventmonitor while in interactive notification is displayed

	-- notoriety bar color settings
	notorietyLEDColor = {
		[4] = { -- first lit (friendly) LED - aka: brightest one - also used as value-text-color
			r = 0,
			g = 255,
			b = 0
		},
		[3] = { -- second lit (friendly) LED
			r = 0,
			g = 255,
			b = 0
		},
		[2] = { -- third lit (friendly) LED
			r = 0,
			g = 196,
			b = 0
		},
		[1] = { -- fourht lit (friendly) LED - aka: darkest one
			r = 0,
			g = 132,
			b = 0
		},
		[0] = { -- inactive color value
			r = 50,
			g = 65,
			b = 78
		},
		[-1] = { -- first lit (enemy) LED - aka: darkest one
			r = 131,
			g = 0,
			b = 0
		},
		[-2] = { -- second lit (enemy) LED
			r = 163,
			g = 0,
			b = 0
		},
		[-3] = { -- third lit (enemy) LED
			r = 255,
			g = 0,
			b = 0
		},
		[-4] = { -- fourth lit (enemy) LED - aka: brightest one - also used as value-text-color
			r = 255,
			g = 0,
			b = 0
		}
	},

	-- notoriety value color
	notorietyValueColor = {
		[1] = { -- enemy
			r = 255,
			g = 0,
			b = 0
		},
		[2] = { -- neutral
			r = 90,
			g = 130,
			b = 153
		},
		[3] = { -- friendly
			r = 0,
			g = 255,
			b = 0
		}
	},

	-- matrix specifying the color index in notorietyColor for each relationValue - LEDElement pair - LEDs are specificed from element 1..8 (aka: light colors from right to left)
	notorietyColorMatrix = {
		[-4] = { 0, 0, 0, 0, -1, -2, -3, -4 },
		[-3] = { 0, 0, 0, 0, -2, -3, -4,  0 },
		[-2] = { 0, 0, 0, 0, -3, -4,  0,  0 },
		[-1] = { 0, 0, 0, 0, -4,  0,  0,  0 },
		[0]  = { 0, 0, 0, 0, 0, 0, 0, 0 },
		[1]  = { 0, 0, 0, 4, 0, 0, 0, 0 },
		[2]  = { 0, 0, 4, 3, 0, 0, 0, 0 },
		[3]  = { 0, 4, 3, 2, 0, 0, 0, 0 },
		[4]  = { 4, 3, 2, 1, 0, 0, 0, 0 }
	}
}

-- TODO: @ Stefan med - add proper localization support for basic UI strings
-- text array containing localized text
local L = {
	["Allied"]           = ffi.string(C.GetLocalizedText( 1001, 5203, "Allied")),
	["Enemy"]            = ffi.string(C.GetLocalizedText( 1001, 5201, "Enemy")),
	["Neutral"]          = ffi.string(C.GetLocalizedText( 1001, 5202, "Neutral")),
	["No Signal"]        = ffi.string(C.GetLocalizedText( 1001, 5204, "No Signal")),
	["Player"]           = ffi.string(C.GetLocalizedText( 1001, 5200, "Player")),
	["Press %s"]         = ffi.string(C.GetLocalizedText( 1015,  120, "Press %s")),
	["To:"]              = ffi.string(C.GetLocalizedText( 1001, 5205, "To"))..ffi.string(C.GetLocalizedText(1001, 120, ":")),
	["Unknown Faction"]  = ffi.string(C.GetLocalizedText(20212,  301, "Unknown Faction"))
}

-- private member data
local private = {
	anarkElements = { -- array of all Anark elements
		details = { -- array of Anark elements for detail overlays
			-- [type] = {					-- type being one of "extTable", "factionLadder", "full", "header", "notoriety", "tabular", "top"
				-- [element] = AnarkElement	-- the Anark element
				-- [active]  = true|false	-- indicates whether the element is active
			-- }
		},
		factionLadder = { -- array of Anark elements for the faction ladder
		    --[x]              = nil,   -- faction ladder LED component (1..8)
			iconTexture        = nil,   -- faction icon texture element
			valueText          = nil,   -- faction ladder value text element
			relationText       = nil,   -- faction ladder relation text element
			factionText        = nil    -- faction ladder faction text element
		},
		monitorElement         = nil,   -- monitor element
		notorietyBlinking      = nil,   -- blinking notoriety component
		iconElement            = nil,   -- icon element
		grainElement           = nil,   -- grain element for fadin/fadeout
		main                   = nil,   -- main element (containing the differene eventmonitor slides: inactive, icon, rendertarget)
		interactElement        = nil,   -- the element for the interactive eventmonitor notification effect
		backcolor              = nil,   -- the color background element
		background             = nil,   -- the background elements
		softtarget             = nil,   -- the softtarget element
		interactiveText        = nil    -- the "press A" text element
	},
	notificationsActive              = false, -- indicates whether the notification is active
	notifications = { -- notifications sorted by priority
		-- [priority] = { -- FIFO list for player notifications
		-- }
	},
	softtargetUpdate                 = nil,   -- requested softtarget
	softtargetID                     = nil,   -- softtarget ID (if any softtarget is active)
	softtargetTemplateConnectionName = nil,   -- softtarget template connection name (if a softtarget is active and it has a template connection specified)
	stateRequests = { -- list of active/inactive monitor states
		-- [priorityIndex] = true | false
	},
	currentState                    = nil,   -- the name of the current state
	mapActive                       = false, -- indicates whether the map is currently active
	resetMap                        = false, -- indicates whether we have to reset the map
	autoHideMapTime                 = nil,   -- time at which the automap will disappear (nil, if no auto map active atm)
	environmentTargetID             = 0,     -- the ID of the environment object target (0 if none is set)
	softEnvironmentMessageID        = nil,   -- the message ID of the current soft environment object (if any)
	notorietyLadderFactionDetails   = nil,   -- data of the faction associated with the notoriety ladder (nil => inactive notoriety ladder, or component used if specified)
	-- {
		-- [factionID]   = factionID -- the faction ID
		-- [factionName] = string    -- the faction name
		-- [factionIcon] = string    -- the faction icon
	-- }
	notorietyLadderComponentDetails = nil,   -- data of the component associated with the notoriety ladder (nil => inactive notoriety ladder, or faction used if specifeid - takes precedence over notorietyLadderFactionDetails)
	-- {
		-- [component]        = componentID | nil -- nil, if the component is no longer valid
		-- [factionName]      = string -- the component's owning faction name
		-- [relationDetails]  = {
			-- [relationStatus]   = number -- the relation status of the component (0 = enemy, 1 = neutral, 2 = friend, 3 = player property, 4 = unknown)
			-- [relationValue]    = number -- the relation value of the component
			-- [relationLEDValue] = number -- the relation LED value of the component
			-- [isBoostedValue]   = boolean -- indicates whether the current relation is boosted (true) or permanent (false)
		-- }
	-- }
	overlayInfo                     = nil,   -- information used for overlay layer
	-- {
		-- same structure as returned from GetEventMonitorDetailsBridge() plus:
		-- [referenceComponent] = componentID | nil -- the reference component for which live-update data is to be queried (nil if no component)
		-- [radarComponent]     = componentID | 0   -- the component to highlight on the radar, when displayed
        -- [focusComponent]     = componentID | 0   -- the component which the radar should be focused on (0, if focused on current player controlled)
	-- }
	previousRelationDetails         = nil,   -- the relationDetails used in the previous frame (same table structure as notorietyLadderComponentDetails.relationDetails)
	autoClose                       = nil,   -- time at which the current active state closes
	currentNotification             = nil,   -- the current notification (if any) - i.e. not the ID
	pipNotificationID               = nil,   -- the ID of current botification in the picture in picture mode
	pipCutsceneID                   = nil,   -- the ID of current cutscene in the picture in picture mode
	curSofttargetAction             = nil,   -- current softtarget action (if any)
	factionLadderActive             = false, -- indicates whether the faction ladder is active
	liveUpdateValues                = nil,   -- liveUpdateValues which are currently displayed (nil, if no values are displayed atm)
	-- {
		-- [frame] {	-- live-update values for the given frame
			-- [x] = {
				-- ["element"] -- anark text element, retrieving the constructed text
				-- ["referenceComponent"] = componentID | nil -- the component for which placeholders are to be queried
				-- ["junks"] = {
					-- [x] = {
						-- ["isPlaceholder"] = true|false -- indicates whether the entry is a placeholder (true) or plain text (false)
						-- ["text"] = text|placeholder -- the text to be displayed or placeholder
					-- }
				-- }
			-- }
		-- }
	-- }
	monitorActive                   = true,  -- indicates whether the monitor is active (in case of the cockpit monitor, it's always active)
	initialState                    = nil,   -- the state the monitor will enter once it's fully active
	appearFinished                  = nil,   -- if set indicates that the monitor's appear animation is running - set to the time when the appear-animation is done
	mapText                         = nil,   -- the text to be displayed on the holomap (if any)
	showDetails                     = true,  -- indicates whether the eventmonitor display shows the details info
	radarEnabled                    = false, -- indicates whether the game setting is set to have the radar displayed
	shipRadarEnabled                = false, -- indicates whether the player ship's radar system is enabled (disabled at gamestart during campaign)
	radarMapMode                    = false, -- indicates whether the radar is in map (true) or 45� (false) mode
	pipActive                       = false, -- indicates whether the pIp-window is active atm
	scheduledOverlays = {
		-- frame = { -- frame being one of: "notorietyFrame", "topFrame", "headerFrame", "fullFrame", "tableFrame", "extTableFrame"
		--    ["startTime"] = time at which the frame appears
		--    ["endTime"]   = time at which the frame disappears
		-- #StefanLow - shown could be combined with anarkElements.details maybe
		--    ["shown"]     = true/false - indicates whether the frame is displayed atm
		-- }
	},
	environmentObjectSupport = true,  -- indicates whether the eventmonitor support for environment object handling is enabled
	allowRadar               = true,  -- if set to true, the eventmonitor can display the radar in inactive state
	hudMonitor               = false, -- indicates whether we are running the hud eventmonitor
	showAutoMapEvents        = true,  -- indicates whether we show automap-events on the eventmonitor when the player changes zones
    externalTargetMode       = false, -- indicates whether we are currently in external target mode
    defaultRadarActive       = false, -- indicates whether the default radar (aka the one showing the player ship/drone/target) is active atm
}

-- local functions forward declarations
local activateCockpitMonitorMode
local activateHudMonitorMode
local activateMonitor
local activatePIPNotification
local activateState
local changeState
local closeCurrentState
local constructPlaceholderText
local convertAlignment
local convertDurations
local createMapDisplay
local createPlayerMapDisplay
local createNoSignalDisplay
local deactivateCutscene
local deactivateInteraction
local deactivateMonitor
local deactivateNotification
local deactivatePIPNotification
local deactivateState
local getEventMonitorDetailsBridge
local getLEDColor
local getTextJunks
local hasNotifications
local hideAutoMap
local hideDetailOverlay
local hideDetailSlide
local hideEnvironmentInfo
local hideNormalFrameOverlay
local hideNotification
local hideNotorietyFrameOverlay
local hideOverlay
local hideSoftEnvironmentInfo
local hideSofttarget
local initAutoMapEventSupport
local initEnvironmentObjectSupport
local initMousePicking
local initNotifications
local initNotorietyData
local isActiveLED
local isBlinkingLED
local isHighestState
local isRadarEnabled
local onSelectAction
local onChangedEnvironmentObject
local onChangedSoftEnvironmentObject
local onChangedZone
local onCutsceneStopped
local onEnableRadar
local onExternalTargetViewActive
local onExternalTargetViewInactive
local onGamePlanChange
local onMouseClick
local onShowNotification
local onToggleEventMonitorDetails
local onToggleRadarMode
local onUnlock
local onSofttargetChanged
local processLiveUpdateValues
local processOverlaySchedule
local queueNotification
local prepareLiveUpdateText
local removeLiveUpdateValues
local removeStateRequest
local requestState
local scheduleDetailOverlay
local setAlignedTextElement
local setCheckedText
local setCockpitMode
local setHUDMode
local setTableRowElement
local setTextElement
local showAutoMap
local showDetailSlide
local showEnvironmentInfo
local showExtTableFrameOverlay
local showSoftEnvironmentInfo
local showMainFrameOverlay
local showNotification
local showNotorietyFrameOverlay
local showOverlay
local showSofttarget
local showTableFrameOverlay
local showUnqueuedNotification
local switchNotification
local toggleEventMonitorDetails
local toggleRadar
local toggleRadarMode
local triggerGrain
local updateActiveState
local updateEventMonitorDetails
local updateEventMonitorDisplay
local updateNotifications
local updateNotorietyLadder
local updateRelationStatusData

---------------------------------
-- Gameface lifetime functions --
---------------------------------
function self:onInitialize()
	-- initialize Anark elements
	local contract = getElement("Scene.UIContract")
	local anarkElements = private.anarkElements
	anarkElements.monitorElement        = getElement("Scene.Layer.Monitor")
	anarkElements.background            = getElement("background", anarkElements.monitorElement)
	anarkElements.grainElement          = getElement("effects_add", anarkElements.monitorElement)
	anarkElements.interactElement       = getElement("interact", anarkElements.monitorElement)
	anarkElements.interactHeaderElement = getElement("interact_header", anarkElements.monitorElement)
	anarkElements.main                  = getElement("main", anarkElements.monitorElement)
	anarkElements.backcolor             = getElement("backcolor", anarkElements.monitorElement)
	anarkElements.softtarget            = getElement("softtarget", anarkElements.monitorElement)
	anarkElements.notorietyBlinking     = getElement("brblink", anarkElements.monitorElement)
	anarkElements.iconElement           = getElement("icon.icon.icon.material.icon", anarkElements.main)
	anarkElements.rendertargetBorder    = getElement("rendertarget_border", anarkElements.monitorElement)
	anarkElements.interactiveText       = getElement("Text", anarkElements.interactElement)
	local detailElements = anarkElements.details
	detailElements.header = {
		["element"] = getElement("details_header", anarkElements.monitorElement),
		["active"] = false
	}
	detailElements.extTable = {
		["element"] = getElement("details_table_ext", anarkElements.monitorElement),
		["active"] = false
	}
	detailElements.notoriety = {
		["element"] = getElement("details_br", anarkElements.monitorElement),
		["active"] = false
	}
	detailElements.factionLadder = {
		["element"] = getElement("row.factionladder", detailElements.notoriety.element),
		["active"] = false
	}
	detailElements.full = {
		["element"] = getElement("details_full", anarkElements.monitorElement),
		["active"] = false
	}
	detailElements.tabular = {
		["element"] = getElement("details_table", anarkElements.monitorElement),
		["active"] = false
	}
	detailElements.top = {
		["element"] = getElement("details_top", anarkElements.monitorElement),
		["active"] = false
	}
	local factionLadderElements = anarkElements.factionLadder
	factionLadderElements.iconTexture  = getElement("row.faction_icon.material.texture", detailElements.notoriety.element)
	factionLadderElements.valueText    = getElement("value", detailElements.factionLadder.element)
	factionLadderElements.factionText  = getElement("row.faction_name", detailElements.notoriety.element)
	factionLadderElements.relationText = getElement("row.faction_state", detailElements.notoriety.element)
	for i = 1, 8 do
		factionLadderElements[i] = getElement("faction"..i, detailElements.factionLadder.element)
	end

	-- initialize event monitor state requests
	for _, value in ipairs(config.priorization) do
		private.stateRequests[value] = false
	end

	-- init private.showDetails - defaults to true, if not set
	private.showDetails = C.GetConfigSetting("eventmonitordetails") ~= 0
	-- init private.radarEnabled - defaults to true, if not set
	private.radarEnabled = C.GetConfigSetting("disableradar") == 0
	-- init private.radarMapMode - defaults to false, if not set
	private.radarMapMode = C.GetConfigSetting("radarmode") == 1

	registerForEvent("cutsceneStopped", contract, onCutsceneStopped)
	registerForEvent("enableRadar", contract, onEnableRadar)
	registerForEvent("executeNotification", contract, onMouseClick)
	registerForEvent("externalTargetViewActive", contract, onExternalTargetViewActive)
	registerForEvent("externalTargetViewInctive", contract, onExternalTargetViewInactive)
	registerForEvent("gameplanchange", contract, onGamePlanChange)
	registerForEvent("onUnlock", contract, onUnlock)
	registerForEvent("selectAction", contract, onSelectAction)
	registerForEvent("showNotification", contract, onShowNotification)
	registerForEvent("softtargetChanged", contract, onSofttargetChanged)
	registerForEvent("toggleEventMonitorDetails", contract, onToggleEventMonitorDetails)
	registerForEvent("toggleRadarMode", contract, onToggleRadarMode)

	-- register for relevant eventmonitor events
	NotifyOnCutsceneStopped(contract)

	-- preload render target to prevent stuttering
	PrepareRenderTarget(config.renderTarget)
	PrepareRenderTarget(config.pipRenderTarget)

    -- set whether we allow to display the radar and enable displaying environment object support (which we do in all but the 1st-person modes)
    local firstperson = IsFirstPerson()
    private.allowRadar = not firstperson
	-- #coreUIMed - simplify environmentObjectSupport by just removing the state requests (instead of keeping that additional state)?
	private.environmentObjectSupport = not firstperson
	private.shipRadarEnabled = C.AreShipSystemsEnabled()

	-- determine external view mode
	local external = C.IsExternalViewActive()
	if external then
		-- only required in external mode - otherwise it's false
		private.externalTargetMode = C.IsExternalTargetMode()
		if private.externalTargetMode then
			-- no need to enforce - will be initialized implicitly
			requestState("externalTarget", false)
		end
	end

	-- perform any hud monitor specific initialization
	if firstperson or external or C.HasRemoteControl() then
		setHUDMode()
	else
		setCockpitMode()
	end

	-- initialize mouse picking
	initMousePicking()

	-- update current notifications in the system
	initNotifications()

	-- environment object handling
	initEnvironmentObjectSupport(contract)

	-- automap event handling
	initAutoMapEventSupport(contract)
end

function self:onUpdate()
	local curTime = getElapsedTime()

	-- #coreUIMed - reenable this check, once we add proper support for handling ship system disabling...
	-- then also revert the changes done as part of this revision
	--if not private.shipRadarEnabled then
		-- check this for as long as the systems are disabled --- since this is just the case shortly at the beginning of the campaign, it's acceptable to do this until it's enabled
		-- #coreUIMed --- replace checks with proper event handling
		local shipSystemsActive = C.AreShipSystemsEnabled()
		if shipSystemsActive ~= private.shipRadarEnabled then
			private.shipRadarEnabled = shipSystemsActive
			if isRadarEnabled() and private.allowRadar then
				-- make sure that the radar gets enabled, once the ship systems are enabled
				updateActiveState(true)
			end
		end
	--end

	if private.hudMonitor and private.appearFinished ~= nil then
		-- appear animation has been triggered, make sure we activate the proper state, when the animation is done
		if curTime > private.appearFinished then
			private.monitorActive = true
			private.appearFinished = nil
			activateState(private.initialState)
			private.initialState = nil
		end
	end

	if private.autoClose and private.autoClose < curTime then
		closeCurrentState(false)
		return
	end

	-- TODO: med - combine with autoClose?
	if private.autoHideMapTime and private.autoHideMapTime < curTime then
		hideAutoMap()
	end

	if private.softtargetUpdate then
		if next(private.softtargetUpdate) then
			showSofttarget(table.unpack(private.softtargetUpdate))
		else
			hideSofttarget()
		end
		private.softtargetUpdate = nil
	end

	processOverlaySchedule()

	if private.notorietyLadderFactionDetails or private.notorietyLadderComponentDetails then
		updateNotorietyLadder(private.notorietyLadderFactionDetails, private.notorietyLadderComponentDetails)
	end

	if private.liveUpdateValues ~= nil then
		processLiveUpdateValues()
	end

	-- perform any pending map-reset-calls --- we don't do these immediately, so to not unnecessarily recreate a map which we are closing and then just recreating directly again
	-- if we wouldn't do that, we'd see animations on the eventmonitor map whenever the target is changed
	if private.resetMap then
		UnsetMapRenderTarget()
		private.resetMap = false
		private.mapActive = false -- just to be double-sure --- it's supposed to already have been set to false
        private.defaultRadarActive = false
	end

	-- #coreUIMed this is way too hacky/complicated --- refactor the default radar handling completely
	-- note: this is added here for partial support of changing external targets (see XR-1060) - while atm not being required (since the external target view component is fixed, it's kept here to ease the
	-- implementation for XR-1060
    if private.defaultRadarActive then
        local focusComponent = 0
        if private.externalTargetMode then
            focusComponent = C.GetExternalTargetViewComponent()
        end

        if private.curDescription.focusComponent ~= focusComponent then
            -- we need to switch the focus target for the radar
            private.curDescription.focusComponent = focusComponent
            if focusComponent ~= 0 then
                private.mapActive = C.SetMapRenderTargetOnTarget(config.renderTarget, focusComponent, private.curDescription.radarComponent, private.radarMapMode)
            else
                private.mapActive = C.SetMapRenderTarget(config.renderTarget, private.curDescription.radarComponent, private.radarMapMode)
            end
        end
    end
end

-------------------------------------
-- Presentation specific callbacks --
-------------------------------------
function onSelectAction(_, actionNumber)
	private.curSofttargetAction = actionNumber

	if private.currentState == "softtarget" then
		local details, success = getEventMonitorDetailsBridge(tostring(private.softtargetID), private.softtargetTemplateConnectionName, private.curSofttargetAction)
		if not success then
			private.curSofttargetAction = nil -- reset
			return -- in case of any error, ignore the onSelectAction-call - error already logged in getEventMonitorDetailsBridge
		end

        local focusComponent = 0
        if private.externalTargetMode then
            focusComponent = C.GetExternalTargetViewComponent()
        end

		updateEventMonitorDetails(details, true, private.softtargetID, focusComponent)
		updateEventMonitorDisplay(details, true, false)
	end
end

function onChangedZone(_, oldzone, newzone)
	if not private.showAutoMapEvents then
		return -- auto map events are disabled
	end

	if oldzone == nil then
		-- this might happen when a previous zone was destroyed prior to dispatching this call
		-- it is considered an edge case and hence we simply skip displaying an auto map event
		-- so we don't have to bother at all
		return
	end

	local oldZoneDetails = C.GetZoneDetails(oldzone)
	-- note: we must store the old zone name here, since the following call to GetZoneDetails(newzone) would overwrite the const-chars returned by GetZoneDetails() - fixes XR-234
	local oldZoneName = ffi.string(oldZoneDetails.ZoneName)
	local newZoneDetails = C.GetZoneDetails(newzone)

	local highwayChange = (oldZoneDetails.isLocalHighway ~= newZoneDetails.isLocalHighway) or (oldZoneDetails.isSuperHighway ~= newZoneDetails.isSuperHighway)
	-- note: we must also check for highway change events, since the to be displayed UINames for highways and current zone might be the same when the player enters/leaves highways (especially zone highways)
	if not highwayChange and oldZoneName == ffi.string(newZoneDetails.ZoneName) then
		return -- we switched a zone, but not the hotspot --- hence, no automap event (see mail: "Re: #DISCUSSIONREPORT# Empty space handling on map")
	end

	if newZoneDetails.isLocalHighway then
		-- case: entering local highway
		showAutoMap(L["To:"].." "..tostring(ffi.string(newZoneDetails.ZoneName)))
	elseif newZoneDetails.isSuperHighway then
		-- case: entering super highway
		showAutoMap(L["To:"].." "..tostring(ffi.string(newZoneDetails.SectorName)))
	else -- it's a zone
		if oldZoneDetails.isLocalHighway then
			-- case: leaving local highway
			-- we assume that when issuing the call here, the player is still close to the highway he dropped off and hence
			-- getting the highway section closest to the current player position returns the highway section the player previously dropped off
			showAutoMap(tostring(ffi.string(newZoneDetails.ZoneName)))
		elseif oldZoneDetails.isSuperHighway then
			-- case: leaving super highway
			showAutoMap(tostring(ffi.string(newZoneDetails.SectorName)))
		else
			-- zone <-> zone case
			if C.IsGateTransition(oldzone, newzone) then
				-- case: leaving gate
				showAutoMap(tostring(ffi.string(newZoneDetails.ClusterName)))
			else
				-- case: changed zone
				showAutoMap(tostring(ffi.string(newZoneDetails.ZoneName)))
			end
		end
	end
end

function onCutsceneStopped(_, cutsceneid)
	if private.pipCutsceneID and private.pipCutsceneID == cutsceneid then
		deactivatePIPNotification()
	end
	if private.curDescription and private.curDescription.cutsceneID == cutsceneid then
		closeCurrentState(false) -- notification done, due to interrupted cutscene
	end
end

function onEnableRadar(_, enable)
	enableRadar(enable)
end

function onExternalTargetViewActive()
	private.externalTargetMode = true
	requestState("externalTarget")
end

function onExternalTargetViewInactive()
	private.externalTargetMode = false
	remoteStateRequest("externalTarget")
end

function onGamePlanChange(_, gameplan)
	local mode = "hud"
	if gameplan == "firstperson" or gameplan == "externalfirstperson" then
        private.allowRadar = false
		private.externalTargetMode = false
		private.environmentObjectSupport = false
	elseif gameplan == "external" then
        private.allowRadar = true
		-- only needs to be determined in "external" case, otherwise it's false implicitly
		private.externalTargetMode = C.IsExternalTargetMode()
		private.environmentObjectSupport = true
	elseif gameplan == "drone" then
        private.allowRadar = true
		private.externalTargetMode = false
		private.environmentObjectSupport = true
    else -- cockpit
        private.allowRadar = true
		private.externalTargetMode = false
		private.environmentObjectSupport = true
		mode = "cockpit"
	end

	-- request the external target mode state, if in external target view
	if private.externalTargetMode then
		requestState("externalTarget")
	else
		removeStateRequest("externalTarget")
	end

	-- ensure the environment info is removed if displayed atm
	if not private.environmentObjectSupport then
		hideEnvironmentInfo()
		hideSoftEnvironmentInfo()
	end

	-- set the correct mode
	if mode == "hud" then
		setHUDMode()
	else -- mode == "cockpit"
		setCockpitMode()
	end
end

function onMouseClick(_, delayed)
	if not delayed then
		-- #StefanLow - review whether currentNotification could have changed
		RaisePlayerInteractionEvent(private.curDescription.interactionID)
	end
end

function onShowNotification(_, notificationID)
	showNotification(notificationID)
end

function onToggleEventMonitorDetails()
	toggleEventMonitorDetails()
end

function onToggleRadarMode()
	toggleRadarMode()
end

function onChangedEnvironmentObject()
	if private.environmentObjectSupport then
		hideEnvironmentInfo()

		local objectid = C.GetEnvironmentObject()
		if objectid ~= 0 then
			showEnvironmentInfo(objectid)
		end
	end
end

-- #StefanMed - combine this with onChangedEnvironmentObject
-- This is used for info-points to set messageIDs as the environment object - should combine with the
-- EnvironmentObject-changed event and support combinations of objectID / connection to find the
-- corresponding message or somesuch
function onChangedSoftEnvironmentObject(_, messageID)
	if private.environmentObjectSupport then
		hideSoftEnvironmentInfo()

		if messageID ~= nil then
			showSoftEnvironmentInfo(messageID)
		end
	end
end

function onSofttargetChanged(_, softtargetmessageid)
	private.curSofttargetAction = nil -- reset upon loss of softtarget

	if softtargetmessageid then
		local softtargetDetails = C.GetSofttarget()

		-- we have to ensure again that there's really a softtarget because we'd also get this call for already destroyed softtarget messages (those, which
		-- were removed/destroyed in-between the softtarget dispatch call)
		if softtargetDetails.softtargetID == 0 then
			-- softtarget message has been destroyed
			return
		end

		private.softtargetUpdate = {softtargetDetails.softtargetID, ffi.string(softtargetDetails.softtargetConnectionName)}
	else
		private.softtargetUpdate = {}
	end
end

function onUnlock()
	-- reset the eventmonitor, so it displays the correct state

	-- #coreUIHigh -- should this update externalviewstates and HUD/cockpit mode here?

	-- #coreUILow --- XT-3829 - ultimately we'd actually handle restoring the correct eventmonitor state correctly meaning:
		-- update to the correct soft environment info, if set
		-- set the correct softtarget, if we have one
		-- set the dialog map correctly, if it's active
		-- do not abort the cutscene, if it's still active upon unlocking
		-- proper handle the current selected softtarget action
	-- however, all of these are minor things, and hence can be handled with a very low priority

	-- hide any previous state, in-case it was kept before locking the monitor
	hideSoftEnvironmentInfo()
	private.curSofttargetAction = nil
	hideSofttarget()
	deactivatePIPNotification()

	-- update current notifications in the system
	initNotifications()

	-- note: must be done after initNotifications - otherwise, notifications are still set to active and closeCurrentState() would switch to the next notification (unnecessarily)
	if private.curDescription then
		closeCurrentState(true) -- we must force a state-update here, since we might have missed a notification/event and we didn't unset the map, in case the UI changed modes (for instance from Cockpit to FirstPerson mode)
	end

	if private.environmentObjectSupport then
		-- set initial state of environmental info
		local environmentTargetID = C.GetEnvironmentObject()
		if environmentTargetID ~= 0 then
			showEnvironmentInfo(environmentTargetID)
		else
			hideEnvironmentInfo()
		end
	end

	-- normally we'd have to call updateActiveState here (case: showing "no signal" initially) --- however, that's already done in initNotifications() and show/hideEnvironmentInfo()
end

-------------------------------------
-- Presentation specific functions --
-------------------------------------
function activateMonitor(state)
	-- #coreUIMed - this looks completely incorrect now...
	private.initialState = state

	if private.monitorActive then
		return	-- monitor already active, nothing to do
	end

	if (private.allowRadar or (state ~= "inactive")) and (private.appearFinished == nil) then
		ShowPresentation()
		-- trigger the appear animation
		goToSlide(private.anarkElements.background, "appear")
		PlaySound("ui_mon_eve_hud_on_core")
		private.appearFinished = getElapsedTime() + config.appearTime
	end
end

function activateState(state)
	local details
	local radarComponent = 0
    local focusComponent = 0
	local playSound = true
    if private.externalTargetMode then
        focusComponent = C.GetExternalTargetViewComponent()
    end
	if state == "softtarget" then
		details                    = getEventMonitorDetailsBridge(tostring(private.softtargetID), private.softtargetTemplateConnectionName, private.curSofttargetAction)
		radarComponent             = private.softtargetID
        private.defaultRadarActive = private.allowRadar and isRadarEnabled()
		goToSlide(private.anarkElements.softtarget, "active")
	elseif state == "externalTarget" then
		details                    = getEventMonitorDetailsBridge(tostring(focusComponent), nil, nil)
        private.defaultRadarActive = private.allowRadar and isRadarEnabled()
		goToSlide(private.anarkElements.softtarget, "active")
	elseif state == "environmentinfo" then
		details                    = getEventMonitorDetailsBridge(tostring(private.environmentTargetID))
		radarComponent             = private.environmentTargetID
        private.defaultRadarActive = private.allowRadar and isRadarEnabled()
	elseif state == "softenvironmentinfo" then
		local messageDetails = C.GetMessageDetails(private.softEnvironmentMessageID)
		details = {}
		if messageDetails.componentID ~= 0 then
			-- this can happen, since the game system notifies us via an event of the changed soft environment message (see XR-110)
			-- if we just removed the message and notified the game system on that removal, it didn't yet fire the event and we'd still
			-- have the softenvironmentinfo-request active
			details                    = getEventMonitorDetailsBridge(tostring(messageDetails.componentID), ffi.string(messageDetails.connectionName))
			radarComponent             = messageDetails.componentID
            private.defaultRadarActive = private.allowRadar and isRadarEnabled()
		end
	elseif state == "notification" then
		private.notificationsActive = true
		updateNotifications() -- update the notification immediately, so to correctly swap to the next one, if the notification slide was reactivated
        focusComponent = 0
		triggerGrain()
	elseif state == "automap" then
		private.autoHideMapTime    = getElapsedTime() + config.autoMapTime
		details                    = createMapDisplay()
        focusComponent             = 0
        private.defaultRadarActive = false
	elseif state == "inactive" then
		-- #coreUIMed - better alternative might be to introduce a default radar state --- so we do not have to distinguish based on hudMonitor and allowRadar settings?
		if private.hudMonitor and (not private.allowRadar or not isRadarEnabled()) then
			deactivateMonitor()
            private.defaultRadarActive = false
			playSound = false
		else
			details = createPlayerMapDisplay()
            private.defaultRadarActive = isRadarEnabled()
		end
	end

	-- #StefanMed - also add handling for notifications to have a common code flow
	if details ~= nil then
		if state ~= "softtarget" then
			-- only in case of the softtarget, we set (aka: highlight) the target on the map
			radarComponent = 0
		end
		updateEventMonitorDetails(details, state == "softtarget" or state == "externalTarget", radarComponent, focusComponent)
		updateEventMonitorDisplay(details, true, false)
	end

	if playSound then
		PlaySound("ui_mon_eve_change_core")
	end

	-- #StefanMed add support to abort state activation (on error)
end

function changeState(state, force)
	if not force and private.currentState == state then
		return -- correct slide is already active
	end

	local previousState = private.currentState
	private.currentState = state

	deactivateState(previousState)

	if private.monitorActive then
		activateState(state)
	else
		-- if the monitor is not yet active, we have to activate it first (aka: display the appear-animation) before we can show something
		activateMonitor(state)
	end
end

function closeCurrentState(force)
	private.autoClose = nil

	if private.notificationsActive then
		-- go to next notification
		updateNotifications()
		return
	end

	removeStateRequest(private.currentState, force)
end

function convertAlignment(alignment)
	if alignment == "left" then
		return 0
	elseif alignment == "center" then
		return 1
	else -- right
		return 2
	end
end

-- we convert any 0-duration to nil to indicate indifinite durations
-- that simplifies handling lateron, since we do not have to check for nil | 0
function convertDurations(description)
	if description.mainFrameTimings and description.mainFrameTimings.duration == 0 then
		description.mainFrameTimings.duration = nil
	end

	if description.notorietyFrameTimings and description.notorietyFrameTimings.duration == 0 then
		description.notorietyFrameTimings.duration = nil
	end

	if description.duration and description.duration == 0 then
		description.duration = nil
	end
end

-- function takes junks and craetes the to be displayed text with all placeholders having been replaced
function constructPlaceholderText(junks, component)
	local text = ""

	for _, entry in ipairs(junks) do
		if not entry.isPlaceholder then
			text = text..entry.text
		else
			local entryText = GetLiveDataBridge(entry.text, component)
			if entryText == nil then
				-- if the call didn't return any value, add the placeholder itself
				text = text.."$"..entry.text.."$"
			else
				text = text..entryText
			end
		end
	end

	return text
end

function createMapDisplay()
	local details = {
		["mainFrameTimings"] = {
			["appear"] = 0 -- show instantly
		},
		["showMap"] = true,
		["details"] = {
			["layout"] = "header",
			["header"] = {
				["text"]  = private.mapText,
				["color"] = {
					["r"] = 255,
					["g"] = 255,
					["b"] = 255
				},
				["font"] = "Zekton",
				["fontsize"] = 28,
			},
			["headerBackground"] = { -- bright blue
				["r"] = 88,
				["g"] = 122,
				["b"] = 145
			}
		}
	}

	return details
end

function createPlayerMapDisplay()
	local details = {
		["mainFrameTimings"] = {
			["appear"] = 0 -- show instantly
		},
		["showMap"] = isRadarEnabled(),
		["details"] = {
			["layout"] = "header",
			["header"] = {
				["text"] = ffi.string(C.GetPlayerZoneName()),
				["color"] = {
					["r"] = 255,
					["g"] = 255,
					["b"] = 255
				},
				["font"] = "Zekton",
				["fontsize"] = 28,
			},
			["headerBackground"] = { -- bright blue
				["r"] = 88,
				["g"] = 122,
				["b"] = 145
			}
		}
	}

	return details
end

function createNoSignalDisplay()
	local details = {
		["mainFrameTimings"] = {
			["appear"] = 0 -- show instantly
		},
		["details"] = {
			["layout"] = "long",
			["header"] = {
				["text"]  = L["No Signal"],
				["color"] = {
					["r"] = 255,
					["g"] = 255,
					["b"] = 255
				},
				["font"] = "Zekton",
				["fontsize"] = 28,
			},
			["headerBackground"] = { -- bright blue
				["r"] = 88,
				["g"] = 122,
				["b"] = 145
			}
		}
	}

	return details
end

function deactivateCutscene()
	if private.curDescription and private.curDescription.cutsceneID then
		StopCutscene(private.curDescription.cutsceneID)
		private.curDescription.cutsceneID = nil
		if private.curDescription.deleteDescriptor then
			ReleaseCutsceneDescriptor(private.curDescription.cutsceneDescriptor)
			private.curDescription.cutsceneDescriptor = nil
		end
	end
end

function deactivateInteraction()
	if private.curDescription and private.curDescription.interactionDescriptor then
		if private.activeInteractElement then
			goToSlide(private.activeInteractElement, "inactive")
			private.activeInteractElement = nil
		end
		EventmonitorInteractionHidden(private.curDescription.interactionDescriptor)
		if private.curDescription.deleteDescriptor then
			ReleaseInteractionDescriptor(private.curDescription.interactionDescriptor)
			private.curDescription.interactionDescriptor = nil
		end
	end
end

function deactivateMonitor()
	updateEventMonitorDisplay(nil, false, false)
	private.monitorActive = false
	goToSlide(private.anarkElements.background, "inactive")
	PlaySound("ui_mon_eve_hud_off_core")
	HidePresentation()
end

function deactivateNotification()
	if private.currentNotification then
		-- also deactivate a cutscene (if it's still running that is)
		deactivateCutscene()

		-- also deactivate eventmonitor interaction (if it was active in the previous notification)
		deactivateInteraction()

		hideDetailOverlay()

		ReleaseNotification(private.currentNotification.ID)
		private.currentNotification = nil
	end
end

function deactivateState(state)
	private.autoClose = nil

	-- schedule any previously displayed overlay frame to close
	hideDetailOverlay()

	-- deactivate any cutscene (is used for notifications as well as other "normal" cases like softtarget display)
	deactivateCutscene()

	-- deactivate any previous eventmonitor interaction (is used for notifications as well as other "normal" cases like softtarget display)
	deactivateInteraction()

	-- deactivate the background color element
	goToSlide(private.anarkElements.backcolor, "inactive")

	if state == "notification" then
		deactivateNotification()
		private.notificationsActive = false
		-- entirely deactivate notifications, if we just displayed the last one
		if not hasNotifications() then
			private.stateRequests["notification"] = false
		end
	elseif state == "automap" then
		if private.mapActive then
			private.resetMap = true
		end
	elseif state == "softtarget" or state == "externalTarget" then
		goToSlide(private.anarkElements.softtarget, "inactive")
	end
end

-- #StefanMed - simplify getEventMonitorDetailsBridge, updateEventMonitorDetails, and updateEventMonitorDisplay - they should be combinable now
function getEventMonitorDetailsBridge(componentID, connectionName, currentAction)
	-- note: on error, in the GetEventmonitorDetails()-call, we'd end up with a nil-return here
	local details = GetEventMonitorDetailsBridge(componentID, connectionName, currentAction)

	local success = details ~= nil
	if not success then
		DebugError("Eventmonitor error. Failed to retrieve details from GetEventmonitorDetails. Reverting to default handling.")
		details = {} -- revert using an empty details container and fill with default values
	end

	-- patch the returned data to comply to our internal requirements
	details.referenceComponent = componentID

	return details, success
end

function activateCockpitMonitorMode()
	if private.hudMonitor then
		return -- cockpit monitor settings only apply to the cockpit eventmonitor
	end

	-- cockpit EM is always active
	private.monitorActive = true

	SetRenderTargetOneToOne()

	local offsetx = config.cockpitMonitorOffsetX * config.cockpitMonitorScale
	local offsety = config.cockpitMonitorOffsetY * config.cockpitMonitorScale

	setAttribute(private.anarkElements.monitorElement, "scale.x", config.cockpitMonitorScale)
	setAttribute(private.anarkElements.monitorElement, "scale.y", config.cockpitMonitorScale)

	setAttribute(private.anarkElements.monitorElement, "position.x", -config.cockpitMonitorWidth / 2 + offsetx)
	setAttribute(private.anarkElements.monitorElement, "position.y", config.cockpitMonitorHeight / 2 + offsety)
end

function activateHudMonitorMode()
	-- initially the hud eventmonitor is inactive
	private.monitorActive = false
	-- initial state is "inactive" in the first-person case
	private.currentState = "inactive"

	SetFullScreenOneToOne()
	local screenWidth, screenHeight = getScreenInfo()
	-- ensure that we do not position the 1:1-mapped presentation on subpixels, by moving the entire element by one pixel to the bottom/right, if the
	-- screenWidth or screenHeight is odd
	if screenWidth % 2 ~= 0 then
		screenWidth = screenWidth - 1 -- make it one pixel smaller, so we shift it one pixel to the right from the left screen edge
	end
	if screenHeight % 2 ~= 0 then
		screenHeight = screenHeight - 1 -- make it one pixel smaller, so we shift it one pixel to the bottom from the upper screen edge
	end

	local posx
	local posy = screenHeight/2
	if config.topRightPos then
		posx = screenWidth/2 - config.hudMonitorWidth
	else
		posx = -screenWidth/2
	end

	setAttribute(private.anarkElements.monitorElement, "scale.x", config.hudMonitorScale)
	setAttribute(private.anarkElements.monitorElement, "scale.y", config.hudMonitorScale)

	setAttribute(private.anarkElements.monitorElement, "position.x", posx)
	setAttribute(private.anarkElements.monitorElement, "position.y", posy)
end

function getLEDColor(LEDElementNumber, relationLEDValue)
	local colorIndex = config.notorietyColorMatrix[relationLEDValue][LEDElementNumber]
	return config.notorietyLEDColor[colorIndex]
end

function getTextJunks(text)
	if type(text) ~= "string" then
		return text -- early out --- nil or number can return directly --- this ensures that the following algorithm doesn't have to deal with number types and #text won't issue a Lua error
	end

	local junks = {}

	local placeHolderStart = false
	local placeholderFound = false
	local plainText = ""
	local placeholder = ""

	for i = 1, #text do
		local w = string.sub(text, i, i)
		if w == "$" then
			if not placeHolderStart then
				placeHolderStart = true
			else -- found a $ after a placeholder was started
				-- check if there's any recorded character in the placeholder-text - if so, it's an endtag - otherwise it's an escaped $$
				if placeholder == "" then
					plainText = plainText.."$"
				else
					-- placeholder end-tag found
					if plainText ~= "" then
						-- first we record any previous plainText
						table.insert(junks, { ["isPlaceholder"] = false, ["text"] = plainText })
					end
					table.insert(junks, { ["isPlaceholder"] = true, ["text"] = placeholder })
					placeholder = ""
					plainText = ""
					placeholderFound = true
				end
				placeHolderStart = false
			end
		else -- it's not a $, hence record the character in the right element
			if placeHolderStart then
				placeholder = placeholder..w
			else
				plainText = plainText..w
			end
		end
	end

	if placeHolderStart then
		-- case: foo$bar -> plain-text-element with a simple $
		plainText = plainText.."$"..placeholder
	end

	if plainText ~= "" then
		table.insert(junks, { ["isPlaceholder"] = false, ["text"] = plainText })
	end

	if placeholderFound then
		return junks
	end

	return plainText -- just plain text - no junks
end

function hasNotifications()
	return next(private.notifications)
end

function hideAutoMap()
	private.autoHideMapTime = nil
	private.mapText = nil
	removeStateRequest("automap", false)
end

function hideDetailOverlay()
	private.overlayInfo = nil

	local curTime = getElapsedTime()
	-- schedule close animation for all overlay frames
	for frame, scheduleData in pairs(private.scheduledOverlays) do
		-- prevent any further scheduled frames to appear
		scheduleData.startTime = nil
		if scheduleData.shown then
			-- set any currently active frames to close
			scheduleData.endTime = curTime
		end
	end
end

function hideDetailSlide(elementEntry)
	if not elementEntry.active then
		return -- already hidden, nothing to do
	end

	goToSlide(elementEntry.element, "inactive")
	elementEntry.active = false
end

function hideEnvironmentInfo()
	private.environmentTargetID = 0
	removeStateRequest("environmentinfo", false)
end

function hideSoftEnvironmentInfo()
	private.softEnvironmentMessageID = nil
	removeStateRequest("softenvironmentinfo", false)
end

function hideNotorietyFrameOverlay()
	private.notorietyLadderFactionDetails   = nil
	private.notorietyLadderComponentDetails = nil
	private.previousRelationDetails         = nil
	goToSlide(private.anarkElements.notorietyBlinking, "inactive")
	hideDetailSlide(private.anarkElements.details.notoriety)
end

function hideNormalFrameOverlay(frame)
	removeLiveUpdateValues(frame)
	if frame == "headerFrame" then
		hideDetailSlide(private.anarkElements.details.header)
	elseif frame == "fullFrame" then
		hideDetailSlide(private.anarkElements.details.full)
	elseif frame == "topFrame" then
		hideDetailSlide(private.anarkElements.details.top)
	elseif frame == "tableFrame" then
		hideDetailSlide(private.anarkElements.details.tabular)
	elseif frame == "extTableFrame" then
		hideDetailSlide(private.anarkElements.details.extTable)
	end
end

function hideNotification()
	removeStateRequest("notification", false)
end

function hideOverlay(frame)
	-- remove the scheduled event
	if private.scheduledOverlays[frame] == nil then
		private.scheduledOverlays[frame] = {}
	end
	local frameSchedule = private.scheduledOverlays[frame]
	frameSchedule.endTime = nil
	frameSchedule.shown   = false

	if frame == "topFrame" or frame == "headerFrame" or frame == "fullFrame" or frame == "tableFrame" or frame == "extTableFrame" then
		hideNormalFrameOverlay(frame)
	elseif frame == "notorietyFrame" then
		hideNotorietyFrameOverlay()
	end
end

function hideSofttarget()
	removeStateRequest("softtarget", false)
end

function initAutoMapEventSupport(contract)
	registerForEvent("changedZone", contract, onChangedZone)
	NotifyOnChangedZone(contract)
end

function initEnvironmentObjectSupport(contract)
	registerForEvent("changedEnvironmentObject", contract, onChangedEnvironmentObject)
	registerForEvent("changedSoftEnvironmentObject", contract, onChangedSoftEnvironmentObject)
	NotifyOnChangedEnvironmentObject(contract)

	-- set initial state of environmental info
	if private.environmentObjectSupport then
		local environmentTargetID = C.GetEnvironmentObject()
		if environmentTargetID ~= 0 then
			showEnvironmentInfo(environmentTargetID)
		end
	end
end

function initMousePicking()
	local interacttexture = getElement("event_monitor_interact", private.anarkElements.interactElement)
	registerForEvent("onMouseClick", interacttexture, onMouseClick)
	RegisterMouseInteractions(interacttexture)
	SetMouseOverride(interacttexture, config.interactCursorIcon)

	interacttexture = getElement("mousepicking", private.anarkElements.interactHeaderElement)
	registerForEvent("onMouseClick", interacttexture, onMouseClick)
	RegisterMouseInteractions(interacttexture)
	SetMouseOverride(interacttexture, config.interactCursorIcon)
end

function initNotifications()
	-- first abort any playing notification (which was for instance displayed in another eventmonitor)
	C.AbortCurrentNotification()

	-- clear any current notifications (might be outdated)
	private.notifications = {}
	removeStateRequest("notification", false)

	-- and refill the notifications (one after another)
	-- #StefanLow review --- 52-bit-limit due to tonumber()-usage
	local numNotifications = tonumber(C.GetNumNotifications())
	for i = 1, numNotifications do
		showNotification(C.GetNotificationID(i))
	end
end

-- converts description.notorietyComponent to description.notorietyComponentDetails
-- and description.notorietyFaction to description.notorietyFactionDetails
function initNotorietyData(description)
	-- cache any notoriety component data here, so that we do not suffer issues, if the lifetime of the component ends, before we are updating the eventmonitor details
	-- this can happen, since we do not enforce any restriction on the component being passed on as the notoriety component --- therefore we
	-- a) are checking whether the component still exists
	-- b) cache the current data, if available
	-- c) add data for a fallback case ("unknown"), in case the component data can no longer be retrieved
	-- see XR-825 / XR-197 for cases we ran into this problem --- while these cases have been dealt with properly on the notification system side, we do not ensure proper handling
	-- for mods in the same way --- this fallback case is easier to implement and as safe as the proper approach from a usage point of view
	-- TODO: @coreUI - med - this is not 100% correct - if the notorietyComponent is a MT-object it doesn't ensure that the MT-object is persistent! This can lead to differring notoriety data
	-- being displayed if the previously used MT-component is detached and reused for a new temp-component

	-- convert notorietyFaction -> notorietyFactionDetails
	if description.notorietyFaction then
		local factionDetails = C.GetFactionDetails(description.notorietyFaction)
		description.notorietyFactionDetails = {
			factionID   = description.notorietyFaction,
			factionName = ffi.string(factionDetails.factionName),
			factionIcon = ffi.string(factionDetails.factionIcon)
		}
		description.notorietyFaction = nil
	end

	-- retrieve basic component information
	local componentID    = description.notorietyComponent
	local validComponent = (componentID ~= nil and C.IsValidComponent(componentID))

	-- set the notorietyIcon, if it wasn't specified explicitly
	if not description.notorietyIcon then
		if componentID ~= nil then
			-- componentID faction icon takes precedence
			if validComponent then
				local ownerDetails = C.GetOwnerDetails(componentID)
				description.notorietyIcon = ffi.string(ownerDetails.factionIcon)
			else
				-- component is no longer valid - no way to determine faction ID - fall-back to unknown faction icon
				description.notorietyIcon = "faction_ownerless"
			end
		elseif description.notorietyFactionDetails then
			-- otherwise use the faction info
			description.notorietyIcon = description.notorietyFactionDetails.factionIcon
		--else 
			-- otheriwse nothing to do, notoriety frame is not being displayed
		end
	end

	if componentID == nil then
		return -- no notorietyComponent data at all -> nothing to do
	end

	description.notorietyComponentDetails = {}
	description.notorietyComponent        = nil

	if validComponent then
		-- component is valid -> populate the details structure
		local factionDetails = C.GetOwnerDetails(componentID)
		description.notorietyComponentDetails.componentID     = componentID
		-- TODO: @coreUI - med - this is utterly wrong here --- it's calling GetOwner() internally which is incorrect - it MUST call GetUIOwner() instead
		-- could not change at time of writing this due to a veto
		-- note that the difference between GetUIOwner() and GetOwner() is that GetUIOwner() returns the player faction regardless of the target's cover faction (if set to)
		-- this would be the correct behavior in this case too - in practice it won't be triggerred in a vanilla game, since that functionality is not used (it's accessible via Mods however)
		-- the net outcome is that in this case the eventmonitor would NOT display "player" for player owned stuff anymore, while the rest of the UI would display the object as player owned
		-- (including coloring the target element)
		description.notorietyComponentDetails.factionName     = ffi.string(C.GetFactionNameForEventMonitorHack(componentID))
		description.notorietyComponentDetails.relationDetails = C.GetRelationStatus(componentID)
	else
		-- failing to initialize component - component already destroyed --- init with fallback data
		description.notorietyComponentDetails.factionName     = L["Unknown Faction"]
		description.notorietyComponentDetails.relationDetails = {
			relationStatus   = 4,
			relationValue    = 0,
			relationLEDValue = 0,
			isBoostedValue   = false
		}
	end
end

function isActiveLED(LEDElementNumber, relationLEDValue, boostActive)
	if relationLEDValue == 0 then
		return false -- for a relation of 0, no LED is active
	end

	local maxLED
	local minLED
	if relationLEDValue < 0 then
		-- enemy LED-case
		minLED = 5
		maxLED = 4 - relationLEDValue -- relationLEDValue is -1..-4 -> maxLED 5..8
		if boostActive then
			maxLED = maxLED - 1 -- reserve last LED for blinking
		end
	else
		-- friendly LED-case
		maxLED = 4
		minLED = 5 - relationLEDValue -- relationLEDValue is 1..4 -> minLED 4..1
		if boostActive then
			minLED = minLED + 1 -- reserve last LED for blinking
		end
	end

	return LEDElementNumber <= maxLED and LEDElementNumber >= minLED
end

function isBlinkingLED(LEDElementNumber, relationLEDValue, boostActive)
	if not boostActive then
		return false -- no boost active, no LED is blinking
	end

	if relationLEDValue == 0 then
		return false -- for a relation of 0, no LED is active
	end

	if relationLEDValue < 0 then
		-- enemy LED-case
		return LEDElementNumber == (4 - relationLEDValue)
	end

	-- friendly LED-case
	return LEDElementNumber == (5 - relationLEDValue)
end

function isHighestState(state)
	for _, value in ipairs(config.priorization) do
		if value == state then
			return true
		elseif private.stateRequests[value] then
			return false
		end
	end

	-- not in the list, so it's not the highest state
	DebugError("Eventmonitor error. State '"..tostring(state).."' is not registered as a prioritized state.")
	return false
end

function isRadarEnabled()
	return private.radarEnabled and private.shipRadarEnabled
end

function processLiveUpdateValues()
	local text
	for frame, data in pairs(private.liveUpdateValues) do
		if private.scheduledOverlays[frame] ~= nil and private.scheduledOverlays[frame].shown then
			-- frame is displayed, process live update values
			for _, entry in ipairs(data) do
				text = constructPlaceholderText(entry.junks, entry.referenceComponent)
				setAttribute(entry.element, "textstring", text)
			end
		end
	end
end

function processOverlaySchedule()
	local curTime = getElapsedTime()
	for frame, scheduleData in pairs(private.scheduledOverlays) do
		if scheduleData.startTime and curTime > scheduleData.startTime then
			showOverlay(frame)
		elseif scheduleData.endTime and curTime > scheduleData.endTime then
			hideOverlay(frame)
		end
	end
end

function queueNotification(notificationID, priority)
	private.notifications[priority] = private.notifications[priority] or {}
	table.insert(private.notifications[priority], notificationID)
	requestState("notification")
end

function prepareLiveUpdateText(text, element, frame, component)
	local textJunks = getTextJunks(text)
	if type(textJunks) ~= "table" then
		return textJunks -- no placeholders, hence use the plain text (but parsed --- so that any $$ is unescaped)
	end

	local liveUpdateValue = {
		["element"]            = element,
		["referenceComponent"] = component,
		["junks"]              = textJunks
	}
	if private.liveUpdateValues == nil then
		private.liveUpdateValues = {}
	end
	if private.liveUpdateValues[frame] == nil then
		private.liveUpdateValues[frame] = {}
	end
	table.insert(private.liveUpdateValues[frame], liveUpdateValue)

	return constructPlaceholderText(textJunks, component)
end

function removeLiveUpdateValues(frame)
	if private.liveUpdateValues ~= nil then
		private.liveUpdateValues[frame] = nil
		if next(private.liveUpdateValues) == nil then
			private.liveUpdateValues = nil -- nil the list, if last liveupdate-value was removed
		end
	end
end

function removeStateRequest(state, force)
	private.stateRequests[state] = false
	updateActiveState(force)
end

function requestState(state, force)
	private.stateRequests[state] = true
	updateActiveState(force)
end

function scheduleDetailOverlay(componentInfo)
	private.overlayInfo = componentInfo

	-- determine which overlay frame to use
	local layout
	local mainFrame
	-- if details == nil, we do not display any main frame overlay
	if componentInfo.details ~= nil then
		layout = componentInfo.details.layout
		if layout == "table" then
			mainFrame = "tableFrame"
		elseif layout == "header" then
			mainFrame = "headerFrame"
		elseif layout == "long" then
			mainFrame = "fullFrame"
		elseif layout == "short" then
			mainFrame = "topFrame"
		-- else it's nil
		end
	end

	-- determine whether we show the notoriety frame or the 5th table bar
	local bottomFrame
	local showNotorietyFrame = componentInfo.notorietyIcon ~= nil or componentInfo.notorietyFactionDetails ~= nil or componentInfo.notorietyComponentDetails ~= nil
	if showNotorietyFrame then
		bottomFrame = "notorietyFrame"
	elseif layout == "table" then
		bottomFrame = "extTableFrame"
	-- else it's nil
	end

	-- sanity / error checks
	if mainFrame == "headerFrame" and componentInfo.details ~= nil and componentInfo.details.text ~= nil and componentInfo.details.text.text ~= "" and componentInfo.details.text.text ~= nil then
		DebugError("Eventmonitor error. Eventmonitor set to show header overlay but retrieved text info. Text '"..tostring(componentInfo.details.text.text).."' will not be displayed.")
		componentInfo.details.text = nil
	end

	-- calculate appear/disappear timings for overlay frames
	local curTime = getElapsedTime()
	local mainFrameAppearTime
	local mainFrameEndTime
	if mainFrame ~= nil then
		if private.scheduledOverlays[mainFrame] == nil then
			private.scheduledOverlays[mainFrame] = {}
		end
		local frameSchedule = private.scheduledOverlays[mainFrame]
		mainFrameAppearTime = curTime
		if componentInfo.mainFrameTimings then
			mainFrameAppearTime = (componentInfo.mainFrameTimings.appear or 0) + curTime
			mainFrameEndTime    =  componentInfo.mainFrameTimings.duration
			if mainFrameEndTime then
				mainFrameEndTime = mainFrameEndTime + mainFrameAppearTime
			end
		end
		frameSchedule.startTime = mainFrameAppearTime
		frameSchedule.endTime   = mainFrameEndTime
	end

	-- #StefanLow - code redundancy
	local bottomFrameAppearTime
	local bottomFrameEndTime
	local bottomFrameStartTime
	local bottomFrameDuration
	if bottomFrame == "extTableFrame" then -- in this case we have to use the main-frame-timings
		if componentInfo.mainFrameTimings then
			bottomFrameStartTime = componentInfo.mainFrameTimings.appear or 0
			bottomFrameDuration  = componentInfo.mainFrameTimings.duration
		end
	else -- use the notorietyFrameTimings
		if componentInfo.notorietyFrameTimings then
			bottomFrameStartTime = componentInfo.notorietyFrameTimings.appear or 0
			bottomFrameDuration  = componentInfo.notorietyFrameTimings.duration
		end
	end
	if bottomFrame ~= nil then
		if private.scheduledOverlays[bottomFrame] == nil then
			private.scheduledOverlays[bottomFrame] = {}
		end
		local frameSchedule = private.scheduledOverlays[bottomFrame]

		bottomFrameAppearTime = curTime
		if bottomFrameStartTime then
			bottomFrameAppearTime = bottomFrameStartTime + curTime
			bottomFrameEndTime    = bottomFrameDuration
			if bottomFrameEndTime then
				bottomFrameEndTime = bottomFrameEndTime + bottomFrameAppearTime
			end
		end
		frameSchedule.startTime = bottomFrameAppearTime
		frameSchedule.endTime   = bottomFrameEndTime
	end
end

function setAlignedTextElement(element, info, frame, component)
	setTextElement(element, info, frame, component)

	if info ~= nil then
		-- set x position
		setAttribute(element, "position.x", info.xoffset + config.tableTextOffset)

		-- set horizontal alignment
		setAttribute(element, "horzalign", convertAlignment(info.alignment))
	end
end

function setCheckedText(element, text)
	-- only update the faction text, if it really changed
	-- (note: Anark does not filter setAttribute() calls which do not change the string value, since doing so would have
	-- and unnecessary performance impact due to the required string comparison on each setAttribute-call)

	if getAttribute(element, "textstring") ~= text then
		setAttribute(element, "textstring", text)
	end
end

function setCockpitMode()
	-- cockpit EM is always active
	goToSlide(private.anarkElements.background, "inactive")
	private.monitorActive = true
	ShowPresentation()

	private.hudMonitor = false
	private.environmentObjectSupport = true
	private.showAutoMapEvents = true

	activateCockpitMonitorMode()

	local objectid = C.GetEnvironmentObject()
	if objectid ~= 0 then
		showEnvironmentInfo(objectid)
	end
	
	if private.currentState == "inactive" or private.currentState == "automap" then
		updateActiveState(true)
	end
end

function setHUDMode()
	if private.hudMonitor then
		return -- we are already in HUD mode
	end

	private.hudMonitor = true
	private.showAutoMapEvents = false

	activateHudMonitorMode()

	if private.currentState == "notification" or private.currentState == "softtarget" or private.currentState == "softenvironmentinfo" or private.currentState == "externalTarget" then
		if appearAnimation then
			goToSlide(private.anarkElements.background, "appear")
		else
			goToSlide(private.anarkElements.background, "active")
		end
	elseif private.currentState == "inactive" or private.currentState == "automap" then
        if private.allowRadar then
		    updateActiveState(true)
        else
    		deactivateMonitor()
        end
	end
end

function setTableRowElement(element, info, frame, component)
	-- icon / iconcolor
	if info.icon and info.icon ~= "" then
		local iconElement = getElement("icon", element)
		local iconTextureElement = getElement("material.icon", iconElement)
		SetIcon(iconTextureElement, info.icon, info.iconcolor.r, info.iconcolor.g, info.iconcolor.b, true, config.tableIconSize, config.tableIconSize)
		setAttribute(iconElement, "opacity", 100)
	else -- no icon, hide by setting opacity to 0
		setAttribute(getElement("icon", element), "opacity", 0)
	end

	-- icon background color
	SetDiffuseColor(getElement("iconbg.material", element), info.iconbackground.r, info.iconbackground.g, info.iconbackground.b)

	-- text background color
	SetDiffuseColor(getElement("textbg.material", element), info.text.background.r, info.text.background.g, info.text.background.b)

	-- set text elements for current row
	for i = 1, 5 do
		setAlignedTextElement(getElement("Text"..i, element), info.text[i], frame, component)
	end
end

function setTextElement(element, info, frame, component)
	local text = ""

	if info and info.text and info.text ~= "" then
		-- only set text-related values, when text is given
		setAttribute(element, "font", info.font)
		setAttribute(element, "size", info.fontsize)
		setAttribute(element, "textcolor.r", info.color.r)
		setAttribute(element, "textcolor.g", info.color.g)
		setAttribute(element, "textcolor.b", info.color.b)

		text = prepareLiveUpdateText(info.text, element, frame, component)
	end

	setCheckedText(element, text)
end

function showAutoMap(text)
	if not isHighestState("automap") then
		return -- do not queue automap requests, just reject them
	end

	private.mapText = text

	requestState("automap")
end

function showDetailSlide(elementEntry)
	if elementEntry.active then
		return -- already active, nothing to do
	end

	goToSlide(elementEntry.element, "appear")
	elementEntry.active = true
end

function showEnvironmentInfo(targetid)
	private.environmentTargetID = targetid
	requestState("environmentinfo")
end

function showExtTableFrameOverlay()
	setTableRowElement(getElement("row", private.anarkElements.details.extTable.element), private.overlayInfo.details.tabular[5], "extTableFrame", private.overlayInfo.referenceComponent)
	showDetailSlide(private.anarkElements.details.extTable)
end

function showMainFrameOverlay(frame)
	local componentInfo = private.overlayInfo

	-- get correct detail layer element (top, full, or bottom details)
	local detailElement
	local textEnabled = frame ~= "headerFrame" -- text is only available in non-header-only overlays
	if frame == "fullFrame" then
		detailElement = private.anarkElements.details.full
	elseif frame == "topFrame" then
		detailElement = private.anarkElements.details.top
	elseif frame == "headerFrame" then
		detailElement = private.anarkElements.details.header
	end

	-- set header
	setTextElement(getElement("header", detailElement.element), componentInfo.details.header, frame, componentInfo.referenceComponent)
	SetDiffuseColor(getElement("headerbg.material", detailElement.element), componentInfo.details.headerBackground.r, componentInfo.details.headerBackground.g, componentInfo.details.headerBackground.b)

	-- set text elements (unless in header frame, which doesn't support text)
	if textEnabled then
		local text
		if componentInfo.details ~= nil then
			text = componentInfo.details.text
		end
		setTextElement(getElement("Text", detailElement.element), text, frame, componentInfo.referenceComponent)
	end

	showDetailSlide(detailElement)
end

function showNotorietyFrameOverlay()
	local componentInfo = private.overlayInfo

	showDetailSlide(private.anarkElements.details.notoriety)

	-- icon display
	if componentInfo.notorietyIcon then
		SetIcon(private.anarkElements.factionLadder.iconTexture, componentInfo.notorietyIcon, config.notorietyIconColor.r, config.notorietyIconColor.g, config.notorietyIconColor.b, true, config.tableIconSize, config.tableIconSize)
	end

	-- notoriety ladder
	private.notorietyLadderFactionDetails   = componentInfo.notorietyFactionDetails
	private.notorietyLadderComponentDetails = componentInfo.notorietyComponentDetails
	-- TODO: @coreUI low - reconsider handling relationStatus here - could directly use relationDetails struct?
	local relationStatus
	local factionName
	-- note: order is important - component info takes precedence!
	if componentInfo.notorietyComponentDetails then
		factionName = componentInfo.notorietyComponentDetails.factionName
		relationStatus = componentInfo.notorietyComponentDetails.relationDetails.relationStatus
	elseif componentInfo.notorietyFactionDetails then
		factionName = componentInfo.notorietyFactionDetails.factionName
		-- TODO: @coreUI - med - this is a redundant call to C.GetFactionRelationStatus() here and then in updateNotorietyLadder()...
		local relationDetails = C.GetFactionRelationStatus(componentInfo.notorietyFactionDetails.factionID)
		relationStatus = relationDetails.relationStatus
	end

	if relationStatus ~= nil then
		-- for the player's faction or for unknown factions we do not show the notoriety ladder
		private.factionLadderActive = (relationStatus < 3)

		if componentInfo.notorietyEffect then
			goToSlide(private.anarkElements.notorietyBlinking, "active")
		else
			goToSlide(private.anarkElements.notorietyBlinking, "inactive")
		end

		if private.factionLadderActive then
			goToSlide(private.anarkElements.details.factionLadder.element, "active")
			private.anarkElements.details.factionLadder.active = true
		else
			goToSlide(private.anarkElements.details.factionLadder.element, "inactive") -- must be done regardless, since we do not reset the slide when deactivating the entire notoriety row
			private.anarkElements.details.factionLadder.active = false
		end

		-- set factionname (only set once, no need to update each frame)
		setAttribute(private.anarkElements.factionLadder.factionText, "textstring", factionName)

		updateNotorietyLadder(componentInfo.notorietyFactionDetails, componentInfo.notorietyComponentDetails)
	else
		private.factionLadderActive = false
		goToSlide(private.anarkElements.details.factionLadder.element, "inactive")
		private.anarkElements.details.factionLadder.active = false
		goToSlide(private.anarkElements.notorietyBlinking, "inactive")
	end
end

function showOverlay(frame)
	-- remove the scheduled event
	if private.scheduledOverlays[frame] == nil then
		private.scheduledOverlays[frame] = {}
	end

	local frameSchedule = private.scheduledOverlays[frame]

	-- clear any live-update-value for the frame from the previous (old) frame
	removeLiveUpdateValues(frame)

	if frame == "topFrame" or frame == "headerFrame" or frame == "fullFrame" then
		showMainFrameOverlay(frame)
	elseif frame == "tableFrame" then
		showTableFrameOverlay()
	elseif frame == "extTableFrame" then
		showExtTableFrameOverlay()
	elseif frame == "notorietyFrame" then
		showNotorietyFrameOverlay()
	end

	-- done after show calls, so we can check whether frame is already shown via frameSchedule.shown in showXXXCalls
	frameSchedule.startTime = nil
	frameSchedule.shown = true
end

function showNotification(notificationID)
	local priority, queued = GetNotificationPriority(notificationID)
	if priority == nil then
		return -- ignore - can be nil, if notification was removed already
	end

	if queued then
		queueNotification(notificationID, priority)
	else
		showUnqueuedNotification(notificationID, priority)
	end
end

function toggleEventMonitorDetails()
	if private.allowRadar then
		if isRadarEnabled() then
			private.showDetails = not private.showDetails
			C.SetConfigSetting("eventmonitordetails", private.showDetails)
			
			updateActiveState(true)
		end
	end
end

function enableRadar(enable)
	if private.radarEnabled ~= enable then
		private.radarEnabled = enable

		if enable then
			-- make sure that when we enable the radar, the detail overlay is also enabled
			-- (prevents issues with that mode having been disabled when the radar was deactivated - making it appear as if the radar setting wouldn't have an effect when you reenable it...)
			private.showDetails = true
			C.SetConfigSetting("eventmonitordetails", private.showDetails)
		end
	end
	
	if private.allowRadar then
		updateActiveState(true)
	end
end

function toggleRadarMode()
	if private.allowRadar then
		if isRadarEnabled() then
			private.radarMapMode = not private.radarMapMode
			C.SetConfigSetting("radarmode", private.radarMapMode)
			
			updateActiveState(true)
		end
	end
end

function showSoftEnvironmentInfo(messageID)
	private.softEnvironmentMessageID = messageID
	requestState("softenvironmentinfo")
end

function showSofttarget(softtargetid, softtargetconnectionname)
	private.softtargetID                     = softtargetid
	private.softtargetTemplateConnectionName = softtargetconnectionname
	requestState("softtarget", isHighestState("softtarget"))
end

function showTableFrameOverlay()
	local componentInfo = private.overlayInfo

	-- set header, if specified
	setTextElement(getElement("header", private.anarkElements.details.tabular.element), componentInfo.details.header, "tableFrame", componentInfo.referenceComponent)
	SetDiffuseColor(getElement("headerbg.material", private.anarkElements.details.tabular.element), componentInfo.details.headerBackground.r, componentInfo.details.headerBackground.g, componentInfo.details.headerBackground.b)

	for i = 1, 4 do
		setTableRowElement(getElement("row"..i, private.anarkElements.details.tabular.element), private.overlayInfo.details.tabular[i], "tableFrame", private.overlayInfo.referenceComponent)
	end

	showDetailSlide(private.anarkElements.details.tabular)
end

function activatePIPNotification(notificationID, descriptor)
	private.pipNotificationID = notificationID

	if descriptor.duration ~= nil then
		DebugError("Eventmonitor error. Duration defined in cutscene notification descriptor ignored.")
	end

	private.pipCutsceneID = StartCutscene(descriptor.cutsceneDescriptor, config.pipRenderTarget)

	if descriptor.sound then
		PlaySound(descriptor.sound)
	end

	C.NotifyDisplayNotification(notificationID)

	if not private.pipActive then
		goToSlide(private.anarkElements.rendertargetBorder, "active")
		private.pipActive = true
	end
end

function deactivatePIPNotification()
	if not private.pipActive then
		return -- not active atm, so nothing to deactivate
	end

	goToSlide(private.anarkElements.rendertargetBorder, "inactive")

	if private.pipCutsceneID ~= nil then
		StopCutscene(private.pipCutsceneID)
	end

	ReleaseNotification(private.pipNotificationID)

	private.pipNotificationID = nil
	private.pipCutsceneID = nil
	private.pipActive = false
end

function showUnqueuedNotification(notificationID, priority)
	if private.allowRadar and isRadarEnabled() then
		local notificationInfos = GetNotificationDetails(notificationID)
		if notificationInfos.cutsceneDescriptor and not (notificationInfos.details or notificationInfos.interactionDescriptor or notificationInfos.interactionText or notificationInfos.notorietyIcon or notificationInfos.notorietyEffect or notificationInfos.notorietyFaction or notificationInfos.notorietyComponent) then
			activatePIPNotification(notificationID, notificationInfos)
			return
		end
	end

	-- unqueued notificationsa are only displayed, if nothing with a higher priority is being displayed right now
	if isHighestState("notification") then
		if private.currentNotification == nil then
			queueNotification(notificationID, priority)
			return
		end

		-- at this point the notification which is displayed atm might have already been destroyed (and we'd get a closeCurrentState call right after this one)
		local curPriority = GetNotificationPriority(private.currentNotification.ID)
		if curPriority == nil or curPriority <= priority then
			queueNotification(notificationID, priority)
			updateNotifications()
			return
		end
	end

	-- if we didn't display it, we must release the notification
	ReleaseNotification(notificationID)
end

function switchNotification()
	local highestPriority       = table.maxn(private.notifications)
	local notification          = private.notifications[highestPriority][1]
	local notificationInfos     = GetNotificationDetails(notification)
	private.currentNotification = notificationInfos

	-- if for any reason the notification could not be processed, skip the request
	if notificationInfos then
		notificationInfos.ID = notification
		local defaultDuration = config.notificationDelay
		if notificationInfos.cutsceneDescriptor then
			defaultDuration = nil -- by default, cutscene notifications are indifinite
		end
		local duration = notificationInfos.duration or defaultDuration
		notificationInfos.duration = duration
		updateEventMonitorDisplay(notificationInfos, false, true, notificationInfos.silent)
		if notificationInfos.sound then
			PlaySound(notificationInfos.sound)
		end

		C.NotifyDisplayNotification(notification)
	end

	-- remove the current one from the list -- we remove the "notification" immediately, even if the player was not able to see it
	-- #StefanMed rediscuss with Bernd whether this really is what he wants (wasn't decided yet)
	table.remove(private.notifications[highestPriority], 1)
	if #private.notifications[highestPriority] == 0 then
		-- remove entire priority-table, if last notification for the priority was removed
		private.notifications[highestPriority] = nil
	end
end

function updateNotifications()
	-- free any previous notification
	deactivateNotification()

	repeat
		if not hasNotifications() then
			hideNotification() -- no more notifications to display
			return
		end
		switchNotification()
	until private.currentNotification ~= nil
end

function triggerGrain()
	goToSlide(private.anarkElements.grainElement, "active")
end

function updateActiveState(force)
	for _, state in ipairs(config.priorization) do
		if private.stateRequests[state] then
			changeState(state, force)
			return
		end
	end

	-- no one wants to show something, so deactivate the eventmonitor
	changeState("inactive", force)
end

function updateEventMonitorDetails(description, isSofttarget, radarComponent, focusComponent)
	-- note: it's ensured by design that radarComponent always exists (either it's a softtarget, envObj, or softenvobj -> all cases handled for destruction notifications)
	-- TODO: @coreUI - med --- this is actually a hack to ensure that the radarComponent is patched into the description structure --- doesn't quite belong here / same for focusComponent
	description.radarComponent = radarComponent
    description.focusComponent = focusComponent

	if not private.allowRadar then
		-- radar is disabled
		return
	end

	-- if we are given a descriptor using a cutscene or background element, it should take precedence over our own setting
	if description.cutsceneDescriptor ~= nil or description.backgroundIcon ~= nil then
		return
	end

	if isRadarEnabled() then
		-- always force map display, unless radar is disabled (in which case we only display the map, if the requester told us to)
		description.showMap = true
	end

	if not description.showMap then
		-- map isn't displayed, so we have nothing to alter here
		return
	end

	-- mode 1: nothing to change - show the data as it is provided to us
	if private.showDetails then
		return
	end

	-- mode 2: in case of the softtarget (or externalTarget) we just display the header, in all other cases we show no overlay
	if isSofttarget then
		description.details.layout = "header"
	else
		-- remove overlay
		description.details = nil
		-- reasoning: we could actually also nil these for the softtarget case, since it won't make much of a difference --- however, we stick with the timing settings, so the caller "could" have the possibility to decide when the softtarget information are to appear in theory
		description.mainFrameTimings      = nil
		description.notorietyFrameTimings = nil
		-- interactionDescriptor must not be niled for the softtarget, since there we still want to be able to interact with the dock (show dock info) by LMB-clicking onto the eventmonitor
		-- in all other cases having an interactive eventmonitor without showing actually the data for the underlying object wouldn't make much sense
		description.interactionDescriptor = nil
		description.interactionText       = nil
	end
	-- the following values must be niled for everything, since we do not want to display any overlay/background element
	description.notorietyIcon      = nil
	description.notorietyEffect    = nil
    description.notorietyFaction   = nil
    description.notorietyComponent = nil
end

function updateEventMonitorDisplay(description, deleteDescriptor, isNotification, isSilent)
	-- first we stop anything which was played before
	if private.curDescription then
		-- a cutscene?
		deactivateCutscene()

		-- an eventmonitor interaction?
		deactivateInteraction()

		-- a map?
		if private.mapActive then
			private.resetMap = true
		end
	end

	private.curDescription = description

	if description == nil then
		-- if we have no further description, all we need to do is deactivate the frame and we are done
 		goToSlide(private.anarkElements.main, "inactive")
		return
	end
		
	convertDurations(description)
	initNotorietyData(description)

	private.curDescription.deleteDescriptor = deleteDescriptor

	-- auto timeout
	if description.duration then
		private.autoClose = getElapsedTime() + description.duration
	end

	-- first we have to check if we should show a map, and whether that would actually work
	if description.showMap then
        if description.focusComponent ~= 0 then
            private.mapActive = C.SetMapRenderTargetOnTarget(config.renderTarget, description.focusComponent, description.radarComponent, private.radarMapMode)
        else
		    private.mapActive = C.SetMapRenderTarget(config.renderTarget, description.radarComponent, private.radarMapMode)
        end
		-- #StefanLow - simplify mapActive --- should be somehow combined with hideOverlay() so it's not required in deactivateState anymore
		if private.mapActive then
			private.resetMap = false -- do not reset the map, if we are showing it again
		else
			-- if this happens, it indicates a problem in the holomap system - fall-back to show no-signal
			DebugError("Eventmonitor error. Failed to display map. Falling back to display no signal.")

			private.description = createNoSignalDisplay()
			-- retain the duration of the original descriptor, so the display behaves timing-wise the same
			private.description.duration = description.duration
		end
	end

	-- then we switch to the right screen
	local slide = "inactive"
	if description.backgroundIcon then
		slide = "icon"
		SetIcon(private.anarkElements.iconElement, description.backgroundIcon, nil, nil, nil, false)
	elseif description.cutsceneDescriptor then
		slide = "rendertarget"
		private.curDescription.cutsceneID = StartCutscene(description.cutsceneDescriptor, config.renderTarget)
	elseif description.showMap then
		slide = "rendertarget"
	end
	goToSlide(private.anarkElements.main, slide)

	-- activate interaction event, if specified
	if description.interactionDescriptor then
		if isNotification and not isSilent then
			private.activeInteractElement = private.anarkElements.interactElement
			if config.displayPressHint then
				local text = ""
				local keybinding = ffi.string(C.GetLocalizedInteractiveNotificationKey())
				if keybinding ~= "" then
					text = string.format(L["Press %s"], keybinding)
				end
				setAttribute(private.anarkElements.interactiveText, "textstring", text)
			end
		else
			private.activeInteractElement = private.anarkElements.interactHeaderElement
		end
		goToSlide(private.activeInteractElement, "active")
		-- only activate executeNotification handling for gamepad/keyboard actions, if we show a notification (otherwise any interaction is just triggerable with a mouseclick)
		-- also the text is only passed along, if we are in non-silent mode
		local interactionText = description.interactionText
		if isSilent then
			interactionText = ""
		end
		description.interactionID = EventmonitorInteractionShown(description.interactionDescriptor, interactionText, isNotification)
	end

	-- set background color
	if description.background then
		SetDiffuseColor(getElement("background.material", private.anarkElements.backcolor), description.background.r, description.background.g, description.background.b)
		goToSlide(private.anarkElements.backcolor, "active")
	end

	-- finally we schedule the overlay info
	scheduleDetailOverlay(description)
end

function updateNotorietyLadder(notorietyFactionDetails, notorietyComponentDetails)
	local relationDetails
	if notorietyComponentDetails ~= nil then
		updateRelationStatusData(notorietyComponentDetails)
		relationDetails = notorietyComponentDetails.relationDetails
	else -- use factionID
		relationDetails = C.GetFactionRelationStatus(notorietyFactionDetails.factionID)
	end

	local factionLadderElements = private.anarkElements.factionLadder

	-- update relation text and color
	if private.previousRelationDetails == nil or (private.previousRelationDetails.relationStatus ~= relationDetails.relationStatus) then
		local relationColor = config.relationColor[relationDetails.relationStatus + 1]
		local relationText = "" -- empty for unknown/invalid cases -- in case of relationStatus == 4 we do display Unknown Faction without an additional faction text
		if relationDetails.relationStatus == 0 then
			relationText = L["Enemy"]
		elseif relationDetails.relationStatus == 1 then
			relationText = L["Neutral"]
		elseif relationDetails.relationStatus == 2 then
			relationText = L["Allied"]
		elseif relationDetails.relationStatus == 3 then
			relationText = L["Player"]
		end
		setCheckedText(factionLadderElements.relationText, relationText)
		setAttribute(factionLadderElements.relationText, "textcolor.r", relationColor.r)
		setAttribute(factionLadderElements.relationText, "textcolor.g", relationColor.g)
		setAttribute(factionLadderElements.relationText, "textcolor.b", relationColor.b)
	end

	if private.factionLadderActive then
		-- only update the faction ladder, if it's active

		-- set the relation value
		if private.previousRelationDetails == nil or (private.previousRelationDetails.relationValue ~= relationDetails.relationValue or private.previousRelationDetails.relationLEDValue ~= relationDetails.relationLEDValue) then
			local notorietyValueColor = config.notorietyValueColor[2]
			local relationTextValue = relationDetails.relationValue
			if relationDetails.relationValue > 0 then
				relationTextValue = "+"..relationDetails.relationValue
				notorietyValueColor = config.notorietyValueColor[3]
			elseif relationDetails.relationValue < 0 then
				notorietyValueColor = config.notorietyValueColor[1]
			-- else - notorietyValueColor is 0 as initialized
			end
			setCheckedText(factionLadderElements.valueText, relationTextValue)
			setAttribute(factionLadderElements.valueText, "textcolor.r", notorietyValueColor.r)
			setAttribute(factionLadderElements.valueText, "textcolor.g", notorietyValueColor.g)
			setAttribute(factionLadderElements.valueText, "textcolor.b", notorietyValueColor.b)
		end

		-- update relation LED elements
		if private.previousRelationDetails == nil or (private.previousRelationDetails.isBoostedValue ~= relationDetails.isBoostedValue or private.previousRelationDetails.relationLEDValue ~= relationDetails.relationLEDValue) then
			local slide
			for i = 1, 8 do
				if isBlinkingLED(i, relationDetails.relationLEDValue, relationDetails.isBoostedValue) then
					slide = "blinking"
				elseif isActiveLED(i, relationDetails.relationLEDValue, relationDetails.isBoostedValue) then
					slide = "active"
				else
					slide = "inactive"
				end

				local materialElement = getElement("Rectangle.material", factionLadderElements[i])
				local elementColor = getLEDColor(i, relationDetails.relationLEDValue)
				SetDiffuseColor(materialElement, elementColor.r, elementColor.g, elementColor.b)

				goToSlide(factionLadderElements[i], slide)
			end
		end
	end

	private.previousRelationDetails = relationDetails
end

function updateRelationStatusData(notorietyComponentDetails)
	if notorietyComponentDetails.component ~= nil then
		if C.IsValidComponent(notorietyComponentDetails.component) then
			notorietyComponentDetails.relationDetails = C.GetRelationStatus(notorietyComponentDetails.component)
		else
			-- component became invalid --- set to nil for next call
			notorietyComponentDetails.component = nil
		end
	end
end