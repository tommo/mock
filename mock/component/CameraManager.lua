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
	dummyDeck:setRect( -10000, -10000, 10000, 10000 )
	layer:insertProp( dummyProp )
	return layer
end


local DefaultFrameBufferOptions = {
	filter      = MOAITexture.GL_LINEAR,
	clearDepth  = true,
	clearStencil= true,
	colorFormat = false,
	scale       = 1,
	size        = 'relative',
	autoResize  = true
}

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
	--TODO: render order of renderTargets
	local contextMap = {}

	local renderTableMap = {}
	local bufferTable    = {}
	
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
		game:setRenderStack(
			context,
			renderData.deviceRenderTable,
			renderData.bufferTable,
			renderData.renderTableMap
		)
	end

end

function CameraManager:_buildBufferTable( passQueue )
	local currentRenderTarget = false
	local currentBuffer  = false
	local currentOption  = false
	local currentBatch   = false
	local currentCamera  = false
	local bufferBatchMap = {}

	local defaultOptions = { clearColor = {0,0,0,1}, clearDepth = true, clearStencil = true }

	local bufferInfoTable = {}
	
	--TODO:replace with canvas context
	currentRenderTarget = game:getMainRenderTarget()
	currentBuffer       = currentRenderTarget and currentRenderTarget:getFrameBuffer() or MOAIGfxDevice.getFrameBuffer()
	

	--collect batches
	for i, entry in ipairs( passQueue ) do
		local tag = entry.tag

		local camera = entry.camera
		local cameraChanged = false
		if camera ~= currentCamera then
			cameraChanged = true
			currentCamera = camera
		end

		if tag == 'render-target' then
			local renderTarget = entry.renderTarget
			local buffer = renderTarget:getFrameBuffer()
			local option = entry.option or defaultOptions
			
			if (buffer ~= currentBuffer) or cameraChanged then
				currentBatch = {}
				table.insert( bufferInfoTable,
					{
						buffer = buffer,
						option = option,
						batch  = currentBatch,
						camera = currentCamera
					}
				)
				currentBuffer = buffer
				currentOption = option
			end

		elseif tag == 'layer' then
			if (not currentBatch) or cameraChanged then
				currentBatch = {}
				table.insert( bufferInfoTable,
					{
						buffer = currentBuffer,
						option = defaultOptions,
						batch  = currentBatch,
						camera = currentCamera
					}
				)
			end
			local layer = entry.layer
			if layer then	table.insert( currentBatch, layer ) end
		end

	end

	local USE_FRAMEBUFFER_COMMAND = true

	if USE_FRAMEBUFFER_COMMAND then
		local currentCamera = false
		local resultBufferTable = {}
		local currentCamerRenderCommands = {}
		local resultRenderTableMap = {} --legacy

		for i, info in ipairs( bufferInfoTable ) do
			local camera = info.camera
			if camera ~= currentCamera then
				currentCamera = camera
				currentCamerRenderCommands = {}
				camera:_updateRenderCommandTable( currentCamerRenderCommands )
				table.insert( resultBufferTable, currentCamerRenderCommands )
			end
			
			local frameRenderCommand = MOAIFrameBufferRenderCommand.new()
			frameRenderCommand:setFrameBuffer( assert( info.buffer ) )
			frameRenderCommand:setRenderTable( assert( info.batch ) )
			frameRenderCommand.camera = camera
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
			table.insert( currentCamerRenderCommands, frameRenderCommand )
		end

		return resultBufferTable, resultRenderTableMap
	else
		--
		local innerContainer = {}
		local batchCount  = #bufferInfoTable
		local id = 0
		local function switchBatch()
			if batchCount == 0 then return end
			id = id + 1
			if id > batchCount then id = 1 end

			local info = bufferInfoTable[ id ]

			local buffer   = info.buffer
			--batch
			innerContainer[1] = info.batch or nil
			--option
			local option = info.option
			local clearColor = option and option.clearColor
			if clearColor then
				buffer:setClearColor( unpack( clearColor ) )
			else
				buffer:setClearColor()
			end
			buffer:setClearDepth( ( option and option.clearDepth ) ~= false )
			buffer:setClearStencil( ( option and option.clearStencil ) ~= false )
		end

		local universalRenderTable = {
			--container,
			innerContainer,
			--switcher,
			buildCallbackLayer( switchBatch ),
		}
		
		local resultBufferTable    = {}
		local resultRenderTableMap = {}
		local currentCameraBufferTable = {}
		local currentCamera = false
		for i, entry in ipairs( bufferInfoTable ) do
			local buffer = entry.buffer		
			local camera = entry.camera
			if camera ~= currentCamera then
				currentCamera = camera
				currentCameraBufferTable = {}
				table.insert( resultBufferTable, currentCameraBufferTable )
			end
			table.insert( currentCameraBufferTable, buffer )
			resultRenderTableMap[ buffer ] = universalRenderTable
		end

		switchBatch() --set initial id

		return resultBufferTable, resultRenderTableMap
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
connectSignalFunc( 'layer.update',  function(...) cameraManager:onLayerUpdate  ( ... ) end )

function getCameraManager()
	return cameraManager
end

