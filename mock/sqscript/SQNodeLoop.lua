module 'mock'

--------------------------------------------------------------------
CLASS: SQNodeLoopBase ( SQNodeGroup )
	:MODEL{}

function SQNodeLoopBase:isGroup()
	return true
end

-- function SQNodeLoopBase:executeChildNodes( context, env )
-- 	while not self:checkLoopDone( context, env ) do
-- 		local res = SQNode.executeChildNodes( self, context, env )
-- 		if res == 'jump' then return res end
-- 	end
-- end

function SQNodeLoopBase:checkLoopDone( context, env )
	return true
end

function SQNodeLoopBase:exit( context, env )
	if not self:checkLoopDone( context, env ) then
		--GOTO
		return 'loop'
	end
end

function SQNodeLoopBase:getIcon()
	return 'sq_node_loop'
end

--------------------------------------------------------------------
CLASS: SQNodeLoopCounted ( SQNodeLoopBase )
	:MODEL{
		Field 'count' :int() :range(0);
	}

function SQNodeLoopCounted:__init()
	self.count = 0
end

function SQNodeLoopCounted:setLoopCount( count )
	self.count = count or 0
end

function SQNodeLoopCounted:enter( context, env )
	env.count = 0
end

function SQNodeLoopCounted:checkLoopDone( context, env )
	local count = (env.count or 0) + 1
	if count > self.count then return true end
	env.count = count
	return false
end

function SQNodeLoopCounted:getRichText()
	return string.format(
		'[ <cmd>LOOP</cmd> <number>%d</number> times ]',
		self.count
	)
end

--------------------------------------------------------------------
CLASS: SQNodeLoopInfinite ( SQNodeLoopBase )
	:MODEL{
	}

function SQNodeLoopInfinite:checkLoopDone( context, env )
	return true
end

function SQNodeLoopInfinite:getRichText()
	return string.format(
		'[ <cmd>LOOP_INIFINITE</cmd> ]'
	)
end


--------------------------------------------------------------------
registerSQNode( 'loop_counted', SQNodeLoopCounted )
registerSQNode( 'loop_infinite', SQNodeLoopInfinite )
