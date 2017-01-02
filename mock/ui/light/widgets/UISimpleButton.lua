module 'mock'

CLASS: UISimpleButton ( UIButton )
	:MODEL{
		Field 'text' :string() :getset( 'Text' )
	}

function UISimpleButton:__init()
	self.borderColor = {0,0,0,1}
	self.buttonColor = {1,1,1,1}
	self.backgroundSpriteDeck = false
	self.textLabel      = self:attachInternal( TextLabel() )
	self.drawScript     = self:attachInternal( DrawScript() )
	self.backgroundSprite = self:attachInternal( DeckComponent() )

end

function UISimpleButton:getText()
	return self.textLabel:getText()
end

function UISimpleButton:setText( t )
	return self.textLabel:setText( t )
end

function UISimpleButton:onUpdateVisual( style )
	self.buttonColor = { style:getColor( 'background_color' ) }
	self.borderColor = { style:getColor( 'border_color' ) }

	local spriteDeck = style:getAsset( 'background_sprite' )
	if self.backgroundSpriteDeck ~= spriteDeck then
		self.backgroundSpriteDeck = spriteDeck
		if not spriteDeck then
			self.backgroundSprite:hide()
			self.drawScript:show()
		else
			self.backgroundSprite:setDeck( spriteDeck )
			self.backgroundSprite:show()
			self.drawScript:hide()
		end
	end
	self.backgroundSprite:setColor( unpack( self.buttonColor ) )
	self.backgroundSprite:setSize( self:getSize() )
	
end

function UISimpleButton:onDraw()
	local w, h = self:getSize()
	-- MOAIGfxDevice.setPenColor( unpack( self.buttonColor ) )
	-- MOAIDraw.fillRect( 0, 0, w, h )
	MOAIGfxDevice.setPenColor( unpack( self.borderColor ) )
	MOAIDraw.drawRect( 0, 0, w, h )
end

registerEntity( 'UISimpleButton', UISimpleButton )

