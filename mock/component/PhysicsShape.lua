module 'mock'

--------------------------------------------------------------------
CLASS: PhysicsShape ( mock.Component )
	:MODEL{
		Field 'active'   :boolean();
		Field 'tag'       :string();
		Field 'loc'       :type('vec2') :getset('Loc') :label('Loc'); 
		Field 'material'  :asset( 'physics_material' ) :getset( 'Material' );
	}

function PhysicsShape:__init()
	self.active = true 
	self.tag = false
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

function PhysicsShape:getTag()
	return self.tag
end

function PhysicsShape:setTag( tag )
	self.tag = tag
	if self.shape then
		self.shape.tag = self.tag
	end
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

function PhysicsShape:getBody()
	return self.parentBody
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
	-- TODO: remove this
	material.categoryBits = categoryBits
	material.maskBits     = maskBits
	material.group        = group
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
	if not self.active then return end
	local shape = self.shape
	if shape then 
		shape.component = nil
		shape:destroy()
		self.shape = false
	end

	local parentBody = self.parentBody
	if not parentBody then return end
	local body = parentBody.body
	shape = self:createShape( body )
	-- back reference to the component
	shape.component = self
	self.shape = shape
	shape.tag = self.tag
	--apply material
	--TODO
	self:updateMaterial()
end

function PhysicsShape:createShape( body )
	local shape = body:addCircle( 0,0, 100 )
	return shape
end

function PhysicsShape:setCollisionHandler(handler, phaseMask, categoryMask)
	if not self.shape then return end
	self.handlerData = {
		func         = handler,
		phaseMask    = phaseMask,
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
