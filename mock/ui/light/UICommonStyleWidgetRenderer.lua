module 'mock'

--------------------------------------------------------------------
CLASS: UICommonStyleWidgetRenderer ( UIWidgetRenderer )
	:MODEL{}

function UICommonStyleWidgetRenderer:onInit( widget )
	self.backgroundSprite = widget:attachInternal( DeckComponent() )
	self.textLabel        = widget:attachInternal( TextLabel() )
	self.textLabel:setText('')
	self.textLabel:setVisible( false )
	self.borderColor = {0,0,0,1}
	self.bgColor = {1,1,1,1}
	self.backgroundSpriteDeck = false
	self.textLabel.fitAlignment = false
end

function UICommonStyleWidgetRenderer:onDestroy( widget )
	widget:detach( self.backgroundSprite )
	widget:detach( self.textLabel )
end

function UICommonStyleWidgetRenderer:getBackgroundRect()
	return self.widget:getLocalRect()
end

function UICommonStyleWidgetRenderer:getContentRect()
	return self.widget:getLocalRect()
end

function UICommonStyleWidgetRenderer:updateBackgroundStyle( widget, style )
	local sprite = self.backgroundSprite
	local spriteDeck = style:getAsset( 'background_sprite' )
	if self.backgroundSpriteDeck ~= spriteDeck then
		self.backgroundSpriteDeck = spriteDeck
		if not spriteDeck then
			sprite:hide()
		else
			sprite:setDeck( spriteDeck )
			sprite:show()
		end
	end
	local padding = style:get( 'padding', 0 )

	sprite:setColor( unpack( self.bgColor ) )
	sprite:setRect( self:getBackgroundRect() )
	sprite:setLocZ( -0.1 )
end

function UICommonStyleWidgetRenderer:updateTextStyle( widget, style )
	local label = self.textLabel

	label:setAlignment( 'center' )
	label:setAlignmentV( 'center' )
	label:setRect( self:getContentRect() )
	label:addLoc( style:getVec2( 'text_offset', { 0, 0 } ) )

	local font = style:getAsset( 'font' )
	local fontSize = style:get( 'font_size', 12 )
	local styleSheet = makeStyleSheetFromFont( font, fontSize )
	label:setStyleSheet( AdHocAsset( styleSheet) )
	label:setColor( style:getColor( 'text_color', { 1,1,1,1 } ) )
	
	label:setLocZ( 0.1 )
end


function UICommonStyleWidgetRenderer:onUpdateStyle( widget, style )
	self.bgColor = { style:getColor( 'background_color' , { 1,1,1,1 } ) }
	self.borderColor = { style:getColor( 'border_color', { 1,1,1,1 } ) }

	self:updateBackgroundStyle( widget, style )
	self:updateTextStyle( widget, style )

end


function UICommonStyleWidgetRenderer:onUpdateContent( widget, style )
	--text
	local label = self.textLabel
	local text = widget:getContentData( 'text', 'render' )
	if text then 
		label:setVisible( true )
		label:setText( text )
	else
		label:setVisible( false )
	end
	--icon
end
