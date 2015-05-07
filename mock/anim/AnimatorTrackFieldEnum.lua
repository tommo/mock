module 'mock'

CLASS: AnimatorKeyFieldEnum ( AnimatorKey )
	:MODEL{
		Field 'value' :selection( 'getTargetFieldEnumItems' ) :string(); --Variation
	}

function AnimatorKeyFieldEnum:__init()
	self.value = false
end

function AnimatorKeyFieldEnum:setValue( value )
	self.value = value
end

function AnimatorKeyFieldEnum:getTargetFieldEnumItems()
	local field = self:getTrack().targetField
	local enum = field.__enum
	return enum
end

--------------------------------------------------------------------
CLASS: AnimatorTrackFieldEnum ( AnimatorTrackFieldDiscrete )

function AnimatorTrackFieldEnum:createKey( pos, context )
	local key = AnimatorKeyFieldEnum()
	key:setPos( pos )
	local target = context.target
	key:setValue( self.targetField:getValue( target ) )
	return self:addKey( key )
end

function AnimatorTrackFieldEnum:getIcon()
	return 'track_enum'
end
