module 'mock'

--------------------------------------------------------------------
CLASS: AnimatorAnimatorKey ( AnimatorEventKey )
	:MODEL{
		Field 'clip'  :string() :selection( 'getClipNames' ) :set( 'setClip' );
		Field 'playMode' :enum( EnumTimerMode );
		Field 'throttle' :float()  :meta{ step = 0.1 } :range( 0 );
		-- Field 'rangeStart' :string();
		-- Field 'rangeEnd' :string();
		'----';
		Field 'resetLength' :action( 'resetLength' );
	}

function AnimatorAnimatorKey:__init()
	self.clip = false
	self.throttle = 1
	self.playMode = MOAITimer.NORMAL
	-- self.rangeStart = ''
	-- self.rangeEnd   = ''
end

function AnimatorAnimatorKey:getClipNames()
	local animator = self:getTrack():getEditorTargetObject()
	return animator:getClipNames()
end

function AnimatorAnimatorKey:setClip( clip )
	self.clip = clip
end

function AnimatorAnimatorKey:toString()
	return self.clip or '<nil>'
end

function AnimatorAnimatorKey:resetLength()
	local animator = self:getTrack():getEditorTargetObject()
	local animClip = animator:getClip( self.clip )
	if animClip then
		self:setLength( animClip:getLength() / self.throttle )
	end
end


--------------------------------------------------------------------
CLASS: AnimatorAnimatorTrack ( AnimatorEventTrack )
	:MODEL{
	}

function AnimatorAnimatorTrack:getIcon()
	return 'track_anim'
end

function AnimatorAnimatorTrack:toString()
	local pathText = self.targetPath:toString()
	return pathText..'<clips>'
end

function AnimatorAnimatorTrack:createKey( pos, context )
	local key = AnimatorAnimatorKey()
	key:setPos( pos )
	self:addKey( key )
	local target = context.target --Animator
	key.clip     = target.default
	return key
end

function AnimatorAnimatorTrack:build( context )
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

local min = math.min
function AnimatorAnimatorTrack:apply( state, playContext, t, t0 )
	local spanId  = self.spanCurve:getValueAtTime( t )
	local key     = self.keys[ spanId ]
	local sprite  = playContext.sprite
	local animState = playContext[ spanId ]
	local subTime = min( key.length, ( t - key.pos ) ) * key.throttle
	local conv = animState.timeConverter
	if conv then
		subTime = conv( subTime, animState.clipLength )
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

function AnimatorAnimatorTrack:onStateLoad( state )
	local rootEntity, scene = state:getTargetRoot()
	local animator = self.targetPath:get( rootEntity, scene )
	local playContext = { animator = animator }
	for i, key in ipairs( self.keys ) do
		local animState = animator:loadClip( key.clip, false ) --create non active state
		animState.timeConverter = timeMapFuncs[ key.playMode ]
		playContext[ i ] = animState
	end
	state:addUpdateListenerTrack( self, playContext )
end



--------------------------------------------------------------------
CLASS: AnimatorClipSpeedAnimatorTrack ( AnimatorValueTrack )
	:MODEL{
	}


function AnimatorClipSpeedAnimatorTrack:isCurveTrack()
	return true
end

function AnimatorClipSpeedAnimatorTrack:createKey( pos, context )
	local key = AnimatorKeyNumber()
	key:setPos( pos )
	local target = context.target
	key:setValue( 1.0 )
	return self:addKey( key )
end

function AnimatorClipSpeedAnimatorTrack:getIcon()
	return 'track_anim'
end

function AnimatorClipSpeedAnimatorTrack:toString()
	local pathText = self.targetPath:toString()
	return pathText..'<clip_speed>'
end

function AnimatorClipSpeedAnimatorTrack:build( context )
	self.curve = self:buildCurve()
	context:updateLength( self:calcLength() )
end

function AnimatorClipSpeedAnimatorTrack:onStateLoad( state )
	local rootEntity, scene = state:getTargetRoot()
	local target = self.targetPath:get( rootEntity, scene )
	state:addUpdateListenerTrack( self, target )
end

function AnimatorClipSpeedAnimatorTrack:apply( state, playContext, t, t0 )
	local value = self.curve:getValueAtTime( t )
	state:setClipSpeed( value )
end

function AnimatorClipSpeedAnimatorTrack:isPlayable()
	return true
end


--------------------------------------------------------------------
registerCustomAnimatorTrackType( Animator, 'clips', AnimatorAnimatorTrack )
registerCustomAnimatorTrackType( Animator, 'clip_speed', AnimatorClipSpeedAnimatorTrack )
