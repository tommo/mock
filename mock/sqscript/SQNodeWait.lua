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

function SQNodeWait:getRichText()
	return string.format( '<cmd>WAIT</cmd> <data><number>%.2f</number> sec</data>', self.duration )
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

function SQNodeWaitFrame:getRichText()
	return string.format( '<cmd>WAIT</cmd> <data><number>%d</number> frames</data>', self.frameCount )
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

function SQNodeWaitRandom:getRichText()
	local min = math.max( self.duration - self.variation/2, 0 )
	local max = self.duration + self.variation/2
	return string.format(
		'<cmd>WAIT</cmd> <data><number>%.2f</number> ~ <number>%.2f</number> sec </data>',
	 min, 
	 max
	)
end

--------------------------------------------------------------------
registerSQNode( 'wait', SQNodeWait             )
registerSQNode( 'wait_frame', SQNodeWaitFrame   )
registerSQNode( 'wait_random', SQNodeWaitRandom )
