module 'mock'

CLASS: AnimatorKey ()
CLASS: AnimatorTrack ()
CLASS: AnimatorClip ()

--------------------------------------------------------------------
AnimatorKey
:MODEL{		
		Field 'pos'    :int() :range(0)  :getset('Pos');
		Field 'length' :int() :range(0)  :getset('Length');
		Field 'tweenMode'      :enum( EnumAnimCurveTweenMode );
		Field 'tweenAnglePre'  :enum( EnumAnimCurveTweenMode ) :no_edit();		
		Field 'tweenAnglePost' :enum( EnumAnimCurveTweenMode ) :no_edit();		
		Field 'parent' :type( AnimatorTrack ) :no_edit();		
	}

function AnimatorKey:__init()
	self.pos    = 0
	self.length = 10
	----
	self.tweenMode = 0 --LINEAR
	self.tweenAnglePre  = 0
	self.tweenAnglePost = 0
end

function AnimatorKey:getTweenCurveNormal()
	local a0, a1 = self.tweenAnglePre, self.tweenAnglePost
	local nx0 = math.cosd( a0 )
	local ny0 = math.sind( a0 )
	local nx1 = math.cosd( a1 )
	local ny1 = math.sind( a1 )
	return nx0, ny0, nx1, ny1
end

function AnimatorKey:findNextKey( allowWrap )
	-- self.parent:sortKeys()
	local action = self:getAction()	
	local wrap = allowWrap ~= false and action.loop
	local keys = self.parent.keys
	local pos0 = self.pos
	local pos = false
	local res = nil
	for i, e in ipairs( keys ) do
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
		return keys[1]
	end
	return nil
end

function AnimatorKey:start( state, pos )
end

function AnimatorKey:setPos( pos )
	self.pos = pos
end

function AnimatorKey:isResizable()
	return false
end

function AnimatorKey:getPos()
	return self.pos
end

function AnimatorKey:getKeyFramePos()
	return self.pos
end

function AnimatorKey:setLength( length )
	self.length = length
end

function AnimatorKey:getLength()
	return self.length
end

function AnimatorKey:getEnd()
	return self.pos + self.length
end

function AnimatorKey:getTrack()
	return self.parent
end

function AnimatorKey:getAction()	
	local track = self.parent
	return track and track.parent
end

function AnimatorKey:getRootConfig()
	local track = self.parent
	if track then
		local action = track.parent
		if action then return action.parent end
	end
	return nil
end

function AnimatorKey:setTweenMode( mode )
	self.tweenMode = mode
end

--------------------------------------------------------------------
--VIRTUAL
function AnimatorKey:getCurveValue()
	return 0
end

function AnimatorKey:toString()
	return 'key'
end


--------------------------------------------------------------------
AnimatorTrack
:MODEL{
		Field 'name' :string();		
		Field 'keys' :array( AnimatorKey ) :no_edit() :sub();		
		Field 'parent' :type( AnimatorClip ) :no_edit();
		Field 'enabled' :boolean();
	}

function AnimatorTrack:__init()
	self.name = 'track'
	self.keys = {}
	self.enabled = true
end

function AnimatorTrack:getType()
	return 'track'
end

function AnimatorTrack:toString()
	return self.name
end

function AnimatorTrack:getAction()
	return self.parent
end

function AnimatorTrack:getRootConfig()
	local action = self.parent
	return action and action.parent
end
--------------------------------------------------------------------

function AnimatorTrack:addKey( pos, evType )
	evType = evType or self:getDefaultKeyType()
	local ev = self:createKey( evType )
	table.insert( self.keys, ev )
	ev.parent = self
	ev.pos = pos or 0
	return ev
end

function AnimatorTrack:removeKey( ev )
	for i, e in ipairs( self.keys ) do
		if e == ev then 
			table.remove( self.keys, i )
			return true
		 end
	end	
	return false
end

function AnimatorTrack:cloneKey( ev )
	local newEv = mock.clone( ev )
	table.insert( self.keys, newEv )
	newEv.parent = self
	newEv.pos = ev.pos + ev.length
	return newEv	
end

local function _sortKey( o1, o2 )
	return o1.pos < o2.pos
end

function AnimatorTrack:sortKeys()
	table.sort( self.keys, _sortKey )
end

function AnimatorTrack:calcLength()
	local l = 0
	for i, e in ipairs( self.keys ) do
		local l1 = e:getEnd()
		if l1>l then l = l1 end
	end
	return l
end

function AnimatorTrack:getFirstKey()
	return self.keys[ 1 ]
end

