module 'mock'

--------------------------------------------------------------------
CLASS: UIWidgetElementImage ( UIWidgetElement )
	:MODEL{}

function UIWidgetElementImage:__init()
end

function UIWidgetElementImage:onInit( widget )
	local sprite = widget:attachInternal( DeckComponent() )
	self.sprite = sprite
	self.spriteDeck = false
end

function UIWidgetElementImage:onDestroy( widget )
	widget:detach( self.label )
end

function UIWidgetElementImage:onUpdateStyle( widget, style )
	local sprite = self.sprite
	local spriteDeck = style:getAsset( self:makeStyleName( 'sprite' ) )
	if self.spriteDeck ~= spriteDeck then
		self.spriteDeck = spriteDeck
		if not spriteDeck then
			sprite:hide()
		else
			sprite:setDeck( spriteDeck )
			sprite:show()
		end
	end
	local color = { style:getColor( self:makeStyleName( 'color' ), { 1,1,1,1 } ) }
	sprite:setColor( unpack( color ) )
end

function UIWidgetElementImage:onUpdateSize( widget, style )
	local sprite = self.sprite
	local ox, oy = self:getOffset()
	local x0, y0, x1, y1 = self:getRect()
	sprite:setRect( x0 + ox, y0 + oy, x1 + ox, y1 + oy )
end

function UIWidgetElementImage:setZOrder( z )
	self.sprite:setLocZ( z )
end

--------------------------------------------------------------------
CLASS: UIWidgetElementText ( UIWidgetElement )
	:MODEL{}

function UIWidgetElementText:__init()
	self.styleBaseName = ''
	self.text = ''
	self.label = false
end

function UIWidgetElementText:setText( text )
	self.text = text
end

function UIWidgetElementText:onInit( widget, style )
	local label = widget:attachInternal( TextLabel() )
	self.label = label
	label:setText('')
	label:setVisible( false )
	label.fitAlignment = false
	label:setLocZ( 0.1 )
end

function UIWidgetElementText:onDestroy( widget )
	widget:detach( self.label )
end

function UIWidgetElementText:onUpdateStyle( widget, style )
	local align    = style:get( self:makeStyleName( 'alignment' ), 'left' )
	local alignV   = style:get( self:makeStyleName( 'alignment_vertical' ), 'top' )
	local font     = style:getAsset( self:makeStyleName( 'font' ) )
	local fontSize = style:get( self:makeStyleName( 'font_size' ), 12 )
	local color    = { style:getColor( self:makeStyleName( 'color' ), { 1,1,1,1 } ) }
	local styleSheet = makeStyleSheetFromFont( font, fontSize )

	local label = self.label
	label:setAlignment( align )
	label:setAlignmentV( alignV )
	label:setStyleSheet( AdHocAsset( styleSheet ) )
	label:setColor( unpack( color ) )

end

function UIWidgetElementText:onUpdateSize( widget, style )
	local label = self.label
	local ox, oy = self:getOffset()
	local x0, y0, x1, y1 = self:getRect()
	label:setRect( x0 + ox, y0 + oy, x1 + ox, y1 + oy )
end

function UIWidgetElementText:onUpdateContent( widget, style )
	local label = self.label
	local text = self.text
	if text then 
		label:setVisible( true )
		label:setText( text )
	else
		label:setVisible( false )
	end
end

function UIWidgetElementText:setZOrder( z )
	self.label:setLocZ( z )
end
