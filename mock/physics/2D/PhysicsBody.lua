module 'mock'

EnumBodyTransformSyncPolicy = _ENUM_V {
	'use_entity_transform',
	'use_body_transform',
	'smart_update',
}

--------------------------------------------------------------------
CLASS: PhysicsBody ( mock.Component )
	:MODEL{
		Field 'bodyDef'      :asset_pre( 'physics_body_def' ) :getset( 'BodyDef' );
		'----';
		Field 'mass'         :getset( 'Mass' );
		Field 'transformSyncPolicy'   :enum( EnumBodyTransformSyncPolicy );
		Field 'updateMassFromShape' :boolean();
		-- Field 'Calc Mass'    :action('calcMass');
		-- Field 'Test Mass'    :action('testMass');
	}

mock.registerComponent( 'PhysicsBody', PhysicsBody )

function PhysicsBody:__init()
	self.bodyDef = false
	self.bodyDefPath = false
	---	
	self.updateMassFromShape = false
	self.bodyReady = false

	self.body   = false
	self.joints = {}
	self.mass    = 0
	self.bodyType = 'dynamic'
	self.useEntityTransform = false
	self.transformSyncPolicy = 'use_body_transform'
end


function PhysicsBody:onAttach( entity )
	local body = self:createBody( entity )
	self.body = body
	self.body.component = self

	local prop = entity:getProp( 'physics' )
	body:setAttrLink ( MOAIProp.ATTR_X_LOC, prop, MOAIProp.ATTR_WORLD_X_LOC ) 
	body:setAttrLink ( MOAIProp.ATTR_Y_LOC, prop, MOAIProp.ATTR_WORLD_Y_LOC ) 
	body:setAttrLink ( MOAIProp.ATTR_Z_LOC, prop, MOAIProp.ATTR_WORLD_Z_LOC )
	body:setAttrLink ( MOAIProp.ATTR_Z_ROT, prop, MOAIProp.ATTR_WORLD_Z_ROT ) 

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
	
	-- update position sync based on body type and settings
	self:updateTransformSyncPolicy( entity )
	self:updateMass()
end

function PhysicsBody:setTransformSyncPolicy( policy )
	self.transformSyncPolicy = policy
	if self.body then
		return self:updateTransformSyncPolicy()
	end
end

function PhysicsBody:updateTransformSyncPolicy( entity )
	local prop = entity:getProp( 'physics' )
	local body = self.body
	local policy = self.transformSyncPolicy
	if policy == 'use_body_transform' then
		-- break body<-prop position link 
		body:clearAttrLink( MOAIProp.ATTR_X_LOC )
		body:clearAttrLink( MOAIProp.ATTR_Y_LOC )
		body:clearAttrLink( MOAIProp.ATTR_Z_LOC )
		body:clearAttrLink( MOAIProp.ATTR_Z_ROT )
		prop:setAttrLink ( MOCKProp.SYNC_WORLD_LOC_2D, body, MOAIProp.TRANSFORM_TRAIT )

	elseif policy == 'use_entity_transform'	then
		-- break prop->body position link 
		-- prop:setWorldLoc(body:getPosition())
		prop:clearAttrLink ( MOCKProp.SYNC_WORLD_LOC_2D )
		body:setAttrLink ( MOAIProp.ATTR_X_LOC, prop, MOAIProp.ATTR_WORLD_X_LOC ) 
		body:setAttrLink ( MOAIProp.ATTR_Y_LOC, prop, MOAIProp.ATTR_WORLD_Y_LOC ) 
		body:setAttrLink ( MOAIProp.ATTR_Z_LOC, prop, MOAIProp.ATTR_WORLD_Z_LOC )
		body:setAttrLink ( MOAIProp.ATTR_Z_ROT, prop, MOAIProp.ATTR_WORLD_Z_ROT ) 

	else
		--TODO

	end

end

