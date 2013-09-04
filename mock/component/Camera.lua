module 'mock'
local insert = table.insert
local remove = table.remove

--[[
	camera = 
		RenderTable 
]]

EnumCameraViewportMode = {
	{ 'EXPANDING', 'expanding' }, --expand to full screen
	{ 'FIXED',     'fixed' },     --fixed size, in device unit
	{ 'RELATIVE',  'relative' },  --relative size, in ratio
}

local function prioritySortFunc( a, b )	
	local pa = a.priority or 0
	local pb = b.priority or 0
	return pa < pb
end

local globalCameraList = {}

local function findMainCameraForScene( scene )
	for _, cam in ipairs( globalCameraList ) do
		if cam.scene == scene and cam.mainCamera then return cam end
	end
	return nil
end

local function updateRenderStack()
	--TODO: render order of framebuffers
	local contextMap = {}

	local renderTableMap = {}
	local bufferTable    = {}
	local deviceBuffer   = MOAIGfxDevice.getFrameBuffer()
	local count = 0
	table.sort( globalCameraList, prioritySortFunc )

	for _, cam in ipairs( globalCameraList ) do
		local context = cam.context
		local renderData = contextMap[ context ]
		if not renderData then
			renderData = {
				renderTableMap    = {},
				bufferTable       = {},
				deviceRenderTable = {}
			}
			contextMap[ context ] = renderData
		end

		local fb = cam:getFrameBuffer()
		local rt
		if fb ~= deviceBuffer then
			rt = renderData.renderTableMap[ fb ]
			if not rt then
				rt = {}
				renderData.renderTableMap[ fb ] = rt
				if fb ~= deviceBuffer then --add framebuffer by camera order
					insert( renderData.bufferTable, fb )
				end
			end
		else
			rt = renderData.deviceRenderTable
		end

		for i, layer in ipairs( cam.moaiLayers ) do
			count = count + 1
			insert( rt, layer )
		end

	end

	for context, renderData in pairs( contextMap ) do
		game:setRenderStack( context, renderData.deviceRenderTable, renderData.bufferTable, renderData.renderTableMap )		
	end

end

local function _onDeviceResize( w, h )
	for _, cam in ipairs( globalCameraList ) do
		if not cam.fixedViewport then
			cam:updateViewport()
		end
	end
end


local function _onGameResize( w, h )
	for _, cam in ipairs( globalCameraList ) do
		if not cam.fixedViewport then
			cam:updateViewport()
		end
	end
end

local function _onLayerUpdate( layer, var )
	if var == 'priority' then
		for _, cam in ipairs( globalCameraList ) do
			cam:reorderLayers()
		end
		updateRenderStack()
	end
end

connectSignalFunc( 'device.resize', _onDeviceResize )
connectSignalFunc( 'gfx.resize', _onGameResize )
connectSignalFunc( 'layer.update', _onLayerUpdate )
-------------
CLASS: Camera ( Actor )

:MODEL{
	Field 'zoom'        :number()  :getset('Zoom')   :range(0) ;
	Field 'perspective' :boolean() :isset('Perspective');
	Field 'nearPlane'   :number()  :getset('NearPlane');
	Field 'farPlane'    :number()  :getset('FarPlane');
	Field 'FOV'         :number()  :getset('FOV')    :range( 0, 360 ) ;
}

wrapWithMoaiTransformMethods( Camera, '_camera' )


local function _cameraZoomControlNodeCallback( node )
	return node.camera:updateViewport()
end

