module 'mock'

--------------------------------------------------------------------
CLASS: SQNodeWait ( SQNode )
	:MODEL{
		Field 'duration'
	}

function SQNodeWait:__init()
	self.duration = 1
end

function SQNodeWait:enter( context, env )
	env.elapsed = 0
end

function SQNodeWait:step( context, env, dt )
	local elapsed = env.elapsed 
	elapsed = elapsed + dt
	if elapsed >= self.duration then return true end
	env.elapsed = elapsed
end


--------------------------------------------------------------------
CLASS: SQNodeWaitFrame ( SQNode )
	:MODEL{
		Field 'frameCount'
	}

function SQNodeWaitFrame:__init()
	self.frameCount = 1
end

function SQNodeWaitFrame:enter( context, env )
	env.elapsed = 0
end

function SQNodeWaitFrame:step( context, env, dt )
	local elapsed = env.elapsed 
	elpased = elpased + 1
	return elpased >= self.frameCount
end


--------------------------------------------------------------------
CLASS: SQNodeWaitRandom ( SQNode )
	:MODEL{
		Field 'duration';
		Field 'variation';
	}

function SQNodeWaitRandom:__init()
	self.duration = 1
	self.variation = 0.1
end

function SQNodeWaitRandom:enter( context, env )
	env.duration = self.duration + noise( self.variation )
	env.elapsed = 0
end

function SQNodeWaitRandom:step( context, env, dt )
	local elpased = env.elapsed 
	elpased = elpased + dt
	if elpased >= env.duration then return true end
	env.elapsed = elapsed
end

