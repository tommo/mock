module 'mock'

--generic tilemap
--------------------------------------------------------------------
CLASS: TileMapGrid ()
	:MODEL{}

function TileMapGrid:__init()
	self.grid = MOAIGrid.new()
	self.tileset = false
end

function TileMapGrid:getMoaiGrid()
	return self.grid
end

function TileMapGrid:setSize( w, h, tw, th, ox, oy, cw, ch )
	self.grid:setSize( w, h, tw, th, ox, oy, cw, ch  )
	self.width = w
	self.height = h	
end

function TileMapGrid:getTile( x, y ) -- name
	return self.grid:getTile( x, y )
end

function TileMapGrid:setTile( x, y, id )
	return self.grid:setTile( x, y, id or 0 )
end

function TileMapGrid:fill( id )
	self.grid:fill( id )
end

function TileMapGrid:setTileset( tileset )
	self.tileset = tileset
end

function TileMapGrid:loadTiles( data )
	loadMOAIGridTiles( self.grid, data['tiles'] )
	self.loaded = true
end

function TileMapGrid:saveTiles()
	local data = {}
	data[ 'tiles' ] = saveMOAIGridTiles( self.grid )
	return data
end




--------------------------------------------------------------------
CLASS: TileMapLayer ()
	:MODEL{
		Field 'name'    :string();
		Field 'tag'     :string();
		Field 'tileset' :asset( 'tileset' )
	}

function TileMapLayer:__init()
	self.name      = 'layer'
	self.tag       = ''
	self.tileset   = false
	self.parentMap = false
	self.mapGrid   = false
	self.visible   = true
end

function TileMapLayer:getName()
	return self.name
end

function TileMapLayer:setName( name )
	self.name = name
end

function TileMapLayer:getMap()
	return self.parentMap
end

function TileMapLayer:getGrid()
	return self.mapGrid
end

function TileMapLayer:setSize( ... )
	self.mapGrid:setSize( ... )
end

function TileMapLayer:getGrid()
	return self.mapGrid
end

function TileMapLayer:saveData()
	local data = {}
	data['tiles'] = self.mapGrid:saveTiles()
	return data
end

function TileMapLayer:loadTiles( data )
	local tilesData = data['tiles']
	return self.mapGrid:loadTiles( tilesData )
end

function TileMapLayer:setTileset( tileset )
	self.tileset   = tileset
	self.mapGrid:setTileset( tileset )
end

function TileMapLayer:getTile( x,y )
	return self.mapGrid:getTile( x, y )
end

function TileMapLayer:setTile( x, y, id )
	return self.mapGrid:setTile( x, y, id )
end

function TileMapLayer:fill( id )
	return self.mapGrid:fill( id )
end

function TileMapLayer:onParentAttach( ent )
end

function TileMapLayer:onParentDetach( ent )
end

function TileMapLayer:setVisible( vis )
	self.visible = vis
end



----------------------------------------------------------------------
CLASS: TileMapParam ()
:MODEL {
	Field 'defaultTileset' :asset('tileset;named_tileset'); -- :onset( 'updateTileSizeFromTileset' );
	Field 'width'          :int() :range(1);
	Field 'height'         :int() :range(1);
	Field 'tileWidth'      :int() :range(1);
	Field 'tileHeight'     :int() :range(1);
}

-- function TileMapParam:updateTileSizeFromTileset()
-- 	local tilesetPath = self.defaultTileset
-- 	local set = loadAsset( tilesetPath )
-- 	if not set then return end
-- 	local tw, th = set:getTileSize()
-- 	self.tileWidth  = tw 
-- 	self.tileHeight = th	
-- end

--------------------------------------------------------------------
CLASS: TileMap ()
	:MODEL{
		Field 'serializedData' :string() :no_edit() :set( 'setSerializedData' );
		'----';
		Field 'defaultTileset' :asset( 'tileset' ) :readonly();
		Field 'size'     :type( 'vec2' ) :getset( 'Size' ) :readonly() :meta{ decimals = 0 };
		Field 'tileSize' :type( 'vec2' ) :getset( 'TileSize' ) :readonly() :meta{ decimals = 0 };
		'----';
		Field 'init'     :action( 'toolActionInit' );
		Field 'resize'   :action( 'toolActionResize' );

}

--TODO: API
function TileMap:__init()
	self.layers = {}
	self.serializedData = false
	self.width      = 1
	self.height     = 1
	self.tileWidth  = 1
	self.tileHeight = 1
	self.defaultTileset = false
end

function TileMap:getSize()
	return self.width, self.height
end

function TileMap:getTileSize()
	return self.tileWidth, self.tileHeight
end

function TileMap:setSize( w, h )
	self.width, self.height = w, h
end

function TileMap:setTileSize( w, h )
	self.tileWidth, self.tileHeight = w, h
end

function TileMap:onAttach( ent )
	for i, layer in ipairs( self.layers ) do
		layer:onParentAttach( ent )
	end
end

function TileMap:onDetach( ent )
	for i, layer in ipairs( self.layers ) do
		layer:onParentDetach( ent )
	end
end

function TileMap:getLayers()
	return self.layers
end

function TileMap:addLayer( l )
	table.insert( self.layers, l )
	l.parentMap = self
	if self._entity then
		l:onParentAttach( self._entity )
	end
	return true
end

function TileMap:removeLayer( l )
	for i, layer in ipairs( self.layers ) do
		if layer == l then
			if self._entity then
				layer:onParentDetach( self._entity )
			end
			table.remove( self.layers, i )
			return true
		end
	end
	return false
end

function TileMap:saveData()
	local data = {}
	local layerDatas = {}
	for i, layer in ipairs( self.layers ) do
		local layerData = layer:saveData()
		layerDatas[ i ] = layerData
	end
	data[ 'layers' ]   = layerDatas
	data[ 'size' ]     = { self:getSize() }
	data[ 'tileSize' ] = { self:getTileSize() }
	return data
end

function TileMap:loadData( data )
	local layerDatas = data['layers']
	local size = data['size']
	local tileSize = data['tileSize']

end

function TileMap:setSerializedData( data )
	self.pendingTileData = data
	if self.scene then
		self:loadPendingTileData()
	end
end

function TileMap:getSerializedData()
	local data = self:saveData()
	return data
end

function TileMap:loadPendingTileData()
	if not self.pendingTileData then return end
	if self.pendingTileData.groundTiles then
		self.groundMap:loadTiles( self.pendingTileData.groundTiles )
	end
end

function TileMap:init( param )
	self.tileWidth  = param.tileWidth
	self.tileHeight = param.tileHeight
	self.width      = param.width
	self.height     = param.height
	self.defaultTileset = param.defaultTileset
	--create a default layer
	local layer = TileMapLayer()
	self:addLayer( layer )
end

function TileMap:getDefaultParam()
	local param = TileMapParam()
	param.width      = 20
	param.height     = 20
	param.tileWidth  = 40
	param.tileHeight = 30
	param.defaultTileset = self.defaultTileset
	return param
end

function TileMap:toolActionInit()
	local param = self:getDefaultParam()
	if mock_edit.requestProperty( 'input tilemap parameters', param ) then
		self:init( param )
		mock_edit.alertMessage( 'message', 'tilemap is initialized', 'info' )
	end
end

function TileMap:toolActionResize()
		mock_edit.alertMessage( 'message', 'TODO*', 'info' )
end


registerComponent( 'TileMap', TileMap )
registerEntityWithComponent( 'TileMap', TileMap )
