module 'mock'

--------------------------------------------------------------------
CLASS: SQNodeCoroutine ( SQNodeGroup )
	:MODEL{
		Field 'id' :string()
	}

function SQNodeCoroutine:__init()
	self.id = false
end

function SQNodeCoroutine:isExecutable()
	return true
end

function SQNodeCoroutine:load( data )
	local args = data.args
	self.id = args[1] or false
end

function SQNodeCoroutine:build( buildContext )
	local routine = self:getRoutine()
end

function SQNodeCoroutine:enter( state, env )
end

function SQNodeCoroutine:exit( state, env )
	return 'end'
end

function SQNodeCoroutine:getRichText()
	return string.format( '<cmd>COROUTINE</cmd> <signal>%s</signal>', self.id )
end


--------------------------------------------------------------------
CLASS: SQNodeCoroutineWaitAll ( SQNode )
	:MODEL{}


function SQNodeCoroutineWaitAll:step( state, env, dt )
	if state:isSubRoutineRunning() then return false end
	return true
end

function SQNodeCoroutineWaitAll:getRichText()
	return string.format( '<cmd>WAIT_COROUTINES</cmd>' )
end

--------------------------------------------------------------------
CLASS: SQNodeCoroutinePause ( SQNode )
	:MODEL{}

function SQNodeCoroutinePause:enter()
	
end

--------------------------------------------------------------------
registerSQNode( 'coroutine',    SQNodeCoroutine )
registerSQNode( 'coroutine_wait_all',    SQNodeCoroutineWaitAll )

--legacy alias
registerSQNode( 'wait_coroutines',    SQNodeCoroutineWaitAll )

