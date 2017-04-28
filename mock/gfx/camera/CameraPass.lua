module 'mock'

--------------------------------------------------------------------
CLASS: CameraPass ()
	:MODEL{}

function CameraPass:__init()
	self.camera = false
	self.renderTarget  = false
	self.renderTargets = {}
	self.passes = {}
	self.currentRenderTarget = false
	self.defaultRenderTarget = false
	self.outputRenderTarget  = false
	self.debugLayers = {}
	self.groups = {}
	self.groupStates = {}
	self.finalizers = {}
end

function CameraPass:setGroupActive( id, active )
	self.groupStates[ id ] = active ~= false
	local group = self.groups[ id ]
	if not group then return end
	for layer in pairs( group ) do
		layer:setVisible( active )
	end
end

function CameraPass:isGroupActive( id )
	return self.groupStates[ id ] ~= false
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

function CameraPass:release()
	self:onRelease()
	self.passes = false
	self.debugLayers = false
	self.groupStates = false
	self.groups = false
	self.renderTargets = false
	for i, finalizer in ipairs( self.finalizers ) do
		finalizer()
	end
	self.finalizers = false
end

function CameraPass:onRelease()
	for key, renderTarget in pairs( self.renderTargets ) do
		renderTarget:setParent( nil )
		renderTarget:clear()
	end
	self.renderTargets = {}
	self.camera = false
end

function CameraPass:build()
	self.passes = {}
	self.groups = {}
	self:setCurrentGroup( 'default' )
	self:onBuild()
	self:buildImageEffects()
	self:postBuild()
	return self.passes
end

function CameraPass:onInit()
end

function CameraPass:onBuild()
end

function CameraPass:postBuild()
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

function CameraPass:setCurrentGroup( id )
	local group = self.groups[ id ]
	if not group then
		group = {}
		self.groups[ id ] = group
	end
	self.currentGroup = group
	self.currentGroupId = id
end

function CameraPass:pushPassData( data )
	data[ 'camera' ] = self:getCamera()
	data[ 'group'  ] = self.currentGroupId or 'default'
	table.insert( self.passes, data )
end

function CameraPass:pushRenderLayer( layer, layerType, debugLayer )
	if not layer then 
		_error( 'no render layer given!' )
		return
	end
	
	if not debugLayer then
		self.currentGroup[ layer ] = true
	end
	
	self:pushPassData {
		tag   = 'layer',
		layer = layer,
		type  = layerType or 'render'
	}
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
	--
	self:pushPassData { 
		tag          = 'render-target',
		renderTarget = renderTarget,
		option       = option 
		}
end

function CameraPass:pushDefaultRenderTarget( option )
	return self:pushRenderTarget( self:getDefaultRenderTarget(), option )
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

function CameraPass:pushRenderTargetCopy( targetId, sourceId, scaleX, scaleY )
	self:pushRenderTarget( targetId )
	local copyLayer = self:buildSimpleOrthoRenderLayer()
	local copyProp = self:buildSimpleQuadProp( 1, 1, self:getRenderTargetTexture( sourceId ) )
	local scaleX, scaleY = scaleX or 1, scaleY or 1
	local ox, oy = ( 1 - scaleX ) / 2, ( 1 - scaleY ) / 2
	copyProp:setScl( scaleX, scaleY )
	copyProp:setLoc( -ox, oy )
	copyLayer:insertProp( copyProp )
	self:pushFinalizer( function()
		copyLayer:removeProp( copyProp )
	end )
	self:pushRenderLayer( copyLayer )
	return copyLayer, copyProp
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
		renderTarget:clear()
	end
	self.renderTargets = {}
end

function CameraPass:buildRenderTarget( option, srcRenderTarget )
	local renderTarget = TextureRenderTarget()
	local option = option and table.simplecopy( option ) or {}
	local rootRenderTarget = srcRenderTarget and srcRenderTarget:getRootRenderTarget()
	if rootRenderTarget and rootRenderTarget:isInstance( TextureRenderTarget ) then
		if option.colorFormat      == nil then option.colorFormat      = rootRenderTarget.colorFormat end
		if option.useDepthBuffer   == nil then option.useDepthBuffer   = rootRenderTarget.useDepthBuffer end
		if option.useStencilBuffer == nil then option.useStencilBuffer = rootRenderTarget.useStencilBuffer end
		if option.depthFormat      == nil then option.depthFormat      = rootRenderTarget.depthFormat end
		if option.stencilFormat    == nil then option.stencilFormat    = rootRenderTarget.stencilFormat end
	end
	renderTarget:initFrameBuffer( option )
	srcRenderTarget = srcRenderTarget or self:getDefaultRenderTarget()
	srcRenderTarget:addSubViewport( renderTarget )
	return renderTarget
