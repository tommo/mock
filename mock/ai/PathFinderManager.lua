module 'mock'

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
end


function PathFinderManager:getKey()
	return 'PathFinderManager'
end

function PathFinderManager:onInit( game )
end

function PathFinderManager:onUpdate( game, dt )
	self:updatePathFinders()
end

function PathFinderManager:addRequest( request, prior )
	if prior then
		table.insert( self.requestQueue, 1, request )
	else
		table.insert( self.requestQueue, request )
	end
	self.queueSize = self.queueSize + 1
end

function PathFinderManager:removeRequest( request )
	local idx = table.index( self.requestQueue, request )
	if idx then
		table.remove( self.requestQueue, request )
	end
	self.queueSize = self.queueSize - 1
end

function PathFinderManager:updatePathFinders()
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


--------------------------------------------------------------------
local pathFinderManager = PathFinderManager()
function getPathFinderManager()
	return pathFinderManager
end

