module 'mock'

local insert = table.insert

--------------------------------------------------------------------
CLASS: AnimatorKey ()
CLASS: AnimatorClipSubNode ()
CLASS: AnimatorTrackGroup ( AnimatorClipSubNode )
CLASS: AnimatorTrack ( AnimatorClipSubNode )
CLASS: AnimatorClip ()

--------------------------------------------------------------------
AnimatorKey
:MODEL{		
		Field 'pos'    :float() :range(0)  :getset('Pos')      :meta{ decimals = 3, step = 0.01 };
		Field 'length' :float() :range(0)  :getset('Length')   :meta{ decimals = 3, step = 0.01 };
		Field 'tweenMode'      :enum( EnumAnimCurveTweenMode ) :no_edit();
		Field 'tweenAnglePre'  :enum( EnumAnimCurveTweenMode ) :no_edit();
		Field 'tweenAnglePost' :enum( EnumAnimCurveTweenMode ) :no_edit();
		Field 'parent' :type( AnimatorTrack ) :no_edit();		
		'----';
	}

function AnimatorKey:__init( pos, tweenMode )
	self.pos    = pos or 0
	self.length = 0
	----
	self.tweenMode = tweenMode or 0 --LINEAR
	self.tweenAnglePre  = 180
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
	for i, k in ipairs( keys ) do
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
	assert( type( pos ) == 'number' )
	self.pos = pos
end

function AnimatorKey:isResizable()
	return false
end

function AnimatorKey:getPos()
	return self.pos
end

function AnimatorKey:getPosMS()
	return math.floor( self.pos*1000 )
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

function AnimatorKey:getClip()
	-- local track = self.parent
	-- if track then
	-- 	return track:getClip()
	-- end
	-- return nil
	return self.parentClip
end

function AnimatorKey:setTweenMode( mode )
	self.tweenMode = mode
end

function AnimatorKey:setTweenAnglePre( angle )
	self.tweenAnglePre = 180 - angle
end

function AnimatorKey:setTweenAnglePost( angle )
	self.tweenAnglePost = angle
end

function AnimatorKey:executeEvent( state, time )
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
AnimatorClipSubNode
:MODEL{
	Field 'name' :string();
	Field 'parent' :type( AnimatorClipSubNode ) :no_edit();
	Field 'children' :array( AnimatorClipSubNode ) :no_edit();
	Field 'parentClip' :type( AnimatorClip ) :no_edit();
}

function AnimatorClipSubNode:__init()
	self.parent = false
	self.children = {}
	self.parentClip = false
end

function AnimatorClipSubNode:build( context )
	self:buildChildren( context )
end

function AnimatorClipSubNode:isPlayable()
	return false
end

function AnimatorClipSubNode:isPreviewable()
	return true
end

function AnimatorClipSubNode:canDelete()
	return true
end

function AnimatorClipSubNode:hasCurve()
	return false
end

function AnimatorClipSubNode:buildChildren( context )
	for _, child in ipairs( self.children ) do
		child:build( context )
		if child:isPlayable() then
			context:addPlayableTrack( child )
		end
	end
end

function AnimatorClipSubNode:getAllChildren( list )
	list = list or {} 
	for _, child in ipairs( self.children ) do
		insert( list, child )
		child:getAllChildren( list )
	end
	return list
end

function AnimatorClipSubNode:getIcon()
	return 'normal'
end

function AnimatorClipSubNode:addChild( node )
	assert( not node.parent )
	node.parent = self
	node.parentClip = self.parentClip
	insert( self.children, node )
end

function AnimatorClipSubNode:removeChild( node )
	local idx = table.index( self.children, node )
	if idx then
		table.remove( self.children, idx )
	end
end

function AnimatorClipSubNode:getChildren()
	return self.children
end

function AnimatorClipSubNode:getParent()
	return self.parent
end

function AnimatorClipSubNode:getRoot()
	local p = self
	while true do
		local pp = p.parent
		if not pp then return p end
		p = pp
	end
end

function AnimatorClipSubNode:getClip()
	-- local root = self:getRoot()
	-- return root.clip
	return self.parentClip
end

