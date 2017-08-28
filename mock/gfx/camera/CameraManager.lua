module 'mock'


--------------------------------------------------------------------
local function prioritySortFunc( a, b )	
	local pa = a.priority or 0
	local pb = b.priority or 0
	return pa < pb
end

--------------------------------------------------------------------
CLASS: CameraManager ()
	:MODEL{}

function CameraManager:__init()
	self.cameras    = {}
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

function CameraManager:updateLayerVisible()
	for cam in pairs( self.cameras ) do
		cam:updateLayerVisible()
	end
end

function CameraManager:update()
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
		local bufferTable = {}
		for _, cam in ipairs( renderData.cameras ) do
			local cameraRenderCommands = cam:buildRenderCommandTable()
			table.insert( bufferTable, cameraRenderCommands )
		end
		renderData.bufferTable    = bufferTable
		renderData.renderTableMap = {} --legacy?
	end

	if not contextMap[ 'game' ] then
		local placeHolderRenderCommand = MOAIFrameBufferRenderCommand.new()
		placeHolderRenderCommand:setClearColor( hexcolor'#4d543c' )
		placeHolderRenderCommand:setFrameBuffer( MOAIGfxDevice.getFrameBuffer() )
		contextMap[ 'game' ] = {
			deviceRenderTable = {},
			renderTableMap    = {},
			bufferTable       = { placeHolderRenderCommand },
		}
	end
	
	for context, renderData in pairs( contextMap ) do
		game:setRenderStack(
			context,
			renderData.deviceRenderTable,
			renderData.bufferTable,
			renderData.renderTableMap
		)
	end
	self:updateLayerVisible()
end

function CameraManager:onLayerUpdate( layer, var )
	if var == 'priority' then
		for _, cam in ipairs( self:getCameraList() ) do
			cam:reorderRenderLayers()
		end
		self:update()
	elseif var == 'editor_visible' or var == 'visible' then
		self:updateLayerVisible()
	end
end

--Singleton
local cameraManager = CameraManager()
connectSignalFunc( 'layer.update',  function(...) cameraManager:onLayerUpdate  ( ... ) end )

function getCameraManager()
	return cameraManager
end

