module 'mock'

--------------------------------------------------------------------
CLASS: UILabelRenderer ( UIWidgetRenderer )
	:MODEL{}

function UILabelRenderer:onInit( widget )
	self.textElement = self:addElement( 
		UIWidgetElementText()
	)
	self.textElement:setStyleBaseName( 'text' )
end

function UILabelRenderer:getContentRect()
	return self.widget:getLocalRect()
end

function UILabelRenderer:onUpdateSize( widget, style )
	self.textElement:setRect( self:getContentRect() )
end

function UILabelRenderer:onUpdateContent( widget, style )
	local text = widget:getContentData( 'text', 'render' )
	self.textElement:setText( text )
end

