module 'mock'
--------------------------------------------------------------------
--SOUND SOURCE
--------------------------------------------------------------------
CLASS: SoundSource ( Component )
	:MODEL{
		Field 'defaultEvent' :asset( getSupportedSoundAssetTypes() )  :getset('DefaultEvent');
		Field 'autoPlay'    :boolean();
		'----';
		Field 'singleInstance' :boolean();
		Field 'initialVolume' :number();
		'----';
		Field 'is3D' :boolean();
		Field 'following' :boolean();
		Field 'minDistance' :getset( 'MinDistance' );
		Field 'maxDistance' :getset( 'MaxDistance' );
	}

	:META{
		category = 'audio'
	}


function SoundSource:__init()
	self.eventInstances = {}
	self.eventNamePrefix = false
	self.loopSound = true
	self.defaultEventPath = false
	self.singleInstance = false
	self.initialVolume = -1
	self.is3D = true
	self.following = true
	self.minDistance = -1
	self.maxDistance = -1
end

function SoundSource:onAttach( entity )
end

function SoundSource:onDetach( entity )
	self:stop()
	self.eventInstances = nil
end

function SoundSource:setDefaultEvent( path )
	self.defaultEventPath = path
end

function SoundSource:getDefaultEvent()
	return self.defaultEventPath
end

function SoundSource:onStart()
	if self.autoPlay then self:start() end	
end

function SoundSource:setEventPrefix( prefix )
	self.eventNamePrefix = prefix or false
end

function SoundSource:start()
	if self.defaultEventPath then
		if self.is3D then
			return self:playEvent3D( self.defaultEventPath )
		else
			return self:playEvent2D( self.defaultEventPath )
		end
	end
end

function SoundSource:stop()
	for instance, k in pairs( self.eventInstances ) do
		instance:stop()
	end
	self.eventInstances = {}
end

--------------------------------------------------------------------
function SoundSource:_addInstance( instance, follow )
	local mgr = AudioManager.get()
	if self.singleInstance then
		self:stop()
	end
	self:clearStoppedInstances()
	self.eventInstances[ instance ] = true
	if self.initialVolume >= 0 then
		instance:setVolume( self.initialVolume )
	end
	local d0, d1 = self.minDistance, self.maxDistance
	local u2m = mgr:getUnitToMeters()
	if d0 >= 0 then
		mgr:setEventInstanceSetting( instance, 'min_distance', d0 * u2m )
	end
	if d1 >= 0 then
		mgr:setEventInstanceSetting( instance, 'max_distance', d1 * u2m )
	end
	if follow then
		inheritTransform( instance, self._entity:getProp( 'physics' ) )
		instance:setLoc( 0,0,0 )
		instance:forceUpdate()
	end
	return instance
end

function SoundSource:_playEvent3DAt( event, x,y,z, follow, looped )
	local instance	
	instance = AudioManager.get():playEvent3D( event, x,y,z )
	if instance then
		follow = follow == nil and self.following or follow
		return self:_addInstance( instance, follow~=false )
	else
		_error( 'sound event not found:', event )
		return false
	end
end

function SoundSource:_playEvent2D( event, looped )
	local instance = AudioManager.get():playEvent2D( event, looped )
	if instance then
		return self:_addInstance( instance, false )
	else
		_error( 'sound event not found:', event )
		return false
	end
end

--------------------------------------------------------------------
function SoundSource:playEvent3DAt( event, x,y,z, follow )
	return self:_playEvent3DAt( event, x,y,z, follow, nil )
end

function SoundSource:playEvent3D( event, follow )
	local x,y,z
	self._entity:forceUpdate()
	local prop = self._entity:getProp( 'physics' )
	x,y,z = prop:getWorldLoc()
	return self:playEvent3DAt( event, x,y,z, follow )
end

function SoundSource:playEvent2D( event )
	return self:_playEvent2D( event, nil )
end

function SoundSource:playEvent( event )
	if self.is3D then
		return self:playEvent3D( event )
	else
		return self:playEvent2D( event )
	end
end

function SoundSource:loopEvent3DAt( event, x,y,z, follow )
	return self:_playEvent3DAt( event, x,y,z, follow, true )
end

function SoundSource:loopEvent3D( event, follow )
	local x,y,z
	x,y,z = self._entity:getWorldLoc()
	return self:loopEvent3DAt( event, x,y,z, follow )
end

function SoundSource:loopEvent2D( event )
	return self:_playEvent2D( event, true )
end

--------------------------------------------------------------------
function SoundSource:isBusy()
	self:clearStoppedInstances()
	return next(self.eventInstances) ~= nil
end
	
function SoundSource:clearStoppedInstances()
	if not self.eventInstances then return end
	local t1 = {}
	for instance, k in pairs( self.eventInstances ) do
		if instance:isValid() then
			t1[ instance ] = k
		end
	end
	self.eventInstances = t1
end

function SoundSource:pauseInstances( paused )
	if not self.eventInstances then return end
	for instance in pairs( self.eventInstances ) do
		instance:pause( paused ~= false )
	end
end

function SoundSource:resumeInstances()
	if not self.eventInstances then return end
	for instance in pairs( self.eventInstances ) do
		instance:pause( false )
	end
end

function SoundSource:getMinDistance()
	return self.minDistance
end

function SoundSource:getMaxDistance()
	return self.maxDistance
end

function SoundSource:setMinDistance( d )
	self.minDistance = d
	if self._entity then self:updateDistance() end
end

function SoundSource:setMaxDistance( d )
	self.maxDistance = d
	if self._entity then self:updateDistance() end
end

function SoundSource:updateDistance()
	local d0, d1 = self.minDistance, self.maxDistance
	local mgr = AudioManager.get()
	local u2m = mgr:getUnitToMeters()
	for instance in pairs( self.eventInstances ) do
		if d0 >= 0 then
			mgr:setEventInstanceSetting( instance, 'min_distance', d0 * u2m )
		end
		if d1 >= 0 then
			mgr:setEventInstanceSetting( instance, 'max_distance', d1 * u2m )
		end
	end
end

function SoundSource:getDefaultEventSetting( key )
	local ev = self.defaultEventPath
	if not ev then return nil end
	return AudioManager.get():getEventSetting( ev, key )
end

function SoundSource:getDefaultEventDistanceSetting()
	if not self.defaultEventPath then return nil end
	local d0, d1 = self.minDistance, self.maxDistance
	local mgr = AudioManager.get()
	local u2m = mgr:getUnitToMeters()
	if d0 < 0 then
		d0 = self:getDefaultEventSetting( 'min_distance' ) / u2m
	end
	if d1 < 0  then
		d1 = self:getDefaultEventSetting( 'max_distance' ) / u2m
	end
	return d0, d1
end
--------------------------------------------------------------------
function SoundSource:onDrawGizmo( selected )
	if not self.defaultEventPath then return end
	local mgr = AudioManager.get()
	GIIHelper.setVertexTransform( self._entity:getProp( 'render' ) )
	local d0, d1 = self:getDefaultEventDistanceSetting()
	mock_edit.applyColor( 'range-min' )
	MOAIDraw.drawCircle( 0, 0, d0 )
	mock_edit.applyColor( 'range-max' )
	MOAIDraw.drawCircle( 0, 0, d1 )
end

--------------------------------------------------------------------
function SoundSource:onBuildGizmo()
	local icon = mock_edit.IconGizmo( 'sound.png' )
	local draw = mock_edit.DrawScriptGizmo()
	return icon, draw
end


registerComponent( 'SoundSource', SoundSource )
--------------------------------------------------------------------
