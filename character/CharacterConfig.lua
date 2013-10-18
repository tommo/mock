module 'character'


CLASS: CharacterActionEvent ()
CLASS: CharacterActionTrack ()
CLASS: CharacterAction ()
CLASS: CharacterConfig ()


--------------------------------------------------------------------
CharacterActionEvent
:MODEL{		
		Field 'pos'    :int() :range(0)  :getset('Pos');
		Field 'length' :int() :range(0)  :getset('Length');
		Field 'parent' :type( CharacterActionTrack ) :no_edit();		
	}

function CharacterActionEvent:__init()
	self.pos    = 0
	self.length = 10
end

function CharacterActionEvent:findNextEvent()
	-- self.parent:sortEvents()
	local events = self.parent.events
	local pos0 = self.pos
	local pos = false
	local res = nil
	for i, e in ipairs( events ) do
		local pos1 = e.pos
		if e ~= self and pos1 > pos0  then
			if not pos or pos > pos1 then
				res = e
				pos = pos1
			end
		end		
	end
	return res
end

function CharacterActionEvent:start( target, pos )
	return self:onStart( target, pos )
end

function CharacterActionEvent:onStart( pos )
end

function CharacterActionEvent:toString()
	return 'event'
end

function CharacterActionEvent:setPos( pos )
	self.pos = pos
end

function CharacterActionEvent:isResizable()
	return false
end

function CharacterActionEvent:getPos()
	return self.pos
end

function CharacterActionEvent:setLength( length )
	self.length = length
end

function CharacterActionEvent:getLength()
	return self.length
end

function CharacterActionEvent:getTrack()
	return self.parent
end

function CharacterActionEvent:getAction()
	return self.parent.parent
end



--------------------------------------------------------------------

CharacterActionTrack
:MODEL{
		Field 'name' :string();		
		Field 'events' :array( CharacterActionEvent ) :no_edit();		
		Field 'parent' :type( CharacterAction ) :no_edit();
	}

function CharacterActionTrack:__init()
	self.name = 'track'
	self.events = {}
end

function CharacterActionTrack:getType()
	return 'track'
end

function CharacterActionTrack:getAction()
	return self.parent
end

--whether build keyframe using event from the track
function CharacterActionTrack:hasKeyFrames() 
	return true
end

function CharacterActionTrack:createEvent()
	return CharacterActionEvent()
end

function CharacterActionTrack:addEvent( pos )
	local ev = self:createEvent()
	table.insert( self.events, ev )
	ev.parent = self
	ev.pos = pos or 0
	return ev
end

function CharacterActionTrack:removeEvent( ev )
	for i, e in ipairs( self.events ) do
		if e == ev then 
			table.remove( self.events, i )
			return true
		 end
	end	
	return false
end

local function _sortEvent( o1, o2 )
	return o1.pos < o2.pos
end

function CharacterActionTrack:sortEvents()
	table.sort( self.events, _sortEvent )
end

function CharacterActionTrack:toString()
	return self.name
end


--------------------------------------------------------------------
CLASS: CharacterActionState ()
	:MODEL{}

local function _actionStateEventListener( timer, key, timesExecuted, time, value )
	local state  = timer.state
	local action = state.action
	local span   = action.spanList[ key ]
	local target = state.target
	for i, ev in ipairs( span ) do
		target:processActionEvent( ev, timer:getTime() )
	end
end

function CharacterActionState:__init( action, target )
	self.action = action
	self.target = target
	local timer = MOAITimer.new()
	self.timer  = timer
	local curve = action:getKeyCurve() 
	timer:setCurve( curve )
	timer:setSpan( 100000 )
	timer:setMode( MOAITimer.NORMAL )
	timer:setListener( MOAITimer.EVENT_TIMER_KEYFRAME, _actionStateEventListener )
	timer.state = self
	self.throttle = 1
end

function CharacterActionState:setThrottle( th )
	th = th or 1
	self.throttle = th
	self.timer:throttle( th )
end

function CharacterActionState:start()
	self.timer:start()
	self.timer:throttle( self.throttle )
end

function CharacterActionState:stop()
	self.timer:stop()
end

function CharacterActionState:pause()
	self.timer:pause()
end

function CharacterActionState:getTime()
	return self.timer:getTime()
end

