module 'mock'

CLASS: DeckComponentGrid ( DeckComponent )
	:MODEL{
		'----';
		Field 'gridSize' :type( 'vec2' ) :getset( 'GridSize' ) :meta{ decimals = 0 };
		Field 'cellSize' :type( 'vec2' ) :getset( 'CellSize' );
		Field 'spacing'  :type( 'vec2' ) :getset( 'Spacing' );
		Field 'fitDeckSize' :action();
	}

registerComponent( 'DeckComponentGrid', DeckComponentGrid )

function DeckComponentGrid:__init()
	self.gridSize = { 1,1 }
	self.cellSize = { 50,50 }
	self.spacing  = { 0, 0 }
	self.deckPath = false
	self.attached = false
	self.grid = MOAIGrid.new()
	self.grid:fill( 1 )
	self.remapper = MOAIDeckRemapper.new()
	self.remapper:reserve( 1 )
	self.remapper:setAttrLink( 1, self.prop, MOAIProp.ATTR_INDEX )
	self.prop:setGrid( self.grid )
	self.prop:setRemapper( self.remapper )
end

function DeckComponentGrid:onAttach( ent )
	DeckComponentGrid.__super.onAttach( self, ent )
	self:updateGrid()
end

function DeckComponentGrid:getGridSize()
	return unpack( self.gridSize )
end

function DeckComponentGrid:setGridSize( x, y )
	self.gridSize = {
		math.floor( math.max( 1, x ) ),
		math.floor( math.max( 1, y ) ),
	}
	self:updateGrid()
end

function DeckComponentGrid:getCellSize()
	return unpack( self.cellSize )
end

function DeckComponentGrid:setCellSize( x, y )
	self.cellSize = { x, y }
	self:updateGrid()
end

function DeckComponentGrid:getSpacing()
	return unpack( self.spacing )
end

function DeckComponentGrid:setSpacing( x, y )
	self.spacing = { x, y }
	self:updateGrid()
end

function DeckComponentGrid:fitDeckSize()
	local deck = self._moaiDeck
	if not deck then return end
	local x0,y0,z0, x1,y1,z1 = deck.source:getBounds()
	local w, h, d = x1-x0, y1-y0, z1-z0
	return self:setCellSize( w, h )
end

function DeckComponentGrid:updateGrid()
	local prop = self:getMoaiProp()

	local gx, gy = unpack( self.gridSize )
	local cx, cy = unpack( self.cellSize )
	local sx, sy = unpack( self.spacing )
	local ox, oy = 0, 0
	self.grid:setSize( gx, gy, cx + sx, cy + sy, -ox, -oy, 1, 1 )
	self.grid:fill( 1 )

end
