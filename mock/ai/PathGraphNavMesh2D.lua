module 'mock'

CLASS: PathGraphNavMesh2D ( PathGraph )
	:MODEL{}

function PathGraphNavMesh2D:buildFromPolyPaths( polyPaths )
	local navmesh = MOCKNavMesh.new()
	navmesh:buildFromPolyPaths( polyPaths )
	self.pathGraph = navmesh
	self._dirty = false
end

function PathGraphNavMesh2D:buildMOAIPathGraph()
	local graph = MOCKNavMesh.new()
	return graph
end

function PathGraphNavMesh2D:updatePathFinderOptions( pf, owner, context )
	--implementation depedent
end

function PathGraphNavMesh2D:getNodeId( x, y, z, owner, context )
	local mesh = self.pathGraph
	if mesh then
		local nodeId = mesh:getNodeAtPoint( x, y )
		print( x,y, nodeId )
		return nodeId
	else
		return false
	end
end

function PathGraphNavMesh2D:buildNavigatePath( request, nodePath )
	local x0, y0 = request:getStartLoc()
	local x1, y1 = request:getTargetLoc()
	local naviPath = self.pathGraph:findNavigationPath(
		x0, y0,
		x1, y1,
		nodePath
		)	
	return naviPath
end