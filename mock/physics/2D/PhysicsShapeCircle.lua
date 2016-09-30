module 'mock'

--------------------------------------------------------------------
CLASS: PhysicsShapeCircle ( PhysicsShape )
	:MODEL{
		Field 'radius' :set('setRadius');
		'----';
		Field 'Match size' :action('matchSize');
	}

mock.registerComponent( 'PhysicsShapeCircle', PhysicsShapeCircle )

function PhysicsShapeCircle:__init()
	self.radius = 100
end

function PhysicsShapeCircle:clone(original)
	local copy = PhysicsShapeCircle.__super.clone(self, original)

	original = original or self
	copy.radius = original.radius

	return copy
end

function PhysicsShapeCircle:createShape( body )	
	local x, y = self:getLoc()
	local shape = body:addCircle( x, y, self.radius )
	return shape
end

function PhysicsShapeCircle:setRadius( radius )
	self.radius = radius
	self:updateShape()
end

function PhysicsShapeCircle:getRadius()
	return self.radius
end

function PhysicsShapeCircle:matchSize()
	local deck = self._entity:com(mock.DeckComponent)
	if deck then
		local x1,y1,z1, x2,y2,z2 = deck.prop:getBounds()

		local radius = ((x2-x1) + (y2-y1)) / 4
		self.radius = radius
		self:setLoc((x1 + x2)/2, (y1+y2)/2)
		
		self:updateShape()
	end
end

function PhysicsShapeCircle:getLocalVerts( steps )
	steps = steps or 8
	local r = self.radius
	local x0, y0 = self:getLoc()
	local interval = math.pi*2/steps
	local cos ,sin = math.cos, math.sin
	local result = {}
	for i = 1, steps do
		local a = interval * ( i - 1 )
		local x = x0 + cos( a )*r
		local y = y0 + sin( a )*r
		table.append( result, x, y )
	end
	return result
end

