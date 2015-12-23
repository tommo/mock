module 'mock'

--------------------------------------------------------------------
CLASS: SQNodeLoopBase ( SQNode )
	:MODEL{}

function SQNodeLoopBase:executeChildNodes( context, env )
	if self:isLoopDone( context, env ) then return end
	return self:executeChildNodes( context )
end

function SQNodeLoopBase:isLoopDone( context, env )
	return true
end

--------------------------------------------------------------------
CLASS: SQNodeCountedLoop ( SQNode )
	:MODEL{
		Field 'count' :int() :range(0);
	}

function SQNodeCountedLoop:enter( context, env )
	env.count = 0
end

function SQNodeCountedLoop:isLoopDone( context, env )
	local count = env.count + 1
	if count > self.count then return true end
	env.count = count
	return false
end

--------------------------------------------------------------------
CLASS: SQNodeInfiniteLoop ( SQNode )
	:MODEL{
	}

function SQNodeInfiniteLoop:isLoopDone( context, env )
	return true
end
