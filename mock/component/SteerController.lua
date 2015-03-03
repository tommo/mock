module 'mock'

CLASS: PhysicsBodySteerController ()
	:MODEL{}

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

function PhysicsBodySteerController:pushBehaviour( behaviour )
	self._controller:pushBehaviour( behaviour )
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

