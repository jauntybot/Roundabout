
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
	sounds[v] = snd.sampleplayer.new('assets/audio/sfx/' .. v)
end

SoundManager.sounds = sounds
SoundManager.coroutines = {}

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

local function fadeOut()
    while SoundManager.bgSong:getVolume() > 0 do
        SoundManager.bgSong:setVolume(SoundManager.bgSong:getVolume() - .05)
        coroutine.yield()
    end
    SoundManager.bgSong:stop()
end

function SoundManager:fadeSongOut()
    if SoundManager.bgSong:isPlaying() then        
        CoCreate(self.coroutines, 'fadeOut', fadeOut)
    end
end

function SoundManager:update()
    for co, f in pairs(self.coroutines) do
        if f ~= nil then CoRun(self.coroutines, co) end
    end
end