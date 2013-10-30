module 'character'
--------------------------------------------------------------------
CLASS: Character ( mock.Behaviour )
	:MODEL{
		Field 'config'  :asset('character') :getset( 'Config' );
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

	self.actionEventCallbacks = false

end

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
	--todo
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
	actionState:start()
	return actionState
end

function Character:stop()
	if not self.activeState then return end
	self.activeState:stop()
	self.activeState = false
	self.spineSprite:stop( false )
end

function Character:pause( paused )
	if not self.activeState then return end
	self.activeState:pause( paused )
	self.spineSprite:pause( paused )
end

function Character:resume()
	return self:pause( false )
end

function Character:setThrottle( th )
	self.throttle = th
	if self.activeState then
		self.activeState:setThrottle( th )
	end
	self.spineSprite:setThrottle( th )
end

-----
function Character:onStart( ent )
	ent:attach( self.spineSprite )
	ent:attach( self.soundSource )
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
function Character:processActionEvent( ev, time )
	ev:start( self, time )
	if self.actionEventCallbacks then
		for i, callback in ipairs( self.actionEventCallbacks ) do
			callback( self, ev, time )
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


------
--EVENT ACTION:

function Character:playAnim( clip, loop, resetPose )
	self.spineSprite:play( clip, loop and MOAITimer.LOOP, resetPose )
end

function Character:stopAnim( resetPose )
	self.spineSprite:stop( resetPose )
end

--------------------------------------------------------------------
mock.registerComponent( 'Character', Character )
