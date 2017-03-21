module 'mock'
if not MOAIFMODStudioMgr then return end

local _mgr = false

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
		['ProfilingEnabled']           = true;
		['ProfilingPort']              = nil;
		['FsCallbacksEnabled']         = nil;
		['SoundDisabled']              = nil;
		['DopplerScale']               = nil;
	}

	if game:isEditorMode() then
		option[ 'ProfilingEnabled' ] = false
	end
	local system = MOAIFMODStudioMgr.createSystem( option )
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
		event, node = tryLoadAsset( event ) 
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
	self.system = false
	self.unitsToMeters = 1
	_mgr = self
end

function FMODStudioAudioManager:init( option )
	local system = createFMODStudioSystem()
	if not system then return false end
	self.system = system
	
	--apply options
	local u2m = option[ 'unitsToMeters' ] or 1
	self.unitsToMeters = u2m
	self.system:setUnitsToMeters( u2m )

	self.default3DSpread = option[ '3DSpread' ] or 360
	self.default3DLevel  = option[ '3DLevel' ] or 1

	system:setNumListeners( 1 )
	self:getListener( 1 ):setLoc( 1000000, 1000000, 1000000 )
	self:clearCaches()
	return true
end

function FMODStudioAudioManager:getUnitToMeters()
	return self.unitsToMeters
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
		bus = self.system:getBus( fullpath ) or false
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
	if bus then 
		bus:setPaused( paused ~= false )
	else
		_warn( 'no audio bus found', category )
	end
end

function FMODStudioAudioManager:muteCategory( category, muted )
	local bus = self:getBus( category )
	if bus then
		bus:setMute( paused ~= false )
	else
		_warn( 'no audio bus found', category )
	end
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

function FMODStudioAudioManager:getEventDescription( eventPath )
	local eventId = _affirmFmodEvent( eventPath )
	if not eventId then
		-- _warn( 'no audio event found', eventPath )
		return false
	end
	local eventDescription = self:getEventById( eventId )
	if not eventDescription then
		-- _warn( 'no event found', eventId )
		return false
	end
	return eventDescription
end

local EVENT_CREATE = MOAIFMODStudioEventInstance.EVENT_CREATE
local function _CallbackOnCreate3DEvent( this )
	-- this:set3DLevel( _mgr.default3DLevel )
end

local function _CallbackOnCreate2DEvent( this )
end

function FMODStudioAudioManager:createEventInstance( eventPath )
	local eventDescription = self:getEventDescription( eventPath )
	if not eventDescription then return false end
	local instance = eventDescription:createInstance()
	-- if eventDescription:is3D() then
	-- 	instance:setListener( EVENT_CREATE, _CallbackOnCreate3DEvent )
	-- else
	-- 	instance:setListener( EVENT_CREATE, _CallbackOnCreate2DEvent )
	-- end
	return instance
end

function FMODStudioAudioManager:playEvent3D( eventPath, x, y, z )
	local instance = self:createEventInstance( eventPath )
	if not instance then return false end
	instance:start()
	instance:setLoc( x, y, z )
	return instance
end

function FMODStudioAudioManager:playEvent2D( eventPath )
	local instance = self:createEventInstance( eventPath )
	if not instance then return false end
	instance:start()
	return instance
end

function FMODStudioAudioManager:isEventInstancePlaying( sound )
	return sound:getPlaybackState() ~= MOAIFMODStudioEventInstance.PLAYBACK_STOPPED
end


local FMODStudioEventSettingNames = {
	[ 'min_distance' ] = MOAIFMODStudioEventInstance.PROPERTY_MINIMUM_DISTANCE,
	[ 'max_distance' ] = MOAIFMODStudioEventInstance.PROPERTY_MAXIMUM_DISTANCE,
}

function FMODStudioAudioManager:getEventSetting( path, key )
	local ed = self:getEventDescription( path )
	if not ed then return nil end
	if key == 'min_distance' then
		return ed:getMinimumDistance()
	elseif key == 'max_distance' then
		return ed:getMaximumDistance()
	else
		return nil
	end
end

function FMODStudioAudioManager:setEventSetting( path, key, value )
	--do nothing
	return	
end

function FMODStudioAudioManager:getEventInstanceSetting( eventInstance, key )
	local id
	if type( key ) == 'number' then
		id = key
	else
		id = FMODStudioEventSettingNames[ key ]
	end
	return id and eventInstance:getProperty( id )
end


function FMODStudioAudioManager:setEventInstanceSetting( eventInstance, key, value )
	local id
	if type( key ) == 'number' then
		id = key
	else
		id = FMODStudioEventSettingNames[ key ]
	end
	if not id then
		_warn( 'no valid event property', key )
	end
	return eventInstance:setProperty( id, value )
end


local function _getEventInstanceParameterIndex( eventInstance, key )
	local desc = eventInstance:getDescription()
	if not desc then return nil end
	local parameterIndexCache = desc.parameterIndexCache
	if not parameterIndexCache then
		parameterIndexCache = {}
		desc.parameterIndexCache = parameterIndexCache
	end
	local index = parameterIndexCache[ key ]
	if index ~= nil then return index end
	index = desc:getParameterIndex( key ) or false
	parameterIndexCache[ key ] = index
	return index
end

function FMODStudioAudioManager:getEventInstaceParameter( eventInstance, key )
	local index = _getEventInstanceParameterIndex( key )
	return eventInstance:getParameterValueByIndex( index )
end

function FMODStudioAudioManager:setEventInstanceParameter( eventInstance, key, value )
	local index = _getEventInstanceParameterIndex( eventInstance )
	if index then
		return eventInstance:setParameterValueByIndex( index, value )
	end
end

--------------------------------------------------------------------
_stat( 'using FMOD Studio audio manager' )
FMODStudioAudioManager()

 