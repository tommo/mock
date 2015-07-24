module 'mock'

local DefaultCodeTileData = {
	shape = 'rect_filled',
	subdivision = 1
}

--------------------------------------------------------------------
CLASS: CodeTileset ( Tileset )
	:MODEL{}

function CodeTileset:__init()
	self.tileCount = 0
	self.nameToTile = {}
	self.idToTile   = {}
	self.nameToId   = {}
	self.idToName   = {}

	self.debugDeck  = MOAIScriptDeck.new()
	self.debugDeck:setDrawCallback( 
		function( idx, xOff, yOff, xScl, yScl )
			return self:onDebugDraw( idx, xOff, yOff, xScl, yScl )
		end
		)
end

function CodeTileset:loadData( data )
	self.defaultTileData = data[ 'default' ] or DefaultCodeTileData
	local tiles = data[ 'tiles' ] or {}
	local id = 1
	local nameToTile = self.nameToTile
	local idToTile   = self.idToTile
	local nameToId   = self.nameToId
	local idToName   = self.idToName
	for key, tileData in pairs( tiles ) do
		id = id + 1
		local tile = { name = key, id = id, data = tileData}
		if nameToTile[ key ] then
			_warn( 'duplicated code tile', key )
		else
			nameToTile[ key ] = tile
			idToTile  [ id  ] = tile
			nameToId  [ key ] = id
			idToName  [ id  ] = key
			self:buildDebugDraw( tile )
		end
	end
	return true
end

function CodeTileset:getTileCount()
	return self.tileCount
end

function CodeTileset:getTileDimension()
	return false
end

function CodeTileset:getNameById( id )
	return self.idToName[ id ]
end

function CodeTileset:getIdByName( name )
	return self.nameToId[ name ]
end

function CodeTileset:getTileDataByName( name )
	return self.nameToTile[ name ]
end

function CodeTileset:getTileDataByIndex( idx )
	return self.idToTile[ idx ]
end

function CodeTileset:getTileData( id ) --id is name for CodeTileset, not index
	return self.nameToTile[ id ]
end

local setPenColor   = MOAIGfxDevice.setPenColor
local drawRect      = MOAIGfxDevice.drawRect
local fillRect      = MOAIGfxDevice.fillRect
local drawCircle    = MOAIGfxDevice.drawCircle
local fillCircle    = MOAIGfxDevice.fillCircle

function CodeTileset:buildDebugDraw( tile )
	local debugDraw
	local shape = tile.data.shape
	local color = tile.data.color or '#8cff00'
	local r,g,b = hexcolor( color )
	if shape == 'rect' then
		debugDraw = function( idx, xOff, yOff, xScl, yScl )
			setPenColor( r,g,b )
			drawRect( 0, 0, xScl, yScl )
		end
	elseif shape == 'rect_filled' then
		debugDraw = function( idx, xOff, yOff, xScl, yScl )
			setPenColor( r,g,b )
			fillRect( 0, 0, xScl, yScl )
		end
	elseif shape == 'circle' then
		debugDraw = function( idx, xOff, yOff, xScl, yScl )
			setPenColor( r,g,b )
			drawCircle( 0, 0, xScl, yScl )
		end
	elseif shape == 'circle_filled' then
		debugDraw = function( idx, xOff, yOff, xScl, yScl )
			setPenColor( r,g,b )
			drawCircle( 0, 0, xScl, yScl )
		end
	else
		debugDraw = function( idx, xOff, yOff, xScl, yScl )
			setPenColor( r,g,b )
			drawRect( 0, 0, xScl, yScl )
		end
	end
	tile.debugDraw = debugDraw
end

function CodeTileset:onDebugDraw( idx, xOff, yOff, xScl, yScl )
	local tile = self.idToTile[ idx ]
	return tile.debugDraw( idx, xOff, yOff, xScl, yScl )
end

function CodeTileset:getDebugDrawDeck()
	return self.debugDeck
end

--------------------------------------------------------------------
function CodeTilesetLoader( node )
	local tileset = CodeTileset()
	local dataPath = node:getObjectFile( 'data' )
	local data = loadAssetDataTable( dataPath )
	tileset:loadData( data )
	return tileset
end

registerAssetLoader ( 'code_tileset',         CodeTilesetLoader )
