module 'mock'


--------------------------------------------------------------------
CLASS: AnimatorClipAnimatorKey ( AnimatorEventKey )
	:MODEL{
		Field 'clip'  :string() :selection( 'getClipNames' ) :set( 'setClip' );
		Field 'playMode' :enum( EnumTimerMode );
		Field 'FPS'   :int();
	}


--------------------------------------------------------------------
CLASS: AnimatorClipAnimatorTrack ( AnimatorEventTrack )
	:MODEL{
	}



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
registerCustomAnimatorTrackType( Animator, 'clip_speed', AnimatorClipSpeedAnimatorTrack )
