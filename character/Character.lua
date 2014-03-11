module 'character'
--------------------------------------------------------------------
CLASS: Character ( mock.Behaviour )
	:MODEL{
		Field 'config'  :asset('character') :getset( 'Config' );
		Field 'mirrorX'  :boolean() :set( 'setMirrorX' );
		Field 'mirrorY'  :boolean() :set( 'setMirrorY' );
		Field 'default' :string();
		Field 'autoPlay' :boolean();
		Field 'loop'     :boolean();
	}

function Character:__init()
	self.config      = false
	self.default     = 'default'
	self.activeState = false
	self.spineSprite = mock.SpineSprite()	
	self.soundSource = mock.SoundSource()
	self.throttle    = 1
	self.mirrorX     = false
	self.mirrorY     = false

	self.actionEventCallbacks = false
end

--------------------------------------------------------------------
function Character:onAttach( entity )
	entity:attachInternal( self.spineSprite )

	entity:attachInternal( self.soundSource )
end
--------------------------------------------------------------------

function Character:setConfig( configPath )
	self.configPath = configPath
	self.config = mock.loadAsset( configPath )
	self:updateConfig()
end

function Character:getConfig()
	return self.configPath
end

function Character:updateConfig()
	local config = self.config
	if not config then return end
	local path = config:getSpine()
	self.spineSprite:setSprite( path )
	local sk = self.spineSprite.skeleton
	if sk then
		setSclX( sk, self.mirrorX and -1 or 1 )
		setSclY( sk, self.mirrorY and -1 or 1 )
	end
end

function Character:setMirrorX( mirror )
	self.mirrorX = mirror
	local skeleton = self.spineSprite.skeleton
	if skeleton then
		setSclX( skeleton, mirror and -1 or 1 )
	end
end

function Character:setMirrorY( mirror )
	self.mirrorY = mirror
	local skeleton = self.spineSprite.skeleton
	if skeleton then
		setSclY( skeleton, mirror and -1 or 1 )
	end
end

--------------------------------------------------------------------
--Track access
--------------------------------------------------------------------
function Character:getAction( actionName )
	if not self.config then return nil end
	return self.config:getAction( actionName )
end

function Character:findTrack( actionName, trackName, trackType )
	local action = self:getAction( actionName )
	if not action then
		_warn('character has no action', actionName)
		return nil
	end
	return action:findTrack( trackName, trackType )
end

function Character:findTrackByType( actionName, trackType )
	local action = self:getAction( actionName )
	if not action then
		_warn('character has no action', actionName)
		return nil
	end
	return action:findTrackByType( trackType )
end


--------------------------------------------------------------------
--playback
function Character:playAction( name )
	local state = self:setAction( name )
	if state then	state:start()	end
	return state
end

function Character:setAction( name )
	if not self.config then
		_warn('character has no config')
		return false
	end
	local action = self.config:getAction( name )
	if not action then
		_warn( 'character has no action', name )
		return false
	end
	self:stop()
	self:setThrottle( 1 )
	local actionState = CharacterState( self, action )
	self.activeState = actionState
	return actionState
end


function Character:stop()
	if not self.activeState then return end
	self.activeState:stop()
end

function Character:pause( paused )
	if not self.activeState then return end
	self.activeState:pause( paused )
end

function Character:resume()
	return self:pause( false )
end

function Character:setThrottle( th )
	self.throttle = th
	if self.activeState then
		self.activeState:setThrottle( th )
	end
end

-----
function Character:onStart( ent )	
	if self.autoPlay and self.default and self.config then
		if self.default == '' then return end
		self:playAction( self.default )
	end
	mock.Behaviour.onStart( self, ent )
end

function Character:onDetach( ent )
	self:stop()
	ent:detach( self.spineSprite )
	return mock.Behaviour.onDetach( self, ent )
end

--------------------------------------------------------------------
function Character:processActionEvent( evtype, ev, time, state )	
	if self.actionEventCallbacks then
		for i, callback in ipairs( self.actionEventCallbacks ) do
			callback( self, evtype, ev, time, state )
		end
	end
end

function Character:addActionEventCallback( cb )
	local callbacks = self.actionEventCallbacks
	if not callbacks then
		callbacks = {}
		self.actionEventCallbacks = callbacks
	end
	table.insert( callbacks, cb )
end

function Character:removeActionEventCallback( cb )
	for i, v in ipairs( self.actionEventCallbacks ) do
		if v == cb then
			return table.remove( self.actionEventCallbacks, i )
		end
	end
end

--------------------------------------------------------------------
--EVENT ACTION:

function Character:playAnim( clip, loop, resetPose )
	self.spineSprite:play( clip, loop and MOAITimer.LOOP, resetPose )
end

function Character:stopAnim( resetPose )
	self.spineSprite:stop( resetPose )
end

--------------------------------------------------------------------
mock.registerComponent( 'Character', Character )
