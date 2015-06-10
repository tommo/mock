module 'mock'

local function bit(p)
  return 2 ^ p  -- 1-based indexing
end

-- Typical call:  if hasbit(x, bit(3)) then ...
local function hasbit(x, p)
  return x % (p + p) >= p       
end

local function setbit(x, p)
  return hasbit(x, p) and x or x + p
end

local function clearbit(x, p)
  return hasbit(x, p) and x - p or x
end
--------------------------------------------------------------------
local squareValueToPattern = {
	[ 1 ] = 'sw',
	[ 2 ] = 'se',
	[ 4 ] = 'nw',
	[ 8 ] = 'ne',
	[ 1 + 2 ] = 's',
	[ 4 + 8 ] = 'n',
	[ 1 + 4 ] = 'w',
	[ 2 + 8 ] = 'e',
	[ 1 + 8 ] = 'ew',
	[ 2 + 4 ] = 'we',
	[ 1 + 2 + 4 ] = '-ne',
	[ 2 + 1 + 8 ] = '-nw',
	[ 4 + 1 + 8 ] = '-se',
	[ 8 + 2 + 4 ] = '-sw',
	[ 8 + 2 + 4 + 1 ] = 'c',
}

local patternToSquareValue = {}
for k,v in pairs( squareValueToPattern ) do
	patternToSquareValue[ v ] = k
end

--------------------------------------------------------------------
CLASS: NamedTileMapTerrainBrush ( TileMapTerrainBrush )
	:MODEL{}


function NamedTileMapTerrainBrush:__init()
	self.prefix = 'unknown'
end

function NamedTileMapTerrainBrush:paint( layer, tx, ty )
	self:updateNeighbors( layer, tx, ty )
end

function NamedTileMapTerrainBrush:remove( layer, tx, ty )
	self:updateNeighbors( layer, tx, ty )
end

function NamedTileMapTerrainBrush:updateNeighbors( layer, x, y  )
	self:updateTile( layer, x, y, 0, 0 )
	self:updateTile( layer, x, y, 1, 0 )
	self:updateTile( layer, x, y, 1, 1 )
	self:updateTile( layer, x, y, 0, 1 )
end

function NamedTileMapTerrainBrush:updateTile( layer, x0, y0, dx, dy )
	local w, h = layer:getSize()
	local x, y = x0 + dx, y0 + dy
	if x < 1 or x > w then return false end
	if y < 1 or y > h then return false end
	local sq = self:getSquareValue( layer, x, y, dx, dy )
	local p = squareValueToPattern[ sq ] or false
	if p then
		layer:setTile( x, y, self.prefix..'.'..p )
	else
		layer:setTile( x, y, self.prefix..'.c' )
	end
end

function NamedTileMapTerrainBrush:isSolid( layer, x, y )	
	local w, h = layer:getSize()
	if x < 1 or x > w then return true end
	if y < 1 or y > h then return true end
	local c = layer:getCodeTile( x, y )
	return c == 1
end

function NamedTileMapTerrainBrush:getSquareValue( layer, x, y, dx, dy )
	local tileData = layer:getTileData( x, y )
	local sq0 = 0
	if tileData and tileData.prefix==self.prefix then
		local pattern = tileData.tileIdBaseHead
		sq0 = patternToSquareValue[ pattern ]
	end
	-- [ 1 ] = 'sw'  bit 0,
	-- [ 2 ] = 'se'  bit 1,
	-- [ 4 ] = 'nw'  bit 2,
	-- [ 8 ] = 'ne'  bit 3,
	local sq = sq0
	if     dx == 0 and dy == 0 then -- +sw
		sq = setbit( sq0, bit(0) )
	elseif dx == 1 and dy == 0 then -- +se
		sq = setbit( sq0, bit(1) )
	elseif dx == 1 and dy == 1 then -- +ne
		sq = setbit( sq0, bit(3) )
	elseif dx == 0 and dy == 1 then -- +nw
		sq = setbit( sq0, bit(2) )
	end
	return sq
end



--------------------------------------------------------------------
CLASS: NamedTileset ( Tileset )
	:MODEL{}

function NamedTileset:__init()
	self.nameToTile = {}
	self.nameToId = {}
	self.idToName = {}
	self.terrainBrushes = {}
	self.tileWidth = 0
	self.tileHeight = 0
	self.tileCount  = 0
end

function NamedTileset:getTerrainBrushes()
	return self.terrainBrushes
end

function NamedTileset:getTileSize()
	return self.tileWidth, self.tileHeight
end

function NamedTileset:createMoaiDeck()
	local deck = MOAIGfxQuadDeck2D.new()
	return deck
end

function NamedTileset:buildTerrainBrush( tileGroup )
	local brush = NamedTileMapTerrainBrush()
	brush.prefix = tileGroup.name
	brush.name = tileGroup.name
	table.insert( self.terrainBrushes, brush )
	return brush
end

local function extractTileIdBase( id )
	local base = string.match( id, '.*%.(.*)')
	if not base then return nil end
	local head, tail = string.match( base, '(-?%a+)(.*)' )
	return head, tail
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
		if groupData[ 'type' ] == 'T' then
			self:buildTerrainBrush( group )
		end
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
			local data2 = table.simplecopy( tileData )
			data2.group  = group
			data2.prefix = group.name
			local head, tail = string.match( baseName, '(-?%a+)(.*)' )
			data2.tileIdBaseHead = head or ''
			data2.tileIdBaseTail = tail or ''
			self.nameToTile[ itemName ] = data2
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

function NamedTileset:getTileData( id )
	return self.nameToTile[ id ]
end

function NamedTileset:getRawRect( id )
	local tileData = self.nameToTile( id )
	if tileData then return unpack( tileData['raw_rect'] ) end
	return nil
end

function NamedTileset:getNamedTileMapTerrainBrushes()
	return self.terrainBrushes
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
