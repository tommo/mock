module 'mock'

CLASS: AnimatorTrackFieldNumber ( AnimatorTrackField )

function AnimatorTrackFieldNumber:createKey( pos, context )
	local key = AnimatorKeyNumber()
	key:setPos( pos )
	local target = context.target
	key:setValue( self.targetField:getValue( target ) )
	return self:addKey( key )
end

function AnimatorTrackFieldNumber:getIcon()
	return 'track_number'
end
