module 'mock'

--------------------------------------------------------------------
--BUILTIN FLOW
--------------------------------------------------------------------
CLASS: StoryNodeStart ( StoryNode )
	:MODEL{}

--------------------------------------------------------------------
CLASS: StoryNodeEnd ( StoryNode )
	:MODEL{}

function StoryNodeEnd:onStateUpdate( state )
	--stop current scope
	state:endGroup()
	return 'ok'
end

--------------------------------------------------------------------
CLASS: StoryNodeHub ( StoryNode )
	:MODEL{}

--------------------------------------------------------------------
CLASS: StoryNodeAND ( StoryNode )
	:MODEL{}

function StoryNodeAND:__init()
	self.routeCount = 0
end

function StoryNodeAND:onStateEnter( state )
	state.parentState:addNodeVisitCount( self )
end

function StoryNodeAND:onStateUpdate( state )
	if state.parentState:getNodeVisitCount( self ) >= self.routeCount then
		return 'ok'
	else
		return 'running'
	end
end

function StoryNodeAND:onLoad( nodeData )
	self.routeCount = #self.routesIn
end

--------------------------------------------------------------------
CLASS: StoryNodeOR ( StoryNode )
	:MODEL{}


function StoryNodeOR:onStateEnter( state )
	state.parentState:addNodeVisitCount( self )
end

function StoryNodeOR:onStateUpdate( state )
	if state.parentState:getNodeVisitCount() > 0 then
		return 'ok'
	else
		return 'running'
	end
end

--------------------------------------------------------------------
CLASS: StoryNodeUNO ( StoryNode )
	:MODEL{}

--------------------------------------------------------------------
CLASS: StoryNodeSTOP ( StoryNode )
	:MODEL{}

--------------------------------------------------------------------
CLASS: StoryNodeComment ( StoryNode )
	:MODEL{}

registerStoryNodeType( 'START', StoryNodeStart )
registerStoryNodeType( 'END',   StoryNodeEnd   )
registerStoryNodeType( 'HUB',   StoryNodeHub   )
registerStoryNodeType( 'AND',   StoryNodeAND   )
registerStoryNodeType( 'OR',    StoryNodeOR    )
registerStoryNodeType( 'UNO',   StoryNodeUNO   )
registerStoryNodeType( 'STOP',  StoryNodeSTOP  )
registerStoryNodeType( 'COMMENT', StoryNodeComment )