function CharacterActionState:isDone()
	return self.timer:isDone()
end

function CharacterActionState:isPaused()
	return self.timer:isPaused()
end



--------------------------------------------------------------------
CharacterAction	:MODEL{
		Field 'name' :string();		
		Field 'tracks' :array( CharacterActionTrack ) :no_edit();		
		Field 'parent' :type( CharacterConfig ) :no_edit();
	}

function CharacterAction:__init()
	self.name = 'action'
	self.tracks = {}
end

function CharacterAction:start()
end

function CharacterAction:addTrack( t )
	local track = t or CharacterActionTrack()
	table.insert( self.tracks, track )
	track.parent = self
	return track
end

function CharacterAction:removeTrack( track )
	for i, t in ipairs( self.tracks ) do
		if t == track then return table.remove( self.tracks, i )  end
	end	
end

function CharacterAction:findTrack( name, trackType )
	for i, t in ipairs( self.tracks ) do
		if t.name == name then
			if not trackType or t:getType() == trackType then return t end
		end
	end
end

function CharacterAction:findTrackByType( trackType )
	for i, t in ipairs( self.tracks ) do
		if t:getType() == trackType then return t end
	end
	return nil
end


function CharacterAction:createActionState( target )
	local state = CharacterActionState( self, target )
	return state
end

function CharacterAction:getKeyCurve()
	return self.keyCurve or self:_buildKeyCurve()
end

function CharacterAction:_buildKeyCurve()
	local spanPoints = {}
	local spanSet    = {}
	local spanList   = {}
	for i, track in ipairs( self.tracks ) do
		track:sortEvents()
		if track:hasKeyFrames() then
			for i, event in ipairs( track.events ) do
				local pos    = event.pos
				local length = event.length
				local t = spanSet[ pos ]
				if not t then 
					t = {}
					spanSet[ pos ] = t
					table.insert( spanPoints, pos )
				end
				table.insert( t, event )
			end
		end
	end
	table.sort( spanPoints )
	local curve = MOAIAnimCurve.new()
	curve:reserveKeys( #spanPoints )
	for i, pos in ipairs( spanPoints ) do
		local time = pos/1000 --ms convert to second
		curve:setKey( i, time, i ) 
		spanList[ i ] = spanSet[ pos ]
	end
	self.spanList = spanList
	self.keyCurve = curve
	return curve
end

--------------------------------------------------------------------
CharacterConfig	:MODEL{
		Field 'name'    :string();
		Field 'spine'   :asset('spine') :getset('Spine');
		Field 'actions' :array( CharacterAction ) :no_edit();		
	}

function CharacterConfig:__init()
	self.name    = 'character'
	self.actions = {}
end

function CharacterConfig:getSpine()
	return self.spinePath
end

function CharacterConfig:setSpine( path )
	self.spinePath = path
end

function CharacterConfig:addAction( name )
	if not self.actions then self.actions = {} end
	local action = CharacterAction()
	action.name = name
	table.insert( self.actions, action )
	action.parent = self
	return action
end

function CharacterConfig:removeAction( act )
	for i, a in ipairs( self.actions ) do
		if act == a then
			table.remove( self.actions, i )
			return
		end
	end
end

function CharacterConfig:getAction( name )
	for i, act in ipairs( self.actions ) do
		if act.name == name then return act end
	end
	return nil
end

--------------------------------------------------------------------
local function loadCharacterConfig( node )
	local data   = mock.loadAssetDataTable( node:getObjectFile('config') )
	local config = mock.deserialize( nil, data )
	if config then --set parent nodes
		for i, act in ipairs( config.actions ) do
			act.parent = config		
			for i, track in ipairs( act.tracks ) do
				track.parent = act
				for i, event in ipairs( track.events ) do
					event.parent = track
				end
			end
		end
	end
	return config
end

mock.registerAssetLoader( 'character', loadCharacterConfig )

--------------------------------------------------------------------

local _TrackTypes = {}
function getCharacterActionTrackTypeTable()
	return _TrackTypes
end

function registerCharacterActionTrackType( name, trackClas )
	if _TrackTypes[ name ] then
		_warn( 'duplicated action track type', name )
	end
	_TrackTypes[ name ] = trackClas
end

function getCharacterActionTrackType( name )
	return _TrackTypes[ name ]
end
