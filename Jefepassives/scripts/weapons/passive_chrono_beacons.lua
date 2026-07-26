local passiveEffect = mod_loader.mods[modApi.currentMod].libs.passiveEffect
local pawnTypeUtils = mod_loader.mods[modApi.currentMod].libs.pawnTypeUtils

local CHRONO_DEBRIS_IMAGE = mod_loader.mods[modApi.currentMod].resourcePath .. "img/effects/chrono_debris.png"
local OVERCHARGED_DAMAGE = 2
-- Experimentally seems the right delay
local CHRONO_DEBRIS_SPEED = 13 -- tiles per second
local CHRONO_DEBRIS_OFFSET_X = -14
local CHRONO_DEBRIS_OFFSET_Y = 5
local CHRONO_DEBRIS_NUM_FRAMES = 7
local CHRONO_DEBRIS_FRAME_DELAY = 0.09
local CHRONO_DEBRIS_DELAY_BEFORE = 0.5
local CHRONO_DEBRIS_DELAY_AFTER = 0.5
local CHRONO_DEBRIS_DELAY_FOR_SOUND = 0.2

local chronoDebrisFlight = nil
local chronoDebrisSurface = nil
local chronoDebrisScaledSurface = nil
local chronoDebrisScaledFor = nil
local chronoDebrisDrawHooked = false
local chronoDebrisClipRect = sdl.rect(0, 0, 0, 0)

-- This is all a bit janky but its working so I don't want to
-- mess with it too much
local function boardTileToScreen(tileX, tileY)
	local scale = GetBoardScale()
	local uiScale = GetUiScale()
	local tile00, _, _, tw, th = getScreenRefs(scale)
	local tileW = tw * uiScale
	local tileH = th * uiScale

	return {
		x = tile00.x + tileW * (tileX - tileY) * scale,
		y = tile00.y + tileH * (tileX + tileY) * scale,
	}
end

local function getChronoDebrisOffscreenStart(target)
	local tileX = target.x
	local tileY = target.y

	while tileX > -4 and tileY > -4 do
		tileX = tileX - 7
		tileY = tileY + 1
	end

	return tileX, tileY
end

local function getChronoDebrisScaledSurface(drawScale)
	if not chronoDebrisSurface then
		chronoDebrisSurface = sdlext.surface(CHRONO_DEBRIS_IMAGE)
	end
	if chronoDebrisScaledFor ~= drawScale then
		chronoDebrisScaledFor = drawScale
		chronoDebrisScaledSurface = sdl.scaled(drawScale, chronoDebrisSurface)
	end
	return chronoDebrisScaledSurface
end

local function getChronoDebrisFallDistance(target)
	local fromX, fromY = getChronoDebrisOffscreenStart(target)
	local dx = target.x - fromX
	local dy = target.y - fromY
	return fromX, fromY, math.sqrt(dx * dx + dy * dy)
end

local function getChronoDebrisFallTime(distance)
	if distance <= 0 then
		return 0
	end
	return distance / CHRONO_DEBRIS_SPEED
end

local function getChronoDebrisTiming(target)
	local fromX, fromY, distance = getChronoDebrisFallDistance(target)
	local fallTime = getChronoDebrisFallTime(distance)
	local trailingFrameTime = (CHRONO_DEBRIS_NUM_FRAMES - 1) * CHRONO_DEBRIS_FRAME_DELAY
	local firstFrameDuration = fallTime - trailingFrameTime

	if firstFrameDuration < 0 then
		firstFrameDuration = 0
	end

	return {
		fromX = fromX,
		fromY = fromY,
		distance = distance,
		fallTime = fallTime,
		firstFrameDuration = firstFrameDuration,
		totalDuration = CHRONO_DEBRIS_DELAY_BEFORE + fallTime,
		delayBefore = CHRONO_DEBRIS_DELAY_BEFORE,
	}
end

local function getChronoDebrisFrameIndex(flight, elapsed)
	if elapsed < flight.firstFrameDuration then
		return 0
	end

	local animElapsed = elapsed - flight.firstFrameDuration
	return math.min(
		CHRONO_DEBRIS_NUM_FRAMES - 1,
		1 + math.floor(animElapsed / CHRONO_DEBRIS_FRAME_DELAY)
	)
end

