
local snd = playdate.sound

SoundManager = {}

SoundManager.kSoundFlutter = 'flutter'
SoundManager.kSoundIneffectiveHit = 'hitEnemyReg'
SoundManager.kSoundCriticalHit = 'hitEnemy'
SoundManager.kSoundGuardHold = 'orgHeldGuard'
SoundManager.kSoundPerfectGuard = 'orgPerfGuard'
SoundManager.kSoundHeroDmg = 'dmgCrunch'
SoundManager.kSoundHeroSwipe = 'orgSwipe'
SoundManager.kSoundChargeWait = 'chargeWait'
SoundManager.kSoundChargePeak = 'chargePeak'
SoundManager.kSoundFadeAttack = 'enemyAxeSwipe'


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
	local filePlayer = snd.fileplayer.new('Audio/sfx/rippleStar')
	filePlayer:play(0) -- repeat forever
end