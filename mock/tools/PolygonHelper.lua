module 'mock'

local sqrt = math.sqrt
local cos	= math.cos
local acos = math.acos
local pi	= math.pi
local halfPi = pi*0.5
local doublePi = pi*2
local abs	= math.abs
local atan2 = math.atan2


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


local function offsetPolygon(verts, offset, looped)
	offset = offset or 0
	if offset == 0 then return verts end
	----
	local offsetedPolygon = {}

	local vertCount = #verts

	local x0, y0 
	local x1, y1 		= verts[1], verts[2]
	local x, y
	if looped then
		x, y 	= verts[vertCount - 1], verts[vertCount]
	else
		local dx = x1 - verts[3]
		local dy = y1 - verts[4]
		x, y = x1 + dx, y1 + dy
	end

	--loop through all points
	for i=1, vertCount-1, 2 do
		--reuse previously localized points
		x0, y0 	= x, y
		x, y 	= x1, y1

		if i < vertCount - 1 then
			x1, y1 = verts[i + 2], verts[i + 3]
		else
			if looped then
				x1, y1 = verts[1], verts[2]
			else
				local dx = x - x0
				local dy = y - y0
				x1, y1 = x + dx, y + dy
			end
		end

		local vx0, vy0 	= x - x0, y - y0
		local vx1, vy1 	= x1 - x, y1 - y

		local length0 = sqrt( vx0^2 + vy0^2 )
		local length1 = sqrt( vx1^2 + vy1^2 )

		local nx0, ny0 	= vx0 / length0, vy0 / length0
		local nx1, ny1 	= vx1 / length1, vy1 / length1
		
		local vectorAngle = atan2(ny1, nx1) - atan2(ny0, nx0)

		if vectorAngle == 0 then
			offsetedPolygon[i]   = x + ny0*offset 
			offsetedPolygon[i+1] = y - nx0*offset
		else
			if vectorAngle < 0 then 
				vectorAngle = vectorAngle - halfPi*0.5 + doublePi
			else
				vectorAngle = vectorAngle + halfPi*0.5
			end

			local vectorAngle2 = halfPi - acos(nx0*nx1 + ny0*ny1)

			local vectorScale = 1 / cos(vectorAngle2)

			if vectorAngle <= pi then
				vectorScale = vectorScale*(-1)
			end

			offsetedPolygon[i]   = x - (nx0 - nx1)*vectorScale*offset 
			offsetedPolygon[i+1] = y - (ny0 - ny1)*vectorScale*offset
		end
	end

	return offsetedPolygon
end


PolygonHelper = {
	reversePath     = reversePath;
	triangulate     = triangulate;	
	convexPartition = convexPartition;
	offsetPolygon   = offsetPolygon;
}
