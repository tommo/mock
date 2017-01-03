module 'mock'
if not MOAIFMODStudioMgr then return end

--------------------------------------------------------------------
injectMoaiClass( MOAIFMODStudioEventInstance, {
	isValid = function( self )
		return self:getPlaybackState() ~= MOAIFMODStudioEventInstance.PLAYBACK_STOPPED
	end
} )

--------------------------------------------------------------------

local function createFMODStudioSystem()
	if not MOAIFMODStudioMgr then return end
	_stat('init FMODStudio')
	
	local option = {
		['MaxChannelCount']            = nil;
		['SoundMemoryMB']              = nil;
		['RsxMemoryMB']                = nil;
		['VoiceLRUMaxMB']              = nil;
		['VoiceLRUBufferMB']           = nil;
		['RealChannelCount']           = nil;
		['PCMCodecCount']              = nil;
		['ADPCMCodecCount']            = nil;
		['CompressedCodecCount']       = nil;
		['MaxInputChannelCount']       = nil;
		['DSPBufferSize']              = nil;
		['DSPBufferCount']             = nil;
		['SoundSystemEnabled']         = nil;
		['DistantLowpassEnabled']      = nil;
		['EnvironmentalReverbEnabled'] = nil;
		['Near2DBlendEnabled']         = nil;
		['AuditioningEnabled']         = nil;
		['ProfilingEnabled']           = nil;
		['FsCallbacksEnabled']         = nil;
		['SoundDisabled']              = nil;
		['DopplerScale']               = nil;
	}

	local system = MOAIFMODStudioMgr.createSystem()
	if not system then
		_error('FMODStudio not initialized...')
		return false
	else
		_stat('FMODStudio ready...')
		return system
	end

end


local event2IDCache = table.weak_k()

local function _affirmFmodEvent( event )
	if not event then return nil end
	local id = event2IDCache[ event ]
	if id ~= nil then return id end
	if type( event ) == 'string' then
		event, node = loadAsset( event ) 
		if event then
			id = event:getSystemID()
		else
			return nil
		end
	else
		id = event:getSystemID()
	end
	event2IDCache[ event ] = id or false
	return id
end


--------------------------------------------------------------------
CLASS: FMODStudioAudioManager ( AudioManager )
	:MODEL{}

function FMODStudioAudioManager:__init()
end

function FMODStudioAudioManager:init()
	local system = createFMODStudioSystem()
	if not system then return false end
	self.system = system
	self:clearCaches()
	return true
end

function FMODStudioAudioManager:getSystem()
	return self.system
end


function FMODStudioAudioManager:clearCaches()
	self.cacheBus = {}
	self.cacheSnapshot = {}
	self.cacheEventDescription = {}
end

function FMODStudioAudioManager:getListener( idx )
	return self.system:getListener( idx or 1 )
end

function FMODStudioAudioManager:getEventById( id )
	local ed = self.cacheEventDescription[ id ]
	if ed == nil then
		ed = self.system:getEventByID( id ) or false
		self.cacheEventDescription[ id ] = ed
	end
	return ed
end

function FMODStudioAudioManager:getBus( path )
	if path == 'master' then path = '' end
	local bus = self.cacheBus[ path ]
	if bus == nil then
		local fullpath = 'bus:/' .. path
		local bus = self.system:getBus( fullpath ) or false
		self.cacheBus[ path ] = bus
	end
	return bus
end

function FMODStudioAudioManager:getCategoryVolume( category )
	local bus = self:getBus( category )
	if not bus then return false end
	return bus:getFaderLevel()
end

function FMODStudioAudioManager:setCategoryVolume( category, volume )
	local bus = self:getBus( category )
	if not bus then return false end
	return bus:setFaderLevel( volume or 1 )
end

function FMODStudioAudioManager:seekCategoryVolume( category, v, delta, easeType )
	category = category or 'master'
	delta = delta or 0
	if delta <= 0 then return self:setCategoryVolume( category, v ) end
	local bus = self:getBus( category )
	if not bus then return nil end

	local v0 = bus:getFaderLevel()
	v = clamp( v, 0, 1 )
	easeType = easeType or MOAIEaseType.EASE_OUT
	local tmpNode = MOAIScriptNode.new()
	tmpNode:reserveAttrs( 1 )
	tmpNode:setCallback( function( node )
		local value = node:getAttr( 0 )
		return bus:setFaderLevel( value )
	end )
	tmpNode:setAttr( 0, v0 )
	return tmpNode:seekAttr( 0, v, delta, easeType )
end

function FMODStudioAudioManager:moveCategoryVolume( category, dv, delta, easeType )
	category = category or 'master'
	local v0 = self:getCategoryVolume( category )
	if not v0 then return nil end
	return self:seekCategoryVolume( category, v0 + dv, delta, easeType )
end

function FMODStudioAudioManager:pauseCategory( category, paused )
	local bus = self:getBus( category )
	if bus then bus:setPaused( paused ~= false ) end
end

function FMODStudioAudioManager:muteCategory( category, muted )
	local bus = self:getBus( category )
	if bus then bus:setMute( paused ~= false ) end
end

function FMODStudioAudioManager:isCategoryMuted( category )
	local bus = self:getBus( category )
	if not bus then return nil end
	return bus:isMute()
end

function FMODStudioAudioManager:isCategoryPaused( category )
	local bus = self:getBus( category )
	if not bus then return nil end
	return bus:isPaused()
end

function FMODStudioAudioManager:createEventInstance( eventPath )
	local eventId = _affirmFmodEvent( eventPath )
	if not eventId then
		_warn( 'no audio event found', eventPath )
		return false
	end
	local ed = self:getEventById( eventId )
	if not ed then
		_warn( 'no event found', eventId )
		return false
	end
	local instance = ed:createInstance()
	return instance
end

function FMODStudioAudioManager:playEvent3D( eventPath, x, y, z )
	local instance = self:createEventInstance( eventPath )
	if not instance then return false end
	instance:start()
	return instance
end

function FMODStudioAudioManager:playEvent2D( eventPath, looped )
	local instance = self:createEventInstance( eventPath )
	if not instance then return false end
	instance:start()
	return instance
end

function FMODStudioAudioManager:isSoundPlaying( sound )
	return sound:getPlaybackState() ~= MOAIFMODStudioEventInstance.PLAYBACK_STOPPED
end

--------------------------------------------------------------------
_stat( 'using FMOD Studio audio manager' )
FMODStudioAudioManager()

 