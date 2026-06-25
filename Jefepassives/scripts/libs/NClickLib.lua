local mod = modApi:getCurrentMod()
local path = mod.scriptPath
local weaponArmed = require(path .."libs/weaponArmed")
Clicks = {}
PhaseClicks = {{}}
FiredUsingComfirm = false
Phase = 1
PreventDouble = true
NClickSkill = Skill:new{
	TwoClick = true,
	PhaseChanges = {nil},
	ConfirmationFuncs = {nil},
	NClick = true
}
function NClickSkill:GetTargetArea(p1)
	local ret = PointList()
	ret:push_back(Point(10,10))
	if self.TargetAreas[Phase] then
		self.TargetAreas[Phase](ret, p1, self)
	else
		LOG("Attempted to use TargetArea ", Phase)
	end
	return ret
end

function NClickSkill:IsTwoClickException(p1,p2)
	if p2==Point(10,10) then
		Clicks = {}
		PhaseClicks = {{}}
		Phase = 1
		return true
	else

	local NextPhase = (self.PhaseChanges[Phase] or function(a,b,c) return Phase+1 end)(p1,p2,self) --Lua is ridiculous for letting me do this line


	if (NextPhase) > (self.Phases) then
		
		Clicks = {}
		PhaseClicks = {{}}
		Phase = 1
		return true
	end
	return false
	end

end

function NClickSkill:GetSkillEffect(p1, p2)
		local ret = SkillEffect()
		ret:AddDamage(SpaceDamage(p1, 0))
		self.SkillEffects[Phase](ret, p1, p2, self)
		return ret
end

function NClickSkill:GetSecondTargetArea(p1, p2)
	local ret = PointList()

	if (Board:GetPawn(p1):GetFirstClick() == Point(1000,1000)) then
		local NextPhase = (self.PhaseChanges[Phase] or function(a,b,c) return Phase+1 end)(p1,p2,self)
		if self.TargetAreas[NextPhase] then
			self.TargetAreas[NextPhase](ret,p1,self,p2)
		end
	else
		if PreventDouble then
			if not PhaseClicks[Phase] then
				PhaseClicks[Phase] = {}
			end
			(PhaseClicks[Phase])[#(PhaseClicks[Phase])+1]=p2
			Phase = (self.PhaseChanges[Phase] or function(a,b,c) return Phase+1 end)(p1,p2,self)
			Clicks[#Clicks+1] = p2
			PreventDouble = false
		else
			PreventDouble = true
		end
	end
	return ret
end

function NClickSkill:GetFinalEffect(p1, p2, p3)
	local ret = SkillEffect()
	LOG("Error Occurred. Shouldn't have been able to get here.")
	return ret
end

local function EVENT_onModsLoaded()

	modapiext:addPawnSelectedHook(function(_, pawn)
			Clicks = {}
			Phase = 1
	end)

end

weaponArmed.events.onWeaponArmed:subscribe(function(skill, pawnId)
	local pawn = Game:GetPawn(pawnId)
	if _G[skill.__Id].NClick then
		Clicks = {}
		Phase = 1
	end
end)


modApi.events.onModsLoaded:subscribe(EVENT_onModsLoaded)

local ConfirmWeapon = function(scancode)
	if (scancode == 13) and Board then
		local Pawn = nil
		local Weapon = false
			for i = 0, 2 do
				if Board:GetPawn(i) then
					if Board:GetPawn(i):GetArmedWeapon() then
						Pawn = Board:GetPawn(i)
						Weapon = Pawn:GetArmedWeapon()
						break
					end
				end
			end
		if Weapon then
		if _G[Weapon].Confirmation then
			if (_G[Weapon].ConfirmationFuncs)[Phase] then
				 _G[Weapon].ConfirmationFuncs[Phase]()
				Pawn:FireWeapon(Point(11,11),Pawn:GetArmedWeaponId())
			else
				Pawn:FireWeapon(Point(10,10),Pawn:GetArmedWeaponId())
			end
		end
		end
	end
end
if not DoesEventExist then
	modApi.events.onKeyPressed:subscribe(ConfirmWeapon)
	DoesEventExist = true
end







--How to use
--To make an N-Click weapon, make a weapon in the form of Weapon_ID=NClickSkill
--DO NOT ADD ANY TARGET AREAS OR SKILLEFFECTS.
--Make a list of each target area for each phase, as a function, each taking the arguments ret, p1, self
--And a list of each skill effect for each phase, as a function, each taking the arguments ret, p1, p2, self
--Version 2 adds phasechanges. THESE ARE OPTIONAL. They're for if you want dynamic targeting flowchart stuff. The corresponding PhaseChange function is called after each phase and tells it what phase to go to next. If instead of a function, it's nil, [Or if PhaseChanges is left undefined], it will just increase phase by one. ANY PHASE ABOVE THE WEAPON'S self.Phases is going to immediately fire the weapon on that click.
--When making these, keep in mind:
--p2 will always refer to the tile being moused over, or the final tile clicked during the final skilleffect
--Clicks has all previous tiles. So Clicks[1] will refer to the first tile clicked, Clicks[2] the second tile clicked, etc
--Contact @TheBoardsCousin in the ITB discord if you would like help using this library or would like an example weapon