function Camera:__init( option )
	option = option or {}

	local cam = MOAICamera.new()
	self._camera  = cam

	self.relativeViewportSize = false
	self.fixedViewportSize    = false

	self.viewportScale = false
	self.mode          = 'expanding' --{ 'strech', 'fixed' }

	self.zoomControlNode = MOAIScriptNode.new()
	self.zoomControlNode:reserveAttrs( 1 )
	self.zoomControlNode.camera = self
	self:setZoom( 1 )
	self.zoomControlNode:setCallback( _cameraZoomControlNodeCallback )

	self.moaiLayers = {}
	self.viewport   = MOAIViewport.new()
	self.priority   = option.priority or 0
	self.mainCamera = false

	self.dummyLayer = MOAILayer.new()  --just for projection transform
	self.dummyLayer:setViewport( self.viewport )
	self.dummyLayer:setCamera( self._camera )
	
	self.includedLayers = option.included or 'all'
	self.excludedLayers = option.excluded or ( option.included and 'all' or false )
	self:setFrameBuffer()

	self:setFOV( 90 )
	local defaultNearPlane, defaultFarPlane = -10000, 10000
	self:setNearPlane( defaultNearPlane )
	self:setFarPlane ( defaultFarPlane )
	self:setPerspective( false )

	self.context = 'game'
end

function Camera:onAttach( entity )
	self.scene = entity.scene
	table.insert( globalCameraList, self )
	self:updateViewport()
	self:updateLayers()
	entity:_attachTransform( self._camera )
	--use as main camera if no camera applied yet for current scene
	if not findMainCameraForScene( self.scene ) then 
		self:setMainCamera()
	end
end

function Camera:onDetach( entity )
	--remove from global camera list
	for i, cam in ipairs( globalCameraList ) do
		if cam == self then remove( globalCameraList, i ) break end
	end
	updateRenderStack()
end

--------------------------------------------------------------------
--will affect Entity:wndToWorld
function Camera:setMainCamera()
	if self.mainCamera then return end
	local scene = self.scene
	if not scene then return end
	for _, cam in ipairs( globalCameraList ) do
		if cam.mainCamera and cam ~= self and cam.scene == self.scene then
			cam.mainCamera = false
		end 
	end

	for k, layer in pairs( self.scene.layers ) do
		local name = layer.name
		if self:_isLayerIncluded( name ) or (not self:_isLayerExcluded( name )) then
			layer:setViewport( self.viewport )
			layer:setCamera( self._camera )
		end
	end	
end

function Camera:isMainCamera()
	return self.mainCamera
end

function Camera:getMainCamera()
	if not self.scene then return nil end
	return findMainCameraForScene( self.scene )
end

--------------------------------------------------------------------
function Camera:isLayerIncluded( name )
	for i, layer in ipairs( self.moaiLayers ) do
		if layer.name == name then return true end
	end
	return false
end 

--internal use
function Camera:_isLayerIncluded( name )
	if name == '_GII_EDITOR_LAYER' and not self.__allowEditorLayer then return false end
	if self.includedLayers == 'all' then return nil end
	for i, n in ipairs( self.includedLayers ) do
		if n == name then return true end
	end
	return false
end

--internal use
function Camera:_isLayerExcluded( name )
	if name == '_GII_EDITOR_LAYER' and not self.__allowEditorLayer then return true end
	if self.excludedLayers == 'all' then return true end
	if not self.excludedLayers then return false end
	for i, n in ipairs( self.excludedLayers ) do
		if n == name then return true end
	end
	return false
end

function Camera:updateLayers()
	local scene  = self.scene
	local layers = {} 
	self.moaiLayers = layers
	--make a copy of layers from current scene
	for id, sceneLayer in ipairs( scene.layers ) do
		local name  = sceneLayer.name
		if self:_isLayerIncluded( name ) or (not self:_isLayerExcluded( name )) then
			local layer    = MOAILayer.new()
			layer.name     = name
			layer.priority = -1
			layer.source   = sceneLayer.source
			layer:setPartition( sceneLayer:getPartition() )

			layer:setViewport( self.viewport )
			layer:setCamera( self._camera )
			
			--TODO: should be moved to debug facility
			layer:showDebugLines( true )
			local world = game:getBox2DWorld()
			if world then layer:setBox2DWorld( world ) end

			if sceneLayer.sortMode then
				layer:setSortMode( sceneLayer.sortMode )
			end
			inheritVisible( layer, sceneLayer )
			insert( layers, layer )
			layer._mock_camera = self
		end
	end
	self:reorderLayers()
	updateRenderStack()
end

