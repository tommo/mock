module 'mock'

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
	self.sceneTriggerMap = {}
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
	self:pendUpdate()
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

	self:pendUpdate()
end

function StoryContext:pendUpdate()
	self.needUpdate = true
end

function StoryContext:tryUpdate( force )
	if self.needUpdate or force then
		self.rootState:update()
	end
end
----
function StoryContext:addInputTrigger( state, node )
	local triggers = self.inputTriggerMap[ state ]
	if not triggers then
		triggers = {}
		self.inputTriggerMap[ state ] = triggers
	end
	table.insert( triggers, node )
	node:onStart( state )
end

function StoryContext:clearInputTriggers( state )
	local triggers = self.inputTriggerMap[ state ]
	if triggers then
		for _, node in ipairs( triggers ) do
			node:onStop( state )
		end
		self.inputTriggerMap[ state ] = nil
	end
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

--------------------------------------------------------------------
function StoryContext:addSceneEventTrigger( state, sceneEventNode )	
	local triggers = self.sceneTriggerMap[ state ]
	if not triggers then
		triggers = {}
		self.sceneTriggerMap[ state ] = triggers
	end
	triggers[ sceneEventNode ] = false
end

function StoryContext:clearSceneEventTriggers( state )
	self.sceneTriggerMap[ state ] = nil
end

function StoryContext:sendSceneEvent( sceneId, event )
	if not sceneId then return end
	-- print( 'context:', 'scene event', sceneId, event )
	for state, triggers in pairs( self.sceneTriggerMap ) do
		for sceneEventNode, subState in pairs( triggers ) do
			if sceneEventNode.sceneId == sceneId then
				if subState then
					if event == 'exit' then
						if subState then
							subState:forceEnd()
						end
						triggers[ sceneEventNode ] = nil
					end
				else
					if event == 'enter' then
						local newSubState = state:enterStoryNode( sceneEventNode, nil, nil )
						triggers[ sceneEventNode ] = newSubState
					end
				end
			end --if
		end -- for
	end

end

--------------------------------------------------------------------

function StoryContext:getRoleControllers( roleId )
	return getStoryManager():getRoleControllers( roleId )
end


function StoryContext:isActive()
	return getStoryManager():getActiveContext() == self
end

function StoryContext:setActive()
	getStoryManager():setActiveContext( self )
end

--------------------------------------------------------------------

function StoryContext:deserializeState( data )
	--TODO
end

function StoryContext:serializeState()
	local data = {}
	--TODO
	return data
end
