module 'mock'

EnumPhysicsBodyType = _ENUM_V{
	'dynamic',
	'static',
	'kinematic'
}


---------------------------------------------------------------------
--Material
--------------------------------------------------------------------
CLASS: PhysicsMaterial ()
	:MODEL{
		Field 'density';
		Field 'restitution';
		Field 'friction';
		Field 'isSensor' :boolean();
		'----';
	}

function PhysicsMaterial:__init()
	self.density = 1
	self.restitution = 0.5
	self.friction = 0.5
	self.isSensor = false
end

--------------------------------------------------------------------
local function loadPhysicsMaterial( node )
	local data   = mock.loadAssetDataTable( node:getObjectFile('config') )
	local config = mock.deserialize( nil, data )	
	return config
end

mock.registerAssetLoader( 'physics_material', loadPhysicsMaterial )


--------------------------------------------------------------------
CLASS: PhysicsBody ( mock.Component )
	:MODEL{
		Field 'bodyType'     :enum( EnumPhysicsBodyType ) :getset( 'Type' );
		Field 'isBullet'     :boolean();
		Field 'allowSleep'   :boolean();
		Field 'gravityScale' :set( 'setGravityScale' );
		Field 'fixRotation'  :boolean();
		'----';
		Field 'Calc Mass'    :action('calcMass');
	}

mock.registerComponent( 'PhysicsBody', PhysicsBody )

function PhysicsBody:__init()
	self.isBullet     = false
	self.allowSleep   = true
	self.gravityScale = 1
	self.fixRotation  = false
	self.bodyType     = 'dynamic'
	self.body = false
	self.joints = {}
	self.mass = 1
end

function PhysicsBody:onAttach( entity )
	self.body = self:createBody()

	local prop = entity:getProp()
	self.body:setAttrLink ( MOAIProp.ATTR_X_LOC, prop, MOAIProp.ATTR_WORLD_X_LOC ) 
	self.body:setAttrLink ( MOAIProp.ATTR_Y_LOC, prop, MOAIProp.ATTR_WORLD_Y_LOC ) 
	self.body:setAttrLink ( MOAIProp.ATTR_Z_ROT, prop, MOAIProp.ATTR_Z_ROT ) 
	for com in pairs( entity:getComponents() ) do
		if isInstance( com, PhysicsShape ) then
			com:updateParentBody( self )
		end
	end

	for j in pairs( self.joints ) do
		j:updateJoint()
	end

	for com in pairs( entity:getComponents() ) do
		if isInstance( com, PhysicsJoint ) then
			com:updateParentBody( self )
		end
	end

	self.body:forceUpdate()
end

function PhysicsBody:onStart( entity )
	local body = self.body
	if self.bodyType == 'dynamic' then
		body:clearAttrLink( MOAIProp.ATTR_X_LOC )
		body:clearAttrLink( MOAIProp.ATTR_Y_LOC )
		body:clearAttrLink( MOAIProp.ATTR_Z_ROT )

		local prop = entity:getProp()
		prop:clearAttrLink( MOAIProp.INHERIT_TRANSFORM )
		prop:setAttrLink ( MOAIProp.ATTR_X_LOC, body, MOAIProp.ATTR_WORLD_X_LOC ) 
		prop:setAttrLink ( MOAIProp.ATTR_Y_LOC, body, MOAIProp.ATTR_WORLD_Y_LOC ) 
		prop:setAttrLink ( MOAIProp.ATTR_Z_ROT, body, MOAIProp.ATTR_Z_ROT ) 
		-- inheritTransform( prop, body )
	end
	body:setFixedRotation( self.fixRotation )
	-- body:setSleepingAllowed( self.allowSleep )
	body:setBullet( self.isBullet )
	body:setMassData(self.mass)
	body:setGravityScale( self.gravityScale )
end

function PhysicsBody:onDetach( entity )
	if self.body then
		local body = self.body
		body:clearAttrLink( MOAIProp.ATTR_X_LOC )
		body:clearAttrLink( MOAIProp.ATTR_Y_LOC )
		body:clearAttrLink( MOAIProp.ATTR_Z_ROT )
		local prop = entity:getProp()
		prop:clearAttrLink ( MOAIProp.ATTR_X_LOC )
		prop:clearAttrLink ( MOAIProp.ATTR_Y_LOC )
		prop:clearAttrLink ( MOAIProp.ATTR_Z_ROT )
		self.body = false
		body:destroy()
	end	
end

local bodyTypeNames = {
	dynamic   = MOAIBox2DBody.DYNAMIC;
	static    = MOAIBox2DBody.STATIC;
	kinematic = MOAIBox2DBody.KINEMATIC;
}
function PhysicsBody:createBody()
	return game.b2world:addBody( bodyTypeNames[ self.bodyType ] or MOAIBox2DBody.DYNAMIC )
end

