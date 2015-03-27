module 'mock'

--------------------------------------------------------------------
CLASS: NamedTileGrid ()
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
	self.width = width
	self.height = height	
end


function NamedTileGrid:getTile( x, y ) -- name
	local id = self.gird:getTile( x, y )
	return self.idToName[ id ]
end

function NamedTileGrid:setTile( x, y, name )
	local id = self.nameToId[ name ] or 0
	return self.grid:setTile( x, y, id )
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

function NamedTileGrid:getMoaiGrid()
	return self.grid
end

function NamedTileGrid:loadTiles( data )
	assert( self.tileset )
	local nameToId = data[ 'nameToId' ]
	local nameToId2 = self.nameToId
	local w, h = data[ 'width' ], data[ 'height' ]
	if w ~= self.width or h ~= self.height then
		_warn( 'tilemap size mismatch' )
		return false
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
		for k, id1 in pairs( nameToId ) do
			local id2 = nameToId2[ k ] or 0
			if id2 == 0 then _warn( 'symbol not found in tileset' ) end
			conversionTable[ id1 ] = id2
		end
		local grid = self.grid
		for y = 1, h do
			for x = 1, w do
				grid:setTile( x, y, conversionTable[ grid:getTile( x, y ) ] )
			end
		end
	end
	self.loaded = true
end

function NamedTileGrid:saveTiles()
	assert( self.tileset )
	
	local encoded = saveMOAIGridTiles( self.grid )

	local output = {}
	output[ 'nameToId' ] = self.nameToId
	output[ 'width'    ] = self.width
	output[ 'height'   ] = self.height
	output[ 'tiles'    ] = encoded

	return output
end

--------------------------------------------------------------------
CLASS: NamedTileMap ( mock.RenderComponent )
	:MODEL{}

function NamedTileMap:__init( grid )
	self.prop = MOAIProp.new()
	self.grid = NamedTileGrid( grid )
	self.prop:setGrid( self.grid:getMoaiGrid() )
end

function NamedTileMap:setSize( ... )
	self.grid:setSize( ... )
end

function NamedTileMap:onAttach( ent )
	ent:_attachProp( self.prop )
end

function NamedTileMap:onDetach( ent )
	ent:_detachProp( self.prop )
end

function NamedTileMap:getGrid()
	return self.grid
end

function NamedTileMap:saveTiles()
	return self.grid:saveTiles()
end

function NamedTileMap:loadTiles( data )
	return self.grid:loadTiles( data )
end

function NamedTileMap:setTileset( tileset )
	self.tileset   = tileset
	self.grid:setTileset( tileset )
	self.prop:setDeck( tileset:getMoaiDeck() )
end

function NamedTileMap:getTile( x,y )
	return self.grid:getTile( x, y )
end

function NamedTileMap:setTile( x, y, name )
	return self.grid:setTile( x, y, name )
end

function NamedTileMap:fill( name )
	return self.grid:fill( name )
end

mock.registerComponent( 'NamedTileMap', NamedTileMap )



--------------------------------------------------------------------
CLASS: NamedTileGroup ()

function NamedTileGroup:__init()
	self.nameToId = {}
	self.idToName = {}
	self.tileType = 'C'
end


--------------------------------------------------------------------
CLASS: NamedTileset ( Deck2D )
	:MODEL{}

function NamedTileset:__init()
	self.nameToTile = {}
	self.nameToId = {}
	self.idToName = {}
	self.tileWidth = 0
	self.tileHeight = 0
end

function NamedTileset:getTileSize()
	return self.tileWidth, self.tileHeight
end

function NamedTileset:createMoaiDeck()
	local deck = MOAIGfxQuadDeck2D.new()
	return deck
end

function NamedTileset:load( data, texture )
	self.name = data['name']
	self.rawName = data['raw_name']
	self.nameToId = {}
	self.idToName = {}
	self.groups = {}
	self.tileWidth, self.tileHeight = unpack( data['size'] )

	local count = 0
	for i, groupData in pairs( data[ 'groups' ] ) do
		local name = groupData[ 'name' ]
		group = NamedTileGroup()
		group.tileType = groupData[ 'type' ]
		group.alt      = groupData[ 'alt'  ]
		group.name     = groupData[ 'name' ]
		self.groups[ name ] = group
		for _, tileData in pairs( groupData[ 'tiles' ] ) do
			local itemName = tileData[ 'name' ]
			local baseName = tileData[ 'basename' ]
			count = count + 1
			local index = count
			tileData.index = index
			group.nameToId[ baseName ] = index
			group.idToName[ index ] = baseName
			self.nameToId[ itemName ] = index
			self.idToName[ index ] = itemName
			self.nameToTile[ itemName ] = tileData
		end
	end
	
	local deck = self:getMoaiDeck()
	deck:reserve( count )
	deck:setTexture( texture )
	local texW, texH = texture:getSize()
	for k, tile in pairs( self.nameToTile ) do
		local i = tile.index
		local x,y,tw,th = unpack( tile['rect'] )
		local x0, y0, x1, y1 = unpack( tile[ 'deck_rect' ] )
		local u0,v0,u1,v1 = x / texW, y / texH, ( x + tw )/texW, ( y + th )/texH
		deck:setRect( i, x0, y0, x1, y1 )
		deck:setUVRect( i, u0, v1, u1, v0 )
	end
end


--------------------------------------------------------------------
CLASS: NamedTilesetPack()
function NamedTilesetPack:__init()
	self.tilesets = {}
end

function NamedTilesetPack:getTileset( name )
	return self.tilesets[ name ]
end

function NamedTilesetPack:load( json, texpath )
	local texture = MOAITexture.new()
	texture:load( texpath )
	local data = loadAssetDataTable( json )
	self.tilesets    = {}
	self.nameToTile = {}
	local count = 0
	local setNameToId = {}
	local setIdToName = {}
	for k, tilesetData in pairs( data[ 'themes' ] ) do
		local tileset = NamedTileset()
		tileset:load( tilesetData, texture )
		self.tilesets[ tilesetData[ 'name' ] ] = tileset
	end
end

