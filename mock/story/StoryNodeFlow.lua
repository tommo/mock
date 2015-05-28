module 'mock'

--------------------------------------------------------------------
--BUILTIN FLOW
--------------------------------------------------------------------
CLASS: StoryNodeStart ( StoryNode )
	:MODEL{}
function StoryNodeStart:onStateEnter( state, prevNode, prevResult ) 
end

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
end

function StoryNodeAND:onStateEnter( state, prevNode, prevResult )
	local context = state.parentState:getNodeContext( self ) 
	local count = context[ prevNode ] or 0
	context[ prevNode ] = count + 1
	if count == 0 then --check other count
		local ready = true
		for node in pairs( self.nodesSrc ) do
			local c = context[ node ] or 0
			if c == 0 then ready = false break end
		end
		if ready then --reduce node count, add a proceed count
			for node in pairs( self.nodesSrc ) do
				context[ node ] = context[ node ] - 1
			end
			context[ 'ready' ] = true
		end
	end
end

function StoryNodeAND:onStateUpdate( state )
	local context = state.parentState:getNodeContext( self )
	if context['ready'] then
		context['ready'] = false
		return 'ok'
	else
		return 'stop'
	end
end


function StoryNodeAND:onLoad( nodeData )
	local nodesSrc = {}
	for i, route in ipairs( self.routesIn ) do
		nodesSrc[ route.nodeSrc ] = true
	end
	self.nodesSrc = nodesSrc
end

--------------------------------------------------------------------
CLASS: StoryNodeLimit ( StoryNode )
	:MODEL{}


function StoryNodeLimit:__init()
	self.routeLimit = 1
end

function StoryNodeLimit:onStateUpdate( state )
	local context = state.parentState:getNodeContext( self ) 
	local count = context['routeCount'] or 0
	if count < self.routeLimit then
		count = count + 1
		context[ 'routeCount' ] = count
		return 'ok'
	else
		return 'stop'
	end
end

function StoryNodeLimit:onLoad()
	local limit = tonumber( self.text ) or 1
	self.routeLimit = limit
end

--------------------------------------------------------------------
CLASS: StoryNodeComment ( StoryNode )
	:MODEL{}



--------------------------------------------------------------------
registerStoryNodeType( 'START', StoryNodeStart )
registerStoryNodeType( 'END',   StoryNodeEnd   )

registerStoryNodeType( 'HUB',   StoryNodeHub   )

registerStoryNodeType( 'AND',   StoryNodeAND   )
registerStoryNodeType( 'LIMIT',    StoryNodeLimit    )

registerStoryNodeType( 'COMMENT', StoryNodeComment )

