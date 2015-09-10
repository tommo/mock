module 'mock'

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
	self.parentGraph.needRebuild = true
	return true
end

function Waypoint:removeNeighbour( p1 )
	if not self.nodeId then return false end
	if p1 == self then return false end
	p1.neighbours[ self ] = nil
	self.neighbours[ p1 ] = nil
	self.parentGraph.needRebuild = true
	return true
end

function Waypoint:clearNeighbours()
	for p in pairs( self.neighbours ) do
		p.neighbours[ self ] = nil
	end
	self.neighbours = {}
	self.parentGraph.needRebuild = true
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
		self.parentGraph.needRebuild = true
	end
end

--------------------------------------------------------------------
CLASS: WaypointGraph ( Component )
	:MODEL{
		Field 'serializedData' :variable() :no_edit() :getset( 'SerializedData' );
}

registerComponent( 'WaypointGraph', WaypointGraph )

function WaypointGraph:__init()
	self.waypoints   = {}
	self.tmpConnections = {}

	self.nodeCount = 0
	self.pathGraph = MOAIVecPathGraph.new()
	self.finderQueue = {}
	self.maxTotalIteration  = 50
	self.maxSingleIteration = 5
	self.trans = MOAITransform.new()
	self.needRebuild = true
end

function WaypointGraph:onAttach( ent )
	ent:_attachTransform( self.trans )
end

function WaypointGraph:onDetach( ent )
end

function WaypointGraph:setSerializedData( data )
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
	self.needRebuild = true --?

end

function WaypointGraph:getSerializedData()
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

function WaypointGraph:addWaypoint()
	local p = Waypoint()
	self.nodeCount = self.nodeCount + 1
	p.nodeId = self.nodeCount	
	p.parentGraph = self
	inheritTransform( p.trans, self.trans )
	table.insert( self.waypoints, p )
	self.needRebuild = true
	return p
end

function WaypointGraph:removeWaypoint( wp )
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
	self.needRebuild = true
end

function WaypointGraph:getWaypoint( id )
	return self.waypoints[ id ]
end

function WaypointGraph:findWaypointByName( name )
	for i, p in ipairs( self.waypoints ) do
		if p.name == name then return p end
	end
	return nil
end

function WaypointGraph:connectWaypoints( id1, id2, ctype )
	local p1 = self.waypoints[ id1 ]
	local p2 = self.waypoints[ id2 ]
	if p1 and p2 then
		return p1:addNeighbour( p2, ctype )
	else
		_error( 'invalid waypoint id', id1, id2 )
	end
	return false
end

function WaypointGraph:disconnectWaypoints( id1, id2 )
	local p1 = self.waypoints[ id1 ]
	local p2 = self.waypoints[ id2 ]
	if p1 and p2 then
		return p1:removeNeighbour( p2 )
	end
	return false
end

function WaypointGraph:buildMOAIPathGraph()
	local graph = MOAIVecPathGraph.new()
	self.pathGraph = graph
	self.needRebuild = false
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

function WaypointGraph:affirmMOAIPathGraph()
	if self.needRebuild then
		self:buildMOAIPathGraph()
	end
	return self.pathGraph
end

function WaypointGraph:requestPath( x, y, z )
end

function WaypointGraph:findWaypointByLoc( x, y, padding )
	padding = padding or 8
	local pad2 = padding*padding
	for i, wp in ipairs( self.waypoints ) do
		local x0, y0 = wp:getLoc()
		local dx, dy = x - x0, y - y0
		if dx*dx + dy*dy < pad2 then return wp end
	end
end

function WaypointGraph:findConnectionByLoc( x, y, padding )
end

function WaypointGraph:_addTmpConnection( p1, p2, ctype )
	self.tmpConnections[ p1 ] = { p1, p2, ctype }
end

function WaypointGraph:_clearTmpConnections()
	self.tmpConnections = {}
end

function WaypointGraph:findNearestWaypoint( x, y, z, maxDistance, checkingCallback )
	--TODO: some borad phase? QUAD tree? 
	-- if checkingCallback and checkingCallback( )
	local minDistance = false
	local candidate = false
	for i, p in ipairs( self.waypoints ) do
		local x0, y0, z0 = p:getLoc()
		local distance = distance3( x0,y0,z0, x,y,z )

		if ( maxDistance > distance ) 
			and ( ( not candidate ) or ( distance < minDistance ) )
			and ( ( not checkingCallback ) or ( checkingCallback( p ) ) )
		then
			candidate = p
			minDistance = distance
		end
	end
	return candidate

end
