module 'mock'

--------------------------------------------------------------------
CLASS: PathFinderRequest ()

function PathFinderRequest:__init( owner )
	self.pathfinder = MOAIPathFinder.new()
	self.stopped = false
	self.owner = owner
	self.targetGraph = false
	self.heuristic = false
end

function PathFinderRequest:init( targetGraph, startWaypoint, targetWaypoint, heuristic )
	self.targetGraph    = targetGraph
	self.startWaypoint  = startWaypoint
	self.targetWaypoint = targetWaypoint
	local pathGraph = targetGraph:affirmMOAIPathGraph()
	if not pathGraph then
		_warn( 'no valid PathGraph' )
		self:stop()
		return false
	end

	local pf = self.pathfinder
	pf:setGraph( pathGraph )
	local id0 = startWaypoint:getNodeId()
	local id1 = targetWaypoint:getNodeId()
	pf:init( id0, id1 )

	if heuristic then
		pf:setHeuristic( heuristic )
	end

end

function PathFinderRequest:stop()
	self.stopped = true
end

function PathFinderRequest:update( iteration )
	local pf = self.pathfinder
	if pf:findPath( iteration ) then return false end
	--report
	local size = pf:getPathSize()
	if size <= 0 then
		self.owner:reportPath( self, false )
		self.stopped = true
		return true
	end

	local graph = self.targetGraph
	local waypoints = graph.waypoints
	-- local data
	
	local path = {}
	for i = 1, size do
		local nodeId = pf:getPathEntry( i )
		local p = waypoints[ nodeId ]
		path[ i ] = p
	end

	self.owner:reportPath( self, path )
	return true
end


--------------------------------------------------------------------
CLASS: PathFinder ( Component )
	:MODEL{
		Field 'targetGraph' :type( WaypointGraph ) :getset( 'Graph' )
	}

mock.registerComponent( 'PathFinder', PathFinder )

function PathFinder:__init()
	self.targetGraph = false
	self.currentRequests = {}
	self.checkingCallback = false
	self.maxDistanceToWaypoint = false
end

function PathFinder:setMaxDistanceToWaypoint( distance )
	self.maxDistanceToWaypoint = distance
end

function PathFinder:setGraph( graph )
	self.targetGraph = graph
end

function PathFinder:getGraph()
	return self.targetGraph
end

function PathFinder:stopRequest( request )
	if self.currentRequests[ request ] then
		if not request.stopped then
			request:stop()
		end
		self.currentRequests[ request ] = nil
	end
end

function PathFinder:clearRequests()
	for request in pairs( self.currentRequests ) do
		if not request.stopped then
			request:stop()
		end
	end
	self.currentRequests = {}
end

function PathFinder:requestPathFromHere( x, y, z, keepPrevRequests )
	local x0, y0, z0 = self:getEntity():getWorldLoc()
	return self:requestPath( x0,y0,z0, x,y,z, keepPrevRequests )
end

function PathFinder:requestPath( x0, y0, z0, x1, y1, z1, keepPrevRequests )
	local graph = self.targetGraph
	if not graph then
		_warn( 'no target waypoint graph specified' )
		return nil
	end

	if not keepPrevRequests then self:clearRequests() end

	local request = PathFinderRequest( self )
	pathFinderManager:addRequest( request )

	--find nearest waypoint
	local maxDistance = self.maxDistanceToWaypoint
	local callback    = self.checkingCallback
	local p0 = graph:findNearestWaypoint( x0, y0, z0, maxDistance, callback )
	local p1 = graph:findNearestWaypoint( x1, y1, z1, maxDistance, callback )
	request:init( graph, p0, p1 )

	self.currentRequests[ request ]	= true

	return request
end

function PathFinder:reportPath( request, path )
	if request.onReport then
		request.onReport( request, path )
	end
	self.currentRequests[ request ] = nil
	return self:onReport( request, path )
end

function PathFinder:onReport( request, path )
	if path then
		self:getEntity():tell( 'pathfinder.finished', path, self )
	else
		self:getEntity():tell( 'pathfinder.failed', path, self )
	end
end

function PathFinder:onDetach( ent )
	self:clearRequests()
end