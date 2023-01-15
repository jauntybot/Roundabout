
local snd = playdate.sound

SoundManager = {}

SoundManager.kSoundDodgeRoll = 'orgRoll'
SoundManager.kSoundIneffectiveHit = 'orgRegHit'
SoundManager.kSoundCriticalHit = 'orgSupHit'
SoundManager.kSoundGuardHold = 'orgHeldGuard'
SoundManager.kSoundPerfectGuard = 'orgPerfGuard'
SoundManager.kSoundHeroDmg = 'orgDmg'
SoundManager.kSoundHeroSwipe = 'orgSwipe'

local sounds = {}

for _, v in pairs(SoundManager) do
	sounds[v] = snd.sampleplayer.new('Audio/sfx/' .. v)
end

SoundManager.sounds = sounds

function SoundManager:playSound(name)
	self.sounds[name]:play(1)		
end


function SoundManager:stopSound(name)
	self.sounds[name]:stop()
end


function SoundManager:playBackgroundMusic()
	local filePlayer = snd.fileplayer.new('sfx/main_theme')
	filePlayer:play(0) -- repeat forever
end