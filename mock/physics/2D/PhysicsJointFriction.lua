module 'mock'
---------------------------------------------------------------------
CLASS: PhysicsJointFriction ( PhysicsJoint )
	:MODEL{
		Field 'target'  :no_edit();
		Field 'offsetB' :no_edit();
		'----';
		Field 'maxForce';
		Field 'maxTorque';

}

mock.registerComponent( 'PhysicsJointFriction', PhysicsJointFriction )

function PhysicsJointFriction:__init()
	self.distacne  = 100
	self.maxForce  = 0
	self.maxTorque = 0
end

function PhysicsJointFriction:createJoint( bodyA, bodyB )
	bodyA:forceUpdate()
	local x0,y0 = bodyA:getWorldLoc()
	local joint = self:getB2World():addFrictionJoint(
			bodyA,
			bodyB,
			x0,y0,
			self.maxForce,
			self.maxTorque
		)
	return joint
end

function PhysicsJointFriction:getTargetMoaiBody()
	return self:getB2World().ground
end

function PhysicsJointFriction:setMaxForce( f )
	self.maxForce = f
	if self.joint then
		self.joint:setMaxForce( f )
	end
end

function PhysicsJointFriction:setMaxTorque( t )
	self.maxTorque = t
	if self.joint then
		self.joint:setMaxTorque( t )
	end
end

---------------------------------------------------------------------

