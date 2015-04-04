module 'mock'
--------------------------------------------------------------------
CLASS: CameraPass ()
	:MODEL{}

function CameraPass:__init()
	self.camera = false
	self.renderLayers = {}
	self.renderTarget  = false
	self.renderTargets = {}
	self.passes = {}
	self.currentRenderTarget = false
	self.defaultRenderTarget = false
	self.outputRenderTarget  = false
end

function CameraPass:init( camera )
	self.camera = camera
	self.outputRenderTarget = camera:getRenderTarget()

	if camera.hasImageEffect then
		self.defaultRenderTarget = self:buildRenderTarget( nil, self.outputRenderTarget )
	else
		self.defaultRenderTarget = self.outputRenderTarget
	end

	self:onInit()
end

function CameraPass:build()
	self.passes = {}
	self:onBuild()
	self:buildImageEffects()
	return self.passes
end

function CameraPass:onInit()
end

function CameraPass:onBuild()
end

function CameraPass:getCamera()
	return self.camera
end

function CameraPass:getDefaultRenderTarget()
	return self.defaultRenderTarget
end

function CameraPass:getCurrentRenderTarget()
	return self.currentRenderTarget
end

function CameraPass:getOutputRenderTarget()
	return self.outputRenderTarget
end

function CameraPass:pushRenderLayer( layer, renderTarget, option )
	if not layer then 
		_error( 'no render layer given!' )
		return
	end
	if renderTarget or option then
		self:pushRenderTarget( renderTarget, option )
	end

	table.insert( self.passes, {
			tag   = 'layer',
			layer = layer
		}
	)
	return layer
end

function CameraPass:pushRenderTarget( renderTarget, option )
	if type( renderTarget ) == 'string' then
		local renderTargetName = renderTarget
		renderTarget = self:getRenderTarget( renderTargetName )
		if not renderTarget then
			_error( 'render target not found:', renderTargetName )
		end
	end

	local renderTarget = renderTarget or self:getDefaultRenderTarget()
	self.currentRenderTarget = renderTarget
	assert( isInstance( renderTarget, RenderTarget ) )
	table.insert( self.passes, { 
		tag          = 'render-target',
		renderTarget = renderTarget,
		option       = option 
		}
	)
end

function CameraPass:findPreviousRenderTarget()
	for i = #self.passes, 1, -1 do
		local pass = self.passes[ i ]
		if pass.tag == 'render-target' then
			return pass.renderTarget
		end
	end
	return nil
end

function CameraPass:pushOverridedShader( shader )
	local moaiShader = nil
	if type( shader ) == 'string' then --path
		shader = mock.loadAsset( shader )
	end
	if shader then
		if shader:getClassName() == 'MOAIShader' then
			moaiShader = shader
		else
			moaiShader = shader:getMoaiShader()
		end
	end
	self:pushCallback( function()
		MOAIGfxDevice.setOverridedShader( moaiShader )
	end)
end


----
--Render Targets
function CameraPass:requestRenderTarget( name, option )
	name = name or 'default'
	local renderTarget = self.renderTargets[ name ]
	if renderTarget then return renderTarget end
	renderTarget = self:buildRenderTarget( option )
	renderTarget.__name = name
	self.renderTargets[ name ] = renderTarget
	return renderTarget
end

function CameraPass:getRenderTarget( name )
	return self.renderTargets[ name ]
end

function CameraPass:getRenderTargetTexture( name )
	local target = self.renderTargets[ name ]
	return target and target:getFrameBuffer()
end

function CameraPass:clearRenderTargets()
	for name, renderTarget in pairs( self.renderTargets ) do
		renderTarget:release()
	end
	self.renderTargets = {}
end

function CameraPass:buildRenderTarget( option, srcRenderTarget )
	local renderTarget = TextureRenderTarget()
	renderTarget:initFrameBuffer( option )
	srcRenderTarget = srcRenderTarget or self:getDefaultRenderTarget()
	srcRenderTarget:addSubViewport( renderTarget )
	return renderTarget
end


function CameraPass:buildDebugDrawLayer()
	local camera   = self.camera
	if not camera.showDebugLines then return nil end
	local layer    = MOAILayer.new()
	layer.priority = 100000

	layer:setViewport  ( camera:getMoaiViewport() )
	layer:setCamera    ( camera._camera )

	layer._mock_camera = camera

	layer:showDebugLines( true )
	
	local renderTable = {}

	local world = self.camera.scene:getBox2DWorld()
	world:setDebugDrawEnabled( true )
	table.insert( renderTable, world )

	layer:setOverlayTable( renderTable )
	-- if world then layer:setBox2DWorld( world ) end

	return layer
end


function CameraPass:applyCameraToMoaiLayer( layer, option )	
	local camera   = self.camera
	layer:setViewport ( self.currentRenderTarget:getMoaiViewport() )
	layer:setCamera   ( camera._camera )
	return layer
end

function CameraPass:buildSceneLayerRenderLayer( sceneLayer, option )	
	local camera   = self.camera
	if not camera:isLayerIncluded( sceneLayer.name ) then return false end
	local includeLayer = option and option.include
	local excludeLayer = option and option.exclude
	
	if includeLayer and not table.index( includeLayer, sceneLayer.name ) then return false end
	if excludeLayer and table.index( excludeLayer, sceneLayer.name ) then return false end

	local source   = sceneLayer.source
	local layer    = MOAILayer.new()
	
	layer.name     = sceneLayer.name
	layer.priority = -1
	layer.source   = source

	layer:showDebugLines( false )
	layer:setPartition ( sceneLayer:getPartition() )
	
	if option and option.viewport then
		layer:setViewport  ( option.viewport )
	else
		layer:setViewport  ( self:getCurrentRenderTarget():getMoaiViewport() )
	end

	if option and option.transform then
		layer:setCamera  ( option.transform )
	else
		layer:setCamera  ( camera._camera )
	end

	if camera.parallaxEnabled and source.parallax then
		layer:setParallax( unpack(source.parallax) )
	end
	
	if sceneLayer.sortMode then
		layer:setSortMode( sceneLayer.sortMode )
	end

	inheritVisible( layer, sceneLayer )
	layer._mock_camera = camera

	if camera.FLAG_EDITOR_OBJECT then		
		local src = sceneLayer.source
		local visible = src.editorVisible and src.editorSolo~='hidden'
		if not visible then layer:setVisible( false ) end
	end

	return layer