function PhysicsBody:getType()
	return self.bodyType
end

function PhysicsBody:setType( t ) 
	self.bodyType = t
	if self.body then
		self.body:setType( bodyTypeNames[ t ] or MOAIBox2DBody.DYNAMIC )
	end
end

function PhysicsBody:setGravityScale( s )
	self.gravityScale = s
	if self.body then
		self.body:setGravityScale( s )
	end
end

function PhysicsBody:_removeJoint( j )
	self.joints[ j ] = nil
end

function PhysicsBody:_addJoint( j )
	self.joints[ j ] = true
end

function PhysicsBody:setMass(mass)
	self.mass = mass
end

function PhysicsBody:getMass()
	return self.mass
end

function PhysicsBody:calcMass()
	local deck = self._entity:com(mock.DeckComponent)
	if deck then
		local x1,y1,z1, x2,y2,z2 = deck.prop:getBounds()

		local w = x2 - x1
		local h = y2 - y1
		local radius = (w+h)/4
		local linearWeight = radius * 0.1
		self:setMass(linearWeight*linearWeight)
	end
end


_wrapMethods( PhysicsBody, 'body', {
	'applyAngularImpulse',
	'applyForce',
	'applyLinearImpulse',
	'applyTorque',
	'getAngle',
	'getAngularVelocity',
	'getInertia',
	'getGravityScale',
	'getLinearVelocity',
	'getLocalCenter',
	'getMass',
	'getPosition',
	'getWorldCenter',
	'isActive',
	'isAwake',
	'isBullet',
	'isFixedRotation',
	'resetMassData',
	'setActive',
	'setAngularDamping',
	'setAngularVelocity',
	'setAwake',
	'setBullet',
	'setFixedRotation',
	'setLinearDamping',
	'setLinearVelocity',
	'setMassData',
	'setTransform',
	}
)


--------------------------------------------------------------------
CLASS: PhysicsShape ( mock.Component )
	:MODEL{
		Field 'loc'       :type('vec2') :getset('Loc') :label('Loc'); 
		Field 'material'  :asset( 'physics_material' );
	}

function PhysicsShape:__init()
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
	--apply material
	--TODO
	local shape = self.shape
	shape:setFriction( 0.5 )
	shape:setRestitution( 0.3 )
	shape:setDensity( rand( 0.5, 1 ) )

	self.parentBody.body:resetMassData()

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
--------------------------------------------------------------------
CLASS: PhysicsJoint ( mock.Component )
	:MODEL{
		Field 'target' :type( PhysicsBody ) :set('setTarget');
		'----';
		Field 'offsetA' :type( 'vec2' ) :tuple_getset( 'offsetA');
		Field 'offsetB' :type( 'vec2' ) :tuple_getset( 'offsetB');
		'----';
	}

function PhysicsJoint:__init()
	self.joint = false
	self.parentBody = false
end

function PhysicsJoint:setTarget( target )	
	if self.target == target then return end
	if self.target then
		self.target:_removeJoint( self )
	end
	self.target = target	
	if self.target then
		self.target:_addJoint( self )
	end
	self:updateJoint()
end

function PhysicsJoint:findBody()
	local body = self._entity:getComponent( PhysicsBody )
	return body
end

function PhysicsJoint:onAttach( entity )
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

function PhysicsJoint:onStart( entity )
	self:updateJoint()
end

function PhysicsJoint:onDetach( entity )
	if not self.joint then return end
	if self.parentBody and self.parentBody.body and
		 self.target and self.target.body 
	then
		self.joint:destroy()
	end
	self.joint = false
end

function PhysicsJoint:updateParentBody( body )
	self.parentBody = body
	self:updateJoint()
end

function PhysicsJoint:updateJoint()
	if self.joint then 
		self.joint:destroy()
		self.joint = false
	end
	if not self.parentBody then return end
	if not self.target then return end

	local bodyA = self.parentBody.body
	local bodyB = self.target.body
	if not ( bodyA and bodyB  ) then return end
	self.joint = self:createJoint( bodyA, bodyB )

end

function PhysicsJoint:createJoint( body )
	--OVERRIDE

end

--------------------------------------------------------------------

CLASS: PhysicsJointDistance ( PhysicsJoint )
	:MODEL{
		Field 'distacne'
}

mock.registerComponent( 'PhysicsJointDistance', PhysicsJointDistance )

function PhysicsJointDistance:__init()
	self.distacne = 100
end

function PhysicsJointDistance:createJoint( bodyA, bodyB )
	bodyA:forceUpdate()
	bodyB:forceUpdate()
	local x0,y0 = bodyA:getWorldLoc()
	local x1,y1 = bodyB:getWorldLoc()
	local joint = game.b2world:addDistanceJoint(
			bodyA,
			bodyB,
			x0,y0,
			x1,y1
		)
	return joint
end

---------------------------------------------------------------------