function PhysicsBody:onDetach( entity )
	if self.body then
		local body = self.body
		body:clearAttrLink( MOAIProp.ATTR_X_LOC )
		body:clearAttrLink( MOAIProp.ATTR_Y_LOC )
		body:clearAttrLink( MOAIProp.ATTR_Z_LOC )
		body:clearAttrLink( MOAIProp.ATTR_Z_ROT )
		local prop = entity:getProp( 'physics' )
		-- prop:clearAttrLink ( MOAIProp.ATTR_X_LOC )
		-- prop:clearAttrLink ( MOAIProp.ATTR_Y_LOC )
		prop:clearAttrLink ( MOAIProp.ATTR_Z_ROT )
		prop:clearAttrLink( MOCKProp.SYNC_WORLD_LOC_2D )
		self.body = false
		body:destroy()
	end	
end

local bodyTypeNames = {
	dynamic   = MOAIBox2DBody.DYNAMIC;
	static    = MOAIBox2DBody.STATIC;
	kinematic = MOAIBox2DBody.KINEMATIC;
}

function PhysicsBody:getBox2DWorld()
	return self._entity.scene:getBox2DWorld()
end

function PhysicsBody:createBody( entity )
	--TODO: use b2BodyDef here
	local world = self:getBox2DWorld()
	local body = world:addBody( bodyTypeNames[ self.bodyType ] or MOAIBox2DBody.DYNAMIC )
	return body
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
	body:setLinearDamping   ( def.linearDamping )
	body:setAngularDamping ( def.angularDamping )
end

----
function PhysicsBody:setType( bodyType )
	if not self.body then return end
	self.body:setType( bodyTypeNames[ bodyType ] or MOAIBox2DBody.DYNAMIC )
	self.bodyType = bodyType

	-- re-setting the mass after changing body type
	self:updateTransformSyncPolicy( self._entity )
	self:updateMass()
end

function PhysicsBody:getType()
	return self.bodyType
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

function PhysicsBody:testMass()
	print( self.mass )
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

function PhysicsBody:getDefaultMaterial()
	if self.bodyDef then
		local materialPath = self.bodyDef.defaultMaterial
		if materialPath then
			return loadAsset( materialPath )
		end
	end
	return false
end

function PhysicsBody:_removeJoint( j )
	self.joints[ j ] = nil
end

function PhysicsBody:_addJoint( j )
	self.joints[ j ] = true
end

function PhysicsBody:setPosition( x, y )
	local body = self.body
	local angle = body:getAngle()
	body:setTransform( x, y, angle )
end

function PhysicsBody:setAngle( dir )
	local body = self.body
	local x, y = body:getPosition()
	body:setTransform( x, y, dir )
end

function PhysicsBody:addPosition( dx, dy )
	local x,y = self:getPosition()
	return self:setPosition( x+dx, y+dy )
end

function PhysicsBody:addAngle( da )
	local a = self:getAngle()
	return self:setAngle( da + a )
end

function PhysicsBody:getTag()
	if self.bodyDef then
		return self.bodyDef.tag
	end
	return nil
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

	-- klass['physicsPostThread'] = function(self)
	-- 	while true do
	-- 		self:onPostPhysicsUpdate()
	-- 		coroutine.yield()
	-- 	end
	-- end

	-- -- This could be merged into physicsPostThread() but leave it here for
	-- -- possible future updates
	-- klass['onPostPhysicsUpdate'] = function(self)
	-- 	if self.callingQueue then 
	-- 		for i,func in ipairs(self.callingQueue) do
	-- 			func()
	-- 		end
	-- 		-- all done, clear queue
	-- 		self.callingQueue = {}
	-- 	end
	-- end

	-- Called by user
	klass['addPostPhysicsCallback'] = function(self, func)
		-- if self.callingQueue then
		-- 	table.insert(self.callingQueue, func)
		-- else
		-- 	self.callingQueue = {func}
		-- end
		local ent = self:getEntity()
		local action = ent:callAsAction( func )
		ent:setActionPriority( action, 8 )

	end

	-- local originalOnStart = klass['onStart']
	-- klass['onStart'] = function(self, ...)
	-- 	originalOnStart(self, ...)
	-- 	-- add busy update for onPhysicsPostUpdate
	-- 	local coro = self:addCoroutine( 'physicsPostThread' )
	-- 	self:setActionPriority(coro, 8)
	-- end

	updateAllSubClasses( klass )	
end
