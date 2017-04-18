module 'mock'

--------------------------------------------------------------------
CLASS: UIWidgetElementText ( UIWidgetElement )
	:MODEL{}

function UIWidgetElementText:__init()
	self.styleBaseName = ''
	self.text = ''
	self.label = false
	self.defaultAlignment  = 'left'
	self.defaultAlignmentV = 'center'
end

function UIWidgetElementText:setDefaultAlignment( h, v )
	self.defaultAlignment = h or 'left'
	self.defaultAlignmentV = h or 'center'
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
	local align    = style:get( self:makeStyleName( 'alignment' ), self.defaultAlignment )
	local alignV   = style:get( self:makeStyleName( 'alignment_vertical' ), self.defaultAlignmentV )
	local font     = style:getAsset( self:makeStyleName( 'font' ) )
	local fontSize = style:get( self:makeStyleName( 'font_size' ), 12 )
	local color    = { style:getColor( self:makeStyleName( 'color' ), { 1,1,1,1 } ) }
	local styleSheet = makeStyleSheetFromFont( font, fontSize )
	local lineSpacing = style:get( self:makeStyleName( 'line_spacing' ), 2 )

	self:setOffset( style:getVec2( self:makeStyleName( 'offset' ), { 0, 0 } ) )
	local label = self.label
	label:setAlignment( align )
	label:setAlignmentV( alignV )
	label:setStyleSheet( AdHocAsset( styleSheet ) )
	label:setColor( unpack( color ) )
	label:setLineSpacing( lineSpacing )

end

function UIWidgetElementText:onUpdateSize( widget, style )
	local label = self.label
	local ox, oy = self:getOffset()
	local x0, y0, x1, y1 = self:getRect()
	label:setRect( x0 + ox, y0 + oy, x1 + ox, y1 + oy )
	label:setLocZ( self:getZOrder() )
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

