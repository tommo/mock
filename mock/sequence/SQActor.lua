module 'mock'
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


-- --------------------------------------------------------------------
-- CLASS: SQMutex ()
-- 	:MODEL{}

-- function SQMutex:__init()
-- 	self.locked = {}
-- 	self.owner  = {} --key:
-- end

-- --------------------------------------------------------------------


CLASS: SQSemaphore ()
	:MODEL{}
