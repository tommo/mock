module 'character'

--------------------------------------------------------------------
CLASS: EventMessage ( CharacterActionEvent )
	:MODEL{
		Field 'message' :string();
		Field 'arg'     :string()
	}
function EventMessage:__init()
	self.length = 0
	self.name   = 'message'
	self.arg    = false
end

function EventMessage:isResizable()
	return true
end

function EventMessage:start( state, pos )
	state.target:tell( self.message, self )
end

function EventMessage:toString()
	return tostring( self.message )
end


--------------------------------------------------------------------
CLASS: TrackMessage ( CharacterActionTrack )
	:MODEL{}

function TrackMessage:__init()
	self.name = 'message'
end

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
