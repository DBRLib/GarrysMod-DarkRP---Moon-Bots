//-----------------------------------------------------------------------------------------------
//
//client side script for ghoul entity
//
//@author Deven Ronquillo
//@version 30/12/18
//-----------------------------------------------------------------------------------------------
include('shared.lua')

function ENT:Draw()

	for k, v in pairs(self:GetMaterials()) do

		local materialData = {

			["$basetexture"] = "color/white",
			["$model"] = 1,
			["$subsurfaceprop"] = "flesh",
			["$selfillum"] = 1
		}

		if(k <= 2) then

			local newMat = CreateMaterial("glowingghouleyes","UnlitGeneric", materialData):SetVector("$color2", Vector(0.780, 1.0, 0.350))

			self:SetSubMaterial(k-1, "!glowingghouleyes")
		elseif(k >= 3 && k <= 5 || k == 10) then

			local newMat = CreateMaterial("glowingghoulskin","UnlitGeneric", materialData):SetVector("$color2", Vector(0.322, 0.78, 0.2))

			self:SetSubMaterial(k-1, "!glowingghoulskin")
		elseif(k >= 6 && k <= 9) then

			local newMat = CreateMaterial("glowingghoulhair","UnlitGeneric", materialData):SetVector("$color2", Vector(0.449, 1.0, 0.402))

			self:SetSubMaterial(k-1, "!glowingghoulhair")

		else

			local newMat = CreateMaterial("glowingghouleyelashes","UnlitGeneric", materialData):SetVector("$color2", Vector(0.550, 1.0, 0.500))

			self:SetSubMaterial(k-1, "!glowingghouleyelashes")
		end
	end

	self:DrawModel()
end

hook.Add("PreDrawHalos", "DrawHalo", function()

	halo.Add(ents.FindByClass("moonbots_glowingone"), Color(200, 255, 150), 6, 6, 1, true, false)
end)

