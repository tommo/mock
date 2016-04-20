module 'mock'

--------------------------------------------------------------------
CLASS: Animator ( Component )
	:MODEL{
		Field 'data'         :asset('animator_data') :getset( 'DataPath' );
		'----';
		Field 'throttle'     :number() :range( 0 ) :meta{ step=0.1 } :getset( 'Throttle' );
		'----';
		Field 'default'      :string() :selection( 'getClipNames' );
		Field 'autoPlay'     :boolean();
		Field 'autoPlayMode' :enum( EnumTimerMode );
	}

function Animator:__init()
	self.dataPath    = false
	self.data        = false
	self.default     = 'default' --default clip
	self.activeState = false
	self.throttle    = 1
	self.scale       = 1
	self.autoPlay    = true
	self.autoPlayMode= MOAITimer.LOOP 
	self.params      = {}
end

--------------------------------------------------------------------
function Animator:onAttach( entity )
end
--------------------------------------------------------------------

function Animator:setDataPath( dataPath )
	self.dataPath = dataPath
	self.data = mock.loadAsset( dataPath )
end

function Animator:getDataPath()
	return self.dataPath
end

function Animator:getData()
	return self.data
end

function Animator:getClipNames()
	local data = self.data
	if not data then return nil end
	local result = {}
	for _, clip in ipairs( data.clips ) do
		local name = clip.name
		table.insert( result, { name, name } )
	end
	return result
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
	if not self.data then return nil end
	return self.data:getClip( clipName )
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
	if not self.data then
		return false
	end
	return self.data:getClip( name ) and true or false
end

function Animator:_loadClip( clip, makeActive )
	local state = AnimatorState()
	state:setThrottle( self.throttle )
	state:loadClip( self, clip )
	if makeActive ~= false then 
		self:stop()
		self.activeState = state
	end
	return state
end

function Animator:loadClip( name, makeActive )
	if not self.data then
		_warn('Animator has no data')
		return false
	end
	local clip = self.data:getClip( name )
	if not clip then
		_warn( 'Animator has no clip', name )
		return false
	end
	return self:_loadClip( clip, makeActive )
end

function Animator:getActiveState()
	return self.activeState
end

function Animator:playClip( clipName, option )
	local state = self:loadClip( clipName )
	if state then	
		tt = type( option )
		if tt == 'string' then --play mode only
		elseif tt == 'table' then --advcanced options
			--TODO
		elseif option then
			local playMode = option
			state:setMode( playMode )
		end
		state:start()
	end
	return state
end

-- function Animator:play( ... )
-- 	return self:playClip( ... )
-- end

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

function Animator:startDefaultClip()
	if self.default and self.data then
		if self.default == '' then return end
		return self:playClip( self.default, self.autoPlayMode )
	end
	return false
end

function Animator:setThrottle( th )
	self.throttle = th
	if self.activeState then
		self.activeState:setThrottle( th )
	end
end

function Animator:getThrottle()
	return self.throttle
end

-----
function Animator:onStart( ent )	
	if self.autoPlay then
		self:startDefaultClip()
	end
end

function Animator:onDetach( ent )
	self:stop()
end

--------------------------------------------------------------------
mock.registerComponent( 'Animator', Animator )
