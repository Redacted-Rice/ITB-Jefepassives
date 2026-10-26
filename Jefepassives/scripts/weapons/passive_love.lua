-- Enables Roy Mode. Have fun Jefepato!
-- special thanks to Lemonymous and Metalocif for dialog system help

Jefepassives_Love = PassiveSkill:new{
	Name = "The Power of Love",
	Description = "Once you embrace the power of love, it will never truly leave you.",
	Icon = "weapons/passives/passive_love.png",
	Passive = "Jefepassives_Love",
	Rarity = 1,
	PowerCost = 0,
	Damage = 0,
	Upgrades = 0,
	TipImage = {
		Unit = Point(5, 5),
		Enemy = Point(2, 2),
		CustomEnemy = "Roy_Tentacle"
	},
}

RoyRadio = Pawn:new{
	Name = "Radio Tower",
	Health = 3,
	Image = "radiotower",
	MoveSpeed = 0,
	DefaultTeam = TEAM_ENEMY,
	SkillList = {},
	ImpactMaterial = IMPACT_METAL,
	SoundLocation = "/support/vip_truck/",
	Pushable = false,
	Massive = true,
	Neutral = true,
	Portrait = "enemy/radioroy",
}
AddPawn("RoyRadio")

local function addRoyDialog(mission)
	Board:AddPawn("RoyRadio",Point(-1,-1))
	local pawn_list = Board:GetPawns(TEAM_ANY)
	for i = 0,pawn_list:size() do
		local subject = Board:GetPawn(pawn_list:index(i))
		if subject ~= nil then
			if subject:GetType() == "RoyRadio" then
				mission.royradio_dialog_id = pawn_list:index(i)
			end
		end
	end
	local roy = Board:GetPawn(mission.royradio_dialog_id)
	roy:SetSpace(Point(-1,-1))
end

function IsInTable(tb, element)
  for _, value in pairs(tb) do
    if value == element then
      return true
    end
  end
  return false
end

local function addRoyCombat(mission)
	local size = Board:GetSize()
	local points = {}
	for x = 0,size.x do
		for y = 0,size.y do
			local curr = Point(x,y)
			if not Board:IsPawnSpace(curr) and not Board:IsBlocked(curr,PATH_GROUND) then
				points[#points + 1] = curr
			end
		end
	end
	local result = Point(-1,-1)
	while result == Point(-1,-1) do
		local try = random_removal(points)
		if not IsInTable(extract_table(Board:GetZone("pylons")),try) then -- do not spawn on a pylon
			result = try
		end
	end
	Board:AddPawn("RoyRadio",result)
	local pawn_list = Board:GetPawns(TEAM_ANY)
	for i = 0,pawn_list:size() do
		local subject = Board:GetPawn(pawn_list:index(i))
		if subject ~= nil then
			if subject:GetType() == "RoyRadio" then
				mission.royradio_dialog_id = pawn_list:index(i) -- comes out nil? why???
			end
		end
	end
	local status = not Board:IsPawnAlive(mission.royradio_dialog_id) and OBJ_COMPLETE or OBJ_STANDARD
	Game:AddObjective("Kill Roy Rubold",status)
end

 local function initDialog(mission)
	if not IsPassiveSkill("Jefepassives_Love") and GAME.RoyMode == true and GAME.royradio_dialog_unequip ~= true then -- play after unequipping, only once
		addRoyDialog(mission)
		GAME.royradio_dialog_unequip = true
		local cast = {}
		cast.main = mission.royradio_dialog_id
		modapiext.dialog:triggerRuledDialog("JPass_RoyUnequip",cast)
	elseif IsPassiveSkill("Jefepassives_Love") or GAME.RoyMode == true then -- do effects like normal
		if GAME.RoyMode == nil then -- first trigger
			GAME.RoyMode = true -- :)
			addRoyDialog(mission)
			local cast = {}
			cast.main = mission.royradio_dialog_id
			modapiext.dialog:triggerRuledDialog("JPass_RoyIntro",cast)
		elseif mission.MapTags[1] == "final_island" then -- phase 1 last island
			addRoyDialog(mission)
			local cast = {}
			cast.main = mission.royradio_dialog_id
			modapiext.dialog:triggerRuledDialog("JPass_RoyFinal1",cast)
		elseif GAME.RoyMode == true then -- subsequent triggers
			addRoyDialog(mission)
			local cast = {}
			cast.main = mission.royradio_dialog_id
			modapiext.dialog:triggerRuledDialog("JPass_RoyMissionStart",cast)
		end
	end
 end
 
 local function killDialog(mission, pawn)
	if mission ~= nil then
		if pawn:GetType() == "Roy_Tentacle" then
			local cast = {}
			cast.main = mission.royradio_dialog_id
			modapiext.dialog:triggerRuledDialog("JPass_RoyTentaKill",cast)
		elseif pawn:GetType() == "RoyRadio" and pawn:GetSpace() ~= Point(-1,-1) then -- only counts when he's on the board
			if mission.MapTags[1] == "final_cave" then -- total hack to prevent instakills by random intro boulders. Should this be here? probably not.
				pawn:SetHealth(1)
				if mission.royradio_dialog_id == nil then -- shouldn't happen, but does
					local pawn_list = Board:GetPawns(TEAM_ANY)
					for i = 0,pawn_list:size() do
						local subject = Board:GetPawn(pawn_list:index(i))
						if subject ~= nil then
							if subject:GetType() == "RoyRadio" then
								mission.royradio_dialog_id = pawn_list:index(i)
							end
						end
					end
				end
				local cast = {}
				cast.main = mission.royradio_dialog_id
				modapiext.dialog:triggerRuledDialog("JPass_RoyDie",cast)
				GAME.RoyMode = false
				Board:StartShake(1)
				local die_space = pawn:GetSpace()
				pawn:SetSpace(Point(-1,-1))
				Board:AddAnimation(die_space,"radiotowerd",ANIM_DELAY)
				modApi:scheduleHook(1000, function() -- let the dialog play first
					Board:AddAnimation(die_space,"explo_fire1",ANIM_DELAY)
					pawn:SetHealth(0)
					local enemyList = extract_table(Board:GetPawns(TEAM_PLAYER))
					for i = 1, #enemyList do
						if Board:GetPawn(enemyList[i]):GetType() == "Roy_Tentacle" then
							Board:AddAnimation(Board:GetPawn(enemyList[i]):GetSpace(),"djinn_tentae",ANIM_REVERSE)
							Board:RemovePawn(Board:GetPawn(enemyList[i]))
						end
					end
				end)
			else
				pawn:SetHealth(3) -- nuh uh! doesn't count!
			end
		end
	end
 end
 
 local fixMode = function()
	if GAME.RoyMode == false then GAME.RoyMode = true end -- crash prevention
