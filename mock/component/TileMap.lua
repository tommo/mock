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

function TileMapGrid:tileIdToGridId( tileId )
	return tileId
end


--------------------------------------------------------------------
CLASS: TileMapLayer ()
	:MODEL{
		Field 'name'    :string();
		Field 'tag'     :string();
		Field 'tilesetPath' :asset( 'tileset' );
		Field 'visible' :boolean();
	}

function TileMapLayer:__init()
	self.name      = 'layer'
	self.tag       = ''
	self.parentMap = false
	self.mapGrid   = false
	self.visible   = true

	self.width      = 1
	self.height     = 1
	self.tileWidth  = 1
	self.tileHeight = 1
	self.tilesetPath = false
	self.tileset = false

	self.order     = 0 --order

end

function TileMapLayer:init( parentMap, tilesetPath )
	self.width      = parentMap.width
	self.height     = parentMap.height
	self.tileWidth  = parentMap.tileWidth
	self.tileHeight = parentMap.tileHeight
	self.tilesetPath  = tilesetPath
	self.tileset      = loadAsset( tilesetPath )
	self:onInit()
end

function TileMapLayer:worldToModel( x, y )
	return self.parentMap._entity:worldToModel( x, y )
end

function TileMapLayer:onInit()
	local grid = self:getGrid()
	grid:setSize( self.width, self.height, self.tileWidth, self.tileHeight )
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

function TileMapLayer:tileIdToGridId( tileId )
	return self.mapGrid:tileIdToGridId( tileId )
end

function TileMapLayer:loadData( data, parentMap )
	local tilesetPath = data[ 'tileset' ]
	
	self:init( parentMap, tilesetPath )
	self.name = data[ 'name' ]
	self.tag  = data[ 'tag'  ]
	--TODO:verify size
	local width, height         = unpack( data['size'] )
	local tileWidth, tileHeight = unpack( data['tileSize'] )
	assert( self.width  == width )
	assert( self.height == height )
	assert( self.tileWidth == tileWidth )
	assert( self.tileHeight == tileHeight )
	self:getGrid():loadTiles( data['tiles'] )
	self:onLoadData( data )
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

function TileMapLayer:getTileData( x, y )
	local id = self.mapGrid:getTile( x, y )
	local tileset = self:getTileset()
	if not tileset then return nil end
	return tileset:getTileData( id )
end

function TileMapLayer:setTile( x, y, id )
	return self.mapGrid:setTile( x, y, id )
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

function TileMapLayer:setVisible( vis )
	self.visible = vis
end

local drawLine = MOAIDraw.drawLine
function TileMapLayer:onDrawGridLine()
	local tileWidth, tileHeight = self.tileWidth, self.tileHeight
	local width, height = self.width, self.height
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

function TileMapLayer:updateRenderParams( param )
	local map = self.parentMap
	self:setShader( map.shader )
	self:setDepthTest( map.depthTest )
	self:setDepthMask( map.depthMask )
	self:setBillboard( map.billboard )
	self:setBlend( map.blend )
end

function TileMapLayer:setDepthTest( param )
end

function TileMapLayer:setDepthMask( param )
end

function TileMapLayer:setBillboard( param )
end

function TileMapLayer:setBlend( param )
end

function TileMapLayer:setShader( param )
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
CLASS: TileMap ( RenderComponent )
	:MODEL{
		Field 'serializedData' :string() :no_edit() :getset( 'SerializedData' );
		'----';
		Field 'defaultTileset' :asset( 'tileset' ) :readonly();
		Field 'size'     :type( 'vec2' ) :getset( 'Size' ) :readonly() :meta{ decimals = 0 };
		Field 'tileSize' :type( 'vec2' ) :getset( 'TileSize' ) :readonly() :meta{ decimals = 0 };
		'----';
		Field 'init'     :action( 'toolActionInit' );
		Field 'resize'   :action( 'toolActionResize' );
}

registerComponent( 'TileMap', TileMap )
registerEntityWithComponent( 'TileMap', TileMap )

--TODO: API
function TileMap:__init()
	self.layers = {}
	self.width      = 1
	self.height     = 1
	self.tileWidth  = 1
	self.tileHeight = 1
	self.defaultTileset = false
	self.pendingMapData = false
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
	if self.pendingMapData then
		self:loadPendingMapData()
	end
	self:updateRenderParams()
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
		l:updateRenderParams()
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
	layer:init( self, tilesetPath )
	self:addLayer( layer )
	return layer
end

function TileMap:createLayerByTileset( tilesetPath )
	local tileset, anode = mock.loadAsset( tilesetPath )
	local atype = anode:getType()
	if atype == 'tileset' then
		return TileMapLayer()
	elseif atype == 'named_tileset' then
		return NamedTileMapLayer()
	elseif atype == 'deck2d.mtileset' then
		return NamedTileMapLayer()
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
	local data = self.pendingMapData
	self.width, self.height         = unpack( data['size'] )
	self.tileWidth, self.tileHeight = unpack( data['tileSize'] )
	local layerDatas = data[ 'layers' ]
	for i, layerData in ipairs( layerDatas ) do
		local layer = self:createLayerByTileset( layerData[ 'tileset' ] )
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
		mock_edit.alertMessage( 'message', 'TODO*', 'info' )
end

function TileMap:findLayerByName( name )
	for i, layer in ipairs( self.layers ) do
		if layer.name == name then return layer end
	end
end

function TileMap:getLayer( idx )
	return self.layers[ idx ]
end


function TileMap:getBlend()
	return self.blend
end

function TileMap:setBlend( b )
	self.blend = b
	self:updateRenderParams()		
end

function TileMap:setShader( s )
	self.shader = s
	self:updateRenderParams()		
end

function TileMap:setDepthMask( enabled )
	self.depthMask = enabled
	self:updateRenderParams()		
end

function TileMap:setDepthTest( mode )
	self.depthTest = mode
	self:updateRenderParams()		
end

function TileMap:setBillboard( billboard )
	self.billboard = billboard
	self:updateRenderParams()		
end

function TileMap:updateRenderParams()
	for i, layer in ipairs( self.layers ) do
		layer:updateRenderParams()		
	end
end

