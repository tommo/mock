module 'character'

--------------------------------------------------------------------
CLASS: EventTrailFX ( CharacterActionEvent )
	:MODEL{
		Field 'texture'  :asset('texture');
		Field 'color'    :type( 'color' ) :getset( 'Color' );
		Field 'blend'    :enum( mock.EnumBlendMode );
		Field 'loc' :type('vec3') :getset('Loc');
		'----';
		Field 'trailSpeed' :int() :range( 1, 10 ) :widget('slider');
	}

function EventTrailFX:__init()
	self.easeType = MOAIEaseType.EASE_IN
	self.transform = MOAITransform.new()
	self.texture = false
	self.color   = {1,1,.5,1}
	self.blend = 'add'
	self.trailSpeed = 5
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

function EventTrailFX:getColor()
	return unpack( self.color )
end

function EventTrailFX:setColor( r,g,b,a )
	self.color = { r,g,b,a }
end

--------------------------------------------------------------------
CLASS: EventTrailFXArc ( EventTrailFX )
	:MODEL {
		Field 'radius' ;
		Field 'trailLength' ;
		Field 'angle0' :range( 0, 360 ) :widget( 'slider' );
		Field 'angle1' :range( 0, 360 ) :widget( 'slider' );
	}
function EventTrailFXArc:__init()
	self.radius      = 100
	self.trailLength = 70
	self.angle0 = 0
	self.angle1 = 90
end

local function _onTrailStop( node )
	local prop = node.prop

end

local function getTextureUV( tex )
	local ttype = tex.type

	local t, uv
	if ttype == 'sub_texture' then
		t = tex.atlas
		uv = tex.uv
	elseif ttype == 'framebuffer' then
		t = tex:getMoaiFrameBuffer()
		uv = { 0,0,1,1 }
	else
		t = tex
		uv = { 0,1,1,0 }
	end

	return t, uv
end

function EventTrailFXArc:start( state, pos )
	local duration = self.length/1000 / state.throttle
	if duration == 0 then return end
	local tex = mock.loadAsset( self.texture )
	if not tex then return end
	local target = state.target
	local ent = target:getEntity()	
	--todo: cache this
	local deck = MOAISectionDeck.new()	
	local moaiTex, uv = getTextureUV( tex )
	deck:setTexture( moaiTex )
	deck:setUVRect( unpack( uv ) )
	local prop = MOAIProp.new()
	prop:setDeck( deck )
	prop:setLoc( self.transform:getLoc() )
	deck:setRadius( self.radius, self.trailLength )
	setPropBlend( prop, self.blend )
	ent:_attachProp( prop )
	prop:setColor( unpack( self.color ) )
	local a0, a1 = self.angle0, self.angle1
	deck:setSection( a0, a0, 10 )
	local delay = ( 1 - self.trailSpeed/10 ) * 4 + 1
	local action = deck:seekAngle0( a1, duration * delay, MOAIEaseType.SOFT_EASE_IN )
	deck:seekAngle1( a1, duration, MOAIEaseType.EASE_IN )	
	action:setListener( MOAIAction.EVENT_STOP, function()
		ent:_detachProp( prop )
	end
	)
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
local function drawSectionDeckGizmo( x,y, radius, length, a0, a1 )
	setWidth( 1 )
	MOAIDraw.drawCircle( 0,0, 5 )
	setColor( 1,0,1 )
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
	drawSectionDeckGizmo( x,y, self.radius, self.trailLength, self.angle0, self.angle1 )
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
