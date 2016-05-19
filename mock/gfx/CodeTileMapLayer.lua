module 'mock'

--------------------------------------------------------------------
CLASS: CodeTileGrid ( TileMapGrid )
	:MODEL{}

function CodeTileGrid:__init( grid )
	self.nameToId = {}
	self.idToName = {}
	self.tileset = false
	self.grid = grid or MOAIGrid.new()
	self.loaded = false
	self.width  = false
	self.height = false
end

function CodeTileGrid:setSize( w, h, tw, th, ox, oy, cw, ch )
	self.grid:setSize( w, h, tw, th, ox, oy, cw, ch  )
	self.width = w
	self.height = h	
end

function CodeTileGrid:resize( w, h, tw, th, ox, oy, cw, ch )
	resizeMOAIGrid( self.grid, w, h, tw, th, ox, oy, cw, ch )
	self.width  = w
	self.height = h
end

function CodeTileGrid:getTile( x, y ) -- name
	local id = self.grid:getTile( x, y )
	return self.idToName[ id ]
end

function CodeTileGrid:setTile( x, y, name )
	local id = name and self.nameToId[ name ] or 0
	return self.grid:setTile( x, y, id )
end

function CodeTileGrid:fill( name )
	local id = self.nameToId[ name ] or 0
	self.grid:fill( id )
end

function CodeTileGrid:setTileset( tileset )
	self.tileset = tileset
	self.nameToId = self.tileset.nameToId
	self.idToName = self.tileset.idToName	
end

function CodeTileGrid:tileIdToGridId( tileId )
	return self.nameToId[ tileId ] or false
end

function CodeTileGrid:getMoaiGrid()
	return self.grid
end

function CodeTileGrid:loadTiles( data )
	-- assert( self.tileset )
	if not self.tileset then return end
	local nameToId = data[ 'nameToId' ]
	local nameToId2 = self.nameToId
	local w, h = data[ 'width' ], data[ 'height' ]
	if w ~= self.width or h ~= self.height then
		_warn( 'tilemap size mismatch' )
		-- return false
		w = self.width
		h = self.height
	end

	loadMOAIGridTiles( self.grid, data['tiles'] )
	
	--check if match
	local notMatch = false
	for k, id in pairs( nameToId ) do
		if nameToId2[ k ] ~= id then notMatch = true break end
	end

	--conversion
	if notMatch then
		local conversionTable = {}
		conversionTable[0] = 0
		for k, id1 in pairs( nameToId ) do
			local id2 = nameToId2[ k ] or 0
			if id2 == 0 then _warn( 'symbol not found in tileset' ) end
			conversionTable[ id1 ] = id2
		end
		local grid = self.grid
		for y = 1, h do
			for x = 1, w do
				local id0 = grid:getTile( x, y )
				local id1 = conversionTable[ id0 ]
				if not id1 then
					_warn( 'cannot find tile conversion', id0 )
					id1 = 0
				end
				grid:setTile( x, y, id1 )
			end
		end
	end
	self.loaded = true
end

function CodeTileGrid:saveTiles()
	-- assert( self.tileset )
	if not self.tileset then return false end

	local encoded = saveMOAIGridTiles( self.grid )

	local output = {}
	output[ 'nameToId' ] = self.nameToId
	output[ 'width'    ] = self.width
	output[ 'height'   ] = self.height
	output[ 'tiles'    ] = encoded

	return output
end


--------------------------------------------------------------------
CLASS: CodeTileMapLayer ( TileMapLayer )
	:MODEL{}

function CodeTileMapLayer:__init()
	self.visible = true
end

function CodeTileMapLayer:onInit( initFromEditor )
	local tileset = self.tileset
	if initFromEditor then
		self.subdivision = tileset.defaultTileData.subdivision
	end

	self.mapGrid = CodeTileGrid()
	self.mapGrid:setTileset( tileset )
	
	local w, h   = self:getSize()
	local tw, th = self:getTileSize()
	self.mapGrid:setSize( w, h, tw, th, 0, 0, tw, th )
	
	self.debugDrawProp = MOAIProp.new()
	setPropBlend( self.debugDrawProp, 'alpha' )
	-- local deck = tileset:getDebugDrawDeck()
	local deck = tileset:buildDebugDrawDeck()
	deck:setRect( 0,0, tw, th )
	self.debugDrawProp:setDeck( deck )
	self.debugDrawProp:setGrid( self.mapGrid:getMoaiGrid() )


end

function CodeTileMapLayer:onResize( w, h )
	local w, h = self:getSize()
	local tw, th = self:getTileSize()
	self.mapGrid:resize( w, h, tw, th, 0,0, tw,th )
end

function CodeTileMapLayer:setVisible( vis )
	self.visible = vis
end

function CodeTileMapLayer:isVisible()
	return self.visible
end

function CodeTileMapLayer:getGrid()
	return self.mapGrid
end

function CodeTileMapLayer:getMoaiGrid()
	return self:getGrid():getMoaiGrid()
end

function CodeTileMapLayer:getType()
	return 'code_tile_layer'
end

function CodeTileMapLayer:getTile( x,y )
	return self.mapGrid:getTile( x, y )
end

function CodeTileMapLayer:getTileData( x, y )
	local name = self.mapGrid:getTile( x, y )
	local data = self.tileset and self.tileset:getTileDataByName( name )	
	return data
end

function CodeTileMapLayer:setTile( x, y, name )
	return self.mapGrid:setTile( x, y, name )
end

function CodeTileMapLayer:removeTile( x, y )
	self.mapGrid:setTile( x, y, false )
end

function CodeTileMapLayer:fill( name )
	return self.mapGrid:fill( name )
end

function CodeTileMapLayer:onParentAttach( ent )
end

function CodeTileMapLayer:onParentDetach( ent )
end

function CodeTileMapLayer:getDebugDrawProp()
	return self.debugDrawProp
end

function CodeTileMapLayer:onSubDivisionChange( div )
	self:onResize()
	-- local tw, th = self:getTileSize()
	-- self.mapGrid:resize( w, h, tw, th, 0, 0, 1, 1 )
	-- subdivideMOAIGrid()
end

function CodeTileMapLayer:getSize()
	local div = self.subdivision or 1
	local w, h = self.parentMap:getSize()
	return w*div, h*div
end

function CodeTileMapLayer:getTileSize()
	local div = self.subdivision or 1
	local tw, th = self.parentMap:getTileSize()
	return tw/div, th/div
end
