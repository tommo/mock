module 'mock'

--------------------------------------------------------------------
CLASS: WaypointPathFinderManager ( GlobalManager )
	:MODEL {
		Field 'maxTotalIteration'  :int() :range( 1 );
		Field 'maxSingleIteration' :int() :range( 1 );
	}

function WaypointPathFinderManager:__init()
	self.queueSize = 0
	self.maxTotalIteration = 30
	self.maxSingleIteration = 3
	self.minSingleIteration = 1
	self.requestQueue = {}
end


function WaypointPathFinderManager:getKey()
	return 'WaypointPathFinderManager'
end

function WaypointPathFinderManager:onInit( game )
end

function WaypointPathFinderManager:onUpdate( game, dt )
	self:updatePathFinders()
end

function WaypointPathFinderManager:addRequest( request, prior )
	if prior then
		table.insert( self.requestQueue, 1, request )
	else
		table.insert( self.requestQueue, request )
	end
	self.queueSize = self.queueSize + 1
end

function WaypointPathFinderManager:removeRequest( request )
	local idx = table.index( self.requestQueue, request )
	if idx then
		table.remove( self.requestQueue, request )
	end
	self.queueSize = self.queueSize - 1
end

function WaypointPathFinderManager:updatePathFinders()
	if self.queueSize <= 0 then return end

	local totalIteration = 0
	local maxTotalIteration  = self.maxTotalIteration
	local maxSingleIteration = self.maxSingleIteration
	local minSingleIteration = self.minSingleIteration

	local stoppedRequests = {}
	local hasStoppedRequest = false

	for i, request in ipairs( self.requestQueue ) do
		if request.stopped then
			stoppedRequests[ request ] = true
			hasStoppedRequest = true
		else
			local singleIteration
			if totalIteration < maxTotalIteration  then
				singleIteration = maxSingleIteration
				totalIteration  = totalIteration + singleIteration
			else
				minSingleIteration = minSingleIteration
			end
			if request:update( singleIteration ) then
				stoppedRequests[ request ] = true
				hasStoppedRequest = true
			end
		end
	end

	if hasStoppedRequest then	
		--shrink
		local newQueue = {}
		for i, p in pairs( self.requestQueue ) do
			if not stoppedRequests[ p ] then
				table.insert( newQueue, p )
			end
		end
		self.requestQueue = newQueue
		self.queueSize    = #newQueue
	end

end


--------------------------------------------------------------------
local waypointPathFinderManager = WaypointPathFinderManager()
function getWaypointPathFinderManager()
	return waypointPathFinderManager
end



--------------------------------------------------------------------
CLASS: WaypointPathFinderRequest ()

function WaypointPathFinderRequest:__init( owner )
	self.pathfinder = MOAIPathFinder.new()
	self.stopped = false
	self.owner = owner
	self.targetGraph = false
	self.heuristic = false
end

function WaypointPathFinderRequest:init( targetGraph, startWaypoint, targetWaypoint, heuristic )
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

function WaypointPathFinderRequest:stop()
	self.stopped = true
end

function WaypointPathFinderRequest:update( iteration )
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
CLASS: WaypointPathFinder ( Component )
	:MODEL{
	}
mock.registerComponent( 'WaypointPathFinder', WaypointPathFinder )

function WaypointPathFinder:__init()
	self.targetGraph = false
	self.currentRequests = {}
	self.checkingCallback = false
	self.maxDistanceToWaypoint = false
end

function WaypointPathFinder:setMaxDistanceToWaypoint( distance )
	self.maxDistanceToWaypoint = distance
end

function WaypointPathFinder:setGraph( graph )
	self.targetGraph = graph
end

function WaypointPathFinder:stopRequest( request )
	if self.currentRequests[ request ] then
		if not request.stopped then
			request:stop()
		end
		self.currentRequests[ request ] = nil
	end
end

function WaypointPathFinder:clearRequests()
	for request in pairs( self.currentRequests ) do
		if not request.stopped then
			request:stop()
		end
	end
	self.currentRequests = {}
end

function WaypointPathFinder:requestPathFromHere( x, y, z, keepPrevRequests )
	local x0, y0, z0 = self:getEntity():getWorldLoc()
	return self:requestPath( x0,y0,z0, x,y,z, keepPrevRequests )
end

function WaypointPathFinder:requestPath( x0, y0, z0, x1, y1, z1, keepPrevRequests )
	local graph = self.targetGraph
	if not graph then
		_warn( 'no target waypoint graph specified' )
		return nil
	end

	if not keepPrevRequests then self:clearRequests() end

	local request = WaypointPathFinderRequest( self )
	waypointPathFinderManager:addRequest( request )

	--find nearest waypoint
	local maxDistance = self.maxDistanceToWaypoint
	local callback    = self.checkingCallback
	local p0 = graph:findNearestWaypoint( x0, y0, z0, maxDistance, callback )
	local p1 = graph:findNearestWaypoint( x1, y1, z1, maxDistance, callback )
	request:init( graph, p0, p1 )

	self.currentRequests[ request ]	= true

	return request
end

function WaypointPathFinder:reportPath( request, path )
	if request.onReport then
		request.onReport( request, path )
	end
	self.currentRequests[ request ] = nil
	return self:onReport( request, path )
end

function WaypointPathFinder:onReport( request, path )
	if path then
		self:getEntity():tell( 'pathfinder.finished', path, self )
	else
		self:getEntity():tell( 'pathfinder.failed', path, self )
	end
end

function WaypointPathFinder:onDetach( ent )
	self:clearRequests()
end
