local mod = modApi:getCurrentMod()
local LocalVersion = 1.0
if not NClickVersions then
	NClickVersions = {}
end


if not NClickVersions[LocalVersion] then

NClickVersions[LocalVersion] = true
local path = mod.scriptPath
local weaponArmed = require(path .."libs/weaponArmed")
Clicks = {}

PhaseClicks = {{}}
FiredUsingComfirm = false
Phase = 1
PreventDouble = true
NClickSkill = Skill:new{
	TwoClick = true,
	NClickVersion = LocalVersion,
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
			PhaseClicks = {{}}
			Phase = 1
	end)

end

weaponArmed.events.onWeaponArmed:subscribe(function(skill, pawnId)
	local pawn = Game:GetPawn(pawnId)
	if _G[skill.__Id].NClick then
		Clicks = {}
		PhaseClicks = {{}}
		Phase = 1
	end
end)


modApi.events.onModsLoaded:subscribe(EVENT_onModsLoaded)

local ConfirmWeapon = function(scancode)

	if (scancode == 13) and Board then
		local Pawn = nil
		local Weapon = false
		local AllPawns = extract_table(Board:GetPawns(TEAM_ANY))
			for i = 1, #AllPawns do
				local curr = AllPawns[i]
				if Board:GetPawn(curr) then
					if Board:GetPawn(curr):GetArmedWeapon() then
						Pawn = Board:GetPawn(curr)
						Weapon = Pawn:GetArmedWeapon()
						break
					end
				end
			end

		if Weapon then
			if _G[Weapon].NClickVersion == LocalVersion then
				if _G[Weapon].Confirmation then
					if (_G[Weapon].ConfirmationFuncs)[Phase] then
						if not(_G[Weapon].ConfirmationFuncs[Phase](Pawn:GetSpace(),_G[Weapon]) == nil) then
							Pawn:FireWeapon(Point(10,10),Pawn:GetArmedWeaponId())
						else
							Pawn:FireWeapon(Point(11,11),Pawn:GetArmedWeaponId())
						end
					else
						Pawn:FireWeapon(Point(10,10),Pawn:GetArmedWeaponId())
					end
				end
			end
		end
	end
end
modApi.events.onKeyPressed:subscribe(ConfirmWeapon)
end
