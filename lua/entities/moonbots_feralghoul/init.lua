//-----------------------------------------------------------------------------------------------
//
//Server side script for ghoul entity
//
//@author Deven Ronquillo
//@version 11/1/19
//-----------------------------------------------------------------------------------------------
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include('shared.lua')

DEBUG = 0

ACTIVEENTS = 0
ACTIVELEADERENTS = 0

ALERTSOUNDMAP = {

	"npc/zombie_poison/pz_alert1.wav",
	"npc/zombie_poison/pz_alert2.wav",
	"npc/zombie/zombie_pain6.wav",
	"npc/fast_zombie/leap1.wav",
	"npc/zombie_poison/pz_call1.wav"
}

HITSOUNDMAP = {
	
	"npc/barnacle/barnacle_crunch2.wav",
	"npc/barnacle/barnacle_crunch3.wav"
}

STEPSOUNDMAP = {

	"npc/fast_zombie/foot1.wav",
	"npc/fast_zombie/foot2.wav",
	"npc/fast_zombie/foot3.wav",
	"npc/fast_zombie/foot4.wav",
	"npc/zombie_poison/pz_left_foot1.wav"
}

IDLESOUNDMAP = {

	"npc/antlion/idle1.wav",
	"npc/headcrab/idle2.wav",
	"npc/barnacle/barnacle_pull1.wav",
	"npc/barnacle/barnacle_pull3.wav",
	"npc/barnacle/barnacle_pull4.wav",
	"npc/headcrab_poison/ph_talk1.wav",
	"npc/headcrab_poison/ph_talk2.wav",
	"npc/headcrab_poison/ph_talk3.wav"
}

DEATHSOUNDMAP = {

	"npc/zombie_poison/pz_die2.wav",
	"npc/zombie_poison/pz_pain1.wav",
	"npc/zombie_poison/pz_pain2.wav",
	"npc/zombie/zombie_die2.wav",
	"npc/zombie/zombie_pain3.wav"
}


ENT.model = "models/ppm/player_default_base.mdl"
ENT.class = "moonbots_feralghoul"

ENT.isLeader = false
ENT.leader = nil
ENT.enemy = nil
ENT.lastDistToEnemy = 0
ENT.ensureDiffrentEnemy = nil

LOSETARGETDIST = CreateConVar( "sv_feralghoulchasedistance", 1500, 128, "Sets the maximum distance the ghoul can chase its target at." )
SEARCHRADIUS = CreateConVar( "sv_feralghoulsearch", 1000, 128, "Sets the maximum radius the ghoul will use to find a target." )

LOSELEADERDIST = CreateConVar( "sv_feralghoulleaderdistance", 500, 128, "Sets the maximum distance a ghoul may be from its pack leader." )
SEARCHLEADERDIST = CreateConVar( "sv_feralghoulleadersearch", 1500, 128, "Sets the maximum distance the ghoul will use to find a leader." )






----------------------------------------------------
-- ENT:Initialize()
-- instantiates the base entity
----------------------------------------------------
function ENT:Initialize()

	self:SetModel( self.model )

	self:SetHealth( math.Rand(75,200) )

	self:SetHairColor(math.Rand(25, 200)/255)
	self:SetBodyColorR(math.Rand(50, 150)/255)
	self:SetBodyColorG(math.Rand(50, 150)/255)
	self:SetBodyColorB(math.Rand(0, 50)/255)

	raceRoll = math.random(0, 2)

	if(raceRoll == 0) then

		self:SetBodygroup(2, 1)
		self:SetBodygroup(3, 0)
	elseif(raceRoll == 1) then

		self:SetBodygroup(2, 0)
		self:SetBodygroup(3, 1)
	else

		self:SetBodygroup(2, 1)
		self:SetBodygroup(3, 1)
	end

	local hairPreset = math.random(0, 11)

	self:SetBodygroup(4, hairPreset)
	self:SetBodygroup(5, hairPreset)
	self:SetBodygroup(6, hairPreset)

	self:SetBodygroup(8, math.random(0, 4))


	ACTIVEENTS = ACTIVEENTS + 1

	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)

	timer.Simple( 3, function()

		self:SetCollisionGroup(COLLISION_GROUP_NONE)
	end )
end










----------------------------------------------------
-- ENT:Get/SetEnemy()
-- Simple functions used in keeping our enemy saved
----------------------------------------------------
function ENT:SetEnemy( ent )
	self.enemy = ent
end
function ENT:GetEnemy()
	return self.enemy
end

