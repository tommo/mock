module 'mock'

local function reversePath( path )
	local verts = path:getVerts()
	local count = #verts/2
	local path1 = MOCKPolyPath.new()
	path1:reserve( count )
	for i = 1, count do
		local k = ( i - 1 ) * 2
		local x, y = verts[ k + 1 ], verts[ k + 2 ]
		local idx = ( count - i ) + 1
		path1:setVert( idx, x, y )
	end
	return path1
end

local function convexPartition( verts, maxPolygonSize )
	if not ( MOCKPolyPath and MOCKPolyPartition ) then
		return { verts }
	end

	local path = MOCKPolyPath.new()
	local count = #verts/2
	path:reserve( count )
	for i = 1, count do
		local k = ( i - 1 ) * 2
		local x, y = verts[ k + 1 ], verts[ k + 2 ]
		local idx = i
		path:setVert( idx, x, y )
	end

	path:clean( 2 )
	local partition = MOCKPolyPartition.new()
	local triangulated = partition:doConvexPartition{ path }
	if not triangulated then
		path = path:reversed()
		triangulated = partition:doConvexPartition{ path }
	end

	if not triangulated then
		return { verts }
	end

	local result = {}
	for i, tri in ipairs( triangulated ) do
		local count = tri:getVertCount()
		if count > 2 then
			local triVerts = tri:getVerts()
			while true do
				local ccount = #triVerts
				if maxPolygonSize and ccount > maxPolygonSize then
					local partA = {}
					local partB = {}
					for i = 1, maxPolygonSize do
						partA[ i ] = triVerts[ i ]
					end
					for i = maxPolygonSize - 1, ccount do
						partB[ i - ( maxPolygonSize - 1 ) + 1 ] = triVerts[ i ]
					end
					table.insert( partB, triVerts[1] )
					table.insert( partB, triVerts[2] )
					triVerts = partB
					table.insert( result, partA )
				else
					table.insert( result, triVerts )
					break
				end
			end
		end
	end
	return result
end

local function convexPartition( verts, option )
	if not ( MOCKPolyPath and MOCKPolyPartition ) then
		return { verts }
	end
	option = option or {}

	local maxVertCount = option['maxPolygonSize'] and option['maxPolygonSize'] * 2

	local path = MOCKPolyPath.new()
	local count = #verts/2
	path:reserve( count )
	for i = 1, count do
		local k = ( i - 1 ) * 2
		local x, y = verts[ k + 1 ], verts[ k + 2 ]
		local idx = i
		path:setVert( idx, x, y )
	end

	if option['nearThreshold'] then
		path:clean( option['nearThreshold'] )
	end

	local partition = MOCKPolyPartition.new()
	local triangulated = partition:doConvexPartition{ path }
	if not triangulated then
		path = path:reversed()
		triangulated = partition:doConvexPartition{ path }
	end

	if not triangulated then
		return { verts }
	end

	local result = {}
	for i, tri in ipairs( triangulated ) do
		local count = tri:getVertCount()
		if count > 2 then
			local triVerts = tri:getVerts()
			while true do
				local ccount = #triVerts
				if maxVertCount and ccount > maxVertCount then
					local partA = {}
					local partB = {}
					for i = 1, maxVertCount do
						partA[ i ] = triVerts[ i ]
					end
					for i = maxVertCount - 1, ccount do
						partB[ i - ( maxVertCount - 1 ) + 1 ] = triVerts[ i ]
					end
					table.insert( partB, triVerts[1] )
					table.insert( partB, triVerts[2] )
					triVerts = partB
					table.insert( result, partA )
				else
					table.insert( result, triVerts )
					break
				end
			end
		end
	end
	return result
end


local function triangulate( verts, option )
	if not ( MOCKPolyPath and MOCKPolyPartition ) then
		return { verts }
	end
	option = option or {}

	local path = MOCKPolyPath.new()
	local count = #verts/2
	path:reserve( count )
	for i = 1, count do
		local k = ( i - 1 ) * 2
		local x, y = verts[ k + 1 ], verts[ k + 2 ]
		local idx = i
		path:setVert( idx, x, y )
	end

	if option['nearThreshold'] then
		path:clean( option['nearThreshold'] )
	end

	local partition = MOCKPolyPartition.new()
	local triangulated = partition:doTriagulation{ path }
	if not triangulated then
		path = path:reversed()
		triangulated = partition:doTriagulation{ path }
	end

	if not triangulated then
		return { verts }
	end

	local result = {}
	for i, tri in ipairs( triangulated ) do
		table.insert( result, tri:getVerts() )
	end
	return result
end

PolygonHelper = {
	reversePath     = reversePath;
	triangulate     = triangulate;	
	convexPartition = convexPartition;
}
