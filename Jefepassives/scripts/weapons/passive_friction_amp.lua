-- By Hedera

Jefepassives_Friction = PassiveSkill:new{
	Name = "Friction Amp",
	Description = "When an enemy is subjected to forced movement, set it on Fire.",
	PowerCost = 2,
	Icon = "weapons/passives/passive_friction_amp.png",
	Upgrades = 0,
	Passive = "Jefepassives_Friction",
	TipImage = {
		Unit = Point(1,3),
		CustomPawn = "ArtiMech",
		Enemy = Point (2,1),
	}
}

Emitter_Spark = Emitter_Burst_Heal:new{
	image = "effects/particle_spark.png",
	max_alpha = 1,
	lifespan = 2,
	burst_count = 5,
	variance_x = 15,
	variance_y = 15,
	angle = 300,
	speed = 4,
	gravity = true,
}

Emitter_Spark_0 = Emitter_Spark:new{
	angle = -30,
}

Emitter_Spark_1 = Emitter_Spark:new{
	angle = 30,
}

Emitter_Spark_2 = Emitter_Spark:new{
	angle = 180,
}

Emitter_Spark_3 = Emitter_Spark:new{
	angle = 240,
}

-- 30 is down-right, -30 is up-right, 180 is down-left, 240 is up-left, 300 is straight up

function Jefepassives_Friction:GetSkillEffect(p1,p2)
	local ret = SkillEffect()
		local vek_id = Board:GetPawn(Point(2,1)):GetId()
		local direction = GetDirection(p2 - p1)
		local damage = SpaceDamage(Point(1,1), 1)
		ret:AddArtillery(Point(1,3),damage,"effects/shot_artimech.png",FULL_DELAY)
		for dir = 0, 3 do
			damage = SpaceDamage(Point(1,1) + DIR_VECTORS[dir],0,dir)
			damage.sAnimation = "airpush_"..dir
			ret:AddDamage(damage)
		end
		ret:AddDelay(.2)
		ret:AddBurst(Point(3,1),"Emitter_Spark_1",DIR_NONE)
		local burn = SpaceDamage(Point(3,1),0)
		burn.iFire = EFFECT_CREATE
		burn.bHide = true
		ret:AddDamage(burn)
		ret:AddDelay(1.4)
			
	return ret
end

	local PushCheck = function(mission, pawn, oldPosition)
		if IsPassiveSkill("Jefepassives_Friction") and pawn:GetTeam() == TEAM_ENEMY and mission ~= nil and Game:GetTeamTurn() == TEAM_PLAYER then
			local board_size = Board:GetSize()
			local newPosition = pawn:GetSpace()
			--some mods send pawns outside the board, don't count that here
			if newPosition.x >= 0 and newPosition.x < board_size.x and newPosition.y >= 0 and newPosition.y < board_size.y and oldPosition.x >= 0 and oldPosition.x < board_size.x and oldPosition.y >= 0 and oldPosition.y < board_size.y then
				if newPosition.x == oldPosition.x or newPosition.y == oldPosition.y then --if points are inline
					local dir = GetDirection(newPosition - oldPosition)
					Board:AddBurst(newPosition,"Emitter_Spark_"..dir,DIR_NONE)
				else
					Board:AddBurst(newPosition,"Emitter_Spark",DIR_NONE)
				end
				local burn = SpaceDamage(pawn:GetSpace(),0)
				burn.iFire = EFFECT_CREATE
				Board:DamageSpace(burn)
			end
		end
	end

	local function EVENT_onModsFirstLoaded()
		modapiext:addPawnPositionChangedHook(PushCheck)
	end
	
modApi.events.onModsLoaded:subscribe(EVENT_onModsFirstLoaded)