function AnimatorClipSubNode:toString()
	return 'unknown'
end

--load from deserialize
function AnimatorClipSubNode:_load()
	self:onLoad()
	for _, child in ipairs( self.children ) do
		child:_load()
	end
end

function AnimatorClipSubNode:onLoad()
end

function AnimatorClipSubNode:collectObjectRecordingState( animator, recordingState )
	for i, child in ipairs( self.children ) do
		child:collectObjectRecordingState( animator, recordingState )
	end
	self:onCollectObjectRecordingState( animator, recordingState )
end

function AnimatorClipSubNode:restoreObjectRecordingState( animator, recordingState )
	for i, child in ipairs( self.children ) do
		child:restoreObjectRecordingState( animator, recordingState )
	end
	self:onRestoreObjectRecordingState( animator, recordingState )
end


function AnimatorClipSubNode:onCollectObjectRecordingState( animator, recordingState )
end

function AnimatorClipSubNode:onRestoreObjectRecordingState( animator, recordingState )
end

updateAllSubClasses( AnimatorClipSubNode )

--------------------------------------------------------------------
AnimatorTrackGroup
:MODEL{
}

function AnimatorTrackGroup:getIcon()
	return 'group'
end

--------------------------------------------------------------------
AnimatorTrack
:MODEL{
		Field 'keys' :array( AnimatorKey ) :no_edit() :sub();		
		Field 'enabled' :boolean();
		Field 'targetPath'  :no_edit() :get( 'serializeTargetPath' ) :set( 'deserializeTargetPath' );
	}

function AnimatorTrack:__init()
	self.name = 'track'
	self.keys = {}
	self.enabled = true
	self.targetPath = AnimatorTargetPath()
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

function AnimatorTrack:setTargetPath( path )
	self.targetPath = path
end

function AnimatorTrack:serializeTargetPath()
	local data = self.targetPath:serialize()
	local jsonData = MOAIJsonParser.encode( data )
	return jsonData
end

function AnimatorTrack:deserializeTargetPath( jsonData )
	local data = MOAIJsonParser.decode( jsonData )
	self.targetPath = AnimatorTargetPath()
	self.targetPath:deserialize( data )
end

function AnimatorTrack:getTargetObject( rootEntity, scene )
	if not self.targetPath then return nil end
	scene = scene or ( rootEntity and rootEntity.scene )
	if not ( rootEntity or scene ) then return nil end
	return self.targetPath:get( rootEntity, scene )
end

function AnimatorTrack:getEditorTargetObject()
	local rootEntity, rootScene = getAnimatorEditorTarget()
	return self:getTargetObject( rootEntity, rootScene )
end

--------------------------------------------------------------------
function AnimatorTrack:createKey( pos, ... )
	--you can return multiple keys
	error( 'implement this')
end

function AnimatorTrack:addKey( key )
	insert( self.keys, key )
	key.parent = self
	return key
end

function AnimatorTrack:removeKey( key )
	for i, k in ipairs( self.keys ) do
		if e == key then 
			key.parent = false
			table.remove( self.keys, i )
			return true
		 end
	end	
	return false
end

function AnimatorTrack:cloneKey( key )
	local newKey = mock.clone( key )
	insert( self.keys, newKey )
	newKey.parent = self
	newKey.pos = key.pos + key.length
	return newKey	
end

local function _sortKey( o1, o2 )
	return o1.pos < o2.pos
end

function AnimatorTrack:sortKeys()
	table.sort( self.keys, _sortKey )
end

function AnimatorTrack:calcLength()
	local l = 0
	for i, k in ipairs( self.keys ) do
		local l1 = k:getEnd()
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

function AnimatorTrack:build( context )
end

function AnimatorTrack:onStateLoad( state )
end

--------------------------------------------------------------------
CLASS: AnimatorClipBuildContext ()
function AnimatorClipBuildContext:__init()
	self.length         = 0
	self.playableTracks = {}
	self.eventKeys      = {}
	self.attrLinkInfo   = {}
	self.attrLinkCount  = 0
end

function AnimatorClipBuildContext:updateLength( l )
	self.length = math.max( l, self.length )
end

