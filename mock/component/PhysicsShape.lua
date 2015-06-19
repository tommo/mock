module 'mock'

--------------------------------------------------------------------
CLASS: PhysicsShape ( mock.Component )
	:MODEL{
		Field 'loc'       :type('vec2') :getset('Loc') :label('Loc'); 
		Field 'material'  :asset( 'physics_material' ) :getset( 'Material' );
	}

function PhysicsShape:__init()
	self.materialPath = false
	self.material = false
	self.loc = { 0,0 }
	self.shape = false
	self.parentBody = false
end

function PhysicsShape:clone(original)
	original = original or self

	-- make copy from derived class
	local copy = self.__class()
	copy:setMaterial(original:getMaterial())
	copy.loc = { original.loc[1], original.loc[2] }
	return copy
end

function PhysicsShape:setLoc( x,y )
	self.loc = { x or 0, y or 0 }
	self:updateShape()
end

function PhysicsShape:getLoc()
	return unpack( self.loc )
end

function PhysicsShape:getBox2DWorld()
	return self:getScene():getBox2DWorld()
end

function PhysicsShape:findBody()
	local body = self._entity:getComponent( PhysicsBody )
	return body
end

function PhysicsShape:isSensor()
	if self.material then
		return self.material.isSensor
	end
	return false
end

function PhysicsShape:getMaterial()
	return self.materialPath
end

function PhysicsShape:setMaterial( path )
	self.materialPath = path
	if not path then
		self.material = false
		return
	end
	self.material = loadAsset( path )
	self:updateMaterial()
end

function PhysicsShape:getMaterialTag()
	return self.material and self.material.tag
end

function PhysicsShape:updateMaterial()
	local material, shape = self.material, self.shape
	if not shape then return end
	if not material then 
		material = getDefaultPhysicsMaterial() 
		self.material = material
	end
	shape:setDensity      ( material.density )
	shape:setFriction     ( material.friction )
	shape:setRestitution  ( material.restitution )
	shape:setSensor       ( material.isSensor )
	-- print('categoryBits: ', bit.tohex(material.categoryBits), ' maskBits: ', bit.tohex(material.maskBits))
	shape:setFilter       ( material.categoryBits or 1, material.maskBits or 0xffffffff, material.group or 0 )
	self.parentBody:updateMass()
end

function PhysicsShape:setFilter(categoryBits, maskBits, group)
	group = group or 0

	local material, shape = self.material, self.shape
	if not shape then return end
	if not material then 
		material = getDefaultPhysicsMaterial() 
		self.material = material
	end

	shape:setFilter(categoryBits, maskBits, group)
	-- update material as well
	material.categoryBits = categoryBits
	material.maskBits = maskBits
	material.group = group
end

function PhysicsShape:onAttach( entity )
	if not self.parentBody then
		for com in pairs( entity:getComponents() ) do
			if isInstance( com, PhysicsBody ) then
				if com.body then
					self:updateParentBody( com )
				end
				break
			end
		end		
	end
end

function PhysicsShape:onDetach( entity )
	if not self.shape then return end
	if self.parentBody and self.parentBody.body then
		self.shape:destroy()
		self.shape.component = nil
		self.shape = false
	end
end

function PhysicsShape:updateParentBody( body )
	self.parentBody = body
	self:updateShape()
end

function PhysicsShape:updateShape()
	if self.shape then 
		self.shape:destroy()
		self.shape.component = nil
		self.shape = false
	end
	if not self.parentBody then return end
	local body = self.parentBody.body
	self.shape = self:createShape( body )
	-- back reference to the component
	self.shape.component = self
	--apply material
	--TODO
	self:updateMaterial()
end

function PhysicsShape:createShape( body )
	local shape = body:addCircle( 0,0, 100 )
	return shape
end

function PhysicsShape:setCollisionHandler(handler, phaseMask, categoryMask)

	self.handlerData = {
		func = handler,
		phaseMask = phaseMask,
		categoryMask = categoryMask
	}

	self.shape:setCollisionHandler(handler, phaseMask, categoryMask)
end

function PhysicsShape:getCollisionHandler()
	if self.handlerData then
		return self.handlerData.func, self.handlerData.phaseMask, self.handlerData.categoryMask
	end
end

_wrapMethods( PhysicsShape, 'shape', {
	'getFilter',
	'setDensity',
	'setFriction',
	'setRestitution',
	'setSensor',
	})


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

	print('---------')
	local step = (self.endAngle - self.startAngle) / self.tessellation

	local d = self.endAngle

	for i=0,self.tessellation do
		local angle = self.endAngle - i * step
		print(angle)

		local x = ox + math.cos(mock.d2arc(angle)) * self.radius
		local y = oy + math.sin(mock.d2arc(angle)) * self.radius
		table.insert(verts, x)
		table.insert(verts, y)

	end
	print('---------')

	return body:addPolygon(verts)
end
