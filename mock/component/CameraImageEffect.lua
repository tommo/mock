module 'mock'

CLASS: CameraImageEffect ( Component )
	:MODEL{}

function CameraImageEffect:onAttach( entity )
	local camera = entity:getComponent( Camera )
	if camera then
		self.targetCamera = camera
		camera:addImageEffect( self )
	else
		_warn( 'no camera found' )
	end
end

function CameraImageEffect:onDetach( entity )
	if self.targetCamera then
		self.targetCamera:removeImageEffect( self )
		self.targetCamera = false
	end
end

function CameraImageEffect:getCamera()
	return self.targetCamera
end

function CameraImageEffect:buildCameraPass( pass, frameBuffer )
	local layer, prop, quad = pass:buildSingleQuadRenderLayer()
	prop:setTexture( frameBuffer )
	pass:pushRenderLayer( layer )
	return self:onBuild( prop, frameBuffer, layer )
end

function CameraImageEffect:onBuild( prop, texture, layer )
end

--------------------------------------------------------------------
