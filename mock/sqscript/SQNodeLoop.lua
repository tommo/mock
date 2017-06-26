module 'mock'

--------------------------------------------------------------------
CLASS: SQNodeLoopBase ( SQNodeGroup )
	:MODEL{}

function SQNodeLoopBase:isGroup()
	return true
end

function SQNodeLoopBase:checkLoopDone( state, env )
	return true
end

function SQNodeLoopBase:exit( state, env )
	if not self:checkLoopDone( state, env ) then
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

function SQNodeLoopCounted:enter( state, env )
	env.count = 0
end

function SQNodeLoopCounted:checkLoopDone( state, env )
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

function SQNodeLoopInfinite:checkLoopDone( state, env )
	return false
end

function SQNodeLoopInfinite:getRichText()
	return string.format(
		'[ <cmd>LOOP_INIFINITE</cmd> ]'
	)
end


--------------------------------------------------------------------
registerSQNode( 'loop_counted', SQNodeLoopCounted )
registerSQNode( 'loop_infinite', SQNodeLoopInfinite )
