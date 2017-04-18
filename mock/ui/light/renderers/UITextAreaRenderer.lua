module 'mock'

--------------------------------------------------------------------
CLASS: UITextAreaRenderer ( UIWidgetRenderer )
	:MODEL{}

function UITextAreaRenderer:onInit( widget )
	self.textElement = self:addElement( 
		UIWidgetElementText()
	)
	self.textElement:setStyleBaseName( 'text' )
end

function UITextAreaRenderer:getContentRect()
	return self.widget:getLocalRect()
end

function UITextAreaRenderer:onUpdateSize( widget, style )
	self.textElement:setRect( self:getContentRect() )
end

function UITextAreaRenderer:onUpdateContent( widget, style )
	local text = widget:getContentData( 'text', 'render' )
	self.textElement:setText( text )
end