end

function CameraPass:buildDebugDrawLayer()
	local camera   = self.camera

	local layer    = MOAILayer.new()
	layer.priority = 100000

	layer:setViewport  ( camera:getMoaiViewport() )
	layer:setCamera    ( camera._camera )

	layer._mock_camera = camera

	layer:showDebugLines( true )
	
	local overlayTable = {}
	local underlayTable = {}
	layer:setOverlayTable( overlayTable )
	layer:setUnderlayTable( underlayTable )
	layer:setPartition( self.camera.scene:getDebugPropPartition() )
	--physics
	local world = self.camera.scene:getBox2DWorld()
	table.insert( underlayTable, world )
	--debugdraw queue
	local debugDrawQueue = self.camera.scene:getDebugDrawQueue()
	table.insert( overlayTable, debugDrawQueue:getMoaiProp() )
	table.insert( self.debugLayers, layer )
	layer:setVisible( false )
	return layer
end

function CameraPass:pushFinalizer( f ) 
	table.insert( self.finalizers, f )
end

function CameraPass:setShowDebugLayers( visible )
	for i, layer in ipairs( self.debugLayers ) do
		layer:setVisible( visible )
	end
end

function CameraPass:applyCameraToMoaiLayer( layer, option )	
	local camera   = self.camera
	layer:setViewport ( self.currentRenderTarget:getMoaiViewport() )
	layer:setCamera   ( camera._camera )
	return layer
end

function CameraPass:buildSceneLayerRenderLayer( sceneLayer, option )	
	local camera   = self.camera
	local allowEditorLayer = option and option.allowEditorLayer
	if not camera:isLayerIncluded( sceneLayer.name, allowEditorLayer ) then return false end
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
	self:pushFinalizer( function()
		layer:removeProp( prop )
	end )
	return layer, prop, quad
end

function CameraPass:buildCallbackRenderLayer( func )
	local camera   = self.camera
	local dummyProp = MOAIProp.new()
	local dummyDeck = MOAIScriptDeck.new()
	dummyProp:setDeck( dummyDeck )
	dummyDeck:setDrawCallback( func )
	return dummyProp
end

function CameraPass:pushGfxPass( passId )
	return self:pushCallback( 
		function() return MOAIGfxDevice.setPass( passId ) end, 
		'gfx-pass'
	)
end


function CameraPass:pushCallback( func, layerType )
	return self:pushRenderLayer(
			self:buildCallbackRenderLayer( func ),
			layerType or 'call'
		)
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

function CameraPass:pushEditorLayerPass()
	local camera = self.camera
	local scene  = camera.scene

	for id, sceneLayer in ipairs( scene.layers ) do
		local name  = sceneLayer.name
		if name == '_GII_EDITOR_LAYER' then
			local p = self:buildSceneLayerRenderLayer( sceneLayer, { allowEditorLayer = true } )
			if p then
				self:pushRenderLayer( p )
			end
			break
		end
	end
end

function CameraPass:buildImageEffects()
	if not self.camera.hasImageEffect then return end
	
	local defaultRenderTarget = self:getDefaultRenderTarget()
	local outputRenderTarget = self.outputRenderTarget
	assert( defaultRenderTarget ~= outputRenderTarget )

	local imageEffects = self.camera.imageEffects
	local effectPassCount = 0
	for i, effect in ipairs( self.camera.imageEffects ) do
		effectPassCount = effectPassCount + effect:getPassCount()
	end

	local backbuffer  = defaultRenderTarget
	local frontbuffer = outputRenderTarget
	if effectPassCount > 1 then --need backbuffer
		frontbuffer = self:buildRenderTarget( nil, outputRenderTarget )
	end
	local totalEffectPassId = 0
	for i, imageEffect in ipairs( imageEffects ) do
		local passCount = imageEffect:getPassCount()
		
		for pass = 1, passCount do
			totalEffectPassId = totalEffectPassId + 1
			if totalEffectPassId == effectPassCount then
				--last one output to output buffer
				frontbuffer = outputRenderTarget
			end
			self.defaultRenderTarget = frontbuffer
			self:pushRenderTarget( frontbuffer )
			local result = imageEffect:buildCameraPass( self, backbuffer:getFrameBuffer(), pass )			
			--swap double buffer
			backbuffer, frontbuffer = frontbuffer, backbuffer
		end

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

	if camera:isEditorCamera() then
		self:pushEditorLayerPass()
	end

