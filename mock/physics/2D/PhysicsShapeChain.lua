module 'mock'

--------------------------------------------------------------------
CLASS: PhysicsShapeChain ( PhysicsShape )
	:MODEL{
		Field 'loc' :no_edit();
		Field 'verts' :array( 'number' ) :getset( 'Verts' ) :no_edit();
		Field 'looped' :boolean() :isset( 'Looped' );
	}

mock.registerComponent( 'PhysicsShapeChain', PhysicsShapeChain )
--------------------------------------------------------------------

function PhysicsShapeChain:__init()
	self.looped = false
	self.boundRect = {0,0,0,0}
	self:setVerts{
		0,0,
		100,0
	}
end

function PhysicsShapeChain:setLooped( looped )
	self.looped = looped
	self:updateVerts()
end

function PhysicsShapeChain:isLooped()
	return self.looped
end

function PhysicsShapeChain:onAttach( ent )
	PhysicsShapeChain.__super.onAttach( self, ent )
	self:updateVerts()
end

function PhysicsShapeChain:getVerts()
	return self.verts
end

function PhysicsShapeChain:setVerts( verts )
	self.verts = verts 
	self:updateVerts()	
end

function PhysicsShapeChain:updateVerts()
	if not self._entity then return end
	local verts = self.verts
	local x0,y0,x1,y1
	for i = 1, #verts, 2 do
		local x, y = verts[ i ], verts[ i + 1 ]
		x0 = x0 and ( x < x0 and x or x0 ) or x
		y0 = y0 and ( y < y0 and y or y0 ) or y
		x1 = x1 and ( x > x1 and x or x1 ) or x
		y1 = y1 and ( y > y1 and y or y1 ) or y
	end
	self.boundRect = { x0 or 0, y0 or 0, x1 or 0, y1 or 0 }
	local count = #verts
	if count < 4 then return end
	self:updateShape()
end

function PhysicsShapeChain:createShape( body )
	local verts = self.verts
	local path = MOCKPolyPath.new()
	local count = #verts/2
	path:reserve( count )
	for i = 1, count do
		local k = ( i - 1 ) * 2
		local x, y = verts[ k + 1 ], verts[ k + 2 ]
		path:setVert( i, x, y )
	end
	path:clean( 2 )

	local chain = body:addChain( path:getVerts(), self:isLooped() )
	return chain
end
