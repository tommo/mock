module 'mock'


--------------------------------------------------------------------
CLASS: NamedTileset ( Deck2D )
	:MODEL{}

function NamedTileset:__init()
	self.nameToTile = {}
	self.nameToId = {}
	self.idToName = {}
	self.tileWidth = 0
	self.tileHeight = 0
	self.tileCount  = 0
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
	self.tileCount = count
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

function NamedTileset:getTileCount()
	return self.tileCount
end

function NamedTileset:getTileDimension()
	return false
end

function NamedTileset:buildPreviewGrid()
	local grid = MOAIGrid.new()
	local count = self:getTileCount()
	local cols = 6
	local rows = math.ceil( count/cols )
	local tw, th = self:getTileSize()
	grid:setSize( cols, rows, tw, th + 100, 0,0, 1,1 )
	for i = 1, count do
		local x, y = grid:cellAddrToCoord( i )
		grid:setTile( x, y, i )
	end
	return grid
end

function NamedTileset:getNameById( id )
	return self.idToName[ id ]
end

function NamedTileset:getIdByName( name )
	return self.nameToId[ name ]
end

function NamedTileset:getTileDataByName( name )
	return self.nameToTile[ name ]
end

function NamedTileset:getRawRect( id )
	local tileData = self.nameToTile( id )
	if tileData then return unpack( tileData['raw_rect'] ) end
	return nil
end

--------------------------------------------------------------------
CLASS: NamedTileGroup ()

function NamedTileGroup:__init()
	self.nameToId = {}
	self.idToName = {}
	self.tileType = 'C'
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


--------------------------------------------------------------------
function NamedTilesetLoader( node )
	local pack = loadAsset( node.parent )
	local name = node:getName()	
	local item = pack:getTileset( name )
	return item
end

function NamedTilesetPackLoader( node )
	local atlasFile = node:getObjectFile( 'atlas' )
	local defFile = node:getObjectFile( 'def' )
	-- local defData = loadAssetDataTable( defFile )
	local pack = NamedTilesetPack()
	pack:load( defFile, atlasFile )
	return pack
end

registerAssetLoader ( 'named_tileset',         NamedTilesetLoader )
registerAssetLoader ( 'named_tileset_pack',    NamedTilesetPackLoader )
