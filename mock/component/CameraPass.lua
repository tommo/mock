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
		self:_resetPassQueue()
		for _, cam in ipairs( renderData.cameras ) do
			for _, camPass in ipairs( cam.passes ) do
				for i, pass in ipairs( camPass:build() ) do
					self:_pushRenderPass( pass )
				end
			end
		end
		local bufferTable, renderTableMap = self:_buildBufferTable()
		renderData.bufferTable    = bufferTable
		renderData.renderTableMap = renderTableMap
	end

	for context, renderData in pairs( contextMap ) do
		game:setRenderStack( context, renderData.deviceRenderTable, renderData.bufferTable, renderData.renderTableMap )		
	end
end

function CameraManager:_resetPassQueue()
	self.passQueue = {}
end

function CameraManager:_pushRenderPass( layer, framebuffer )
	table.insert( self.passQueue, { layer, framebuffer or false } )
end

function CameraManager:_buildBufferTable()
	local deviceBuffer   = MOAIGfxDevice.getFrameBuffer()

	local bufferTable    = {}
	local currentFB      = false
	local currentBatch   = {}
	local bufferBatchMap = {}
	local resultRenderTableMap = {}
	-- local hasDeviceBuffer = false

	for i, item in ipairs( self.passQueue ) do
		local layer, fb = item[1], item[2] or deviceBuffer
		if fb~=currentFB then
			currentBatch = {}
			table.insert( bufferTable, fb )
			local m = bufferBatchMap[ fb ] 
			if not m then
				m = {}
				bufferBatchMap[ fb ] = m
			end
			table.insert( m, currentBatch )
			-- if fb == deviceBuffer then hasDeviceBuffer = true end
			currentFB = fb
		end
		table.insert( currentBatch, layer )
	end

	for fb, batches in pairs( bufferBatchMap ) do
		local batchCount = #batches
		if batchCount > 1 then
			if fb == deviceBuffer then batchCount = batchCount + 1 end
			local innerContainer  = {}		
			local id = 0
			local function switcher()
				id = id + 1
				if id > batchCount then id = 1 end
				local rt = batches[ id ] or nil
				innerContainer[1] = rt
			end

			local renderTable = {
				--switcher,
				buildCallbackLayer( switcher ),
				--container,
				innerContainer
			}
			resultRenderTableMap[ fb ] = renderTable
		else
			resultRenderTableMap[ fb ] = batches
		end
	end
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
	self.passes = {}
end

function CameraPass:getCamera()
	return self.camera
end

function CameraPass:addPass( p )
	table.insert( self.passes, p )
	return p
end

function CameraPass:build()
	self.passes = {}
	self:onBuild()
	return self.passes
end

function CameraPass:setFrameBuffer()
end

function CameraPass:getFrameBuffer()
end

function CameraPass:buildSceneLayerRenderPass( sceneLayer )	
	local camera   = self.camera
	if not camera:isLayerIncluded( sceneLayer.name ) then return false end

	local source   = sceneLayer.source
	local layer    = MOAILayer.new()
	layer.name     = sceneLayer.name
	layer.priority = -1
	layer.source   = source

	layer:setPartition ( sceneLayer:getPartition() )
	layer:setViewport  ( camera.viewport )
	layer:setCamera    ( camera._camera )

	if camera.parallaxEnabled and source.parallax then
		layer:setParallax( unpack(source.parallax) )
	end
	--TODO: should be moved to debug facility
	layer:showDebugLines( false )
	local world = game:getBox2DWorld()
	if world then layer:setBox2DWorld( world ) end

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

function CameraPass:buildSingleQuadRenderPass()
	local camera   = self.camera

	local layer = MOAILayer.new()

	local viewport = MOAIViewport.new()
	viewport:setSize( camera:getViewportWndRect() )
	layer:setViewport( viewport )

	local dummyProp = MOAIProp.new()
	local quad = MOAIGfxQuad2D.new()
	quad:setRect( camera:getViewportRect() )
	dummyProp:setDeck( quad )
	layer:insertProp( dummyProp )
	layer.quad = quad

	return layer
end

function CameraPass:buildCallbackRenderPass( func )
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

--------------------------------------------------------------------
CLASS: SceneCameraPass ( CameraPass )
 	:MODEL{} 

function SceneCameraPass:onBuild()
	local camera = self.camera
	local scene  = camera.scene
	--make a copy of layers from current scene
	for id, sceneLayer in ipairs( scene.layers ) do
		local name  = sceneLayer.name
		local p = self:buildSceneLayerRenderPass( sceneLayer )
		self:addPass( p )
	end
end

--------------------------------------------------------------------
CLASS: CallbackCameraPass ( CameraPass )
	:MODEL{}

function CallbackCameraPass:onBuild()
	local function callback( ... )
		return self:onDraw( ... )
	end
	self:addPass( self:buildCallbackRenderPass( callback ) )
end

function CallbackCameraPass:onDraw( ... )
end
