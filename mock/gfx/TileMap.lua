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

function TileMapGrid:locToCoord( x, y )
	return self.grid:locToCoord( x, y )
end

function TileMapGrid:coordToLoc( x, y )
	return self.grid:coordToLoc( x, y )
end

function TileMapGrid:isValidCoord( x, y )
	if x < 1 then return false end
	if y < 1 then return false end
	local w, h = self.grid:getSize()
	if x > w then return false end
	if y > h then return false end
	return true
end

function TileMapGrid:setSize( w, h, tw, th, ox, oy, cw, ch )
	self.grid:setSize( w, h, tw, th, ox, oy, cw, ch  )
	self.width = w
	self.height = h	
end

function TileMapGrid:getTile( x, y ) -- name
	return self.grid:getTile( x, y )
end

function TileMapGrid:getTileRaw( x, y )
	return self.grid:getTile( x, y )
end

function TileMapGrid:setTile( x, y, id )
	return self.grid:setTile( x, y, id or 0 )
end

function TileMapGrid:setTileRaw( x, y, raw )
	return self.grid:setTile( x, y, raw or 0 )
end

function TileMapGrid:setTileFlags( x, y, flags )
	return self.grid:setTileFlags( x, y, flags )
end

function TileMapGrid:clearTileFlags( x, y, flags )
	return self.grid:clearTileFlags( x, y, flags )
end

function TileMapGrid:getTileFlags( x, y )
	return self.grid:getTileFlags( x, y )
end

function TileMapGrid:findTile( id, x0, y0, x1, y1 )
	local w, h = self.width, self.height
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

function TileMapGrid:tileIdToGridId( tileId )
	return tileId
end

function TileMapGrid:gridIdToTileId( gridId )
	return tileId
end

--------------------------------------------------------------------
CLASS: TileMapLayer ()
	:MODEL{
		Field 'name'    :string();
		Field 'tag'     :string();
		Field 'tilesetPath' :asset_pre( 'deck2d.tileset' )  :readonly();
		-- Field 'visible' :boolean();
		Field 'subdivision' :int() :range( 1, 4 ) :readonly();
		Field 'material'    :asset_pre( 'material' ) :getset( 'Material' );
	}

function TileMapLayer:__init()
	self.name      = 'layer'
	self.tag       = ''
	self.parentMap = false
	self.mapGrid   = false
	self.visible   = true

	--for verifying purpose only
	self.width      = 1
	self.height     = 1
	self.tileWidth  = 1
	self.tileHeight = 1

	self.tilesetPath = false
	self.tileset = false

	self.order     = 0 --order
	self.subdivision = 1

	self.material = false
end

function TileMapLayer:init( parentMap, tilesetPath, initFromEditor )
	self.tilesetPath  = tilesetPath
	self.tileset      = loadAsset( tilesetPath )
	self:onInit( initFromEditor )
end

function TileMapLayer:getMaterial()
	return self.materialPath
end

function TileMapLayer:setMaterial( path )
	self.materialPath = path
	self:updateMaterial()
end

function TileMapLayer:getMaterialName()
	if not self.materialPath then 
		return 'N/A'
	else
		return basename( self.materialPath )
	end
end

function TileMapLayer:worldToModel( x, y )
	return self.parentMap._entity:worldToModel( x, y )
end

function TileMapLayer:onInit()
	self.mapGrid = TileMapGrid()
	self.mapGrid:setTileset( self.tileset )
	local w, h   = self:getSize()
	local tw, th = self:getTileSize()
	self.mapGrid:setSize( w, h, tw, th )
end

function TileMapLayer:resize( w, h )
	self:onResize( w, h )
end

function TileMapLayer:setSubDivision( div )
	local div0 = self.subdivision
	self.subdivision = div
	self:onSubDivisionChange( div, div0 )
end

function TileMapLayer:getSubDivision()
	return self.subdivision
end

function TileMapLayer:onSubDivisionChange( div, div0 )
end

function TileMapLayer:onResize( w, h )
end

function TileMapLayer:getName()
	return self.name
end

function TileMapLayer:setName( name )
	self.name = name
end

function TileMapLayer:getType()
	return 'layer'
end

function TileMapLayer:getTilesetPath()
	return self.tilesetPath
end

function TileMapLayer:getTileset()
	return self.tileset
end

function TileMapLayer:getMap()
	return self.parentMap
end

function TileMapLayer:getGrid()
	return self.mapGrid
end

function TileMapLayer:getMoaiGrid()
	return self:getGrid():getMoaiGrid()
end

function TileMapLayer:getSize()
	return self.parentMap:getSize()
end

function TileMapLayer:getTileSize()
	return self.parentMap:getTileSize()
end

function TileMapLayer:getCellSize()
	return self:getTileSize()
end

