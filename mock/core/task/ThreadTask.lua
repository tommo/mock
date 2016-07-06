module 'mock'

--------------------------------------------------------------------
CLASS: ThreadTaskManager ()
	:MODEL{}

local _mgr = false
function getThreadTaskManager()
	if _mgr then return _mgr end
	_mgr = ThreadTaskManager()
	return _mgr
end

function isThreadTaskBusy( groupId )
	return getThreadTaskManager():isBusy( groupId )
end

function getThreadTaskGroup( groupId )
	groupId = groupId or getThreadTaskManager().defaultGroupId
	return getThreadTaskManager():getGroup( groupId )
end

function getThreadTaskProgress( groupId )
	groupId = groupId or getThreadTaskManager().defaultGroupId
	local group = getThreadTaskManager():getGroup( groupId, false )
	if not group then return 1 end
	return group:getProgress()
end

function ThreadTaskManager:__init()
	self.groups = {}
	self.defaultGroupId = 'main'
end

function ThreadTaskManager:getGroup( name, createIfNotExist )
	local group = self.groups[ name ]
	if not group and ( createIfNotExist ~= false ) then
		group = ThreadTaskGroup()
		self.groups[ name ] = group
		group.manager = self
	end
	return group
end

function ThreadTaskManager:setGroupSize( name, size )
	local group = self:getGroup( name, true )
	group:setSize( size )
end

function ThreadTaskManager:getDefaultGroupId()
	return self.defaultGroupId
end

function ThreadTaskManager:getDefaultGroup()
	return self:affirmGroup( self.defaultGroupId )
end
	
function ThreadTaskManager:setDefaultGroup( name )
	self.defaultGroupId = name or 'main'
end

function ThreadTaskManager:pushTask( groupId, t )
	groupId = groupId or self.defaultGroupId
	local group = self:getGroup( groupId )
	group:pushTask( t )
	return t
end

function ThreadTaskManager:isBusy( groupId )
	local group = self:getGroup( groupId or self.defaultGroupId, false )
	if not group then return false end
	return group:isBusy()
end

function ThreadTaskManager:isAnyBusy()
	return self.busy
end


---------------------------------------------------------------------
CLASS: ThreadTaskGroup ()
	:MODEL{}

function ThreadTaskGroup:__init()
	self.size = 0
	self.queues = {}
	self:setSize( 1 )
end

function ThreadTaskGroup:setSize( size )
	size = math.max( size, 1 )
	self.size = size or 1
	for i = 1, size do
		local q = self.queues[ i ]
		if not q then
			q = ThreadTaskQueue()
			self.queues[ i ] = q
		end
	end
end

function ThreadTaskGroup:getSize()
	return self.size
end

function ThreadTaskGroup:isIdle()
	return not self:isBusy()
end

function ThreadTaskGroup:isBusy()
	for i, queue in ipairs( self.queues ) do
		if queue:isBusy() then return true end
	end
	return false
end

function ThreadTaskGroup:getTotalTaskSize()
	local size = 0
	for i, queue in ipairs( self.queues ) do
		size = size + queue.totalTaskSize
	end
	return size
end

function ThreadTaskGroup:getTaskSize()
	local size = 0
	for i, queue in ipairs( self.queues ) do
		size = size + queue.taskSize
	end
	return size
end

function ThreadTaskGroup:getProgress()
	local totalSize = self:getTotalTaskSize()
	if totalSize <= 0 then return 1 end
	local taskSize = self:getTaskSize()
	return 1 - ( taskSize/totalSize )
end

function ThreadTaskGroup:pushTask( task )
	--find empty queue
	local minQSize = 1000000
	local selectedQueue = false
	for i, queue in ipairs( self.queues ) do
		if not queue:isBusy() then
			selectedQueue = queue
			break
		end
		local qsize = queue.taskCount
		if ( not minQSize ) or qsize < minQSize then
			minQSize = qsize
			selectedQueue = queue
		end
	end
	assert( selectedQueue )
	return selectedQueue:pushTask( task )

end

--------------------------------------------------------------------
CLASS: ThreadTaskQueue ()
	:MODEL{}
function ThreadTaskQueue:__init()
	
	self.pending = {}
	self.activeTask = false
	self.taskSize  = 0
	self.taskCount = 0
	self.totalTaskSize  = 0
	self.totalTaskCount = 0
	self.thread = false
	self.coro = MOAICoroutine.new()

end

function ThreadTaskQueue:getThread()
	if not self.thread then
		self.thread = MOAITaskThread.new()
	end
	return self.thread
end

function ThreadTaskQueue:resetProgress()
	self.totalTaskSize  = self.taskSize
	self.totalTaskCount = self.taskCount
end

function ThreadTaskQueue:getProgress()
	if self.totalTaskSize <= 0 then return 1 end
	return 1 - ( self.taskSize / self.totalTaskSize )
end

function ThreadTaskQueue:pushTask( task )
	table.insert( self.pending, task )
	self.taskSize  = self.taskSize + task:getTaskSize()
	self.taskCount = self.taskCount + 1
	self.totalTaskSize  = self.totalTaskSize + task:getTaskSize()
	self.totalTaskCount = self.totalTaskCount + 1
	task.queue = self
	if not self.activeTask then
		return self:processNext()
	end
end

function ThreadTaskQueue:processNext()
	local t = table.remove( self.pending, 1 )
	if t then
		_stat( 'Processing task', t:toString() )
		self.activeTask = t
		t.execTime0 = os.clock()
		t:onExec( self )
		_stat( 'task in execution now' )
		return t
	else
		--no more task, stop the thread
		_stat( 'Thread empty, now stopping....' )
		self.thread:stop()
		self.thread = nil
	end
end

function ThreadTaskQueue:isBusy()
	return ( self.activeTask and true ) or ( next( self.pending ) ~= nil )
end

function ThreadTaskQueue:notifyCompletion( task )
	assert( self.activeTask == task )
	_stat( 'Task completed', task:toString() )
	self.activeTask = false
	self.taskSize = self.taskSize - task:getTaskSize()
	self.taskCount = self.taskCount - 1
	task.execTime1 = os.clock()
	self:processNext()
end

function ThreadTaskQueue:notifyFail( task ) --TODO: allow interrupt on error?
	assert( self.activeTask == task )
	_stat( 'Task failed', task:toString() )
	self.activeTask = false
	self.taskSize = self.taskSize - task:getTaskSize()
	self.taskCount = self.taskCount - 1
	task.execTime1 = os.clock()
	self:processNext()
end

--------------------------------------------------------------------
CLASS: ThreadTask ()
	:MODEL{}

function ThreadTask:getDefaultGroupId()
	return nil
end

function ThreadTask:start( groupId )
	getThreadTaskManager():pushTask( groupId or self:getDefaultGroupId(), self )
end

function ThreadTask:toString()
	return '<unknown>'
end

function ThreadTask:complete( ... )
	if self.queue then 
		self.queue:notifyCompletion( self )		
	end
	return self:onComplete( ... )
end

function ThreadTask:fail( ... )
	if self.queue then 
		self.queue:notifyFail( self )		
	end
	return self:onFail( ... )
end

function ThreadTask:onExec( queue )
end

function ThreadTask:onComplete( ... )
end

function ThreadTask:onFail( ... )
end

function ThreadTask:getTaskSize() --for progress calculation
	return 1
end

function ThreadTask:getTimeElapsed()	
	local t0 = self.execTime0 or 0
	local t1 = self.execTime1 or os.clock()
	return t1 - t0
end


