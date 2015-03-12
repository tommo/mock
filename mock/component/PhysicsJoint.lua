module 'mock'

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
