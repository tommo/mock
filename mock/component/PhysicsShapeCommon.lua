module 'mock'

--------------------------------------------------------------------
CLASS: PhysicsShapeBox ( PhysicsShape )
	:MODEL{
		Field 'w' :set('setWidth');
		Field 'h' :set('setHeight');
		Field 'rotation' :set('setRotation');
		'----';
		Field 'Match size' :action('matchSize');
	}

mock.registerComponent( 'PhysicsShapeBox', PhysicsShapeBox )

function PhysicsShapeBox:__init()
	self.w = 100
	self.h = 100
	self.rotation = 0
end

function PhysicsShapeBox:clone(original)
	local copy = PhysicsShapeBox.__super.clone(self, original)

	original = original or self
	copy.w = original.w
	copy.h = original.h
	copy.rotation = original.rotation

	return copy
end

function PhysicsShapeBox:createShape( body )	
	local w = self.w
	local h = self.h
	local x, y = self:getLoc()
	local shape = body:addRect( 
			x-w/2, y-h/2, x+w/2, y+h/2, self.rotation/180*3.14
		)
	return shape
end

function PhysicsShapeBox:setWidth( w )
	self.w = w
	self:updateShape()
end

function PhysicsShapeBox:setHeight( h )
	self.h = h
	self:updateShape()
end

function PhysicsShapeBox:getSize()
	return self.w, self.h
end

function PhysicsShapeBox:setSize( w, h )
	self.w = w
	self.h = h
	self:updateShape()
end

function PhysicsShapeBox:setRotation( rotation )
	self.rotation = rotation
	self:updateShape()
end

function PhysicsShapeBox:matchSize()
	local deck = self._entity:com(mock.DeckComponent)
	if deck then
		local x1,y1,z1, x2,y2,z2 = deck.prop:getBounds()

		self.w = x2 - x1
		self.h = y2 - y1

		self:setLoc((x1 + x2)/2, (y1+y2)/2)

		self:updateShape()
	end
end

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

--------------------------------------------------------------------
CLASS: PhysicsShapePolygon ( PhysicsShape )
	:MODEL{}

-- mock.registerComponent( 'PhysicsShapePolygon', PhysicsShapePolygon )

--------------------------------------------------------------------
CLASS: PhysicsShapeEdges ( PhysicsShape )
	:MODEL{}

-- mock.registerComponent( 'PhysicsShapeEdges', PhysicsShapeEdges )

--------------------------------------------------------------------
CLASS: PhysicsShapeChain ( PhysicsShape )
	:MODEL{}

-- mock.registerComponent( 'PhysicsShapeChain', PhysicsShapeChain )

