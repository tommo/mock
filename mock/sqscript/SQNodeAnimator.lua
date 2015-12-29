module 'mock'

--------------------------------------------------------------------
CLASS: SQNodeAnimatorControl ( SQNode )
	:MODEL{

	}

function SQNodeAnimatorControl:__init()
end

function SQNodeAnimatorControl:enter( context, env )
end

function SQNodeAnimatorControl:checkAndGetAnimator( context )
	local entity = context:getEnv( 'entity' )
	local animator = entity:getComponent( Animator )
	if not animator then
		_warn( 'no animator for entity:', entity:getName() )
	end
	return animator
end

function SQNodeAnimatorControl:getIcon()
	return 'sq_node_animator'
end


--------------------------------------------------------------------
CLASS: SQNodeAnimatorStop ( SQNodeAnimatorControl )
	:MODEL{}

function SQNodeAnimatorStop:enter( context, env )
	local animator = self:checkAndGetAnimator( context )
	if not animator then return false end
	animator:stop()
end

function SQNodeAnimatorStop:getRichText()
	return string.format(
		'<cmd>STOP_ANIMATOR</cmd>'
	)
end

function SQNodeAnimatorStop:getIcon()
	return 'sq_node_animator_stop'
end


--------------------------------------------------------------------
CLASS: SQNodeAnimatorPause ( SQNodeAnimatorControl )
	:MODEL{}

function SQNodeAnimatorPause:enter( context, env )
	local animator = self:checkAndGetAnimator( context )
	if not animator then return false end
	animator:pause()
end

function SQNodeAnimatorPause:getRichText()
	return string.format(
		'<cmd>PAUSE_ANIMATOR</cmd>'
	)
end

function SQNodeAnimatorPause:getIcon()
	return 'sq_node_animator_pause'
end


--------------------------------------------------------------------
CLASS: SQNodeAnimatorResume ( SQNodeAnimatorControl )
	:MODEL{}

function SQNodeAnimatorResume:enter( context, env )
	local animator = self:checkAndGetAnimator( context )
	if not animator then return false end
	animator:resume()
end

function SQNodeAnimatorResume:getRichText()
	return string.format(
		'<cmd>RESUME_ANIMATOR</cmd>'
	)
end

--------------------------------------------------------------------
CLASS: SQNodeAnimatorThrottle ( SQNodeAnimatorControl )
	:MODEL{
		Field 'throttle' :range( 0 );
}

function SQNodeAnimatorThrottle:enter( context, env )
	local animator = self:checkAndGetAnimator( context )
	if not animator then return false end
	animator:setThrottle( 'throttle' )
end

function SQNodeAnimatorThrottle:getRichText()
	return string.format(
		'<cmd>RESUME_ANIMATOR</cmd>'
	)
end

--------------------------------------------------------------------
CLASS: SQNodeAnimatorPlay ( SQNodeAnimatorControl )
	:MODEL{
		Field 'clip' :string();
		Field 'mode' :enum( EnumTimerMode );
		Field 'duration' :range(0);
		Field 'blocking' :boolean();
	}

function SQNodeAnimatorPlay:__init()
	self.clip = ''
	self.mode = MOAITimer.NORMAL
	self.duration = 0 --use clip time
	self.blocking = true
end

function SQNodeAnimatorPlay:getRichText()
	local duration = self.duration
	local blocking = self.blocking
	return string.format(
		'<cmd>PLAY_ANIM</cmd> "<string>%s</string>" mode:<data>%s</data> duration:<number>%s</number> <flag>%s</flag>',
		self.clip,
		_ENUM_NAME( EnumTimerMode, self.mode, '????' ),
		duration == 0 and 'auto' or string.format( '%.2f', duration ),
		blocking and 'blocked' or ''
	)
end

function SQNodeAnimatorPlay:enter( context, env )
	local animator = self:checkAndGetAnimator( context )
	if not animator then return false end
	local state = animator:playClip( self.clip, self.mode )
	if not state then 
		_warn( 'no animator clip found:', animator:getEntity():getName(), self.clip )
		return false
	end
	local duration = self.duration
	if duration > 0 then
		state:setDuration( duration )
	end
	env.animState = state
	return true 
end

function SQNodeAnimatorPlay:step( context, env, dt )
	if self.blocking then
		local state = env.animState
		if state:isDone() then return true end
	else
		return true
	end
end

--------------------------------------------------------------------
registerSQNode( 'animator_stop',      SQNodeAnimatorStop   )
registerSQNode( 'animator_pause',     SQNodeAnimatorPause  )
registerSQNode( 'animator_resume',    SQNodeAnimatorResume )
registerSQNode( 'animator_throttle',  SQNodeAnimatorThrottle   )
registerSQNode( 'animator_play',      SQNodeAnimatorPlay   )
