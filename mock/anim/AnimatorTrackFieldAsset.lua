module 'mock'

CLASS: AnimatorTrackFieldAsset ( AnimatorTrackField )

function AnimatorTrackFieldAsset:createKey( pos, context )
	local key = AnimatorKeyBoolean()
	key:setPos( pos )
	local target = context.target
	key:setValue( self.targetField:getValue( target ) )
	return self:addKey( key )
end

function AnimatorTrackFieldAsset:getIcon()
	return 'track_boolean'
end

function AnimatorTrackFieldAsset:apply( state, target, t )
	local value = self.curve:getValueAtTime( t )
	return self.targetField:setValue( target, value == 1 )
end
