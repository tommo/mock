module 'mock'

--------------------------------------------------------------------
CLASS: SceneLocationManager ()
	:MODEL{}

function SceneLocationManager:__init()
	self.locationRegistry = {}
end

function SceneLocationManager:getLocations()
end

--------------------------------------------------------------------
CLASS: SceneLocation ()
	:MODEL{}

function SceneLocation:onAttach()
end

function SceneLocation:onDetach()
end