end
 
 local function phase2Dialog(mission)
	if GAME.RoyMode == true and (mission.MapTags[1] == "final_cave" or mission.MapTags[1] == "final_island") then  -- phase 2 last island
		modApi:conditionalHook(
			function()
				return Board ~= nil and mission ~= nil --crash prevention, it's a rough transition
			end,
			function()
				addRoyCombat(mission)
				local cast = {}
				cast.main = mission.royradio_dialog_id
				modapiext.dialog:triggerRuledDialog("JPass_RoyFinal2",cast)
			end
		)
	end
end

-- dialog ---------------------------------------------------------

Personality.Artificial.JPass_RoyIntro = {
	"Testing, testing. Is this thing on?",
	"Coming in loud and clear. Hello islands!",
	"10-8, all readings clear. We're live!",
	"Roy Rubold here, thanks for tuning in.",
	"Hello to all our new listeners out there.",
}

modapiext.dialog:addRuledDialog("JPass_RoyIntro", {
    Odds = 100,
    { main = "JPass_RoyIntro" }
})

Personality.Artificial.JPass_RoyUnequip = {
	"Don't touch that dial, folks!",
	"Did you miss me?",
	"Can't get rid of me that easily.",
	"Still here, just in case you were worried.",
	"Still here, by the way.",
}

modapiext.dialog:addRuledDialog("JPass_RoyUnequip", {
    Odds = 100,
    { main = "JPass_RoyUnequip" }
})

Personality.Artificial.JPass_RoyMissionStart = {
	"Let's get this party started!",
	"Come on out dear, we've got company!",
	"She'll be with us in just a moment.",
	"Now remember - no fighting, you three!",
	"Come out and play!",
	"I'm getting something thrilling on my sensors!",
	"Our show's just about to start!",
	"Beautiful day for it, don't you think?",
	"Good to see you again.",
	"Need some help? Not to worry!",
	"Here, let me get those for you.",
	"Let's make this a bit more exciting!",
	"We'll be back after a quick commercial break.",
	"Now back to our scheduled programming.",
	"One more for the fans!",
	"Be glad you're not watching this one folks, it's about to get grisly.",
	"Will our heroes prevail? I hope not!",
	"It's a nice landscape, but it could use more lava.",
	"Hear that? She's getting closer now!",
	"Something's coming in hot from the main hive.",
	"Make way for the main attraction!",
	"Roy Rubold, coming in live from the site of the outbreak!",
	"Something big is brewing beneath the surface!",
	"Hold on, we're having some interference.",
	"Go team! No, not you guys, the other ones.",
	"I know you're listening to this, you know.",
	"Bo-ring! Bring in the cavalry!",
	"Oh great, the Mechs are back.",
	"Give her a minute, she's warming up.",
	"Maybe we can just talk this out.",
	"Good morning, everybody!",
	"Hey it's Roy, just checking in.",
	"Yeah, it's the Mechs again. Send her in.",
	"Places, everyone!",
	"Places, everyone! It's showtime!",
	"They're here, get in position!",
	"We're doing this again, are we?",
	"Guess who!",
	-- TODO: add more (never enough)
}

