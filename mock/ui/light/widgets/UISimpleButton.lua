module 'mock'

CLASS: UISimpleButton ( UIButton )
	:MODEL{
		Field 'text' :string() :getset( 'Text' )
	}

function UISimpleButton:__init()
	self.buttonColor = {1,1,1,1}
	self.textLabel  = self:attachInternal( TextLabel() )
	self.drawScript = self:attachInternal( DrawScript() )
end

function UISimpleButton:getText()
	return self.textLabel:getText()
end

function UISimpleButton:setText( t )
	return self.textLabel:setText( t )
end

function UISimpleButton:onUpdateVisual( style )
	local color = { style:getColor( 'background_color' ) }
	self.buttonColor = color
end

function UISimpleButton:onDraw()
	local w, h = self:getSize()

	if self.pressed then
		MOAIGfxDevice.setPenColor( unpack( self.buttonColor ) )
	else
		MOAIGfxDevice.setPenColor( unpack( self.buttonColor ) )
	end
	MOAIDraw.fillRect( 0, 0, w, h )
end

registerEntity( 'UISimpleButton', UISimpleButton )