function AnimatorClipBuildContext:reserveAttrLinks( track, count )
	local base = self.attrLinkCount + 1
	self.attrLinkCount = self.attrLinkCount + count
	return base
end

function AnimatorClipBuildContext:addPlayableTrack( track )
	self.playableTracks[ track ] = true
end

function AnimatorClipBuildContext:addEventKey( key )
	insert( self.eventKeys, key )
end

function AnimatorClipBuildContext:addEventKeyList( keys )
	for i, key in ipairs( keys ) do
		self:addEventKey( key )
	end
end

function AnimatorClipBuildContext:finish()
	--build keyframe for key events
	local keyPoints = {}
	local keySet    = {}
	local keyMap    = {}
	for i, eventKey in ipairs( self.eventKeys ) do
		local pos = eventKey:getPosMS()
		if pos<0 then pos = 0 end
		local t = keySet[ pos ]
		if not t then 
			t = {}
			keySet[ pos ] = t
			insert( keyPoints, pos )
		end
		insert( t, eventKey )
	end

	table.sort( keyPoints )
	local eventCurve = MOAIAnimCurve.new()
	eventCurve:reserveKeys( #keyPoints )
	for i, pos in ipairs( keyPoints ) do
		local time = pos/1000 --ms convert to second
		eventCurve:setKey( i, time, i ) 
		keyMap[ i ] = keySet[ pos ]
	end

	self.keyEventMap  = keyMap
	self.eventCurve   = eventCurve

end

--------------------------------------------------------------------
AnimatorClip	:MODEL{
		Field 'name' :string();		
		Field 'loop' :boolean();
		Field 'length' :int();
		Field 'inherited' :boolean() :no_edit();
		Field 'root' :type( AnimatorClipSubNode ) :no_edit();
		'----';
		Field 'comment' :string();
	}

function AnimatorClip:__init()
	self.name      = 'action'
	
	self.root      = AnimatorTrackGroup()
	self.root.parentClip = self

	self.stateData = false
	self.loop      = false
	self.length    = -1

	self.builtContext = false

	self.inherited = false
end

function AnimatorClip:getRoot()
	return self.root
end

function AnimatorClip:getTrackList()
	return self.root:getAllChildren()
end

function AnimatorClip:clearPrebuiltContext()
	self.builtContext = false
end

function AnimatorClip:getBuiltContext()
	if not self.builtContext then self:prebuild() end
	return self.builtContext
end

function AnimatorClip:prebuild()
	local playableTrackList = {}
	local buildContext = AnimatorClipBuildContext()
	self.root:build( buildContext )
	buildContext:finish()
	self.builtContext = buildContext
	self.length = buildContext.length
end

function AnimatorClip:getLength()
	return self.length
end

function AnimatorClip:collectObjectRecordingState( animator, state )
	local state = state or AnimatorRecordingState( animator )
	self.root:collectObjectRecordingState( animator, state )
	return state
end

--------------------------------------------------------------------
CLASS: AnimatorRecordingState ()

function AnimatorRecordingState:__init( animator )
	self.states = {}
	self.animator = animator
end

function AnimatorRecordingState:markFieldRecording( obj, fieldId )
	--TODO:support non field recording state
	local state = self.states[ obj ]
	if not state then
		state = {}
		self.states[ obj ] = state
	end
	local model = Model.fromObject( obj )
	if state[ fieldId ] then return end
	state[ fieldId ] = { model:getFieldValue( obj, fieldId ) }
end

function AnimatorRecordingState:applyRetainedState()
	for obj, state in pairs( self.states ) do
		local model = Model.fromObject( obj )
		for fieldId, boxedValue in pairs( state ) do
			model:setFieldValue( obj, fieldId, unpack( boxedValue ) )
		end
	end
end

function AnimatorRecordingState:restoreFieldRecording( obj, fieldId )
	local state = self.states[ obj ]
	if not state then return end
	local model = Model.fromObject( obj )
	local boxedValue = state[ fieldId ]
	if not boxedValue then return end
	model:setFieldValue( obj, fieldId, unpack( boxedValue ) )
	state[ fieldId ] = nil
end
