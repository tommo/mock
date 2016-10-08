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
CLASS: SQNodeWaitCoroutines ( SQNode )
	:MODEL{}


function SQNodeWaitCoroutines:step( state, env, dt )
	if state:isSubRoutineRunning() then return false end
	return true
end

function SQNodeWaitCoroutines:getRichText()
	return string.format( '<cmd>WAIT_COROUTINES</cmd>' )
end


--------------------------------------------------------------------
registerSQNode( 'coroutine',    SQNodeCoroutine )
registerSQNode( 'wait_coroutines',    SQNodeWaitCoroutines )

