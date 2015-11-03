module 'mock'

CLASS: AnimatorTrackFieldInt ( AnimatorTrackField )


function AnimatorTrackFieldInt:hasCurve()
	return true
end

function AnimatorTrackFieldInt:createKey( pos, context )
	local key = AnimatorKeyInt()
	key:setPos( pos )
	local target = context.target
	key:setValue( self.targetField:getValue( target ) )
	return self:addKey( key )
end

function AnimatorTrackFieldInt:getIcon()
	return 'track_number'
end

local floor = math.floor
function AnimatorTrackFieldInt:apply( state, target, t )
	local value = floor( self.curve:getValueAtTime( t ) )
	return self.targetField:setValue( target, value )
end