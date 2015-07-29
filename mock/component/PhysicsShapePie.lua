module 'mock'

--------------------------------------------------------------------
CLASS: PhysicsShapePie ( PhysicsShape )
	:MODEL
{
	Field 'Start angle'			:int()			:getset('StartAngle');
	Field 'End angle'				:int()			:getset('EndAngle');
	Field 'Tessellation'		:int()			:getset('Tessellation');
	Field 'Radius'					:number()		:getset('Radius');
}

mock.registerComponent( 'PhysicsShapePie', PhysicsShapePie )

function PhysicsShapePie:__init()
	self.startAngle = 330
	self.endAngle = 390
	self.tessellation = 6
	self.radius = 50
end

function PhysicsShapePie:clone(original)
	local copy = PhysicsShapePie.__super.clone(self, original)

	original = original or self
	copy.startAngle = original.startAngle
	copy.endAngle = original.endAngle
	copy.tessellation = original.tessellation
	copy.radius = original.radius

	return copy
end

function PhysicsShapePie:angleWrap()
	while self.endAngle < self.startAngle do
		self.endAngle = self.endAngle + 360
	end
end

function PhysicsShapePie:setStartAngle(angle)
	if self.endAngle - angle > 180 then
		return
	end

	self.startAngle = angle

	self:updateShape()
end

function PhysicsShapePie:getStartAngle()
	return self.startAngle
end

function PhysicsShapePie:setEndAngle(angle)
	if angle - self.startAngle > 180 then
		return
	end

	self.endAngle = angle

	self:updateShape()
end

function PhysicsShapePie:getEndAngle()
	return self.endAngle
end

function PhysicsShapePie:setTessellation(tessellation)

	tessellation = mock.clamp(tessellation, 2, 6)
	self.tessellation = tessellation

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

function PhysicsShapePie:createShape(body)

	self:angleWrap()

	local verts = {}

	-- origin(x, y)
	local ox, oy = self:getLoc()
	table.insert(verts, ox)
	table.insert(verts, oy)

	-- print('---------')
	local step = (self.endAngle - self.startAngle) / self.tessellation

	local d = self.endAngle

	for i=0,self.tessellation do
		local angle = self.endAngle - i * step
		-- print(angle)

		local x = ox + math.cos(mock.d2arc(angle)) * self.radius
		local y = oy + math.sin(mock.d2arc(angle)) * self.radius
		table.insert(verts, x)
		table.insert(verts, y)

	end
	-- print('---------')

	return body:addPolygon(verts)
end
