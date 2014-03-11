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

function CharacterActionEvent:findNextEvent( allowWrap )
	-- self.parent:sortEvents()
	local action = self:getAction()	
	local wrap = allowWrap ~= false and action.loop
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
	if res then
		return res
	elseif wrap then
		return events[1]
	end
	return nil
end

function CharacterActionEvent:start( state, pos )
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

function CharacterActionEvent:getKeyFramePos()
	return self.pos
end

function CharacterActionEvent:setLength( length )
	self.length = length
end

function CharacterActionEvent:getLength()
	return self.length
end

function CharacterActionEvent:getEnd()
	return self.pos + self.length
end

function CharacterActionEvent:getTrack()
	return self.parent
end

function CharacterActionEvent:getAction()	
	local track = self.parent
	return track and track.parent
end

function CharacterActionEvent:getRootConfig()
	local track = self.parent
	if track then
		local action = track.parent
		if action then return action.parent end
	end
	return nil
end
--------------------------------------------------------------------
CharacterActionTrack
:MODEL{
		Field 'name' :string();		
		Field 'events' :array( CharacterActionEvent ) :no_edit() :sub();		
		Field 'parent' :type( CharacterAction ) :no_edit();
	}

function CharacterActionTrack:__init()
	self.name = 'track'
	self.events = {}
end

function CharacterActionTrack:getType()
	return 'track'
end

function CharacterActionTrack:toString()
	return self.name
end

function CharacterActionTrack:getAction()
	return self.parent
end

function CharacterActionTrack:getRootConfig()
	local action = self.parent
	return action and action.parent
end
--------------------------------------------------------------------
function CharacterActionTrack:addEvent( pos, evType )
	local ev = self:createEvent( evType )
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

function CharacterActionTrack:calcLength()
	local l = 0
	for i, e in ipairs( self.events ) do
		local l1 = e:getEnd()
		if l1>l then l = l1 end
	end
	return l
end

function CharacterActionTrack:getHeadEvent()
	return self.events[ 1 ]
end

function CharacterActionTrack:getTailEvent()
	local l = #self.events
	if l > 0 then
		return self.events[ l ]
	end
	return nil
end

--------------------------------------------------------------------
--VIRTUAL Functions
--whether build keyframe using event from the track
function CharacterActionTrack:hasKeyFrames() 
	return true
end
--Event Factory
function CharacterActionTrack:createEvent()
	return CharacterActionEvent()
end

--for multiple event type support
function CharacterActionTrack:getEventTypes()
	return false
end

--(pre)build
function CharacterActionTrack:buildStateData( stateData ) 
end
--(clean)build
function CharacterActionTrack:clearStateData( stateData ) 
end

function CharacterActionTrack:setThrottle( state, th )
end

function CharacterActionTrack:start( state )
end

function CharacterActionTrack:stop( state )
end

function CharacterActionTrack:pause( state, paused )
end

function CharacterActionTrack:apply( state, t )
end

function CharacterActionTrack:apply2( state, t0, t1 )
end

--------------------------------------------------------------------
CharacterAction	:MODEL{
		Field 'name' :string();		
		Field 'loop' :boolean();
		Field 'length' :int();
		Field 'tracks' :array( CharacterActionTrack ) :no_edit() :sub();		
		Field 'parent' :type( CharacterConfig ) :no_edit();
	}

function CharacterAction:__init()
	self.name      = 'action'
	self.tracks    = {}
	self.stateData = false
	self.loop      = false
	self.length    = -1
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

--------------------------------------------------------------------
function CharacterAction:getStateData()	
	return self.stateData or self:buildStateData()
end

function CharacterAction:buildStateData()
	stateData = {}
	local length = 0
	for i, track in ipairs( self.tracks ) do
		track:buildStateData( stateData )
		local l = track:calcLength()
		if l>length then length = l end
	end
	stateData.length   = length
	stateData.keyCurve = self:_buildKeyCurve()
	self.stateData = stateData
	return stateData
end

function CharacterAction:clearStateData()
	for i, track in ipairs( self.tracks ) do
		track:clearStateData( stateData )
	end
	self.stateData = false
end

function CharacterAction:_buildKeyCurve()
	local spanPoints = {}
	local spanSet    = {}
	local spanList   = {}
	for i, track in ipairs( self.tracks ) do
		track:sortEvents()
		if track:hasKeyFrames() then
			for i, event in ipairs( track.events ) do
				local pos = event:getKeyFramePos()
				if pos<0 then pos = 0 end
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

function CharacterConfig:sortEvents() --pre-serialization
	for i, action in ipairs( self.actions ) do
		for _, track in ipairs( action.tracks ) do
			track:sortEvents()
		end
	end
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

function registerCharacterActionTrackType( name, trackClas, eventTypes )
	if _TrackTypes[ name ] then
		_warn( 'duplicated action track type', name )
	end
	_TrackTypes[ name ] = {
		clas = trackClas,
		eventTypes = eventTypes
	}
end

function getCharacterActionTrackType( name )
	local entry = _TrackTypes[ name ]
	return entry and entry.clas
end

function getCharacterActionTrackEventTypes( name )

end
