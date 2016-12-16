module 'mock'

local NameToAnimMode = {
	['normal']           = MOAITimer.NORMAL;
	['reverse']          = MOAITimer.REVERSE;
	['continue']         = MOAITimer.CONTINUE;
	['continue_reverse'] = MOAITimer.CONTINUE_REVERSE;
	['loop']             = MOAITimer.LOOP;
	['loop_reverse']     = MOAITimer.LOOP_REVERSE;
	['ping_pong']        = MOAITimer.PING_PONG;
}

--------------------------------------------------------------------
CLASS: SQNodeAnimator ( SQNode )
	:MODEL{

	}

function SQNodeAnimator:__init()
	self.cmd = 'play'
	self.blocking  = false
end

function SQNodeAnimator:enter( state, env )
	local animator = self:checkAndGetAnimator( state )
	if not animator then return false end
	local cmd = self.cmd
	if cmd == 'play' then
		if not self.argClipName then return false end
		local animState = animator:playClip( self.argClipName, self.argMode )
		-- print( 'play animation', animator:getEntityName(), self.argClipName, self.argMode )
		if not animState then 
			self:_warn( 'no animator clip found:', animator:getEntity():getName(), self.argClipName )
			return false
		end
		local duration = self.argDuration
		if duration > 0 then
			animState:setDuration( duration )
		end
		env.animState = animState
		return true 

	elseif cmd == 'load' then
		if not self.argClipName then return false end
		local animState = animator:playClip( self.argClipName, self.argMode )
		if not animState then 
			self:_warn( 'no animator clip found:', animator:getEntity():getName(), self.argClipName )
			return false
		end
		animState:pause()
		return false

	elseif cmd == 'stop' then
		animator:stop()
		return false

	elseif cmd == 'pause' then
		animator:pause( paused )
		return false

	elseif cmd == 'resume' then
		local state = animator:getActiveState()
		if not state then
			return false
		end
		animator:resume()
		env.animState = state
		return true

	elseif cmd == 'throttle' then
		animator:setThrottle( self.argThrottle )
		return false

	elseif cmd == 'seek' then
		local state = animator:getActiveState()
		if not state then
			return false
		end
		state:seek( self.argPosFrom )

	elseif cmd == 'to' then
		local state = animator:getActiveState()
		if not state then
			return false
		end
		state:setRange( nil, self.argPosTo )
		state:resume()
		env.animState = state
		return true

	elseif cmd == 'range' then
		local state = animator:getActiveState()
		if not state then
			return false
		end
		state:setRange( self.argPosFrom, self.argPosTo )
		state:resume()
		env.animState = state
		return true

	else
		return false
	end
end

function SQNodeAnimator:step( state, env, dt )
	if self.blocking then
		local animState = env.animState
		if animState:isActive() then return fasle end
	else
		return true
	end
end

function SQNodeAnimator:checkAndGetAnimator( state )
	local target = self:getContextEntity( state )
	local animator = target:getComponent( Animator )
	if not animator then
		self:_warn( 'no animator for target:', target:getName() )
	end
	return animator
end

function SQNodeAnimator:getIcon()
	return 'sq_node_animator'
end

function SQNodeAnimator:load( data )
	local args = data.args
	local cmd = args[1]
	if not cmd then return end
	self.cmd = cmd
	if cmd == 'play' then
		--
		self.argClipName = args[2] or false
		self.argDuration = tonumber( args[3] ) or 0
		self.argMode = NameToAnimMode[ args[4] or 'normal' ] or 0
		self.blocking = true

	elseif cmd == 'load' then
		self.argClipName = args[2] or false
		self.argMode = NameToAnimMode[ args[3] or 'normal' ] or 0
		self.blocking  = false

	elseif cmd == 'loop' then
		self.cmd = 'play'
		self.argClipName = args[2] or false
		self.argDuration = tonumber( args[3] ) or 0
		self.argMode = NameToAnimMode[ 'loop' ]
		self.blocking = false

	elseif cmd == 'stop' then
		--no args
	elseif cmd == 'pause' then
		--self.argPause = paused
		--no args
	elseif cmd == 'resume' then
		--no args
	elseif cmd == 'throttle' then
		self.argThrottle = tonumber( args[2] ) or 1
	elseif cmd == 'seek' then
		self.argPosFrom = tonumber( args[2] ) or args[2]
	elseif cmd == 'to' then
		self.argPosTo = tonumber( args[2] ) or args[2]
		self.blocking = true
	elseif cmd == 'range' then
		self.argPosFrom = tonumber( args[2] ) or args[2]
		self.argPosTo = tonumber( args[3] ) or args[3]
		self.blocking = true
	else
		self:_warn( 'unkown animator command', tostring(cmd) )
		return false
	end
end

--------------------------------------------------------------------
registerSQNode( 'anim', SQNodeAnimator   )
