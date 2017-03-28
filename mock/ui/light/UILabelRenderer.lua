module 'mock'

--------------------------------------------------------------------
CLASS: UILabelRenderer ( UIWidgetRenderer )
	:MODEL{}

function UILabelRenderer:onInit( widget )
	local label = widget:attachInternal( TextLabel() )
	self.textLabel = label
	label:setText('')
	label:setVisible( false )
	label.fitAlignment = false
	label:setLocZ( 0.1 )
end

function UILabelRenderer:onDestroy( widget )
	widget:detach( self.textLabel )
end

function UILabelRenderer:getContentRect()
	return self.widget:getLocalRect()
end

function UILabelRenderer:onUpdateSize( widget, style )
	--text size
	local label = self.textLabel
	label:setRect( self:getContentRect() )
	label:addLoc( style:getVec2( 'text_offset', { 0, 0 } ) )
end

function UILabelRenderer:onUpdateStyle( widget, style )
	local label = self.textLabel
	label:setAlignment( 'center' )
	label:setAlignmentV( 'center' )
	local font = style:getAsset( 'font' )
	local fontSize = style:get( 'font_size', 12 )
	local styleSheet = makeStyleSheetFromFont( font, fontSize )
	label:setStyleSheet( AdHocAsset( styleSheet) )
	label:setColor( style:getColor( 'text_color', { 1,1,1,1 } ) )

end

function UILabelRenderer:onUpdateContent( widget, style )
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