function Camera:reorderLayers()
	local layers = self.moaiLayers 
	for i, layer in ipairs( layers ) do
		layer.priority = layer.source.priority
	end
	table.sort( layers, prioritySortFunc )
end

function Camera:getRenderLayer( name )
	for i, layer in ipairs( self.moaiLayers ) do
		if layer.name == name then return layer end
	end
	return nil
end
--------------------------------------------------------------------
function Camera:setPerspective( p )
	self.perspective = p
	local ortho = not p
	local cam = self._camera	
	cam:setOrtho( ortho )
	if ortho then

	else --perspective
		cam:setFieldOfView( 90 )
	end
	self:updateZoom()
end

function Camera:isPerspective()
	return self.perspective
end


function Camera:setNearPlane( near )
	local cam = self._camera
	self.nearPlane = near
	cam:setNearPlane( near )
end

function Camera:setFarPlane( far )
	local cam = self._camera
	self.farPlane = far
	cam:setFarPlane( far )
end

function Camera:getFOV()
	return self.fov
end

function Camera:setFOV( fov )
	self.fov = fov
	self._camera:setFieldOfView( fov )
end

function Camera:getNearPlane()
	return self.nearPlane
end

function Camera:getFarPlane()
	return self.farPlane
end
--------------------------------------------------------------------

function Camera:wndToWorld( x, y )
	return self.dummyLayer:wndToWorld( x, y )
end

function Camera:worldToWnd( x, y, z )
	return self.dummyLayer:worldToWnd( x, y, z )
end

function Camera:getScreenRect()
	return game:getViewportRect()
end

function Camera:getScreenScale()
	return game:getViewportScale()
end

function Camera:updateViewport( updateRenderStack )
	local gx0, gy0, gx1, gy1
	local fb = self.frameBuffer
	if fb == MOAIGfxDevice.getFrameBuffer() then		
		gx0, gy0, gx1, gy1 = self:getScreenRect()
	else
		gx0, gy0 = 0, 0
		gx1, gy1 = fb:getSize()
	end

	local vx0, vy0, vx1, vy1

	--TODO: clip rect if exceeds the framebuffer boundary
	local mode = self.mode
	if mode == 'expanding' then
		vx0, vy0, vx1, vy1 =  gx0, gy0, gx1, gy1
	elseif mode == 'fixed' then
		vx0, vy0, vx1, vy1 =  unpack( self.fixedViewportSize )
	elseif mode == 'relative' then
		local w, h = gx1-gx0, gy1-gy0
		local x0, y0 ,x1, y1 = unpack( self.relativeViewportSize )
		vx0, vy0, vx1, vy1 =  x0*w + gx0, y0*h + gy0, x1*w + gx0, y1*h + gy0
	else
		error( 'unknown camera mode:' .. tostring( mode ) )	
	end

	local vw, vh = vx1 - vx0, vy1 - vy0
	
	self.viewportWndRect  = { vx0, vy0, vx1, vy1 }
	self.viewport:setSize( vx0, vy0, vx1, vy1 )

	self:updateZoom()
end

function Camera:updateZoom()
	local zoom = self:getZoom()
	if zoom <= 0 then zoom = 0.00001 end
	local sw, sh = self:getScreenScale()
	if not sw then return end
	local w, h   = sw / zoom, sh / zoom
	if self.perspective then
		local dx,dy,dx1,dy1 = self:getScreenRect()
		local dw = dx1-dx
		local dh = dy1-dy
		self.viewportScale  = { w, h }
		self.viewport:setScale( dw/zoom, dh/zoom )
	else
		self.viewportScale  = { w, h }
		self.viewport:setScale( w, h )
	end
end

function Camera:getViewportSize()
	local scale = self.viewportScale
	return scale[1], scale[2]
end

function Camera:getViewportRect()
	local x0, y0, x1, y1 = self:getViewportLocalRect()
	local cam = self._cam
	local wx0, wy0 = cam:modelToWorld( x0, y0 )
	local wx1, wy1 = cam:modelToWorld( x1, y1 )
	return wx0, wy0, wx1, wy1
end

