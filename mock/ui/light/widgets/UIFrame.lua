module 'mock'

CLASS: UIFrame ( UIWidget )
	:MODEL{}

function UIFrame:__init()
	self:setClippingChildren( true )
end

function UIFrame:setSize( w, h )
	print( 'size', w, h )
	UIFrame.__super.setSize( self, w, h )
	self:setScissorRect( 0, 0, w, h )
end

registerEntity( 'UIFrame', UIFrame )

