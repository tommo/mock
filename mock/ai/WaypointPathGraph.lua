module 'mock'

local insert = table.insert


--------------------------------------------------------------------
CLASS: WaypointGraphContainer ( Component )
	:MODEL{
		Field 'pathGraphID' :string();
		Field 'serializedData' :variable() :no_edit() :getset( 'SerializedData' );
		'----';
		Field 'clear' :action( 'clear' );
}

registerComponent( 'WaypointGraphContainer', WaypointGraphContainer )

function WaypointGraphContainer:__init()
	self.graph = WaypointPathGraph()
	self.pathGraphID = 'main'
	self.registered = false
end

function WaypointGraphContainer:onAttach( ent )
	ent:_attachTransform( self.graph.trans )
end

function WaypointGraphContainer:onStart( ent )
	self.graph:register( self.pathGraphID )
	self.registred = true
end

function WaypointGraphContainer:onDetach( ent )
	if self.registered then
		self.graph:unregister()
	end
end

function WaypointGraphContainer:getGraph()
	return self.graph
end

function WaypointGraphContainer:getSerializedData()
	return self.graph:getSerializedData()
end

function WaypointGraphContainer:setSerializedData( data )
	self.graph:setSerializedData( data )
end

function WaypointGraphContainer:clear()
	self.graph:clear()
end


---------------------------------------------------------------------
CLASS: Waypoint ()
	:MODEL{}

function Waypoint:__init()
	self.parentGraph = false
	self.name  = 'waypoint'
	self.trans = MOAITransform.new()
	self.nodeId = false
	self.neighbours = {}
end

function Waypoint:setName( n )
	self.name = n
end

function Waypoint:getName()
	return self.name
end

function Waypoint:getNodeId()
	return self.nodeId
end

function Waypoint:getTransform()
	return self.trans
end

function Waypoint:isNeighbour( p1 )
	return self.neighbours[ p1 ] and true or false
end

function Waypoint:addNeighbour( p1, ctype )
	if not self.nodeId then return false end
	if p1 == self then return false end
	ctype = ctype or true -- 'forcelink', 'nolink'
	p1.neighbours[ self ] = ctype
	self.neighbours[ p1 ] = ctype
	self.parentGraph:markDirty()
	return true
end

function Waypoint:removeNeighbour( p1 )
	if not self.nodeId then return false end
	if p1 == self then return false end
	p1.neighbours[ self ] = nil
	self.neighbours[ p1 ] = nil
	self.parentGraph:markDirty()
	return true
end

function Waypoint:clearNeighbours()
	for p in pairs( self.neighbours ) do
		p.neighbours[ self ] = nil
	end
	self.neighbours = {}
	self.parentGraph:markDirty()
end

function Waypoint:getLoc()
	return self.trans:getLoc()
end

function Waypoint:getWorldLoc()
	self.trans:forceUpdate()
	return self.trans:getWorldLoc()
end

function Waypoint:setLoc( x, y, z )
	self.trans:setLoc( x, y, z )
	if self.parentGraph then
		self.parentGraph:markDirty()
	end
end


--------------------------------------------------------------------
CLASS: WaypointPathGraph ( PathGraph )
	:MODEL{}

function WaypointPathGraph:__init()
	self.pathGraph = MOAIVecPathGraph.new()
	self.nodeCount = 0
	self.waypoints   = {}
	self.tmpConnections = {}
	self.trans = MOAITransform.new()
end

function WaypointPathGraph:setSerializedData( data )
	if not data then return end
	local waypoints = {}
	self.waypoints = waypoints
	
	--load waypoints
	for i, pdata in ipairs( data.waypoints ) do
		local p = self:addWaypoint()
		p:setLoc( unpack( pdata.loc ) )
	end
	for i, conn in ipairs( data.connections ) do
		local id0, id1, ctype = unpack( conn )
		self:connectWaypoints( id0, id1, ctype )
	end
	self:markDirty()
end

function WaypointPathGraph:getSerializedData()
	--save waypoints
	local connections = {}
	local waypoints = {}
	for i, p in ipairs( self.waypoints ) do
		waypoints[ i ] = {
			loc = { p:getLoc() }
		}
		for n, ctype in pairs( p.neighbours ) do
			if n.nodeId > i then
				table.insert( connections, { p.nodeId, n.nodeId, ctype } )
			end
		end
	end
	return {
		waypoints = waypoints,
		connections = connections
	}
end

function WaypointPathGraph:clear()
	self.waypoints = {}
	self:markDirty()
