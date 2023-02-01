
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

SoundManager.bgSong = nil

function SoundManager:playSong(song, vol)
	if SoundManager.bgSong ~= nil then SoundManager.bgSong:stop() end
	SoundManager.bgSong = snd.fileplayer.new(song)
	SoundManager.bgSong:setVolume(vol)
	SoundManager.bgSong:play(0)
end