----------------------------------------------------
-- ENT:HaveEnemy()
-- Returns true if we have a enemy
----------------------------------------------------
function ENT:HaveEnemy()
	-- If our current enemy is valid
	if ( self:GetEnemy() and IsValid( self:GetEnemy() ) ) then

		if(self:GetRangeTo( self:GetEnemy():GetPos() )  == self.lastDistToEnemy) then

			self.ensureDiffrentEnemy = self:GetEnemy()

			timer.Simple( 1, function() self.ensureDiffrentEnemy = nil end )
			
			return self:FindEnemy()

		-- If the enemy is too far
		elseif ( self:GetRangeTo( self:GetEnemy():GetPos() ) > GetConVar("sv_feralghoulchasedistance"):GetInt() ) then

			-- If the enemy is lost then call FindEnemy() to look for a new one
			-- FindEnemy() will return true if an enemy is found, making this function return true
			return self:FindEnemy()

		-- If the enemy is dead( we have to check if its a player before we use Alive() )
		elseif ( self:GetEnemy():IsPlayer() and !self:GetEnemy():Alive() ) then

			return self:FindEnemy()		-- Return false if the search finds nothing
		end
		-- The enemy is neither too far nor too dead so we can return true
		self.lastDistToEnemy = self:GetRangeTo( self:GetEnemy():GetPos() )
		return true
	else
		-- The enemy isn't valid so lets look for a new one
		return self:FindEnemy()
	end
end

----------------------------------------------------
-- ENT:FindEnemy()
-- Returns true and sets our enemy if we find one
----------------------------------------------------
function ENT:FindEnemy()

	if(!self.isLeader && IsValid(self:GetLeader()) && IsValid(self.leader:GetEnemy()) && self.leader:GetEnemy():Alive()) then

		self:SetEnemy( self.leader:GetEnemy() )
		return true
	end

	-- This can be done any way you want eg. ents.FindInCone() to replicate eyesight
	if( self.isLeader || (!self.isLeader && IsValid(self:GetLeader()) && !IsValid(self.leader:GetEnemy()) ) || (!IsValid(self:GetLeader()) && !self.isLeader) ) then

		local _ents = ents.FindInSphere( self:GetPos(), GetConVar("sv_feralghoulsearch"):GetInt() )

		-- Here we loop through every entity the above search finds and see if it's the one we want
		for k, v in pairs( _ents ) do

			if ( v:IsPlayer() && v:Alive() && ( self.ensureDiffrentEnemy == nil ||  v != self.ensureDiffrentEnemy ) ) then

				-- We found one so lets set it as our enemy and return true
				self.ensureDiffrentEnemy = nil
				self:SetEnemy( v )
				return true
			end
		end
	end

	-- We found nothing so we will set our enemy as nil ( nothing ) and return false
	self:SetEnemy( nil )
	return false
end

----------------------------------------------------
-- ENT:ChaseEnemy()
-- Works similarly to Garry's MoveToPos function
-- except it will constantly follow the
-- position of the enemy until there no longer
-- is one.
----------------------------------------------------
function ENT:ChaseEnemy( options )

	local options = options or {}

	local path = Path( "Follow" )

	path:SetMinLookAheadDistance( options.lookahead or 300 )
	path:SetGoalTolerance( options.tolerance or 20 )
	path:Compute( self, self:GetEnemy():GetPos() )		-- Compute the path towards the enemies position

	if ( !path:IsValid() ) then return "failed" end

	while ( path:IsValid() and self:HaveEnemy() ) do

		if ( path:GetAge() > 0.1 ) then					-- Since we are following the player we have to constantly remake the path
			path:Compute( self, self:GetEnemy():GetPos() )-- Compute the path towards the enemy's position again
		end

		path:Update( self )								-- This function moves the bot along the path

		if ( options.draw ) then path:Draw() end

		-- If we're stuck, then call the HandleStuck function and abandon
		if ( self.loco:IsStuck() ) then
			self:HandleStuck()
			return "stuck"
		end

		coroutine.yield()
	end

	return "ok"
end












----------------------------------------------------
-- ENT:Get/SetLeader()
-- Simple functions used in keeping our leader saved
----------------------------------------------------
function ENT:SetLeader( ent )
	self.leader = ent
end
function ENT:GetLeader()
	return self.leader