end

--------------------------------------------------------------------
CLASS: CallbackCameraPass ( CameraPass )
	:MODEL{}

function CallbackCameraPass:onBuild()
	local function callback( ... )
		return self:onDraw( ... )
	end
	self:pushRenderLayer( self:buildCallbackRenderLayer( callback ) )
end

function CallbackCameraPass:onDraw( ... )
end


--------------------------------------------------------------------
--build render commands
local defaultOptions = { 
	clearColor   = {0,0,0,0}, 
	clearDepth   = true, 
	clearStencil = true
}

local emptyOptions = { 
	clearColor   = false, 
	clearDepth   = false, 
	clearStencil = false
}

--------------------------------------------------------------------
function buildCameraRenderCommandTable( camera )
	--build passes
	local passQueue = {}
	for _, camPass in ipairs( camera.passes ) do
		for i, passEntry in ipairs( camPass:build() ) do
			table.insert( passQueue, passEntry )
		end
	end

	local currentBuffer  = false
	local currentOption  = false
	local currentBatch   = false

	local bufferInfoTable = {}
	
	local defaultRenderTarget = game:getMainRenderTarget()
	local defaultBuffer       = defaultRenderTarget 
		and defaultRenderTarget:getFrameBuffer()
		or  MOAIGfxDevice.getFrameBuffer()

	--collect batches
	for i, entry in ipairs( passQueue ) do
		local tag = entry.tag
		if tag == 'render-target' then
			local renderTarget = entry.renderTarget
			local buffer = renderTarget:getFrameBuffer()
			local option = entry.option or defaultOptions
			if buffer ~= currentBuffer then
				currentBatch = {}
				table.insert( bufferInfoTable,
					{
						buffer = buffer,
						option = option,
						batch  = currentBatch,
						camera = camera
					}
				)
				currentBuffer = buffer
				currentOption = option
			end

		elseif tag == 'layer' then
			if not currentBatch then
				currentBatch = {}
				table.insert( bufferInfoTable,
					{
						buffer = currentBuffer or defaultBuffer,
						option = emptyOptions,
						batch  = currentBatch,
						camera = camera
					}
				)
			end
			local layer = entry.layer
			if layer then	table.insert( currentBatch, layer ) end
		end

	end

	local cameraRenderCommands = {}
	camera._renderCommandTable = cameraRenderCommands
	-- table.clear( cameraRenderCommands )

	for i, info in ipairs( bufferInfoTable ) do
		local frameRenderCommand = MOAIFrameBufferRenderCommand.new()
		frameRenderCommand.camera = camera
		frameRenderCommand:setFrameBuffer( assert( info.buffer ) )
		frameRenderCommand:setRenderTable( assert( info.batch ) )
		frameRenderCommand:setEnabled( camera:isActive() )

		local option = info.option
		local clearColor   = option and option.clearColor
		local clearDepth   = option and option.clearDepth
		local clearStencil = option and option.clearStencil
		
		local tt = type( clearColor )
		if tt == 'table' then --color values
			frameRenderCommand:setClearColor( unpack( clearColor ) )
		elseif tt == 'string' then --color node
			frameRenderCommand:setClearColor( hexcolor( clearColor ) )
		elseif tt == 'userdata' then --color node
			frameRenderCommand:setClearColor( clearColor )
		else
			frameRenderCommand:setClearColor()
		end
		frameRenderCommand:setClearDepth( clearDepth ~= false )
		frameRenderCommand:setClearStencil( clearStencil ~= false )
		table.insert( cameraRenderCommands, frameRenderCommand )
	end

	return cameraRenderCommands
end