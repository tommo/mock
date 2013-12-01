module 'mock'

--------------------------------------------------------------------
local function prioritySortFunc( a, b )	
	local pa = a.priority or 0
	local pb = b.priority or 0
	return pa < pb
end

local function buildCallbackLayer( func )
	local layer = MOAILayer.new()
	local viewport = MOAIViewport.new()
	viewport:setSize( 1,1 )
	layer:setViewport( viewport )
	local dummyProp = MOAIProp.new()
	local dummyDeck = MOAIScriptDeck.new()
	dummyProp:setDeck( dummyDeck )
	dummyDeck:setDrawCallback( func )
	dummyDeck:setRect(-10000,-10000,10000,10000)
	layer:insertProp( dummyProp )
	return layer
end
--------------------------------------------------------------------
CLASS: CameraManager ()
	:MODEL{}

function CameraManager:__init()
	self.cameras = {}
	self.passQueue = {}
end

function CameraManager:register( cam )
	self.cameras[ cam ] = true
	self:update()
end

function CameraManager:unregister( cam )
	self.cameras[ cam ] = nil
	self:update()
end

function CameraManager:getCameraList()
	local list = {}
	local i = 1
	for cam in pairs( self.cameras ) do
		list[ i ] = cam
		i = i + 1
	end
	table.sort( list, prioritySortFunc )	
	return list
end

function CameraManager:update()
	--TODO: render order of framebuffers
	local contextMap = {}

	local renderTableMap = {}
	local bufferTable    = {}
	local deviceBuffer   = MOAIGfxDevice.getFrameBuffer()
	
	--build context->cameraList map	
	for _, cam in ipairs( self:getCameraList() ) do
		local context    = cam.context
		local renderData = contextMap[ context ]
		if not renderData then
			renderData = {
				cameras           = {},
				renderTableMap    = {},
				bufferTable       = {},
				deviceRenderTable = false
			}
			contextMap[ context ] = renderData
		end
		table.insert( renderData.cameras, cam )
	end

	for context, renderData in pairs( contextMap ) do
		local passQueue = {}
		for _, cam in ipairs( renderData.cameras ) do
			for _, camPass in ipairs( cam.passes ) do				
				for i, passEntry in ipairs( camPass:build() ) do
					table.insert( passQueue, passEntry )
				end
			end
		end
		local bufferTable, renderTableMap = self:_buildBufferTable( passQueue )
		renderData.bufferTable    = bufferTable
		renderData.renderTableMap = renderTableMap
	end

	for context, renderData in pairs( contextMap ) do
		game:setRenderStack( context, renderData.deviceRenderTable, renderData.bufferTable, renderData.renderTableMap )		
	end
end

function CameraManager:_buildBufferTable( passQueue )
	local deviceBuffer   = MOAIGfxDevice.getFrameBuffer()

	local bufferTable    = {}
	local currentFB      = false
	local currentOption  = false
	local currentBatch   = false
	local bufferBatchMap = {}

	local defaultOptions = { clearColor = {0,0,0,1}, clearDepth = true }

	local bufferInfoTable = {}
	
	--collect batches
	for i, entry in ipairs( passQueue ) do
		local tag = entry.tag

		if tag == 'buffer' then
			local fb = entry.framebuffer or deviceBuffer
			local option = entry.option or defaultOptions
			if fb ~= currentFB  then				
				currentBatch = {}
				table.insert( bufferInfoTable,
					{
						buffer = fb,
						option = option,
						batch  = currentBatch						
					}
				)
				currentFB     = fb
				currentOption = option
			end
		elseif tag == 'layer' then
			if not currentBatch then
				currentBatch = {}
				table.insert( bufferInfoTable,
					{
						buffer = deviceBuffer,
						option = defaultOptions,
						batch  = currentBatch						
					}
				)
			end
			local layer = entry.layer
			if layer then	table.insert( currentBatch, layer ) end
		end

	end

	--
	local bufferTable    = {}
	local innerContainer = {}
	local batchCount  = #bufferInfoTable
	local id = 0

	local function switchBatch()
		if batchCount==0 then return end
		id = id + 1
		if id > batchCount then id = 1 end
		local info = bufferInfoTable[ id ]
		local fb   = info.buffer
		--batch
		innerContainer[1] = info.batch or nil
		--option
		local option = info.option
		local clearColor = option and option.clearColor
		if clearColor then
			fb:setClearColor( unpack( clearColor ) )
		else
			fb:setClearColor()
		end
		fb:setClearDepth( option and option.clearDepth )
	end

	local universalRenderTable = {
		--container,
		innerContainer,
		--switcher,
		buildCallbackLayer( switchBatch ),
	}

	local resultRenderTableMap = {}
	for i, entry in ipairs( bufferInfoTable ) do
		local buffer = entry.buffer		
		table.insert( bufferTable, buffer )
		resultRenderTableMap[ buffer ] = universalRenderTable
	end
	switchBatch() --set initial id
	return bufferTable, resultRenderTableMap

end

function CameraManager:onDeviceResize( w, h )
	for _, cam in ipairs( self:getCameraList() ) do
		if not cam.fixedViewport then
			cam:updateViewport()
		end
	end
end


function CameraManager:onGameResize( w, h )
	for _, cam in ipairs( self:getCameraList() ) do
		if not cam.fixedViewport then
			cam:updateViewport()
		end
	end
end

