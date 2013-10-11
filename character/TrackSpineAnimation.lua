module 'character'

--------------------------------------------------------------------
CLASS: EventSpineAnimation ( CharacterActionEvent )
	:MODEL{
		Field 'clip' :string()
	}

function EventSpineAnimation:__init()
	self.length = 1
	self.clip   = ''
end

function EventSpineAnimation:onStart( target, pos )
	if self.clip == '' then
		return target:stopAnim()
	end
	target:playAnim( self.clip )
end

function EventSpineAnimation:toString()
	return tostring( self.clip )
end

function EventSpineAnimation:setClip( name )
	self.clip = name
end
--------------------------------------------------------------------
CLASS: TrackSpineAnimation ( CharacterActionTrack )
	:MODEL{}

function TrackSpineAnimation:createEvent()
	return EventSpineAnimation()
end

function TrackSpineAnimation:toString()
	return '<spine>' .. tostring( self.name )
end
--------------------------------------------------------------------
registerCharacterActionTrackType( 'Spine Animation', TrackSpineAnimation )
