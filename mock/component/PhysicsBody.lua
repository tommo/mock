module 'mock'

--------------------------------------------------------------------
CLASS: PhysicsBody ( mock.Component )
	:MODEL{
		Field 'bodyDef'      :asset( 'physics_body_def' ) :getset( 'BodyDef' );
		'----';
		Field 'mass'         :getset( 'Mass' );
		Field 'updateMassFromShape' :boolean();
		Field 'Calc Mass'    :action('calcMass');
	}

mock.registerComponent( 'PhysicsBody', PhysicsBody )

function PhysicsBody:__init()
	self.bodyDef = false
	self.bodyDefPath = false
	---	
	self.updateMassFromShape = false
	self.bodyReady = false
	self.mass    = 1
	---	
	self.body   = false
	self.joints = {}
	self.mass    = 1
end


function PhysicsBody:onAttach( entity )
	local body = self:createBody()
	self.body = body
	self.body.component = self

	local prop = entity:getProp()
	body:setAttrLink ( MOAIProp.ATTR_X_LOC, prop, MOAIProp.ATTR_WORLD_X_LOC ) 
	body:setAttrLink ( MOAIProp.ATTR_Y_LOC, prop, MOAIProp.ATTR_WORLD_Y_LOC ) 
	body:setAttrLink ( MOAIProp.ATTR_Z_ROT, prop, MOAIProp.ATTR_Z_ROT ) 

	self:updateBodyDef()

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

	self.bodyReady = true
	self:updateMass()

	self.body:forceUpdate()
end

function PhysicsBody:getMoaiBody()
	return self.body
end

function PhysicsBody:onStart( entity )
	local body = self.body
	if self:getType() ~= 'static' then
		body:clearAttrLink( MOAIProp.ATTR_X_LOC )
		body:clearAttrLink( MOAIProp.ATTR_Y_LOC )
		body:clearAttrLink( MOAIProp.ATTR_Z_ROT )

		local prop = entity:getProp()
		prop:setAttrLink ( MOAIProp.ATTR_X_LOC, body, MOAIProp.ATTR_WORLD_X_LOC ) 
		prop:setAttrLink ( MOAIProp.ATTR_Y_LOC, body, MOAIProp.ATTR_WORLD_Y_LOC ) 
		prop:setAttrLink ( MOAIProp.ATTR_Z_ROT, body, MOAIProp.ATTR_Z_ROT ) 
	end

	self:updateMass()
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
	--TODO: use b2BodyDef here
	return game.b2world:addBody( bodyTypeNames[ self.bodyType ] or MOAIBox2DBody.DYNAMIC )
end

function PhysicsBody:setBodyDef( path )
	self.bodyDefPath = path
	if path then
		self.bodyDef = mock.loadAsset( path )
	end
	self:updateBodyDef()
end

function PhysicsBody:getBodyDef()
	return self.bodyDefPath
end

function PhysicsBody:updateBodyDef()
	self:applyBodyDef( self.bodyDef )
end

function PhysicsBody:applyBodyDef( def )
	if not self.body then return end
	--TODO: use b2BodyDef here
	local def  = def or getDefaultPhysicsBodyDef()
	local body = self.body
	body:setType( bodyTypeNames[ def.bodyType ] or MOAIBox2DBody.DYNAMIC )
	body:setFixedRotation   ( def.fixedRotation )
	body:setSleepingAllowed ( def.allowSleep )
	body:setBullet          ( def.isBullet )
	body:setGravityScale    ( def.gravityScale )
	body:setGravityScale    ( def.linearDamping )
	body:setGravityScale    ( def.angularDamping )
end

----
function PhysicsBody:setType( bodyType )
	if not self.body then return end
	self.body:setType( bodyTypeNames[ bodyType ] or MOAIBox2DBody.DYNAMIC )
end

function PhysicsBody:getType()
	if self.bodyDef then
		return self.bodyDef.bodyType
	else
		return false
	end
end

function PhysicsBody:setGravityScale( s )
	if self.body then
		self.body:setGravityScale( s )
	end
end

----
function PhysicsBody:setMass(mass)
	self.mass = mass
	self:updateMass()
end

function PhysicsBody:getMass()
	return self.mass
end

function PhysicsBody:updateMass()
	if not self.bodyReady then return end
	if self.updateMassFromShape then
	 	self.body:resetMassData()
	else
		self.body:setMassData( self.mass )
	end
end

function PhysicsBody:calcMass()
	local deck = self._entity:com(mock.DeckComponent)
	if deck then
		local x1,y1,z1, x2,y2,z2 = deck.prop:getBounds()

		local w = x2 - x1
		local h = y2 - y1
		local radius = (w+h)/4
		local linearWeight = radius * 0.1
		self:setMass( linearWeight*linearWeight )
	end
end


function PhysicsBody:_removeJoint( j )
	self.joints[ j ] = nil
end

function PhysicsBody:_addJoint( j )
	self.joints[ j ] = true
end


_wrapMethods( PhysicsBody, 'body', {
	'applyAngularImpulse',
	'applyForce',
	'applyLinearImpulse',
	'applyTorque',
	'getAngle',
	'getAngularVelocity',
	'getContactList',
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

-- Helper
-- Dynamically add post physics update functionality for one class which
-- typically has physics components attached on and requires positional
-- changes during the collision handler.
function installPhysicsPostUpdate(klass)

	klass['physicsPostThread'] = function(self)
		while true do
			self:onPhysicsPostUpdate()
			coroutine.yield()
		end
	end

	-- This could be merged into physicsPostThread() but leave it here for
	-- possible future updates
	klass['onPhysicsPostUpdate'] = function(self)
		if self.callingQueue then 
			for i,func in ipairs(self.callingQueue) do
				func()
			end
			-- all done, clear queue
			self.callingQueue = {}
		end
	end

	-- Called by user
	klass['callOnNextUpdate'] = function(self, func)
		if self.callingQueue then
			table.insert(self.callingQueue, func)
		else
			self.callingQueue = {func}
		end

	end

	local originalOnStart = klass['onStart']
	klass['onStart'] = function(self)
		originalOnStart(self)
		-- add busy update for onPhysicsPostUpdate
		self:addCoroutine( 'physicsPostThread' )
	end
end
