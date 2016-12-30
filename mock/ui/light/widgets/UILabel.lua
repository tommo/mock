module 'mock'

CLASS: UILabel ( UIWidget )
	:MODEL{
		Field 'text' :string() :getset( 'Text' );
}

mock.registerEntity( 'UILabel', UILabel )

function UILabel:__init()
	self.textBox = self:attachInternal( TextLabel() )
	
end

function UILabel:getText( t )
	return self.textBox:getText()
end

function UILabel:setText( t )
	self.textBox:setText( t )
end

function UILabel:initContent( style )
end

function UILabel:updateStyle( style )
	self.textBox:setAlignment( style:get( self, 'align' ) )
end

function UILabel:updateContent( style )
end

function UILabel:initCommonContent( style )

end

function UILabel:initCommonBackground( style )
	local background = style:get( self, 'background' )
end