local function blitChronoDebrisFrame(screen, drawScale, frameIndex, screenPos)
	local surface = getChronoDebrisScaledSurface(drawScale)
	local frameW = math.floor(surface:w() / CHRONO_DEBRIS_NUM_FRAMES)
	local frameH = surface:h()
	local x = math.floor(screenPos.x + CHRONO_DEBRIS_OFFSET_X * drawScale)
	local y = math.floor(screenPos.y + CHRONO_DEBRIS_OFFSET_Y * drawScale)

	chronoDebrisClipRect.x = x
	chronoDebrisClipRect.y = y
	chronoDebrisClipRect.w = frameW
	chronoDebrisClipRect.h = frameH

	local currentClipRect = screen:getClipRect()
	if currentClipRect then
		chronoDebrisClipRect = chronoDebrisClipRect:getIntersect(currentClipRect)
	end

	screen:clip(chronoDebrisClipRect)
	screen:blit(surface, nil, x - frameIndex * frameW, y)
	screen:unclip()
end


Jefepassives_ChronoBeacons = PassiveSkill:new{
	Name = "Chrono Beacons",
	Description = "Time Pods targets the strongest Vek on the board.",
	PowerCost = 1,
	Icon = "weapons/passives/passive_chrono_homing.png",
	Passive = "Jefepassives_ChronoBeacons",
	Upgrades = 1,
	UpgradeCost = {1},
	Overcharged = false,
	TipImage = {
		Unit = Point(2, 1),
		Enemy = Point(2, 3),
		Target = Point(2, 3),
	},
	TargetId = nil,
}

Weapon_Texts.Jefepassives_ChronoBeacons_Upgrade1 = "Overcharged"

function Jefepassives_ChronoBeacons.queueChronoDebrisFlight(target)
	local timing = getChronoDebrisTiming(target)
	chronoDebrisFlight = {
		fromX = timing.fromX,
		fromY = timing.fromY,
		toX = target.x,
		toY = target.y,
		startTime = os.clock(),
		fallTime = timing.fallTime,
		delayBefore = 0,
		firstFrameDuration = timing.firstFrameDuration,
		totalDuration = timing.totalDuration,
	}
end

function Jefepassives_ChronoBeacons:buildChronoDebrisEffect(target)
	local effect = SkillEffect()
	if not target or not Board or not Board:IsValid(target) then
		return effect
	end

	local timing = getChronoDebrisTiming(target)

	effect:AddScript([[local p = ]] .. target:GetString() .. [[
			Board:AddAlert(p, "DEBRIS INCOMING")
			Board:Ping(p, GL_Color(255, 50, 50))]])
	effect:AddDelay(timing.delayBefore)
	effect:AddSound("/props/pod_incoming")
	effect:AddDelay(CHRONO_DEBRIS_DELAY_FOR_SOUND)
	effect:AddScript("Jefepassives_ChronoBeacons.queueChronoDebrisFlight(" .. target:GetString() .. ")")
	effect:AddDelay(timing.fallTime)

	local damage = SpaceDamage(target, OVERCHARGED_DAMAGE)
	damage.sSound = "/impact/dynamic/rock"
	effect:AddDamage(damage)

	if CHRONO_DEBRIS_DELAY_AFTER > 0 then
		effect:AddDelay(CHRONO_DEBRIS_DELAY_AFTER)
	end

	return effect
end

function Jefepassives_ChronoBeacons:GetSkillEffect(p1, p2)
	local effect = SkillEffect()
	local damage = self.Overcharged and 2 or DAMAGE_DEATH
	local target = self.TipImage.Target
	local alertStr = self.Overcharged and "DEBRIS INCOMING" or "POD INCOMING"
	effect:AddScript([[local p = ]] .. target:GetString() .. [[
			Board:AddAlert(p, "]] .. alertStr .. [[")
			Board:Ping(p, GL_Color(255, 50, 50))]])
	effect:AddDelay(2)
	effect:AddDamage(SpaceDamage(target, damage))
	effect:AddDelay(2)
	return effect
end

function Jefepassives_ChronoBeacons:getVekPriorityTier(pawn)
	if pawnTypeUtils.isBoss(pawn) then
		return 4
	end
	-- psion
	if pawnTypeUtils.isSpawnCategory(pawn, "Leader") then
		return 3
	end
	if _G[pawn:GetType()].Tier == TIER_ALPHA then
		return 2
	end
	if pawnTypeUtils.isSpawnCategory(pawn, "Unique") then
		return 1
	end
	if pawnTypeUtils.isSpawnCategory(pawn, "Core") then
		return 0
	end
	return -1
end

local function isStrongerVekTarget(tier, health, pawnId, bestTier, bestHealth, bestId)
	if health ~= bestHealth then
		return health > bestHealth
	end
	if tier ~= bestTier then
		return tier > bestTier
	end
	return pawnId > bestId
