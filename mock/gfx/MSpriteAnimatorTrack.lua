module 'mock'


--------------------------------------------------------------------
CLASS: MSpriteAnimatorKey ( AnimatorEventKey )
	:MODEL{
		Field 'clip'  :string() :selection( 'getClipNames' ) :set( 'setClip' );
		Field 'playMode' :enum( EnumTimerMode );
		Field 'throttle'   :number();
		'----';
		Field 'useRange'  :boolean();
		Field 'range'     :type( 'vec2' ) :getset( 'Range' ) :meta{ decimals = 3, step = 0.01 };
		'----';
		Field 'resetLength' :action( 'resetLength' );
	}

function MSpriteAnimatorKey:__init()
	self.throttle = 1
	self.clip = 'default'
	self.playMode = MOAITimer.NORMAL
	self.useRange = false
	self.range = { 0, 0 }
end

function MSpriteAnimatorKey:getRange()
	return unpack( self.range )
end

function MSpriteAnimatorKey:setRange( mi, ma )
	self.range = { mi, ma }
end

function MSpriteAnimatorKey:getClipNames()
	local msprite = self:getTrack():getEditorTargetObject()
	return msprite:getClipNames()
end

function MSpriteAnimatorKey:setClip( clip )
	self.clip = clip
end

function MSpriteAnimatorKey:toString()
	return self.clip or '<nil>'
end

function MSpriteAnimatorKey:resetLength()
	local msprite = self:getTrack():getEditorTargetObject()
	local clipData = msprite:getClip( self.clip )
	if clipData then
		self:setLength( clipData.length / self.throttle )
	end
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
	return key
end

function MSpriteAnimatorTrack:build( context )
	self:sortKeys()
	local count = #self.keys
	local spanCurve    = MOAIAnimCurve.new()
	spanCurve:reserveKeys( count + 2 )
	spanCurve:setKey( 1, 0, -1, MOAIEaseType.FLAT )
	local pos = 0
	for i = 1, count do
		local key = self.keys[ i ]
		spanCurve:setKey( i + 1, key.pos, i,  MOAIEaseType.FLAT )
	end
	local l = self:calcLength()
	spanCurve:setKey( count + 2, l+0.00001, -1, MOAIEaseType.FLAT )
	-- spanCurve:setKey( count + 2, l, count, MOAIEaseType.FLAT )
	self.spanCurve    = spanCurve
	context:updateLength( l )
end

local min = math.min
function MSpriteAnimatorTrack:apply( state, playContext, t, t0 )
	local spanId  = self.spanCurve:getValueAtTime( t )
	if spanId < 0 then return end
	local key     = self.keys[ spanId ]
	local sprite  = playContext.sprite
	local animState = playContext[ spanId ]
	if not animState then return end
	local subTime = min( key.length, ( t - key.pos ) ) * key.throttle
	if key.useRange then
		local range = key.range
		local conv = animState.timeConverter
		local t0, t1 = range[1], range[2]
		if conv then
			subTime = conv( subTime, t1 - t0 ) + t0
		else
			subTime = min( subTime + t0, t1 )
		end
	else
		local conv = animState.timeConverter
		if conv then
			subTime = conv( subTime, animState.length )
		end
	end
	animState:apply( subTime )
end

local max = math.max
local floor = math.floor

--TODO: optimization using C++
local function mapTimeReverse( t, length )
	return max( length - t, 0 )
end

local function mapTimeReverseContinue( t, length )
	return length - t
end

local function mapTimeReverseLoop( t, length )
	t = t % length
	return length - t
end

local function mapTimePingPong( t, length )
	local span = floor( t / length )
	t = t % length
	if span % 2 == 0 then --ping
		return t
	else
		return length - t
	end
end

local function mapTimeLoop( t, length )
	return t % length
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
		if animState then
			animState.timeConverter = timeMapFuncs[ key.playMode ]
			animState.length = clip.length
			animState.clip   = clip
			playContext[ i ] = animState
		else
			_warn( 'no msprite clip named', key.clip, 'in', sprite.spritePath )
			playContext[ i ] = false
		end
	end
	state:addUpdateListenerTrack( self, playContext )
end



--------------------------------------------------------------------
registerCustomAnimatorTrackType( MSprite, 'clips', MSpriteAnimatorTrack )
