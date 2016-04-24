module 'mock'

CLASS: AnimatorTrackVecComponent ( AnimatorValueTrack )
	:MODEL {
		Field 'comId' :int() :no_edit();
	}
--------------------------------------------------------------------
function AnimatorTrackVecComponent:__init( comId, name )
	self.comId = comId
	self.name = name
end

function AnimatorTrackVecComponent:createKey( pos )
	local key = AnimatorKeyNumber( pos )
	key:setPos( pos )
	return self:addKey( key )
end

function AnimatorTrackVecComponent:isPlayable()
	return false
end

function AnimatorTrackVecComponent:getIcon()
	return 'track_number'
end

function AnimatorTrackVecComponent:isCurveTrack()
	return true
end

function AnimatorTrackVecComponent:canReparent( target )
	return false
end


--------------------------------------------------------------------
CLASS: AnimatorTrackFieldVecCommon ( AnimatorTrackField )

function AnimatorTrackFieldVecCommon:__init()
	self.splitted = false
end

function AnimatorTrackFieldVecCommon:getComponentCount()
	return 1
end

function AnimatorTrackFieldVecCommon:getComponentTrack( id )
	for i, sub in ipairs( self.children ) do
		if sub.comId == id then return sub end
	end
	return nil
end

function AnimatorTrackFieldVecCommon:createSubComponentTrack( id, name )
	local track = AnimatorTrackVecComponent( id, name )
	self:addChild( track )
end

function AnimatorTrackFieldVecCommon:createKey( pos, context )
	local target = context.target
	local x,y,z = self.targetField:getValue( target )
	local keyX = self:createSubComponentTrackKey( 1, pos, x )
	local keyY = self:createSubComponentTrackKey( 2, pos, y )
	local keyZ = self:createSubComponentTrackKey( 3, pos, z )
	return keyX, keyY, keyZ
end

function AnimatorTrackFieldVecCommon:createSubComponentTrackKey( comId, pos, value )
	local track = self:getComponentTrack( comId )
	local key = track:createKey( pos )
	key:setValue( value )
	return key
end

function AnimatorTrackFieldVecCommon:updateParentKey( parentKey, changedKey )
	local childKeys = parentKey:getChildKeys()
	if not childKeys then return end
	local vec = {}
	for i, k in ipairs( childKeys ) do
		local childTrack = k:getTrack()
		local comId = childTrack.comId
		vec[ comId ] = k.value
		k.pos = parentKey.pos
	end
	parentKey:setValue( unpack( vec ) )

end

function AnimatorTrackFieldVecCommon:updateChildKeys( parentKey )
	local childKeys = parentKey:getChildKeys()
	if not childKeys then return end
	local vec = { parentKey:getValue() }
	for i, k in ipairs( childKeys ) do
		local childTrack = k:getTrack()
		local comId = childTrack.comId
		k.value = vec[ i ]
		k.pos = parentKey.pos
	end
end


function AnimatorTrackFieldVecCommon:unsplitKeys()
	if not self.splitted then return end
	self.splitted = false
	local keys = {}
end

function AnimatorTrackFieldVecCommon:splitKeys()
	if self.splitted then return end
	self.splitted = true
	self.keys = {}
end

function AnimatorTrackFieldVecCommon:apply( state, target, t )
	local x = self.curveX:getValueAtTime( t )
	local y = self.curveY:getValueAtTime( t )
	local z = self.curveZ:getValueAtTime( t )
	return self.targetField:setValue( target, x, y, z )
end

function AnimatorTrackFieldVecCommon:isEmpty()
	return
		self:getComponentTrack(1):isEmpty() and
		self:getComponentTrack(2):isEmpty() and
		self:getComponentTrack(3):isEmpty()
end

function AnimatorTrackFieldVecCommon:build( context ) --building shared data
	self.curveX = self:getComponentTrack( 1 ):buildCurve()
	self.curveY = self:getComponentTrack( 2 ):buildCurve()
	self.curveZ = self:getComponentTrack( 3 ):buildCurve()
	context:updateLength( self:calcLength() )
end

function AnimatorTrackFieldVecCommon:calcLength()
	local length = math.max( 
		self:getComponentTrack(1):calcLength(), 
		self:getComponentTrack(2):calcLength(), 
		self:getComponentTrack(3):calcLength()
	)
	return length