end

local function isWeakerVekTarget(tier, health, pawnId, bestTier, bestHealth, bestId)
	return not isStrongerVekTarget(tier, health, pawnId, bestTier, bestHealth, bestId)
end

function Jefepassives_ChronoBeacons:findVekSpace(isPreferred)
	if not Board then
		return nil
	end

	local bestSpace, bestTier, bestHealth, bestId
	for _, pawnId in ipairs(extract_table(Board:GetPawns(TEAM_ANY))) do
		local pawn = Board:GetPawn(pawnId)
		if pawn and pawn:IsEnemy() and pawn:GetHealth() > 0 and
				not pawnTypeUtils.isSpawnCategory(pawn, "Bots")then
			local tier = self:getVekPriorityTier(pawn)
			local health = pawn:GetMaxHealth()
			if not bestSpace or isPreferred(tier, health, pawnId, bestTier, bestHealth, bestId) then
				bestTier = tier
				bestHealth = health
				bestId = pawnId
				bestSpace = pawn:GetSpace()
			end
		end
	end
	return bestSpace, bestId
end

function Jefepassives_ChronoBeacons:fireOverchargedStrike()
	local target = self:findVekSpace(isWeakerVekTarget)
	if not target or not Board:IsValid(target) then
		return
	end
	Board:AddEffect(self:buildChronoDebrisEffect(target))
end

function Jefepassives_ChronoBeacons:GetPassiveSkillEffect_OnDeploymentPhaseEnd()
	if not Board then
		return
	end

	if self.Overcharged then
		self:fireOverchargedStrike()
	end

	if not Board.SetPodLandingPoint then
		return
	end

	local target, id = self:findVekSpace(isStrongerVekTarget)
	if not target or not Board:IsValid(target) then
		return
	end

	self.TargetId = id
	Board:SetPodLandingPoint(target)
end

-- This keeps the vek from soft locking on being killed
function Jefepassives_ChronoBeacons:GetPassiveSkillEffect_OnPodLanded()
	local pawn = Board:GetPawn(self.TargetId)
	if pawn then
		Board:RemovePawn(pawn)
	end
end

function Jefepassives_ChronoBeacons:GetPassiveSkillEffect_OnFrameDrawStart(screen)
	if not Board or not chronoDebrisFlight then
		return
	end

	local flight = chronoDebrisFlight
	local elapsed = os.clock() - flight.startTime

	if elapsed >= flight.fallTime then
		chronoDebrisFlight = nil
		return
	end

	local moveElapsed = elapsed
	local flyProgress = 0
	if moveElapsed > 0 and flight.fallTime > 0 then
		flyProgress = math.min(1, moveElapsed / flight.fallTime)
	end

	local tileX = flight.fromX + (flight.toX - flight.fromX) * flyProgress
	local tileY = flight.fromY + (flight.toY - flight.fromY) * flyProgress
	local drawScale = GetBoardScale() * GetUiScale()
	local screenPos = boardTileToScreen(tileX, tileY)
	local frameIndex = getChronoDebrisFrameIndex(flight, elapsed)

	blitChronoDebrisFrame(screen, drawScale, frameIndex, screenPos)
end

function Jefepassives_ChronoBeacons:GetPassiveSkillEffect_OnGameExited()
	chronoDebrisFlight = nil
end

function Jefepassives_ChronoBeacons:init(fullChronoBeacons)
	if fullChronoBeacons then
		LOG("Full version of Chrono Beacons initialized")
		Jefepassives_ChronoBeacons_A = Jefepassives_ChronoBeacons:new{
			UpgradeDescription = "After deployment, a chrono debris fragment strikes the weakest Vek for 2 damage.",
			Overcharged = true,
		}
	else
		LOG("Non memhack version of Chrono Beacons initialized")
		Jefepassives_ChronoBeacons.Upgrades = 0
		Jefepassives_ChronoBeacons.Overcharged = true
		Jefepassives_ChronoBeacons.Description =
				"After deployment, a chrono debris fragment strikes the weakest Vek for 2 damage."
	end

	local hooks = {
		"onDeploymentPhaseEnd",
		"onFrameDrawStart",
		"onGameExited",
	}
	if fullChronoBeacons then
		table.insert(hooks, "onPodLanded")
	end

	passiveEffect:addPassiveEffect("Jefepassives_ChronoBeacons", hooks)
end

return Jefepassives_ChronoBeacons