modapiext.dialog:addRuledDialog("JPass_RoyMissionStart", {
    Odds = 100,
    { main = "JPass_RoyMissionStart" }
})

Personality.Artificial.JPass_RoyTentaKill = {
	"Now that's just uncalled for.",
	"Don't mind them dear, they're just jealous.",
	"Send up another! We've had an accident!",
	"That's just undignified.",
	"Really? Oh well.",
	"Ouch.",
	"You hate to see it, folks.",
	"You really hate to see it, folks.",
	"Sorry dear!",
	"It's nothing personal, I'm sure.",
	"She'll get better in no time.",
	"Oh, she's really mad now!",
	"She'll get you for that.",
	"You just can't be doing that.",
	"Well, at least we have more.",
	"Rude!",
	"How rude!",
	"Stop that!",
	"Surely we can just talk this out.",
	"You deserve to lose, acting like this.",
	"Now you've done it.",
	"Now you've really done it.",
	"Oh come on.",
	"Come on, you know better.",
	"What did they ever do to you?",
	
}

modapiext.dialog:addRuledDialog("JPass_RoyTentaKill", {
    Odds = 40,
    { main = "JPass_RoyTentaKill" }
})

Personality.Artificial.JPass_RoyFinal1 = {
	"Darling, you're needed upstairs.",
	"Come to pay me a visit, have you?",
	"Is it that time already?",
	"Feeling powerful enough to come knocking, I see.",
	"Oh great. They're here already.",
}

modapiext.dialog:addRuledDialog("JPass_RoyFinal1", {
    Odds = 100,
    { main = "JPass_RoyFinal1" }
})

Personality.Artificial.JPass_RoyFinal2 = {
	"They've reached the station! Defend me, dear!",
	"You don't stand a chance. This volcano loves me.",
	"Prepare to be destroyed by the power of love.",
}

modapiext.dialog:addRuledDialog("JPass_RoyFinal2", {
    Odds = 100,
    { main = "JPass_RoyFinal2" }
})

Personality.Artificial.JPass_RoyDie = {
	"She'll avenge me! Just you wait!",
	"This isn't over! I'll be back!",
	"Kill them all for me, dear.",
	"Over and out.",
}

modapiext.dialog:addRuledDialog("JPass_RoyDie", {
    Odds = 100,
    { main = "JPass_RoyDie" }
})


-- functionality below copied from Roy Rubold, obviously--------------------------------------

local function getUnoccupiedSpace(offset) --offset added to help randomness
	local ret = Point(-1,-1)
	local size = Board:GetSize()
	while ret == Point(-1,-1) do
		math.randomseed(os.time() - offset)
		local x = math.random(0,size.x - 1)
		local y = math.random(0,size.y - 1)
		if not Board:IsBlocked(Point(x,y),PATH_GROUND) or Board:IsPawnSpace(Point(x,y)) then
			ret = Point(x,y)
		end
	end
	return ret
end

local function tentaCount() --thanks tatu!
	local count = 0
	local enemyList = extract_table(Board:GetPawns(TEAM_PLAYER))
	for i = 1, #enemyList do
		if Board:GetPawn(enemyList[i]):GetType():find("Roy_Tentacle") ~= nil then
			count = count + 1
		end
	end
	return count
end

BaseEmerge = ANIMS.Animation:new { 
	Image = "units/aliens/firefly_1_emerge.png", 
	NumFrames = 10, 
	PosX = -24, 
	PosY = 0, 
	Loop = false, 
	Time = 0.05, 
	Sound = "/enemy/shared/crawl_out",
	Height = 1}

BaseUnit = ANIMS.Animation:new { Image = "units/player/mech_punch_1.png", PosX = -19, PosY = -4, Loop = true, Time = 0.3 }
EnemyUnit = BaseUnit:new { Height = 1 }