end
----------------------------------------------------
-- ENT:HaveLeader()
-- Returns true if we have a leader
----------------------------------------------------
function ENT:HaveLeader()
	-- If our current enemy is valid
	if ( self:GetLeader() and IsValid( self:GetLeader() ) ) then
		-- If the enemy is too far
		if ( self:GetRangeTo( self:GetLeader():GetPos() ) > GetConVar("sv_feralghoulchasedistance"):GetInt() ) then
			-- If the enemy is lost then call FindEnemy() to look for a new one
			-- FindEnemy() will return true if an enemy is found, making this function return true
			return self:FindLeader()
		-- If the enemy is dead( we have to check if its a player before we use Alive() )
		end
		-- our leader is alive and in range
		return true
	else
		-- The enemy isn't valid so lets look for a new one
		return self:FindLeader()
	end
end

----------------------------------------------------
-- ENT:FindLeader()
-- Returns true and sets our leader if we find one, else makes us leader
----------------------------------------------------
function ENT:FindLeader()
	-- Search around us for entities
	-- This can be done any way you want eg. ents.FindInCone() to replicate eyesight
	local _ents = ents.FindInSphere(self:GetPos(), GetConVar("sv_feralghoulleadersearch"):GetInt() )
	-- Here we loop through every entity the above search finds and see if it's the one we want
	for k, v in pairs( _ents ) do

		if ( v:GetClass() == self.class && v.isLeader == true ) then

			local vLocalEnts = ents.FindInSphere(v:GetPos(), GetConVar("sv_feralghoulleaderdistance"):GetInt() )
			local vLocalEntsCount = 0

			for key, value in pairs( vLocalEnts ) do

				if(value:GetClass() == self.class) then

					vLocalEntsCount = vLocalEntsCount + 1
				end
			end

			if( vLocalEntsCount <= 3 ) then
				-- We found one so lets set it as our leader and return true
				self:SetLeader( v )
				return true
			end
		end
	end
	-- We found nothing so we will set our leader as nil ( nothing ) and return false

	if( ACTIVELEADERENTS < (1/3)*ACTIVEENTS) then


		self:SetLeader( self )
		self.isLeader = true
		ACTIVELEADERENTS = ACTIVELEADERENTS + 1

		return true
	else

		self:SetLeader( nil )
		return false
	end
end

----------------------------------------------------
-- ENT:ChaseEnemy()
-- Works similarly to Garry's MoveToPos function
-- except it will constantly follow the
-- position of the enemy until there no longer
-- is one.
----------------------------------------------------
function ENT:FollowLeader( options )

	local options = options or {}

	local path = Path( "Follow" )
	path:SetMinLookAheadDistance( options.lookahead or 300 )
	path:SetGoalTolerance( options.tolerance or 300 )
	path:Compute( self, self:GetLeader():GetPos() )		-- Compute the path towards the enemies position

	if ( !path:IsValid() ) then return "failed" end

	while ( path:IsValid() and self:HaveLeader() ) do

		if ( path:GetAge() > 0.1 ) then					-- Since we are following the player we have to constantly remake the path
			path:Compute( self, self:GetLeader():GetPos() )-- Compute the path towards the enemy's position again
		end
		path:Update( self )								-- This function moves the bot along the path

		if ( options.draw ) then path:Draw() end
		-- If we're stuck, then call the HandleStuck function and abandon
		if ( self.loco:IsStuck() ) then

			self:HandleStuck()
			return "stuck"
		end

		coroutine.yield()

	end

	return "ok"
end



----------------------------------------------------
-- ENT:HandleStuck()
-- tries to unstick the bot
----------------------------------------------------

function ENT:HandleStuck()

	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)

	timer.Simple( 3, function()

		if !IsValid(self) then return end
		
		self.loco:ClearStuck()
	end )
end


----------------------------------------------------
-- ENT:OnUnStuck()
-- returns the bot to a normal collision group when un stuck
----------------------------------------------------
function ENT:OnUnStuck()

	self:SetCollisionGroup(COLLISION_GROUP_NONE)
end