end

function WaypointPathGraph:addWaypoint()
	local p = Waypoint()
	self.nodeCount = self.nodeCount + 1
	p.nodeId = self.nodeCount	
	p.parentGraph = self
	inheritTransform( p.trans, self.trans )
	table.insert( self.waypoints, p )
	self:markDirty()
	return p
end

function WaypointPathGraph:removeWaypoint( wp )
	local idx = table.index( self.waypoints, wp )
	if not idx then return false end
	wp:clearNeighbours()
	table.remove( self.waypoints, idx )
	self.nodeCount = self.nodeCount - 1
	local waypoints = self.waypoints
	for i = idx, self.nodeCount do
		local p = waypoints[ i ]
		p.nodeId = i
	end
	self:markDirty()
end

function WaypointPathGraph:getWaypoint( id )
	return self.waypoints[ id ]
end

function WaypointPathGraph:findWaypointByName( name )
	for i, p in ipairs( self.waypoints ) do
		if p.name == name then return p end
	end
	return nil
end

function WaypointPathGraph:connectWaypoints( id1, id2, ctype )
	local p1 = self.waypoints[ id1 ]
	local p2 = self.waypoints[ id2 ]
	if p1 and p2 then
		return p1:addNeighbour( p2, ctype )
	else
		_error( 'invalid waypoint id', id1, id2 )
	end
	return false
end

function WaypointPathGraph:disconnectWaypoints( id1, id2 )
	local p1 = self.waypoints[ id1 ]
	local p2 = self.waypoints[ id2 ]
	if p1 and p2 then
		return p1:removeNeighbour( p2 )
	end
	return false
end

function WaypointPathGraph:findWaypointByLoc( x, y, padding )
	padding = padding or 8
	local pad2 = padding*padding
	for i, wp in ipairs( self.waypoints ) do
		local x0, y0 = wp:getLoc()
		local dx, dy = x - x0, y - y0
		if dx*dx + dy*dy < pad2 then return wp end
	end
end

function WaypointPathGraph:findConnectionByLoc( x, y, padding )
end

function WaypointPathGraph:_addTmpConnection( p1, p2, ctype )
	self.tmpConnections[ p1 ] = { p1, p2, ctype }
end

function WaypointPathGraph:_clearTmpConnections()
	self.tmpConnections = {}
end

function WaypointPathGraph:findNearestWaypoint( x, y, z, maxDistance, checkingCallback )
	--TODO: some borad phase? QUAD tree? 
	-- if checkingCallback and checkingCallback( )
	local minDistance = false
	local candidate = false
	for i, p in ipairs( self.waypoints ) do
		local x0, y0, z0 = p:getWorldLoc()
		local distance = distance3Sqrd( x0,y0,z0, x,y,z )
		print( 'check',i,distance, x0,y0,z0 )
		if ( ( not maxDistance ) or ( maxDistance > distance ) )
			and ( ( not candidate ) or ( distance < minDistance ) )
			and ( ( not checkingCallback ) or ( checkingCallback( p ) ) )
		then
			candidate = p
			minDistance = distance
		end
	end
	return candidate
end

--Virtual functions
function WaypointPathGraph:buildNavigatePath( request, nodePath )
	local waypoints = self.waypoints
	local output = {}
	for i, pid in ipairs( nodePath ) do
		local wp = waypoints[ pid ]
		insert( output, { wp:getWorldLoc() } )
	end
	insert( output, 1, { request:getStartLoc() } )
	insert( output, { request:getTargetLoc() } )
	return output
end

function WaypointPathGraph:buildMOAIPathGraph()
	local graph = MOAIVecPathGraph.new()
	local count = self.nodeCount
	graph:reserveNodes( count )

	for i, wp in ipairs( self.waypoints ) do
		local id = i
		local x, y, z = wp:getWorldLoc()
		graph:setNode( i, x, y, z )
		for neighbour, ctype in pairs( wp.neighbours ) do
			local id1 = neighbour.nodeId
			if ctype ~= 'nolink' and id1 > id then
				graph:setNeighbors( id, id1, true )
			end
		end
	end

	return graph
end

function WaypointPathGraph:updatePathFinderOptions( pf, owner, context )
	--implementation depedent
	-- pf:setmHeuristic
end

function WaypointPathGraph:getNodeId( x, y, z, owner, context )
	local wp = self:findNearestWaypoint( x,y,z )
	print( x,y,z, wp:getWorldLoc() )
	return wp and wp.nodeId or false
end
