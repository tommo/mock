module 'character'

--------------------------------------------------------------------
CLASS: EventTrailFX ( CharacterActionEvent )
	:MODEL{
		-- Field 'trailType' :enum( EnumTrailType );		
	}

function EventTrailFX:__init()
	self.origin = { 0,0 }
	self.angle0 = 0
	self.delta  = 90
	self.easeType = MOAIEaseType.EASE_IN
end

function EventTrailFX:onStart( state )
end


--------------------------------------------------------------------
CLASS: EventTrailFXArc ( EventTrailFX )
	:MODEL {
		Field 'origin' :type('vec2') :tuple_getset();
		Field 'angle0' :range( 0, 360 ) :widget( 'slider' );
		Field 'delta' ;
		Field 'easeType' :enum( EnumEaseType );
	}

function EventTrailFXArc:start( state, pos )
	
end

--
function EventTrailFXArc:onBuildGizmo()
	local giz = mock_edit.SimpleBoundGizmo()
	giz:setTarget( self )
	linkLoc( giz:getProp(), self.transform )
	linkRot( giz:getProp(), self.transform )
	return giz
end

function EventTrailFXArc:drawBounds()
	MOAIDraw.drawEmitter( 0,0 )
end
--------------------------------------------------------------------
CLASS: TrackTrailFX ( CharacterActionTrack )
	:MODEL{}

function TrackTrailFX:__init()
	self.name = 'trailFX'
end

function TrackTrailFX:getType()
	return 'trailFX'
end

function TrackTrailFX:createEvent( evType )
	if evType == 'arc' then
		return EventTrailFXArc()
	else
		return EventTrailFXCurve()
	end
end

function TrackTrailFX:toString()
	return '<trail>'.. tostring( self.name )
end

--------------------------------------------------------------------
registerCharacterActionTrackType( 'TrailFX', TrackTrailFX )