function TileMapLayer:getDebugDrawProp()
	return false
end

function TileMapLayer:tileIdToGridId( tileId )
	return self.mapGrid:tileIdToGridId( tileId )
end

function TileMapLayer:loadData( data, parentMap )
	local tilesetPath = data[ 'tileset' ]
	self.subdivision = data[ 'subdivision' ] or 1
	self.name = data[ 'name' ]
	self.tag  = data[ 'tag'  ]
	self.materialPath = data[ 'material' ] or false
	
	self:init( parentMap, tilesetPath )
	--TODO:verify size
	local width, height         = unpack( data['size'] )
	local tileWidth, tileHeight = unpack( data['tileSize'] )

	local w0, h0   = self:getSize()
	local tw0, th0 = self:getTileSize()

	assert( w0  == width )
	assert( h0  == height )
	assert( tw0 == tileWidth )
	assert( th0 == tileHeight )

	self:getGrid():loadTiles( data['tiles'] )
	self:onLoadData( data )
	self:updateMaterial()
end

function TileMapLayer:saveData()
	local data = {}
	data[ 'type'     ] = self:getType()
	data[ 'name'     ] = self.name
	data[ 'tag'      ] = self.tag
	data[ 'size'     ] = { self:getSize() }
	data[ 'tileSize' ] = { self:getTileSize() }
	data[ 'tiles'    ] = self:getGrid():saveTiles()
	data[ 'tileset'  ] = self:getTilesetPath()
	data[ 'order'    ] = self.order
	data[ 'subdivision' ] = self.subdivision
	data[ 'material' ] = self.materialPath
	self:onSaveData( data )
	return data
end

function TileMapLayer:setOrder( order )
	self.order = order
	self:onSetOrder( order )
end

function TileMapLayer:onSetOrder( order )
end

function TileMapLayer:onLoadData( data )
end

function TileMapLayer:onSaveData( data )
end

function TileMapLayer:getTile( x,y )
	return self.mapGrid:getTile( x, y )
end

function TileMapLayer:getTileRaw( x,y )
	return self.mapGrid:getTileRaw( x, y )
end

function TileMapLayer:getTileFlags( x,y )
	return self.mapGrid:getTileFlags( x, y )
end

function TileMapLayer:findTile( id, x0,y0, x1,y1 )
	return self.mapGrid:findTile( id, x0,y0, x1,y1 )
end

function TileMapLayer:getTerrain( x, y )
	return nil
end

function TileMapLayer:getTileData( x, y )
	local id = self.mapGrid:getTile( x, y )
	local tileset = self:getTileset()
	if not tileset then return nil end
	return tileset:getTileData( id )
end

function TileMapLayer:setTile( x, y, id )
	return self.mapGrid:setTile( x, y, id )
end

function TileMapLayer:setTileRaw( x, y, raw )
	return self.mapGrid:setTileRaw( x, y, raw )
end

function TileMapLayer:setTileFlags( x, y, flags )
	return self.mapGrid:setTileFlags( x, y, flags )
end

function TileMapLayer:clearTileFlags( x, y, flags )
	return self.mapGrid:clearTileFlags( x, y, flags )
end

function TileMapLayer:removeTile( x, y )
	self.mapGrid:setTile( x, y, 0 )
end

function TileMapLayer:fill( id )
	return self.mapGrid:fill( id )
end

function TileMapLayer:locToCoord( x, y )
	return self.mapGrid:locToCoord( x, y )
end

function TileMapLayer:coordToLoc( x, y )
	return self.mapGrid:coordToLoc( x, y )
end

function TileMapLayer:isValidCoord( x, y )
	return self.mapGrid:isValidCoord( x, y )
end

function TileMapLayer:getParentMap()
	return self.parentMap
end

function TileMapLayer:onParentAttach( ent )
end

function TileMapLayer:onParentDetach( ent )
end

function TileMapLayer:onSetVisible( vis )
end

function TileMapLayer:setVisible( vis )
	self.visible = vis
	return self:onSetVisible( vis )
end

local drawLine = MOAIDraw.drawLine
function TileMapLayer:onDrawGridLine()
	local tileWidth, tileHeight = self:getTileSize()
	local width, height = self:getSize()
	local x0, x1 = 0, width * tileWidth
	local y0, y1 = 0, height * tileHeight
	for col = 0, width do --vlines
		local x = col*tileWidth
		drawLine( x, y0, x, y1 )
	end
	for row = 0, height do --hlines
		local y = row*tileHeight
		drawLine( x0, y, x1, y )
	end
end

function TileMapLayer:updateMaterial()
	local materialObject = self.materialPath and loadAsset( self.materialPath )
	if not materialObject then
		materialObject = self.parentMap:getMaterialObject()
	end
	self:applyMaterial( materialObject )
end

