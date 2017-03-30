module 'mock'

--------------------------------------------------------------------
CLASS: UIButtonRenderer ( UIWidgetRenderer )
	:MODEL{}

function UIButtonRenderer:onInit( widget )
	self.textElement = self:addElement( UIWidgetElementText() )
	self.textElement:setStyleBaseName( 'text' )
	
	-- self.bgElement   = self:addElement( UIWidgetElementGeometryRect() )
	self.bgElement   = self:addElement( UIWidgetElementImage() )
	self.bgElement:setStyleBaseName( 'background' )

	self.bgElement:setZOrder( -1 )
end

function UIButtonRenderer:getContentRect()
	return self.widget:getLocalRect()
end

function UIButtonRenderer:onUpdateSize( widget, style )
	self.textElement:setRect( self:getContentRect() )
	self.bgElement:setRect( self:getContentRect() )
end

function UIButtonRenderer:onUpdateContent( widget, style )
	local text = widget:getContentData( 'text', 'render' )
	self.textElement:setText( text )
end

