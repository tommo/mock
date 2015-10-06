module 'mock'

--------------------------------------------------------------------
local storyNodeTypeRegistry = {}
function registerStoryNodeType( tag, clas )
	storyNodeTypeRegistry[ tag ] = clas
end

--------------------------------------------------------------------
CLASS: StoryGraph ()
	:MODEL{}

function StoryGraph:__init()
	self:initRoot()
end

function StoryGraph:initRoot()
	self.rootGroup = StoryScopedGroup()
	self.rootGroup.id = '__root'
	self.rootGroup.text = '__root'
	self.rootGroup.actorId = false
end

function StoryGraph:_loadStoryNode( nodeData, group, scope, nodeDict )
	local ntype = nodeData[ 'type' ]
	local node
	local isGroup = false
	if ntype == 'REF' then
		node = StoryScopedGroup()
		node.scope = scope
		scope = node
		isGroup = true

	elseif ntype == 'GROUP' then
		node = StoryNodeGroup()
		node.scope = scope
		isGroup = true

	else
		local nodeClas = storyNodeTypeRegistry[ ntype ]
		if nodeClas then
			node = nodeClas()
		else
			_warn( 'unknown story node type', ntype, nodeData['fullId'] )
			node = StoryNode()
		end
		node.scope = scope
	end

	node.type    = ntype
	node.id      = nodeData[ 'fullId' ] or 'unknown'
	node.text    = nodeData[ 'text' ]
	-- node.groupId = nodeData [ 'group' ]
	if isGroup then
		for _, childData in ipairs( nodeData[ 'children' ] ) do
			self:_loadStoryNode( childData, node, scope, nodeDict )
		end
	end
	group:addChild( node )
	nodeDict[ node.id ] = node --for edge reference
	node.graph = self
	node.data  = nodeData
	return node
end

function StoryGraph:load( data )
	self:initRoot()

	local nodeDict = {}
	local root = self.rootGroup
	--nodes
	for _, nodeData in ipairs( data[ 'rootNodes' ] ) do
		self:_loadStoryNode( nodeData, root, root, nodeDict )
	end

	--edges/routes
	for _, edgeData in ipairs( data[ 'edges' ] ) do		
		if edgeData['type'] == 'COMMENT' then
			--PASS
		else
			local srcId = edgeData[ 'src' ]
			local dstId = edgeData[ 'dst' ]
			local srcNode = nodeDict[ srcId ]
			local dstNode = nodeDict[ dstId ]
			if srcNode:isDecorator() then
				srcNode:apply( dstNode )
			else
				local route = StoryRoute( srcNode, dstNode )
				route.type  = edgeData[ 'type' ]
				route.text = edgeData[ 'text' ]
				route.graph = self
				route:onLoad( edgeData )
			end
		end
	end
	root.nodeData = {}
	root:loadNodeData()
	
end

function StoryGraph:getRoot()
	return self.rootGroup
end

--------------------------------------------------------------------
CLASS: StoryNode ()
	:MODEL{}

function StoryNode:__init()
	self.id = false
	self.text = ''
	self.routesOut = {}
	self.routesIn  = {}
	self.decorators = {}
	self.type = 'node'
	self.scope = false
	self.group = false
	self.actorId  = false
end

function StoryNode:getActorId()
	if self.actorId then return self.actorId end
	if self.group then return self.group:getActorId() end
	return false
end

function StoryNode:setActorId( id )
	self.actorId = id
end

function StoryNode:getScope()
	return self.scope
end

function StoryNode:getId()
	return self.id
end

function StoryNode:getText()
	return self.text
end

function StoryNode:getType()
	return self.type
end

function StoryNode:isDecorator()
	return false
end


function StoryNode:toString()
	return '[' .. self.id .. '<'..self:getType()..'>]\t'.. self.text
end

function StoryNode:calcNextNode( state, prevNodeResult )
	local nextNodes = {}
	for i, routeOut in ipairs( self.routesOut ) do
		local dst = routeOut.nodeDst
		if routeOut.type == 'NOT' then
			if not prevNodeResult then
				table.insert( nextNodes, dst )
			end
		else
			if prevNodeResult ~= false then
				table.insert( nextNodes, dst )
			end
		end
	end
	return nextNodes
end

function StoryNode:onLoad( nodeData )
end

function StoryNode:onStateEnter( state, prevNode, prevResult )
	-- print( '-> ', self:toString() )
end

function StoryNode:onStateUpdate( state )
	return 'ok'
end

function StoryNode:onStateExit( state )
end

function StoryNode:loadNodeData()
	self:onLoad( self.nodeData )
end
--------------------------------------------------------------------
CLASS: StoryNodeGroup ( StoryNode )
	:MODEL{}

function StoryNodeGroup:__init()
	self.children = {}
	self.startNodes = {}
	self.inputNodes = {}
end

function StoryNodeGroup:addChild( node )
	node.group = self
	table.insert( self.children, node )
end

function StoryNodeGroup:findChildrenByType( typeId )
	local found = {}
	for i, child in ipairs( self.children ) do
		if child:getType() == typeId then
			table.insert( found, child )
		end
	end
	return found
end

function StoryNodeGroup:onStateEnter( state, prevNode, prevResult )
	--start all START node
	--add INPUT node into trigger pool
	for startNode in pairs( self.startNodes ) do
		state:enterStoryNode( startNode, nil, nil )
	end
	for inputNode in pairs( self.inputNodes ) do
		state:addInputTrigger( inputNode )
	end
end

function StoryNodeGroup:onLoad( nodeData )
	local startNodes = {}
	local inputNodes = {}
	for _, child in ipairs( self.children ) do
		local t = child:getType()
		if t == 'START' then
			startNodes[ child ] = true
		elseif t == 'INPUT' then
			inputNodes[ child ] = true
		end
	end
	self.startNodes = startNodes
	self.inputNodes = inputNodes
end

function StoryNodeGroup:onStateUpdate( state )
	return 'running'
end

function StoryNodeGroup:loadNodeData()
	for i, child in ipairs( self.children ) do
		child:loadNodeData()
	end
	self:onLoad( self.nodeData )
end

--------------------------------------------------------------------
CLASS: StoryScopedGroup ( StoryNodeGroup )
	:MODEL{}

function StoryScopedGroup:__init()
end

function StoryScopedGroup:getType()
	return 'ScopedGroup'
end

---------------------------------------------------------------------
CLASS: StoryDecoratorNode ( StoryNode )
	:MODEL{}

function StoryDecoratorNode:isDecorator()
	return true
end

function StoryDecoratorNode:apply( dstNode )
	table.insert( dstNode.decorators , self )
	self:onApply( dstNode )
end

function StoryDecoratorNode:onApply( dstNode )
end

--------------------------------------------------------------------
CLASS: StoryRoute ()
	:MODEL{}

function StoryRoute:__init( nodeSrc, nodeDst )
	self.text = ''
	self.nodeSrc = nodeSrc
	self.nodeDst = nodeDst
	self.type  = 'NORMAL'
	table.insert( nodeSrc.routesOut, self ) 
	table.insert( nodeDst.routesIn,  self ) 
end

function StoryRoute:getType()
	return self.type
end

function StoryRoute:onLoad( data )
	self.valueNumber = tonumber( self.text ) or false
end

--------------------------------------------------------------------
--ASSET Loader
--------------------------------------------------------------------
local function StoryGraphLoader( node )
	local path = node:getObjectFile('def')
	local data = loadJSONFile( path )
	local graph = StoryGraph()
	graph:load( data )
	return graph
end

registerAssetLoader ( 'story_graph', StoryGraphLoader )
