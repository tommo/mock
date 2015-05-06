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
		if cam._enabled then
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
	local bufferTable    = {}
	local currentRenderTarget = false
	local currentBuffer  = false
	local currentOption  = false
	local currentBatch   = false
	local bufferBatchMap = {}

	local defaultOptions = { clearColor = {0,0,0,1}, clearDepth = true }

	local bufferInfoTable = {}
	
	--TODO:replace with canvas context
	currentRenderTarget = game:getMainRenderTarget()
	currentBuffer       = currentRenderTarget and currentRenderTarget:getFrameBuffer() or MOAIGfxDevice.getFrameBuffer()
	
	--collect batches
	for i, entry in ipairs( passQueue ) do
		local tag = entry.tag
		if tag == 'render-target' then
			local renderTarget = entry.renderTarget
			local buffer = renderTarget:getFrameBuffer()
			local option = entry.option or defaultOptions
			if buffer ~= currentBuffer  then				
				currentBatch = {}
				table.insert( bufferInfoTable,
					{
						buffer = buffer,
						option = option,
						batch  = currentBatch						
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
						buffer = currentBuffer,
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

