module 'mock'

CLASS: AnimatorTrackFieldBoolean ( AnimatorTrackField )

function AnimatorTrackFieldBoolean:createKey( pos, context )
	local key = AnimatorKeyBoolean()
	key:setPos( pos )
	local target = context.target
	key:setValue( self.targetField:getValue( target ) )
	return self:addKey( key )
end

function AnimatorTrackFieldBoolean:getIcon()
	return 'track_boolean'
end

function AnimatorTrackFieldBoolean:apply( state, target, t )
	local value = self.curve:getValueAtTime( t )
	return self.targetField:setValue( target, value == 1 )
end
