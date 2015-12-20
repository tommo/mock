module 'mock'


--------------------------------------------------------------------
CLASS: SQContext ()
	:MODEL{}

function SQContext:__init()
	self.currentNode = false
end

function SQContext:update()
	local current = self.currentNode
	if not current then return end
	current:step( self )
end

--------------------------------------------------------------------
CLASS: SQCoroutine ()
	:MODEL{}

function SQCoroutine:__init()
	self.coroutine = MOAICoroutine.new()
	self.coroutine:run( function()
		return self:actionMain()
	end)
	self.context = false
end

function SQCoroutine:actionMain()
	local context = self.context
	local currentNode = context:getEntryNode()
	while true do
		local r = currentNode:enter( context )
		if not r then return self:actionStop() end
		local dt = 0
		while true do
			local rstep = currentNode:step( context, dt )
			if rstep == true then
				break
			elseif reset == false then
				return self:actionStop()
			end
			dt = coroutine.yield()
		end
		currentNode:exit( context )
	end
end

function SQCoroutine:actionStop()
end



--------------------------------------------------------------------
CLASS: SQActor ( Behaviour )
	:MODEL{}

function SQActor:__init()
	self.sequenceCoroutines = {}
end

function SQActor:_spawnThread()
end

function SQActor:updateThreads()
end


--------------------------------------------------------------------
CLASS: SQMutex ()
	:MODEL{}

function SQMutex:__init()
	self.locked = {}
	self.owner  = {} --key:
end

--------------------------------------------------------------------


