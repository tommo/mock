module 'mock'


--------------------------------------------------------------------
CLASS: MSpriteAnimatorKey ( AnimatorKey )
	:MODEL{
		Field 'clip'  :string() :selection( 'getClipNames' ) :set( 'setClip' );
		Field 'playMode' :enum( EnumTimerMode );
		Field 'FPS'   :int();
	}

function MSpriteAnimatorKey:__init()
	self.FPS = 10
	self.clip = 'default'
	self.playMode = MOAITimer.NORMAL
end

function MSpriteAnimatorKey:getClipNames()
	local msprite = self:getTrack():getEditorTargetObject()
	return msprite:getClipNames()
end

function MSpriteAnimatorKey:setClip( clip )
	self.clip = clip
end

--------------------------------------------------------------------
CLASS: MSpriteAnimatorTrack ( CustomAnimatorTrack )
	:MODEL{
	}

function MSpriteAnimatorTrack:getIcon()
	return 'track_anim'
end

function MSpriteAnimatorTrack:toString()
	local pathText = self.targetPath:toString()
	return pathText..'<clips>'
end


function MSpriteAnimatorTrack:createKey( pos, context )
	local key = MSpriteAnimatorKey()
	key:setPos( pos )
	self:addKey( key )
	local target = context.target --MSprite
	key.clip     = target.default
	key.FPS      = target:getFPS()
	-- key.playMode = target.autoPlayMode
	return key
end

function MSpriteAnimatorTrack:build( context )
	self:sortKeys()
	local count = #self.keys
	local spanCurve    = MOAIAnimCurve.new()
	spanCurve:reserveKeys( count )
	for i = 1, count do
		local key = self.keys[ i ]
		spanCurve   :setKey( i, key.pos, i,  MOAIEaseType.FLAT )
	end
	self.spanCurve    = spanCurve
	context:updateLength( self:calcLength() )
end

function MSpriteAnimatorTrack:apply( state, playContext, t )
	local spanId  = self.spanCurve:getValueAtTime( t )
	local key     = self.keys[ spanId ]
	local subTime = ( t - key.pos ) * key.FPS
	local sprite  = playContext.sprite
	local animState = playContext[ spanId ]
	animState:setTime( subTime )
	animState:apply( animState:getTime() )
end

function MSpriteAnimatorTrack:onStateLoad( state )
	local rootEntity, scene = state:getTargetRoot()
	local sprite = self.targetPath:get( rootEntity, scene )
	local playContext = { sprite = sprite }
	for i, key in ipairs( self.keys ) do
		local animState = sprite:createAnimState( key.clip, key.playMode )
		playContext[ i ] = animState
	end
	state:addUpdateListenerTrack( self, playContext )
end

--------------------------------------------------------------------
registerCustomAnimatorTrackType( MSprite, 'clips', MSpriteAnimatorTrack )
