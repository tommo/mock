module 'character'

--------------------------------------------------------------------
CLASS: EventMessage ( CharacterActionEvent )
	:MODEL{
		Field 'message' :string()
	}
function EventMessage:__init()
	self.length = 0
	self.name   = 'message'
end

function EventMessage:isResizable()
	return true
end

function EventMessage:onStart( target, pos )
	target:tell( self.message, self )
end

function EventMessage:toString()
	return tostring( self.message )
end


--------------------------------------------------------------------
CLASS: TrackMessage ( CharacterActionTrack )
	:MODEL{}

function TrackMessage:getType()
	return 'message'
end

function TrackMessage:createEvent()
	return EventMessage()
end

function TrackMessage:toString()
	return '<msg>' .. tostring( self.name )
end
--------------------------------------------------------------------
registerCharacterActionTrackType( 'Message', TrackMessage )
