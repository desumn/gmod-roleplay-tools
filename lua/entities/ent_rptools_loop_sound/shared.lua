---@class RPToolsLoopSoundEntity : Entity
---@field play_sound { sound : string, iterations : integer, level : number, pitch : number, volume : number }
---@field soundPatch CSoundPatch
---@field soundDuration number

AddCSLuaFile()

RPTools = RPTools or {}
ENT.Type = "anim"
ENT.Base = "base_anim"

---@param self RPToolsLoopSoundEntity
function ENT:Initialize()
  if SERVER then
    self:SetModel("models/hunter/plates/plate.mdl")
    self:SetNoDraw(true)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_NONE)

    if not self.play_sound then
      return
    end

    self.soundPatch = CreateSound(self, self.play_sound.sound)
    if not self.soundPatch then
      return
    end

    self.soundPatch:SetSoundLevel(self.play_sound.level)
    self.soundPatch:ChangePitch(self.play_sound.pitch)
    self.soundPatch:ChangeVolume(self.play_sound.volume)

    self.soundDuration = SoundDuration(self.play_sound.sound)
    self.soundPatch:Play()

    if self.soundDuration ~= 0 then
      timer.Create("node_" .. self:EntIndex() .. "_sound_loop", self.soundDuration, 0, function()
        self.soundPatch:Play()
      end)

      local iterations = self.play_sound.iterations or 0
      if iterations > 0 then
        timer.Simple(iterations * self.soundDuration, function()
          self:Remove()
        end)
      end
    end
  end
end

---@param self RPToolsLoopSoundEntity
function ENT:OnRemove()
  timer.Remove("node_" .. self:EntIndex() .. "_sound_loop")
  if self.soundPatch then
    self.soundPatch:Stop()
    self.soundPatch = nil
  end
end
