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

function PhysicsShape:setLoc( x,y )
	self.loc = { x or 0, y or 0 }
	self:updateShape()
end

function PhysicsShape:getLoc()
	return unpack( self.loc )
end

function PhysicsShape:findBody()
	local body = self._entity:getComponent( PhysicsBody )
	return body
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
	if not material then material = getDefaultPhysicsMaterial() end
	shape:setDensity      ( material.density )
	shape:setFriction     ( material.friction )
	shape:setRestitution  ( material.restitution )
	shape:setSensor       ( material.isSensor )
	shape:setFilter       ( material.categoryBits or 0, material.maskBits or 0xffff, material.group or 0 )
	self.parentBody:updateMass()
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
		self.shape = false
	end
	if not self.parentBody then return end
	local body = self.parentBody.body
	self.shape = self:createShape( body )
	-- back refernce to the component
	self.shape.component = self
	--apply material
	--TODO
	self:updateMaterial()
end

function PhysicsShape:createShape( body )
	local shape = body:addCircle( 0,0, 100 )
	return shape
end

_wrapMethods( PhysicsShape, 'shape', {
	'getFilter',
	'setCollisionHandler',
	'setDensity',
	'setFilter',
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

function PhysicsShapeCircle:createShape( body )	
	local x, y = self:getLoc()
	local shape = body:addCircle( x, y, self.radius )
	return shape
end

function PhysicsShapeCircle:setRadius( radius )
	self.radius = radius
	self:updateShape()
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