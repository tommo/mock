module 'mock'

EnumPhysicsBodyType = _ENUM_V{
	'dynamic',
	'static',
	'kinematic'
}

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

