module 'mock'
--------------------------------------------------------------------
--SOUND SOURCE
--------------------------------------------------------------------
CLASS: SoundSource ( Component )
	:MODEL{
		Field 'defaultClip' :asset( getSupportedSoundAssetTypes() )  :getset('DefaultClip');
		Field 'autoPlay'    :boolean();
		'----';
		Field 'singleInstance' :boolean();
		Field 'following' :boolean();
		Field 'initialVolume' :number();
		Field 'is3D' :boolean();
	}
	:META{
		category = 'audio'
	}


function SoundSource:__init()
	self.eventInstances = {}
	self.eventNamePrefix = false
	self.is3D = true
	self.loopSound = true
	self.defaultClipPath = false
	self.singleInstance = false
	self.initialVolume = -1
	self.following = true
end

function SoundSource:onAttach( entity )
end

function SoundSource:onDetach( entity )
	for instance, k in pairs( self.eventInstances ) do
		instance:stop()
	end
	self.eventInstances = nil
end

function SoundSource:setDefaultClip( path )
	self.defaultClipPath = path
end

function SoundSource:getDefaultClip()
	return self.defaultClipPath
end

function SoundSource:onStart()
	if self.autoPlay then self:start() end	
end

function SoundSource:setEventPrefix( prefix )
	self.eventNamePrefix = prefix or false
end

function SoundSource:start()
	if self.defaultClipPath then
		if self.is3D then
			return self:playEvent3D( self.defaultClipPath )
		else
			return self:playEvent2D( self.defaultClipPath )
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
	if self.singleInstance then
		self:stop()
	end
	self:clearInstances()
	self.eventInstances[ instance ] = true
	if self.initialVolume >= 0 then
		instance:setVolume( self.initialVolume )
	end
	if follow then
		self._entity:_attachTransform( instance )
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
	x,y,z = self._entity:getWorldLoc()
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
	self:clearInstances()
	return next(self.eventInstances) ~= nil
end
	
function SoundSource:clearInstances()
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


--------------------------------------------------------------------
function SoundSource:onBuildGizmo()
	local giz = mock_edit.IconGizmo( 'sound.png' )
	return giz
end


registerComponent( 'SoundSource', SoundSource )
--------------------------------------------------------------------
