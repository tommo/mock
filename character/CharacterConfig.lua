module 'character'

CLASS: CharacterActionEvent ()
CLASS: CharacterActionTrack ()
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

function CharacterActionEvent:getPos()
	return self.pos
end

function CharacterActionEvent:setLength( length )
	self.length = length
end

function CharacterActionEvent:getLength()
	return self.length
end


--------------------------------------------------------------------

CharacterActionTrack
:MODEL{
		Field 'name' :string();		
		Field 'events' :array( CharacterActionEvent ) :no_edit();		
	}

function CharacterActionTrack:__init()
	self.name = 'track'
	self.events = {}
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
		if e == ev then return table.remove( self.events, i )  end
	end	
end

function CharacterActionTrack:toString()
	return self.name
end
--------------------------------------------------------------------
CLASS: CharacterActionState ()
	:MODEL{}

local function _actionStateEventListener( timer, key, timesExecuted, time, value )
	print( key, time, value )
	local state  = timer.state
	local action = state.action
	local span   = action.spanList[ key ]
	for i, ev in ipairs( span ) do
		ev:start( state.target, time )
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
end

function CharacterActionState:start()
	self.timer:start()
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
CLASS: CharacterAction ()
	:MODEL{
		Field 'name' :string();		
		Field 'tracks' :array( CharacterActionTrack ) :no_edit();		
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
	return track
end

function CharacterAction:removeTrack( track )
	for i, t in ipairs( self.tracks ) do
		if t == track then return table.remove( self.tracks, i )  end
	end	
end

function CharacterAction:createState( target )
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
CLASS: CharacterConfig ()
	:MODEL{
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
