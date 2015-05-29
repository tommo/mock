module 'mock'

--------------------------------------------------------------------
CLASS: StoryState ()
	:MODEL{}

function StoryState:__init( owner )
	self.currentNode      = false
	self.currentNodeEnded = false
	self.active      = false
	self.owner       = owner
	self.subStates   = {}
	self.inputNodes  = {}
	self.nodeContexts = {}
end

function StoryState:isActive()
	return self.active
end

function StoryState:start( storyNode, prevNode, prevNodeResult )
	self.currentNode = storyNode
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
	local owner = self.owner
	--check proceed to next node
	local currentNode = self.currentNode
	
	local result
	if self.currentNodeEnded then --group ended
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

	owner:clearInputNode( self )
	return false
end

function StoryState:enterStoryNode( storyNode, prevNode, prevNodeResult )
	local state = StoryState( self.owner )
	state.parentState = self
	if state:start( storyNode, prevNode, prevNodeResult ) then
		self.subStates[ state ] = true
	end
end

--Input trigger node
function StoryState:addInputNode( inputNode )
	self.owner:addInputNode( self, inputNode )
end

function StoryState:endGroup( groupNode )
	if self.parentState and self.parentState.currentNode == groupNode then
		self.parentState.currentNodeEnded = true
	else
		local nextNodes = groupNode:calcNextNode( self, nil )
		if nextNodes then
			for i, nextNode in ipairs( nextNodes ) do
				self.parentState:enterStoryNode( nextNode, groupNode, nil )
			end
		end
	end
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
	if scopeName == 'scope' then return self:getScopeFlagDict( node ) end
	if scopeName == 'global' then return self:getGlobalFlagDict() end
	if scopeName == 'local' then return self:getLocalFlagDict( node ) end
	return self:getLocalFlagDict( node )
end

function StoryState:getLocalFlagDict( node )
	return self.owner:affirmFlagDict( node.group.id )
end

function StoryState:getScopeFlagDict( node )
	return self.owner:affirmFlagDict( node.scope.id )
end

function StoryState:getGlobalFlagDict()
	return self.owner:getGlobalFlagDict()
end

function StoryState:deserializeState( data )
	--TODO
end

function StoryState:serializeState()
	local data = {}
	--TODO
	return data
end

function StoryState:getRoleControllers( roleId )
	return self.owner:getRoleControllers( roleId )
end

--------------------------------------------------------------------
CLASS: StoryContext ( Component )
	:MODEL{
		Field 'story' :asset( 'story' ) :getset( 'StoryPath' );
	}

function StoryContext:__init()
	self.flagDicts = {}
	self.globalFlagDict = FlagDict( self, '__GLOBAL' )
	self.storyPath = false
	self.storyGraph = false
	self.defaultRoleId = '_NOBODY'
	self.inputTriggerMap = {}
	self.flagTriggerMap  = {}
end

function StoryContext:getStoryPath()
	return self.storyPath
end

function StoryContext:setStoryPath( path )
	self.storyPath = path
	self.storyGraph = loadAsset( path )
end

function StoryContext:affirmFlagDict( id )
	local flagDict = self.flagDicts[ id ]
	if not flagDict then
		flagDict = FlagDict( self, id )
		self.flagDicts[ id ] = flagDict
	end
	return flagDict
end

function StoryContext:getFlagDict( id )
	return self.flagDicts[ id ]
end

function StoryContext:getGlobalFlagDict()
	return self.globalFlagDict
end

----
function StoryContext:onFlagChanged( nodeId, id )
	--TODO: lazy update support?
	self.needUpdate = true
end

----
function StoryContext:reset()
	self.inputTriggerMap = {}
	self.roleControllers = {}
end

function StoryContext:start()
	self:reset()

	if self.storyGraph then
		self.defaultRoleId = self.storyGraph:getDefaultRole()
		local entryNode = self.storyGraph:getRoot()
		self.rootState = StoryState( self )
		self.rootState:start( entryNode )
	end
	self.needUpdate = true
end

function StoryContext:tryUpdate( force )
	if self.needUpdate or force then
		self.rootState:update()
	end
end
----
function StoryContext:addInputNode( state, node )
	local triggers = self.inputTriggerMap[ state ]
	if not triggers then
		triggers = {}
		self.inputTriggerMap[ state ] = triggers
	end
	table.insert( triggers, node )
end

function StoryContext:clearInputNode( state )
	self.inputTriggerMap[ state ] = nil
end

function StoryContext:sendInput( roleId, tag, data )
	local defaultRoleId = self.defaultRoleId
	roleId = roleId or defaultRoleId

	for state, triggers in pairs( self.inputTriggerMap ) do
		for _, node in ipairs( triggers ) do
			local nodeTag = node.tag
			local nodeRoleId = node:getRoleId() or defaultRoleId
			if node.tag == tag
				and nodeRoleId == roleId
				and not ( node.data and node.data~=data )
			then
				state:enterStoryNode( node, nil, nil )
			end
		end
	end

end

----
function StoryContext:registerRoleController( controller )
	local roleId = controller:getRoleId()
	local roles = self.roleControllers[ roleId ]
	if not roles then
		roles = {}
		self.roleControllers[ roleId ] = roles
	end
	table.insert( roles, controller )
end

function StoryContext:removeRoleController( controller )
	local roleId = controller:getRoleId()
	local roles = self.roleControllers[ roleId ]
	if not roles then return end
	for i, r in ipairs( roles ) do
		if r == controller then
			table.remove( roles, i )
			return
		end
	end
end

function StoryContext:getRoleControllers( roleId )
	local roles = self.roleControllers[ roleId ]
	return roles or {}
end

----
function StoryContext:deserializeState( data )
	--TODO
end

function StoryContext:serializeState()
	local data = {}
	--TODO
	return data
end