ANIMS.djinn_tenta = EnemyUnit:new{ Image = "units/aliens/djinn_tenta.png", PosX = -24, PosY = -10 }
ANIMS.djinn_tentaa = EnemyUnit:new{ Image = "units/aliens/djinn_tentaa.png", PosX = -24, PosY = -10, NumFrames = 6 }
ANIMS.djinn_tentae = BaseEmerge:new{ Image = "units/aliens/djinn_tentae.png", PosX = -24, PosY = -10, NumFrames = 8 }
ANIMS.djinn_tentad = EnemyUnit:new{ Image = "units/aliens/djinn_tentad.png", PosX = -28, PosY = -10, NumFrames = 8, Time = 0.14, Loop = false  }
ANIMS.djinn_tenta = EnemyUnit:new{ Image = "units/aliens/djinn_tenta.png", PosX = -24, PosY = -10 }
ANIMS.radiotowera = EnemyUnit:new{ Image = "units/aliens/radiotower_a.png", PosX = -28, PosY = -18, NumFrames = 6 }
ANIMS.radiotowerd = EnemyUnit:new{ Image = "units/aliens/radiotower_d.png", PosX = -28, PosY = -18, NumFrames = 10, Time = 0.12, Loop = false }

Roy_Tentacle = Pawn:new{
	Name = "Tentacle",
	Health = 1,
	Image = "djinn_tenta",
	MoveSpeed = 7,
	Burrows = true,
	DefaultTeam = TEAM_ENEMY,
	SkillList = {"TentaAtk"},
	ImpactMaterial = IMPACT_INSECT,
	SoundLocation = "/enemy/burrower_1/",
	Pushable = false,
	Neutral = true,
	Portrait = "enemy/djinn_tenta",
}
AddPawn("Roy_Tentacle") 

TentaAtk = Skill:new{
	Name = "Consuming Grasp",
	Description = "Crushes an adjacent tile, killing anything on it.",
	PathSize = 1,
	Icon = "weapons/enemy_scorpion1.png",	
	Damage = DAMAGE_DEATH,
	PreDamage = 0,
	Range = 1,
	Web = 0,
	Acid = 0,
	Push = 0,
	Class = "Enemy",
	ScoreEnemy = 5,
	ScoreFriendlyDamage = 5,
	ScoreBuilding = 0,
	ScoreNothing = 0,
	LaunchSound = "",
	SoundBase = "/enemy/scorpion_soldier_1",
	TipImage = {
		Unit = Point(2,2),
		Enemy = Point(2,1),
		Target = Point(2,1),
		CustomPawn = "Roy_Tentacle"
	}
}

function TentaAtk:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	local direction = GetDirection(p2 - p1)
	local push = self.Push == 1 and direction or DIR_NONE
	
	if not Board:IsPawnSpace(p2) or Board:GetPawn(p2):GetType() ~= "RoyRadio" then -- roy is immune
		local damage = SpaceDamage(p2,self.Damage,push)
		if Board:GetTerrain(p2) ~= TERRAIN_LAVA then damage.sAnimation = "tentacles" end
		damage.iTerrain = TERRAIN_LAVA
		damage.iAcid = self.Acid
		damage.iDamage = DAMAGE_DEATH
		damage.sSound = self.SoundBase.."/attack"
		
		ret:AddQueuedMelee(p1,damage)
	end
	return ret
end	
----------------------------------------------- HOOKS HANDLERS -----------------------------------------------

local function GetSkillEffect()
	local ret = SkillEffect()
	local present = tentaCount()
	if present >= 0 and present < 3 then
		for i = 0, 2 - present do
			local pawn = PAWN_FACTORY:CreatePawn("Roy_Tentacle") 
			Board:AddPawn(pawn) 
			pawn:SetTeam(TEAM_ENEMY) 
			pawn:SpawnAnimation() 
			pawn:SetTeam(TEAM_PLAYER) 
			--tentacle.iDamage = "DAMAGE_DEATH"
		end
	end
	return ret
end


local spawn = function(mission)
	if GAME.RoyMode == true and Game:GetTeamTurn() == TEAM_ENEMY then
			Board:AddEffect(GetSkillEffect())
	end
end

----------------------------------------------- HOOKS / EVENTS SUBSCRIPTION -----------------------------------------------

local function EVENT_onModsLoaded()
	modApi:addNextTurnHook(spawn)
	--modApi:addNextTurnHook(initDialog)
	modApi:addMissionStartHook(initDialog)
	--modApi:addMissionStartHook(phase2Dialog)
	modApi:addMissionNextPhaseCreatedHook(phase2Dialog) --uh oh! causes a crash!
	modapiext:addPawnKilledHook(killDialog)
	modApi:addPreLoadGameHook(fixMode)
end



modApi.events.onModsLoaded:subscribe(EVENT_onModsLoaded)