module 'mock'

--------------------------------------------------------------------
CLASS: SQNodeAnimator ( SQNode )
	:MODEL{

	}

function SQNodeAnimator:__init()
	self.cmd = 'play'
	self.animState = false
	self.blocking  = true
end

function SQNodeAnimator:enter( state, env )
	local animator = self:checkAndGetAnimator( state )
	if not animator then return false end
	local cmd = self.cmd
	if cmd == 'play' then
		if not self.argClipName then return false end
		local animState = animator:playClip( self.argClipName, self.argMode )
		if not animState then 
			_warn( 'no animator clip found:', animator:getEntity():getName(), self.argClipName )
			return false
		end
		local duration = self.argDuration
		if duration > 0 then
			animState:setDuration( duration )
		end
		env.animState = animState
		return true 

	elseif cmd == 'stop' then
		animator:stop()
		return false

	elseif cmd == 'resume' then
		local animState = env.animState
		if not animState then
			return false
		end
		animator:resume()
		return true

	elseif cmd == 'throttle' then
		animator:setThrottle( self.argThrottle )
		return false

	else
		return false
	end
end

function SQNodeAnimator:step( state, env, dt )
	if self.blocking then
		local animState = env.animState
		if animState:isDone() then return true end
	else
		return true
	end
end

function SQNodeAnimator:checkAndGetAnimator( state )
	local entity = state:getEnv( 'entity' )
	local animator = entity:getComponent( Animator )
	if not animator then
		_warn( 'no animator for entity:', entity:getName() )
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
	if cmd == 'play' then
		--
		self.argClipName = args[2] or false
		self.argMode = args[3] or 'normal'
		self.argDuration = tonumber( args[4] ) or 0

	elseif cmd == 'stop' then
		--no args
	elseif cmd == 'pause' then
		--no args
	elseif cmd == 'resume' then
		--no args
	elseif cmd == 'throttle' then
		self.argThrottle = tonumber( args[2] ) or 1
	else
		_warn( 'unkown animator command', tostring(cmd) )
		return false
	end
end

--------------------------------------------------------------------
registerSQNode( 'anim', SQNodeAnimator   )
