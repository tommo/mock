module 'mock'

--------------------------------------------------------------------
CLASS: Animator ( mock.Behaviour )
	:MODEL{
		Field 'config'       :asset('Animator') :getset( 'Config' );
		Field 'defaultClip'  :string();
		Field 'autoPlay'     :boolean();
		Field 'loop'         :boolean();
	}

function Animator:__init()
	self.config      = false
	self.default     = 'default'
	self.activeState = false
	self.throttle    = 1
	self.scale       = 1
	self.params      = {}

	self.clipEventCallbacks = false
	self.pendingClips = false
end

--------------------------------------------------------------------
function Animator:onAttach( entity )
end
--------------------------------------------------------------------

function Animator:setConfig( configPath )
	self.configPath = configPath
	self.config = mock.loadAsset( configPath )
	self:updateConfig()
end

function Animator:getConfig()
	return self.configPath
end

function Animator:updateConfig()
	local config = self.config
	if not config then return end
end

--------------------------------------------------------------------
--Parameters
--------------------------------------------------------------------
function Animator:setParam( key, value )
	self.params[ key ] = value
end

function Animator:getParam( key, default )
	local v = self.params[ key ]
	return v ~= nil and v or default
end

function Animator:hasParam( key )
	return self.params[ key ] ~= nil
end

--------------------------------------------------------------------
--Track access
--------------------------------------------------------------------
function Animator:getClip( clipName )
	if not self.config then return nil end
	return self.config:getClip( clipName )
end

function Animator:findTrack( clipName, trackName, trackType )
	local clip = self:getClip( clipName )
	if not clip then
		_warn('Animator has no clip', clipName)
		return nil
	end
	return clip:findTrack( trackName, trackType )
end

function Animator:findTrackByType( clipName, trackType )
	local clip = self:getClip( clipName )
	if not clip then
		_warn('Animator has no clip', clipName)
		return nil
	end
	return clip:findTrackByType( trackType )
end

--------------------------------------------------------------------
--playback
function Animator:hasClip( name )
	if not self.config then
		return false
	end
	return self.config:getClip( name ) and true or false
end

function Animator:setClip( name )
	if not self.config then
		_warn('Animator has no config')
		return false
	end
	local clip = self.config:getClip( name )
	if not clip then
		_warn( 'Animator has no clip', name )
		return false
	end
	self:stop()
	self:setThrottle( 1 )
	local clipState = AnimatorState( self, clip )
	self.activeState = clipState
	return clipState
end

function Animator:play( name )
	local state = self:setClip( name )
	self.pendingClips = false
	if state then	state:start()	end
	return state
end

function Animator:playSequence( first, ... )
	local state = self:play( first )
	self.pendingClips = { ... }
	return state
end

function Animator:stop()
	if not self.activeState then return end
	self.activeState:stop()
end

function Animator:pause( paused )
	if not self.activeState then return end
	self.activeState:pause( paused )
end

function Animator:resume()
	return self:pause( false )
end

function Animator:setThrottle( th )
	self.throttle = th
	if self.activeState then
		self.activeState:setThrottle( th )
	end
end

-----
function Animator:onStart( ent )	
	if self.autoPlay and self.default and self.config then
		if self.default == '' then return end
		self:play( self.default )
	end
	mock.Behaviour.onStart( self, ent )
end

function Animator:onDetach( ent )
	self:stop()
	return mock.Behaviour.onDetach( self, ent )
end

--------------------------------------------------------------------
function Animator:processClipEvent( evtype, ev, time, state )	
	if self.clipEventCallbacks then
		for i, callback in ipairs( self.clipEventCallbacks ) do
			callback( self, evtype, ev, time, state )
		end
	end
end

function Animator:addClipEventCallback( cb )
	local callbacks = self.clipEventCallbacks
	if not callbacks then
		callbacks = {}
		self.clipEventCallbacks = callbacks
	end
	table.insert( callbacks, cb )
end

function Animator:removeClipEventCallback( cb )
	for i, v in ipairs( self.clipEventCallbacks ) do
		if v == cb then
			return table.remove( self.clipEventCallbacks, i )
		end
	end
end

--------------------------------------------------------------------
function Animator:processStateEvent( evtype, timesExecuted )	
	if evtype == 'stop' then
		if self.pendingClips then
			local nextClip = table.remove( self.pendingClips, 1 )
			if nextClip then
				local state = self:setClip( nextClip )
				if state then	state:start()	end
			else
				self.pendingClips = false
			end
		end
	end

	if self.stateEventCallbacks then
		for i, callback in ipairs( self.stateEventCallbacks ) do
			callback( self, evtype, timesExecuted )
		end
	end

end

function Animator:addStateEventCallback( cb )
	local callbacks = self.stateEventCallbacks
	if not callbacks then
		callbacks = {}
		self.stateEventCallbacks = callbacks
	end
	table.insert( callbacks, cb )
end

function Animator:removeStateEventCallback( cb )
	for i, v in ipairs( self.stateEventCallbacks ) do
		if v == cb then
			return table.remove( self.stateEventCallbacks, i )
		end
	end
end

--------------------------------------------------------------------
--EVENT ACTION:

function Animator:playAnim( clip, loop, resetPose )
end

function Animator:stopAnim( resetPose )
end

--------------------------------------------------------------------
mock.registerComponent( 'Animator', Animator )