----------------------------------------------------
-- ENT:RunBehaviour()
-- This is where the meat of our AI is
----------------------------------------------------
function ENT:RunBehaviour()
	-- This function is called when the entity is first spawned. It acts as a giant loop that will run as long as the NPC exists
	while ( true ) do
		-- begins loop

		if( self:HaveEnemy() ) then

			if( math.Rand(1, 100) >= 70 ) then

				self:EmitSound(Sound(table.Random(ALERTSOUNDMAP)))
			end

			self.loco:FaceTowards( self:GetEnemy():GetPos() )	-- Face our enemy
			
			self:StartActivity( ACT_RUN )			-- Set the animation
			self.loco:SetDesiredSpeed( 450 )		-- Set the speed that we will be moving at. Don't worry, the animation will speed up/slow down to match
			self.loco:SetAcceleration( 600 )			-- We are going to run at the enemy quickly, so we want to accelerate really fast

			self:ChaseEnemy() 						-- The new function like MoveToPos.

			self.loco:SetAcceleration( 400 )			-- Set this back to its default since we are done chasing the enemy
			self:StartActivity( ACT_IDLE )			--We are done so go back to idle
		elseif ( self:HaveLeader() && !self.isLeader && self:GetLeader():GetPos():Distance(self:GetPos()) >= GetConVar("sv_feralghoulleaderdistance"):GetInt() ) then

			-- Now that we have an enemy, the code in this block will run
			self.loco:FaceTowards( self:GetLeader():GetPos() )	-- Face our enemy

			
			self:StartActivity( ACT_WALK )			-- Set the animation
			self.loco:SetDesiredSpeed( 200 )		-- Set the speed that we will be moving at. Don't worry, the animation will speed up/slow down to match

			self:FollowLeader() 						-- The new function like MoveToPos.

			self:StartActivity( ACT_IDLE )			--We are done so go back to idle
			-- Now once the above function is finished doing what it needs to do, the code will loop back to the start
			-- unless you put stuff after the if statement. Then that will be run before it loops
		else
			-- Since we can't find an enemy, lets wander
			-- Its the same code used in Garry's test bot
			self:StartActivity( ACT_WALK )			-- Walk anmimation
			self.loco:SetDesiredSpeed( 150 )		-- Walk speed
			
			self:MoveToPos( self:GetPos() + Vector( math.Rand( -1, 1 ), math.Rand( -1, 1 ), 0 ) * 150 ) -- Walk to a random place within about 250 units ( yielding )	

			if( math.Rand(1, 100) >= 75 ) then

				self:EmitSound(Sound(table.Random(IDLESOUNDMAP)))
			end

			self:StartActivity( ACT_IDLE )
		end
		-- At this point in the code the bot has stopped chasing the player or finished walking to a random spot
		-- Using this next function we are going to wait 2 seconds until we go ahead and repeat it

		if(DEBUG == 1) then

			self:PrintDebug()
		end

		coroutine.wait( math.floor(math.Rand(0,2)) )
	end
end








----------------------------------------------------
-- ENT:OnContact()
-- called when the bot touches another entity
----------------------------------------------------
function ENT:OnContact( ent )
	
	if ent:IsPlayer() || ent:IsNPC() then

		local dinfo = DamageInfo()
			
		dinfo:SetDamage( math.Rand(5,15) )
		dinfo:SetAttacker( self )
		dinfo:SetDamageType( DMG_SLASH )
		ent:TakeDamageInfo( dinfo )

		self:EmitSound(Sound(table.Random(HITSOUNDMAP)))
	end
end

----------------------------------------------------
-- ENT:OnInjured()
-- called when we are attacked
----------------------------------------------------
function ENT:OnInjured(dinfo)

	if(!IsValid(self.enemy)) then

		self.enemy = dinfo:GetAttacker()
	end	
end

----------------------------------------------------
-- ENT:OnKilled()
-- called when our bots health falls bellow 0
----------------------------------------------------
function ENT:OnKilled(dinfo)

	hook.Call( "OnNPCKilled", GAMEMODE, self, dinfo:GetAttacker(), dinfo:GetInflictor() )

	self:EmitSound(Sound(table.Random(DEATHSOUNDMAP)))

	self:Remove()

	local body = ents.Create( "prop_ragdoll" )

	if !IsValid(body) then return end

	body:SetPos( self:GetPos() )
	body:SetModel( self:GetModel() )
	body:Spawn()

	timer.Simple( 5, function()

		if !IsValid(body) then return end
		body:Remove()
	end )


end

----------------------------------------------------
-- ENT:OnRemove()
-- called when our entity is set to be removed
----------------------------------------------------
function ENT:OnRemove()
	
	ACTIVEENTS = ACTIVEENTS - 1

	if(self.isLeader) then

		ACTIVELEADERENTS = ACTIVELEADERENTS -1
	end
end










function ENT:PrintDebug()

	print("----------"..tostring(self).."----------")
	print("Is a leader: "..tostring(self.isLeader))
	print("Is following: "..tostring(self.leader))
	print("Targeted player: "..tostring(self.enemy))
	print("\n")
	print("Total entities: "..ACTIVEENTS)
	print("Active leaders: "..ACTIVELEADERENTS)
	print("\n")
	print("Hair Color: "..self:GetHairColor())
	print("Body Color: "..self:GetBodyColorR()..", "..self:GetBodyColorG()..", "..self:GetBodyColorB())
end