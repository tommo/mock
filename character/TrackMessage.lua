module 'character'

CLASS: EventMessage ( CharacterActionEvent )
	:MODEL{
		Field 'message' :string()
	}

CLASS: TrackMessage ( CharacterActionTrack )
	:MODEL{}

function TrackMessage:addEvent()
end