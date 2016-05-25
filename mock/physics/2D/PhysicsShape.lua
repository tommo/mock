module 'mock'

--------------------------------------------------------------------
CLASS: PhysicsShape ( mock.Component )
	:MODEL{
		Field 'edit'     :action('editShape') :meta{ icon='edit', style='tool'};
		Field 'active'   :boolean();
		Field 'tag'       :string();
		Field 'loc'       :type('vec2') :getset('Loc') :label('Loc'); 
		Field 'material'  :asset_pre( 'physics_material' ) :getset( 'Material' );
	}
	:META{
		category = 'physics'
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

function PhysicsShape:editShape()
	mock_edit.startAdhocSceneTool( 'physics_shape_editor', { target = self } )
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
	if path then
		self.material = loadAsset( path )
	else
		self.material = false
	end
	self:updateMaterial()
end

function PhysicsShape:getMaterialTag()
	return self.material and self.material.tag
end

function PhysicsShape:getDefaultMaterial()
	return self.parentBody and self.parentBody:getDefaultMaterial() or getDefaultPhysicsMaterial()
end

function PhysicsShape:updateMaterial()
	local material, shape = self.material, self.shape
	if not shape then return end
	if not material then 
		material = self:getDefaultMaterial()
		self.material = material
	end
	
	shape:setDensity      ( material.density )
	shape:setFriction     ( material.friction )
	shape:setRestitution  ( material.restitution )
	shape:setSensor       ( material.isSensor )
	-- print('categoryBits: ', bit.tohex(material.categoryBits), ' maskBits: ', bit.tohex(material.maskBits))
	shape:setFilter       ( 
		material.categoryBits or 1,
		material.maskBits or 0xffffffff,
		material.group or 0
	)
	self.parentBody:updateMass()
end

function PhysicsShape:setFilter(categoryBits, maskBits, group)

	local material, shape = self.material, self.shape
	if not shape then return end
	if not material then 
		material = getDefaultPhysicsMaterial() 
		self.material = material
	end

	shape:setFilter(
		categoryBits or material.categoryBits or 1,
		maskBits or material.maskBits or 0xffff,
		group or material.group or 0 )
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

function PhysicsShape:getParentBody()
	return self.parentBody
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
	self:updateCollisionHandler()
end

function PhysicsShape:createShape( body )
	local shape = body:addCircle( 0,0, 100 )
	return shape
end

function PhysicsShape:setCollisionHandler(handler, phaseMask, categoryMask)
	self.handlerData = {
		func         = handler,
		phaseMask    = phaseMask,
		categoryMask = categoryMask
	}
	return self:updateCollisionHandler()
end

function PhysicsShape:updateCollisionHandler()
	if not self.shape then return end
	if not self.handlerData then return end
	self.shape:setCollisionHandler(
		self.handlerData.func,
		self.handlerData.phaseMask,
		self.handlerData.categoryMask
	)
end

function PhysicsShape:getCollisionHandler()
	if self.handlerData then
		return self.handlerData.func, self.handlerData.phaseMask, self.handlerData.categoryMask
	end
end

function PhysicsShape:getLocalVerts( steps )
	return {}
end

function PhysicsShape:getGlobalVerts( steps )
	local localVerts = self:getLocalVerts( steps )
	local globalVerts = {}
	local ent = self:getEntity()
	local count = #localVerts/2
	ent:forceUpdate()
	for i = 0, count - 1 do
		local x = localVerts[ i * 2 + 1 ]
		local y = localVerts[ i * 2 + 2 ]
		local x, y = ent:modelToWorld( x, y )
		table.append( globalVerts, x, y )
	end
	return globalVerts
end

_wrapMethods( PhysicsShape, 'shape', {
	'getFilter',
	'setDensity',
	'setFriction',
	'setRestitution',
	'setSensor',
	})
