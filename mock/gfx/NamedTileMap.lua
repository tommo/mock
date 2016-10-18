module 'mock'

--------------------------------------------------------------------
CLASS: NamedTileGrid ( TileMapGrid )
	:MODEL{}

function NamedTileGrid:__init( grid )
	self.nameToId = {}
	self.idToName = {}
	self.tileset = false
	self.grid = grid or MOAIGrid.new()
	self.loaded = false
	self.width  = false
	self.height = false
end

function NamedTileGrid:setSize( w, h, tw, th, ox, oy, cw, ch )
	self.grid:setSize( w, h, tw, th, ox, oy, cw, ch  )
	self.width = w
	self.height = h	
end

function NamedTileGrid:resize( w, h, tw, th, ox, oy, cw, ch )
	resizeMOAIGrid( self.grid, w, h, tw, th, ox, oy, cw, ch )
	self.width  = w
	self.height = h
end

function NamedTileGrid:getTile( x, y ) -- name
	local id = self.grid:getTile( x, y )
	return self.idToName[ id ]
end

function NamedTileGrid:setTile( x, y, name )
	local id = name and self.nameToId[ name ] or 0
	return self.grid:setTile( x, y, id )
end

function NamedTileGrid:findTile( id, x0,y0, x1,y1 )
	local id = name and self.nameToId[ name ] or 0
	local w, h = self.width, self.height
	local grid = self.grid
	for y = y0 or 1, y1 or h do
	for x = x0 or 1, x1 or w do
		local v = grid:getTile( x, y )
		if v == id then
			return x, y
		end
	end
	end
	return nil
end

function NamedTileGrid:fill( name )
	local id = self.nameToId[ name ] or 0
	self.grid:fill( id )
end

function NamedTileGrid:setTileset( tileset )
	self.tileset = tileset
	self.nameToId = self.tileset.nameToId
	self.idToName = self.tileset.idToName
end

function NamedTileGrid:tileIdToGridId( tileId )
	return self.nameToId[ tileId ] or false
end

function NamedTileGrid:gridIdToTileId( gridId )
	return self.idToName[ gridId ] or false
end

function NamedTileGrid:getMoaiGrid()
	return self.grid
end

function NamedTileGrid:loadTiles( data )
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

function NamedTileGrid:saveTiles()
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
CLASS: NamedTileMapLayer ( TileMapLayer )
	:MODEL{}

function NamedTileMapLayer:__init()	
end

function NamedTileMapLayer:onInit()
	local tileset = self.tileset
	self.mapGrid = NamedTileGrid()
	self.mapGrid:setTileset( tileset )
	
	local w, h   = self:getSize()
	local tw, th = self:getTileSize()
	self.mapGrid:setSize( w, h, tw, th, 0, 0, 1, 1 )

	self.prop = MOAIProp.new()
	self.prop:setGrid( self.mapGrid:getMoaiGrid() )
	self.prop:setDeck( tileset:getMoaiDeck() )

end

function NamedTileMapLayer:onResize( w, h )
	local tw, th = self:getTileSize()
	self.mapGrid:resize( w, h, tw, th, 0, 0, 1, 1 )
end

function NamedTileMapLayer:worldToModel( x, y )
	return self.prop:worldToModel( x, y )
end


function NamedTileMapLayer:setBlend( b )
	setPropBlend( self.prop, b )
end

function NamedTileMapLayer:setShader( shaderPath )
	if shaderPath then
		local shader = mock.loadAsset( shaderPath )
		if shader then
			local moaiShader = shader:getMoaiShader()
			return self.prop:setShader( moaiShader )
		end
	end
	self.prop:setShader( defaultShader )
end

function NamedTileMapLayer:setVisible( f )
	self.prop:setVisible( f )
end

function NamedTileMapLayer:isVisible()
	return self.prop:getAttr( MOAIProp.ATTR_VISIBLE ) ~= 0
end

function NamedTileMapLayer:getGrid()
	return self.mapGrid
end

function NamedTileMapLayer:getMoaiGrid()
	return self:getGrid():getMoaiGrid()
end

function NamedTileMapLayer:getType()
	return 'named_layer'
end

function NamedTileMapLayer:getTile( x,y )
	return self.mapGrid:getTile( x, y )
end

function NamedTileMapLayer:getTileData( x, y )
	local name = self.mapGrid:getTile( x, y )
	local data = self.tileset and self.tileset:getTileDataByName( name )	
	return data
end

function NamedTileMapLayer:setTile( x, y, name )
	return self.mapGrid:setTile( x, y, name )
end

function NamedTileMapLayer:removeTile( x, y )
	self.mapGrid:setTile( x, y, false )
end

function NamedTileMapLayer:fill( name )
	return self.mapGrid:fill( name )
end

function NamedTileMapLayer:onParentAttach( ent )
	ent:_attachProp( self.prop, 'render' )
end

function NamedTileMapLayer:onParentDetach( ent )
	ent:_detachProp( self.prop )
end

function NamedTileMapLayer:getTerrain( x, y )
	local data = self:getTileData( x, y )
	return data and data.terrain or false
end

function NamedTileMapLayer:applyMaterial( material )
	material:applyToMoaiProp( self.prop )
end

function NamedTileMapLayer:onSetVisible( vis )
	self.prop:setVisible( vis )
end

function NamedTileMapLayer:onSetOffset( x, y, z )
	if self.prop then
		self.prop:setLoc( x, y, z )
	end
end
