//-----------------------------------------------------------------------------------------------
//
//Server side script for ghoul entity
//
//@author Deven Ronquillo
//@version 11/1/19
//-----------------------------------------------------------------------------------------------
include('shared.lua')

function ENT:Draw()

	for k, v in pairs(self:GetMaterials()) do

		if(k <= 2) then

			local materialData = {

				["$basetexture"] = "color/white",
				["$model"] = 1,
				["$subsurfaceprop"] = "flesh",
				["$selfillum"] = 1
			}

			local newMat = CreateMaterial("ghouleyes","UnlitGeneric", materialData):SetVector("$color2", Vector(1,0.314,0.078))

			self:SetSubMaterial(k-1, "!ghouleyes")
		elseif(k >= 3 && k <= 5 || k == 10) then

			local materialData = {

				["$basetexture"] = "color/white",
				["$model"] = 1,
				["$subsurfaceprop"] = "flesh"
			}

			local newMat = CreateMaterial("ghoulskin","VertexLitGeneric", materialData):SetVector("$color2", Vector(self:GetBodyColorR(),self:GetBodyColorG(),self:GetBodyColorB()))//Vector(0.2,0.2,0.102)

			self:SetSubMaterial(k-1, "!ghoulskin")
		elseif(k >= 6 && k <= 9) then

			local materialData = {

				["$basetexture"] = "color/white",
				["$model"] = 1,
				["$subsurfaceprop"] = "flesh"
			}

			local newMat = CreateMaterial("ghoulhair","VertexLitGeneric", materialData):SetVector("$color2", Vector(self:GetHairColor(),self:GetHairColor(),self:GetHairColor()))//Vector(0.18,0.18,0.122)

			self:SetSubMaterial(k-1, "!ghoulhair")

		else

			local materialData = {

				["$basetexture"] = "color/white",
				["$model"] = 1,
				["$subsurfaceprop"] = "flesh"
			}

			local newMat = CreateMaterial("ghouleyelashes","VertexLitGeneric", materialData):SetVector("$color2", Vector(0,0,0))

			self:SetSubMaterial(k-1, "!ghouleyelashes")
		end
	end

	self:DrawModel()
end
