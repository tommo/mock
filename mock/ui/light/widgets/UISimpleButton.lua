module 'mock'

CLASS: UISimpleButton ( UIButton )
	:MODEL{
		Field 'text' :string() :getset( 'Text' )
	}

function UISimpleButton:__init()
	self.borderColor = {0,0,0,1}
	self.buttonColor = {1,1,1,1}
	self.backgroundSpriteDeck = false
	self.backgroundSprite = self:attachInternal( DeckComponent() )
	self.textLabel        = self:attachInternal( TextLabel() )
end

function UISimpleButton:getText()
	return self.textLabel:getText()
end

function UISimpleButton:setText( t )
	return self.textLabel:setText( t )
end


local function rectAdjust( x0, y0, x1, y1, dx0, dy0, dx1, dy1 )
	return x0 + dx0, y0 + dy0, x1 + dx1, y1 + dy1
end

local function rectOffset( x0, y0, x1, y1, ox, oy )
	return x0 + ox, y0 + oy, x1 + ox, y1 + oy
end

function UISimpleButton:onUpdateVisual( style )
	self.buttonColor = { style:getColor( 'background_color' ) }
	self.borderColor = { style:getColor( 'border_color' ) }

	local spriteDeck = style:getAsset( 'background_sprite' )
	if self.backgroundSpriteDeck ~= spriteDeck then
		self.backgroundSpriteDeck = spriteDeck
		if not spriteDeck then
			self.backgroundSprite:hide()
		else
			self.backgroundSprite:setDeck( spriteDeck )
			self.backgroundSprite:show()
		end
	end
	local padding = style:get( 'padding', 0 )

	self.backgroundSprite:setColor( unpack( self.buttonColor ) )
	self.backgroundSprite:setRect( self:getLocalRect() )

	self.textLabel:setAlignment( 'center' )
	self.textLabel:setAlignmentV( 'center' )
	self.textLabel:setLoc( self:getLocalRectCenter() )
	self.textLabel:addLoc( style:getVec2( 'text_offset', { 0, 0 } ) )
	
	local font = style:getAsset( 'font' )
	local fontSize = style:get( 'font_size', 12 )
	local styleSheet = makeStyleSheetFromFont( font, fontSize )
	self.textLabel:setStyleSheet( AdHocAsset( styleSheet) )
	self.textLabel:setColor( style:getColor( 'text_color' ) )
	
	self.backgroundSprite:setLocZ( -0.1 )
	self.textLabel:setLocZ( 0.1 )
end


registerEntity( 'UISimpleButton', UISimpleButton )

