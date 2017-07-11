module 'mock'
local insert = table.insert

--------------------------------------------------------------------
CLASS: PaintCanvasTile ()
	:MODEL{}

function PaintCanvasTile:__init( canvas, x, y )
	self.parentCanvas = canvas
	local w, h = canvas.gridWidth, canvas.gridHeight

	self.x = x
	self.y = y
	self.locX = x * w
	self.locY = y * h
	self.w = w
	self.h = h

	self.name = string.format( 'Tile(%d,%d)', x, y )

	self.targetTexture = RenderTargetTexture()
	self.targetTexture:init( 
		w, h,
		'linear', MOAITexture.GL_RGBA8, false, false
	)
	self.renderTarget = self.targetTexture:getRenderTarget()
	self.frameBuffer = self.renderTarget:getFrameBuffer()

	local renderLayer = MOAILayer.new()
	renderLayer:setPartition( canvas.propPartition )
	local viewport = MOAIViewport.new()
	viewport:setSize( w, h )
	viewport:setScale( w, h )
	renderLayer:setViewport( viewport )

	local cam = MOAICamera.new()
	cam:setOrtho( true )
	cam:setLoc( self.locX + w/2, self.locY + h/2 )
	cam:setNearPlane( -100000 )
	cam:setFarPlane( 100000 )

	renderLayer:setCamera( cam )

	self.renderLayer = renderLayer

	local frameRenderCommand = MOAIFrameBufferRenderCommand.new()
	local fb = self.targetTexture:getMoaiFrameBuffer()
	frameRenderCommand:setClearColor()
	frameRenderCommand:setFrameBuffer( fb )
	frameRenderCommand:setRenderTable( { renderLayer } )
	self.renderCommand = frameRenderCommand

	self:clear( unpack( canvas.clearColor ) )

end

function PaintCanvasTile:buildClearCommand( r,g,b,a )
	local frameRenderCommand = MOAIFrameBufferRenderCommand.new()
	local fb = self.targetTexture:getMoaiFrameBuffer()
	frameRenderCommand:setFrameBuffer( fb )
	frameRenderCommand:setClearColor( r,g,b,a )
	return frameRenderCommand
end

function PaintCanvasTile:grabImage( img )
	img = img or MOAIImage.new()
	self.frameBuffer:grabCurrentFrame( img )
	return img
end

function PaintCanvasTile:clear( r,g,b,a )
	MOAIRenderMgr.renderTable{ 
		self:buildClearCommand( r,g,b,a )
	}
end


--------------------------------------------------------------------
CLASS: PaintCanvas ()
	:MODEL{}

function PaintCanvas:__init()
	self.rows = {}
	self.gridWidth  = 128
	self.gridHeight = 128
	self.propPartition = MOAIPartition.new()
	self.clearColor = { 0,0,0,0 }
	self.dirtyTiles = {}
end

function PaintCanvas:setClearColor( r,g,b,a )
	self.clearColor = { r,g,b,a }
end

local floor = math.floor
function PaintCanvas:locToCoord( x, y )
	local gw, gh = self.gridWidth, self.gridHeight
	local ix = 	floor( x / gw )
	local iy = 	floor( y / gw )
	return ix, iy
end

function PaintCanvas:getTile( x, y )
	local rows = self.rows
	local row = rows[ y ]
	if not row then return nil end
end

function PaintCanvas:affirmTile( x, y )
	local gw, gh = self.gridWidth, self.gridHeight
	local rows = self.rows
	local row = rows[ y ]
	if not row then
		row = {}
		rows[ y ] = row
		local tile = PaintCanvasTile( self, x, y )
		row[ x ] = tile
		return tile
	end

	local tile = row[ x ]
	if not tile then
		tile = PaintCanvasTile( self, x, y )
		row[ x ] = tile
	end
	return tile
end

function PaintCanvas:affirmTileAABB( x0, y0, x1, y1 )
	if x0 > x1 then x0, x1 = x1, x0 end
	if y0 > y1 then y0, y1 = y1, y0 end
	local output = {}
	local rows = self.rows
	for iy = y0, y1 do
		local row = rows[ iy ]
		if not row then
			row = {}
			rows[ iy ] = row
			for ix = x0, x1 do
				local tile = PaintCanvasTile( self, ix, iy )
				row[ ix ] = tile
				insert( output, tile )
			end
		else
			for ix = x0, x1 do
				local tile = row[ ix ]
				if not tile then 
					tile = PaintCanvasTile( self, ix, iy )
					row[ ix ] = tile
				end
				insert( output, tile )
			end
		end
	end
	return output
end

function PaintCanvas:collectTiles()
	local result = {}
	for _, row in pairs( self.rows ) do
		for _, tile in pairs( row ) do
			insert( result, tile )
		end
	end
	return result
end

function PaintCanvas:markDirtyAABB( x0,y0,x1,y1 )
	local tiles = self:affirmTileAABB( x0,y0,x1,y1 )
	local dirtyTiles = self.dirtyTiles
	for _, t in pairs( tiles ) do
		dirtyTiles[ t ] = true
	end
end


--------------------------------------------------------------------
CLASS: PaintBrushStroke ()
	:MODEL{}

function PaintBrushStroke:applyToCanvas( canvas )
	local props = self:buildGraphicsProp( canvas )
	if not props then return end

	local tt = type( props )
	if tt == 'table' then
		--pass
	elseif tt == 'userdata' then
		props = { props }
	end

	local partition = canvas.propPartition
	local dirtyTiles = canvas.dirtyTiles
	for _, prop in pairs( props ) do
		local x0, y0, z0, x1, y1, z1 = prop:getWorldBounds()
		local ix0, iy0 = canvas:locToCoord( x0, y0 )
		local ix1, iy1 = canvas:locToCoord( x1, y1 )
		canvas:markDirtyAABB( ix0, iy0, ix1, iy1 )
		partition:insertProp( prop )
	end
end

function PaintBrushStroke:buildGraphicsProp( canvas )
	return nil
end

--------------------------------------------------------------------
CLASS: PaintCanvasEditor ()
	:MODEL{}

function PaintCanvasEditor:__init( canvas )
	self.canvas = canvas
	self.currentStrokes = {}
end

function PaintCanvasEditor:addStroke( stroke )
	insert( self.currentStrokes, stroke )
end

function PaintCanvasEditor:clearCanvas( r,g,b,a )
	local renderTable = {}
	for _, tile in ipairs( self.canvas:collectTiles() ) do
		insert( renderTable, tile:buildClearCommand( r,g,b,a ) )
	end
	MOAIRenderMgr.renderTable( renderTable )
end

function PaintCanvasEditor:updateCanvas()
	--build strokes
	local canvas = self.canvas
	local partition = canvas.propPartition
	for _, stroke in ipairs( self.currentStrokes ) do
		stroke:applyToCanvas( canvas )
	end

	--flush
	local renderTable = {}
	for tile in pairs( canvas.dirtyTiles ) do
		insert( renderTable, tile.renderCommand )
	end
	MOAIGfxResourceMgr.update()
	MOAINodeMgr.update()
	MOAIRenderMgr.renderTable( renderTable )

	--reset
	canvas.dirtyTiles = {}
	self.currentStrokes = {}
	self.canvas.propPartition:clear()

end

function PaintCanvasEditor:loadStroke( stroke )
end


--------------------------------------------------------------------
CLASS: PaintBrush ()
	:MODEL{}

function PaintBrush:buildStroke( path )
	return false
end



