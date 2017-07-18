module 'mock'

--------------------------------------------------------------------
--------------------------------------------------------------------
CLASS: SimplePaintCanvasVisualizer ( PaintCanvasVisualizer )
	:MODEL{}

function SimplePaintCanvasVisualizer:__init()
	self.canvasSeq = false
	self.props = {}
end

function SimplePaintCanvasVisualizer:onAttach( ent )
	self:updateVisual()
end

function SimplePaintCanvasVisualizer:onUpdateVisual()
	local canvas = self:getCanvas()
	local w, h = canvas:getTileSize()
	local ent = self:getEntity()
	local props = self.props
	for prop in pairs( props ) do
		ent:_detachProp( prop )
	end
	props = {}
	self.props = props
	local count = 0
	for i, tile in ipairs( canvas:collectTiles() ) do
		local prop = MOAIGraphicsProp.new()
		local deck = MOAIGfxQuad2D.new()
		local tex = tile:getMoaiTexture()
		deck:setRect( 0, 0, w, h )
		deck:setTexture( tex )
		prop:setDeck( deck )
		prop:setLoc( tile.locX, tile.locY )
		props[ prop ] = true
		setPropBlend( prop, 'alpha' )
		ent:_attachProp( prop )
		count = count + 1
	end
end