function CameraManager:onLayerUpdate( layer, var )
	if var == 'priority' then
		for _, cam in ipairs( self:getCameraList() ) do
			cam:reorderRenderLayers()
		end
		self:update()
	elseif var == 'editor_visible' then
		self:update()
	end
end

--Singleton
local cameraManager = CameraManager()
connectSignalFunc( 'device.resize', function(...) cameraManager:onDeviceResize ( ... ) end )
connectSignalFunc( 'gfx.resize',    function(...) cameraManager:onGameResize   ( ... ) end )
connectSignalFunc( 'layer.update',  function(...) cameraManager:onLayerUpdate  ( ... ) end )

function getCameraManager()
	return cameraManager
end

--------------------------------------------------------------------
CLASS: CameraPass ()
	:MODEL{}

function CameraPass:__init()
	self.camera = false
	self.renderLayers = {}
	self.framebuffer  = false
	self.framebuffers = {}
	self.passes = {}
end

function CameraPass:getCamera()
	return self.camera
end

function CameraPass:pushRenderLayer( layer, framebuffer, option )
	if not layer then return end
	if framebuffer or option then
		self:pushFrameBuffer( framebuffer, option )
	end

	table.insert( self.passes, {
			tag   = 'layer',
			layer = layer
		}
	)
	return layer
end

function CameraPass:pushFrameBuffer( framebuffer, option )
	table.insert( self.passes, { 
		tag         = 'buffer',
		framebuffer = framebuffer or false,
		option      = option 
		}
	)
end

function CameraPass:build()
	self.passes = {}
	self:onBuild()
	return self.passes
end

function CameraPass:requestFramebuffer( name )
	name = name or 'default'
	local fb = self.framebuffers[ name ]
	if fb then return fb end
	fb = self:buildFramebuffer()
	self.framebuffers[ name ] = fb
	return fb
end

function CameraPass:clearFramebuffers()
	for name, fb in pairs( self.framebuffers ) do
		fb:release()
	end
	self.framebuffers = {}
end


local function _convertFilter( filter, mipmap )
	local output
	if filter == 'linear' then
		if mipmap then
			output = MOAITexture.GL_LINEAR_MIPMAP_LINEAR
		else
			output = MOAITexture.GL_LINEAR
		end
	else  --if fukter == 'nearest' then
		if mipmap then
			output = MOAITexture.GL_NEAREST_MIPMAP_NEAREST
		else
			output = MOAITexture.GL_NEAREST
		end
	end	
	return output
end

function CameraPass:buildFramebuffer()
	local camera = self.camera
	local fb0 = camera:getMoaiFrameBuffer()
	if fb0 then
	end
	local fb = MOAIFrameBufferTexture.new()
	fb:setClearColor()
	fb:setClearDepth( false )
	fb:init( 1136, 640 )
	fb:setFilter( MOAITexture.GL_LINEAR )
	return fb
end

function CameraPass:buildDebugLinesLayer()
	local camera   = self.camera
	if not camera.showDebugLines then return nil end
	local layer    = MOAILayer.new()
	layer.priority = 100000

	layer:setViewport  ( camera.viewport )
	layer:setCamera    ( camera._camera )

	layer._mock_camera = camera

	layer:showDebugLines( true )
	local world = game:getBox2DWorld()
	if world then layer:setBox2DWorld( world ) end

	return layer
end

function CameraPass:buildSceneLayerRenderLayer( sceneLayer )	
	local camera   = self.camera
	if not camera:isLayerIncluded( sceneLayer.name ) then return false end

	local source   = sceneLayer.source
	local layer    = MOAILayer.new()
	layer.name     = sceneLayer.name
	layer.priority = -1
	layer.source   = source

	layer:showDebugLines( false )
	layer:setPartition ( sceneLayer:getPartition() )
	layer:setViewport  ( camera.viewport )
	layer:setCamera    ( camera._camera )

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

function CameraPass:buildSingleQuadRenderLayer( texture )
	local camera   = self.camera

	local layer = MOAILayer.new()

	local viewport = MOAIViewport.new()
	local vx,vy,vx1,vy1 = camera:getViewportWndRect()
	viewport:setSize( vx,vy,vx1,vy1 )
	viewport:setScale( vx1-vx, vy1-vy )
	layer:setViewport( viewport )
	local quad = MOAIGfxQuad2D.new()
	local w, h = camera:getViewportSize()
	quad:setRect( -w/2, -h/2, w/2, h/2 )
	quad:setUVRect( 0,0,1,1 )
	if texture then quad:setTexture( texture ) end

	local dummyProp = MOAIProp.new()
	dummyProp:setDeck( quad )
	layer:insertProp( dummyProp )

	layer.quad = quad
	layer.prop = dummyProp

	return layer
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
	dummyDeck:setRect(-10000,-10000,10000,10000)
	layer:insertProp( dummyProp )
	return layer
end


function CameraPass:pushSceneRenderPass( framebuffer, option )
	local camera = self.camera
	local scene  = camera.scene
	--make a copy of layers from current scene
	if framebuffer or option then
		self:pushFrameBuffer( framebuffer, option )
	end

	for id, sceneLayer in ipairs( scene.layers ) do
		local name  = sceneLayer.name
		local p = self:buildSceneLayerRenderLayer( sceneLayer )

		self:pushRenderLayer( p )
	end
end

--------------------------------------------------------------------
CLASS: SceneCameraPass ( CameraPass )
 	:MODEL{} 

function SceneCameraPass:onBuild()
	self:pushSceneRenderPass()
	local debugLayer = self:buildDebugLinesLayer()
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
--------------------------------------------------------------------
