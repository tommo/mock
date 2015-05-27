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
	self.nodeVisitCount = {}
end

function StoryState:isActive()
	return self.active
end

function StoryState:start( storyNode, prevNodeResult )
	self.currentNode = storyNode
	self.active = true
	storyNode:onStateEnter( self, prevNodeResult )
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
		--- node is still running
		if result == 'running' then return true end
		--- node is done
	end

	currentNode:onStateExit( self, result )
	self.active = false
	--find next node
	local nextNodes = currentNode:calcNextNode( self, result )
	if nextNodes then
		for i, nextNode in ipairs( nextNodes ) do
			self.parentState:enterStoryNode( nextNode, result )
		end
	end

	owner:clearInputNode( self )
	return false
end

function StoryState:enterStoryNode( storyNode, prevNodeResult )
	local state = StoryState( self.owner )
	state.parentState = self
	if state:start( storyNode, prevNodeResult ) then
		self.subStates[ state ] = true
	end
end

--Input trigger node
function StoryState:addInputNode( inputNode )
	self.owner:addInputNode( self, inputNode )
end

function StoryState:endGroup()
	self.parentState.currentNodeEnded = true
end

--node visit count: for route merge node( AND/OR )
function StoryState:addNodeVisitCount( node )
	self.nodeVisitCount[ node ] = ( self.nodeVisitCount[ node ] or 0 ) + 1
end

function StoryState:getNodeVisitCount( node )
	return self.nodeVisitCount[ node ] or 0
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
end

function StoryState:serializeState()
	local data = {}
	return data
end

--------------------------------------------------------------------
CLASS: StoryController ( Component )
	:MODEL{
		Field 'story' :getset( 'StoryPath' );
	}

function StoryController:__init()
	self.flagDicts = {}
	self.globalFlagDict = FlagDict()
	self.storyPath = false
	self.storyGraph = false
	self.defaultRoleId = 'NOBODY'
end

function StoryController:getStoryPath()
	return self.storyPath
end

function StoryController:setStoryPath( path )
	self.storyPath = path
	self.storyGraph = loadAsset( path )
end

function StoryController:affirmFlagDict( id )
	local flagDict = self.flagDicts[ id ]
	if not flagDict then
		flagDict = FlagDict()
		self.flagDicts[ id ] = flagDict
	end
	return flagDict
end

function StoryController:getFlagDict( id )
	return self.flagDicts[ id ]
end

function StoryController:getGlobalFlagDict()
	return self.globalFlagDict
end

function StoryController:addInputNode( state, node )
	local triggers = self.inputTriggerMap[ state ]
	if not triggers then
		triggers = {}
		self.inputTriggerMap[ state ] = triggers
	end
	table.insert( triggers, node )
end

function StoryController:clearInputNode( state )
	self.inputTriggerMap[ state ] = nil
end

function StoryController:onStart( entity )
	self.inputTriggerMap = {}
	if self.storyGraph then
		local entryNode = self.storyGraph:getRoot()
		self.rootState = StoryState( self )
		self.rootState:start( entryNode )
	end
	self:addCoroutine('actionUpdate')
end

function StoryController:actionUpdate()
	if not self.rootState then return end
	while self.rootState:isActive() do
		coroutine.yield()
		self.rootState:update()
	end
end

function StoryController:acceptInput( roleId, tag, data )
	local defaultRoleId = self.defaultRoleId
	roleId = roleId or defaultRoleId

	for state, triggers in pairs( self.inputTriggerMap ) do
		for _, node in ipairs( triggers ) do
			local nodeTag = node.tag
			local nodeRoleId = node.role or defaultRoleId
			if node.tag == tag
				and nodeRoleId == roleId
				and not ( node.data and node.data~=data )
			then
				state:enterStoryNode( node )
			end
		end
	end

end

function StoryController:deserializeState( data )
end

function StoryController:serializeState()
	local data = {}
	return data
end

