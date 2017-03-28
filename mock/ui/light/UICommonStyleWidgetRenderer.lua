module 'mock'

--------------------------------------------------------------------
CLASS: UICommonStyleWidgetRenderer ( UIWidgetRenderer )
	:MODEL{}

function UICommonStyleWidgetRenderer:onInit( widget )
	self.borderColor = {0,0,0,1}
	self.bgColor = {1,1,1,1}
	--
	local label = widget:attachInternal( TextLabel() )
	self.textLabel = label
	label:setText('')
	label:setVisible( false )
	label.fitAlignment = false
	label:setLocZ( 0.1 )

	local bgSprite = widget:attachInternal( DeckComponent() )
	self.backgroundSprite = bgSprite
	self.backgroundSpriteDeck = false
	bgSprite:setLocZ( -0.1 )
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
end

function UICommonStyleWidgetRenderer:updateTextStyle( widget, style )
	local label = self.textLabel
	label:setAlignment( 'center' )
	label:setAlignmentV( 'center' )
	local font = style:getAsset( 'font' )
	local fontSize = style:get( 'font_size', 12 )
	local styleSheet = makeStyleSheetFromFont( font, fontSize )
	label:setStyleSheet( AdHocAsset( styleSheet) )
	label:setColor( style:getColor( 'text_color', { 1,1,1,1 } ) )
end

function UICommonStyleWidgetRenderer:onUpdateSize( widget, style )
	--bg size
	local sprite = self.backgroundSprite
	sprite:setRect( self:getBackgroundRect() )

	--text size
	local label = self.textLabel
	label:setRect( self:getContentRect() )
	label:addLoc( style:getVec2( 'text_offset', { 0, 0 } ) )

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
