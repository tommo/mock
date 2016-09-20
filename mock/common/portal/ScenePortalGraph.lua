module 'mock'
--------------------------------------------------------------------
CLASS: ScenePortalGraphNode ()
	:MODEL{}

function ScenePortalGraphNode:__init()
	self.id = false
	self.connections = {}
end

function ScenePortalGraphNode:load()
end


---------------------------------------------------------------------
CLASS: ScenePortalGraphConnection ()

function ScenePortalGraphConnection:__init()
	self.nodeA = false
	self.nodeB = false
	self.data  = false
end


--------------------------------------------------------------------
CLASS: ScenePortalGraph ()
	:MODEL{}

function ScenePortalGraph:__init()
	self.path = false
	self.nodes = {}
	self.connections = {}
end

function ScenePortalGraph:getPath()
	return self.path
end

function ScenePortalGraph:findConnection( id )
	for i, conn in ipairs( self.connections ) do
		if conn.nodeA.id == id then
			return conn.nodeB.id
		elseif conn.nodeB.id == id then
			return conn.nodeA.id
		end
	end
	return false
end

function ScenePortalGraph:loadData( data )
	local nodes = {}
	local connections = {}
	for i, nodeData in ipairs( data[ 'nodes' ] ) do
		local id = nodeData[ 'fullname' ]
		local node = nodes[ id ]
		if node then
			_warn( 'duplicated node in portal graph', id )
		else
			node = ScenePortalGraphNode()
			node.id = id
			node.name = nodeData[ 'name' ]
			nodes[ id ] = node
		end
	end

	for i, connData in ipairs( data[ 'connections' ] ) do
		local idA = connData[ 'a' ]
		local idB = connData[ 'b' ]
		local data = connData[ 'data' ]
		local conn = ScenePortalGraphConnection()
		local nodeA = assert( nodes[ idA ] )
		local nodeB = assert( nodes[ idB ] )
		conn.nodeA = nodeA
		conn.nodeB = nodeB
		nodeA.connections[ nodeB ] = conn
		nodeB.connections[ nodeA ] = conn
		conn.data = data
		connections[ i ] = conn
	end
	self.nodes = nodes
	self.connections = connections
	return true
end

--------------------------------------------------------------------
local function loadScenePortalGraph( node )
	local data = loadAssetDataTable( node:getObjectFile('def') )
	local graph = ScenePortalGraph()
	graph.path = node:getPath()
	graph:loadData( data )
	return graph
end

mock.registerAssetLoader( 'scene_portal_graph', loadScenePortalGraph )
