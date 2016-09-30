module 'mock'

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
	local world = self:getB2World()
	bodyA:forceUpdate()
	bodyB:forceUpdate()
	local x0,y0 = bodyA:getWorldLoc()
	local x1,y1 = bodyB:getWorldLoc()
	local joint = world:addDistanceJoint(
			bodyA,
			bodyB,
			x0,y0,
			x1,y1
		)
	return joint
end

