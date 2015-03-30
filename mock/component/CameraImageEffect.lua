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
	self.camera:removeImageEffect( self )
	self.targetCamera = false
end

function CameraImageEffect:getCamera()
	return self.targetCamera
end

function CameraImageEffect:buildCameraPass( pass )
	local texture = pass:getDefaultFramebuffer()
	local layer, prop, quad = pass:buildSingleQuadRenderLayer()
	prop:setTexture( texture )
	pass:pushRenderLayer( layer )
	return self:onBuild( prop, texture, layer )
end

function CameraImageEffect:onBuild( prop, texture, layer )
end

--------------------------------------------------------------------