function AnimatorTrack:getLastKey()
	local l = #self.keys
	if l > 0 then
		return self.keys[ l ]
	end
	return nil
end

--------------------------------------------------------------------
--VIRTUAL Functions
--whether build keyframe using key from the track
function AnimatorTrack:hasKeyFrames() 
	return true
end

--Key Factory
function AnimatorTrack:createKey()
	return AnimatorKey()
end

--for multiple key type support
function AnimatorTrack:getKeyTypes()
	return false
end

function AnimatorTrack:getDefaultKeyType()
	return false
end

function AnimatorTrack:buildCurve()
	self:sortKeys()
	local spanPoints = {}
	local spanSet    = {}
	local keys = self.keys
	local curve = MOAIAnimCurveEX.new()
	curve:reserveKeys( #keys )
	for i, key in ipairs( keys ) do
		local t = key:getPos()
		local v = key:getCurveValue()
		curve:setKey( i, t, v )
		curve:setKeyMode( i, key.tweenMode )
		curve:setKeyParam( i, key:getTweenCurveNormal() )
	end
	return curve
end

--(pre)build
function AnimatorTrack:buildStateData( stateData ) 
end
--(clean)build
function AnimatorTrack:clearStateData( stateData ) 
end

function AnimatorTrack:setThrottle( state, th )
end

function AnimatorTrack:start( state )
end

function AnimatorTrack:stop( state )
end

function AnimatorTrack:pause( state, paused )
end

function AnimatorTrack:apply( state, t )
end

function AnimatorTrack:apply2( state, t0, t1 )
end

--------------------------------------------------------------------
AnimatorClip	:MODEL{
		Field 'name' :string();		
		Field 'loop' :boolean();
		Field 'length' :int();
		Field 'tracks' :array( AnimatorTrack ) :no_edit() :sub();		
		Field 'inherited' :boolean() :no_edit();
		'----';
		Field 'comment' :string();
	}

function AnimatorClip:__init()
	self.name      = 'action'
	self.tracks    = {}
	self.stateData = false
	self.loop      = false
	self.length    = -1
	self.inherited = false
end

function AnimatorClip:addTrack( t )
	local track = t or AnimatorTrack()
	table.insert( self.tracks, track )
	track.parent = self
	return track
end

function AnimatorClip:removeTrack( track )
	for i, t in ipairs( self.tracks ) do
		if t == track then return table.remove( self.tracks, i )  end
	end	
end

function AnimatorClip:findTrack( name, trackType )
	for i, t in ipairs( self.tracks ) do
		if t.name == name then
			if not trackType or t:getType() == trackType then return t end
		end
	end
end

function AnimatorClip:findTrackByType( trackType )
	for i, t in ipairs( self.tracks ) do
		if t:getType() == trackType then return t end
	end
	return nil
end

function AnimatorClip:calcLength()
	local length = 0
	for i, track in ipairs( self.tracks ) do
		track:buildStateData( stateData )
		local l = track:calcLength()
		if l>length then length = l end
	end
	return length
end

--------------------------------------------------------------------
function AnimatorClip:getStateData()	
	return self.stateData or self:buildStateData()
end

function AnimatorClip:buildStateData()
	stateData = {}
	stateData.length   = self:calcLength()
	stateData.keyCurve = self:_buildKeyCurve()
	self.stateData = stateData
	return stateData
end

function AnimatorClip:clearStateData()
	for i, track in ipairs( self.tracks ) do
		track:clearStateData( stateData )
	end
	self.stateData = false
end

function AnimatorClip:_buildKeyCurve()
	local spanPoints = {}
	local spanSet    = {}
	local spanList   = {}
	for i, track in ipairs( self.tracks ) do
		track:sortKeys()
		if track:hasKeyFrames() then
			for i, key in ipairs( track.keys ) do
				local pos = key:getKeyFramePos()
				if pos<0 then pos = 0 end
				local t = spanSet[ pos ]
				if not t then 
					t = {}
					spanSet[ pos ] = t
					table.insert( spanPoints, pos )
				end
				table.insert( t, key )
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

local _TrackTypes = {}
function getAnimatorTrackTypeTable()
	return _TrackTypes
end

function registerAnimatorTrackType( name, trackClas, eventTypes )
	if _TrackTypes[ name ] then
		_warn( 'duplicated action track type', name )
	end
	_TrackTypes[ name ] = {
		clas = trackClas,
		eventTypes = eventTypes
	}
end

function getAnimatorTrackType( name )
	local entry = _TrackTypes[ name ]
	return entry and entry.clas
end

function getAnimatorTrackEventTypes( name )

end
