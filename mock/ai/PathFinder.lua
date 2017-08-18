module 'mock'

--------------------------------------------------------------------
--Generic Pathfinding Support
--------------------------------------------------------------------
--------------------------------------------------------------------
local _pathFinderManager
function getPathFinderManager()
	return _pathFinderManager
end

--------------------------------------------------------------------
--Manager
--------------------------------------------------------------------
CLASS: PathFinderManager ( GlobalManager )
	:MODEL {
		Field 'maxTotalIteration'  :int() :range( 1 );
		Field 'maxSingleIteration' :int() :range( 1 );
	}

function PathFinderManager:__init()
	self.queueSize = 0
	self.maxTotalIteration = 30
	self.maxSingleIteration = 30
	self.minSingleIteration = 1
	self.requestQueue = {}
	self.graphRegistry= {}
end


function PathFinderManager:getKey()
	return 'PathFinderManager'
end

function PathFinderManager:onInit( game )
end

function PathFinderManager:onUpdate( game, dt )
	self:updateRequests()
end

function PathFinderManager:addRequest( request, prior )
	if prior then
		table.insert( self.requestQueue, 1, request )
	else
		table.insert( self.requestQueue, request )
	end
	self.queueSize = self.queueSize + 1
	return request
end

function PathFinderManager:removeRequest( request )
	local idx = table.index( self.requestQueue, request )
	if idx then
		table.remove( self.requestQueue, request )
	end
	self.queueSize = self.queueSize - 1
end

function PathFinderManager:updateRequests()
	if self.queueSize <= 0 then return end

	local totalIteration = 0
	local maxTotalIteration  = self.maxTotalIteration
	local maxSingleIteration = self.maxSingleIteration
	local minSingleIteration = self.minSingleIteration

	local stoppedRequests = {}
	local hasStoppedRequest = false
	
	local averageIteration = math.floor( maxTotalIteration/self.queueSize )

	for i, request in ipairs( self.requestQueue ) do
		if request.stopped then
			stoppedRequests[ request ] = true
			hasStoppedRequest = true
		else
			local singleIteration = 0
			if totalIteration < maxTotalIteration  then
				singleIteration = math.min( maxSingleIteration, averageIteration )
				totalIteration  = totalIteration + singleIteration
			end
			singleIteration = math.max( singleIteration, minSingleIteration )
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

function PathFinderManager:registerGraph( id, graph )
	self.graphRegistry[ id ] = graph
end

function PathFinderManager:unregisterGraph( id, graph )
	local graph0 = self.graphRegistry[ id ]
	if graph == graph0 then
		self.graphRegistry[ id ] = nil
		return true
	end
	return false
end

function PathFinderManager:getGraph( id )
	return self.graphRegistry[ id ]
end

function PathFinderManager:clearGraph()
	self.graphRegistry = {}
end



--------------------------------------------------------------------
CLASS: PathGraph ()
	:MODEL{
	}

function PathGraph:__init()
	self.pathGraph = MOAIVecPathGraph.new()
	self._dirty = true
	self.graphID     = false
end

function PathGraph:affirmMOAIPathGraph()
	if self._dirty then
		local graph = self:buildMOAIPathGraph()
		if graph then
			self.pathGraph = graph
			self._dirty = false
		else
			_warn( 'fail building Path Graph', self )
		end
	end
	return self.pathGraph
end

function PathGraph:buildMOAIPathGraph()
	return false
end

function PathGraph:markDirty()
	self._dirty = true
end

function PathGraph:register( id )
	self.graphID = id
	_pathFinderManager:registerGraph( id, self )
end

function PathGraph:unregister()
	if not self.graphID then return end
	_pathFinderManager:unregisterGraph( self.graphID, self )
end

function PathGraph:createPathFinderRequest( owner, x0, y0, z0, x1, y1, z1, context )
	local request = PathFinderRequest( self, owner, context )
	if not request:init( x0,y0,z0, x1,y1,z1 ) then return false end
	_pathFinderManager:addRequest( request )
	return request
end

function PathGraph:updatePathFinderOptions( pf, owner, context )
	--implementation depedent
end

function PathGraph:getNodeId( x, y, z, owner, context )
	return false
end

function PathGraph:buildNavigatePath( request, nodePath )
	return false
end
	

--------------------------------------------------------------------
CLASS: PathFinderRequest ()

