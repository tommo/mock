module 'character'

--------------------------------------------------------------------
CLASS: EventSpineAnimation ( CharacterActionEvent )
	:MODEL{
		Field 'clip' :string()
	}

function EventSpineAnimation:__init()
	self.clip = ''
end

function EventSpineAnimation:onStart( target, pos )
	if self.clip == '' then
		return target:stopAnim()
	end
	target:playAnim( self.clip )
end

function EventSpineAnimation:toString()
	return 'anim'
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
