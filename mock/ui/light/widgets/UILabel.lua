module 'mock'

CLASS: UILabel ( UIWidget )
	:MODEL{
		Field 'text' :string() :getset( 'Text' );
}

mock.registerEntity( 'UILabel', UILabel )

function UILabel:__init()
	self.textLabel = self:attachInternal( TextLabel() )
	self.textLabel.fitAlignment = false
end

function UILabel:getText( t )
	return self.textLabel:getText()
end

function UILabel:setText( t )
	self.textLabel:setText( t )
end

function UILabel:initContent( style )
end

function UILabel:onUpdateVisual( style )	
	local font = style:getAsset( 'font' )
	local fontSize = style:get( 'font_size', 12 )
	local styleSheet = makeStyleSheetFromFont( font, fontSize )
	self.textLabel:setStyleSheet( AdHocAsset( styleSheet) )
	self.textLabel:setColor( style:getColor( 'text_color', { 1,1,1,1 } ) )
	self.textLabel:setAlignment( style:get( 'align', 'left' ) )
	self.textLabel:setAlignmentV( style:get( 'align_vertical', 'center' ) )
	self.textLabel:setRect( self:getLocalRect() )
end
