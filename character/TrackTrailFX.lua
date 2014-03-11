module 'character'

--------------------------------------------------------------------
CLASS: EventTrailFX ( CharacterActionEvent )
	:MODEL{
		Field 'texture'  :asset('texture');
		Field 'blend'    :enum( mock.EnumBlendMode );
		Field 'easeType' :enum( mock.EnumEaseType );
		'----';
		Field 'loc' :type('vec3') :getset('Loc');
	}

function EventTrailFX:__init()
	self.easeType = MOAIEaseType.EASE_IN
	self.transform = MOAITransform.new()
	self.texture = false
	self.blend = 'add'
end

function EventTrailFX:onStart( state )
end

function EventTrailFX:isResizable()
	return true
end

function EventTrailFX:getLoc()
	return self.transform:getLoc()
end

function EventTrailFX:setLoc( x,y,z )
	return self.transform:setLoc( x,y,z )
end

--------------------------------------------------------------------
CLASS: EventTrailFXArc ( EventTrailFX )
	:MODEL {
		Field 'radius' ;
		Field 'trailLength' ;
		Field 'angle0' :range( 0, 360 ) :widget( 'slider' );
		Field 'delta'  :range( 0, 360 ) :widget( 'slider' );
	}
function EventTrailFXArc:__init()
	self.radius      = 100
	self.trailLength = 70
	self.angle0 = 0
	self.delta = 90
end

function EventTrailFXArc:start( state, pos )	
end

function EventTrailFXArc:onBuildGizmo()
	local giz = mock_edit.SimpleBoundGizmo()
	giz:setTarget( self )
	linkLoc( giz:getProp(), self.transform )
	linkScl( giz:getProp(), self.transform )
	linkRot( giz:getProp(), self.transform )
	return giz
end

local setColor = MOAIGfxDevice.setPenColor
local setWidth = MOAIGfxDevice.setPenWidth
local function drawSectionDeckGizmo( x,y, radius, length, a0, delta )
	setWidth( 1 )
	MOAIDraw.drawCircle( 0,0, 5 )
	setColor( 1,0,1 )
	local a1 = a0 + delta
	MOAIDraw.drawArc( 0,0, radius, a0, a1 )
	MOAIDraw.drawArc( 0,0, radius-length, a0, a1 )
	setColor( .5,.2,0 )
	MOAIDraw.drawRadialLine( 0,0, a0, radius-length, radius )
	setWidth( 2 )
	setColor( 1,1,0 )
	MOAIDraw.drawRadialLine( 0,0, a1, radius-length, radius )
	setWidth( 1 )
end

function EventTrailFXArc:drawBounds()
	local x,y = self:getLoc()
	drawSectionDeckGizmo( x,y, self.radius, self.trailLength, self.angle0, self.delta )
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

function TrackTrailFX:getEventTypes()
	return { 'arc', 'trail' }
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