function Camera:getViewportLocalRect()
	local w, h = self:getViewportWorldSize()
	return -w/2, -h/2, w/2, h/2
end

function Camera:getViewportWndRect()
	return unpack( self.viewportWndRect )	
end

function Camera:getViewportWndSize()
	local x0,y0,x1,y1 = self:getViewportWndRect()
	return x1-x0, y1-y0
end

function Camera:setViewport( mode, x0, y0, x1, y1 )
	mode = mode or 'expanding'
	self.mode = mode
	if mode == 'relative' then
		self.relativeViewportSize = { x0, y0, x1, y1 }
	elseif mode == 'fixed' then
		self.fixedViewportSize = { x0, y0, x1, y1 }
	else
		error( 'unknown camera mode:' .. tostring( mode ) )
	end
	self:updateViewport()
end

--------------------------------------------------------------------
--Layer control
--------------------------------------------------------------------
function Camera:bindLayers( included )
	for i, layerName in ipairs( included ) do
		local layer = self.scene:getLayer( layerName )
		if not layer then error('no layer named:'..layerName,2) end
		layer:setCamera( self._camera )
	end
end

function Camera:bindAllLayerExcept( excluded )
	for k, layer in pairs( self.scene.layers ) do
		local match = false
		for i, n in ipairs(excluded) do
			if layer.name == n then match = true break end
		end
		if not match then layer:setCamera( self._camera ) end
	end
end

function Camera:hideLayer( layerName )
	return self:showLayer( layerName, false )
end

function Camera:hideAllLayers( layerName )
	return self:showAllLayers( layerName, false )
end

function Camera:showAllLayers( layerName, shown )
	shown = shown ~= false
	for i, layer in ipairs( self.moaiLayers ) do
		layer:setVisible( shown )
	end
end

function Camera:showLayer( layerName, shown )
	shown = shown ~= false
	for i, layer in ipairs( self.moaiLayers ) do
		if layer.name == layerName then
			layer:setVisible( shown )
		end
	end
end

----
function Camera:seekZoom( zoom, time, easeMode )
	return self.zoomControlNode:seekAttr( 0, zoom, time, easeMode )
end

function Camera:setZoom( zoom )
	return self.zoomControlNode:setAttr( 0, zoom or 1 )
end

function Camera:getZoom()
	return self.zoomControlNode:getAttr( 0 )
end

function Camera:setPriority( p )
	self.priority = p or 0
	updateRenderStack()
end

function Camera:setFrameBuffer( fb )
	self.frameBuffer = fb or MOAIGfxDevice.getFrameBuffer()
	if self.scene then
		self:updateViewport()
		self:updateLayers()
	end
	return self.frameBuffer
end

function Camera:getFrameBuffer()
	return self.frameBuffer
end

--helpers
function Camera:getPos( name, ox, oy ) 
	--TODO: fix this
	ox, oy = ox or 0, oy or 0
	-- local x0, y0, x1, y1 = self:getViewportWorldRect()
	if     name=='top' then
		return gfx.h/2+oy
	elseif name=='bottom' then
		return -gfx.h/2+oy
	elseif name=='left' then
		return -gfx.w/2+ox
	elseif name=='right' then
		return gfx.w/2+ox
	elseif name=='left-top' then
		return -gfx.w/2+ox,gfx.h/2+oy
	elseif name=='left-bottom' then
		return -gfx.w/2+ox,-gfx.h/2+oy
	elseif name=='right-top' then
		return gfx.w/2+ox,gfx.h/2+oy
	elseif name=='right-bottom' then
		return gfx.w/2+ox,-gfx.h/2+oy
	elseif name=='center' then
		return ox,oy
	elseif name=='center-top' then
		return ox,gfx.h/2+oy
	elseif name=='center-bottom' then
		return ox,-gfx.h/2+oy
	elseif name=='left-center' then
		return -gfx.w/2+ox,oy
	elseif name=='right-center' then
		return gfx.w/2+ox,oy
	else
		return error('what position?'..name)
	end
end

wrapWithMoaiTransformMethods( Camera, '_camera' )


registerComponent( 'Camera', Camera)