module 'mock'

--------------------------------------------------------------------
CLASS: PhysicsShapePie ( PhysicsShape )
	:MODEL
{
	Field 'dir'   :range( -180, 180 )   :getset( 'Dir' );
	Field 'range' :range( 1, 360 )      :getset( 'Range');
	Field 'tessellation'		:int()			:range(3, 6) :getset( 'Tessellation');
	Field 'radius'					:number()		:getset( 'Radius');
}

mock.registerComponent( 'PhysicsShapePie', PhysicsShapePie )

function PhysicsShapePie:__init()
	self.dir = 0 
	self.range = 90
	self.tessellation = 6
	self.radius = 50
	self.verts = false
end

function PhysicsShapePie:setDir( dir )
	self.dir = dir
	self:updateShape()
end

function PhysicsShapePie:getDir()
	return self.dir
end

function PhysicsShapePie:setRange( r )
	self.range = r
	self:updateShape()
end

function PhysicsShapePie:getRange()
	return self.range
end

function PhysicsShapePie:setTessellation(tessellation)
	self.tessellation = math.clamp(tessellation, 2, 6)
	self:updateShape()
end

function PhysicsShapePie:getTessellation()
	return self.tessellation
end

function PhysicsShapePie:setRadius(radius)
	if radius < 10 then
		radius = 10
	end
	self.radius = radius
	self:updateShape()
end

function PhysicsShapePie:getRadius()
	return self.radius
end

function PhysicsShapePie:calcVerts()
	local verts = {}

	local ox, oy = self:getLoc()
	table.insert(verts, ox)
	table.insert(verts, oy)

	local range = self.range

	local step = range / self.tessellation

	local d = self.endAngle

	local dir0 = self.dir - range/2

	for i = 0, self.tessellation do

		local angle = dir0 + i*step

		local x = ox + math.cosd( angle ) * self.radius
		local y = oy + math.sind( angle ) * self.radius

		table.insert(verts, x)
		table.insert(verts, y)

	end
	-- print('---------')
	return verts
end

function PhysicsShapePie:createShape(body)
	local verts = self:calcVerts()
	return body:addPolygon(verts)
end
