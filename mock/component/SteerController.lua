module 'mock'

CLASS: PhysicsBodySteerController ()
	:MODEL{}

mock.registerComponent( 'PhysicsBodySteerController', PhysicsBodySteerController )

function PhysicsBodySteerController:__init()
	self._controller = MOAISteerBox2DController.new()
end

function PhysicsBodySteerController:onStart()
	local body = self._entity:getComponent( PhysicsBody )
	if not body then 
		_warn( 'no physicbody found for steer controller')
		return
	end
	self._controller:setBody( body.body )
	self._controller:start()
end

function PhysicsBodySteerController:pushBehaviour( behaviour, weight )
	self._controller:pushBehaviour( behaviour, weight )
	return behaviour
end

function PhysicsBodySteerController:removeBehaviour( behaviour )
	self._controller:removeBehaviour( behaviour )
end

function PhysicsBodySteerController:clearBehaviours()
	self._controller:clearBehaviours()
end

function PhysicsBodySteerController:pause()
	self._controller:pause()
end

function PhysicsBodySteerController:resume()
	self._controller:resume()
end

function PhysicsBodySteerController:getLimiter()
	return self._controller:getLimiter()
end

function PhysicsBodySteerController:getMoaiController()
	return self._controller
end


function PhysicsBodySteerController:getRadius()
	return self._controller:getRadius()
end

function PhysicsBodySteerController:setRadius( r )
	return self._controller:setRadius( r )
end

function PhysicsBodySteerController:setMaxLinearSpeed( v )
	return self._controller:getLimiter():setMaxLinearSpeed( v )
end

function PhysicsBodySteerController:setMaxLinearAcceleration( v )
	return self._controller:getLimiter():setMaxLinearAcceleration( v )
end

function PhysicsBodySteerController:setMaxAngularSpeed( v )
	return self._controller:getLimiter():setMaxAngularSpeed( v )
end

function PhysicsBodySteerController:setMaxAngularAcceleration( v )
	return self._controller:getLimiter():setMaxAngularAcceleration( v )
end


function PhysicsBodySteerController:getLinearVelocity()
	return self._controller:getLinearVelocity()
end

function PhysicsBodySteerController:getLinearSpeed()
	return self._controller:getLinearSpeed()
end

function PhysicsBodySteerController:getLinearAcceleration()
	return self._controller:getLinearAcceleration()
end


function PhysicsBodySteerController:getAngularVelocity()
	return self._controller:getAngularVelocity()
end

function PhysicsBodySteerController:getAngularSpeed()
	return self._controller:getAngularSpeed()
end

function PhysicsBodySteerController:getAngularAcceleration()
	return self._controller:getAngularAcceleration()
end

