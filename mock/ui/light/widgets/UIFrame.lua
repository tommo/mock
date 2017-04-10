module 'mock'

CLASS: UIFrame ( UIWidget )
	:MODEL{}

function UIFrame:__init()
	self:setClippingChildren( true )
end

function UIFrame:onLoad()
	UIFrame.__super.onLoad( self )
	self:setRenderer( UIFrameRenderer() )
end

function UIFrame:setSize( w, h, ... )
	UIFrame.__super.setSize( self, w, h, ... )
	self:setScissorRect( 0, 0, w, h )
end

registerEntity( 'UIFrame', UIFrame )