function PathFinderRequest:__init( graph, owner, context )
	self.stopped     = false

	self.pathfinder   = MOAIPathFinder.new()
	self.owner        = owner
	self.graph        = graph
	self.context      = context
	self.startLoc     = {0,0,0}
	self.targetLoc    = {0,0,0}
	self.startNodeId  = false
	self.targetNodeId = false

	self.onReportCallback = false
end

function PathFinderRequest:getOwner()
	return self.owner
end

function PathFinderRequest:getGraph()
	return self.graph
end

function PathFinderRequest:getStartLoc()
	return unpack( self.startLoc )
end

function PathFinderRequest:getTargetLoc()
	return unpack( self.targetLoc )
end

function PathFinderRequest:getStartNodeId()
	return self.startNodeId
end

function PathFinderRequest:getTargetNodeId()
	return self.targetNodeId
end

function PathFinderRequest:init( x0,y0,z0, x1,y1,z1 )
	self.startLoc     = { x0,y0,z0 }
	self.targetLoc    = { x1,y1,z1 }
	self.startNodeId  = false
	self.targetNodeId = false
	local graph = self.graph
	local owner = self.owner
	local context = self.context

	local moaiPathGraph = graph:affirmMOAIPathGraph()
	if not moaiPathGraph then
		_warn( 'no valid PathGraph' )
		self:stop()
		return false
	end
	local node0 = graph:getNodeId( x0,y0,z0, owner, context )
	local node1 = graph:getNodeId( x1,y1,z1, owner, context )
	if not ( node0 and node1 ) then return false end

	self.startNodeId  = node0
	self.targetNodeId = node1

	local pf = self.pathfinder
	pf:setGraph( moaiPathGraph )
	pf:init( node0, node1 )

	graph:updatePathFinderOptions( pf, owner, context )
	return true
end

function PathFinderRequest:getMoaiPathFinder()
	return self.pathFinder
end

function PathFinderRequest:stop()
	self.stopped = true
end

function PathFinderRequest:update( iteration )
	local pf = self.pathfinder
	if pf:findPath( iteration ) then return false end
	self.stopped = true

	local owner = self.owner

	local size = pf:getPathSize()
	if size <= 0 then
		owner:reportPath( self, false )
		return true
	end

	--report
	local nodePath = {}
	for i = 1, size do
		local nodeId = pf:getPathEntry( i )
		nodePath[ i ] = nodeId
	end

	local navigatePath = self.graph:buildNavigatePath( self, nodePath )
	if navigatePath then
		owner:reportPath( self, navigatePath )
	end
	return true
end

function PathFinderRequest:setCallback( func )
	self.onReportCallback = func
end

--------------------------------------------------------------------
CLASS: PathFinder ( Component )
	:MODEL{
		Field 'targetGraphID' :string();
	}

mock.registerComponent( 'PathFinder', PathFinder )

function PathFinder:__init()
	self.targetGraphID = 'main'
	self.targetGraph   = false
	self.currentRequests = {}
	self.checkingCallback = false
end

function PathFinder:onDetach( ent )
	self:clearRequests()
end

function PathFinder:setTargetGraphID( id )
	self.targetGraphID = id
end

function PathFinder:getTargetGraphID()
	return self.targetGraphID
end

function PathFinder:getTargetGraph()
	local id = self.targetGraphID
	if not id then return false end
	return _pathFinderManager:getGraph( id )
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

function PathFinder:getOptions()
	return self.options
end

function PathFinder:setOptions( options )
	self.options = options
end

function PathFinder:requestPath( x0, y0, z0, x1, y1, z1, context, keepPrevRequests )
	local graph = self:getTargetGraph()
	if not graph then
		_warn( 'no target waypoint graph found' )
		return nil
	end

	if not keepPrevRequests then self:clearRequests() end
	local request = graph:createPathFinderRequest( self, x0,y0,z0, x1,y1,z1, context )
	if request then
		self.currentRequests[ request ]	= true
	end

	return request
end

function PathFinder:requestPathTo( x, y, z, context, keepPrevRequests )
	local x0, y0, z0 = self:getEntity():getWorldLoc()
	return self:requestPath( x0,y0,z0, x,y,z, context, keepPrevRequests )
end

function PathFinder:reportPath( request, path )
	if request.onReportCallback then
		request.onReportCallback( request, path )
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


--------------------------------------------------------------------
_pathFinderManager = PathFinderManager()
