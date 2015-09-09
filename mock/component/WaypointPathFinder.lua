module 'mock'

--------------------------------------------------------------------
CLASS: WaypointPathFinderManager ( GlobalManager )
	:MODEL {
		Field 'maxTotalIteration'  :int() :range( 1 );
		Field 'maxSingleIteration' :int() :range( 1 );
	}

function WaypointPathFinderManager:__init()
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
end

function WaypointPathFinderManager:removeRequest( request )
	local idx = table.index( self.requestQueue, request )
	if idx then table.remove( self.requestQueue, request ) end
end

function WaypointPathFinderManager:updatePathFinders()
	local totalIteration = 0
	local maxTotalIteration  = self.maxTotalIteration
	local maxSingleIteration = self.maxSingleIteration

	local stoppedRequests = {}
	local hasStoppedRequest = false
	for i, request in ipairs( self.requestQueue ) do
		if request.stopped then
			stoppedRequests[ request ] = true
			hasStoppedRequest = true
		else
			local singleIteration
			if totalIteration < maxTotalIteration then
				singleIteration = SINGLE_ITERATION
				totalIteration  = totalIteration + singleIteration
			else
				return 
			end
			if request:update( singleIteration ) then
				stoppedRequests[ request ] = true
				hasStoppedRequest = true
			end
		end
	end

	if hasStoppedRequest then	
		local newQueue = {}
		for i, p in pairs( self.requestQueue ) do
			if not stopFlyingSound[ p ] then
				table.insert( newQueue, p )
			end
		end
		self.requestQueue = newQueue
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
end

function WaypointPathFinderRequest:stop()
	self.stopped = true
end


function WaypointPathFinderRequest:update( iteration )
	local pf = self.pathfinder
	if not pf:findPath( iteration ) then --done
		--report
		local size = pf:getPathSize()
		if size <= 0 then
			self.owner:reportPath( self, false )
			self.stopped = true
			return true
		end

		-- local data
		-- --TODO: stopBefore needs REAL implement
		-- if size>0 then
		-- 	data={}
		-- 	local i0=1
		-- 	-- if pf.stopBefore then i0=2 end --remove last point

		-- 	for i=i0, size do
		-- 		local idx=pf:getPathEntry(i)
		-- 		local x,y=cellAddrToCoord(map,idx)
		-- 		local m=(size-i)*2
		-- 		data[m+1]=x
		-- 		data[m+2]=y
		-- 	end

		-- end
		-- apf[creature]=nil
		-- pfpool[pf]=true
		-- creature:setPath( data, pf.stopBefore )			
		local path = {}
		--TODO
		self.owner:reportPath( self, path )
		return true
	end
end


--------------------------------------------------------------------
CLASS: WaypointPathFinder ( Component )
	:MODEL{
	}
mock.registerComponent( 'WaypointPathFinder', WaypointPathFinder )

function WaypointPathFinder:__init()
	self.targetGraph = false
	self.currentRequests = {}
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

function WaypointPathFinder:requestPath( x0, y0, z0, x, y, z, keepPrevRequests )
	if not self.targetGraph then
		_warn( 'no target waypoint graph specified' )
		return nil
	end

	if not keepPrevRequests then self:clearRequests() end

	local request = WaypointPathFinderRequest( self )
	waypointPathFinderManager:addRequest( request )

	--find nearest waypoint
	
	self.currentRequests[ request ]	= true

	return request
end

function WaypointPathFinder:reportPath( request, path )
	if request.onReport then
		request.onReport( path )
	end
	self.currentRequests[ request ] = nil
	return self:onReportPath( request, path )
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
