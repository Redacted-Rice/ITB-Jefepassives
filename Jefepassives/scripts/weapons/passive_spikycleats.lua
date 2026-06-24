Jefepassives_SpikyCleats_Passive = PassiveSkill:new{
	Name = "Concussors",
	Description = "Blocking a spawn causes the underground Vek to lose health.",
	PowerCost = 1,
	Icon = "weapons/passives/passive_spikycleats.png",
	Upgrades = 1,
	Pawn = "Scorpion1",
	UpgradeCost = {2},
	UpgradeList = { "+1 Damage" },
	Passive = "Jefepassives_SpikyCleats_Passive",
	TipImage = {
		Unit = Point (2,2),
		CustomPawn = "PunchMech",
        	Target = Point(2,2),
        	Enemy = Point(2,2),
	}
}
function Jefepassives_SpikyCleats_Passive:GetSkillEffect(p1,p2)
	local ret = SkillEffect()
	local point = Point(3,2)
	local damage = SpaceDamage(point,0)
	damage.bHide = true
	damage.sPawn = self.Pawn
	ret:AddDamage(damage)
	ret:AddScript("Board:GetPawn(Point(3,2)):SetHealth(2)")
	ret:AddDelay(2)
	damage = SpaceDamage(point,2,1)
	damage.sAnimation = "explopunch1_"..1
	ret:AddMelee(Point(2,2),damage)
	return ret
end
Jefepassives_SpikyCleats_Passive_A = Jefepassives_SpikyCleats_Passive:new{
	UpgradeDescription = "Deals one additional damage each time.",
	Passive = "Jefepassives_SpikyCleats_Passive_A",
	Pawn = "Beetle1",
}

local function EVENT_VekSpawnRemoved(mission, spawnData)
	if IsPassiveSkill("Jefepassives_SpikyCleats_Passive") then
	local dmg = 1
	if IsPassiveSkill("Jefepassives_SpikyCleats_Passive_A") then
		dmg = 2
	end
		local point = spawnData.location
		if Board:IsPawnSpace(point) and (Board:GetPawn(point):GetId() == spawnData.id) then
			(Board:GetPawn(point)):SetHealth((_G[Board:GetPawn(point):GetType()].Health) - (spawnData.turns - 1)*dmg)
		end
	end
end
--Start of the section I like to call "Black magic I stole from paradoxica"
EXCL = {
    "GetAmbience", 
    "GetBonusStatus", 
    "BaseUpdate", 
    "UpdateMission", 
    "GetCustomTile", 
    "GetDamage", 
    "GetTurnLimit", 
    "BaseObjectives",
    "UpdateObjectives",
} 

for i,v in pairs(Mission) do 
    if type(v) == 'function' then 
        local oldfn = v 
        Mission[i] = function(...) 
            if not list_contains(_G["EXCL"], i) then 
                if i == "IsEnvironmentEffect" then
					local spawn_remover = false
						if IsPassiveSkill("Jefepassives_SpikyCleats_Passive") then
							spawn_remover = true
						end
					if spawn_remover then
						GetCurrentMission().DestabilizeCounter = 0
						GetCurrentMission().BlockedSpawnList = {}
					end
				end
            end 
            return oldfn(...) 
        end 
    end 
end

local function EVENT_MissionUpdate(mission)
	local spawn_remover = false
	if mission.ID == "Mission_Test" then return end
	for i = 0,2 do
		if IsPassiveSkill("Jefepassives_SpikyCleats_Passive") then
			spawn_remover = true
		end
	end
	if not spawn_remover then return end
	local CannotSpawn = PointList()
	for k = 1,#mission.QueuedSpawns do
		local curr = mission.QueuedSpawns[k].location
		if Board:IsTerrain(curr, TERRAIN_HOLE) or Board:IsTerrain(curr, TERRAIN_WATER) then
			CannotSpawn:push_back(curr)
		end
	end
	local DeleteThese = extract_table(CannotSpawn)
	for i = 1, #DeleteThese do
		if Board:IsTerrain(DeleteThese[i], TERRAIN_LAVA) then 
			GetCurrentMission():RemoveSpawnPoint(DeleteThese[i])
			Board:SetTerrain(DeleteThese[i], TERRAIN_LAVA)
		else
			GetCurrentMission():RemoveSpawnPoint(DeleteThese[i])
		end
	end
	if Game:IsEvent(EVENT_SPAWNBLOCKED) then
		--increment counter
		mission.DestabilizeCounter = mission.DestabilizeCounter + 1
		--extract list of non-blocked spawns
		if mission.DestabilizeCounter == 1 then
			--add first point in case the first block kills the blocking unit
			if mission.QueuedSpawns[1]~=nil then
				mission.BlockedSpawnList[1] = mission.QueuedSpawns[1].location
			else
				mission.BlockedSpawnList[1] = Point(-1,-1)
			end
			--check if rest of list exists
			if #mission.QueuedSpawns > 1 then
				for k = 2,#mission.QueuedSpawns do
					local curr = mission.QueuedSpawns[k].location
					if not Board:IsTerrain(curr, TERRAIN_HOLE) and not Board:IsTerrain(curr, TERRAIN_WATER) and Board:IsBlocked(curr,PATH_FLYER) then
						mission.BlockedSpawnList[#mission.BlockedSpawnList + 1] = curr
					end
				end
			end
		end
		--crack blocked spawn
			if IsPassiveSkill("Jefepassives_SpikyCleats_Passive") then
	local dmg = 1
	if IsPassiveSkill("Jefepassives_SpikyCleats_Passive_A") then
		dmg = 2
	end
				local point = mission.BlockedSpawnList[mission.DestabilizeCounter]
				local data = mission:GetSpawnPointData(point)
				local type = data.type

				if (_G[type].Health) <= ((data.turns)*dmg) then


					mission:RemoveSpawnPoint(point)

				end
				Game:TriggerSound("/weapons/crack_ko")
			end
	end
end
--End of the section I like to call "Black magic I stole from paradoxica"


	local function EVENT_onModsFirstLoaded()
			modApi.events.onMissionUpdate:subscribe(EVENT_MissionUpdate)
			modApi.events.onVekSpawnRemoved:subscribe(EVENT_VekSpawnRemoved)
	end
	
	modApi.events.onModsFirstLoaded:subscribe(EVENT_onModsFirstLoaded)
