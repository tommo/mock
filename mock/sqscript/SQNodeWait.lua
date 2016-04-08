module 'mock'

--------------------------------------------------------------------
CLASS: SQNodeWait ( SQNode )
	:MODEL{
		Field 'duration' :meta{ step=0.1 } :range( 0 );
	}

function SQNodeWait:__init()
	self.duration = 1
end

function SQNodeWait:load( data )
	self.duration = tonumber( data.args[1] ) or 1
end

function SQNodeWait:enter( state, env )
	env.elapsed = 0
end

function SQNodeWait:step( state, env, dt )
	local elapsed = env.elapsed 
	elapsed = elapsed + dt
	if elapsed >= self.duration then return true end
	env.elapsed = elapsed
end

function SQNodeWait:getRichText()
	return string.format( '<cmd>WAIT</cmd> <number>%.2f</number> sec', self.duration )
end

function SQNodeWait:getIcon()
	return 'sq_node_wait'
end


--------------------------------------------------------------------
CLASS: SQNodeWaitFrame ( SQNode )
	:MODEL{
		Field 'frameCount' :range( 0 );
	}

function SQNodeWaitFrame:__init()
	self.frameCount = 1
end

function SQNodeWaitFrame:enter( state, env )
	env.elapsed = 0
end

function SQNodeWaitFrame:step( state, env, dt )
	local elapsed = env.elapsed 
	elpased = elpased + 1
	return elpased >= self.frameCount
end

function SQNodeWaitFrame:getRichText()
	return string.format( '<cmd>WAIT</cmd> <number>%d</number> frames', self.frameCount )
end

function SQNodeWaitFrame:getIcon()
	return 'sq_node_wait'
end
--------------------------------------------------------------------
CLASS: SQNodeWaitRandom ( SQNode )
	:MODEL{
		Field 'minDuration' :meta{ step=0.1 } :range( 0 );
		Field 'maxDuration' :meta{ step=0.1 } :range( 0 );
	}

function SQNodeWaitRandom:__init()
	self.minDuration = 1
	self.maxDuration = 2
end

function SQNodeWaitRandom:enter( state, env )
	local min, max = self:getRange()
	env.duration = rand( min, max )
	env.elapsed = 0
end


function SQNodeWaitRandom:step( state, env, dt )
	local elapsed = env.elapsed 
	elapsed = elapsed + dt
	if elapsed >= env.duration then return true end
	env.elapsed = elapsed
end

function SQNodeWaitRandom:getRange()
	local min, max = self.minDuration, self.maxDuration
	min = math.max( min, 0 )
	if max < min then max = min end
	return min, max
end

function SQNodeWaitRandom:getRichText()
	local min, max = self:getRange()
	return string.format(
		'<cmd>WAIT</cmd> <number>%.2f</number> ~ <number>%.2f</number> sec',
	 min, 
	 max
	)
end

function SQNodeWaitRandom:getIcon()
	return 'sq_node_wait'
end

--------------------------------------------------------------------
registerSQNode( 'wait', SQNodeWait             )
registerSQNode( 'wait_frame', SQNodeWaitFrame   )
registerSQNode( 'wait_random', SQNodeWaitRandom )
