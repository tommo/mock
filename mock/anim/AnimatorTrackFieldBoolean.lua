module 'mock'

--------------------------------------------------------------------
CLASS: AnimatorTrackFieldBoolean ( AnimatorTrackFieldDiscrete )

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
