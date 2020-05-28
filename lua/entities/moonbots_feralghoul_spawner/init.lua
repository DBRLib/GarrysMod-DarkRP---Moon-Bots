//-----------------------------------------------------------------------------------------------
//
//Server side script for ghoul entity
//
//@author Deven Ronquillo
//@version 22/5/18
//-----------------------------------------------------------------------------------------------
AddCSLuaFile("shared.lua")
AddCSLuaFile( "cl_init.lua" )

include('shared.lua')

SPAWNERMODEL = "models/Gibs/HGIBS.mdl"
NPCMODEL = "moonbots_feralghoul"

MAXENTITYCOUNT = CreateConVar( "sv_feralghoullimit", 20, 128, "Sets the total number of ghouls allowed to spawn." )
MAXGLOWINGENTITYCOUNT = CreateConVar( "sv_glowingonelimit", 3, 128, "Sets the total number of glowing ones allowed to spawn." )
SPAWNTIME = CreateConVar( "sv_feralghoulspawnertime", 300, 128, "Sets the time diffrence between each spawn check." )



function ENT:Initialize()

	self:SetModel( SPAWNERMODEL )

	self:PhysicsInit( SOLID_VPHYSICS )     
	self:SetMoveType( MOVETYPE_NONE )   
	self:SetSolid( SOLID_VPHYSICS )

	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)        

    local phys = self:GetPhysicsObject()

	if (phys:IsValid()) then

		phys:Wake()
	end
end

function ENT:Think()


	local _ents = ents.FindByClass("moonbots_feralghoul")

	if( table.Count(_ents) < GetConVar("sv_feralghoullimit"):GetInt() ) then //spawn the goods


		local entity = ents.Create("moonbots_feralghoul")

		entity:SetPos( self:GetPos() )
		entity:Spawn()
	end

	local _ents = ents.FindByClass("moonbots_glowingone")

	if( table.Count(_ents) < GetConVar("sv_glowingonelimit"):GetInt() ) then //spawn the goods


		local entity = ents.Create("moonbots_glowingone")

		entity:SetPos( self:GetPos() )
		entity:Spawn()
	end

	self:NextThink(CurTime() + GetConVar("sv_feralghoulspawnertime"):GetInt() )
	return true
end












