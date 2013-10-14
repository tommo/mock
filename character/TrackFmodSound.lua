module 'character'

local function fixpath(p)
	p=string.gsub(p,'\\','/')
	return p
end

local function stripExt(p)
	return string.gsub( p, '%..*$', '' )
end

local function stripDir(p)
	p=fixpath(p)
	return string.match(p, "[^\\/]+$")
end

--------------------------------------------------------------------
CLASS: EventFmodSound ( CharacterActionEvent )
	:MODEL{
		Field 'sound' :asset( 'fmod_event' );
		Field 'loop'  :boolean();
	}
function EventFmodSound:__init()
	self.length = 0
	self.loop   = false
end

function EventFmodSound:onStart( target, pos )
	if self.sound then 
		target.soundSource:playEvent2D( self.sound, self.loop )
	end
end

function EventFmodSound:toString()
	if not self.sound then return '<nil>' end
	local name = stripDir( self.sound )
	return self.loop and '<loop>'..name or name
end

--------------------------------------------------------------------
CLASS: TrackFmodSound ( CharacterActionTrack )
	:MODEL{}

function TrackFmodSound:getType()
	return 'fmod_sound'
end

function TrackFmodSound:createEvent()
	return EventFmodSound()
end

function TrackFmodSound:toString()
	return '<fmod>' .. tostring( self.name )
end
--------------------------------------------------------------------
registerCharacterActionTrackType( 'Fmod Sound', TrackFmodSound )
