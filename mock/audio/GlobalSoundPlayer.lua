module 'mock'

local _globalSoundPlayer
function getGlobalSoundPlayer()
	return _globalSoundPlayer
end


--------------------------------------------------------------------
local function _actionSeekInstanceVolume( instance, volume, duration, delay, actionOnFinish )
	local v0 = instance:getVolume()
	if delay and delay > 0 then
		local elapsed = 0
		while elapsed < delay do
			elapsed = elapsed + coroutine.yield()
		end
	end
	instance:pause( false )
	if duration and duration > 0 then
		local elapsed = 0
		while true do
			elapsed = elapsed + coroutine.yield()
			local k = math.min( elapsed / duration, 1 )
			if not instance:isValid() then return end
			instance:setVolume( lerp( v0, volume, k ) )
			if k >= 1 then break end
		end
	else
		instance:setVolume( volume )
	end
	if actionOnFinish == 'stop' then
		instance:stop()
	elseif actionOnFinish == 'pause' then
		instance:pause()
	end
end

--------------------------------------------------------------------
CLASS: GlobalSoundPlayerSession ( Actor )
	:MODEL{}

function GlobalSoundPlayerSession:__init( name )
	self.name = name
	self.currentEvent = false
	self.soundInstance = false
	self.eventQueue = {}
	self.fadingInstance = false
	self.volume = 1

	self.mainCoro = false
end

function GlobalSoundPlayerSession:isPlaying()
	local instance = self.soundInstance
	if not instance then return false end
	return AudioManager.get():isEventInstancePlaying( instance )
end

-- function GlobalSoundPlayerSession:stopSession()
-- end

function GlobalSoundPlayerSession:stop( fadeDuration )
	self:stopMainCoroutine()
	local instance = self.soundInstance
	if not instance then return false end
	if fadeDuration and fadeDuration > 0 then
		self:addCoroutine( _actionSeekInstanceVolume, instance, 0, fadeDuration, false, 'stop' )
	else
		instance:stop()
	end
	self.soundInstance = false
end

function GlobalSoundPlayerSession:changeEvent( eventPath, fadeDuration, delay )
	if self.currentEvent == eventPath then return end
	return self:playEvent( eventPath, fadeDuration, delay )
end

function GlobalSoundPlayerSession:stopMainCoroutine()
	if self.mainCoro then
		self.mainCoro:stop()
		self.mainCoro = false
	end
end

function GlobalSoundPlayerSession:addMainCoroutine( func, ... )
	self:stopMainCoroutine()
	local coro = self:addCoroutine( func, ... )
	self.mainCoro = coro
	return coro
end

function GlobalSoundPlayerSession:playEvent( eventPath, fadeDuration, delay )
	self:stop( fadeDuration )
	local instance = AudioManager.get():playEvent2D( eventPath, looped )
	self.currentEvent = eventPath
	self.soundInstance = instance
	if instance then
		if fadeDuration and fadeDuration > 0 then
			instance:setVolume( 0 )
			instance:pause()
			local coro = self:addMainCoroutine( _actionSeekInstanceVolume, instance, self.volume, delay, fadeDuration )
			self.mainCoro = coro
			return coro
		else
			instance:setVolume( self.volume )
		end
	end
end

function GlobalSoundPlayerSession:seekVolume( vol, duration, delay, actionOnFinish )
	local v0 = self.volume
	local instance = self.soundInstance
	if not instance then return nil end
	local coro = self:addMainCoroutine( _actionSeekInstanceVolume, instance, vol, duration, delay, actionOnFinish )
	self.volume = vol
	return coro
end

function GlobalSoundPlayerSession:setVolume( vol )	
	self.volume = vol or 1
	if self.soundInstance then
		self.soundInstance:setVolume( self.volume )
	end
end

function GlobalSoundPlayerSession:getVolume( vol )
	return self.volume
end

function GlobalSoundPlayerSession:pause( fadeDuration )
	self:stopMainCoroutine()
	print( 'pause', self.name, fadeDuration )
	if self.soundInstance then
		if fadeDuration and fadeDuration > 0 then
			local coro = self:addMainCoroutine( _actionSeekInstanceVolume, self.soundInstance, 0, fadeDuration, false , 'pause')
			return coro
		else
			self.soundInstance:pause()
		end
	end
end

function GlobalSoundPlayerSession:resume( fadeDuration, delay )
	self:stopMainCoroutine()
	print( 'resume', self.name, fadeDuration )
	if self.soundInstance then
		if fadeDuration and fadeDuration > 0 then
			self.soundInstance:setVolume( 0 )
			self:seekVolume( self.volume, fadeDuration, delay )
		else
			self.soundInstance:pause( false )
			self.soundInstance:setVolume( self.volume )
		end
	end
end

function GlobalSoundPlayerSession:getEventInstance()
	return self.soundInstance
end


--------------------------------------------------------------------
CLASS: GlobalSoundPlayer ( GlobalManager )
	:MODEL{}

function GlobalSoundPlayer:__init()
	self.sessions = {}
end

function GlobalSoundPlayer:getKey()
	return 'GlobalSoundPlayer'
end

function GlobalSoundPlayer:affirmSession( name )
	local session = self.sessions[ name ]
	if session then return session end
	return self:addSession( name )
end

function GlobalSoundPlayer:stopSession( name )
	local session = self:getSession( name )
	if session then session:stop() end
end

function GlobalSoundPlayer:stopAllSessions()
	for name, session in pairs( self.sessions ) do
		session:stop()
	end
end

function GlobalSoundPlayer:clearSessions()
	self:stopAllSessions()
	self.sessions = {}
end

function GlobalSoundPlayer:addSession( name )
	local session = GlobalSoundPlayerSession( name )
	if not self.sessions[ name ] then
		self.sessions[ name ] = session
		return session
	else
		_warn( 'duplicated global sound session', name )
		return false
	end
end

function GlobalSoundPlayer:getSession( name )
	return self.sessions[ name ]
end


_globalSoundPlayer = GlobalSoundPlayer()