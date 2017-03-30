module 'mock'

--------------------------------------------------------------------
CLASS: UIFrameRenderer ( UIWidgetRenderer )
	:MODEL{}

function UIFrameRenderer:onInit( widget )
	self.bgElement = self:addElement( 
		UIWidgetElementImage()
	)
	self.bgElement:setStyleBaseName( 'background' )
end

function UIFrameRenderer:getContentRect()
	return self.widget:getLocalRect()
end

function UIFrameRenderer:onUpdateSize( widget, style )
	self.bgElement:setRect( self:getContentRect() )
end

