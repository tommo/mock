module 'mock'

--------------------------------------------------------------------
CLASS: StoryContext ()

function StoryContext:__init()
	self.parentContext = false
	self.childContexts = {}

	self.storyGraph    = false

	self.flagDicts = {}

	self.inputTriggerMap = {}
	self.flagTriggerMap  = {}
	self.needUpdate    = true
	self.rootState     = false
	self.ownerActor    = false
	
	self:affirmFlagDict( '__root' )

end

function StoryContext:createChildContext()
	local context = StoryContext()
	table.insert( self.childContexts, context )
	context.parentContext = self
	return context
end

function StoryContext:removeChildContext( context )
	local idx = table.index( self.childContexts, context )
	table.remove( self.childContexts, idx )
	context.parentContext = false
end

function StoryContext:setStoryGraph( graph )
	self.storyGraph = graph
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
	return getStoryManager():getGlobalFlagDict()
end

function StoryContext:getLocalFlagDict()
	return self:getFlagDict( '__root' )
end

----
function StoryContext:onFlagChanged( nodeId, id )
	--TODO: lazy update support?
	self:pendUpdate()
end

----
function StoryContext:reset()
	self.inputTriggerMap = {}
	self.childContexts   = {}
	self.rootState       = false
end

function StoryContext:start()
	self:reset()

	if self.storyGraph then
		local entryNode = self.storyGraph:getRoot()
		self.rootState = StoryState( self )
		self.rootState:start( entryNode )
	end

	self:pendUpdate()
end

function StoryContext:pendUpdate()
	self.needUpdate = true
	if self.parentContext then
		return self.parentContext:pendUpdate()
	end
end

function StoryContext:tryUpdate( force )
	if self.needUpdate or force then
		for i, childContext in ipairs( self.childContexts ) do
			childContext:tryUpdate( force )
		end
		if self.rootState then
			self.rootState:update()
		end
	end
end

----
function StoryContext:getActors( actorId )
	if not actorId then
		return { self.ownerActor }
	else
		return getStoryManager():getActors( actorId )
	end
end

function StoryContext:setOwnerActor( actor )
	self.ownerActor = actor
end

function StoryContext:getOwnerActor()
	return self.ownerActor
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

function StoryContext:sendInput( actor, tag, data )
	local actorId = actor:getActorId()
	local isOwner = actor == self.ownerActor
	for state, triggers in pairs( self.inputTriggerMap ) do
		for _, node in ipairs( triggers ) do
			local nodeTag = node.tag
			local nodeActorId = node:getActorId()
			local actorMatched = ( not nodeActorId and isOwner ) or ( nodeActorId == actorId )
			if actorMatched
				and node.tag == tag
				and not ( node.data and node.data~=data )
			then
				state:enterStoryNode( node, nil, nil )
			end
		end
	end
	if self.parentContext then
		return self.parentContext:sendInput( actor, tag, data )
	end
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
