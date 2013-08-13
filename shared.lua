local config = ttt_perky_config

ENT.Type 	 = "anim"
ENT.Model 	 = Model( "models/props/cs_office/radio.mdl" )
ENT.LifeTime = config.radiojammer_duration
ENT.destructTime = 0
ENT.SoundInterval = config.radiojammer_sound_interval
ENT.NextSound = 0
ENT.DetectiveNearRadius = 400
ENT.Health = config.radiojammer_health

local jamSound = Sound( "npc/scanner/cbot_servochatter.wav" )
-- load sounds
local randomSounds = {}
for i = 1, 15 do
	randomSounds[i] = Sound( "ambient/levels/prison/radio_random"..i..".wav" )
end

if SERVER then 
	AddCSLuaFile("shared.lua") 
end

if CLIENT then
   -- this entity can be DNA-sampled so we need some display info
   ENT.Icon = "VGUI/ttt/icon_radiojammer"
   ENT.PrintName = "Radio Jammer"
end

function ENT:Initialize()
	self.Entity:SetModel( self.Model )
	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetSolid(SOLID_VPHYSICS)
	self.Entity:SetCollisionGroup(COLLISION_GROUP_NONE)
	self.Entity:SetHealth( self.health )
	if SERVER then
	    self.Entity:SetMaxHealth( self.health )
		self.Entity:SetUseType(SIMPLE_USE)
		self.destructTime = CurTime() + self.LifeTime
	elseif CLIENT then
	   if LocalPlayer() == self:GetOwner() then
	      LocalPlayer().radiojammer = self.Entity
	   end
	end
	self.NextSound = CurTime() + self.SoundInterval
	self.jamming = false
	self.fingerprints = {}
end

function ENT:IsDetectiveNear()
   local center = self:GetPos()
   local r = self.DetectiveNearRadius ^ 2
   local d = 0.0
   local diff = nil
   for _, ent in pairs(player.GetAll()) do
      if IsValid(ent) and ent:IsActiveDetective() then
         -- dot of the difference with itself is distance squared
         diff = center - ent:GetPos()
         d = diff:DotProduct(diff)

         if d < r then
               return true
         end
      end
   end

   return false
end

function ENT:Think()
	if SERVER then
		if CurTime() > self.destructTime then
			self:DoExplode()
			self:Remove()
		end
		if CurTime() > self.NextSound then
			self.NextSound = CurTime() + self.SoundInterval
			local amp = 100
			if self:IsDetectiveNear() then
		         amp = 140
			end
			local n = math.random(1,15)
			WorldSound( randomSounds[n], self:GetPos(), amp, 100 )
			--WorldSound( jamSound, self:GetPos(), amp, 100 )
		end
	end
end

local zapsound = Sound("npc/assassin/ball_zap1.wav")
function ENT:OnTakeDamage(dmginfo)
   self:TakePhysicsDamage(dmginfo)
   self:SetHealth(self:Health() - dmginfo:GetDamage())
   if self:Health() < 0 then
		self:DoExplode()
		self:Remove()
   end
end

function ENT:DoExplode()
	local effect = EffectData()
	effect:SetOrigin( self:GetPos() )
	util.Effect("cball_explode", effect)
	WorldSound( zapsound, self:GetPos() )
end

function ENT:OnRemove()
   if CLIENT then
      if LocalPlayer() == self:GetOwner() then
         LocalPlayer().radiojammer = nil
      end
   end
end

if SERVER then
	
	function ENT.PlayerSay( ply, text, team )
		if #ents.FindByClass( 'ttt_radiojammer' ) > 0 then
			if not ply:HasEquipmentItem( EQUIP_RADIOFREQUENCY ) then
				return "[JAMMED]"
			end
		end
	end
	hook.Add( 'PlayerSay', 'ttt_radiojammer_playersay', ENT.PlayerSay )
	
	function ENT.PlayerCanHearVoice( listner, talker )
		if #ents.FindByClass( 'ttt_radiojammer' ) > 0 then
			if talker:IsSpec() then
			    return nil
			elseif talker:IsActiveTraitor() then
				return nil
			elseif talker:HasEquipmentItem( EQUIP_RADIOFREQUENCY ) then
				return nil
			else
				return false, false
			end
		end
	end
	hook.Add( 'PlayerCanHearPlayersVoice', 'ttt_radiojammer_PlayerCanHearPlayersVoice', ENT.PlayerCanHearVoice )

end