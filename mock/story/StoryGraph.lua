module 'mock'

--------------------------------------------------------------------
CLASS: StoryGraph ()
	:MODEL{}

function StoryGraph:__init()
	self.rootGroup = StoryNodeGroup()
end

function StoryGraph:_loadStoryNode( nodeData, group, nodeDict )
	local ntype = nodeData[ 'type' ]
	local node
	local hasChildren = false
	if ntype == 'REF' or ntype == 'GROUP' then
		node = StoryNodeGroup()
		hasChildren = true
	else
		node = StoryNode() --todo: subclass
	end
	node.type    = ntype
	node.id      = nodeData[ 'fullId' ]
	node.text    = nodeData[ 'text' ]
	-- node.groupId = nodeData [ 'group' ]
	if hasChildren then
		for _, childData in ipairs( nodeData[ 'children' ] ) do
			self:_loadStoryNode( childData, node, nodeDict )
		end
	end
	group:addChild( node )
	nodeDict[ node.id ] = node --for edge reference
	node.graph = self
	node:onLoad( nodeData )
	return node
end

function StoryGraph:load( data )
	self.rootGroup = StoryNodeGroup()

	local nodeDict = {}
	local root = self.rootGroup
	--nodes
	for _, nodeData in ipairs( data[ 'rootNodes' ] ) do
		self:_loadStoryNode( nodeData, root, nodeDict )
	end

	--edges/routes
	for _, edgeData in ipairs( data[ 'edges' ] ) do
		local srcId = edgeData[ 'src' ]
		local dstId = edgeData[ 'dst' ]
		local srcNode = nodeDict[ srcId ]
		local dstNode = nodeDict[ dstId ]
		local route = StoryRoute( srcNode, dstNode )
		route.text = edgeData[ 'text' ]
		route.graph = self
		route:onLoad( edgeData )
	end

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
	self.type = 'node'
end

function StoryNode:getType()
	return self.type
end

function StoryNode:update( thread )

end

function StoryNode:getNextNode()
	local routeOut = self.routesOut[1]
	if routeOut then return routeOut.nodeDst end
	return nil
end

function StoryNode:toString()
	return '<'..self:getType()..'>'..self.id .. '['.. self.text..']'
end

function StoryNode:onLoad( nodeData )
end


--------------------------------------------------------------------
CLASS: StoryNodeGroup ( StoryNode )
	:MODEL{}

function StoryNodeGroup:__init()
	self.children = {}
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

--------------------------------------------------------------------
CLASS: StoryRoute ()
	:MODEL{}

function StoryRoute:__init( nodeSrc, nodeDst )
	self.text = ''
	self.nodeSrc = nodeSrc
	self.nodeDst = nodeDst
	table.insert( nodeSrc.routesOut, self ) 
	table.insert( nodeDst.routesIn,  self ) 
end

function StoryRoute:onLoad( data )
end

--------------------------------------------------------------------
local function StoryGraphLoader( node )
	local path = node:getObjectFile('def')
	local data = loadJSONFile( path )
	local graph = StoryGraph()
	graph:load( data )
	return graph
end

registerAssetLoader ( 'story', StoryGraphLoader )
