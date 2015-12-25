module 'mock'

--------------------------------------------------------------------
CLASS: SQNodeLoopBase ( SQNode )
	:MODEL{}

function SQNodeLoopBase:executeChildNodes( context, env )
	while not self:isLoopDone( context, env ) do
		SQNode.executeChildNodes( self, context, env )
	end
end

function SQNodeLoopBase:isLoopDone( context, env )
	return true
end

--------------------------------------------------------------------
CLASS: SQNodeCountedLoop ( SQNodeLoopBase )
	:MODEL{
		Field 'count' :int() :range(0);
	}

function SQNodeCountedLoop:__init()
	self.count = 0
end

function SQNodeCountedLoop:setLoopCount( count )
	self.count = count or 0
end

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
CLASS: SQNodeInfiniteLoop ( SQNodeLoopBase )
	:MODEL{
	}

function SQNodeInfiniteLoop:isLoopDone( context, env )
	return true
end
