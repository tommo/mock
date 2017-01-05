-- module 'mock'

-- CLASS: UISprite ( UIWidget )
-- 	:MODEL{}

-- function UISimpleButton:__init()
-- 	self.sprite = self:attachInternal( DeckComponent() )
-- 	self.spriteColor = {1,1,1,1}
-- 	self.spriteDeck = false
-- end

-- function UISprite:onUpdateVisual( style )
-- 	self.spriteColor = { style:getColor( 'color' ) }
-- 	local spriteDeck = style:getAsset( 'sprite' )
-- 	if self.backgroundSpriteDeck ~= spriteDeck then
-- 		self.backgroundSpriteDeck = spriteDeck
-- 		if not spriteDeck then
-- 			self.sprite:hide()
-- 		else
-- 			self.sprite:setDeck( spriteDeck )
-- 			self.sprite:show()
-- 		end
-- 	end
-- 	local padding = style:get( 'padding', 0 )

-- 	self.sprite:setColor( unpack( self.spriteColor ) )
-- 	self.sprite:setRect( self:getLocalRect() )

-- 	self.textLabel:setAlignment( 'center' )
-- 	self.textLabel:setAlignmentV( 'center' )
-- 	self.textLabel:setLoc( self:getLocalRectCenter() )
-- 	self.textLabel:addLoc( style:getVec2( 'text_offset', { 0, 0 } ) )
	
-- 	local font = style:getAsset( 'font' )
-- 	local fontSize = style:get( 'font_size', 12 )
-- 	local styleSheet = makeStyleSheetFromFont( font, fontSize )
-- 	self.textLabel:setStyleSheet( AdHocAsset( styleSheet) )
-- 	self.textLabel:setColor( style:getColor( 'text_color' ) )
	
-- 	self.sprite:setLocZ( -0.1 )
-- 	self.textLabel:setLocZ( 0.1 )
-- end

-- registerEntity( 'UISprite', UISprite )
