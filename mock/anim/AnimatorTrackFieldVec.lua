module 'mock'

CLASS: AnimatorTrackVecComponent ( AnimatorTrack )
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


function AnimatorTrackVecComponent:hasCurve()
	return true
end



--------------------------------------------------------------------
CLASS: AnimatorTrackFieldVecCommon ( AnimatorTrackField )
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

function AnimatorTrackFieldVecCommon:apply( state, target, t )
	local x = self.curveX:getValueAtTime( t )
	local y = self.curveY:getValueAtTime( t )
	local z = self.curveZ:getValueAtTime( t )
	return self.targetField:setValue( target, x, y, z )
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
function AnimatorTrackFieldVec3:onInit()
	--create sub component track
	self:createSubComponentTrack( 1, 'x' )
	self:createSubComponentTrack( 2, 'y' )
	self:createSubComponentTrack( 3, 'z' )
end

function AnimatorTrackFieldVec3:createKey( pos, context )
	local target = context.target
	local x,y,z = self.targetField:getValue( target )
	local keyX = self:createSubComponentTrackKey( 1, pos, x )
	local keyY = self:createSubComponentTrackKey( 2, pos, y )
	local keyZ = self:createSubComponentTrackKey( 3, pos, z )
	return keyX, keyY, keyZ
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


--------------------------------------------------------------------
CLASS: AnimatorTrackFieldVec2 ( AnimatorTrackFieldVecCommon )
function AnimatorTrackFieldVec2:onInit()
	--create sub component track
	self:createSubComponentTrack( 1, 'x' )
	self:createSubComponentTrack( 2, 'y' )
end

function AnimatorTrackFieldVec2:createKey( pos, context )
	local target = context.target
	local x,y,z = self.targetField:getValue( target )
	local keyX = self:createSubComponentTrackKey( 1, pos, x )
	local keyY = self:createSubComponentTrackKey( 2, pos, y )
	return keyX, keyY, keyZ
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

function AnimatorTrackFieldVec2:calcLength()
	local length = math.max( 
		self:getComponentTrack(1):calcLength(), 
		self:getComponentTrack(2):calcLength()
	)
	return length
end
