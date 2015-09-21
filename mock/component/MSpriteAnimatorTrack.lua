module 'mock'


--------------------------------------------------------------------
CLASS: MSpriteAnimatorKey ( AnimatorEventKey )
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
CLASS: MSpriteAnimatorTrack ( AnimatorEventTrack )
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

function MSpriteAnimatorTrack:apply( state, playContext, t, t0 )
	local spanId  = self.spanCurve:getValueAtTime( t )
	local key     = self.keys[ spanId ]
	local subTime = ( t - key.pos ) * key.FPS
	local sprite  = playContext.sprite
	local animState = playContext[ spanId ]
	animState:setTime( subTime )
	local conv = animState.timeConverter
	if conv then
		subTime = conv( subTime, animState.length )
		animState:apply( subTime )
	end
	animState:apply( subTime )
end

local max = math.max
local floor = math.floor

--TODO: optimization using C++
local function mapTimeReverse( t0, length )
	return max( length - t0, 0 )
end

local function mapTimeReverseContinue( t0, length )
	return length - t0
end

local function mapTimeReverseLoop( t0, length )
	t0 = t0 % length
	return length - t0
end

local function mapTimePingPong( t0, length )
	local span = floor( t0 / length )
	t0 = t0 % length
	if span % 2 == 0 then --ping
		return t0
	else
		return length - t0
	end
end

local function mapTimeLoop( t0, length )
	return t0 % length
end

local timeMapFuncs = {
	[MOAITimer.NORMAL]           = false;
  [MOAITimer.REVERSE]          = mapTimeReverse;
  [MOAITimer.CONTINUE]         = false;
  [MOAITimer.CONTINUE_REVERSE] = mapTimeReverseContinue;
  [MOAITimer.LOOP]             = mapTimeLoop;
  [MOAITimer.LOOP_REVERSE]     = mapTimeReverseLoop;
  [MOAITimer.PING_PONG]        = mapTimePingPong;
}

function MSpriteAnimatorTrack:onStateLoad( state )
	local rootEntity, scene = state:getTargetRoot()
	local sprite = self.targetPath:get( rootEntity, scene )
	local playContext = { sprite = sprite }
	for i, key in ipairs( self.keys ) do
		local animState, clip = sprite:createAnimState( key.clip, key.playMode )
		animState.timeConverter = timeMapFuncs[ key.playMode ]
		animState.length = clip.length
		playContext[ i ] = animState
	end
	state:addUpdateListenerTrack( self, playContext )
end



--------------------------------------------------------------------
registerCustomAnimatorTrackType( MSprite, 'clips', MSpriteAnimatorTrack )
