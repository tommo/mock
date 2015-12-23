module 'mock'

--------------------------------------------------------------------
CLASS: SQNode ()
	:MODEL{
}

function SQNode:__init()
	self.routine = false
	self.parentNode = false
	self.index = 0
	self.children = false

	self.comment = ''
end

function SQNode:getRoot()
	return self.routine:getRootNode()
end

function SQNode:getChildren()
	return self.children
end

-- function SQNode:getParentSequence()
-- 	local root = self:getRoot()
-- end

function SQNode:getName()
	return 'node'
end

function SQNode:getComment()
	return self.comment
end

function SQNode:setComment( c )
	self.comment = c
end

function SQNode:executeChildNodes( context )
	local children = self.children
	if not children then return false end
	for i, child in ipairs( children ) do
		child:execute( context )
	end
	return true
end

function SQNode:execute( context ) --inside a coroutine
	local env = {}
	--node enter
	local resultEnter = self:enter( context, env )

	--node step
	if resultEnter ~= false then
		local dt = 0
		while true do
			local resultStep = self:step( context, env, dt )
			if resultStep then break end
			dt = coroutine.yield()
		end
	end

	--children
	self:executeChildNodes( context, env )

	--node exit
	return self:exit( context, env )
	
end


function SQNode:enter( context, env )
	return true
end

function SQNode:step( context, env, dt )
	return true
end

function SQNode:exit( context, env )
	return true
end


--------------------------------------------------------------------
CLASS: SQRoutine ()
	:MODEL{}

function SQRoutine:__init()
	self.script   = false

	self.rootNode = SQNode()	
	self.rootNode.routine = self

	self.name = ''
	self.comment = ''
end

function SQNode:getComment()
	return self.comment
end

function SQNode:setComment( c )
	self.comment = c
end

function SQRoutine:getRootNode()
	return self.rootNode
end

function SQRoutine:execute( context )
	return context:executeRoutine( self )
end


--------------------------------------------------------------------
CLASS: SQScript ()
	:MODEL{}

function SQScript:__init()
	self.routines = {}
end

function SQScript:execute( context )
	for i, routine in ipairs( self.routines ) do
		routine:execute( context )
	end
end


--------------------------------------------------------------------
CLASS: SQContext ()
	:MODEL{}

function SQContext:__init()
	self.idleCoroutines = {}
	self.activeCoroutines = {}
end

function SQContext:requestCoroutine()
	local coroutine = MOAICoroutine.new()
	return coroutine
end

function SQContext:executeRoutine( routine )
	local coro = self:requestCoroutine()
	coro:run( function()
		routine:getRootNode():execute( self )
		self.activeCoroutines[ coro ] = nil
	end)
	self.activeCoroutines[ coro ] = true
end

function SQContext:isRunning()
	if next( self.activeCoroutines ) then return true end
	return false
end