end

function CameraPass:buildSimpleOrthoRenderLayer()
	local camera   = self.camera
	local w, h = 1, 1
	
	local viewport = Viewport()
	viewport:setMode( 'relative' )
	viewport:setFixedScale( w, h )
	
	local renderTarget = self:getDefaultRenderTarget()
	viewport:setParent( self:getDefaultRenderTarget() )

	local layer = MOAILayer.new()
	layer:setViewport( viewport:getMoaiViewport() )

	local quadCamera = MOAICamera.new()
	quadCamera:setOrtho( true )
	quadCamera:setNearPlane( -100000 )
	quadCamera:setFarPlane( 100000 )

	layer:setCamera( quadCamera )
	layer.width  = w
	layer.height = h
	return layer, w, h 
end

function CameraPass:buildSimpleQuadProp( w, h, texture, shader )
	local quad = MOAIGfxQuad2D.new()
	quad:setRect( -w/2, -h/2, w/2, h/2 )
	quad:setUVRect( 0,0,1,1 )
	local quadProp = MOAIProp.new()
	quadProp:setDeck( quad )

	if texture then quad:setTexture( texture ) end
	if shader  then quad:setShader( shader )   end

	return quadProp, quad
end

function CameraPass:buildSingleQuadRenderLayer( texture, shader )
	local layer, w, h = self:buildSimpleOrthoRenderLayer()
	local prop, quad = self:buildSimpleQuadProp( w, h, texture, shader )
	layer:insertProp( prop )
	layer.prop = prop
	return layer, prop, quad
end

function CameraPass:buildCallbackRenderLayer( func )
	local camera   = self.camera

	local layer = MOAILayer.new()

	local viewport = MOAIViewport.new()
	viewport:setSize( camera:getViewportWndRect() )
	layer:setViewport( viewport )

	local dummyProp = MOAIProp.new()
	local dummyDeck = MOAIScriptDeck.new()
	dummyProp:setDeck( dummyDeck )
	dummyDeck:setDrawCallback( func )
	dummyDeck:setRect( -10000, -10000, 10000, 10000 )
	layer:insertProp( dummyProp )
	return layer
end

function CameraPass:pushGfxPass( passId )
	self:pushRenderLayer( self:buildCallbackRenderLayer( function()
		MOAIGfxDevice.setPass( passId )
	end) )
end

function CameraPass:pushCallback( func )
	self:pushRenderLayer( self:buildCallbackRenderLayer( func ) )
end


function CameraPass:pushSceneRenderPass( option )
	local camera = self.camera
	local scene  = camera.scene

	for id, sceneLayer in ipairs( scene.layers ) do
		local name  = sceneLayer.name
		local p = self:buildSceneLayerRenderLayer( sceneLayer, option )
		if p then
			self:pushRenderLayer( p )
		end
	end
end


function CameraPass:buildImageEffects()
	if not self.camera.hasImageEffect then return end
	
	local defaultRenderTarget = self:getDefaultRenderTarget()
	local outputRenderTarget = self.outputRenderTarget
	assert( defaultRenderTarget ~= outputRenderTarget )

	local imageEffects = self.camera.imageEffects
	local count = #imageEffects

	local backbuffer  = defaultRenderTarget
	local frontbuffer = outputRenderTarget
	if count > 1 then --need backbuffer
		frontbuffer = self:requestRenderTarget( 'image-effect-backbuffer', self.outputRenderTarget )
	end

	for i, imageEffect in ipairs( imageEffects ) do
		if i == count then
			--last one output to output buffer
			frontbuffer = outputRenderTarget
		end
		self.defaultRenderTarget = frontbuffer
		self:pushRenderTarget( frontbuffer )
		imageEffect:buildCameraPass( self, backbuffer:getFrameBuffer() )
		backbuffer, frontbuffer = frontbuffer, backbuffer
	end

	self.defaultRenderTarget = defaultRenderTarget
end


--------------------------------------------------------------------
CLASS: SceneCameraPass ( CameraPass )
 	:MODEL{} 

function SceneCameraPass:__init( clear, clearColor )
	self.clearBuffer = clear ~= false
	self.clearColor  = clearColor or false
end

function SceneCameraPass:onBuild()
	local camera = self:getCamera()
	local fb0 = self:getDefaultRenderTarget()
	if not self.clearBuffer then
		self:pushRenderTarget( fb0, { clearColor = false } )
	else
		self:pushRenderTarget( fb0, { clearColor = self.clearColor } )
	end
	self:pushSceneRenderPass()
	local debugLayer = self:buildDebugDrawLayer()
	if debugLayer then
		self:pushRenderLayer( debugLayer )
	end
end

--------------------------------------------------------------------
CLASS: CallbackCameraPass ( CameraPass )
	:MODEL{}

function CallbackCameraPass:onBuild()
	local function callback( ... )
		return self:onDraw( ... )
	end
	self:pushPass( self:buildCallbackRenderLayer( callback ) )
end

function CallbackCameraPass:onDraw( ... )
end
