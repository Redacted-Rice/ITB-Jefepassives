-- Adapted from swimmingIcon from Lemonymous and tosx
-- This lib replaces the flying icon and tooltip with an orbital icon and tooltip
-- To use it, just add OrbitalIcon = true to your pawn table and it will take care of the rest.
-- Meant to be used with the orbitalPawn lib
-- To reset orbital tutorial tips, you have to add options in your init

local VERSION = "0.0.1"

local icon = sdlext.surface("img/combat/icons/icon_flying.png")
local mod = modApi:getCurrentMod()
local path = mod.scriptPath

-- You need all these for this lib
local menu = require(path .."libs/menu")
local UiCover = require(path .."ui/cover")
local clip = require(path .."libs/clip")
local tips = require(path.."libs/tutorialTips")

local newicon
local iconSprite = "img/effects/icon_orbital.png"
local pawnTypeShown = false

-- returns the pawnId of pawn
-- currently having it's UI drawn.
local function GetUIEnabledPawn()
	local pawn = Board:GetSelectedPawn()
	
	if not pawn then
		local highlighted = Board:GetHighlighted()
		
		if highlighted and Board then
			pawn = Board:GetPawn(highlighted)
		end
	end
	
	return pawn
end

local missionSmallWidget
local missionLargeWidget

local function UiRootCreatedHook(screen, uiRoot)
	
	local decoDrawFn = function(self, screen, widget)
		local oldX = widget.rect.x
		local oldY = widget.rect.y
		
		widget.rect.x = widget.rect.x - 2
		widget.rect.y = widget.rect.y + 2
		
		DecoSurfaceOutlined.draw(self, screen, widget)
		
		widget.rect.x = oldX
		widget.rect.y = oldY
	end
	
	-- 1 widget to cover up flying icon
	-- when hovering/selecting mech in mission
	missionSmallWidget = Ui()
		:widthpx(25):heightpx(21)
		:addTo(uiRoot)
	local mask = UiCover({size = {25, 21}})
		:addTo(missionSmallWidget)
	local child = Ui()
		:widthpx(25):heightpx(21)
		:decorate({ DecoSurfaceOutlined(newicon, 1, deco.colors.buttonborder, deco.colors.focus, 1) })
		:addTo(missionSmallWidget)
	missionSmallWidget.translucent = true
	missionSmallWidget.visible = false
	child.translucent = true
	child.decorations[1].draw = function(self, screen, widget)
		self.surface = self.surface or self.surfacenormal
		DecoSurface.draw(self, screen, widget)
	end
	
	-- 1 widget to cover up flying icon
	-- when hovering a mech's buffs.
	missionLargeWidget = Ui()
		:widthpx(50):heightpx(42)
		:addTo(uiRoot)
	local child = Ui()
		:widthpx(50):heightpx(42)
		:decorate({ DecoSurfaceOutlined(newicon, 1, deco.colors.buttonborder, deco.colors.buttonborder, 2) })
		:addTo(missionLargeWidget)
	child.translucent = true
	missionLargeWidget.translucent = true
	missionLargeWidget.visible = false

	missionSmallWidget.draw = function(self, screen)
		self.visible = false
		if	icon:wasDrawn()					and
			GetCurrentMission()				and
			not missionSmallWidget.isMasked then
			
			local pawn = GetUIEnabledPawn()
			
			if pawn and _G[pawn:GetType()].OrbitalIcon then
				if not sdlext:isStatusTooltipWindowVisible() then
					self.x = icon.x
					self.y = icon.y
					
					self.children[2].decorations[1].surface = self.children[2].decorations[1].surfacenormal
				elseif sdlext:isStatusTooltipWindowVisible() then
					if Board:IsValid(Board:GetHighlighted()) then
						-- Status window due to mousing over a board unit with CTRL; don't highlight small icon
					else
						self.children[2].decorations[1].surface = self.children[2].decorations[1].surfacehl
					end
				end
				
				self.visible = true
			end
		end
		
		clip(Ui, self, screen)
	end
	
	missionLargeWidget.draw = function(self, screen)
		self.visible = false
		if icon:wasDrawn() and GetCurrentMission() then
			
			local pawn = GetUIEnabledPawn()
			if pawn and _G[pawn:GetType()].OrbitalIcon then
				-- to do: make the large icon visible and clipped while escape menu is up
				if sdlext:isStatusTooltipWindowVisible() and not sdlext:isEscapeMenuWindowVisible() then
					self.x = icon.x
					self.y = icon.y
					
					self.visible = true
				end
			end
		end
		
		Ui.draw(self, screen)
	end
end

local delayOnce = 0
local function onModsLoaded()
	require(path .."libs/menu"):load()
	
	modApi.events.onFrameDrawStart:subscribe(function()
		if delayOnce > 0 then
			delayOnce = delayOnce - 1
		else
			pawnTypeShown = false
		end
	end)
end

local function finalizeInit(self)	
	newicon = sdlext.surface(mod.resourcePath ..iconSprite)
	
	sdlext.addUiRootCreatedHook(UiRootCreatedHook)
	
	local original_GetStatusTooltip = GetStatusTooltip
	function GetStatusTooltip(id)
		if	id == "flying" and Pawn and _G[Pawn:GetType()].OrbitalIcon	then
			return {"Orbital", "Orbital units stay outside of the map area."}
		end
		return original_GetStatusTooltip(id)
	end
	
	modApi.events.onModsLoaded:subscribe(onModsLoaded)
	
	local oldGetText = GetText
	function GetText(id, ...)
		if Pawn_Texts[id] then
			pawnTypeShown = id
			delayOnce = 2 -- don't know why it takes 2 frames to check things
		end

		return oldGetText(id, ...)
	end
	
	-- add tutorial tip (you may use options in your init to reset the tip)
	tips:Add{
		id = "OrbitalPawn",
		title = "Orbital Unit",
		text = "Orbital units stay outside of the map area. Use the unit list on the left of the screen to select them."
	}
	
	-- trigger tutorial tip
	modApi.events.onDeploymentPhaseEnd:subscribe(function()
		if Board then
			local orbital = false
			local pawnList = extract_table(Board:GetPawns(TEAM_ANY))
			for _,p in ipairs(pawnList) do
				local pawn = Board:GetPawn(p)
				if pawn and _G[pawn:GetType()].Orbital then
					orbital = pawn
				end
			end
			if orbital then
				tips:Trigger("OrbitalPawn", Point(-3,6))
			end
		end
	end)
	
end

local function onModsInitialized()
	local isHighestVersion = true
		and OrbitalIcon.initialized ~= true
		and OrbitalIcon.version == VERSION

	if isHighestVersion then
		OrbitalIcon:finalizeInit()
		OrbitalIcon.initialized = true
	end
end


local isNewerVersion = false
	or OrbitalIcon == nil
	or VERSION > OrbitalIcon.version

if isNewerVersion then
	OrbitalIcon = OrbitalIcon or {}
	OrbitalIcon.version = VERSION
	OrbitalIcon.finalizeInit = finalizeInit

	modApi.events.onModsInitialized:subscribe(onModsInitialized)
end

return OrbitalIcon