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
CLASS: SQNodeLoopForCount ( SQNodeLoopBase )
	:MODEL{
		Field 'count' :int() :range(0);
	}

function SQNodeLoopForCount:__init()
	self.count = 0
end

function SQNodeLoopForCount:setLoopCount( count )
	self.count = count or 0
end

function SQNodeLoopForCount:enter( state, env )
	env.count = 0
end

function SQNodeLoopForCount:checkLoopDone( state, env )
	local count = (env.count or 0) + 1
	if count > self.count then return true end
	env.count = count
	return false
end

function SQNodeLoopForCount:getRichText()
	return string.format(
		'[ <cmd>LOOP</cmd> <number>%d</number> times ]',
		self.count
	)
end

--------------------------------------------------------------------
CLASS: SQNodeLoopForever ( SQNodeLoopBase )
	:MODEL{
	}

function SQNodeLoopForever:checkLoopDone( state, env )
	return false
end

function SQNodeLoopForever:getRichText()
	return string.format(
		'[ <cmd>LOOP_FOREVER</cmd> ]'
	)
end


--------------------------------------------------------------------
registerSQNode( 'loop_for', SQNodeLoopForCount )
registerSQNode( 'loop_forever', SQNodeLoopForever )
