module 'mock'

--------------------------------------------------------------------
CLASS: Box2DShapeGroupProxy ()

function Box2DShapeGroupProxy:__init()
	self.shapes = {}
	self.categoryBits = 0
	self.maskBits     = 0
	self.group        = 0
	self.friction     = 1
	self.restitution  = 1
	self.sensor = false
end

function Box2DShapeGroupProxy:getFilter()
	return self.categoryBits, self.maskBits, self.group
end

function Box2DShapeGroupProxy:setFilter( categoryBits, maskBits, group )
	self.categoryBits, self.maskBits, self.group = categoryBits, maskBits, group
	for i, shape in ipairs( self.shapes ) do
		shape:setFilter( categoryBits, maskBits, group )
	end
end

function Box2DShapeGroupProxy:getDensity()
	return self.density
end

function Box2DShapeGroupProxy:setDensity( density )
	self.density = density
	for i, shape in ipairs( self.shapes ) do
		shape:setDensity( density )
	end
end

function Box2DShapeGroupProxy:getFriction()
	return self.friction
end

function Box2DShapeGroupProxy:setFriction( friction )
	self.friction = friction
	for i, shape in ipairs( self.shapes ) do
		shape:setFriction( friction )
	end
end

function Box2DShapeGroupProxy:getRestitution()
	return self.restitution
end

function Box2DShapeGroupProxy:setRestitution( restitution )
	self.restitution = restitution
	for i, shape in ipairs( self.shapes ) do
		shape:setRestitution( restitution )
	end
end

function Box2DShapeGroupProxy:isSensor()
	return self.sensor
end

function Box2DShapeGroupProxy:setSensor( sensor )
	self.sensor = sensor
	for i, shape in ipairs( self.shapes ) do
		shape:setSensor( sensor )
	end
end

function Box2DShapeGroupProxy:destroy()
	for i, shape in ipairs( self.shapes ) do
		shape:destroy()
	end
end

function Box2DShapeGroupProxy:setCollisionHandler( func, phaseMask, categoryMask )
	self.collisionFunc = func
	self.collisionPhaseMask = phaseMask
	self.collisionCategoryMask = categoryMask
	for i, shape in ipairs( self.shapes ) do
		shape:setCollisionHandler(
			func,
			phaseMask,
			categoryMask
		)
	end
end

function Box2DShapeGroupProxy:getCollisionHandler()
	return self.collisionFunc, self.collisionPhaseMask, self.collisionCategoryMask 
end

function Box2DShapeGroupProxy:addShape( shape )
	table.insert( self.shapes, shape )
end


--------------------------------------------------------------------
CLASS: PhysicsShapePolygon ( PhysicsShape )
	:MODEL{
		Field 'verts'  :array() :no_edit();
		Field 'resetShape' :action();
}

mock.registerComponent( 'PhysicsShapePolygon', PhysicsShapePolygon )

function PhysicsShapePolygon:resetShape()
	self:__init()
end

function PhysicsShapePolygon:__init()
	self.verts     = {
		 20, -20,
		-20, -20,
		 0 ,  20
	}
	self.aabb = {0,0,0,0}
end

function PhysicsShapePolygon:setVerts( verts )
	self.verts = verts
	self:updateShape()
end

function PhysicsShapePolygon:getVerts()
	return self.verts
end

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


local function triangulate( verts )
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

	path:clean( 5 )
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
				if ccount > 16 then
					local partA = {}
					local partB = {}
					for i = 1, 16 do
						partA[ i ] = triVerts[ i ]
					end
					for i = 15, ccount do
						partB[ i - 15 + 1 ] = triVerts[ i ]
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

function PhysicsShapePolygon:createShape( body )
	--triangulate
	self.aabb  = { calcAABB( self.verts ) }
	local triangulated = triangulate( self.verts )
	local proxy = Box2DShapeGroupProxy()
	for i, tri in ipairs( triangulated ) do
		local poly = body:addPolygon( tri )
		poly.component = self
		proxy:addShape( poly )
	end
	return proxy	
end

function PhysicsShapePolygon:getLocalVerts( steps )
	return self.verts
end

