module 'mock'

--------------------------------------------------------------------
CLASS: StoryState ()
	:MODEL{}

function StoryState:__init( context )
	self.currentNode      = false
	self.forceEnded  = false
	self.active      = false
	self.context     = context
	self.subStates   = {}
	self.inputNodes  = {}
	self.nodeContexts = {}
end

function StoryState:isActive()
	return self.active
end

function StoryState:start( storyNode, prevNode, prevNodeResult )
	self.currentNode = storyNode
	self.context:pendUpdate()
	self.active = true
	storyNode:onStateEnter( self, prevNode, prevNodeResult )
	return self:update()
end

function StoryState:updateSubStates()
	local deadStates = {}
	local subStates = self.subStates
	for state in pairs( subStates ) do
		if state:update() == false then
			deadStates[ state ] = true
		end
	end
	for deadState in pairs( deadStates ) do
		subStates[ deadState ] = nil
	end
end

function StoryState:update()
	self:updateSubStates()
	local context = self.context
	--check proceed to next node
	local currentNode = self.currentNode
	
	local result
	if self.forceEnded then --group ended
		result = 'ok'
	else
		result = self.currentNode:onStateUpdate( self )		
	end

	--- node is still running
	if result == 'running' then return true end
	--- node is done
	if result == 'stop' then return false end

	currentNode:onStateExit( self, result )
	self.active = false
	--find next node
	local nextNodes = currentNode:calcNextNode( self, result )
	if nextNodes then
		for i, nextNode in ipairs( nextNodes ) do
			self.parentState:enterStoryNode( nextNode, currentNode, result )
		end
	end

	context:clearInputTriggers( self )
	return false
end

function StoryState:enterStoryNode( storyNode, prevNode, prevNodeResult )
	local state = StoryState( self.context )
	state.parentState = self
	if state:start( storyNode, prevNode, prevNodeResult ) then
		self.subStates[ state ] = true
	end	
end

--Input trigger node
function StoryState:addInputTrigger( inputNode )
	self.context:addInputTrigger( self, inputNode )
end

function StoryState:endGroup( groupNode )
	if self.parentState and self.parentState.currentNode == groupNode then
		self.parentState:forceEnd()
	else
		local nextNodes = groupNode:calcNextNode( self, nil )
		if nextNodes then
			for i, nextNode in ipairs( nextNodes ) do
				self.parentState:enterStoryNode( nextNode, groupNode, nil )
			end
		end
	end
end

function StoryState:forceEnd()
	self.forceEnded = true
end

function StoryState:getNodeContext( node, affirm )
	local context = self.nodeContexts[ node ]
	if not context and affirm ~= false then
		context = {}
		self.nodeContexts[ node ] = context
	end
	return context
end

function StoryState:getFlagAccessors( node )
	local localDict  = self:getLocalFlagDict( node )
	local scopeDict  = self:getScopeFlagDict( node )
	local globalDict = self:getGlobalFlagDict()
	return localDict:getAccessor(), scopeDict:getAccessor(), globalDict:getAccessor()
end

function StoryState:getFlagDict( scopeName, node )
	if scopeName == 'scope'  then return self:getScopeFlagDict( node ) end
	if scopeName == 'global' then return self:getGlobalFlagDict() end
	if scopeName == 'local'  then return self:getLocalFlagDict( node ) end
	return self:getLocalFlagDict( node )
end

function StoryState:getLocalFlagDict( node )
	return self.context:affirmFlagDict( node.group.id )
end

function StoryState:getScopeFlagDict( node )
	return self.context:affirmFlagDict( '__root' )
end

function StoryState:getGlobalFlagDict()
	return self.context:getGlobalFlagDict()
end

function StoryState:deserializeState( data )
	--TODO
end

function StoryState:serializeState()
	local data = {}
	--TODO
	return data
end

function StoryState:getActors( actorId )
	return self.context:getActors( actorId )
end