function TileMapLayer:applyMaterial( materialObject )
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


----------------------------------------------------------------------
EnumResizeDirection = _ENUM {
	{ 'From Center',       'C'  };
	{ 'From Left',         'L'  };
	{ 'From Left Bottom',  'LB' };
	{ 'From Left Top',     'LT' };
	{ 'From Right',        'R'  };
	{ 'From Right Bottom', 'RB' };
	{ 'From Right Top',    'RT' };
}

CLASS: TileMapResizeParam ()
:MODEL {
	Field 'width'          :int() :readonly();
	Field 'height'         :int() :readonly();
	Field 'newWidth'       :int() :range(1);
	Field 'newHeight'      :int() :range(1);
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
CLASS: TileMap ( RenderComponent )
	:MODEL{
		Field 'initialized' :boolean() :no_edit();
		Field 'serializedData' :variable() :no_edit() :getset( 'SerializedData' );
		'----';
		Field 'defaultTileset' :asset( 'tileset' ) :readonly();
		Field 'size'     :type( 'vec2' ) :getset( 'Size' ) :readonly() :meta{ decimals = 0 };
		Field 'tileSize' :type( 'vec2' ) :getset( 'TileSize' ) :readonly() :meta{ decimals = 0 };
		'----';
		Field 'init'     :action( 'toolActionInit' );
		Field 'resize'   :action( 'toolActionResize' );
}

-- registerComponent( 'TileMap', TileMap )
-- registerEntityWithComponent( 'TileMap', TileMap )

--TODO: API
function TileMap:__init()
	self.layers = {}
	self.width      = 1 
	self.height     = 1
	self.tileWidth  = 1
	self.tileHeight = 1

	self.defaultTileset = false
	self.pendingMapData = false
	self.initialized = false
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
		layer:applyMaterial( self:getMaterialObject() )
	end
	if self.pendingMapData then
		self:loadPendingMapData()
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
		l:updateMaterial()
		
	end
	return l
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

function TileMap:_createLayer( tilesetPath )
	local layer = self:createLayerByTileset( tilesetPath )
	if not layer then return false end
	layer.parentMap = self
	layer:init( self, tilesetPath, true )
	self:addLayer( layer )
	return layer
end

function TileMap:createLayerByTileset( tilesetPath )
	return false
end

function TileMap:getSupportedTilesetType()
	return ''
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


function TileMap:setSerializedData( data )
	self.pendingMapData = data
	if self.scene then
		self:loadPendingMapData()
	end
end

function TileMap:getSerializedData()
	local data = self:saveData()
	return data
end

function TileMap:loadPendingMapData()
	if not self.pendingMapData then return end
	self.initialized = true
	local data = self.pendingMapData
	self.width, self.height         = unpack( data['size'] )
	self.tileWidth, self.tileHeight = unpack( data['tileSize'] )
	local layerDatas = data[ 'layers' ]
	for i, layerData in ipairs( layerDatas ) do
		local layer = self:createLayerByTileset( layerData[ 'tileset' ] )
		layer.parentMap = self
		if layer then
			layer:loadData( layerData, self )
			self:addLayer( layer )
		end
	end
	self.pendingMapData = false
end

function TileMap:init( param )
	self.tileWidth  = param.tileWidth
	self.tileHeight = param.tileHeight
	self.width      = param.width
	self.height     = param.height
	self.defaultTileset = param.defaultTileset
	self.initialized = true
end

function TileMap:resize( resizeParam )
	local newWidth  = resizeParam.newWidth
	local newHeight = resizeParam.newHeight
	self.width  = newWidth
	self.height = newHeight
	for i, layer in ipairs( self.layers ) do
		layer:resize( newWidth, newHeight )
	end
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

function TileMap:updateLayerOrder()

end

----
function TileMap:toolActionInit()
	local param = self:getDefaultParam()
	if mock_edit.requestProperty( 'input tilemap parameters', param ) then
		self:init( param )
		mock_edit.alertMessage( 'message', 'tilemap is initialized', 'info' )
	end
end

function TileMap:toolActionResize()
	local param = TileMapResizeParam()
	param.width     = self.width
	param.height    = self.height
	param.newWidth  = self.width
	param.newHeight = self.height

	if mock_edit.requestProperty( 'input tilemap parameters', param ) then
		self:resize( param )
		mock_edit.alertMessage( 'message', 'tilemap is resized', 'info' )
	end		
end

function TileMap:findLayerByName( name )
	for i, layer in ipairs( self.layers ) do
		if layer.name == name then return layer end
	end
end

function TileMap:getLayer( idx )
	return self.layers[ idx ]
end


function TileMap:applyMaterial( material )
	for i, layer in ipairs( self.layers ) do
		-- layer:applyMaterial( material )
		layer:updateMaterial()
	end
end