end

function AnimatorTrackFieldVecCommon:getIcon()
	return 'track_vec'
end

--------------------------------------------------------------------
CLASS: AnimatorTrackFieldVec3 ( AnimatorTrackFieldVecCommon )
function AnimatorTrackFieldVec3:init()
	--create sub component track
	self:createSubComponentTrack( 1, 'x' )
	self:createSubComponentTrack( 2, 'y' )
	self:createSubComponentTrack( 3, 'z' )
end

function AnimatorTrackFieldVec3:getComponentCount()
	return 3
end

function AnimatorTrackFieldVec3:createKey( pos, context )
	local target = context.target
	local x,y,z = self.targetField:getValue( target )
	local keyX = self:createSubComponentTrackKey( 1, pos, x )
	local keyY = self:createSubComponentTrackKey( 2, pos, y )
	local keyZ = self:createSubComponentTrackKey( 3, pos, z )
	local masterKey = AnimatorKeyVec3()
	masterKey.pos = pos
	masterKey:addChildKey( keyX )
	masterKey:addChildKey( keyY )
	masterKey:addChildKey( keyZ )
	masterKey:setValue( x,y,z )
	self:addKey( masterKey )
	return masterKey, keyX, keyY, keyZ
end

function AnimatorTrackFieldVec3:apply( state, target, t )
	local x = self.curveX:getValueAtTime( t )
	local y = self.curveY:getValueAtTime( t )
	local z = self.curveZ:getValueAtTime( t )
	return self.targetField:setValue( target, x, y, z )
end

function AnimatorTrackFieldVec3:build( context ) --building shared data
	self.curveX = self:getComponentTrack( 1 ):buildCurve()
	self.curveY = self:getComponentTrack( 2 ):buildCurve()
	self.curveZ = self:getComponentTrack( 3 ):buildCurve()
	context:updateLength( self:calcLength() )
end

function AnimatorTrackFieldVec3:calcLength()
	local length = math.max( 
		self:getComponentTrack(1):calcLength(), 
		self:getComponentTrack(2):calcLength(), 
		self:getComponentTrack(3):calcLength()
	)
	return length
end

function AnimatorTrackFieldVec3:getIcon()
	return 'track_vec3'
end

function AnimatorTrackFieldVec3:isEmpty()
	return
		self:getComponentTrack(1):isEmpty() and
		self:getComponentTrack(2):isEmpty() and
		self:getComponentTrack(3):isEmpty()
end

--------------------------------------------------------------------
CLASS: AnimatorTrackFieldVec2 ( AnimatorTrackFieldVecCommon )
function AnimatorTrackFieldVec2:init()
	--create sub component track
	self:createSubComponentTrack( 1, 'x' )
	self:createSubComponentTrack( 2, 'y' )
end

function AnimatorTrackFieldVec3:getComponentCount()
	return 2
end

function AnimatorTrackFieldVec2:createKey( pos, context )
	local target = context.target
	local x,y = self.targetField:getValue( target )
	local keyX = self:createSubComponentTrackKey( 1, pos, x )
	local keyY = self:createSubComponentTrackKey( 2, pos, y )
	local masterKey = AnimatorKeyVec2()
	masterKey.pos = pos
	masterKey:addChildKey( keyX )
	masterKey:addChildKey( keyY )
	masterKey:setValue( x,y )
	self:addKey( masterKey )
	return masterKey, keyX, keyY
end

function AnimatorTrackFieldVec2:apply( state, target, t )
	local x = self.curveX:getValueAtTime( t )
	local y = self.curveY:getValueAtTime( t )
	return self.targetField:setValue( target, x, y )
end

function AnimatorTrackFieldVec2:build( context ) --building shared data
	self.curveX = self:getComponentTrack( 1 ):buildCurve()
	self.curveY = self:getComponentTrack( 2 ):buildCurve()
	context:updateLength( self:calcLength() )
end

function AnimatorTrackFieldVec2:isEmpty()
	return
		self:getComponentTrack(1):isEmpty() and
		self:getComponentTrack(2):isEmpty()
end

function AnimatorTrackFieldVec2:calcLength()
	local length = math.max( 
		self:getComponentTrack(1):calcLength(), 
		self:getComponentTrack(2):calcLength()
	)
	return length
end
