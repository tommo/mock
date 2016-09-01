module 'mock'

CLASS: DeckComponentArray ( GraphicsPropComponent )
	:MODEL{
		Field 'deck'  :asset('deck2d\\..*') :getset('Deck');
		'----';
		Field 'gridSize' :type( 'vec3' ) :getset( 'GridSize' ) :meta{ decimals = 0 };
		Field 'cellSize' :type( 'vec3' ) :getset( 'CellSize' );
		Field 'fitDeckSize' :action();
	}

registerComponent( 'DeckComponentArray', DeckComponentArray )

function DeckComponentArray:__init()
	self.gridSize = { 1,1,1 }
	self.cellSize = { 50,50,50 }
	self.props = {}
	self.deckPath = false
	self.attached = false
end

function DeckComponentArray:onAttach( ent )
	DeckComponentArray.__super.onAttach( self, ent )
	self.attached = true
	self:updateProps()
end

function DeckComponentArray:onDetach( ent )
	DeckComponentArray.__super.onDetach( self, ent )
	self.attached = false
	self:clearProps()
end

function DeckComponentArray:setDeck( deckPath )
	self.deckPath = deckPath
	local deck = mock.loadAsset( deckPath )
	local moaiDeck = deck and deck:getMoaiDeck()
	self._moaiDeck = moaiDeck
	self:updateDeck()
end

function DeckComponentArray:getDeck( deckPath )
	return self.deckPath	
end

function DeckComponentArray:getGridSize()
	return unpack( self.gridSize )
end

function DeckComponentArray:setGridSize( x, y, z )
	self.gridSize = {
		math.floor( math.max( 1, x ) ),
		math.floor( math.max( 1, y ) ),
		math.floor( math.max( 1, z ) )
	}
	self:updateProps()
end

function DeckComponentArray:getCellSize()
	return unpack( self.cellSize )
end

function DeckComponentArray:setCellSize( x, y, z )
	self.cellSize = { x, y, z }
	self:updateLayout()
end

function DeckComponentArray:fitDeckSize()
	local deck = self._moaiDeck
	if not deck then return end
	local x0,y0,z0, x1,y1,z1 = deck.source:getBounds()
	local w, h, d = x1-x0, y1-y0, z1-z0
	return self:setCellSize( w,h,d )
end

function DeckComponentArray:updateProps()
	self:clearProps()
	local gx, gy, gz = unpack( self.gridSize )
	local count = gx*gy*gz
	local props = self.props
	local prop0 = self.prop
	
	local billboard = self.billboard
	local depthMask = self.depthMask
	local depthTest = self.depthTest
	local material = self:getMaterialObject()

	for i = 1, count do
		local prop = MOAIGraphicsProp.new()
		props[ i ] = prop
		linkPartition( prop, prop0 )
		linkIndex( prop, prop0 )
		linkBlendMode( prop, prop0 )
		inheritTransformColorVisible( prop, prop0 )
		linkShader( prop, prop0 )
		material:applyToMoaiProp( prop )
	end 
	self:updateDeck()
end

function DeckComponentArray:updateDeck()
	if not self.attached then return end
	local deck = self._moaiDeck
	for i, prop in ipairs( self.props ) do
		prop:setDeck( deck )
	end
	local prop0 = self.props[1]
	if prop0 then
		self.propBound = { prop0:getBounds() }
	else
		self.propBound = false
	end
	self:updateLayout()
end

function DeckComponentArray:updateLayout()
	if not self.attached then return end
	local prop = self:getMoaiProp()

	local gx, gy, gz = unpack( self.gridSize )
	local cx, cy, cz = unpack( self.cellSize )
	local idx = 0
	local props = self.props
	for i = 1, gz do
	for j = 1, gy do
	for k = 1, gx do
		idx = idx + 1
		local prop = props[ idx ]
		local dx = ( k - 1 ) * cx
		local dy = ( j - 1 ) * cy
		local dz = ( i - 1 ) * cz
		prop:setLoc( dx, dy, dz )
	end
	end
	end
	if self.propBound then
		local x0,y0,z0,x1,y1,z1 = unpack( self.propBound )
		local w, h, d = x1-x0,y1-y0,z1-z0
		
		local bx0,by0,bz0, bx1,by1,bz1
		if cx >= 0 then
			bx0 = x0
			bx1 = (gx-1)*cx + x1
		else
			bx0 = (gx-1)*cx + x0
			bx1 = x1
		end

		if cy >= 0 then
			by0 = y0
			by1 = (gy-1)*cy + y1
		else
			by0 = (gy-1)*cy + y0
			by1 = y1
		end

		if cz >= 0 then
			bz0 = z0
			bz1 = (gz-1)*cz + z1
		else
			bz0 = (gz-1)*cz + z0
			bz1 = z1
		end
		
		self:getMoaiProp():setBounds(
			bx0, by0, bz0,
			bx1, by1, bz1
		)

	else
		self:getMoaiProp():setBounds( 0,0,0,0,0,0 )
	end
end

function DeckComponentArray:clearProps()
	for i, prop in ipairs( self.props ) do
		clearLinkPartition( prop )
		clearLinkIndex( prop )
		clearInheritTransform( prop )
		clearInheritColor( prop )
		clearLinkShader( prop )
		clearLinkBlendMode( prop )
		prop:setPartition( nil )
		prop:forceUpdate()
	end
	self.props = {}
end

function DeckComponentArray:applyMaterial( mat )
	mat:applyToMoaiProp( self.prop )
	for i, prop in ipairs( self.props ) do
		mat:applyToMoaiProp( prop )
	end
end	


--------------------------------------------------------------------
function DeckComponentArray:drawBounds()
	GIIHelper.setVertexTransform( self.prop )
	local x1,y1,z1, x2,y2,z2 = self.prop:getBounds()
	MOAIDraw.drawRect( x1,y1,x2,y2 )
end

function DeckComponentArray:onBuildSelectedGizmo()
	return mock_edit.SimpleBoundGizmo()
end
