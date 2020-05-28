//-----------------------------------------------------------------------------------------------
//
//shared file for information revolving the ghoul entity
//
//@author Deven Ronquillo
//@version 21/4/18
//-----------------------------------------------------------------------------------------------
ENT.Base = "base_nextbot"

ENT.Spawnable = true
ENT.AdminSpawnable = true

ENT.Author = "Luna <3"

ENT.Category = "Moon Bots"
ENT.PrintName = "Feral Ghoul"
ENT.Instructions = "Don't get to close .-."

function ENT:SetupDataTables()

    self:NetworkVar("Float",0,"HairColor")
    self:NetworkVar("Float",1,"BodyColorR")
    self:NetworkVar("Float",2,"BodyColorG")
    self:NetworkVar("Float",3,"BodyColorB")
end