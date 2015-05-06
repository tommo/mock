module 'mock'

CLASS: AnimatorTrackFieldEnum ( AnimatorTrackField )

function AnimatorTrackFieldEnum:createKey( pos, context )
	local key = AnimatorKeyEnum()
	key:setPos( pos )
	local target = context.target
	key:setValue( self.targetField:getValue( target ) )
	return self:addKey( key )
end

function AnimatorTrackFieldEnum:getIcon()
	return 'track_boolean'
end

function AnimatorTrackFieldEnum:apply( state, target, t )
	local value = self.curve:getValueAtTime( t )
	return self.targetField:setValue( target, value == 1 )
end
