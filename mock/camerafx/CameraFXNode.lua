module 'mock'

--------------------------------------------------------------------
local CameraFXNodeRegistry = {}
function registerCameraFXNode( id, clas )
	if CameraFXNodeRegistry[ id ] then
		_warn( 'duplicated camera FX:', id )
	end
	CameraFXNodeRegistry[ id ] = clas
end


--------------------------------------------------------------------
CLASS: CameraFXNode ()
	:MODEL{
		Field 'active' :boolean();
	}

function CameraFXNode:__init()
	self.active = true
end

function CameraFXNode:setActive( active )
	self.active = active
end

