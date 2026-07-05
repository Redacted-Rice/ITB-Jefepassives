--[[
Idea: Truelch
Code: Truelch

Generic think it'll be useless, I think it'll be helpful, let's find out!
]]

Jefepassives_RandomSwap = PassiveSkill:new{
	--Infos
	Name = "Experimental Swapper",
	Description = "At the start of player's turn, swap two random enemies.",
	PowerCost = 1,
	Icon = "weapons/passives/passive_random_swap.png",

	--Passive
	Passive = "Jefepassives_RandomSwap",

	--Tip image
	TipImage = {
		Unit   = Point(0, 0),
		Target = Point(0, 0),

		Enemy1    = Point(1, 2),
		Building  = Point(1, 3),

		Enemy2    = Point(3, 2),
		Building1 = Point(3, 1),

		CustomEnemy = "Firefly1",
	}
}

function Jefepassives_RandomSwap:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	local damage = SpaceDamage(0)
	damage.bHide = true
	damage.sScript = "Board:GetPawn(Point(1, 2)):FireWeapon(Point(1, 3), 1)"
	ret:AddDamage(damage)

	local damage = SpaceDamage(0)
	damage.bHide = true
	damage.sScript = "Board:GetPawn(Point(3, 2)):FireWeapon(Point(3, 1), 1)"
	ret:AddDamage(damage)

	damage = SpaceDamage(0)
	damage.bHide = true
	damage.fDelay = 1.5
	ret:AddDamage(damage)

	local delay = Board:IsPawnSpace(p2) and 0 or FULL_DELAY --TODO: simplify this
	ret:AddTeleport(Point(1, 2), Point(3, 2), delay)
	
	if delay ~= FULL_DELAY then
		ret:AddTeleport(Point(3, 2), Point(1, 2), FULL_DELAY)
	end

	return ret
end

local function swap2(pawnId1, pawnId2)

	local enemy1 = Board:GetPawn(pawnId1)
	local enemy2 = Board:GetPawn(pawnId2)

	if enemy1 == nil or enemy2 == nil then
		--LOG("At least one of the pawns we want to swap is nil!")
		return
	end

	local p1 = enemy1:GetSpace()
	local p2 = enemy2:GetSpace()

	local delay = Board:IsPawnSpace(p2) and 0 or FULL_DELAY --TODO: simplify this
	--LOG("Jefepassives_RandomSwap -> delay: "..tostring(delay))

	local effect = SkillEffect()

	local sfx = SpaceDamage(p1, 0)
	sfx.sSound = "/weapons/swap"
	effect:AddDamage(sfx)

	effect:AddTeleport(p1, p2, delay)

	if delay ~= FULL_DELAY then
		effect:AddTeleport(p2, p1, FULL_DELAY)
	end

	Board:AddEffect(effect)
end


local function swap(pawnId1, pawnId2)
	if IsPassiveSkill("Jefepassives_TauntingField") then
		modApi:scheduleHook(550, function()
			swap2(pawnId1, pawnId2)
		end)
	else
		swap2(pawnId1, pawnId2)
	end
end




local EVENT_onNextTurn = function(mission)
	if Game:GetTeamTurn() == TEAM_PLAYER and IsPassiveSkill("Jefepassives_RandomSwap") then
		local enemies = {}

		local m = GetCurrentMission()
		if m ~= nil then
			m.jefepassives_swapped_enemies = nil --to avoid swapping again on a future turn reset
		end

		--There must be a way to access directly all the enemy pawns without scanning the whole board, but I'm lazy.
		for j = 0, 7 do
			for i = 0, 7 do
				local curr = Point(i, j)
				local pawn = Board:GetPawn(curr)
				if pawn ~= nil and pawn:IsEnemy() and not pawn:IsGuarding() then
					enemies[#enemies + 1] = pawn
				end
			end
		end

		--Pick two randoms
		if #enemies >= 2 then
			local enemy1 = table.remove(enemies, math.random(1, #enemies))
			local enemy2 = table.remove(enemies, math.random(1, #enemies))

			swap(enemy1:GetId(), enemy2:GetId())

			--Save in the data swapped enemies
			if m ~= nil then
				m.jefepassives_swapped_enemies = { enemy1:GetId(), enemy2:GetId() }
			end
		end
	end
end

modApi.events.onNextTurn:subscribe(EVENT_onNextTurn)

local EVENT_onResetTurn = function(mission)
	modApi:scheduleHook(550, function() --TODO: change that into an appropriate conditional hook
		local m = GetCurrentMission()
		if m ~= nil and m.jefepassives_swapped_enemies ~= nil then
			swap(m.jefepassives_swapped_enemies[1], m.jefepassives_swapped_enemies[2])
		else
			--LOG("either the mission or the swapped enemies data is nil")
		end
	end)
end
modapiext.events.onResetTurn:subscribe(EVENT_onResetTurn)