module 'mock'
--------------------------------------------------------------------
--example component for PaintCanvas
--------------------------------------------------------------------
CLASS: PaintCanvasPlane ( mock.RenderComponent )
	:MODEL{}

registerComponent( 'PaintCanvasPlane', PaintCanvasPlane )

function PaintCanvasPlane:__init()
	self.canvas = false
	self.props = {}
	self.mainProp = MOAIGraphicsProp.new()
end

function PaintCanvasPlane:onAttach( ent )
	ent:_attachProp( self.mainProp )
	self.canvas = ent:com( 'PaintCanvas' ) or false
	if self.canvas then
		self:connect( self.canvas.changed, 'onCanvasUpdate' )		
	end
	self:update()
end

function PaintCanvasPlane:onDetach( ent )
	ent:_detachProp( self.mainProp )
	self.canvas = false
	self:clear()
end

function PaintCanvasPlane:onCanvasUpdate( subset )
	self:update( subset )
end

function PaintCanvasPlane:update( subset )
	local canvas = self.canvas
	if not canvas then return end
	if self.canvasSeq == canvas._seq then return end
	canvas:uploadTextures()
	self.canvasSeq = canvas._seq
	
	self.mainProp:setScl( canvas:getScale() )
	self:clear()

	local w, h = canvas:getTileSize()
	local ent = self:getEntity()
	local props = {}
	self.props = props
	local material = self:getMaterialObject()
	local prop0 = self.mainProp
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
		material:applyToMoaiProp( prop )
		ent:_attachProp( prop )
		linkPartition( prop, prop0 )
		linkIndex( prop, prop0 )
		inheritTransformColorVisible( prop, prop0 )
		count = count + 1
	end
end

function PaintCanvasPlane:clear()
	local ent = self:getEntity()
	for prop in pairs( self.props ) do
		clearLinkPartition( prop )
		clearLinkIndex( prop )
		clearInheritTransform( prop )
		clearInheritColor( prop )
		prop:setPartition( nil )
		prop:forceUpdate()
	end
	self.props = {}
end

function PaintCanvasPlane:applyMaterial( material )
	for prop in pairs( self.props ) do
		material:applyToMoaiProp( prop )
	end
end
